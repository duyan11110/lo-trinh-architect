---
id: management.l1.why-estimate
lang: vi
track: management
level: 1
stage: 1
module: stories-and-estimation
main_path: true
title: "Vì sao ước lượng: lập kế hoạch, không phải hứa hẹn"
duration_min: 10
skills: [management.process.estimation]
prereqs: [management.l1.wip-limits, management.l1.user-story-and-ac]
related: []
vocab: []
example_tag: stage-1
versions_used: []
content_version: 1
status: published
approved_by: auto
reviewed_at: "2026-09-28T04:00:00+07:00"
---

## Bạn cần biết trước

- [[management.l1.wip-limits]] — bạn biết một đội Kanban giới hạn lượng việc đang làm thay vì lên kế hoạch trước một khối việc.
- [[management.l1.user-story-and-ac]] — bạn biết một story nêu ai muốn gì và vì sao, và tiêu chí chấp nhận của nó làm nó kiểm tra được trước khi ai đó bắt đầu viết code.

## Tình huống

Buổi sprint planning đầu tiên của bạn với một đội Đơn Hàng làm việc theo sprint. Product owner đọc năm việc, và sau mỗi việc cả đội nói một con số nhỏ: 3, 3, 2, 2, 1. Chưa ai bắt đầu làm việc nào, và dường như chẳng ai chắc việc nào sẽ mất bao lâu. Một junior ngồi cạnh thì thầm rằng những con số này chắc là hạn chót, và hỏi người đoán sai sẽ ra sao. Nếu chưa ai biết được kích cỡ thật, vì sao đội còn mất công đoán làm gì?

## Khái niệm cốt lõi

- ước lượng — phỏng đoán tốt nhất về độ lớn của một phần việc, đưa ra trước khi bắt đầu làm, với những thông tin có được lúc đó.
- lập kế hoạch — quyết định bao nhiêu việc là vừa phải cho một sprint, hoặc một phần việc lớn hơn sẽ mất đại khái bao lâu.
- sprint planning — buổi họp đầu sprint, nơi đội chọn những việc vừa với sprint.

## Cơ chế hoạt động

```mermaid
flowchart LR
  S[stories in the backlog] --> E[estimate each one]
  E --> P[plan: what fits in this sprint]
  P --> W[do the work]
  W --> L[learn how it compared]
  L -.-> E
```

Một đội ước lượng để có thể lập kế hoạch. Ở sprint planning, câu hỏi là bao nhiêu story đang chờ sẽ vừa với sprint tiếp theo. Câu hỏi đó không trả lời được nếu không có chút ý niệm nào về việc mỗi story lớn cỡ nào so với các story khác. Các con số trong tình huống trên, lấy từ Sprint 14, so sánh các story với nhau; chúng không phải giờ hay ngày, và bài sau sẽ cho thấy chúng được chọn ra sao. Với việc lớn hơn cũng vậy: để nói một tính năng mất vài tuần hay vài tháng, đội cần một kích cỡ đại khái cho từng phần của nó.

Ước lượng được đưa ra trước khi bắt đầu làm, nên nó chỉ dùng được những gì đội biết lúc đó. Code chưa được đọc kỹ, vấn đề bất ngờ chưa xuất hiện, và người hiểu module cũ có thể đang nghỉ phép. Vì vậy ước lượng đôi khi sẽ sai, theo cả hai hướng: có việc hóa ra nhỏ hơn vẻ ngoài, có việc lớn hơn. Điều đó là bình thường, không phải dấu hiệu đội đã làm gì sai.

Ước lượng không phải lời hứa với ai đó bên ngoài đội. Nó là công cụ lập kế hoạch của chính đội. Một story chưa có ước lượng vẫn có thể được làm; điều đội không làm được nếu không có chút ý niệm nào về kích cỡ từng story là quyết định nhận bao nhiêu story vào một sprint. Sau khi làm xong, đội có thể nhìn lại xem các phỏng đoán so với thực tế ra sao, và đó là cách những lần ước lượng sau tốt hơn; đó là mũi tên nét đứt trong sơ đồ.

## Trong hệ thống Đơn Hàng

Sprint backlog của Sprint 14, trong `docs/team/sprint-example.md`, có một cột `Ước lượng` với một con số cho mỗi việc: 3 cho endpoint hủy đơn và cho nút hủy đơn, 2 cho việc chặn hủy đơn đã thanh toán và cho việc ngừng gửi thông báo cho đơn đã hủy, và 1 cho lỗi tổng tiền sai. Chính những con số như vậy giúp một đội quyết định, ở buổi planning, bao nhiêu việc là vừa với sprint.

