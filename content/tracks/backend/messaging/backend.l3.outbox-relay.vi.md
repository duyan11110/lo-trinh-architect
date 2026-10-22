---
id: backend.l3.outbox-relay
lang: vi
track: backend
level: 3
stage: 3
module: messaging
main_path: true
title: "Relay chỉ đánh dấu dòng outbox đã gửi sau khi RabbitMQ xác nhận"
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

## Bạn cần biết trước

- [[backend.l3.outbox-pattern]] — bạn biết rằng mỗi event của đơn được lưu thành một dòng `outbox_messages` trong chính giao dịch của đơn, với `published_at` để trống cho tới khi message tới RabbitMQ.
- [[backend.l2.skip-locked-claiming]] — bạn biết rằng `FOR UPDATE SKIP LOCKED` bên trong một giao dịch cho phép nhiều bản chạy của cùng một bên gửi nhận về những dòng khác nhau của một bảng.
- [[backend.l2.hosted-services]] — bạn biết rằng một `BackgroundService` chạy một vòng lặp song song với các request, chờ trên một `PeriodicTimer`, và tự bắt lỗi của mình ở mỗi vòng.

## Tình huống

Đang ở stage-3, và RabbitMQ đã dừng. Bạn vẫn đặt một đơn. `POST /api/v1/orders` vẫn trả `201`, còn dòng của đơn trong `outbox_messages` ghi "not published". Mỗi giây API ghi một dòng cảnh báo vào log. Bạn bật lại RabbitMQ, và chỉ vài giây sau dòng đó ghi "published", rồi service Notifications (`DonHang.Notifications`) gửi email.

Bạn mở `OutboxRelay`, đoạn code chuyển các dòng này lên RabbitMQ. Gán `published_at` chỉ là một dòng sau lời gọi publish. Nhưng lời gọi trả về xong thì tự nó chưa chứng minh được RabbitMQ đã giữ message.

Vậy khi nào relay mới được đánh dấu một dòng outbox là đã gửi mà không rủi ro?

## Khái niệm cốt lõi

- **publisher confirm** (Lời RabbitMQ báo cho bên publish rằng nó đã nhận trách nhiệm giữ một message) — câu trả lời RabbitMQ gửi về cho bên publish, báo rằng nó đã nhận trách nhiệm giữ message. Trong tình huống trên, đó là tín hiệu `OutboxRelay` chờ trước khi gán `published_at`.
- `OutboxRelay` — hosted service trong `DonHang.Api`, mỗi giây nhận về các dòng `outbox_messages` chưa publish và publish từng dòng lên exchange `donhang.orders`.
- channel — một đường đi bên trong một kết nối tới RabbitMQ, nơi bên publish gửi message. Publisher confirm được bật theo từng channel.
- durable — thiết lập trên một exchange hay một hàng đợi, khiến RabbitMQ giữ lại nó qua một lần broker khởi động lại.
- persistent — thuộc tính của một message, yêu cầu RabbitMQ ghi nó xuống đĩa khi nó vào một hàng đợi durable.

## Cơ chế hoạt động

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

`OutboxRelay` là bước mà bài trước còn bỏ ngỏ. `DonHang.Api` đăng ký nó làm hosted service, nên nó chạy ngay trong process của API.

Mỗi giây, tức một nhịp của vòng lặp `PeriodicTimer`, relay mở một giao dịch và nhận về tối đa 20 dòng có `published_at` trống, dòng cũ nhất trước. Khóa dòng ngăn một bản API khác publish đúng những dòng đó cùng lúc. Với mỗi dòng, `RabbitMqPublisher` gửi message lên `donhang.orders` kèm routing key của dòng.

Channel của bên publish đã bật publisher confirm. RabbitMQ trả lời từng lần publish khi các hàng đợi nhận message đã chấp nhận nó, và lời gọi publish chờ câu trả lời đó. Chỉ khi ấy relay mới gán `PublishedAt`. Nếu RabbitMQ từ chối message, lời gọi sẽ ném exception. Còn khi kết nối đang đứt, publish trên kết nối đó cũng ném exception.

