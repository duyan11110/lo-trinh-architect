---
id: backend.l1.hosting-and-program-cs
lang: en
track: backend
level: 1
stage: 1
module: web-server
main_path: true
title: "Program.cs: where an ASP.NET Core app starts"
duration_min: 12
skills: [backend.http.hosting]
prereqs: [backend.l1.what-kestrel-does]
related: []
vocab: [endpoint]
example_tag: stage-1
versions_used: [aspnetcore]
content_version: 1
status: draft
approved_by: null
reviewed_at: null
---

## Before you start

- [[backend.l1.what-kestrel-does]] — you know Kestrel accepts a connection and hands the request to your code; this lesson is about where that code begins.

## The situation

Kestrel hands a request to your code, the previous lesson said, but never showed where that code begins. You open `DonHang.Api/Program.cs` for the first time and find about seventy lines: some register things, some look like plain method calls, one is named `Run`. A teammate points at a single line, `app.MapControllers();`, and says "that line is what makes the API answer `/api/v1/products`." You do not see a URL anywhere near it. Where does an ASP.NET Core app actually start, and how does one line connect to a specific path?

## Core concepts

- WebApplicationBuilder — the object `WebApplication.CreateBuilder(args)` returns; an app registers what it needs on this object before anything runs.
- WebApplication — what `builder.Build()` produces; the same object the app configures next, and the object whose `Run()` call starts Kestrel.
- **endpoint** — a method-and-path pair mapped to handler code; a request reaches that code only when both match.

## How it works

```mermaid
flowchart LR
  A[CreateBuilder] --> B[Services.Add...]
  B --> C[Build]
  C --> D[wiring calls]
  D --> E[MapControllers]
  E --> F[Run]
```

`WebApplication.CreateBuilder(args)` returns a `WebApplicationBuilder`. Everything an ASP.NET Core app needs before it can run — a database connection, a way to issue tokens, and so on — gets registered on that one object, and the order these registrations happen in does not decide how a later request is answered; it only decides what is available for the app to use.

Calling `builder.Build()` closes that registration phase and produces the `WebApplication` itself, the object Program.cs configures next. Its `Run()` call, at the very end, is what actually starts Kestrel. Between `Build()` and `Run()`, Program.cs wires up the steps every incoming request will pass through before reaching your code; what order those wiring calls run in, and why it matters, is the next lesson's subject.

One of those wiring calls, `app.MapControllers()`, is what makes an **endpoint** exist at all: it looks at classes like `ProductsController` and turns each attribute-routed method on them into a method-and-path pair Kestrel can route a matching request to. `app.MapControllers()` itself runs once, at startup; it does not run again for every request — only the methods it finds do that.

## In the Đơn Hàng system

The registration half of `Program.cs` — before `Build()` — only ever adds things the app might need:

```csharp file=DonHang.Api/Program.cs tag=stage-1 lines=10-20
var builder = WebApplication.CreateBuilder(args);

// lesson: backend.l1.hosting-and-program-cs
builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("ConnectionStrings:Default is not set");
builder.Services.AddDonHangInfrastructure(connectionString);
builder.Services.AddScoped<OrderService>();
builder.Services.AddSingleton<JwtTokenService>();
```

`AddControllers()` is what makes `app.MapControllers()` further down able to find classes like `ProductsController` at all; the rest register a database connection, an order service, and a way to issue tokens. None of these lines decide how any one request gets answered — swapping their order changes nothing a client would ever see, because nothing here maps a path to anything yet.

`Build()` and `Run()` sit near the two ends of a longer block that also sets up the database schema and the wiring calls, none of them this lesson's subject:

```csharp file=DonHang.Api/Program.cs tag=stage-1 lines=52-74
var app = builder.Build();

// lesson: backend.l1.migrations
// Applies pending migrations on start, so a fresh `db` container ends up on
// the same schema a developer gets from `dotnet ef database update`.
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<DonHangDbContext>();
    MigrationBaseline.ApplyIfNeeded(context);
    context.Database.Migrate();
}

// lesson: backend.l1.middleware-pipeline
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

Read only the first and last lines for now: `builder.Build()` produces `app`, and `app.Run()` is the last thing Program.cs does. The lines in between (what runs against the database, and what order the wiring calls happen in) each belong to a different lesson. `app.MapControllers()` is the one line among them this lesson cares about: it is what turns attribute-routed methods on classes like `ProductsController` into real endpoints.

## Beginners often think…

- **"Program.cs only matters when the app starts; nothing in it affects how an individual request is handled later."** → Actually the wiring calls between `Build()` and `Run()` decide exactly how every later request is handled; only the `Services.Add...` order is free to vary. You notice this when reordering a wiring line changes what a request sees, and reordering a `Services.Add` line does not.
- **"`app.MapControllers()`'s handler code runs immediately, when that line executes, not when a matching request later arrives."** → Actually `app.MapControllers()` only registers which method-and-path pairs exist; each method's own body runs later, once per matching request. You notice this when a change you make inside one of these methods only shows up after you send a new request, never at startup.

## Try it (3 minutes)

1. With the lab running (`scripts/up.sh`), find the line `app.MapControllers();` in the quoted block above.
2. Run `curl http://localhost:8080/api/v1/products` twice.

Expected result: both calls print the same product list, computed fresh each time by that method — nothing about that list was computed back when `app.MapControllers()` itself ran, once, at startup.

<details><summary>Suggested answer</summary>

`app.MapControllers()` only recorded that a method exists for that path; the method itself runs on demand, which is why the same curl works twice with no restart in between.

</details>

## Connections

- [[backend.l1.what-kestrel-does]] — Kestrel is what `Run()` finally starts; this lesson is everything Program.cs sets up before that call.
- [[backend.l1.middleware-pipeline]] — the exact order of the wiring calls skipped over here.
- [[backend.l1.rest-resources]] — real endpoint design for Đơn Hàng: which paths exist and what each one should do, now that "endpoint" is a familiar word.

## Five-line summary

1. `WebApplication.CreateBuilder` returns a `WebApplicationBuilder`; `Build()` turns it into the `WebApplication` whose `Run()` call starts Kestrel.
2. The order `builder.Services.Add...` calls run in only decides what is available to the app, not how any request is handled.
3. An endpoint is a method-and-path pair mapped to handler code; `app.MapControllers()` creates one for every attribute-routed method it finds.
4. Such a method's code runs once per matching request, never when `app.MapControllers()` itself executes at startup.
5. What order the wiring calls between `Build()` and `Run()` happen in, and why that order matters, is the next lesson's subject.
