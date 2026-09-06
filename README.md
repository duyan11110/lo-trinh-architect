# Lộ Trình Architect — Tài liệu thiết kế chi tiết V1

Bộ tài liệu này là **bản thiết kế có thể thực thi** của giáo trình "junior developer → architect":
mô hình dữ liệu nội dung, quy trình sinh–phản biện–biên tập, quy tắc chất lượng, bộ prompt,
schema kiểm tra máy, outline giai đoạn 0 và một bài mẫu chuẩn giọng.

Mục tiêu của cả bộ: **một mình bạn + Claude Code sinh ra ~650 bài học song ngữ, đúng kỹ thuật,
đều tay, kiểm tra được bằng máy trước khi bạn đọc.**

## Cấu trúc

```
lo-trinh-architect/
├─ README.md                  ← bạn đang đọc
├─ DECISIONS.md               ← quyết định của chủ + mặc định bắt buộc (agent đọc ngay sau CLAUDE.md; thắng mọi tài liệu khác)
├─ RUNBOOK.md                 ← trình tự chạy tự trị 7 bước tới bàn giao, mỗi bước có Done; `/autopilot` thực thi
├─ CLAUDE.md                  ← chỉ dẫn cho Claude Code khi làm việc trong repo nội dung
├─ .claude/                   ← skills (8 lệnh /…), agents (review-technical, review-junior), settings.json (quyền)
├─ docs/
│  ├─ 00-chuong-trinh.md      ← chương trình 5 giai đoạn × 8 track (đầu vào cho /outline)
│  ├─ 01-mo-hinh-noi-dung.md  ← track / lesson / quiz / skill / glossary / versions: cấu trúc & quy ước id
│  ├─ 02-quy-trinh-pipeline.md ← 6 bước từ outline đến build, công cụ, Definition of Done
│  ├─ 03-quy-tac-chat-luong.md ← quy tắc chống sai sót, style guide VI/EN, checklist biên tập
│  ├─ 04-app-v1-spec.md       ← hợp đồng dữ liệu giữa content.json và app Flutter
│  ├─ 05-ui-ux-flutter.md     ← thiết kế UI/UX: nguyên tắc, điều hướng, đặc tả 10 màn hình, token → ThemeData, component, quiz 6 loại, microcopy, a11y, responsive
│  ├─ 06-huong-dan-claude-code.md ← cách dùng bộ này trong Claude Code: skill /outline /lesson /quiz /translate /gate /repo-stage /gen-module, 2 subagent reviewer, quyền, headless
│  └─ 07-app-architecture.md  ← kiến trúc app: vị trí, pubspec, ngữ pháp Markdown, DDL, scheduler/rút đề, cập nhật từ xa, SVG theme, test, CI, milestone
├─ app/CLAUDE.md              ← chỉ dẫn riêng cho Claude Code khi dựng app Flutter (thư mục app/)
├─ AUDIT.md                   ← biên bản rà soát độc lập v1.2 → v1.3: đã sửa gì, còn gì
├─ schemas/                   ← JSON Schema: track, frontmatter, quiz, meta, review, glossary, path, outline-draft, content.json
├─ prompts/                   ← 9 prompt, dùng nguyên văn với Claude Code (xem docs/02)
├─ templates/                 ← khung bài, glossary hạt giống, versions.yaml
├─ content/path.yaml           ← thứ tự main path 5 giai đoạn (GĐ0 chốt, GĐ1–4 dự kiến)
├─ content/tracks/foundation/track.yaml ← outline đầy đủ Giai đoạn 0 (52 bài) + management/track.yaml (5 bài) = 57 bài GĐ0
├─ examples/                  ← bài mẫu EN+VI, quiz, claims, review, mẩu repo ví dụ, và content.sample.json (fixture cho app)
├─ tools/                     ← đặc tả validate/build (mã nguồn sinh bằng Claude Code)
└─ mockups/                   ← 6 artboard mockup (.dc.html) + canvas.json của design canvas, ảnh xem trước
```

## Bắt đầu như thế nào (tự trị)

Làm Bước 0 trong `RUNBOOK.md` (5 phút: máy có Docker/Flutter/.NET/Node/claude/gh, repo GitHub, bật Pages), mở Claude Code, gõ `/autopilot`. Agent chạy tới PR bàn giao. Phần dưới đây là cách làm từng bước bằng tay.

## Bắt đầu như thế nào (từng bước)

1. Đọc `docs/01` và `docs/03` trước — hai tài liệu này định nghĩa "đúng" là gì.
2. Cập nhật `templates/versions.yaml` theo phiên bản thực tế bạn đang dùng (đây là nguồn sự thật
   duy nhất về phiên bản cho mọi prompt).
3. Sinh `tools/validate` và `tools/build` từ đặc tả trong `tools/SPEC.md` bằng Claude Code.
4. Chạy pipeline (docs/02) cho module đầu tiên của `content/tracks/foundation/track.yaml`.
5. So bài sinh ra với `examples/` — nếu lệch giọng, sửa prompt trước khi sinh tiếp.

## Nguyên tắc bất biến

- **Nội dung là dữ liệu.** Markdown + YAML + JSON trong Git; app chỉ đọc `content.json`.
- **Hai thế giới, hai CLAUDE.md.** Gốc repo = nội dung (không sáng tạo ngoài prompt); `app/` = kỹ sư Flutter theo docs/07.
- **Không có bài nào được publish nếu chưa qua:** validate (máy) → review kỹ thuật (AI) →
  review "đọc như người mới" (AI) → bạn duyệt (người). Bốn cửa, không bỏ cửa nào.
- **Code trong bài phải tồn tại trong repo ví dụ Đơn Hàng** ở đúng tag. Không có code "minh họa"
  tự nghĩ ra — nếu chưa có trong repo, thêm vào repo trước (repo phải build và test xanh).
- **Mọi khẳng định kỹ thuật cụ thể** (số mặc định, hành vi, cú pháp) phải nằm trong danh sách
  `claims` để reviewer đối chiếu tài liệu chính thức. Không chắc → không viết, hoặc viết ở mức nguyên lý.
- **Một bài, một khái niệm, một sơ đồ, tối đa hai đoạn code.** Vi phạm → validate fail.
