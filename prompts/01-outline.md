# 01 — Outline một module (sinh `track.yaml` entries)

> Cách dùng: system = `00-system.md`. Chạy cho **một module** mỗi lần. Đầu ra là YAML để bạn dán vào
> `content/tracks/<track>/track.yaml` và **biên tập tay** trước khi sinh bài — đây là bước bạn đầu tư nhiều nhất.
> Ngữ cảnh nạp: chương trình chi tiết (brainstorm v0.3 mục 5, phần track & level liên quan), `content/path.yaml`,
> `content/glossary.yaml`, `content/versions.yaml`, mọi `track.yaml` đã có (để tham chiếu skill/prereq/vocab hiện hữu),
> `examples/don-hang/STAGE.md` của tag tương ứng và cây file của repo ở tag đó (`git ls-tree -r --name-only <tag>`).

---

## Task

Produce the `track.yaml` entries (skills + one module with its lessons) for:

- track: `{{track}}` · level: `{{level}}` · module id: `{{module_id}}` · stage: `{{stage}}` · example tag: `{{example_tag}}`
- module intent (from the curriculum): {{module_intent}}
- lessons that come BEFORE this module on the main path (ids + titles): {{prior_lessons}}
- terms already introduced by those lessons (`known_vocab`): {{known_vocab}}
- skills already defined across all tracks: {{existing_skills}}
- example repository file tree at `{{example_tag}}`: {{repo_tree}}
- `STAGE.md` for `{{example_tag}}`: {{stage_md}}

## Rules for the outline

1. **Slice by concept, not by topic.** Each lesson teaches exactly one idea a junior can state in one sentence. If your draft
   title contains "and" or a comma, split it. 3–8 lessons per module; 10–15 minutes each.
2. **Order by dependency inside the module** — the lesson that introduces a term precedes every lesson that uses it.
3. **Prerequisites** point only to lessons in `{{prior_lessons}}` or earlier in this module. At most 4. Choose the *closest*
   prerequisites, not the most fundamental ones (prefer the lesson that introduced the term over the lesson that introduced its ancestor).
4. **Vocabulary.** For each lesson list the glossary terms it *introduces* (at most 6). A term may be introduced once in the
   whole curriculum: check `known_vocab` and the other tracks' `track.yaml`. For each new term, also output a glossary entry
   (see output format). Prefer plain words over new terms; a term earns its place only if later lessons will reuse it.
5. **`outline` (3–6 items)** is a contract, not a table of contents: each item is a *statement the lesson must establish*,
   written as a full sentence, specific enough that a reviewer can say yes/no to "does the lesson establish this".
   Bad: "Middleware pipeline". Good: "Middleware runs in the order it is registered, and any middleware can short-circuit the pipeline."
   Do not write outline items you are not sure are true — the outline is where errors enter first.
6. **`misconceptions` (2–4)** are things a junior *actually* believes, phrased as the junior would say them, each one
   wrong in a way this lesson corrects. They become the "Beginners often think…" section and the distractors in the quiz.
   Avoid straw men ("HTTP is a database"); prefer near-misses ("A 404 means the server is down").
7. **`example_files`** name the files in the repository at `{{example_tag}}` that the lesson may quote (at most 4, from the
   tree provided). If nothing suitable exists, list what the repository would need under `repo_changes_needed`
   instead of inventing a file.
8. **`depth_notes`** state explicitly what the lesson must *not* cover, naming the later lesson that will.
9. **`main_path`** is true unless the lesson is genuinely optional for the stage's gate. Optional lessons may not be
   prerequisites of main-path lessons.
10. `duration_min` 8–15 for concept lessons, up to 18 when a lesson has two code blocks to walk through.
11. Titles are specific and concrete (EN ≤ 70 chars; VI natural, not a translation of the EN word by word). A title states
    the idea or asks the question the lesson answers, never a bare noun ("Middleware").

## Output format (YAML only, no prose before or after)

```yaml
skills:                       # NEW skills only; reuse existing ids where they fit
  - id: <track>.<area>.<name>
    title: { vi: "...", en: "..." }
    prereqs: [ ...existing or new skill ids... ]

module:
  id: {{module_id}}
  title: { vi: "...", en: "..." }
  stage: {{stage}}
  summary: { vi: "...", en: "..." }        # one sentence: what the learner can do after this module
  lessons:
    - id: {{track}}.l{{level}}.<slug>
      title: { vi: "...", en: "..." }
      main_path: true
      duration_min: 12
      skills: [ ... ]
      prereqs: [ ... ]
      related: [ ... ]                      # may include ids of lessons not yet written, if listed in the curriculum
      vocab: [ ... ]
      example_tag: {{example_tag}}
      example_files: [ ... ]
      outline:
        - "..."
      misconceptions:
        - "..."
      depth_notes: "..."

glossary_additions:
  - term: <slug>
    en: "..."
    vi_keep: true|false
    vi: "..."
    short_vi: "..."
    short_en: "..."
    introduced_in: <lesson id>

repo_changes_needed:          # empty list if none
  - lesson: <lesson id>
    need: "one sentence: what code/script must exist and why"
    suggested_path: "src/..."

open_questions:               # things only the author can decide; empty if none
  - "..."
```

## Self-check before you answer (fix silently, then output)

- Every `prereqs` id exists in `{{prior_lessons}}` or earlier in this module, and no main-path lesson depends on an optional one.
- No `vocab` term appears in `known_vocab` or another track's `vocab`.
- Every `outline` item is a checkable sentence you believe is true for the pinned versions.
- Every `example_files` path is in the provided tree.
- No lesson needs a term it neither has in `vocab` nor in `known_vocab` to be explained — if one does, either add the term
  (and its glossary entry) or add an `open_questions` item proposing to move the lesson later.
