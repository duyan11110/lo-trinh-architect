---
id: k8s.l4.node-autoscaling
lang: en
track: k8s
level: 4
stage: 4
module: managed-vs-selfhosted
main_path: true
title: "Extra Pods need room: adding nodes is another autoscaler's job"
duration_min: 14
skills: [k8s.scaling.autoscaling]
prereqs: [k8s.l4.horizontal-pod-autoscaler, k8s.l4.managed-control-plane, backend.l4.capacity-planning, k8s.l3.draining-nodes]
related: [k8s.l1.requests-and-limits, k8s.l3.clusters-without-a-cloud, k8s.l4.sharing-a-cluster]
vocab: [cluster-autoscaler]
example_tag: stage-4
versions_used: [kubernetes, kind, postgresql]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-10-28T21:29:36+07:00"
---

## Before you start

- [[k8s.l4.horizontal-pod-autoscaler]] — you know an HPA sets a Deployment's replica count between `minReplicas` and `maxReplicas`.
- [[k8s.l4.managed-control-plane]] — you know a managed cluster's worker nodes come from node pools built from one template.
- [[backend.l4.capacity-planning]] — you know the capacity plan keeps headroom under measured limits, PostgreSQL's `max_connections` among them.
- [[k8s.l3.draining-nodes]] — you know draining a node evicts its Pods so their controllers recreate them on other nodes.

## The situation

The capacity plan expects an evening peak, and the HPA from the last lesson will raise the count when CPU climbs. You rehearse the peak on `donhang` with `cpu-echo`: each Pod now asks for most of a worker's CPU, and you tell the HPA to keep at least 4 replicas. `kubectl get hpa` shows 4 replicas, as asked. Yet `kubectl get deployment` shows `2/4` ready, and two Pods sit in `Pending` with no node. The HPA did its job, and two Pods still do not run. What gives a Pod room on a node, and who adds a node when there is none?

## Core concepts

- Unrequested capacity (not a new term) — what a node can allocate to Pods, minus the requests of the Pods already placed on it; kube-scheduler places a Pod only where this covers the Pod's requests.
- `Pending` Pod (not a new term) — a Pod the API server has accepted whose containers are not running yet; a Pod kube-scheduler has not placed on any node stays in this phase and waits.
- Event (not a new term) — a short record the cluster keeps about an object such as a Pod; kube-scheduler writes a `FailedScheduling` event when it cannot place a Pod, and kubectl can show it.
- **cluster autoscaler** — a component that adds a node to a node pool when Pods cannot be scheduled for lack of resources, and removes a node whose Pods can all run on the other nodes.
- Node start-up time (not a new term) — the time between asking for a new node and that node joining the cluster, ready to take Pods. The provider first creates a machine, most commonly a virtual machine, which must boot and register, so this takes longer than placing a Pod on a node that already has room.

## How it works

```mermaid
flowchart LR
  H[HPA] -->|replica count| D[Deployment]
  D -->|new Pods (via ReplicaSet)| S[kube-scheduler]
  S -->|requests fit| N[Node with room]
  S -->|nothing fits| P[Pending Pod]
  P -->|noticed by| C[cluster autoscaler]
  C -->|add nodes| G[node pool]
  G -.->|node starts and joins| S
```

In the situation above, the HPA did all it ever does: it wrote 4 into the Deployment's replica count. The ReplicaSet created the Pods, and each new Pod went to kube-scheduler. kube-scheduler compares the Pod's requests with each node's unrequested capacity and places the Pod only where they fit. On `donhang`, each worker had room for one `cpu-echo` Pod, so two Pods ran and two stayed `Pending`, with a `FailedScheduling` event saying why.

That is where a cluster autoscaler works, on a cluster whose nodes come from node pools. It looks for Pods that cannot be scheduled for lack of resources. When nodes built from a pool's template would fit them, it has the provider add as many as the waiting Pods need, if the pool's configured maximum allows. Each node must start and join the cluster; only then does kube-scheduler place the waiting Pods on it. Until then they stay `Pending`, and the Pods already running carry the load.

What makes it add a node here is a Pod whose requests do not fit anywhere, never CPU use. A cluster whose nodes run hot, but where every Pod has been placed, gets no node from it.

It also works the other way. When a node's Pods request little and could all run on the other nodes, the autoscaler evicts them, as a drain does, so their controllers recreate them on the other nodes, and removes the node.

`donhang` has no node pool and no cluster autoscaler: kind runs each node as a Docker container, created with the cluster from `deploy/k8s/kind-config.yaml` (one control plane, two workers), and nothing adds nodes afterwards. The two Pods stay `Pending` until the script puts things back.

## In the Đơn Hàng system

