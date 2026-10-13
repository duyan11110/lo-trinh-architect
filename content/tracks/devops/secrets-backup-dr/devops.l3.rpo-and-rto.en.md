---
id: devops.l3.rpo-and-rto
lang: en
track: devops
level: 3
stage: 3
module: secrets-backup-dr
main_path: true
title: "RPO and RTO: how much data and time a failure may cost"
duration_min: 12
skills: [devops.dr.recovery]
prereqs: [devops.l1.volumes, k8s.l1.deploying-don-hang, management.l2.non-functional-requirements]
related: [foundation.l1.shell-scripts, backend.l2.redis-key-value-store]
vocab: [disaster-recovery, rpo, rto]
example_tag: stage-2
versions_used: [postgresql, docker, kubernetes, redis]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-10-13T23:10:28+07:00"
---

## Before you start

- [[devops.l1.volumes]] — you know the `db` service keeps PostgreSQL's files in the volume `db-data`, which outlives the container.
- [[k8s.l1.deploying-don-hang]] — you know the cluster's `db` Pod keeps its data in an `emptyDir`, and a replacement Pod starts empty.
- [[management.l2.non-functional-requirements]] — you know a requirement about how well the system works is useful only with a stated case and a stated measure.

## The situation

At a planning meeting your team lead asks a plain question: if the machine running Đơn Hàng's database died tonight, how many orders would the shop lose, and for how long could customers not order? You answer that there is a backup, `scripts/terminal/backup-db.sh`. Then you look at the file it writes. It creates every table, and not one order is in it. Nobody has ever said how many lost orders, or how many hours without ordering, the shop could live with. Before choosing any backup tool, what must recovery promise, and who decides it?

## Core concepts

- **disaster recovery (DR)** — getting a system working again after losing something it cannot run without, such as the disk under its database or a whole cluster.
- **RPO (recovery point objective)** — how much recent data the business accepts losing in such a failure, counted as time before the failure.
- **RTO (recovery time objective)** — how long the business accepts the system being unusable after the failure, until it works again.
- The only copy of a fact — data that exists in one store and nowhere else, so losing that store loses the fact; a backup is needed only for stores that hold such data.

## How it works

```mermaid
flowchart LR
  C["Last copy you can restore"] -->|"written here: lost, bounded by RPO"| F["Failure"]
  F -->|"unusable here: bounded by RTO"| W["Working again"]
```

Read the diagram as a timeline. On the left is the newest copy of the data that you could actually restore. Every order written between that copy and the failure is gone. The RPO is the longest that gap may be: an RPO of one hour means losing at most the last hour of orders.

On the right, the clock starts when the failure happens and stops when customers can order again. The RTO is the longest that stretch may be. It covers everything in between: someone noticing, getting a working machine, finding the copy, restoring it, checking it, and pointing the api at it.

In the situation above, neither number exists yet, and neither is yours to invent. Both come from the business. The shop knows how many orders its staff could re-enter by hand from customers' emails, and how long a pause in ordering costs it. Your job is to ask, write the answers down as two checkable requirements, and then design to them.

Each step lower costs more. A smaller RPO needs copies taken more often, so more storage and tooling. A smaller RTO needs machines and scripts ready in advance and people who have practised the steps. That is why the business, which pays, sets both numbers. Asking for zero data loss and no downtime is a request whose price someone has to see first.

## In the Đơn Hàng system

The backup that exists at this tag, from `scripts/terminal/backup-db.sh`:

```bash file=scripts/terminal/backup-db.sh tag=stage-2 lines=7-18
out_dir="${1:-/tmp/backups}"
mkdir -p "$out_dir"
file="$out_dir/donhang-schema.sql"

pg_dump --host db --username donhang --dbname donhang \
        --schema-only --no-owner --no-privileges > "$file"

echo "wrote $file"
echo "tables in the backup: $(grep -c 'CREATE TABLE' "$file")"

echo
echo "the exit code of the last command was $?"
```

```text output=true
wrote /tmp/backups/donhang-schema.sql
tables in the backup: 7

the exit code of the last command was 0
```

`pg_dump` is PostgreSQL's tool that writes a database out as a file of SQL statements, called a dump. The flag to look at is `--schema-only` in the `pg_dump` command. With it, the dump holds the statements that create the tables of `donhang` and none of their rows. Restoring it gives you seven empty tables: no customer, no product, no order. The run looks healthy, with a file, a count and exit code `0`, the number a command returns to say it succeeded, yet recovers nothing. The file also lands in `/tmp/backups` inside the lab box, on the same machine as the database.

