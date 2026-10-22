---
id: backend.l3.outbox-relay
lang: en
track: backend
level: 3
stage: 3
module: messaging
main_path: true
title: "The relay marks an outbox row sent only after RabbitMQ confirms it"
duration_min: 15
skills: [backend.messaging.outbox]
prereqs: [backend.l3.outbox-pattern, backend.l2.skip-locked-claiming, backend.l2.hosted-services]
related: [backend.l2.at-least-once-jobs, backend.l2.retry-with-backoff]
vocab: [publisher-confirm]
example_tag: stage-3
versions_used: [dotnet, efcore, postgresql, rabbitmq, rabbitmq_client]
content_version: 1
status: published
approved_by: auto
reviewed_at: "2026-10-14T09:04:50+07:00"
---

## Before you start

- [[backend.l3.outbox-pattern]] — you know that each order event is saved as an `outbox_messages` row in the order's own transaction, with `published_at` empty until the message reaches RabbitMQ.
- [[backend.l2.skip-locked-claiming]] — you know that `FOR UPDATE SKIP LOCKED` inside a transaction lets several copies of a sender claim different rows of one table.
- [[backend.l2.hosted-services]] — you know that a `BackgroundService` runs a loop beside the requests, waits on a `PeriodicTimer`, and catches its own errors each round.

## The situation

It is stage-3, and RabbitMQ has stopped. You place an order anyway. `POST /api/v1/orders` still answers `201`, and the order's row in `outbox_messages` reads "not published". The API logs one warning every second. You start RabbitMQ again, and within seconds the row reads "published" and the Notifications service (`DonHang.Notifications`) sends the email.

You open `OutboxRelay`, the code that moves these rows to RabbitMQ. Setting `published_at` is one line after a publish call. But a call that returns does not by itself prove that RabbitMQ kept the message.

When may the relay safely mark an outbox row as sent?

## Core concepts

- **publisher confirm** — RabbitMQ's answer telling the publisher it has taken responsibility for a message; in the situation above, the signal `OutboxRelay` waits for before it sets `published_at`.
- `OutboxRelay` — the hosted service in `DonHang.Api` that, once a second, claims unpublished `outbox_messages` rows and publishes each to the exchange `donhang.orders`.
- channel — a path inside one connection to RabbitMQ that a publisher sends on; publisher confirms are turned on per channel.
- durable — a setting on an exchange or a queue that makes RabbitMQ keep it across a restart of the broker.
- persistent — a property of a message asking RabbitMQ to write it to disk when it lands in a durable queue.

## How it works

```mermaid
sequenceDiagram
  participant R as OutboxRelay
  participant P as PostgreSQL
  participant B as RabbitMqPublisher
  participant M as RabbitMQ
  R->>P: begin; claim ≤ 20 rows FOR UPDATE SKIP LOCKED
  loop each claimed row
    R->>B: PublishAsync(message)
    B->>M: publish to donhang.orders
    M-->>B: publisher confirm
    B-->>R: returns; PublishedAt = now
  end
  R->>P: SaveChangesAsync, then commit
```

`OutboxRelay` is the step the previous lesson left open. `DonHang.Api` registers it as a hosted service, so it runs in the API's own process.

Every second — one tick of its `PeriodicTimer` loop — the relay opens a transaction and claims up to 20 rows whose `published_at` is empty, oldest first. The row lock keeps another copy of the API from publishing the same rows at the same time. For each row, `RabbitMqPublisher` sends the message to `donhang.orders` with the row's routing key.

The publisher's channel has publisher confirms turned on. RabbitMQ answers each publish once the queues the message is routed to have accepted it, and the publish call waits for that answer. Only then does the relay set `PublishedAt`. If RabbitMQ refuses the message, the call throws instead; and while the connection is down, a publish on it throws too.

That responsibility lasts because nothing in the path is temporary. The exchange and the queues are declared durable, and every message is persistent. A confirmed message that RabbitMQ routed to a durable queue survives a restart of the broker.

After the loop, or after a publish fails partway, the relay saves and commits. Rows confirmed before the failure are stored as published; the rest stay empty for the next tick. While RabbitMQ is down, each tick fails at its first publish, and new orders simply add rows that wait.

One gap remains. If the API process stops after a confirm and before the commit, the transaction never commits. The row stays unpublished, and a later tick publishes it again.

## In the Đơn Hàng system

One tick of the relay, in `DonHang.Messaging/OutboxRelay.cs`. Lines 55–57 belong to a later lesson in this module; skip them here.

```csharp file=DonHang.Messaging/OutboxRelay.cs tag=stage-3 lines=45-69
        using var scope = scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TDbContext>();
        await using var transaction = await db.Database.BeginTransactionAsync(stoppingToken);
        var due = await ClaimDueAsync(db, stoppingToken);

        var published = 0;
        try
        {
            foreach (var message in due)
            {
                // lesson: backend.l3.tracing-through-the-outbox
                // One publish span per message, in the trace its row saved.
                using var activity = MessageTracing.StartPublish(message, publisher.Exchange);
                await publisher.PublishAsync(message, stoppingToken);
                message.PublishedAt = DateTimeOffset.UtcNow;
                published++;
            }
        }
        finally
        {
            // Whatever was confirmed before a failure is recorded as published.
            await db.SaveChangesAsync(stoppingToken);
            await transaction.CommitAsync(stoppingToken);
            if (published > 0) logger.LogInformation("Published {Count} outbox messages", published);
        }
```

