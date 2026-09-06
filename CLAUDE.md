# CLAUDE.md — repo nội dung "Lộ Trình Architect"

Bạn (Claude Code) đang làm việc trong repo giáo trình. Người dùng là tác giả duy nhất; bạn là công cụ sinh,
kiểm tra và sửa nội dung theo các prompt trong `prompts/`. **Không sáng tạo ngoài prompt.**

**Đọc `DECISIONS.md` ngay sau file này.** Nó chứa mọi quyết định của chủ và mặc định bắt buộc cho phiên chạy tự trị; khi tài liệu khác nói khác, DECISIONS.md thắng. Không hỏi lại điều đã có ở đó; điều chưa có → chọn mặc định hợp lý, ghi vào mục 3 của DECISIONS.md, đi tiếp.

## Cấu trúc
- `docs/` — chương trình học (00), hợp đồng nội dung (01), pipeline (02), quy tắc chất lượng (03), hợp đồng app (04), UI/UX (05), hướng dẫn Claude Code (06), kiến trúc app (07). Với việc NỘI DUNG: đọc 01 và 03 trước. Với việc APP: chuyển vào `app/` — ở đó có `app/CLAUDE.md` riêng và quy tắc "không sáng tạo ngoài prompt" của file này không áp dụng.
- `schemas/` — JSON Schema; mọi file YAML/JSON sinh ra phải qua schema tương ứng.
- `prompts/` — 9 prompt, nguồn sự thật. Các skill trong `.claude/skills/` (`/outline`, `/lesson`, `/quiz`, `/translate`, `/gate`, `/repo-stage`, `/gen-module`, `/status`) và hai subagent trong `.claude/agents/` (`review-technical`, `review-junior`) chỉ là lối vào: chúng đọc prompt tương ứng và làm theo. Khi người dùng nói "sinh bài X", "review X"…, dùng đúng skill/subagent; không tự chế quy trình khác.
- `content/versions.yaml`, `content/glossary.yaml`, `content/path.yaml` — nguồn sự thật. Không sửa trừ khi được yêu cầu.
- `content/tracks/<track>/track.yaml` — outline. `content/tracks/<track>/<module>/<slug>.{en.md,vi.md,quiz.json,meta.json,review.json}`.
- `examples/don-hang/` — submodule repo ví dụ. Code trong bài PHẢI trích nguyên văn từ đây ở đúng tag.
- `tools/` — wrapper bash `validate`, `known-vocab`, `extract-code`, `merge-outline`, `capture-output`, `build`, `gen` (đặc tả `tools/SPEC.md`, kể cả Phụ lục A thuật toán).
- `refs/` — (tùy chọn) bản sao docs chính thức để reviewer Grep nguyên văn.
- `app/` — app Flutter (CLAUDE.md riêng).

## Lệnh
- `tools/validate <lesson-id>` · `tools/validate --module <track>/<module>` · `tools/validate --structure-only` · `tools/validate --parity <id>`
- `tools/known-vocab --before <lesson-id>` · `--before-module <track>/<module>` → term đã dạy trước bài/module (prompt 01, 02, 05, 06)
- `tools/merge-outline <track> <draft.yaml>` → gộp draft vào `track.yaml` + `glossary.yaml` (cách duy nhất glossary được sửa bởi công cụ)
- `tools/validate --manifest <stage>` → danh sách `example_files` bắt buộc cho `/repo-stage`
- `tools/extract-code <file> --tag <tag> [--lines a-b]` → in nguyên văn đoạn code để dán vào bài
- `tools/build` → `dist/content.json(.gz)` + `dist/manifest.json`; `--publish` đặt `status: published`
- `tools/gen <track>/<module>` → vòng lặp: prompt 02 → 03 → validate → 04 → 05 → sửa → lặp tới khi không còn blocker (tối đa 3 vòng, sau đó dừng và báo)

## Quy tắc cứng (vi phạm = dừng và báo, không tự "sửa cho hợp lý")
1. Không viết code block nào không tồn tại trong `examples/don-hang` ở tag khai báo (kể cả file văn xuôi `docs/*.md`). Cần code mới → đề xuất thay đổi repo ví dụ (prompt 08), chờ người dùng đồng ý.
2. Không dùng thuật ngữ ngoài `known_vocab ∪ vocab` của bài. Cần thêm → đề xuất sửa `vocab` trong `track.yaml`, chờ đồng ý.
3. Không viết khẳng định cụ thể (mặc định, giới hạn, cú pháp, thứ tự) mà không ghi vào `claims` của `.meta.json`.
4. Không nhắc phiên bản/tính năng ngoài `content/versions.yaml`.
5. Không thêm URL vào thân bài.
6. Review (04, 05) chạy trong **phiên mới**: không đọc `.meta.json`/prompt sinh trước khi tự đọc bài; với 04, đọc bài trước rồi mới mở `claims` để đối chiếu.
7. Không đổi `id` của bất kỳ thứ gì đã có `status != draft`. Tag `stage-N` chỉ khi đủ điều kiện DECISIONS.md C1.
8. Khi validate báo lỗi: sửa đúng lỗi được báo, không viết lại phần khác. Ghi lại thay đổi trong `self_check.notes`.
9. `status: approved` chỉ được đặt theo đúng điều kiện DECISIONS.md D1 (kèm `approved_by: auto`); `published` chỉ do `tools/build --publish`. Không có cách nào khác.
10. Nếu tài liệu chính thức không truy cập được khi review: verdict `unverified`, không suy đoán thành `verified`.

## Giọng
Tiếng Anh khi sinh bài (bản gốc), tiếng Việt khi dịch và khi trao đổi với người dùng. Ngắn, cụ thể, không mở đầu xã giao.
