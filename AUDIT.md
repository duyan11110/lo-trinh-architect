# AUDIT.md — Rà soát độc lập v1.2 → v1.3

Ngày 06/09/2026. Một reviewer độc lập (không phải người viết) đọc toàn bộ 58 file của bộ thiết kế v1.2 và trả lời câu hỏi
"đã đủ để dựng app hoàn chỉnh bằng Claude Code chưa". Kết luận của reviewer: **đủ để bắt đầu pipeline nội dung và corpus GĐ0 sau khi
sửa ~6 điểm chặn; chưa đủ để dựng app end-to-end.** Bản v1.3 sửa toàn bộ các điểm dưới đây. Cột "Trạng thái" ghi cách sửa.

## A. Mâu thuẫn (25)

| # | Phát hiện | Trạng thái v1.3 |
|---|---|---|
| C1 | Frontmatter VI/EN "chỉ khác `lang`" vs thực tế khác cả `title` | docs/01: `lang` + `title`; P01 kiểm `title` VI = `title.vi` của outline |
| C2 | Mục 1 "2–4 bullet" vs bài có 0–1 prereq | Quy tắc mới: 1 bullet/prereq; không prereq → 1 dòng cố định (docs/01, SPEC L04, template, prompt 02) |
| C3 | L11 bắt mọi `[[id]]` tồn tại → deadlock cả GĐ0 vì `related` trỏ GĐ1–4 | L11: ≥ 2 link, ≥ 1 tới bài đã tồn tại; id hứa trước = W; app có chip "sắp có" (docs/04, 05, 07) |
| C4 | `context` scenario 40–80 / 40–150 / 80–150 | Quiz bài 40–150; cross-track gate 80–150; GĐ0 gate 40–80 |
| C5 | scenario cấm ở GĐ0 nhưng gate0 bắt buộc có | Prompt 07 ghi rõ ngoại lệ; prompt 03 trỏ tới ngoại lệ đó |
| C6 | Ví dụ docs/01 không qua schema (`order`, thiếu `no_external_urls`, `history`) | Sửa ví dụ |
| C7 | `content_version` tăng khi nào | Chỉ tăng khi sửa bài đã `published` (docs/01, prompt 02) |
| C8 | Cửa review khác nhau ở 4 chỗ | Một định nghĩa: cửa `reviewed` (không blocker, không `wrong`, mọi claim có verdict) và cửa `approved` (thêm: không major, không `unverified` number/syntax) — docs/02, docs/03, SPEC R03/R04, gen-module |
| C9 | Ai tạo tag `stage-N` | v1.3: sau xác nhận chủ; **v1.4 (DECISIONS D6/C1): agent tự tag khi đủ điều kiện** |
| C10 | `/gen-module` gọi skill có `disable-model-invocation` | Bỏ cờ ở `lesson`, `quiz`, `translate`, `status` |
| C11 | review-junior "không mạng" nhưng có Bash; phải đọc `technical` để merge | Bỏ Bash (known_vocab truyền qua lời giao việc); viết xong `junior` rồi mới mở file để gộp |
| C12 | Lệnh skill gọi nhưng SPEC không có | Thêm `known-vocab --before-module`, `validate <path>`, `--manifest`, `merge-outline`; thống nhất tên lệnh |
| C13 | Đường dẫn output và file văn xuôi không có cú pháp | `outputs/<tag>/<script bỏ đuôi>.txt`; fence `markdown file=`/`text file=`; prose chuyển sang `docs/<module>/` |
| C14 | Bài mẫu tự vi phạm (lines, số header, word_count, thiếu review, ngoặc ≠ short_vi) | Sửa hết; thêm `review.json` mẫu; word_count theo Phụ lục A.1 |
| C15 | Số bài/module 2–8 / 3–8 / 3–6 | 3–8 khắp nơi |
| C16 | Đánh số mục bài L4 và `section_ref` | 11 mục cố định; heading ngộ nhận theo stage; prompt 03 phân bố riêng cho L4 |
| C17 | ● hai nghĩa | Thêm ◉ cho "Học tiếp" |
| C18 | DDL docs/04 thiếu những gì docs/05 dùng | DDL đầy đủ ở docs/07 §4 (kind `review`, `scroll_ratio`, `prereq_warned`, `event`, term flashcard, gate tạm dừng) |
| C19 | Tooltip mọi lần hay chỉ in đậm | Mọi lần xuất hiện, thuật toán A.2 |
| C20 | Tô màu SVG 3 cách | Sentinel `#010101/#020202/#030303`, app thay chuỗi (SPEC build, docs/07 §6) |
| C21 | "Nên đọc lại" từ câu gate không có lesson id | Suy từ `skills` → `skills[].lessons` (content.json có trường `lessons`) |
| C22 | `truefalse` không có trường Đúng/Sai | `option.polarity` + thứ tự a,b true / c,d false (schema, prompt 03, SPEC Q09, mẫu) |
| C23 | "Học tiếp" kẹt ở bài `read` | Học tiếp = `new`/`opened`; bài `read` vào "Quiz đang chờ" |
| C24 | Quyền thiếu (`git -C`, `psql`, `dart`, 4 domain) | Thêm vào settings.json và allowed-tools |
| C25 | Tham chiếu `docs/brainstorm-v0.3.md` không tồn tại | Thêm `docs/00-chuong-trinh.md`; docs/04 trỏ docs/07 |

