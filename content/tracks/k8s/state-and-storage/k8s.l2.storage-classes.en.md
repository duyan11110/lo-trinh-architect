---
id: k8s.l2.storage-classes
lang: en
track: k8s
level: 2
stage: 3
module: state-and-storage
main_path: true
title: "A StorageClass creates volumes on demand; kind's stay on one node"
duration_min: 14
skills: [k8s.storage.volumes]
prereqs: [k8s.l2.persistent-volume-claims, k8s.l1.control-plane-components, k8s.l1.cluster-nodes-and-control-plane]
related: [devops.l3.disaster-recovery-drill]
vocab: [storage-class, dynamic-provisioning]
example_tag: stage-3
versions_used: [kubernetes, kind]
content_version: 1
status: reviewed
approved_by: null
reviewed_at: "2026-10-15T07:46:18+07:00"
---

## Before you start

- [[k8s.l2.persistent-volume-claims]] — the claim `data` turned `Bound` to a PersistentVolume you never wrote; this lesson shows where that volume came from.
- [[k8s.l1.control-plane-components]] — kube-scheduler assigns each Pod to a node; here that choice also decides where a volume is created.
- [[k8s.l1.cluster-nodes-and-control-plane]] — `donhang` has one control-plane node and two workers, each a Docker container made by kind; a volume ends up inside one of them.

## The situation

In the last lesson, `pvc.sh` applied the claim `data` and the Pod `writer`, and the claim then read `Bound` to a PersistentVolume. You never wrote a PersistentVolume. Now you plan to give `db` a claim of its own, so the orders survive a replaced Pod. Before you do, two things matter: where the files physically sit in the cluster `donhang`, and what happens to them if a worker node is taken out of service or the cluster is rebuilt. `kubectl get pv` lists a volume, but not who made it or what holds it in place. Who created that PersistentVolume, and what ties its files to one place?

## Core concepts

- **StorageClass** — an object that names a provisioner, the component that creates PersistentVolumes, together with the settings it uses; a claim chooses one with `storageClassName`.
- Default StorageClass — the class marked `(default)`, given to every claim that names no class; in a kind cluster it is `standard`.
- **dynamic provisioning** — creating a PersistentVolume at the moment a claim needs one, through its StorageClass, so nobody creates volumes ahead of time.
- `WaitForFirstConsumer` — a binding mode: the claim stays `Pending` until a Pod that uses it is scheduled, and the volume is then created to fit that Pod's node.
- Node affinity of a PersistentVolume — the nodes recorded in the volume; every Pod that uses the volume can run only on one of them.

## How it works

```mermaid
sequenceDiagram
  participant S as storage-class.sh
  participant C as claim data
  participant K as kube-scheduler
  participant P as provisioner local-path
  participant N as writer's node
  participant PV as PersistentVolume
  S->>C: apply, no storageClassName
  Note over C: class standard, Pending, no volume
  S->>K: apply Pod writer
  K->>N: choose this node for writer
  K->>C: record the chosen node
  P->>N: create a folder on this node
  P->>PV: create, node affinity = this node
  PV->>C: Bound
  Note over K,N: node unschedulable: new writer stays Pending
```

In the situation above, the claim `data` names no class, so Kubernetes gives it the cluster's default StorageClass, `standard`. `kubectl get storageclass` shows its provisioner, `rancher.io/local-path`, and its binding mode, `WaitForFirstConsumer`.

That mode is why the claim first reads `Pending`, with no PersistentVolume behind it: nothing is created while no Pod needs the storage. When `writer` is applied (the script sends it to the API server, and kube-scheduler picks it up there), kube-scheduler chooses a node for it and records that node on the claim through the API server. Only then does the provisioner act: it creates a folder under `/var/local-path-provisioner/` on that node and a PersistentVolume that describes it, and the claim turns `Bound`. This is dynamic provisioning: the StorageClass said who answers the claim.

The folder exists on one node only, so the PersistentVolume records that node in its node affinity. From then on, every Pod that uses `data` can run only there. The script marks that node unschedulable, deletes `writer` and applies it again. The new `writer` has nowhere to go: the other worker is not the volume's node, and the volume's node takes no new Pods. It stays `Pending` until the node is schedulable again.

