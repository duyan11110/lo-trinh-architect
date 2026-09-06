# 07 — Ngân hàng câu hỏi bài kiểm tra cổng (`gate<N>.json`)

> Cách dùng: system = `00-system.md`. Chạy khi mọi bài main path của giai đoạn đã `approved`. Sinh theo **từng track**
> (một lần gọi = câu hỏi của một track trong giai đoạn) rồi gộp; cuối cùng một lần gọi riêng cho các câu `scenario` dài xuyên track.
> Ngữ cảnh: danh sách bài main path của giai đoạn với "Five-line summary" + `misconceptions` của từng bài; `STAGE.md` của tag;
> toàn bộ câu hỏi quiz bài học của giai đoạn (để **không lặp**); bảng Bloom của stage; `schemas/quiz.schema.json`.
> Sau khi sinh: `tools/validate content/gates/gate<N>.json`, rồi review 04 (chỉ bước 6 — quiz correctness) trên toàn ngân hàng.

---

## Task

Write {{count}} questions for the stage {{stage}} gate bank, covering track `{{track}}` (or: `cross-track scenarios`).
The gate decides whether the learner has *integrated* the stage, not whether they remember each lesson.

### Inputs

- Lessons in scope (id, title, five-line summary, misconceptions): {{lessons_digest}}
- Example system at `stage-{{stage}}`: {{stage_md}}
- All lesson-quiz questions of this stage (do NOT duplicate; you may *combine* their ideas): {{existing_questions}}
- Bloom row for stage {{stage}}: {{bloom_row}} (gate bank must match within ±5%)
- Target mix for this call: {{type_mix}} (e.g. "single 40%, multi 15%, truefalse 10%, order 10%, fill 10%, scenario 15%")

## What makes a gate question different from a lesson question

1. **It spans lessons.** Every gate question should require at least two lessons' ideas (mark all their `skills`). A question
   answerable from one lesson alone belongs in that lesson's quiz, not here.
2. **It is situated one step further than the lessons went.** Take the Đơn Hàng system at this stage and change one thing
   (a new requirement, a failure, a scale change) that the learner has not seen but can reason about from what they learned.
3. **It rewards the right habit, not the right fact.** At stage 0–1: "what would you check first", "which of these explains the symptom".
   At stage 2–3: "which option keeps the guarantee", "what breaks if". At stage 4: "which trade-off, under which constraint".
4. **Cross-track scenarios** (separate call): 3–5 per stage, `context` 80–150 words, touching ≥ 3 tracks, four options each a
   coherent plan; explanations for wrong options must name the condition under which that plan would be the best one.
5. **Distractors** still come from real misconceptions — use the `misconceptions` lists across lessons, especially ones that
   *sound* like they apply to the new situation but do not.

## Rules (in addition to prompt 03's rules, which apply with two exceptions: `scenario` IS used at stage 0 in the gate bank, with `context` 40–80 words; and questions carry no `section_ref`)

- Each question: `track`, `module`, `skills` (≥ 2 skills from ≥ 2 lessons where possible), no `section_ref`.
- Ids `gate{{stage}}.q<n>` continuing from `{{next_index}}`.
- Difficulty average for the bank: stage 0 ≈ 2.5, 1 ≈ 3.0, 2 ≈ 3.3, 3 ≈ 3.7, 4 ≈ 4.2.
- Per-track count is proportional to the number of main-path lessons the track has in the stage: `round(100 × lessons_track / lessons_stage)`,
  minimum 8 (validate Q14, ±20%). Cross-track scenarios (3–5) are a separate call and count for no track.
- "Worth rereading" in the app is derived from `skills` → the lessons that teach them, so every question's `skills` must be exact.
- Vietnamese and English as in prompt 03.

## Output

One ` ```json ` block: `{ "gate": "gate{{stage}}", "stage": {{stage}}, "questions": [ … ] }` — the pipeline merges calls.
Before output, verify: Bloom and type mix; every question lists ≥ 2 skills; no question duplicates an existing one
(> 70% shared tokens); every wrong option has both explanations.
