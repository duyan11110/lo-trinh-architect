---
id: management.l1.kanban-vs-scrum
lang: en
track: management
level: 1
stage: 1
module: stories-and-estimation
main_path: true
title: "Kanban: continuous flow, no fixed sprint"
duration_min: 12
skills: [management.process.kanban]
prereqs: [management.l1.scrum-from-junior-seat]
related: []
vocab: [kanban]
example_tag: stage-1
versions_used: [scrum]
content_version: 1
status: draft
---

## Before you start

- [[management.l1.scrum-from-junior-seat]] — you know a sprint is a fixed time box with one goal, and that work which does not fit moves to the next sprint instead of stretching the dates.

## The situation

The Đơn Hàng company has two development teams. The feature team plans two-week sprints, each with one goal. The support team takes bug reports and customer questions that arrive any day of the week, and some of them cannot wait until the next sprint starts. The support team does not use sprints at all, yet its work is just as visible and just as organised: it lives on a board with four columns. How does work move on that board without a sprint, and why would one company use both ways at once?

## Core concepts

- **Kanban** — a way of tracking work as a continuous flow across the columns of a board, with no fixed-length sprint: an item moves on whenever it is ready.
- board column — one stage of the work, such as to do, in progress, waiting for review or done; an item sits in exactly one column at a time.
- flow — work moving through the columns one item at a time, instead of in a batch planned at the start of a time box.

## How it works

```mermaid
flowchart LR
  T[To do] --> P[In progress]
  P --> R[Waiting for review]
  R --> D[Done]
  N[new bug, any day] --> T
```

**Kanban** keeps work moving through a board. New items join the first column when they are accepted, in priority order. When someone is free, they pull the top item into the next column, and each item moves on as soon as its current step is finished. There is no sprint and no sprint goal: nothing waits for a planning meeting, and nothing waits for the end of a two-week box to count as done.

Because of that, a Kanban board always shows the present. At any moment you can read off what is waiting, what is being worked on, what waits for review and what is finished. A sprint board answers a narrower question: what the team took on in this sprint. It shows the sprint backlog, which belongs to one sprint, so a new sprint brings a new set of items and the board shows one sprint's slice of the work.

The two are different defaults for when work moves, not rival beliefs. Scrum plans a batch around a sprint goal and keeps that goal fixed for the sprint; Kanban lets each item move on its own. Many teams mix them, for example keeping Scrum's roles and events while using a Kanban-style board. The Scrum Guide itself does not say how the team's board should look, so that choice is left to the team.

## In the Đơn Hàng system

The support team's board, in `docs/team/kanban-board-example.md`:

```markdown file=docs/team/kanban-board-example.md tag=stage-1 lines=8-12
| Việc cần làm | Đang làm (giới hạn 2) | Chờ review (giới hạn 2) | Xong |
|---|---|---|---|
| Thêm chỉ mục cho `orders.customer_id` | Sửa lỗi trang sản phẩm bị chậm — Dev 3 | Thêm log cho lần đăng nhập thất bại — Dev 1 | Vá lỗi mật khẩu rỗng vẫn đăng nhập được |
| Viết tài liệu API cho `/api/v1/orders` | Kiểm tra lại cảnh báo email bị gửi hai lần — Dev 2 | | Sửa định dạng số tiền ở trang admin |
| Dọn log cũ hơn 30 ngày | | | Cập nhật container Postgres |
```

Four columns: `Việc cần làm` (to do), `Đang làm` (in progress), `Chờ review` (waiting for review) and `Xong` (done). Each item sits in one of them, with the developer's name once someone works on it. The same file explains why this team has no sprint:

```markdown file=docs/team/kanban-board-example.md tag=stage-1 lines=24-28
Nhóm hỗ trợ (Dev 1, Dev 2) nhận việc từ báo lỗi và câu hỏi của khách hàng bất
cứ ngày nào trong tuần; gom chúng vào một khối hai tuần sẽ làm chậm những việc
cần sửa ngay. Đội tính năng (Dev 3, Dev 4) vẫn dùng sprint riêng (xem
`sprint-example.md`) cho các việc lớn, có thể lên kế hoạch trước — hai đội
cùng công ty, khác cách tổ chức việc theo đúng loại việc mỗi đội nhận.
```

The file says the support team takes work from bug reports and customer questions on any day, and that grouping it into a two-week batch would slow down fixes that are needed now. The feature team keeps its own sprints for large work that can be planned ahead, and the file points to `sprint-example.md` for how a sprint runs. One company, two ways of organising work, each matched to the kind of work the team receives.

## Beginners often think…

- **"Kanban is just Scrum without a name for the roles."** → Actually the difference is when work moves: Scrum fixes a time box and a goal, and Kanban does not need either, so each item moves on as soon as it is ready. You notice this when an urgent bug reaches the support team's board on a Wednesday and goes to the top of `Việc cần làm` at once, to be picked up as soon as someone can take it, instead of waiting for the next sprint planning.
- **"A team using a board with columns is automatically doing Kanban."** → Actually a Scrum team can use the same columns for its sprint backlog and still work in two-week batches. Columns only name the stages; Kanban is about managing how each item flows through them. You notice this when a board with Kanban-looking columns is cleared and refilled every two weeks at sprint planning.

## Try it (3 minutes)

Open `docs/team/kanban-board-example.md` and `docs/team/sprint-example.md` from the repository side by side.

1. On the Kanban board, list what is in `Đang làm` and `Chờ review` right now, and who is on each item.
2. In Sprint 14, find the item that did not finish, and what happened to it.
3. Imagine a customer reports on Wednesday that orders show the wrong total. Write down when each team would start working on it.

Expected result: 1 — `Đang làm`: the slow product page (Dev 3) and the double email warning (Dev 2); `Chờ review`: logging failed logins (Dev 1). 2 — `Ngừng gửi thông báo cho đơn đã hủy`, which moved to the next sprint. 3 — the support team as soon as someone can take it, once an item leaves the full `Đang làm` column; the feature team at its next sprint planning, unless the sprint is changed for it.

Both files describe the same company. Why is the Kanban board a better fit for the support team's work, and the sprint for the feature team's?

<details><summary>Suggested answer</summary>

The support team's work arrives unpredictably and some of it cannot wait, so letting each item flow onto the board and move on as soon as someone can take it lets urgent fixes start without waiting for the next sprint. The feature team's work is larger and can be planned, so a two-week box with one goal lets it commit to a usable piece and protect it from interruptions. The difference is the kind of work each team receives, not which method is better.

</details>

## Connections

- [[management.l1.scrum-from-junior-seat]] — the sprint, the goal and the roles that Kanban does without.
- [[management.l1.wip-limits]] — the limit on the `Đang làm` column, and why it matters.
- [[management.l1.why-estimate]] — why sprint teams estimate the size of their work.

## Five-line summary

1. **Kanban** tracks work as a continuous flow across board columns, with no fixed sprint and no sprint goal.
2. Each item moves on as soon as it is ready, so the board always shows the current state of the work on it.
3. A sprint board shows one sprint's slice and usually starts again with each new sprint.
4. The Đơn Hàng support team uses Kanban for unpredictable work, while the feature team keeps sprints for planned work.
5. Scrum and Kanban are different defaults for when work moves, and many teams mix them.
