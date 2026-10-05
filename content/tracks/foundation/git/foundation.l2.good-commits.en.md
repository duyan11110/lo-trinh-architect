---
id: foundation.l2.good-commits
lang: en
track: foundation
level: 2
stage: 0
module: git
main_path: true
title: "Good commits: small, single-purpose, message says why"
duration_min: 10
skills: [foundation.git.model]
prereqs: [foundation.l2.git-mental-model]
related: [management.l1.code-review-basics]
vocab: []
example_tag: stage-0
versions_used: [git]
content_version: 1
status: published
approved_by: auto
reviewed_at: "2026-09-28T13:00:00+07:00"
---

## Before you start

- [[foundation.l2.git-mental-model]] — a commit is a full snapshot with a parent pointer, and `git add` decides what goes into it. That lesson says what a commit is; this one says what belongs in one.

## The situation

In the Git module's playground repository — the throwaway repository its scripts build for you — you open `README.md` and make two edits in one sitting: you mark the price list script work in progress, and you replace the note about prices with a line telling the reader to run `./test.sh`. Both edits sit in the same file, so you type one `git commit --all --message 'fix'` — `--all` stages every change to files Git already keeps, with no `git add`. Weeks later that instruction is wrong and you want it back out. `git log --oneline` offers one line reading `fix`, and taking it back also takes back the other edit. What belongs in one commit, and what should its message have said?

## Core concepts

- logical change — one thing done to the system that stands on its own: a fix, a rename, one new behaviour. It is the unit a commit should hold.
- subject line and body — the first line of a commit message, the one `git log --oneline` prints next to the abbreviated id, and everything after the blank line that follows it, where the reasoning goes.
- diff — the list of lines a change removes and adds: what `git diff` prints and what a reader of your commit sees. Each block of changed lines, together with the few unchanged lines Git prints around it (three by default), is a hunk, marked by a line starting `@@`; changes close enough to share those surrounding lines fall into one hunk. The hunk is the unit `git add --patch` offers you one at a time.
- revert — a new commit that undoes exactly what one earlier commit changed, written by `git revert <commit>`.
- blame — `git blame`, which names, for each line of a file, the commit that last changed it.
- bisect — `git bisect`, which repeatedly halves a range of commits to find the first one where a symptom appears.

## How it works

```mermaid
flowchart LR
  W["one sitting: two unrelated edits in README.md"] --> P{"git add --patch: stage this hunk? (asked once per hunk)"}
  P -->|"y, first hunk"| S1["staging area: first edit only"]
  P -->|"n, second hunk"| W2["working directory: second edit stays"]
  S1 --> C1["commit 1: one change, its own message"]
  W2 --> S2["staging area: second edit"]
  C1 -->|"then"| S2
  S2 --> C2["commit 2: revertable on its own"]
```

In the situation above, the two edits are one sitting but two logical changes: marking the script work in progress has nothing to do with telling the reader to run `./test.sh`. `git add --patch README.md` walks the file hunk by hunk and asks about each one, so the two edits reach the staging area separately even though they live in the same file. Answer `y` to the first question and `n` to the second, and the staging area holds one change while the working directory still holds the other. Commit, then stage and commit what is left: two commits out of one sitting.

What that buys you is every tool that works per commit. `git revert` writes one undo commit for one target, so a commit holding one change can be taken back without taking back anything else. `git blame` leads you from a line you distrust to the commit that last changed it, and so to that commit's message. `git bisect` halves the history to find the first commit where a symptom appears; the smaller each commit, the fewer lines you have left to read when it stops. On a team whose reviewers read commit by commit, each commit is judged in one go.

The message is the half the diff cannot supply. The diff says how the code changed and never which alternative you rejected or what forced the change. That is what the body is for; the subject line is what a reader meets first, alone, in a list.

## In the Đơn Hàng system

The example system keeps the team's rule for messages in a short file under `docs/git/`. Like the other files under `docs/`, it is written in Vietnamese, and it is quoted here as it stands:

```markdown file=docs/git/commit-message-examples.md tag=stage-0 lines=32-37
- Dòng đầu ≤ 50 ký tự, viết ở thể mệnh lệnh, nói **cái gì** thay đổi.
- Dòng thứ hai để trống.
- Phần thân nói **vì sao**, và phương án nào đã bị loại. Phần diff đã nói
  **như thế nào** rồi, đừng chép lại.
- Một commit là một thay đổi có thể revert riêng. Nếu bạn phải viết "và" ở dòng
  đầu, đó là hai commit.
```

Four rules, in order: keep the first line to 50 characters, in the imperative — `Mark the price list script work in progress` — saying what changes; leave the second line blank; put why in the body together with the option you rejected, since the diff already says how; and keep one commit to one change that can be reverted on its own — if the first line needs the word "and", that is two commits. Git's own documentation recommends the same shape — a summary line of no more than 50 characters, a blank line, then a fuller description — and checks none of that shape when you commit.

