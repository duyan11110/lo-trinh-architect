---
id: backend.l2.skip-locked-claiming
lang: en
track: backend
level: 2
stage: 2
module: background-jobs
main_path: true
title: "Two API copies must not send the same email: SKIP LOCKED"
duration_min: 15
skills: [backend.jobs.reliability]
prereqs: [backend.l2.database-job-queue, foundation.l1.transaction-intro]
related: [backend.l2.at-least-once-jobs]
vocab: [row-lock]
example_tag: stage-2
versions_used: [efcore, postgresql, docker]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-09-28T19:38:25+07:00"
---

## Before you start

- [[backend.l2.database-job-queue]] — you know each order email is a `pending` row in `notifications`, and `NotificationSender` reads the due rows every 2 seconds, sends them and marks them `sent`.
- [[foundation.l1.transaction-intro]] — you know `BEGIN` opens a transaction, `COMMIT` keeps its changes and shows them to others, and a lost connection leaves none of its changes written.

## The situation

Imagine `NotificationSender` read its due rows with a plain `SELECT`. Orders pick up, and the team starts a second copy of the `api` next to the first, both using the same PostgreSQL database. The next morning a customer writes in: she got two identical emails for order 42. You check `notifications` and find one row for order 42, `sent`, which each copy sent once. Both copies woke at nearly the same moment and both read the row while it was still `pending`. How can two copies share one job queue so that each row is taken by exactly one of them?

## Core concepts

- **row lock** — a mark a transaction holds on specific rows until it ends; the kind `FOR UPDATE` takes stops other transactions from changing or locking those rows in the meantime.
- `FOR UPDATE` — a clause at the end of a `SELECT` that takes a row lock on every row the query returns.
- `SKIP LOCKED` — an addition to `FOR UPDATE` that leaves out rows another transaction has already locked, instead of waiting for them.
- Claim — the step where one copy of the sender takes a batch of due rows as its own, by locking them.

## How it works

```mermaid
sequenceDiagram
  participant A as Sender in copy A
  participant DB as PostgreSQL
  participant B as Sender in copy B
  participant M as Mailpit
  A->>DB: BEGIN; due rows FOR UPDATE SKIP LOCKED, LIMIT 10
  DB-->>A: rows 1-10, now locked by A
  B->>DB: BEGIN; the same query
  DB-->>B: rows 11-20, skipping 1-10
  A->>M: send rows 1-10
  A->>DB: save sent; COMMIT, locks released
```

Every running copy of the API hosts its own `NotificationSender`. In the situation above, both copies read with a plain `SELECT` for `pending` rows. Until one of them commits `sent`, the other still sees `pending`, so both sent order 42's email.

The fix is to make taking a row an act that only one transaction can win. Inside a transaction, `SELECT ... FOR UPDATE` puts a row lock on each row it returns. Another transaction that tries to lock or change one of those rows waits until the first one commits or rolls back.

Waiting alone is not enough: the second copy would stand idle while the first sends its batch. With `SKIP LOCKED` added, the second query passes over the locked rows and takes the next due ones instead. In the diagram, copy A claims rows 1 to 10 and copy B claims rows 11 to 20, so each copy of the sender works on a different set.

The lock lasts until the transaction ends. So the sender claims a small batch, sends it, saves `sent` and commits, which releases the locks. A small batch keeps that transaction short. A large one could let one copy lock most due rows while the others find nothing to claim, and would leave more rows waiting if that copy stops. If the process stops before the commit, its connection to PostgreSQL is lost, the transaction rolls back, and the rows stay `pending` for the next claim.

A row lock hides nothing. A plain `SELECT` without `FOR UPDATE` still reads a locked row at once; only other lockers and writers wait or, with `SKIP LOCKED`, pass it by.

## In the Đơn Hàng system

At stage-2 the sender already claims this way. The claim and the commit, as `NotificationSender` uses them in each round:

```csharp file=DonHang.Infrastructure/NotificationQueue.cs tag=stage-2 lines=16-37
    public async Task<List<Notification>> ClaimDueAsync(int batchSize, CancellationToken cancellationToken)
    {
        await db.Database.BeginTransactionAsync(cancellationToken);
        var now = DateTimeOffset.UtcNow;
        return await db.Notifications
            .FromSql($"""
                SELECT * FROM notifications
                WHERE status = 'pending' AND next_attempt_at <= {now}
                ORDER BY next_attempt_at, id
                LIMIT {batchSize}
                FOR UPDATE SKIP LOCKED
                """)
            .Include(n => n.Order!).ThenInclude(o => o.Customer)
            .ToListAsync(cancellationToken);
    }

    // Saves what the sender changed on the claimed rows and releases their locks.
    public async Task CompleteAsync(CancellationToken cancellationToken)
    {
        await db.SaveChangesAsync(cancellationToken);
        await db.Database.CommitTransactionAsync(cancellationToken);
    }
```

