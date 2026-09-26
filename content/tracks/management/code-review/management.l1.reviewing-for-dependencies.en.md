---
id: management.l1.reviewing-for-dependencies
lang: en
track: management
level: 1
stage: 1
module: code-review
main_path: true
title: "What does this class depend on, and how"
duration_min: 13
skills: [management.review.dependencies]
prereqs: [management.l1.reviewing-for-layers, design.l1.solid-dip]
related: []
vocab: []
example_tag: stage-1
versions_used: [dotnet, aspnetcore]
content_version: 1
status: draft
---

## Before you start

- [[management.l1.reviewing-for-layers]] — you know how to check, in a diff, that each new piece of code sits in the layer that owns its kind of work.
- [[design.l1.solid-dip]] — you know high-level code should depend on an abstraction such as `INotifier`, not on a concrete class, and that `OrderPlacedTightlyCoupled` breaks this by creating its own `EmailNotifier`.

## The situation

A pull request adds a class that tells a customer their order has shipped. It works, the tests pass, and the code is short. Inside the class, one field is set with `new` to a concrete email sender. Another reviewer has already approved it with "looks good", and you have the diff open and five minutes. You could read every line of the new method, or you could look first at the top of the class: its `using` lines, its constructor and its fields. Why would those few lines tell you so much?

## Core concepts

- constructor parameter — a value a class asks for when it is created, instead of making it itself; this is how dependency injection hands it what it needs.
- reaching for a dependency — creating, inside the class itself, an object it calls to do its work, such as a notifier or a repository, instead of asking for it; building data such as a new `Order` does not count.
- public contract — the types a project is meant to be used through by other projects, often a C# `interface`, as opposed to the concrete classes it uses for its own work.

## How it works

```mermaid
flowchart TD
  C[new class in the diff] --> P[read its constructor and fields]
  C --> U[read its using lines]
  P --> A{asks for what it needs?}
  A -->|no, creates it with new| X[comment]
  A -->|yes, but a concrete class| K[worth a question]
  P --> N{how many parameters?}
  N -->|many| K
  P --> I{another project's contract or its details?}
  U --> I
  I -->|details| K
```

Reviewing for dependencies means reading how a new class gets what it needs, by eye, from the top of the class. The constructor lists what it asks for, the fields show anything it creates itself, and the `using` lines show which other projects' namespaces it brings in. The `using` lines are not a complete list: a type in the file's own namespace, or in a namespace that contains it, needs no `using`, and a project can add `using` lines for every file at once. So read the constructor's types too.

The first check is whether the class asks or reaches. A class that takes an `INotifier` in its constructor can be given any notifier, including a fake in a test. A class that creates its own concrete notifier with `new` cannot, and changing the channel means editing it; that is worth a comment even if the code works. A class that asks for a concrete class is in between: whoever creates it still chooses what to pass, so that is usually worth a question.

The second check is how many constructor parameters there are. No rule says how many is too many, but the Single Responsibility Principle (SRP) predicts that a class needing many different things probably does many jobs. A long list is a reason to ask what the class is responsible for, not a style complaint.

The third check is where each dependency comes from: an interface another project offers for others to use, or a concrete class that project uses for its own work. Using another project's contract keeps the two loosely coupled. Depending on its details ties them together more tightly with every such line, and a review question can stop that coupling before other code copies it.

## In the Đơn Hàng system

A sample in `samples/DonHang.Samples/Samples/Design/OrderNotifications.cs` shows the first check side by side:

```csharp file=samples/DonHang.Samples/Samples/Design/OrderNotifications.cs tag=stage-1 lines=9-23
public sealed class OrderPlacedTightlyCoupled
{
    private readonly EmailNotifier notifier = new();

    public void Handle(int orderId) => notifier.Send(orderId, "order placed");
}

// lesson: design.l1.dependency-injection-intro
// Same job, but this caller depends on INotifier — the abstraction both
// EmailNotifier and SmsNotifier already implement (Samples/Oop/NotifierBase.cs).
// Any INotifier works here, including a fake one in a test.
public sealed class OrderNotifications(INotifier notifier)
{
    public void Handle(int orderId) => notifier.Send(orderId, "order placed");
}
```

Read the two classes as if they arrived in a diff; the comment in the middle names notifiers from an earlier lesson, and only `INotifier` matters here. `OrderPlacedTightlyCoupled` has no constructor parameters; its field is created with `new()` as an `EmailNotifier`, a concrete class. A reviewer would comment: this class cannot be tested without that email sender, and switching to another channel means editing it. `OrderNotifications` asks for an `INotifier` in its constructor, so whoever creates it chooses the notifier.