Trách nhiệm ấy giữ được lâu vì không thứ gì trên đường đi là tạm thời. Exchange và các hàng đợi được khai báo durable, và mọi message đều persistent. Một message đã được xác nhận và được RabbitMQ đưa vào hàng đợi durable sẽ còn nguyên sau khi broker khởi động lại.

Sau vòng lặp, hoặc khi một lần publish hỏng giữa chừng, relay lưu rồi commit. Các dòng đã được xác nhận trước lỗi được lưu là đã publish, những dòng còn lại vẫn trống cho nhịp sau. Trong lúc RabbitMQ ngừng, nhịp nào cũng hỏng ngay ở lần publish đầu tiên, còn đơn mới chỉ thêm dòng vào hàng chờ.

Vẫn còn một khoảng hở. Nếu process API dừng sau khi có xác nhận mà trước khi commit, giao dịch không bao giờ commit. Dòng đó vẫn chưa publish, và một nhịp sau sẽ publish nó lần nữa.

## Trong hệ thống Đơn Hàng

Một nhịp của relay, trong `DonHang.Messaging/OutboxRelay.cs`. Dòng 55–57 thuộc về một bài sau trong module này, ở đây bạn bỏ qua.

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

Dòng 47 mở giao dịch, dòng 48 nhận về các dòng. `ClaimDueAsync`, nằm phía dưới trong file, là câu truy vấn `FOR UPDATE SKIP LOCKED` với `LIMIT` 20 và `ORDER BY created_at`. Dòng 59 chỉ gán `PublishedAt` sau khi dòng 58 đã trả về. Khối `finally` lưu và commit những gì đã gán, kể cả khi một lần publish ném exception. Sau đó exception thoát khỏi method. `ExecuteAsync`, nằm ngoài đoạn trích, ghi một dòng cảnh báo rồi chờ nhịp sau. `TDbContext` là tham số kiểu của relay, trong `DonHang.Api` nó là `DonHangDbContext`.

Chỗ bật xác nhận và durable, trong `DonHang.Messaging/RabbitMqPublisher.cs`:

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

Dòng 49 bật publisher confirm, còn cờ tracking khiến mỗi lần publish chờ xác nhận của chính nó. Vì vậy `BasicPublishAsync`, được `PublishAsync` gọi ở phần trên của file, chỉ hoàn tất khi RabbitMQ đã xác nhận message. Dòng 51 khai báo `donhang.orders` là durable (kiểu Topic của nó không thuộc bài này). Ngoài đoạn trích, dòng 28 gán `Persistent = true` cho mọi message. `DonHang.Notifications` khai báo hàng đợi `notifications.order-events` của mình là durable trong `RabbitMqTopology.cs` riêng.

Nếu RabbitMQ ngừng, dòng 47 không mở được kết nối, hoặc dòng 48 không mở được channel trên kết nối đã đứt, nên lần publish đầu tiên của nhịp ném exception. Dòng 26, ngoài đoạn trích, gán `MessageId` của mỗi message bằng id của dòng outbox.

## Senior hay nhầm rằng…

- **"Lời gọi publish trả về không lỗi là RabbitMQ đã lưu message, kể cả khi không có publisher confirm."** → Thực ra không có xác nhận thì RabbitMQ không bao giờ báo lại cho lần publish nào, vì vậy lời gọi trả về không nói lên được broker có giữ message hay không. Bạn sẽ nhận ra khi broker khởi động lại giữa một loạt đơn, và vài dòng ghi "published" trong khi chưa hàng đợi nào từng giữ message của chúng.
- **"RabbitMQ ngừng thì đặt đơn phải thất bại, không thì email của đơn sẽ mất."** → Thực ra đơn và dòng outbox của nó chỉ cần PostgreSQL để lưu, vì vậy API vẫn trả `201`. Dòng đó nằm chờ, và relay publish nó khi RabbitMQ chạy lại. Bạn sẽ nhận ra khi `broker-down.sh` in ra `201` và một dòng "not published" lúc RabbitMQ đang dừng, rồi sau đó là "published" và một email "sent".
- **"Outbox bảo đảm mỗi message được giao đúng một lần."** → Thực ra nó cho giao nhận at-least-once: không bao giờ mất một khi đã tới một hàng đợi có binding, nhưng đôi khi bị lặp, vì một lần crash sau xác nhận và trước commit sẽ publish dòng đó lần nữa. Bên nhận phải tính tới bản trùng. Bạn sẽ nhận ra khi `notifications.order-events` chứa hai message có cùng `MessageId`.