Line 47 opens the transaction, and line 48 claims the rows; `ClaimDueAsync`, further down the file, is the `FOR UPDATE SKIP LOCKED` query with `LIMIT` 20 and `ORDER BY created_at`. Line 59 sets `PublishedAt` only after line 58 has returned. The `finally` block saves and commits whatever was set, even when a publish throws. The exception then leaves the method; `ExecuteAsync`, outside the excerpt, logs one warning line and waits for the next tick. `TDbContext` is the relay's type parameter; in `DonHang.Api` it is `DonHangDbContext`.

Where confirms and durability are switched on, in `DonHang.Messaging/RabbitMqPublisher.cs`:

```csharp file=DonHang.Messaging/RabbitMqPublisher.cs tag=stage-3 lines=40-54
    // One channel, opened on first use, with publisher confirms turned on.
    // Declaring the exchange is safe to repeat: it changes nothing when the
    // exchange already exists with the same settings.
    private async Task<IChannel> OpenChannelAsync(CancellationToken cancellationToken)
    {
        if (channel is { IsOpen: true }) return channel;

        var open = await connection.GetAsync(cancellationToken);
        channel = await open.CreateChannelAsync(
            new CreateChannelOptions(publisherConfirmationsEnabled: true, publisherConfirmationTrackingEnabled: true),
            cancellationToken);
        await channel.ExchangeDeclareAsync(exchange, ExchangeType.Topic, durable: true,
            cancellationToken: cancellationToken);
        return channel;
    }
```

Line 49 turns publisher confirms on, and the tracking flag makes each publish wait for its confirm; so `BasicPublishAsync`, which `PublishAsync` calls earlier in the file, completes only once RabbitMQ has confirmed the message. Line 51 declares `donhang.orders` durable (its type, Topic, is not part of this lesson). Outside this excerpt, line 28 sets `Persistent = true` on every message. `DonHang.Notifications` declares its queue `notifications.order-events` durable in its own `RabbitMqTopology.cs`.

If RabbitMQ is down, line 47 cannot open a connection, or line 48 cannot open a channel on the one that dropped, so the first publish of a tick throws. Line 26, outside the excerpt, sets each message's `MessageId` to the outbox row's id.

## Seniors often assume…

- **"Once the publish call returns without an error, RabbitMQ has stored the message, even without publisher confirms."** → Actually, without confirms RabbitMQ never acknowledges a publish, so a returned call says nothing about whether the broker kept the message. You notice this when the broker restarts during a burst of orders, and some rows read "published" while no queue ever held their messages.
- **"If RabbitMQ is down, placing an order has to fail, or its email would be lost."** → Actually the order and its outbox row are saved by PostgreSQL alone, so the API still answers `201`. The row waits, and the relay publishes it once RabbitMQ is back. You notice this when `broker-down.sh` shows `201` and a row "not published" while RabbitMQ is stopped, then "published" and an email "sent".
- **"An outbox makes sure each message is delivered exactly once."** → Actually it gives at-least-once delivery: never lost once it reaches a bound queue, sometimes repeated. A crash after a confirm and before the commit publishes that row again, so receivers must expect duplicates. You notice this when `notifications.order-events` holds two messages with the same `MessageId`.

## Try it (3 minutes)

In the root folder of the example repository, with the Đơn Hàng stack running:

1. Run `scripts/backend/broker-down.sh`.
2. Compare the outbox row printed while RabbitMQ is stopped with the one printed after "rabbitmq is back".
3. Then decide: if the API process were killed right after RabbitMQ confirmed this order's message, before line 67 commits, what would the row read after the restart, and how many copies would reach `notifications.order-events`?

Expected result: the order gets `-> 201`; the row first reads `order.placed | not published`, and the log line reads `Relaying outbox messages failed (...); trying again in 1 s`. After RabbitMQ is back, the row reads `order.placed | published`, and the `notifications` row made from the message reads `sent`. For step 3, check your answer below.

<details><summary>Suggested answer</summary>

The transaction never commits, so PostgreSQL rolls it back: `published_at` stays empty and the row lock is released. After the restart, the next tick claims the row and publishes it again. Two copies reach `notifications.order-events`, both with the same `MessageId`. Nothing is lost, and one message is repeated.

</details>

## Connections

- [[backend.l3.outbox-pattern]] — the step before: it saves the rows with `published_at` empty; this lesson publishes them.
- [[backend.l3.consumer-acknowledgements]] — the same handshake on the receiving side: RabbitMQ waits for the consumer's answer as the relay waits for RabbitMQ's.
- [[backend.l3.idempotent-consumer]] — the fix for the duplicates an at-least-once relay can produce.
- [[backend.l2.at-least-once-jobs]] — the same trade-off at stage-2: send first, record afterwards, accept a rare repeat.
- [[backend.l2.retry-with-backoff]] — the contrast: the relay retries every second, with no backoff and no attempt limit.
- [[backend.l2.skip-locked-claiming]] — the claim query the relay reuses unchanged.

## Five-line summary

1. The relay sets an outbox row's `published_at` only after RabbitMQ confirms the publish, so no row is marked sent too early.
2. Every second, `OutboxRelay` claims up to 20 unpublished rows with `FOR UPDATE SKIP LOCKED`, publishes each to `donhang.orders`, then commits.
3. Publisher confirms make the publish call wait for RabbitMQ's answer; durable exchange and queues and persistent messages keep confirmed messages in their queues across restarts.
4. While RabbitMQ is down, orders still succeed; their rows wait unpublished and go out once the broker is back.
5. A crash between confirm and commit publishes the row again, so the outbox is at-least-once and receivers must expect duplicates.
