---
id: backend.l1.querying-with-linq
lang: en
track: backend
level: 1
stage: 1
module: orm-efcore
main_path: true
title: "LINQ compiles to SQL, it doesn't run in C#"
duration_min: 14
skills: [backend.ef.querying]
prereqs: [backend.l1.migrations, foundation.l1.sql-join]
related: []
vocab: []
example_tag: stage-1
versions_used: [efcore]
content_version: 1
status: draft
approved_by: null
reviewed_at: null
---

## Before you start

- [[backend.l1.migrations]] — you know the schema a migration builds is what a query actually runs against.
- [[foundation.l1.sql-join]] — you know a JOIN pairs rows of two tables on a condition, usually a foreign key equalling the primary key it points to.

## The situation

A teammate is reading `EfOrderRepository.ListByCustomerAsync`, one line: `db.Orders.Where(o => o.CustomerId == customerId).Include(o => o.Customer).OrderBy(o => o.Id).ToListAsync()`. To see what `.Where(...)` alone produces, they copy the first step onto its own line: `var query = db.Orders.Where(o => o.CustomerId == customerId);`.

They expect `query` to already hold one customer's orders. Its declared type is `IQueryable<Order>` — not a `List<Order>`, and no rows anywhere in sight. Does `.Where(...)` filter in PostgreSQL, the database Đơn Hàng runs on, or does it load every order into C# first? And if nothing ran at `.Where(...)`, when does it?

## Core concepts

- LINQ — the chain of C# method calls, `.Where(...)`, `.Include(...)`, `.OrderBy(...)`, written against a `DbSet` like `db.Orders` (the property standing for the `orders` table). A LINQ query builds up a description of a query, not a result; `db.Orders.Where(...)` returns another queryable, with the condition attached to it. `db.Orders` is itself one of these queryables, so further calls chain onto the result the same way they chain onto `db.Orders`.
- deferred execution — that description only reaches PostgreSQL once something asks it for actual rows: `.ToListAsync()`, `.FirstOrDefaultAsync()`, a `foreach`, or any similar call. Writing `db.Orders.Where(...)` alone runs nothing.
- `.Include(...)` — an EF Core call chained into a LINQ query, naming related rows to load in the same query, following a foreign key to another table (`o.Customer` is the customer row `o.CustomerId` points at); by default, EF Core folds it into the one SQL statement as a JOIN, the same JOIN already familiar from writing SQL directly.

## How it works

```mermaid
flowchart LR
  A[db.Orders.Where] -->|builds a description, no DB call| B[queryable]
  B -->|.Include, .OrderBy add to it| C[queryable, JOIN + ORDER BY attached]
  C -->|.ToListAsync enumerates it, sending one SQL statement| D[(PostgreSQL)]
  D -->|rows, each Order carrying its Customer| E[List of Order]
```

`Where`, `Include`, and `OrderBy` don't run anything by themselves — each one takes the queryable it's called on and returns a new queryable, one step longer, the way string methods return a new string. Nothing reaches PostgreSQL until the chain is enumerated; only a call that asks for results does that — `.ToListAsync()`, `.FirstOrDefaultAsync()`, a `foreach` over the query. At that moment, EF Core translates the whole chain built up to then into one SQL statement, sends it once, and PostgreSQL runs the filtering, the ordering, and the JOIN there, not in C# afterward.

This is why `query`, right after `.Where(...)`, is an `IQueryable<Order>` and not a `List<Order>` — its declared type shows `.Where(...)` handed back a query, not a result, and an EF Core query is not sent to PostgreSQL until something enumerates it. The `.Include(o => o.Customer)` step works the same way — it doesn't run a second query for the related `Customer` row; it extends the one SQL statement with a JOIN, so the single `.ToListAsync()` at the end still sends only one query, returning `Order` rows already carrying their `Customer`.

`ListByCustomerAsync` chains four calls: `.Where(...)` for the filter, `.Include(...)` for the JOIN, `.OrderBy(...)` for the order — three that only extend the description — then `.ToListAsync()`, the one that finally runs it. `FindAsync` is shorter — `.Include(...)` then `.FirstOrDefaultAsync(...)` — but the same rule applies: one SQL statement, built from the whole chain, run only when that last call is made.

## In the Đơn Hàng system

`EfOrderRepository`, in `DonHang.Infrastructure/EfOrderRepository.cs`, has two queries built the way described above. The `// lesson:` comments in it are cross-references to other lessons in this example codebase, not part of the query itself:

```csharp file=DonHang.Infrastructure/EfOrderRepository.cs tag=stage-1 lines=1-19
using DonHang.Domain;
using Microsoft.EntityFrameworkCore;

namespace DonHang.Infrastructure;

// lesson: design.l1.the-repository-layer
public sealed class EfOrderRepository(DonHangDbContext db) : IOrderRepository
{
    public Task<Order?> FindAsync(int id) =>
        db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id);

    // lesson: backend.l1.efcore-n-plus-one
    public Task<List<Order>> ListByCustomerAsync(int customerId) =>
        db.Orders.Where(o => o.CustomerId == customerId).Include(o => o.Customer).OrderBy(o => o.Id).ToListAsync();

    public async Task AddAsync(Order order) => await db.Orders.AddAsync(order);

    public Task SaveChangesAsync() => db.SaveChangesAsync();
}
```

`db`, used in every query here, is the `DonHangDbContext` this class is given when it's created — `(DonHangDbContext db)` on the class line — the object `db.Orders` belongs to. `FindAsync(id)` chains `.Include(o => o.Items)` then `.FirstOrDefaultAsync(o => o.Id == id)`: one order, its `Items` — the order's line-item rows in the related `order_items` table, paired in by the foreign key pointing back at this order — joined in, one SQL statement. `ListByCustomerAsync(customerId)` chains `.Where(...)`, `.Include(o => o.Customer)`, `.OrderBy(o => o.Id)`, then `.ToListAsync()`: every step adds to the same description, and only the last one runs it. `AddAsync` and `SaveChangesAsync` are different — they don't build a queryable at all, and are not this lesson's subject. Neither query method writes `async`/`await` — each is one expression, so the chain's own `Task` is returned directly.

## Beginners often think…

- **"A LINQ query loads every row into memory first, and `.Where(...)` filters the C# list afterward."** → Actually `.Where(...)` never loads anything; it extends the query description, and EF Core turns the whole chain into a `WHERE` clause PostgreSQL evaluates before any row leaves the database. You notice this in the one SQL statement EF Core sends: it carries a `WHERE customer_id = ...` (with the `ORDER BY` from `.OrderBy(...)` after it), so other customers' rows never leave the database at all, instead of arriving in C# and getting discarded there.
- **"Writing `db.Orders.Where(o => o.CustomerId == customerId)` runs the query immediately, the moment that line executes, rather than when `.ToListAsync()` is awaited."** → Actually that line only builds a queryable object; nothing is sent to PostgreSQL until something enumerates it. You notice this when a variable holding that line's result has type `IQueryable<Order>`, not `List<Order>` — the `List<Order>` only ever appears as what `.ToListAsync()` hands back.

## Try it (3 minutes)

1. From the Đơn Hàng project's root folder, with the example system running (`scripts/up.sh`), run `curl -s -X POST http://localhost:8080/api/v1/auth/login -H "Content-Type: application/json" -d '{"email": "anh.tran@example.com", "password": "donhang-dev-password"}'`. Take the `token` field from the response — it's what tells the next request which customer is signed in — and run `curl -s http://localhost:8080/api/v1/orders -H "Authorization: Bearer <token>"`, with that value in place of `<token>`.
2. Repeat step 1 with `{"email": "chau.nguyen@example.com", "password": "donhang-dev-password"}`, another account already in the example data, and compare the two `GET /api/v1/orders` responses.

Expected result: two different lists from the same code path — each request reaches PostgreSQL only at `.ToListAsync()`, and the `WHERE` in that one statement is why only that signed-in customer's own rows come back.

<details><summary>Suggested answer</summary>

`ListByCustomerAsync` builds `db.Orders.Where(o => o.CustomerId == customerId)` fresh on every call, with whichever `customerId` came from that request's signed-in customer; the filter is not a fixed list computed once. Because the filtering happens in the one SQL statement `.ToListAsync()` sends, each request's PostgreSQL query only returns that customer's own rows — never a shared, precomputed list that both requests read from.

</details>

## Connections

- [[backend.l1.migrations]] — the schema `Where`/`Include`/`OrderBy` translate against; a column a migration never added cannot appear in the SQL these calls build.
- [[backend.l1.efcore-n-plus-one]] — what goes wrong when a query runs once per loop iteration instead of once, deferred execution's opposite failure.

## Five-line summary

1. A LINQ query against a `DbSet` builds up a description of a query; calling `.Where(...)`, `.Include(...)`, or `.OrderBy(...)` extends that description without running anything.
2. Deferred execution: the description only reaches PostgreSQL once something enumerates it — `.ToListAsync()`, `.FirstOrDefaultAsync()`, a `foreach`.
3. At that moment, EF Core translates the whole chain into one SQL statement; PostgreSQL does the filtering, ordering, and joining, not C# afterward.
4. `.Include(...)` adds a JOIN to that one statement; it does not run a second query for the related data.
5. Right after `.Where(...)`, a variable's declared type is still `IQueryable<Order>`, not `List<Order>` — no rows have been fetched until something enumerates it.