Cùng file đó cho thấy nửa còn lại. Một việc, ngừng gửi thông báo cho đơn đã hủy, được ước lượng 2 và không xong; nó được chuyển sang sprint sau. Ở sprint review, buổi họp cuối sprint, đội đơn giản là không tính nó là xong, và file không nói vì sao nó mất lâu hơn. Ước lượng giúp lập kế hoạch cho một sprint; nó không quyết định điều gì xảy ra trong sprint đó.

Bảng Kanban trong `docs/team/kanban-board-example.md` không có cột ước lượng. Đội đó không lên kế hoạch trước một khối việc; họ giới hạn lượng việc đang làm, nên ít cần định cỡ từng việc trước khi bắt đầu.

## Người mới hay nghĩ rằng…

- **"Mục đích của ước lượng là đưa cho quản lý một hạn chót chính xác để buộc đội phải theo."** → Thực ra đội ước lượng cho việc lập kế hoạch của chính mình: để xem bao nhiêu việc vừa với một sprint, hoặc việc lớn hơn mất đại khái bao lâu. Một con số đưa ra trước khi bắt đầu làm thì không thể chính xác. Bạn sẽ nhận ra khi ước lượng bị biến thành hạn chót và mọi người bắt đầu đưa ra số lớn hơn để tự bảo vệ, khiến các con số không còn giúp được việc lập kế hoạch.
- **"Ước lượng của một đội giỏi thì luôn đúng; sai nghĩa là ước lượng đã làm kém."** → Thực ra mọi ước lượng chỉ dùng những gì biết được trước khi bắt đầu, nên đội giỏi cũng sai, theo cả hai hướng. Điều một đội giỏi làm là học từ khoảng chênh lệch. Bạn sẽ nhận ra khi một việc ước lượng 2 không xong trong sprint của nó, như ở Sprint 14, trong khi bốn việc kia xong.

## Thử ngay (3 phút)

Mở `docs/team/sprint-example.md` trong repository.

1. Cộng các con số trong cột `Ước lượng`.
2. Tìm việc không xong, và ước lượng của nó.
3. Viết một câu về điều đội có thể học từ việc đó ở buổi retrospective, mà không nói ai đoán kém.

Kết quả mong đợi: 1 — 11. 2 — `Ngừng gửi thông báo cho đơn đã hủy`, ước lượng 2. 3 — ví dụ: "việc này mất lâu hơn mức mình định cỡ; lần sau hãy xem vì sao trước khi định cỡ việc tương tự."

Việc không xong được ước lượng 2 mà vẫn không vừa. Vậy con số 2 có phải là sai lầm, và đội có nên ngừng ước lượng không?

<details><summary>Gợi ý đáp án</summary>

Không. Con số 2 là phỏng đoán tốt nhất của đội với những gì biết được lúc planning; việc đó mất lâu hơn, điều mà công việc đôi khi vẫn vậy, và file không nói vì sao. Một ước lượng như thế vẫn làm tròn việc của nó: giúp một đội đánh giá bao nhiêu việc là vừa với một sprint. Ngừng ước lượng sẽ khiến đội không còn cách nào quyết định bao nhiêu việc là vừa với một sprint. Cách phản ứng tốt hơn là tìm ra ở buổi retrospective vì sao nó mất lâu hơn và dùng điều đó ở buổi planning sau.

</details>

## Liên hệ

- [[management.l1.relative-estimation]] — các con số trong cột `Ước lượng` được chọn ra sao: kích cỡ tương đối, không phải giờ.
- [[management.l1.estimates-are-not-commitments]] — vì sao không được coi một ước lượng là lời hứa.
- [[management.l1.scrum-from-junior-seat]] — sprint và buổi lập kế hoạch mà ước lượng phục vụ.

## Tóm tắt 5 dòng

1. Một đội ước lượng để lập kế hoạch: bao nhiêu việc vừa với một sprint, hoặc việc lớn hơn mất đại khái bao lâu.
2. Ước lượng được đưa ra trước khi bắt đầu làm, chỉ với những gì biết được lúc đó.
3. Ước lượng đôi khi sai theo cả hai hướng, và điều đó là bình thường, không phải thất bại.
4. Việc có thể bắt đầu mà không cần ước lượng, nhưng không lập kế hoạch được sprint nếu không biết đại khái mỗi story lớn cỡ nào.
5. Các con số `Ước lượng` của Sprint 14 dùng để lập kế hoạch; việc không xong không biến ước lượng của nó thành lời hứa bị phá.