`node-capacity.sh` first sets each `cpu-echo` Pod's CPU request to 60% of what one worker can allocate, so one worker holds one Pod whatever the number of CPUs of your machine. Then it raises the HPA's floor:

```bash file=scripts/k8s/node-capacity.sh tag=stage-4 lines=40-62
# lesson: k8s.l4.node-autoscaling
# The HPA must keep at least 4 replicas: it sets the count, the scheduler
# finds room for two Pods, one per worker; the other two stay Pending.
echo "\$ kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{\"spec\":{\"minReplicas\":4}}'"
kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{"spec":{"minReplicas":4}}'
for _ in $(seq 90); do
  [ "$(kubectl get hpa cpu-echo -n autoscale-lessons -o jsonpath='{.status.currentReplicas}')" = 4 ] && break
  sleep 2
done
for _ in $(seq 90); do
  pending=$(kubectl get pods -n autoscale-lessons -l app=cpu-echo --field-selector status.phase=Pending \
    -o name | wc -l)
  running=$(kubectl get pods -n autoscale-lessons -l app=cpu-echo --field-selector status.phase=Running \
    -o name | wc -l)
  [ "$pending" -eq 2 ] && [ "$running" -eq 2 ] && break
  sleep 2
done
show kubectl get hpa cpu-echo -n autoscale-lessons
show kubectl get deployment cpu-echo -n autoscale-lessons
echo "\$ kubectl get pods -n autoscale-lessons -l app=cpu-echo (how many in each phase)"
kubectl get pods -n autoscale-lessons -l app=cpu-echo -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' \
  | sort | uniq -c | awk '{ print $2 ": " $1 }'
echo
```

```text output=true
...
$ kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{"spec":{"minReplicas":4}}'
horizontalpodautoscaler.autoscaling/cpu-echo patched
$ kubectl get hpa cpu-echo -n autoscale-lessons
NAME       REFERENCE             TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
cpu-echo   Deployment/cpu-echo   cpu: <unknown>/50%   4         5         4          ...
$ kubectl get deployment cpu-echo -n autoscale-lessons
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
cpu-echo   2/4     4            2           ...
$ kubectl get pods -n autoscale-lessons -l app=cpu-echo (how many in each phase)
Pending: 2
Running: 2

== FailedScheduling of a Pending cpu-echo Pod
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
...
```

The two loops only wait until the HPA reports 4 and two Pods are `Pending`; the last command counts Pods per phase. `show` is a helper from `scripts/lib/network-lessons.sh` that prints a command and runs it. The HPA shows `REPLICAS 4` with its target still `<unknown>`: the new floor alone set the count. The Deployment wants 4 Pods and has 2 ready.

The `FailedScheduling` line comes from the script's next part, outside this excerpt. It counts the three nodes of `donhang`: `2 Insufficient cpu` are the two workers, each already holding one Pod's request, and the other node is the control-plane node, which kind marks to keep ordinary Pods off; that mark is what `1 node(s) had untolerated taint(s)` reports. The rest of the line is about scheduler features this lesson leaves aside, such as Pod priority; you can skip it.

What still bounds `maxReplicas` when nodes can grow is in the capacity plan:

```markdown file=docs/design/capacity-plan.md tag=stage-4 lines=44-54
- Kết nối database: mỗi Pod api giữ một pool kết nối của Npgsql cho
  `ConnectionStrings:Default`, kích thước mặc định vì connection string không
  đặt. Payments, Notifications, các migration và job backup mở kết nối tới
  cùng server. Tổng số Pod × kết nối tối đa mỗi Pod của mọi service phải nhỏ
  hơn `max_connections` của PostgreSQL; đọc giá trị đó bằng
  `SHOW max_connections`, không đoán.

### Khoảng dư

Quy tắc: tải đỉnh không vượt một nửa trần của 2 Pod api, để một Pod gánh được
toàn bộ khi mất Pod kia (node hỏng, rolling update).
```

The first item says each `api` Pod holds its own pool of database connections: open connections the process keeps and reuses, up to a maximum size, so one Pod holds several at once. Other services open connections to the same server. Pods times connections per Pod, over every service, must stay below PostgreSQL's `max_connections`. A cluster autoscaler adds nodes, not database connections, so this bound holds however many nodes exist. The headroom rule keeps the peak under half of what the 2 `api` Pods can serve. That margin also carries the first part of a peak while a new node starts.

## Trade-offs

| | Nodes bought ahead for the planned peak | Cluster autoscaler on a node pool |
|---|---|---|
| Who adds a node | The team, before the peak | The autoscaler, when Pods cannot be scheduled |
| What you pay for | The peak's nodes, all day | Nodes for the requests placed now |
| First part of a sudden peak | Room is already there | New Pods wait in `Pending` while a node starts |
| What bounds `maxReplicas` | What the bought nodes hold, and shared resources | Shared resources such as `max_connections` |
| Where it is possible | Anywhere, including your own machines | Where a provider creates nodes on request |

