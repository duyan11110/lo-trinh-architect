---
id: backend.l1.request-lifecycle
lang: en
track: backend
level: 1
stage: 1
module: web-server
main_path: true
title: "One request, from Kestrel to response"
duration_min: 14
skills: [backend.http.lifecycle]
prereqs: [backend.l1.middleware-pipeline]
related: []
vocab: []
example_tag: stage-1
versions_used: [aspnetcore]
content_version: 1
status: draft
approved_by: null
reviewed_at: null
---

## Before you start

- [[backend.l1.middleware-pipeline]] — you know middleware runs in registration order and any of it can short-circuit; this lesson follows one request the whole way through, out as well as in.

## The situation

You can now recite the order `DonHang.Api/Program.cs` puts things in: exceptions, logging, CORS, `UseAuthentication`, `UseAuthorization`, then the endpoint. A teammate points out two things that list alone cannot explain: `RequestLoggingMiddleware` logs a `401` it never caused, and `ExceptionHandlingMiddleware` still runs even when `UseAuthorization` rejects the request before the endpoint. What actually happens to a response between the moment it is decided and the moment the client receives it?

## Core concepts

- request lifecycle — the complete path one request takes: Kestrel, routing, every middleware in order, then the matched endpoint (or a short-circuit), then back out through the same middleware in reverse.
- routing — the automatic step that decides which endpoint a request's path and method match; it runs before any middleware and has no line of its own in `Program.cs`.
- on the way in — the first half of each middleware's work, the code before its `next` call, which every middleware up to a short-circuit runs once, in registration order.
- on the way out — the second half of each middleware's work, the code after its `next` call, which runs once a response exists, whichever step produced it.
- `context` — the `HttpContext` object each middleware is handed, holding both this one request and the response being built for it.

## How it works

```mermaid
sequenceDiagram
  participant C as Client
  participant K as Kestrel
  participant M1 as ExceptionHandlingMiddleware
  participant M2 as RequestLoggingMiddleware
  participant Z as UseAuthorization
  participant E as OrdersController.Create
  C->>K: request bytes
  K->>M1: request (routing already matched E)
  M1->>M2: next()
  M2->>Z: next()
  Z->>E: next() (if allowed)
  E-->>Z: response
  Z-->>M2: response
  M2-->>M1: response (now logged)
  M1-->>K: response
  K-->>C: response bytes
```

The diagram skips `UseCors` and `UseAuthentication` to keep the shape visible; the full six-step order is in "In the Đơn Hàng system" below. It also uses `OrdersController.Create` because this section's example is about a rejected request; the same shape applies to `OrdersController.Get`, the endpoint Try it uses below. In this pipeline, a request travels forward once: in through Kestrel, through routing, in through every middleware in registration order, then into the matched endpoint if nothing stopped it first. The response travels the same path backward, middleware by middleware, in the reverse of that order — the diagram's arrows going right are that forward trip; the arrows going left are the way out. When `UseAuthorization` does not allow the request, the `Z->>E` arrow never happens, and the response arrow starts at `Z` instead of `E`, then travels back through `M2` and `M1` exactly the same way.

`RequestLoggingMiddleware` is not guessing when it logs a status code: its own `next(context)` call has already returned, so a response now exists, whether the endpoint produced it or a short-circuit further down did. It reads `context.Response.StatusCode` only after that, on the way out — the answer is already there by the time its own code after `next` runs.

A short-circuit does not skip the way out; it only skips what comes after it on the way in. If `UseAuthorization` rejects a request, `ExceptionHandlingMiddleware` and `RequestLoggingMiddleware` — both registered before it — still run their after-`next` code, because from where they stand, `next` returned; a request that a middleware rejects still finishes the trip back through everything that ran before that middleware, including the exception handler.

## In the Đơn Hàng system

The whole trip is visible in one file, top to bottom:

