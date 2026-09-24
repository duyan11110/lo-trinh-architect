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

- **resource** — a thing named by a noun in the URL, like an order or a product; the URL says which thing, the HTTP method says what to do to it.
- collection URL — a URL naming every resource of one kind (`/api/v1/orders`); GET on it lists them all.
- item URL — a URL naming one specific resource (`/api/v1/orders/1`); GET on it reads just that one.
- method, not URL, carries the verb — the same item URL means something different depending on the method: GET reads it, PUT or PATCH changes it, DELETE removes it.

## How it works

```mermaid
flowchart LR
  A["/api/v1/orders"] -->|GET| B[list every order]
  A -->|POST| C[create one order]
  A --> D["/api/v1/orders/{id}"]
  D -->|GET| E[read one order]
  D -->|PUT or PATCH| F[change one order]
  D -->|DELETE| G[remove one order]
```

`/api/v1/orders` and `/api/v1/orders/{id}` are two different resources, not two spellings of one path — the plural, bare path names the whole collection, and adding an id narrows it to one item. Both accept several methods, and each method keeps its usual meaning from `foundation.l1.http-methods` no matter which of the two URLs it's applied to: GET always reads, POST always creates, and so on. Nothing about *what to do* lives in the URL itself; a path like `/api/v1/cancelOrder` tries to put a verb where a noun belongs, which is exactly what makes it a resource smell rather than a resource.

A collection and an item URL also don't share a method's job the same way. POST only makes sense on the collection (you don't "create" an id that doesn't exist yet), while PUT, PATCH and DELETE only make sense on an item (there's no single thing to replace, change, or remove when the URL names all of them at once).

## In the Đơn Hàng system

`ProductsController` maps one collection URL and the item URL under it, both with GET:

```csharp file=DonHang.Api/Controllers/ProductsController.cs tag=stage-1 lines=8-15
[ApiController]
[Route("api/v1/products")]
public sealed class ProductsController(DonHangDbContext db) : ControllerBase
{
    // lesson: backend.l1.get-and-status-codes
    [HttpGet]
    public async Task<ActionResult<List<ProductDto>>> List()
    {
```

`[Route("api/v1/products")]` on the class fixes the shared prefix once; `[HttpGet]` with no id, on `List()`, answers the bare collection URL, `GET /api/v1/products`. `OrdersController` shows the same pattern with an item URL added, plus a method besides GET:

```csharp file=DonHang.Api/Controllers/OrdersController.cs tag=stage-1 lines=9-13
// lesson: backend.l1.creating-a-resource
[ApiController]
[Route("api/v1/orders")]
public sealed class OrdersController(OrderService orderService, IOrderRepository repository) : ControllerBase
{
```

`[HttpPost]` (on `Create`, further down) answers `POST /api/v1/orders` — the collection URL, since creating an order adds to the whole set. `[HttpGet("{id:int}")]` (on `Get`) adds `{id}` to the shared prefix, answering the item URL, `GET /api/v1/orders/{id}`, for one order at a time. Nowhere in either file does a path spell out an action as a verb; `List`, `Get`, and `Create` are C# method names, not part of any URL.

## Beginners often think…

- **"A REST URL like `/api/v1/cancelOrder` is fine as long as it's clear what it does."** → Actually clarity isn't the test — a verb in the URL means the method can no longer carry that job, so every action needs its own path instead of reusing `/api/v1/orders` with a different method. You notice this once a second action, say "reopen an order", needs `/api/v1/reopenOrder` too, and the paths stop matching the small set of resources they actually touch.
- **"Creating an order and listing orders need two different URLs, since they're different actions."** → Actually they're the same URL, `/api/v1/orders`, answered by two different methods — POST creates, GET lists. You notice this in `OrdersController` and `ProductsController` above: one `[Route(...)]` per class, several methods answering the one path it names.

## Try it (3 minutes)

1. With the lab running (`scripts/up.sh`), run `curl -i http://localhost:8080/api/v1/products` (the collection URL, no id).
2. Then run `curl -i http://localhost:8080/api/v1/products/1` (the item URL, id `1`).

Expected result: the first returns `200` with a JSON array of every product; the second returns `200` with one product object, not wrapped in an array. Same `ProductsController`, same GET method's meaning both times — only the URL changed which resource it reads.

<details><summary>Suggested answer</summary>

`ProductsController` maps both URLs to two different methods: `List()` answers the bare collection URL and always returns an array, even if it later held zero or one product; `Get(int id)` answers the item URL and returns a single object, because `{id}` narrows the resource down to exactly one row before GET ever runs. The shape of the response comes from which URL you called, not from how many products happen to exist.

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
4. POST only fits a collection URL; PUT, PATCH, and DELETE only fit an item URL, since each needs exactly one resource to act on.
5. `/api/v1/cancelOrder` puts a verb where a noun belongs — the same job belongs on `/api/v1/orders/{id}` with the right method instead.