The same tie decides what a failure costs. kind runs each node as a Docker container, and the folder is inside that node; `deploy/k8s/kind-config.yaml` maps nothing to your machine's disk. No other node holds a copy either, so the files are only as safe as that one node. A copy on another node or outside the cluster needs a provisioner built to make one; this one keeps each volume on the one node where it was created, and only that node can use it.

## In the Đơn Hàng system

```yaml file=deploy/k8s/lessons/data-pvc.yaml tag=stage-3 lines=1-15
# lesson: k8s.l2.persistent-volume-claims
# lesson: k8s.l2.storage-classes
# A request for storage, not storage: 100 MiB that one node at a time may
# mount read-write. No storageClassName, so the cluster's default
# StorageClass provides it (standard in a kind cluster).
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
  namespace: storage-lessons
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
```

This is the same claim as in the last lesson. Look at what `spec` leaves out: there is no `storageClassName`, so the choice of class falls to the cluster's default. In the output below, `kubectl get storageclass` marks `standard` as `(default)`, and the PersistentVolume that appears later reports `storage class: standard`.

```bash file=scripts/k8s/storage-class.sh tag=stage-3 lines=28-49
# The provisioner created the volume as a folder on the node kube-scheduler
# chose for writer, and the PersistentVolume records that node.
pod_node=$(kubectl get pod writer -n storage-lessons -o jsonpath='{.spec.nodeName}')
pv=$(kubectl get pvc data -n storage-lessons -o jsonpath='{.spec.volumeName}')
pv_node=$(kubectl get pv "$pv" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')
echo "== the PersistentVolume"
kubectl get pv "$pv" -o jsonpath='storage class: {.spec.storageClassName}{"\n"}reclaim policy: {.spec.persistentVolumeReclaimPolicy}{"\n"}folder: {.spec.hostPath.path}{.spec.local.path}{"\n"}'
echo "node in its nodeAffinity is writer's node: $([ "$pv_node" = "$pod_node" ] && echo yes || echo no)"
echo

# lesson: k8s.l2.storage-classes
# Mark that node unschedulable, delete writer and create it again: the only
# node its volume can be mounted on takes no new Pods, so it stays Pending.
echo "\$ kubectl cordon <writer's node>"
kubectl cordon "$pod_node" >/dev/null
show kubectl delete pod writer -n storage-lessons
show kubectl apply -f deploy/k8s/lessons/data-writer-pod.yaml
sleep 10
show kubectl get pod writer -n storage-lessons -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
echo "== why, from the scheduler"
kubectl get events -n storage-lessons --field-selector involvedObject.name=writer,reason=FailedScheduling \
  -o jsonpath='{.items[-1:].message}{"\n"}' | sed -E 's/^0\/[0-9]+ nodes are available: //'
```

```text output=true
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  ...

$ kubectl apply -f deploy/k8s/lessons/data-pvc.yaml
persistentvolumeclaim/data created
claim data: Pending, PersistentVolumes for it: 0
$ kubectl apply -f deploy/k8s/lessons/data-writer-pod.yaml
pod/writer created
claim data: Bound

== the PersistentVolume
storage class: standard
reclaim policy: Delete
folder: /var/local-path-provisioner/pvc-..._storage-lessons_data
node in its nodeAffinity is writer's node: yes

$ kubectl cordon <writer's node>
$ kubectl delete pod writer -n storage-lessons
pod "writer" deleted from storage-lessons namespace
$ kubectl apply -f deploy/k8s/lessons/data-writer-pod.yaml
pod/writer created
$ kubectl get pod writer -n storage-lessons -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
NAME     STATUS
writer   Pending
== why, from the scheduler
1 node(s) didn't match PersistentVolume's node affinity, 1 node(s) had untolerated taint(s), 1 node(s) were unschedulable. no new claims to deallocate, preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

$ kubectl uncordon <writer's node>
$ kubectl get pod writer -n storage-lessons -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
NAME     STATUS
writer   Running
```

