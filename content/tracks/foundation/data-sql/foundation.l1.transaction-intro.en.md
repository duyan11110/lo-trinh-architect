---
id: foundation.l1.transaction-intro
lang: en
track: foundation
level: 1
stage: 0
module: data-sql
main_path: true
title: "Transactions: all or nothing"
duration_min: 12
skills: [foundation.sql.transaction]
prereqs: [foundation.l1.sql-write]
related: [backend.l2.transactions-in-practice, design.l3.outbox-pattern]
vocab: [transaction]
example_tag: stage-0
versions_used: [postgresql]
content_version: 1
status: reviewed
approved_by: null
reviewed_at: "2026-09-17T05:16:15+07:00"
---

## Before you start

- [[foundation.l1.sql-write]] — you write `INSERT`, `UPDATE` and `DELETE`, you check a command tag against the row count you expected, and you have run a file that wraps three writes between `BEGIN` and `ROLLBACK` so the lab ends as it started. This lesson says what that pair promises.

## The situation

Vũ Gia Khánh, the one customer who has never ordered in the lab database you start with `scripts/up.sh`, is finally placing an order: one `Tai nghe` at 890,000 đồng. That takes two writes — a row in `orders`, then a row in `order_items` for the item bought. You run the first `INSERT` and it succeeds; you run the second and the database refuses it, because you typed a quantity of `0` and the table only accepts quantities above zero. The first row is already there. The shop now has an order containing nothing, and the shop finds out about it weeks later. How do you make two writes behave as one?

## Core concepts

- **transaction** — a group of statements the database treats as one unit of work: either the changes of all of them survive, or the changes of none of them do.
- `BEGIN` — the statement that opens a transaction block; every statement after it belongs to the same unit until the block ends.
- `COMMIT` — the statement that ends the block by keeping it: the unit's changes become permanent and other connections start seeing them.
- `ROLLBACK` — the statement that ends the block by discarding it: the database returns to the state it had before the `BEGIN`, however many rows the block had already written.
- atomicity — the guarantee that a transaction is indivisible from the outside: no one ever sees half of it, not another connection and not the database after a crash.
- ACID — the four letters naming the guarantees a transaction carries: atomicity, consistency, isolation and durability. This lesson covers atomicity only; the other three are named here so you recognise the word when you meet it, and come in later lessons.

## How it works

```mermaid
sequenceDiagram
  participant Y as You
  participant D as PostgreSQL
  participant O as Another connection
  Y->>D: BEGIN, then INSERT into orders
  O->>D: SELECT count(*) FROM orders
  D-->>O: 12 — your new row is not there
  Y->>D: INSERT into order_items — refused
  Y->>D: ROLLBACK
  D-->>Y: the order row is gone too
```

In the situation above, the two `INSERT`s were separate statements, and PostgreSQL ran each one as its own unit: it opened one, applied the statement, ended it. That is why the row in `orders` stayed behind when the second write was refused.

`BEGIN` changes that. From `BEGIN` until the block ends, every statement you send belongs to one unit. Your own connection sees the changes as they happen — a count inside the block answers 13 orders — but nothing has left the unit. The connection on the right of the diagram — another person connected to the same database from their own terminal — counts at the same moment and is told 12. It is not reading old data: the thirteenth order does not yet exist for anyone but you.

Two statements end the block on purpose. `COMMIT` keeps every change the unit made, and only then do other connections see them; the database first writes enough to disk that a machine losing power a second later still has the order. `ROLLBACK` discards the unit, whatever it had already written: in the diagram only the second `INSERT` was refused, but the `ROLLBACK` takes the `orders` row with it too.

You do not always pick which one runs. When a statement inside the block fails, PostgreSQL refuses every later command until the block is ended, and the block can no longer be kept: however you end it, none of its changes survive. When your connection drops with the block still open, the server rolls it back.

While the block is open, the rows it changed are held: another transaction that wants to change the same rows waits for yours to end. That is why an open block is a thing to close quickly.

## In the Đơn Hàng system

`db/queries/transaction-place-order.sql` places Khánh's order — this time with a quantity the table accepts — then takes it back, so the lab ends with the same twelve orders it started with. `scripts/sql/run-query.sh` sends the whole file over one connection, so all three counts come from the same connection as the two `INSERT`s.

