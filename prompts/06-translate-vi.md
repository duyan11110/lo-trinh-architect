# 06 — Dịch bài sang tiếng Việt (`.vi.md`)

> Cách dùng: system = `00-system.md`. Chạy sau khi bài `.en.md` đã `approved`. Ngữ cảnh: `.en.md` toàn văn,
> `content/glossary.yaml` (chỉ các term xuất hiện trong bài + `known_vocab`), `docs/03` mục C2, và 1–2 bài `.vi.md` đã
> published cùng track làm mẫu giọng (hoặc `examples/foundation.l1.http-request-response.vi.md`).
> Sau khi dịch: `tools/validate --parity <id>`.

---

## Task

Translate lesson `{{id}}` from English to Vietnamese for a Vietnamese junior developer. The result must read as if it had been
written in Vietnamese by a senior Vietnamese engineer explaining to a younger colleague — not as a translation.

### Inputs

- English lesson: {{lesson_en}}
- Glossary entries for every term in this lesson and in `known_vocab`: {{glossary_subset}}
- Vietnamese voice sample: {{voice_sample_vi}}
- Vietnamese section titles (must be used exactly): 1 "Bạn cần biết trước" · 2 "Tình huống" · 3 "Khái niệm cốt lõi" ·
  4 "Cơ chế hoạt động" · 5 "Trong hệ thống Đơn Hàng" · (L4 only: "Đánh đổi" · "Bạn sẽ chọn gì nếu…") ·
  6 "Người mới hay nghĩ rằng…" (stage 0–2) / "Senior hay nhầm rằng…" (stage 3–4) · 7 "Thử ngay (3 phút)" · 8 "Liên hệ" · 9 "Tóm tắt 5 dòng".
  Optional-lesson blockquote: "> Bỏ qua được nếu: …". "Expected result:" → "Kết quả mong đợi:". `<summary>Suggested answer</summary>` → `<summary>Gợi ý đáp án</summary>`.

## Rules

1. **Terms follow the glossary, no exceptions.** `vi_keep: true` → keep the English word, bold on first appearance exactly where the
   English bolds it, followed by the `short_vi` in parentheses on that first appearance: **middleware** (thành phần đứng giữa request và response).
   `vi_keep: false` → use the `vi` word, bold on first appearance, with the English in parentheses the first time: **khóa chính** (primary key).
   Terms from `known_vocab` are used without bold and without parentheses. Never introduce a Vietnamese rendering the glossary does not have.
2. **Do not translate:** product names, commands, file names, class/method/variable names, table and column names, endpoints,
   HTTP methods and status codes, pattern names (Strategy, Observer…), Git subcommands, YAML keys, anything inside backticks or code blocks.
   Code blocks are copied byte-for-byte including the fence info string.
3. **Structure is identical:** same headings in the same order, same number of bullets in sections 1, 3, 6, 8, same 5 numbered lines
   in section 9, same `[[id]]` links in the same places, same Mermaid block unchanged (diagram labels stay English).
4. **Frontmatter identical** except `lang: vi` and `title` (use the Vietnamese title from the outline).
5. **Translate meaning, not words.** Reorder clauses when Vietnamese wants it. Prefer short sentences. Read each sentence aloud
   in your head: if it sounds like a translation, rewrite it. Forbidden fillers: "được thực hiện bởi", "một cách", "việc" as an empty nominaliser,
   "của bạn" when possession is obvious, "nó" repeated as an English "it".
6. **Register:** "bạn" for the reader; the author does not say "tôi". Neutral, warm, direct. No slang, no teenage internet Vietnamese.
7. **Punctuation and numbers:** Vietnamese comma spacing; thousands with dot (1.000), decimals with comma (0,5); a space between number and unit (10 ms);
   quotation marks " "; no semicolons in prose; keep the English text's absence of exclamation marks.
8. **Misconceptions** (section 6) keep the quoted-belief form: **"…"** → Thực ra …, vì …. Bạn sẽ nhận ra khi ….
9. **Quiz is not part of this task** — quizzes are bilingual at generation time (prompt 03).

## Self-check (fix silently, then output)

- Count: headings, bullets per section, code blocks, `[[id]]`, summary lines — equal to the English.
- Every bolded term: in `vocab` of this lesson, bolded exactly once, rendered per glossary.
- No English sentence left untranslated; no Vietnamese rendering of a `vi_keep` term.
- Search your output for the forbidden fillers and remove them.

## Output

One ` ```markdown ` block: the complete `.vi.md` including frontmatter.