## B. Khoảng trống app (12) → `docs/07-app-architecture.md` + `app/CLAUDE.md` + `examples/content.sample.json` + `schemas/content.schema.json`

Vị trí app trong monorepo và CLAUDE.md riêng (G-A1); ngữ pháp Markdown mở rộng ở tầng AST (G-A2); thuật toán khớp glossary (G-A3, SPEC A.2);
giao thức cập nhật từ xa với `manifest.json` + `.gz` + sha256 + swap nguyên tử (G-A4); DDL đầy đủ + migration + FTS5 giữ dấu (G-A5); bảng bậc ôn tập
và mọi trường hợp cạnh (G-A6); quiz module (G-A7); thuật toán rút đề cổng (G-A8); `content.sample.json` làm fixture (G-A9); pubspec pin, bỏ
`flutter_markdown`, CI/deploy gh-pages, danh sách test bắt buộc (G-A10); ngôn ngữ UI theo ngôn ngữ nội dung, chip "sắp có" (G-A11);
parse trong isolate, LRU AST, index nền (G-A12).

## C. Khoảng trống pipeline (12)

| # | Phát hiện | Trạng thái v1.3 |
|---|---|---|
| G-P1 | 81 `example_files` chưa tồn tại → S07 chặn outline | S07 = W khi tag chưa có; `--no-repo`; `validate --manifest` là đầu vào bắt buộc của prompt 08 |
| G-P2 | Không có tool merge draft → track.yaml + glossary | `tools/merge-outline` + `schemas/outline-draft.schema.json` |
| G-P3 | Meta có trường ngoài schema | Schema cho phép `open_questions`, `repo_changes_needed`; M06 in cảnh báo |
| G-P4 | Validate khi chưa có sidecar | Quy tắc theo trạng thái ở đầu SPEC |
| G-P5 | `tools/gen` Dart gọi prompt thế nào | `gen` là bash gọi `claude -p` (SPEC, docs/06 §6) |
| G-P6 | `capture-output` mơ hồ | Định nghĩa worktree + `up.sh` + `unstable.regex` |
| G-P7 | Thiếu schema glossary/path/draft/content | Thêm 4 schema; kiểm tra thực tế trên file hiện có: xanh |
| G-P8 | Review ngân hàng cổng không có prompt | Prompt 04 chế độ gate; agent nhận đường dẫn gate; Q06/Q13 không áp cho gate |
| G-P9 | Thuật toán đếm từ/khớp term/Bloom/tiêu đề | SPEC Phụ lục A.1–A.7 |
| G-P10 | Validate không chạy được trên `examples/` | `--file`, `--repo-dir` |
| G-P11 | Ai đặt `published` | `tools/build --publish` |
| G-P12 | Prereq chưa có bài | gen-module ghi "chờ prereq", bỏ qua bài |

