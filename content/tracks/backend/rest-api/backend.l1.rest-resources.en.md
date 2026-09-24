---
id: backend.l1.rest-resources
lang: en
track: backend
level: 1
stage: 1
module: rest-api
main_path: true
title: "The URL is a noun, the method is the verb"
duration_min: 12
skills: [backend.rest.design]
prereqs: [backend.l1.hosting-and-program-cs, foundation.l1.http-methods]
related: []
vocab: [resource]
example_tag: stage-1
versions_used: [aspnetcore]
content_version: 1
status: draft
approved_by: null
reviewed_at: null
---

## Before you start

- [[backend.l1.hosting-and-program-cs]] — you know an endpoint is a method-and-path pair, and that `app.MapControllers()` finds these pairs on classes like `ProductsController`.
- [[foundation.l1.http-methods]] — you know GET reads, POST creates, PUT replaces, PATCH partly changes, and DELETE removes.

## The situation

A teammate asks you to add a way to cancel an order and proposes the path `/api/v1/cancelOrder`. It works — you could write a method that answers it — but something about it doesn't sit right next to `/api/v1/orders`, the path Đơn Hàng already uses to create and read orders. What should decide a new endpoint's path, if not just "whatever makes the action clear"?

## Core concepts

- **resource** — by this lesson's convention, a thing named by a noun in the URL (the path half of the method-and-path pair from the last lesson), like an order or a product; the URL says which thing, the HTTP method says what to do to it.
- collection URL — a URL naming every resource of one kind (`/api/v1/orders`); GET on it lists them all.
- item URL — a URL naming one specific resource (`/api/v1/orders/1`); GET on it reads just that one.
- method, not URL, carries the verb — the same item URL means something different depending on the method: GET reads it, PUT or PATCH changes it, DELETE removes it.

## How it works

```mermaid
flowchart LR
  A["/api/v1/orders"] -->|GET| B[list every order]
  A -->|POST| C[create one order]
  A -->|add id| D["/api/v1/orders/{id}"]
  D -->|GET| E[read one order]
  D -->|PUT or PATCH| F[change one order]
  D -->|DELETE| G[remove one order]
```

This diagram is the general pattern every resource can follow, not a promise that Đơn Hàng answers every branch of it today — its own orders collection, below, has no GET yet.

`/api/v1/orders` and `/api/v1/orders/{id}` are two different resources, not two spellings of one path — the plural, bare path names the whole collection, and adding an id narrows it to one item. Both accept several methods, and each method keeps its usual meaning from [[foundation.l1.http-methods]] no matter which of the two URLs it's applied to: GET reads, POST hands the collection something to process — creating a new order, in Đơn Hàng's case — and so on. The resource's own name never becomes the verb; where an action needs a name of its own, it is appended after the item URL instead of replacing it, as the Đơn Hàng section below shows. A path like `/api/v1/cancelOrder` tries to put a verb where a noun belongs, which is why it is not a resource name under this convention.

By convention, POST goes on the collection URL and PUT, PATCH, and DELETE go on an item URL, because each of those three acts on one specific resource, so the URL has to name that one and not the whole set. HTTP itself does not enforce this split — it is a convention this lesson and Đơn Hàng both follow, not a rule the protocol checks.

## In the Đơn Hàng system

Every resource in Đơn Hàng follows the same shape: one `/api/v1/<plural-noun>` prefix per class, then one method per thing that prefix needs to do. Only the `[Route(...)]` and `[Http...]` lines matter for this lesson; the rest — parameter types, what each method's body does — belongs to later lessons. `ProductsController` maps its collection URL and the item URL under it, both with GET:

```csharp file=DonHang.Api/Controllers/ProductsController.cs tag=stage-1 lines=8-28
[ApiController]
[Route("api/v1/products")]
public sealed class ProductsController(DonHangDbContext db) : ControllerBase
{
    // lesson: backend.l1.get-and-status-codes
    [HttpGet]
    public async Task<ActionResult<List<ProductDto>>> List()
    {
        var products = await db.Products
            .Select(p => new ProductDto(p.Id, p.Name, p.PriceVnd))
            .ToListAsync();
        return Ok(products);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ProductDto>> Get(int id)
    {
        var product = await db.Products.FindAsync(id);
        if (product is null) return NotFound();
        return Ok(new ProductDto(product.Id, product.Name, product.PriceVnd));
    }
```

`[Route("api/v1/products")]` on the class fixes the shared prefix once; `[HttpGet]` with no id, on `List()`, answers the bare collection URL, `GET /api/v1/products`. `[HttpGet("{id:int}")]`, on `Get(int id)`, adds `{id}` to that prefix — a placeholder the actual id in the request fills in, with `:int` saying only a whole number matches — answering the item URL, `GET /api/v1/products/{id}`, the one Try it calls below.

`OrdersController` carries the same class-level attribute, `[Route("api/v1/orders")]`, and a `[HttpPost]` method, `Create`, answering the collection URL, `POST /api/v1/orders` (creating an order adds to the whole set — not shown again here, same shape as `[Route(...)]` above). Further down the same class, two more methods answer the item URL and the teammate's question from the situation above:

```csharp file=DonHang.Api/Controllers/OrdersController.cs tag=stage-1 lines=30-46
    [HttpGet("{id:int}")]
    public async Task<ActionResult<OrderDto>> Get(int id)
    {
        var order = await repository.FindAsync(id);
        if (order is null) return NotFound();
        return Ok(ToDto(order));
    }

    // lesson: management.l1.reviewing-for-tests
    // Deliberately missing a check: see OrderService.CancelOrderAsync.
    [Authorize]
    [HttpPatch("{id:int}/cancel")]
    public async Task<ActionResult<OrderDto>> Cancel(int id)
    {
        var order = await orderService.CancelOrderAsync(id);
        return Ok(ToDto(order));
    }
```

`[HttpGet("{id:int}")]` answers the item URL, `GET /api/v1/orders/{id}`, for one order at a time — the same shape as `ProductsController.Get` above. `[HttpPatch("{id:int}/cancel")]`, on `Cancel`, is the teammate's real answer: `PATCH /api/v1/orders/{id}/cancel`, not `/api/v1/cancelOrder`. The order's own path, `/api/v1/orders/{id}`, never disappears; `cancel` is a named action of its own — the server decides what cancelling means, instead of a client writing a status field directly — so it gets a segment after the item URL rather than replacing it.

Not every `/api/v1/...` path names a resource this way. A third class, `AuthController`, groups its one endpoint under the prefix `/api/v1/auth`: `POST /api/v1/auth/login`. `login` is a verb, same as `cancel` — and that's fine for the same reason: no order, product, or other thing is being named here, so no noun is being pushed aside for it. `/api/v1/cancelOrder` is different because an order already exists and already has its own path to keep.

## Beginners often think…

- **"A URL like `/api/v1/cancelOrder` is fine as long as it's clear what it does."** → Actually clarity isn't the test, and the fix isn't a brand-new top-level path either. Đơn Hàng's real fix for exactly this action is `PATCH /api/v1/orders/{id}/cancel`: the order's own path survives, with `cancel` added after it. You notice this in `OrdersController` above, where the resource's URL stays intact even for an action that isn't a plain PUT or a plain field change.
- **"Creating an order and listing orders need two different URLs, since they're different actions."** → Actually they'd be the same URL, `/api/v1/orders`, answered by whichever methods that resource needs — POST creates, as `OrdersController.Create` does; GET would list, as `ProductsController.List` does for products. `OrdersController` and `ProductsController` are different classes, same pattern: Đơn Hàng just hasn't needed a GET that lists every order yet.
- **"The `v1` in `/api/v1/orders` refers to the version of each individual order, not this whole set of endpoints."** → Actually `v1` is fixed once for every endpoint this server answers, not per order: `/api/v1/orders/1` and `/api/v1/orders/2` carry the same `v1` even after one order has changed status several times and the other never has.

## Try it (3 minutes)

1. From the Đơn Hàng project's root folder, start the lab with `scripts/up.sh`, then run `curl -i http://localhost:8080/api/v1/products` (the collection URL, no id).
2. Then run `curl -i http://localhost:8080/api/v1/products/1` (the item URL, id `1`).

Expected result: the first returns `200` with a JSON array of every product; the second returns `200` with one product object, not wrapped in an array. Same `ProductsController`, same GET method's meaning both times — only the URL changed which resource it reads.

<details><summary>Suggested answer</summary>

`ProductsController` maps both URLs to two different methods: `List()` answers the bare collection URL and always returns an array, even if it later held zero or one product; `Get(int id)` answers the item URL, taking `{id}` from the URL as its own parameter and using it to ask the database for exactly one product. That per-request lookup, not something decided before GET runs, is what makes the response a single object instead of an array.

</details>

## Connections

- [[backend.l1.hosting-and-program-cs]] — the endpoint concept this lesson turns into a naming convention.
- [[foundation.l1.http-methods]] — the method meanings this lesson keeps fixed across every resource.
- [[backend.l1.dtos-and-serialization]] — the shape of what these endpoints actually return.
- [[backend.l1.get-and-status-codes]] — the status codes `List()` and `Get()` should return, beyond the `200`s seen here.

## Five-line summary

1. A resource is a thing named by a noun in the URL; the HTTP method, not the URL, says what to do to it.
2. A collection URL (`/api/v1/orders`) and an item URL (`/api/v1/orders/1`) are two different resources, not two spellings of one.
3. GET on a collection lists everything; GET on an item reads just that one — the method's meaning never changes between them.
4. POST usually fits a collection URL; PUT, PATCH, and DELETE usually fit an item URL, since each acts on one resource, not the whole set.
5. `/api/v1/cancelOrder` puts a verb where a noun belongs — Đơn Hàng's fix keeps the order's own path, adding the action after it: `PATCH /api/v1/orders/{id}/cancel`.
