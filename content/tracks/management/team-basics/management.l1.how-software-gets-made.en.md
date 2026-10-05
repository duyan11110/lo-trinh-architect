---
id: management.l1.how-software-gets-made
lang: en
track: management
level: 1
stage: 0
module: team-basics
main_path: true
title: "How software gets made: from idea to user"
duration_min: 10
skills: [management.process.sdlc]
prereqs: []
related: [devops.l1.what-is-deploy]
vocab: []
example_tag: stage-0
versions_used: []
content_version: 1
status: published
approved_by: auto
reviewed_at: "2026-09-28T13:00:00+07:00"
---

## Before you start

- No prerequisites — start here.

## The situation

Your first task on Đơn Hàng arrives as one line: a customer must be able to cancel an order that has not been delivered yet. You open the example repository at `stage-0`, the label on its starting state, and find no application to change. What is there includes a database holding twelve orders and a folder of the team's own notes. Somebody decided this was worth building, and which orders may be cancelled at all. Somebody will answer the phone when it goes wrong next month. Where did that one line come from, and what happens to your code after you think you are finished?

## Core concepts

- the six steps — gathering needs, designing, building, testing, releasing and operating: the steps the team's own note uses for any piece of work, whether or not a way of working (a method) names them.
- a trip — one journey through all six steps, from a need arriving to the built thing running for real users.
- trip size — how much of the system travels through the six steps at once: one small feature, or everything the system will ever do.
- a single-trip method — each step done once, for the whole system, before the next step starts; teams often call this shape a waterfall.
- an iterative method — the same six steps repeated on one small slice at a time, so the system grows by finished pieces rather than by finished steps; teams often call working this way agile.
- the cost of being wrong — the work you throw away when a decision turns out wrong, which grows with how much got built on top of it first.

## How it works

```mermaid
flowchart LR
  N["1 Gather needs"] --> D["2 Design"]
  D --> B["3 Build"]
  B --> T["4 Test"]
  T --> R["5 Release"]
  R --> O["6 Operate"]
  O -->|"what you learn here starts the next trip"| N
```

The one line you were handed is the output of step 1: a need written down without saying how to build it. Step 2 turns that need into decisions your code must obey: which orders may be cancelled, and what happens to the rest. Step 3 is where you come in. Step 4 checks the built thing against conditions the team agreed on. Step 5 puts it in front of users. Step 6 is every week after that, when the thing runs and the next need is found.

The arrow back from 6 to 1 is the part of the diagram worth keeping. Six steps in a row would be a project that ends; the arrow makes them a loop that runs as long as anyone uses the system. The team's note on this feature puts it as a rule: the six steps happen even when nobody names them. What the methods disagree about is how much of the system goes around the loop at one time.

Send everything around once — all needs gathered, then all designed, then all built, which can take a year — and a decision made in step 2 waits until step 5 to meet a real user: that is the single-trip method. Send one small feature around and it reaches step 5 in a week or two: that is an iterative method. If a decision turns out wrong, the iterative method costs two weeks of building rather than a year of it. That is the argument for small trips: not less thinking and not fewer written decisions, but a shorter distance between a decision and the evidence that it was wrong.

## In the Đơn Hàng system

The team's note records how they already took this same feature around the loop, in Vietnamese; picture yourself as its builder. `docs/team/lifecycle-example.md` has six headings, one per step. `Thu thập nhu cầu` (step 1) says the need started with customer care reporting about ten calls a day asking to cancel an undelivered order, and that the person who did step 1, whom the file calls the product owner, rewrote it as one sentence that does not say how to build it. `Thiết kế` (step 2) records the team's decision: only an order in status `new` can be cancelled, while a `paid` one goes to refunds. It is written down because it narrows the scope — the set of orders the feature must handle — so much.

`Xây dựng` (step 3) is two people on separate branches, each merging the main branch into their own daily. Then comes `Kiểm thử`, step 4, the heading that is easy to picture as the end of the work.

```markdown file=docs/team/lifecycle-example.md tag=stage-0 lines=22-23
Tiêu chí chấp nhận được viết trước khi code. Tester chạy lại đúng các tiêu chí
đó, cộng thêm một trường hợp không ai nghĩ tới: hủy đơn hai lần liên tiếp.
```

