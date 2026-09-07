# 02 — Sinh một bài học (`.en.md` + `.meta.json`)

> Cách dùng: system = `00-system.md`. Một bài mỗi lần (Claude Code lặp qua module). Có ba chế độ:
> `mode: generate` (bài mới), `mode: fix-validation` (dán lỗi validate), `mode: apply-review` (dán `.review.json`).
> Ngữ cảnh nạp (Claude Code đọc file, không copy tay):
> - `content/versions.yaml`, `content/glossary.yaml`
> - entry của bài trong `track.yaml` (nguyên văn) + entry module (title, summary)
> - với mỗi prereq: frontmatter + mục "Five-line summary" của bài đó (không nạp cả bài)
> - `tools/known-vocab --before <id>` → `known_vocab`
> - `examples/don-hang/STAGE.md` ở `example_tag` + nội dung nguyên văn các `example_files` (`tools/extract-code`)
> - một bài đã `approved` cùng track (hoặc `examples/foundation.l1.http-request-response.en.md`) làm mẫu giọng
> - `templates/lesson.template.md`

---

## Task

Write lesson `{{id}}` in English, following `lesson.template.md` exactly, and its sidecar `{{id}}.meta.json`.

**Mode:** {{mode}}
{{#if fix-validation}}Validation errors to fix (change nothing else; keep every sentence not implicated by an error):
{{validation_errors}}{{/if}}
{{#if apply-review}}Review to apply (fix every `blocker` and `major`; for `minor`, apply if it costs one sentence or less;
for claim verdicts `wrong` → correct or remove the statement; `rephrased` → use `suggested_text`; `unverified` on
`number`/`syntax` claims → rewrite at the level of principle so the claim disappears). **Budget as you go, not after:**
adding review sentences is what most often pushes a lesson over §4's 150–300 words or the 900–1,600/2,000 total (§ Hard
constraints below) — cut an equal amount of prose the review did *not* ask about as you add, don't add first and trim
later. Same discipline for `.meta.json`: `claims[].text` ≤ 300 chars, `claims` ≤ 25 total, `self_check.notes` ≤ 500
chars — a review that adds claims eats this budget too; merge a new fact into an existing claim's table/list before
adding a new entry. Running out of round budget fighting these caps instead of the review's actual content is a real,
observed failure mode (tools/gen pilot, 2026-09-07).
{{review_json}}{{/if}}

### Inputs

- Outline entry: {{outline_entry}}
- Module: {{module_entry}}
- Prerequisite summaries: {{prereq_summaries}}
- `known_vocab` (terms you may use without defining): {{known_vocab}}
- `vocab` (terms this lesson must introduce — bolded once and defined in "Core concepts"): {{vocab}}
- Example system state (`STAGE.md` at `{{example_tag}}`): {{stage_md}}
- Example files, verbatim, with line numbers: {{example_files_content}}
- Versions in force: {{versions_yaml}}
- Voice sample (an approved lesson): {{voice_sample}}

## How to write it — in this order

1. **Read the outline items as a contract.** The lesson must establish each of them, in that order, and nothing beyond
   `depth_notes`. If an outline item is, to your knowledge, false for the pinned versions, stop and report it under
   `open_questions` in the meta file instead of writing around it.
2. **Find the situation first.** Pick a concrete moment in Đơn Hàng at `{{example_tag}}` where the learner *feels* the
   problem this lesson solves, before knowing its name. The situation section ends with one question; every later section
   answers that question. If you cannot find a situation in the example system at this tag, stop and report.
3. **Choose the code before the prose.** From `example_files`, select the ≤ 2 blocks (≤ 25 lines each) that best show
   the outline items. Copy them verbatim with `file=`, `tag=`, `lines=`. If the best illustration is not in the files,
   report it under `repo_changes_needed`; do not write substitute code.
4. **Draw the mechanism.** One Mermaid diagram, ≤ 8 nodes, showing order or containment — the thing a reader could not
   get from prose alone. Sequence diagram for a flow, flowchart for a decision or pipeline, ER for schema.
5. **Write the sections** in template order. The situation may mention a `vocab` word plainly, as people would say it; "Core concepts"
   is where each term is bolded once and defined in one sentence; "How it works" then uses it ("in the situation above, the thing that … is the middleware").
6. **Write "Beginners often think…"** from the outline's `misconceptions`. Form: **"quoted belief"** → Actually X, because Y.
   You notice this when Z (a symptom the junior will meet). Stage 3–4 lessons title this section "Seniors often assume…".
7. **Write "Try it"** as one action + one observation + "Expected result:" that the learner can verify in under 3 minutes
   with only the example repository or a terminal. Concept-only lessons use a thinking exercise with a `<details>` answer.
8. **Write "Connections"** stating the *relation* to each linked lesson ("the same idea one layer up", "the fix for the
   problem in", "prerequisite for", "the opposite of"). At least 2 links; include the ids in `related` when given.
9. **Write the five-line summary last.** Line 1 is the one sentence this lesson exists to teach. If you cannot write line 1
   as one sentence, the lesson has two ideas — report it.

## Hard constraints (validate will reject otherwise)

- Sections: exactly the 9 H2 headings from the template, in order, with those exact titles (level-4 lessons have 11: "Trade-offs" as 6 and
  "What would you choose if…" as 7, then the remaining four). The misconception heading follows the STAGE: "Beginners often think…" for stage 0–2,
  "Seniors often assume…" for stage 3–4. Optional lessons start with `> Skip this if: …`.
- "Before you start": exactly one bullet per prerequisite; a lesson with no prerequisites has exactly one bullet reading
  `No prerequisites — start here.`
- "Connections": at least 2 `[[id]]` links, at least one of them to a lesson that already exists in a `track.yaml`; ids promised by the
  curriculum but not yet outlined are allowed (the app shows them as "coming soon").
- Word count 900–1600 (L1–L3) or 900–2000 (L4), excluding code and frontmatter. Situation 60–120 words. How-it-works prose 150–300 words.
- Exactly one ` ```mermaid ` block; at most two blocks with `file=` (code, or `markdown file=`/`text file=` for a prose file of the
  repository), each ≤ 25 lines, `file=` from `example_files`, `tag={{example_tag}}`, `lines=a-b` matching the block's line count exactly;
  optional ` ```text output=true ` right after a script block, copied verbatim from `outputs/{{example_tag}}/<script without extension>.txt`.
- Every term in `vocab` is bolded exactly once, in "Core concepts", where it is defined; sections 1–2 may use the word plainly
  (the situation speaks in everyday words before naming things). No glossary term outside `known_vocab ∪ vocab` appears anywhere
  in prose. Bold is used for nothing else except the quoted belief opening each "Beginners often think…" bullet.
- No URL. No person's name, date, quote or market figure. No "latest", "recent", "nowadays", "best practice" without a condition.
  No exclamation marks. Paragraphs ≤ 6 sentences.
- Frontmatter copied from the outline entry (including `related`, `[]` when absent); `lang: en`, `status: draft`, `versions_used` = the version keys
  the lesson depends on. `content_version` stays `1` until the lesson is published; fix/apply modes before publish do not change it;
  a change to a `published` lesson increments it by one.

## The claims ledger (`.meta.json`) — this is not optional

After writing, re-read the lesson sentence by sentence and list **every** statement a reviewer could check against
documentation or by running code: defaults, limits, orders, syntax, API names, behaviour on error, what the pinned
version does. Classify each (`fact`, `behavior`, `number`, `syntax`, `opinion`, `history`), give the `section` number,
a `source_hint` naming the official document section a reviewer should open, and `version_key` where relevant.
`behavior`, `number`, `syntax`, `history` are always `needs_verification: true`.

Then ask, for each claim: *would I bet the lesson on this?* If not, go back and either remove the sentence or lift it
to a principle that needs no claim. Fewer, safer claims beat many risky ones. A lesson with zero claims is suspicious
(you probably forgot some), and so is one with more than 25 (you are teaching too much).

Fill `coverage` honestly: which outline items the lesson establishes (by number), which it misses, and anything it says
beyond `depth_notes`. Fill `self_check`.

## Output

Two fenced blocks, nothing else:

1. ` ```markdown ` — the full `.en.md` including frontmatter.
2. ` ```json ` — the `.meta.json` per `schemas/meta.schema.json`; `open_questions` and `repo_changes_needed` are optional top-level
   arrays (validate ignores them, the pipeline reports them). `self_check.word_count` uses the counting rule in `tools/SPEC.md` Appendix A.1.

If you had to stop (false outline item, no situation, missing code, unavoidable unknown term), output only:
` ```json ` with `{"blocked": true, "reasons": ["..."], "proposals": ["..."]}`.
