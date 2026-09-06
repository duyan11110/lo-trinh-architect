# 03 — Sinh quiz cho một bài (`.quiz.json`)

> Cách dùng: system = `00-system.md`. Chạy **sau khi** bài `.en.md` đã qua validate (quiz bám bài, không bám outline).
> Chế độ: `generate`, `fix-validation`, `apply-review` như prompt 02.
> Ngữ cảnh nạp: toàn văn `.en.md` của bài, entry outline (để lấy `misconceptions`), `known_vocab`, bảng phân bố Bloom theo stage
> (docs/01 §6), `schemas/quiz.schema.json`, và — chỉ để tránh trùng — danh sách câu hỏi (question text) của các bài cùng module đã có.

---

## Task

Write the quiz for lesson `{{id}}` (stage {{stage}}): 5–7 questions in both English and Vietnamese, as `{{id}}.quiz.json`.

**Mode:** {{mode}}
{{#if fix-validation}}Errors to fix, changing nothing else: {{validation_errors}}{{/if}}
{{#if apply-review}}Review items of kind `quiz` to apply: {{review_quiz_items}}{{/if}}

### Inputs

- Lesson text: {{lesson_en}}
- Outline misconceptions: {{misconceptions}}
- `known_vocab`: {{known_vocab}}
- Existing questions in this module (avoid duplicates): {{sibling_questions}}
- Bloom distribution for stage {{stage}}: {{bloom_row}}
- Vietnamese glossary rules for terms used: {{glossary_subset}}

## What a good question is here

The quiz exists to tell the learner **whether they understood**, and if not, **which section to reread**. It is not a test
of memory and not a trick. Every question must be answerable by someone who understood the lesson and *only* the lesson
plus its prerequisites — never by outside knowledge, never by pattern-matching option lengths.

1. **Anchor every question in a situation**, preferably in Đơn Hàng at the lesson's tag. "A customer submits an order and
   sees 201 — what does the client know for sure?" beats "What does 201 mean?".
2. **Distractors are real misconceptions.** At least one wrong option per question comes from the outline's
   `misconceptions` or the lesson's "Beginners often think…" section, and carries that text in its `misconception` field.
   The other distractors are *near-misses* — true statements that do not answer the question, or the right idea applied
   to the wrong case. Never absurd options.
3. **Explanations teach.** `explanation.correct` says why, in ≤ 3 sentences. Each wrong option's explanation first says
   *why a reasonable person picks it*, then why it fails here, then (for `scenario`) *when it would be the right choice*.
   Never just "Incorrect."
4. **`section_ref`** points to the section whose rereading fixes the misunderstanding. L1–L3 (9 sections): distribute across 3–6, at most
   one question on 2 or 8, none on 1, 7, 9. L4 (11 sections: 6 = Trade-offs, 7 = What would you choose if…, 8 = misconceptions): distribute
   across 3–8, at most one on 2 or 10, none on 1, 9, 11.
5. **Bloom mix for stage {{stage}}** must match `{{bloom_row}}` within ±1 question. `remember` questions (if any) still sit in a situation.
6. **Types.** Use at least 3 of the 6 types. Rules per type:
   - `single`: 4 options, 1 correct. Options within 60% of each other's length.
   - `multi`: 4–6 options, 2+ correct; the question says "select all that apply".
   - `truefalse`: a statement, then exactly 4 options in fixed order — a and b begin "True, because …" with `"polarity": "true"`, c and d begin
     "False, because …" with `"polarity": "false"` (VI: "Đúng, vì …" / "Sai, vì …") — only one fully right.
   - `order`: 3–6 steps of a flow taught in "How it works"; list the `options` in a SHUFFLED order (never the correct one — the app shows
     them as listed); `answer` lists option ids in the correct order.
   - `fill`: a line of code/YAML/command *from the lesson's code blocks* with one token replaced by `___`; `answer` lists all
     accepted spellings; optional `answer_regex`. Only for stage ≥ 1 and only when the token is meaningful, not a flag to memorise.
   - `scenario`: `context` (40–150 words: scale, team, constraint) + question + 4 options, each a defensible action; exactly one
     is best *in this context*; `bloom` ∈ apply/analyze/evaluate. Required at stage ≥ 2 (≥ 1 per quiz), allowed at stage 1, not in
     stage-0 lesson quizzes (the stage-0 gate bank is the exception, see prompt 07).
7. **Forbidden:** "all/none of the above", double negatives, questions about version numbers, flag names or exact defaults,
   quoting the lesson's definition verbatim as the correct option, two questions testing the same point, any option longer than 220 characters.
8. **Vietnamese.** Write `vi` as natural Vietnamese for a junior, following the glossary (`vi_keep` terms stay English and are
   not bolded in quiz text). Do not translate word by word; keep numbers, code, endpoints, status codes identical in both languages.
   Option lengths: in `single`/`scenario`, the correct option's EN length stays within 60% of the average option length.
9. **Difficulty** 1–5: 1–2 for `remember`/`understand`, 3 for `apply`, 4–5 for `analyze`/`evaluate`. A quiz at stage 0 averages ≤ 2.5; stage 4 averages ≥ 3.5.

## Output

One ` ```json ` block: the quiz per `schemas/quiz.schema.json`, `lesson` and `stage` filled, question ids `{{id}}.q1` … in order.
Before output, check: Bloom counts vs the row; every wrong option has an explanation in both languages; every `misconception`
text appears in the outline or the lesson; no two questions share > 70% of their tokens; `skills` of each question ⊆ lesson skills.
