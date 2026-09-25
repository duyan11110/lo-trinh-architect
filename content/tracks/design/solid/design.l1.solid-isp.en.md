---
id: design.l1.solid-isp
lang: en
track: design
level: 1
stage: 1
module: solid
main_path: true
title: "ISP: small interfaces, nobody implements what they don't use"
duration_min: 13
skills: [design.solid.isp]
prereqs: [design.l1.solid-lsp]
related: []
vocab: [isp]
example_tag: stage-0
versions_used: [dotnet]
content_version: 1
status: draft
approved_by: null
reviewed_at: null
---

## Before you start

- [[design.l1.solid-lsp]] — you know every class behind a base type must keep that type's promise, so callers never have to check which one they got.

## The situation

A teammate wants every notification channel to "look the same", so they propose one interface, `INotificationChannel`, with four methods: `SendEmail`, `SendSms`, `SendPush` and `GetDeliveryReport`. Then they try to make `SmsNotifier` implement it. It can send an SMS, but what should its `SendEmail` do? Its `SendPush`, or its `GetDeliveryReport`, when nothing in the samples tracks delivery at all? And code that sends an order confirmation — imagined for this lesson — would call only one of the four, yet depend on all of them. What went wrong with an interface that looked so complete?

## Core concepts

- **Interface Segregation Principle (ISP)** — no code should be forced to depend on methods it does not use; when the code that calls or implements an interface needs different parts of it, split it into small, focused interfaces instead of one large one.
- depend on — code depends on an interface when it implements it or calls through it; implementers must change when its methods change, and callers can only be given classes that provide all of it.
- fat interface — an interface with methods that some of its implementers or callers have no use for.

## How it works

```mermaid
flowchart LR
  S[SmsNotifier under the proposal: 1 real, 3 filler] -->|implements| F[INotificationChannel: 4 methods]
  C[confirmation code: calls 1] -->|asks for| F
  B[NotifierBase] -->|implements| I[INotifier: Send]
  E[EmailNotifier] -->|derives from| B
  M[SmsNotifier] -->|derives from| B
```

The left half of the diagram is the proposal; the right half is what the samples have today. A fat interface hurts on two sides.

On the implementing side, C# requires a class to provide every method the interface declares, apart from any the interface gives a body of its own — and none of these four has one. `SmsNotifier` has real behaviour for `SendSms` only, so the other three get filler: an empty body, a made-up result, or an exception. And if someone changes the parameters of `GetDeliveryReport`, every implementing class must change, `SmsNotifier` included, even though nothing it does is about delivery reports.

On the calling side, the order confirmation code uses one method but asks for an `INotificationChannel`, so it can only be given classes that provide all four. A class that can send an SMS and nothing else cannot be handed to it without filler. If that filler throws, the promise from the LSP lesson breaks: code that holds an `INotificationChannel` may call `SendEmail` and has no way to know this one will fail.

ISP's answer is to cut interfaces along what the code that calls or implements them needs. Code that sends a message about an order needs one thing: a way to send it. That is exactly what `INotifier` offers, and `EmailNotifier` and `SmsNotifier` implement it through `NotifierBase`. If delivery reports are ever needed, they belong in a separate interface that only reporting code uses and only classes that can report implement.

## In the Đơn Hàng system

The interface the samples already have:

```csharp file=samples/DonHang.Samples/Samples/Oop/INotifier.cs tag=stage-0 lines=5-8
public interface INotifier
{
    void Send(int orderId, string subject);
}
```

One method. A class that implements `INotifier` promises to send a message about an order, and nothing else. In the samples, `NotifierBase` implements it: it provides `Send`, keeps a list of sent messages, prints each one, and leaves a single step, `Format`, to the classes that derive from it. The two channels fill in only that step:

```csharp file=samples/DonHang.Samples/Samples/Oop/NotifierBase.cs tag=stage-0 lines=21-31
public sealed class EmailNotifier : NotifierBase
{
    protected override string Format(int orderId, string subject) =>
        $"email about order {orderId}: {subject}";
}

public sealed class SmsNotifier : NotifierBase
{
    protected override string Format(int orderId, string subject) =>
        $"sms about order {orderId}: {subject}";
}
```

Neither class carries a method it has no behaviour for. `SmsNotifier` does not know email exists; `EmailNotifier` does not know about SMS. Both are `INotifier`s, so either one can be used wherever an `INotifier` is expected. Compare that with the proposed `INotificationChannel`, where `SmsNotifier` would carry three methods it has no real behaviour for.

## Beginners often think…

- **"A big interface is fine as long as every class implementing it eventually uses every method somewhere."** → Actually, even when each method is used by some class somewhere, ISP asks about each piece of code that depends on the interface, not about the system as a whole. The confirmation code calls one method of `INotificationChannel`, yet it can only be given classes that implement all four. You notice this when a class that does exactly what you need cannot be passed in without filler for methods you never call.
- **"ISP is only about how many methods an interface has, not about who is forced to depend on it."** → Actually a small count is a symptom, not the goal. An interface with three methods is fine when every caller and every implementer needs all three; `INotificationChannel` is a problem because `SmsNotifier` needs one of its four. You notice this when you find yourself writing filler bodies just to make a class compile.

## Try it (3 minutes)

Take the proposed `INotificationChannel` from the situation, with `SendEmail`, `SendSms`, `SendPush` and `GetDeliveryReport`.

1. List the methods `SmsNotifier` would have real behaviour for, and the ones it would have to fill with something.
2. List the methods the order confirmation code calls, if it sends an SMS.
3. Say which interface in the samples already gives both of them exactly what they need.

Expected result: 1 — real: `SendSms`; filler: `SendEmail`, `SendPush`, `GetDeliveryReport`. 2 — only `SendSms`. 3 — `INotifier`, with its single `Send`, which `SmsNotifier` gets through `NotifierBase`.

If `GetDeliveryReport` later needs a new parameter, which classes must change under each design?

<details><summary>Suggested answer</summary>

With `INotificationChannel`, every implementing class must change, `SmsNotifier` and `EmailNotifier` included, even though neither reports anything. With `INotifier`, nothing changes: delivery reports would live in their own interface, implemented only by classes that can report.

</details>

## Connections

- [[design.l1.solid-lsp]] — filler methods that throw are exactly the broken promise LSP warns about.
- [[foundation.l1.oop-interface-vs-abstract]] — where `INotifier`, `NotifierBase`, `EmailNotifier` and `SmsNotifier` were first introduced.
- [[design.l1.solid-dip]] — the last SOLID principle, about which way the dependency on an interface like `INotifier` should point.

## Five-line summary

1. The Interface Segregation Principle says no code should be forced to depend on methods it does not use.
2. A fat interface makes implementers write filler methods and makes callers depend on methods they never call.
3. Filler that throws also breaks the promise LSP asks every implementation to keep.
4. `INotifier` has one method, `Send`, so `EmailNotifier` and `SmsNotifier` carry only what they really do.
5. Cut interfaces by what each caller and implementer needs, not by a wish for every channel to look the same.