The rest of that file shows both sides: five one-line messages that nobody, the author included, can interpret three months later, and one whose body says why cancelling a paid order is now blocked — refunds are not built yet — and that marking such orders "awaiting refund" was turned down because nobody watches that state. Some teams also require a fixed prefix on the subject line, a convention called Conventional Commits; this repository's rule file does not ask for one.

The fourth rule feels impossible once both edits sit in the same file. A script in the repository makes that split anyway, on a playground repository it builds for itself:

```bash file=scripts/git/stage-partial.sh tag=stage-0 lines=10-27
git switch --quiet -c staging-demo main
sed -i '3s|.*|A tiny script that adds up a price list. Work in progress.|' README.md
sed -i '14s|.*|Run ./test.sh from this folder to check the total.|' README.md

echo "both edits are in the working tree:"
git diff --stat

echo
echo "answering y to the first hunk and n to the second:"
printf 'y\nn\n' | git add --patch README.md

echo
echo "what is staged:"
git diff --cached

echo
echo "what is still only in the working tree:"
git diff
```

```text output=true
both edits are in the working tree:
 README.md | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
...
what is staged:
diff --git a/README.md b/README.md
...
@@ -1,6 +1,6 @@
...
-A tiny script that adds up a price list.
+A tiny script that adds up a price list. Work in progress.
...
what is still only in the working tree:
diff --git a/README.md b/README.md
...
@@ -11,4 +11,4 @@ A tiny script that adds up a price list. Work in progress.
...
-Prices are in đồng, written as whole numbers.
+Run ./test.sh from this folder to check the total.
```

The first line makes a new branch `staging-demo` starting from `main`, so the demo edits stay off the main line of history. The two `sed` lines then make the two edits of the situation, on lines 3 and 14 of `README.md` — far enough apart that their surrounding lines do not meet, so `--patch` has two hunks to offer — and `git diff --stat` counts each rewritten line once as removed and once as added.

The `printf` feeds two answers into `git add --patch README.md`, which offers the two hunks in turn and takes the first only. The last two commands are the proof: `git diff --cached` shows the staged hunk alone, and `git diff` shows the other one still sitting in the working directory — `working tree`, the script's words, is Git's own name for what this lesson calls the working directory. The text after the second `@@` is not part of that hunk: it is an earlier line of the file that Git repeats as a label for where the hunk sits, and the hunk itself holds just the `-Prices…`/`+Run ./test.sh…` pair.

## Beginners often think…

- **"Commit messages do not matter because the code is what counts."** → Actually the code says what the system does now and never says why it was changed, and the commit message is the only reasoning stored inside the commit itself, so it is the only one that travels with the change. You notice this when you find a line that looks wrong, run `git blame` on it, follow the commit it names, and find `fix` — so you change the line back and reopen the bug it was closing.
- **"One commit per day is a reasonable rhythm."** → Actually the rhythm is one logical change, which may be three commits before lunch or one across two days, while a day-sized commit holds whatever you happened to touch. You notice this when reverting yesterday takes back a fix you still want, or `git bisect` stops at a commit of forty files and tells you nothing.
- **"I will tidy the history later, so anything goes now."** → Actually tidying later means reading a diff you no longer remember and inventing the reasoning after the fact; the cheapest moment to write why is while you still know it. You notice this when you sit down to split a week-old commit and cannot tell which lines belonged together.

## Try it (3 minutes)

1. From the top folder of the example system, run `scripts/up.sh`, which starts the example system the Git scripts run inside and is ready when it prints `The lab is up.`; then run `scripts/git/stage-partial.sh`, which builds its playground repository and makes the two edits.
2. In its output, compare the block under `what is staged:` with the block under `what is still only in the working tree:`, and count the `@@` lines in each.
3. Write the subject line you would give the staged change alone, in 50 characters or fewer, without the word "and".

Expected result: each block holds one `@@` line — one hunk staged, one hunk left behind — although both edits are in the same file and were made in the same sitting. A subject line for the staged change is something like `Mark the price list script work in progress`; if yours needed "and", it was describing both edits, which is the fourth rule telling you the split was right.

## Connections

- [[foundation.l2.git-mental-model]] — prerequisite: it says how a commit is stored, this one says what to put in it.
- [[foundation.l2.git-history-and-recovery]] — where commit quality is spent: `git blame` and `git revert` both take one commit as their unit.
- [[foundation.l2.git-bisect]] — the sharpest case of the same argument: halving only helps if each commit is one change.
- [[management.l1.code-review-basics]] — the same commits read from the other seat, by someone going through your change one commit at a time.

## Five-line summary

1. One commit holds one logical change — the unit you could revert on its own without taking back anything you still want.
2. The subject line says what in 50 characters or fewer; the body says why, and which option you rejected.
3. The diff already says how; the message is the commit's only place for why, so spend it on why and the rejected option.
4. `git add --patch` stages one hunk at a time, so two unrelated edits in one file can still become two commits.
5. `git revert`, `git blame`, `git bisect` and a reviewer reading commit by commit all work per commit, so commit quality is their quality.