## D. Rủi ro (12)

| # | Phát hiện | Trạng thái v1.3 |
|---|---|---|
| R1 | 8 chỗ outline GĐ0 dùng term trước khi dạy | Sửa outline; chuyển `request`/`response` sang bài `url-to-page`; rà lại bằng script A.2 → 0 vi phạm |
| R2 | Docker/container ở GĐ0 | Thay bằng "lab box" qua `scripts/up.sh` + `ssh-into-lab.sh`; STAGE.md và prompt 08 cập nhật |
| R3 | Deadlock L11 | Xem C3 |
| R4 | `order` chưa xáo | Prompt 03 bắt xáo; Q15 kiểm |
| R5 | `truefalse` parse tiền tố | Xem C22 |
| R6 | Meta bắt ≥ 3 claim | Schema ≥ 1; M05 chỉ khi có code |
| R7 | Gate chia đều theo track | Tỉ lệ theo số bài (skill gate, prompt 07, Q14) |
| R8 | WebFetch chỉ trả tóm tắt | Ưu tiên `refs/` clone docs (docs/06 §2, §4; docs/03 A9; prompt 04; agent) |
| R9 | Cú pháp `arguments`/`$id` chưa chắc | Giữ, kèm fallback `$ARGUMENTS` (docs/06) — cần bạn xác nhận trên bản Claude Code đang cài |
| R10 | Gọi Dart từ root không có pubspec | Wrapper bash `tools/<name>` (SPEC) |
| R11 | `related` không bắt buộc trong track nhưng bắt buộc trong frontmatter | Bắt buộc ở cả hai; đã thêm `related: []` cho 25 bài |
| R12 | `…` vs `...` | L02 chuẩn hóa (A.3) |

## E. Còn lại (bạn quyết / kiểm tra tay)

1. `templates/versions.yaml` — mọi phiên bản là gợi ý, phải xác nhận bằng lệnh thật trước khi sinh bài.
2. Cú pháp skill/agent (`arguments`, `maxTurns`, `disable-model-invocation`) khớp với bản Claude Code bạn cài — chạy `/status` một lần để kiểm.
3. `docs/07 §2` pin major của gói; Claude Code phải `flutter pub outdated` và pin số cụ thể.
4. Repo ví dụ `stage-0` chưa tồn tại — là việc đầu tiên của `/repo-stage 0`; manifest 81 file lấy từ `tools/validate --manifest 0`.
5. Mockup canvas là tĩnh; text "Bài x/8" đã sửa cho khớp thứ tự module `http`.

## F. Vòng 2 (v1.3 → v1.4): "agent tự chạy không cần hỏi"

Reviewer độc lập mô phỏng một phiên Claude Code từ checkout trống tới app M7 và liệt kê **70 điểm** agent phải hỏi/đoán/dừng
(A setup 8 · B tools 13 · C repo ví dụ 13 · D pipeline 8 · E app 16 · F CI 6 · G quyền/chi phí 6) và 19 quyết định ngầm cần chủ ký.
Chủ đã trả lời 12 câu hỏi (DECISIONS.md mục 1); 58 điểm còn lại được chốt thành mặc định bắt buộc (DECISIONS.md mục 2), gồm cả những
điểm kỹ thuật reviewer phát hiện: cờ `--web-renderer` đã bị gỡ, `golden_toolkit` ngừng phát triển, SVG của mermaid-cli không tương thích
`flutter_svg` (cần `htmlLabels:false` + inline CSS), `git -C … push` lọt lưới deny, module chưa outline làm S03 fail, capture-output gà–trứng
với tag, khóa `npgsql` thiếu. `RUNBOOK.md` + skill `/autopilot` là trình tự chạy 7 bước tới PR bàn giao; việc chủ làm chỉ còn Bước 0.
