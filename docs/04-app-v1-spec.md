# 04 — Hợp đồng dữ liệu app V1

App Flutter V1 là trình đọc `content.json` + SQLite tiến độ. Tài liệu này chốt **hợp đồng dữ liệu và hành vi phụ thuộc nội dung**;
kiến trúc, DDL đầy đủ, ngữ pháp Markdown, giao thức cập nhật, scheduler và CI ở `docs/07-app-architecture.md` (nguồn sự thật khi hai tài liệu lệch nhau).

## 1. `content.json`

```jsonc
{
  "meta": {
    "content_version": 37,            // tăng mỗi build có thay đổi
    "built_at": "2026-10-01T20:12:00+07:00",
    "versions": { "dotnet": "10.0", "kubernetes": "1.34", ... },   // copy từ versions.yaml
    "langs": ["vi", "en"]
  },
  "path": {                            // từ path.yaml
    "stages": [
      { "stage": 0, "title": {"vi":"Nền tảng","en":"Foundations"}, "gate": "gate0",
        "modules": ["foundation/computer", "foundation/terminal", ...] }
    ]
  },
  "tracks": [ /* cây track → level → module → lesson (chỉ id + title + main_path + duration) */ ],
  "lessons": {
    "backend.l1.request-lifecycle": {
      "id": "...", "track": "backend", "level": 1, "stage": 1, "module": "web-server",
      "main_path": true, "duration_min": 12,
      "title": {"vi":"...","en":"..."},
      "skills": [...], "prereqs": [...], "related": [...], "vocab": [...],
      "example_tag": "stage-1",
      "sections": {                    // body đã tách theo 9 (hoặc 11) mục, Markdown
        "vi": [ {"n":1,"heading":"Bạn cần biết trước","md":"..."}, ... ],
        "en": [ ... ]
      },
      "diagram_svg": "<svg …>",          // Mermaid đã render, nhúng thẳng, 3 màu sentinel (docs/07 §6)
      "skip_note": null,                 // chuỗi "Bỏ qua được nếu…" cho bài nhánh phụ
      "content_version": 2
    }
  },
  "quizzes": { "backend.l1.request-lifecycle": { /* quiz.json nguyên vẹn */ } },
  "gates": { "gate0": { "questions": [...] } },
  "glossary": [ /* glossary.yaml nguyên vẹn */ ],
  "skills": [ { "id": "...", "title": {...}, "track": "...", "prereqs": [...], "lessons": ["...lesson ids teaching this skill..."] } ]
}
```

Kích thước ước tính 650 bài × 2 ngôn ngữ + SVG nhúng ≈ 9–11 MB JSON (≈ 2 MB gzip). Đóng gói làm asset (`assets/content/content.json`), tải bản mới dạng `.gz` theo giao thức docs/07 §7.

## 2. Render Markdown trong app

Ngữ pháp đầy đủ (info string, `[[id]]`, `{{diagram}}`, `<details>`, cấu trúc bullet mục ngộ nhận/liên hệ, "Expected result") ở docs/07 §3 — đây là hợp đồng giữa build và renderer. Tooltip thuật ngữ áp dụng cho mọi lần xuất hiện theo thuật toán SPEC Phụ lục A.2. Link `[[id]]` tới bài không có trong `content.json` render thành chip "sắp có" (không mở được).

## 3. Hành vi phụ thuộc dữ liệu

| Dữ liệu | Hành vi |
|---|---|
| `path.stages[].modules` + `lessons[].main_path` | "Học tiếp" = bài main_path đầu tiên có `status ∈ {new, opened}`; bài `read` (đã đọc, chưa qua quiz) hiện trong "Quiz đang chờ" trên trang chủ, không chặn "Học tiếp"; "còn N bài tới cổng" đếm main_path chưa `passed` trong stage |
| `prereqs` | Mở bài mà prereq chưa `passed` → hộp thoại nêu tên bài thiếu; cho phép tiếp tục |
| `quiz.questions[].section_ref` | Kết quả quiz: câu sai → nút "Đọc lại mục N" cuộn tới heading N |
| `quiz` ≥ 70% | Bài chuyển `passed`; < 70% → `read` (đã đọc, chưa qua) |
| Câu sai | Vào `review_item` bậc 0 (due +1 ngày); lịch bậc→khoảng và mọi trường hợp cạnh ở docs/07 §5 |
| `gates[gateN]` | Thi cổng: rút 35 câu theo thuật toán docs/07 §5.4 (tỉ lệ theo track như ngân hàng, ≥ 3 `scenario`, tránh lặp với lần thi trước); ≥ 75% → stage `passed`; làm lại không giới hạn. "Nên đọc lại" = bài dạy các `skills` của câu sai (`skills[].lessons`) |
| `vocab` | Khi bài chuyển `read`, mọi term trong `vocab` vào `vocab_seen` |
| `meta.content_version` | Lớn hơn bản đang có → hỏi cập nhật; sau cập nhật, bài đã `passed` giữ nguyên trạng thái dù `content_version` của bài tăng (chỉ hiện nhãn "đã cập nhật") |

## 4. SQLite

```sql
lesson_progress(lesson_id TEXT PK, status TEXT CHECK(status IN ('new','opened','read','passed')),
                first_opened_at TEXT, completed_at TEXT, best_score REAL)
quiz_attempt(id INTEGER PK, lesson_id TEXT, kind TEXT CHECK(kind IN ('lesson','module','gate')),
             started_at TEXT, finished_at TEXT, score INTEGER, total INTEGER, answers_json TEXT)
review_item(question_id TEXT PK, stage INTEGER DEFAULT 0, due_at TEXT, last_result INTEGER, times_seen INTEGER)
vocab_seen(term TEXT PK, first_lesson_id TEXT, seen_at TEXT)
stage_progress(stage INTEGER PK, gate_passed_at TEXT, best_gate_score REAL)
settings(key TEXT PK, value TEXT)          -- lang, theme, font_scale, content_version
```

DDL ở đây là tóm tắt; **DDL đầy đủ + migration ở docs/07 §4**. Xuất/nhập tiến độ = dump các bảng thành một JSON.

## 5. Tìm kiếm

FTS5 trên `title.vi`, `title.en`, và nối các `sections[].md` (bỏ code block). Kết quả nhóm theo track, hiện mục khớp.