The service that places and cancels orders, in `DonHang.Domain/OrderService.cs`, is declared as `OrderService(IOrderRepository repository, INotifier notifier)`: two constructor parameters, both interfaces declared in `DonHang.Domain` itself. Nothing in the file names a database class or the `DonHang.Infrastructure` project. It passes all three checks.

Now the login controller, in `DonHang.Api/Controllers/AuthController.cs`:

```csharp file=DonHang.Api/Controllers/AuthController.cs tag=stage-1 lines=1-11
using DonHang.Domain;
using DonHang.Infrastructure;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DonHang.Api.Controllers;

// lesson: backend.l1.validating-a-jwt
[ApiController]
[Route("api/v1/auth")]
public sealed class AuthController(DonHangDbContext db, JwtTokenService tokenService) : ControllerBase
```

The `using DonHang.Infrastructure;` line and the constructor say the same thing: `AuthController` takes `DonHangDbContext`, the concrete database class from the infrastructure project, not an interface. It also takes `JwtTokenService`, a concrete class from the API's own namespace, which is why no `using` names it; by the first check that is passed in, so worth a question at most. The two `Microsoft.*` lines bring in the web framework and the database library. In Đơn Hàng, what the infrastructure project offers the business layer is mainly its implementations of interfaces from `DonHang.Domain`, such as `IOrderRepository`; `DonHangDbContext` is the class it uses to do that work. A reviewer can ask whether the controller could depend on such an interface instead of the database class, which is the same question the layers review asked from another side.

## Beginners often think…

- **"Counting constructor parameters is a style nitpick, not a real design concern."** → Actually the constructor is the first place a class that does too many jobs shows it, because each job needs its own things. You notice this when a class with a long parameter list has to change for several unrelated reasons, and every change risks the others.
- **"A dependency issue in new code isn't worth commenting on unless it's already causing a bug."** → Actually the cost of a hard-wired dependency shows up later, when someone needs to test the class or change what it uses, and by then other code may copy it. You notice this when writing a unit test for a class like `OrderPlacedTightlyCoupled` means sending a real email, because nothing lets you pass in a fake.

## Try it (3 minutes)

Open `DonHang.Api/Controllers/OrdersController.cs` from the repository at stage-1.

1. Write down the constructor parameters of `OrdersController`, and whether each is a concrete class or an interface.
2. Look at the `using` lines and write down which Đơn Hàng projects the controller uses.
3. Decide whether you would leave a dependency comment, and write it in one sentence if so.

Expected result: step 1 — `OrderService`, a concrete class, and `IOrderRepository`, an interface. Step 2 — `DonHang.Domain` only; there is no `using DonHang.Infrastructure;`, and types from `DonHang.Api`, a namespace that contains the controller's own, need no `using`. Step 3 — a question is reasonable, for example: "`OrderService` is a concrete class; would an interface make this controller easier to test on its own?" Either answer can be right; the point is that you looked.

A teammate says: "`OrdersController` takes a concrete `OrderService`, so it breaks the same rule as `OrderPlacedTightlyCoupled`." Is that the same problem?

<details><summary>Suggested answer</summary>

Not quite. `OrdersController` still asks for `OrderService` in its constructor, so whoever creates it chooses which object to pass; in the API, the web framework creates the controller and the DI container supplies what its constructor asks for. `OrderPlacedTightlyCoupled` creates its own `EmailNotifier` with `new`, so nobody outside can choose. Depending on a concrete class that is passed in is usually a smaller concern than creating one yourself, because the caller can still choose what to pass; the first can be worth a question, the second is worth a clear comment.

</details>

## Connections

- [[management.l1.reviewing-for-layers]] — the previous check: is the code in the right layer.
- [[management.l1.reviewing-for-tests]] — the next check: does the test actually check the new behavior.
- [[design.l1.dependency-injection-intro]] — how a class receives its dependencies instead of creating them.

## Five-line summary

1. Reviewing for dependencies reads a new class's constructor and `using` lines, by eye.
2. A class that creates its own concrete dependency with `new` cannot be given a fake, and is worth a comment.
3. Many constructor parameters suggest, by SRP, that a class does several jobs, which is worth asking about.
4. Depending on another project's concrete details instead of an interface tightens coupling that review can stop early.
5. `OrderService` asks for two interfaces from its own project; `AuthController` takes the infrastructure project's concrete `DonHangDbContext`.