`ClaimDueAsync` opens the transaction first, then runs the claim as SQL with `FromSql`. `NotificationSender` passes a `batchSize` of 10. Between the two methods it sends each email, so the locks are held for exactly one batch. `CompleteAsync` saves the changed rows inside that same transaction and commits it.

The script for this lesson inserts four demo rows due in the year 2100, which the API's own sender leaves alone. Each session in it is one separate connection to PostgreSQL: `sql` is a helper defined earlier in the script that sends its `--command` statements over one new connection. Session A claims two rows and holds the locks for 3 seconds; while it does, sessions B, C and D run one after another:

```bash file=scripts/backend/skip-locked.sh tag=stage-2 lines=19-41
# lesson: backend.l2.skip-locked-claiming
# The WHERE, ORDER BY and locking clause of NotificationQueue.ClaimDueAsync;
# each session below sends it in a transaction of its own.
claim="SELECT subject FROM notifications
       WHERE status = 'pending' AND next_attempt_at <= '$due'
       ORDER BY next_attempt_at, id LIMIT 2"

echo "== session A: BEGIN, claim 2 rows FOR UPDATE SKIP LOCKED, hold the locks for 3 s"
session_a=$(mktemp)
sql --command "BEGIN" --command "$claim FOR UPDATE SKIP LOCKED" \
    --command "SELECT pg_sleep(3)" --command "COMMIT" > "$session_a" &
sleep 1
grep -v '^$' "$session_a" | sed 's/^/  A got: /'

echo "== session B, while A holds its locks: the same claim"
sql --command "BEGIN" --command "$claim FOR UPDATE SKIP LOCKED" --command "COMMIT" | sed 's/^/  B got: /'

echo "== session C: the claim without SKIP LOCKED, giving up after 1 s of waiting"
sql --command "SET lock_timeout = '1s'" --command "BEGIN" --command "$claim FOR UPDATE" \
    --command "COMMIT" 2>&1 | sed 's/^/  C: /' || true

echo "== session D: a plain SELECT, no FOR UPDATE: it waits for nothing"
sql --command "SELECT subject FROM notifications WHERE next_attempt_at = '$due' ORDER BY id" | sed 's/^/  D sees: /'
```

Session A plays copy A; the trailing `&` runs it in the background, so the script moves on after 1 second while A still holds its locks. Session B plays copy B with `SKIP LOCKED`. Session C drops `SKIP LOCKED`, so it has to wait; `lock_timeout` makes it give up after 1 second instead of waiting for A. Session D only reads.

## Beginners often think…

- **"The `WHERE status = 'pending'` filter is enough: once one copy sends the email, the other copy will not see the row."** → Actually the other copy read the row before the first one committed `sent`, so it already holds the row in memory and sends it too. You notice this when a customer gets two identical emails while `notifications` holds a single row for that order.
- **"A locked row is hidden from every other query until the transaction ends."** → Actually a row lock only affects other transactions that try to lock or change the row. A plain `SELECT` reads it at once. You notice this when you query `notifications` while the sender is mid-batch: every claimed row is still there, still `pending`.

## Try it (3 minutes)

1. With the example system running (`scripts/up.sh`), predict what sessions B, C and D will print, then run `scripts/backend/skip-locked.sh` from the root folder of the example repository.
2. Compare the rows A and B got, and read C's line.

Expected result: when no real order email is waiting for a retry (its row would come first in the claim's order), A got `demo job 1` and `demo job 2`, B got `demo job 3` and `demo job 4`, C printed `ERROR:  canceling statement due to lock timeout` followed by a `CONTEXT:` line, and D sees all four demo jobs. The script deletes its demo rows when it ends.

## Connections

- [[backend.l2.database-job-queue]] — prerequisite: the queue that two copies of the sender now share.
- [[foundation.l1.transaction-intro]] — prerequisite: the transaction whose end releases every row lock.
- [[backend.l2.at-least-once-jobs]] — the other way a duplicate email appears: a crash between sending and committing, which row locks do not prevent.
- [[backend.l2.transactions-in-practice]] — a later lesson on what concurrent transactions see of each other's changes.

## Five-line summary

1. Claiming job rows with `FOR UPDATE SKIP LOCKED` inside a transaction lets several copies of a sender share one queue without taking the same row.
2. Every copy of the API runs its own `NotificationSender`; a plain `SELECT` lets two copies read and send the same `pending` row.
3. `FOR UPDATE` locks the returned rows; other lockers and writers wait until the transaction commits or rolls back.
4. `SKIP LOCKED` passes over rows already locked, so each copy claims a different small batch, sends it and commits.
5. A plain `SELECT` still reads locked rows, and a crash before the commit leaves the rows `pending` for the next claim.