```csharp file=DonHang.Api/Program.cs tag=stage-1 lines=65-74
// Order matters: exceptions caught first, then every request logged, then
// the terminal middleware (auth, routing) that decides how to answer it.
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

The comment's "terminal middleware" means the last calls able to answer a request outright instead of only passing it on — `UseAuthorization`, plus `UseAuthentication` right before it, which the comment's "auth" is short for even though `UseAuthentication` itself never rejects a request. The comment's "routing" is a different use of that word from the one in Core concepts: not the automatic matching that already happened before these six lines ran, but `app.MapControllers()`, the line that runs whichever method was matched.

Reading top to bottom names the forward order for these six calls: exception handling, logging, CORS, `UseAuthentication`, `UseAuthorization`, then the matched endpoint. `UseCors` and `UseAuthentication` are only names holding positions in that list here — what each one does is not this lesson's subject. The final `app.Run();` line is not a step of the trip either — it is the call that runs the app, starting the server that then listens for connections, and blocks until the app shuts down. Nothing in this file spells out the reverse order — it does not need to, because the reverse order is always exactly this list backward, for every request, whether it reaches `app.MapControllers()` or stops one line earlier, at `UseAuthorization`. A `POST /api/v1/orders` with no `Authorization` header travels in only as far as `UseAuthorization`, but travels out through `RequestLoggingMiddleware` and `ExceptionHandlingMiddleware` regardless — as you saw in the previous lesson's Try it.

## Beginners often think…

- **"The response leaves the app the moment the endpoint's code finishes, without passing back through the middleware that ran earlier."** → Actually the response travels back out through every middleware that called `next` on the way in, in reverse order, before Kestrel ever sends it. You notice this when `RequestLoggingMiddleware` reports a status code the endpoint decided several steps earlier.
- **"A request that a middleware rejects never reaches any of the app's own code at all, including the middleware after it."** → Actually "after it" is the part that never runs; middleware registered *before* the one that rejected the request still runs its own after-`next` code on the way back out. You notice this above, where a `POST /api/v1/orders` with no `Authorization` header still gets logged by `RequestLoggingMiddleware` even though `UseAuthorization` rejected it.

## Try it (3 minutes)

1. With the lab running (`scripts/up.sh`), run `curl -i http://localhost:8080/api/v1/orders/999999` (a `GET` for an order that does not exist). Any status line back means the lab is up; a connection error means it is not.
2. Run `docker compose logs api` and find the line for that request.

Expected result: curl prints `404`; the log line reads `GET /api/v1/orders/999999 responded 404 in ...ms`. Nothing about `OrdersController.Get`'s `404` was known to `RequestLoggingMiddleware` when the request went in — only on the way back out, once the endpoint had already decided, does the status code exist for it to log.

Question: how could `RequestLoggingMiddleware` log a `404` it never decided, without knowing anything about orders?

<details><summary>Suggested answer</summary>

`RequestLoggingMiddleware` reads `context.Response.StatusCode` after `await next(context)` returns, and by then the whole rest of the trip — every later middleware and `OrdersController.Get` itself — has already run and decided the answer. (Routing had already matched the endpoint before this middleware ever ran, so it plays no part in what happens after `next`.) The middleware does not know or care whether that answer came from the endpoint or from an earlier short-circuit; it logs whatever is there once its own `next` call comes back.

</details>

## Connections

- [[backend.l1.middleware-pipeline]] — the forward order and the idea of short-circuiting, which this lesson extends with the trip back out.
- [[backend.l1.what-kestrel-does]] — inside `DonHang.Api` itself, Kestrel is both ends of this trip: the first thing that sees the request and the last thing that sees the response before it leaves the app.
- [[backend.l1.errors-and-problem-details]] — the same reverse trip, read from the angle of what a middleware does with an error on the way back out.

## Five-line summary

1. In this pipeline, a request travels forward once: through Kestrel, routing, every middleware in order, then the matched endpoint, if nothing stopped it first.
2. The response travels the same path backward, through every middleware that ran on the way in, in the reverse of that order.
3. A middleware's after-`next` code runs once a response exists, whichever step — the endpoint or a short-circuit — actually produced it.
4. A short-circuit skips everything registered after it on the way in, but not the way out for middleware registered before it.
5. Reading `Program.cs` top to bottom gives you the forward order for its own middleware; the reverse order is always that same list backward.