## What would you choose if…

- …Đơn Hàng moves to machines the team runs itself: buy nodes for the planned peak plus headroom, and keep `maxReplicas` within what those nodes hold by requests, because nothing creates a node on demand and a Pod beyond that only waits in `Pending`.
- …production runs on a managed cluster and the evening peak builds up over an hour: an HPA on `api` plus a cluster autoscaler on its node pool, with the plan's headroom carrying the load while each node starts.
- …a promotion sends a sharp peak at a known minute: the pair alone reacts too late, since a node takes Pods only after its machine is created and booted, so raise `minReplicas` by a commit before that minute, let the nodes join in time, and lower it afterwards.

## Seniors often assume…

- **"The HPA adds nodes when the cluster runs out of room."** → Actually the HPA only writes a replica count; kube-scheduler places Pods, and a cluster autoscaler, if one runs, adds nodes. You notice this when `kubectl get hpa` shows the count you expect while the Deployment's ready count stays lower and Pods sit in `Pending`.
- **"A cluster autoscaler adds a node as soon as CPU use gets high."** → Actually it reacts to Pods that cannot be scheduled for lack of resources, judged by requests. You notice this when nodes run hot for an hour and the node count does not move, because every Pod found a place.
- **"With autoscaling turned on, we no longer need a capacity plan."** → Actually both autoscalers act inside limits the plan sets: a new node needs time to join, and PostgreSQL's `max_connections` does not grow with nodes. You notice this when a peak's first minutes bring errors while nodes start, or extra `api` Pods fail to get database connections.

## Try it (3 minutes)

From the root of the Đơn Hàng repository, with Docker Desktop running and `kubectl` and kind installed:

1. Run `scripts/k8s/node-capacity.sh`. It creates `donhang` if it is missing, which takes longer than this exercise. If it stops because a worker has less than 60% of its CPU unrequested, it names the fix: delete the namespaces earlier lessons left, then run it again.
2. Find the HPA's `REPLICAS`, the Deployment's `READY` and the `FailedScheduling` line.
3. Suppose the same Pods ran on a managed cluster with a cluster autoscaler on the workers' node pool, each node the size of a `donhang` worker. What happens to the two `Pending` Pods, and what still stops you setting `maxReplicas` to 50 for `api`?

Expected result: the HPA at 4 replicas, the Deployment at `2/4`, `Pending: 2` and `Running: 2`, and an event with `2 Insufficient cpu`; at the end the script puts back the request and `minReplicas` and deletes `autoscale-lessons`.

<details><summary>Suggested answer</summary>

The autoscaler sees two Pods that fit no node. A node from the template holds one such Pod, and the autoscaler asks for as many nodes as the waiting Pods need, so, if the pool's configured maximum allows, it has the provider add two nodes; once they start and join, kube-scheduler places the Pods. Until then they stay `Pending`. As for 50 `api` Pods, each would hold its own pool of database connections, and with the other services they must stay below `max_connections`, which no added node raises.

</details>

## Connections

- [[k8s.l4.horizontal-pod-autoscaler]] — the autoscaler one step earlier: it sets the Pod count whose Pods then need nodes.
- [[k8s.l1.requests-and-limits]] — the requests that kube-scheduler and the cluster autoscaler both count, never the use.
- [[k8s.l4.managed-control-plane]] — where node pools come from; a cluster autoscaler grows and shrinks them.
- [[backend.l4.capacity-planning]] — the plan whose headroom and connection limit still bound `maxReplicas`.
- [[k8s.l3.draining-nodes]] — removing a node means emptying it first, as a drain does.
- [[k8s.l3.clusters-without-a-cloud]] — on your own machines nothing creates a node on demand.
- [[k8s.l4.sharing-a-cluster]] — a namespace's quota can refuse new Pods before any node runs short.
- [[k8s.l4.requests-drive-cluster-cost]] — next: since nodes follow requests, so does the cost.

## Five-line summary

1. An HPA only sets how many Pods run; each extra Pod still needs a node whose unrequested capacity covers its requests, or it stays `Pending`.
2. kube-scheduler places Pods by requests, not use; when no node has room, it records a `FailedScheduling` event.
3. A cluster autoscaler adds a node to a node pool when Pods cannot be scheduled, and removes nodes whose Pods fit elsewhere.
4. A new node must start and join first, so headroom still carries a peak's first part; your own machines are bought ahead instead.
5. `maxReplicas` stays bounded by shared resources such as PostgreSQL's `max_connections`, however many nodes exist.