Where the data itself lives, in the cluster, from `deploy/k8s/db.yaml`:

```yaml file=deploy/k8s/db.yaml tag=stage-2 lines=50-60
          volumeMounts:
            - name: init-scripts
              mountPath: /docker-entrypoint-initdb.d
            - name: data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: init-scripts
          configMap:
            name: db-init
        - name: data
          emptyDir: {}
```

PostgreSQL's data folder is the volume `data`, an `emptyDir` (the `init-scripts` lines mount setup files, not the data; ignore them here). Kubernetes creates it empty for the Pod and deletes it when the Pod is removed. If the Pod is replaced, or its node is lost, every order in the cluster is gone. In Compose, `docker-compose.yml` mounts the named volume `db-data` at the same folder. It survives removing the container, but it lives on the disk of one machine, so it does not survive losing that machine.

Redis is different. `docker-compose.yml` says of it, in the comment above the `redis` service, that nothing in it is the only copy of a fact: PostgreSQL has them all. The api fills Redis from PostgreSQL and keeps answering from PostgreSQL when Redis is not there. Losing Redis costs some slower requests, not data. So the first question for each store is whether it holds the only copy of a fact; how to back it up comes second.

## Seniors often assume…

- **"The RPO is whatever interval the backup job happens to run at."** → Actually the RPO is a target the business sets, and the job's interval is one design that has to meet it. The data you really lose is measured back to the last copy you can restore, which is older than the last run if that run failed, copied the wrong thing, or sat on the machine that died. You notice this when a job that "runs every night" meets its first real failure and the newest usable copy is weeks old.
- **"The RTO is how long the restore command takes."** → Actually the RTO clock runs from the failure until customers can use the system again, and the restore command is one step inside it. Noticing the failure, getting a machine, finding the copy and checking the result all count. You notice this when a restore that took minutes on your laptop turns into an afternoon during a real outage.
- **"Every data store in the system needs the same kind of backup."** → Actually only a store holding the only copy of a fact needs a backup to avoid losing data; a cache like Redis, which the api refills from PostgreSQL and can answer without, needs none. You notice this when a backup plan spends effort on Redis while a store holding real records is missing from it.

## Try it (3 minutes)

A thinking exercise. Suppose the shop says: staff can re-enter by hand at most the last 15 minutes of orders, and customers may be unable to order for at most 2 hours.

1. Would one dump of `donhang` with its rows, taken every night, meet that RPO?
2. For the RTO, list the steps between "the database machine dies" and "customers can order again". Which step does a restore command cover?

Expected result: you can say, for each number, whether a nightly dump meets it, and you have a list of at least four steps for the RTO.

<details><summary>Suggested answer</summary>

1. No. A failure just before the next nightly run loses almost a day of orders, far more than 15 minutes. Meeting a 15-minute RPO needs a copy at least every 15 minutes, kept off the database's machine.
2. Noticing the failure, getting a working machine, fetching the newest copy, restoring it, checking that orders are there, and pointing the api at the new database. The restore command covers only one of these. Whether the rest fits in 2 hours is something you find out by timing it, not by guessing.

</details>

## Connections

- [[foundation.l1.shell-scripts]] — the same `backup-db.sh` as a first script; here it is judged by what it can bring back.
- [[backend.l2.redis-key-value-store]] — the reason Redis needs no backup: PostgreSQL holds every fact Redis caches.
- [[management.l2.non-functional-requirements]] — RPO and RTO are two such requirements, each with a stated case and a measure.
- [[devops.l3.logical-backups]] — the next step: a dump with rows, whose RPO is the time between dumps.
- [[devops.l3.restore-testing]] — where a timed restore replaces the guess about the RTO.

## Five-line summary

1. Recovery starts with two numbers from the business: how much recent data it may lose (RPO) and how long it may be down (RTO).
2. RPO is counted back from the failure to the last copy you can actually restore, not to the last job run.
3. RTO runs from the failure until the system works again, and covers far more than the restore command.
4. Stage-2's `backup-db.sh` dumps with `--schema-only`, and both `db-data` and the cluster's `emptyDir` live on one machine.
5. Redis holds no only copy of a fact, so it needs no backup; find those stores first, then choose backups.