Above the excerpt, the script applies the claim, waits five seconds and counts PersistentVolumes for it: none, and the claim is `Pending`. Only after `writer` is applied does it read `Bound`. Lines 30–32 read three names: the node `writer` runs on, the volume bound to the claim, and the node in that volume's node affinity. Line 34 prints the volume's class, policy and folder; the folder can sit in either of two fields, so it reads both. Line 35 compares the two nodes and prints `yes`. `show`, defined above the excerpt, prints a command after `$` and then runs it.

Lines 41–42 mark the node unschedulable with `kubectl cordon`, then the script recreates `writer`. The scheduler records each reason for not placing a Pod as an event about that Pod, and `kubectl get events` lists them. Lines 48–49 print the last one, with the `0/3 nodes are available:` prefix cut off by `sed`. Each of the three nodes is ruled out: the other worker does not match the volume's node affinity, the volume's node is unschedulable, and the control-plane node is excluded for a reason outside this lesson; the rest of the line does not matter here. Below the excerpt, `kubectl uncordon` makes the node schedulable again, and `writer` turns `Running` there. `RECLAIMPOLICY` and the `reclaim policy:` line belong to the next lesson; `ALLOWVOLUMEEXPANSION` is not used here.

## Seniors often assume…

- **"A volume in a kind cluster lives on the laptop's disk and survives deleting the cluster."** → Actually it is a folder inside one node, and kind runs each node as a Docker container; `deploy/k8s/kind-config.yaml` maps no folder of your machine into the nodes, and no other node holds a copy. Whatever happens to that node happens to the files. You notice this when `storage-class.sh` prints the folder `/var/local-path-provisioner/...` and you find no folder of your machine mapped to it.
- **"A Pod with a persistent volume can be moved to any node, like a Pod without one."** → Actually its PersistentVolume records one node in its node affinity, and kube-scheduler places Pods that use the volume only there. If that node is unschedulable or gone, the Pod waits. You notice this when a replacement Pod stays `Pending` and its events say `didn't match PersistentVolume's node affinity`.
- **"Every cluster's default StorageClass behaves the way kind's does."** → Actually the default is whatever class was marked as default in that cluster; its provisioner decides where volumes live, and its binding mode decides when they are created. With the mode `Immediate`, a volume is created as soon as the claim exists, before any Pod. Some clusters have no default at all. You notice this when `kubectl get storageclass` on another cluster shows a different `PROVISIONER` or `VOLUMEBINDINGMODE`, or no `(default)`.

## Try it (3 minutes)

With the cluster `donhang` running (`scripts/k8s/cluster-up.sh`), in the `don-hang` folder:

1. Run `scripts/k8s/storage-class.sh`.
2. Find the first `claim data:` line, printed before `writer` is applied, and the line under `== why, from the scheduler`.

Expected result: the output matches the one shown above. The first line reads `claim data: Pending, PersistentVolumes for it: 0`; the scheduler's line names `PersistentVolume's node affinity` for one node and `unschedulable` for another; the script ends with `writer` `Running`.

## Connections

- [[k8s.l2.persistent-volume-claims]] — prerequisite: the same claim and Pod, now seen from the storage side.
- [[k8s.l2.reclaim-policy]] — next: what happens to this PersistentVolume and its folder when the claim is deleted.
- [[k8s.l3.clusters-without-a-cloud]] — builds on this: storage that keeps copies across nodes, the gap kind's one-node folders leave open.
- [[devops.l3.disaster-recovery-drill]] — the reason to rehearse recovery: a volume kept on one node is only as safe as that node.

## Five-line summary

1. A StorageClass names a provisioner that creates a PersistentVolume when a claim asks, so nobody has to create volumes ahead of time.
2. A claim without `storageClassName` gets the default StorageClass; in kind that is `standard`, with the provisioner `rancher.io/local-path`.
3. `standard` waits for the first Pod using the claim, then creates the volume as a folder on the node chosen for that Pod.
4. The PersistentVolume records that node, so later Pods using the claim run only there; while that node is unschedulable, they stay `Pending`.
5. kind's volumes have no copy on another node or on your machine, so the data is only as safe as that one node.