```sql file=db/queries/transaction-place-order.sql tag=stage-0 lines=4-20
SELECT count(*) AS orders_before FROM orders;

-- lesson: foundation.l1.transaction-intro
BEGIN;

INSERT INTO orders (id, customer_id, placed_at, status)
VALUES (13, 5, '2026-04-01 09:00:00+07', 'new');

INSERT INTO order_items (order_id, product_id, quantity, unit_price_vnd)
VALUES (13, 3, 1, 890000);

SELECT count(*) AS orders_inside_transaction FROM orders;

ROLLBACK;

-- Nothing survived the rollback, including the order the first INSERT created.
SELECT count(*) AS orders_after_rollback FROM orders;
```

Read the three counts, because they are the whole lesson. The first answers 12, the lab's own orders. The second count sits inside the block, after both `INSERT`s, and answers 13 — your connection sees what your own unit has written. The last one runs after `ROLLBACK` and answers 12 again.

The two writes belong together for a reason the tables state. `order_items.order_id` references `orders.id`, so the second row cannot exist without the first; and `quantity` is declared to be above zero, which is the refusal in the situation. A file that ends in `COMMIT` instead would leave both rows, and this file would then print 13 the next time it ran.

This file writes the id `13` itself instead of asking the table for the next generated one, so it needs no clean-up line at the end.

## Beginners often think…

- **"Each statement is independent, so a failure halfway leaves the database consistent."** → Actually each statement is atomic on its own, and that is all PostgreSQL promises you outside a block: the refused statement leaves nothing, and the statements that already succeeded stay. Keeping two tables in step is a rule of your shop, not of one statement. You notice this when the situation above reaches the shop: `orders` holds a row that `order_items` has nothing for, no error is left anywhere, and the order turns up weeks later in a report as an order worth nothing.
- **"Wrapping my writes in a transaction makes the code run faster."** → Actually a transaction decides what survives, not how fast anything runs. Grouping many small writes does cut how often the database writes to disk, so a long run of `INSERT`s can finish sooner. But every row the block has changed stays held until it ends, so a block kept open to be "efficient" makes every other write to those rows wait. You notice this when a job that opens a block, writes one row and waits for a person to answer a question turns a one-second write into a queue behind it.

## Try it (3 minutes)

1. Start the lab with `scripts/up.sh`, then run `scripts/sql/run-query.sh transaction-place-order`. Read the three counts in the order they print.
2. Open `db/queries/transaction-place-order.sql` and change the quantity `1` to `0` in the `order_items` `INSERT`, so that write breaks the rule the table declares. Run the same command again, then put the `1` back and run it a third time.

Expected result: the first run prints `orders_before` 12, `orders_inside_transaction` 13, `orders_after_rollback` 12. The second run prints 12, accepts the `INSERT` into `orders`, and then stops on the refusal of the second one: the runner ends the file at the first error and prints the refusal message, so neither of the later counts runs. The third run prints 12 again: the interrupted block left nothing behind, because the run stopped at the refusal and the connection closed with the block still open, and the server rolls such a block back.

## Connections

- [[foundation.l1.sql-write]] — the lesson this one completes: there you made one row change at a time, here you decide which changes stand together.
- [[foundation.l1.tables-keys-relations]] — the foreign key declared there is why an order and its items have to be written as one unit.
- [[backend.l2.transactions-in-practice]] — the same idea one layer up, where the block is opened by application code instead of by a line in a file.
- [[design.l3.outbox-pattern]] — the answer to what you do when the two things that must happen together are a database write and a message to another system, which no single transaction covers.

## Five-line summary

1. A transaction is a group of statements whose changes all survive or all disappear, which is how two writes become one unit of work.
2. `BEGIN` opens the block, `COMMIT` keeps it and makes it visible to others, `ROLLBACK` discards it.
3. Outside a block every statement is its own transaction, so a failure halfway through a sequence of writes leaves the earlier ones standing.
4. Anything that goes wrong inside a block — a refused statement, a lost connection — ends with nothing written.
5. An open block holds the rows it changed against every other write, so keep transactions short and never wait for a person inside one.