## Thử ngay (3 phút)

Ở thư mục gốc của repo ví dụ, khi stack Đơn Hàng đang chạy:

1. Chạy `scripts/backend/broker-down.sh`.
2. So dòng outbox được in ra lúc RabbitMQ đang dừng với dòng được in ra sau "rabbitmq is back".
3. Rồi hãy xác định: nếu process API bị kill ngay sau khi RabbitMQ xác nhận message của đơn này, trước khi dòng 67 commit, thì sau khi khởi động lại dòng đó sẽ ghi gì, và bao nhiêu bản tới được `notifications.order-events`?

Kết quả mong đợi: đơn nhận `-> 201`. Dòng outbox lúc đầu ghi `order.placed | not published`, và dòng log ghi `Relaying outbox messages failed (...); trying again in 1 s`. Sau khi RabbitMQ chạy lại, dòng đó ghi `order.placed | published`, và dòng `notifications` sinh ra từ message ghi `sent`. Ở bước 3, hãy đối chiếu với đáp án bên dưới.

<details><summary>Gợi ý đáp án</summary>

Giao dịch không bao giờ commit, nên PostgreSQL rollback nó: `published_at` vẫn trống và khóa dòng được nhả ra. Sau khi khởi động lại, nhịp kế tiếp nhận dòng đó và publish nó lần nữa. Hai bản tới `notifications.order-events`, cả hai có cùng `MessageId`. Không gì bị mất, chỉ một message bị lặp.

</details>

## Liên hệ

- [[backend.l3.outbox-pattern]] — bước trước: lưu các dòng với `published_at` trống. Bài này publish chúng.
- [[backend.l3.consumer-acknowledgements]] — cùng kiểu bắt tay ở phía nhận: RabbitMQ chờ câu trả lời của consumer giống như relay chờ câu trả lời của RabbitMQ.
- [[backend.l3.idempotent-consumer]] — cách xử lý các bản trùng mà một relay at-least-once có thể sinh ra.
- [[backend.l2.at-least-once-jobs]] — cùng đánh đổi đó ở stage-2: gửi trước, ghi nhận sau, chấp nhận thỉnh thoảng bị lặp.
- [[backend.l2.retry-with-backoff]] — điểm tương phản: relay thử lại mỗi giây, không backoff và không giới hạn số lần.
- [[backend.l2.skip-locked-claiming]] — câu truy vấn nhận dòng mà relay dùng lại nguyên vẹn.

## Tóm tắt 5 dòng

1. Relay chỉ gán `published_at` cho một dòng outbox sau khi RabbitMQ xác nhận lần publish, nên không dòng nào bị đánh dấu đã gửi quá sớm.
2. Mỗi giây, `OutboxRelay` nhận về tối đa 20 dòng chưa publish bằng `FOR UPDATE SKIP LOCKED`, publish từng dòng lên `donhang.orders`, rồi commit.
3. Publisher confirm khiến lời gọi publish chờ câu trả lời của RabbitMQ, còn exchange và hàng đợi durable cùng message persistent giữ message đã xác nhận trong hàng đợi qua các lần khởi động lại.
4. Khi RabbitMQ ngừng, đặt đơn vẫn thành công, các dòng của đơn nằm chờ chưa publish và được gửi đi khi broker chạy lại.
5. Một lần crash giữa xác nhận và commit sẽ publish dòng đó lần nữa, nên outbox là at-least-once và bên nhận phải tính tới bản trùng.