Read the order of events in the first sentence: `Tiêu chí chấp nhận`, the checkable conditions, exist *trước khi code*, before the code. The file does not say who wrote them, only that they existed before anyone coded. Step 4 therefore re-runs an earlier agreement, so the tester — the person the file gives step 4 to — is not deciding what correct means. The tester adds one case nobody had thought of — cancelling the same order twice in a row — so the step also finds what the agreement missed. On many teams you also check each agreed condition yourself against your running code, for example cancelling a `new` order and trying to cancel a `paid` one, which makes step 4 shared.

`Phát hành` (step 5) puts the feature in front of users at the start of a week. `Vận hành` (step 6) reports what the team learned afterwards: after a week the calls drop to two a day, and a cancelled order is still sending a notification that says it is on its way. That wrong behaviour, the file says, goes back to step 1 as a new need.

```markdown file=docs/team/lifecycle-example.md tag=stage-0 lines=36-39
Sáu bước trên luôn xảy ra, kể cả khi không ai gọi tên chúng. Khác biệt giữa các
phương pháp làm việc chỉ là **kích thước một vòng**: làm cả sáu bước cho một
tính năng nhỏ trong hai tuần, hay làm cả sáu bước cho cả hệ thống trong một năm.
Vòng nhỏ không tạo ra ít tài liệu hơn; nó làm cho việc sai sớm rẻ hơn.
```

*Kích thước một vòng* is the size of one trip. The last sentence is the one to carry away: a small trip does not produce fewer documents; it makes being wrong early cheaper.

## Beginners often think…

- **"Agile means no planning and no written decisions."** → Actually the repository's one-feature trip, a cancel button, still writes down the need, the scope decision and the conditions for passing. A small trip shortens the wait for feedback rather than removing the thinking. You notice this when a team that stopped writing decisions down spends each planning conversation re-deciding what it settled a month ago.
- **"Testing is a phase that starts when development finishes."** → Actually the conditions a tester checks are agreed before the code is written, so testing is an agreement being re-run, and the same trip also produces cases nobody agreed on in advance. You notice this when a problem found after release turns out to be a behaviour nobody ever decided on, because nobody agreed the conditions before the code.
- **"My task starts when the task arrives and ends when my code works."** → Actually the line you were handed is the output of two earlier steps and the input to three later ones, each settled by somebody else or by the whole team. You notice this when someone asks what your feature does to orders that are already paid, and the answer was settled in step 2 by the team, before you started.

## Try it (3 minutes)

1. Take the cancel-order feature above. For each of the six steps, write down in one short phrase the single thing that step handed to the next one.
2. Now mark which of your six answers you would produce yourself as a junior, and which arrive from somebody else.

Expected result: one of the six is entirely yours, one is shared with the tester, and the other four arrive from somebody else or from the whole team.

<details><summary>Suggested answer</summary>

Step 1 hands over a need in one sentence: customers want to cancel an undelivered order. Step 2 hands over a scope decision: `new` can be cancelled, `paid` goes to refunds. Step 3 hands over the built feature. Step 4 hands over a verdict against the agreed conditions, plus the case nobody thought of. Step 5 hands over a feature customers can use. Step 6 hands back a measurement and a new bug, the cancelled order that still says it is on its way, which becomes the next step 1.

Step 3 is yours. Step 4 is shared on many teams: you check the agreed conditions against your running code, and a tester re-runs them plus the cases nobody agreed on. The other four arrive from somebody else or from the whole team: step 1 from the product owner, step 2 from a team decision made before your code, steps 5 and 6 from whoever on your team releases and watches the system.

</details>

## Connections

- [[management.l1.scrum-from-junior-seat]] — one named way of fixing the size of a trip around this loop, and the meetings each step turns into.
- [[management.l1.user-story-and-ac]] — steps 1, 2 and 4 at the size of a single task: how a need becomes one sentence and a list of checkable conditions.
- [[devops.l1.what-is-deploy]] — step 5 opened up: what releasing actually does to the code you finished.

## Five-line summary

1. Your team's note names six steps every feature goes through: gathering needs, designing, building, testing, releasing and operating, whatever the method is called.
2. Those six steps are a loop, not a line: what you learn while the system runs becomes the next need to gather.
3. Methods differ mainly in how much of the system goes around that loop at once, from one small feature to everything.
4. Small trips make being wrong cheap because a decision meets real users in weeks; they do not mean less planning or fewer written decisions.
5. You build in step 3 and often share step 4 with a tester; the other four come from others or the whole team.
