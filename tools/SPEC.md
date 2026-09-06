# tools/SPEC.md — Đặc tả công cụ (sinh mã bằng Claude Code)

Ngôn ngữ: **Dart** (cùng toolchain với app). Mã nguồn ở `tools/src/*.dart` với `tools/pubspec.yaml` riêng; mỗi công cụ có **wrapper bash** cùng tên không đuôi (`tools/validate`, `tools/known-vocab`, `tools/extract-code`, `tools/merge-outline`, `tools/capture-output`, `tools/build`) gọi `dart run` đúng thư mục — mọi tài liệu, skill và settings đều gọi qua wrapper. `tools/gen` là bash thuần (gọi `claude -p`), không phải Dart.
Exit code 0 = xanh, ≠ 0 = có lỗi; in lỗi dạng `LEVEL <id> <rule-code>: message` (LEVEL = E hoặc W) để dán ngược vào prompt.

Các thuật toán dùng chung (đếm từ, khớp thuật ngữ, chuẩn hóa tiêu đề, làm tròn Bloom) định nghĩa ở **Phụ lục A** cuối file — validate và app dùng cùng định nghĩa.

## validate

Đầu vào: một lesson id, một đường dẫn file (`content/gates/gate0.json`, hoặc bài ngoài cây như `examples/x.en.md` với `--file`), `--module <track>/<module>`, `--stage <n>`, hoặc không tham số (toàn bộ). Cờ: `--structure-only` (chỉ track.yaml/path.yaml/glossary), `--no-repo` (bỏ S07/L08 khi tag chưa tồn tại — dùng ở bước outline), `--repo-dir <dir>` (thư mục thường thay cho tag git — dùng cho `examples/don-hang-stage-0`), `--parity <id>`.

Quy tắc theo trạng thái: nhóm Q chỉ chạy khi `.quiz.json` tồn tại (bài `draft` chưa có quiz không lỗi); nhóm R chỉ chạy khi `status ≥ reviewed`; nhóm P chỉ khi có `.vi.md`.

### Mã lỗi và quy tắc

**Cấu trúc (S)**
- S01 `track.yaml` không qua `schemas/track.schema.json`.
- S02 lesson id trùng (toàn cục).
- S03 module trong `track.yaml` không có trong `path.yaml` (E); module trong `path.yaml` chưa có `track.yaml` (W — giai đoạn chưa outline).
- S04 `prereqs` trỏ tới id không tồn tại, hoặc có thứ tự toàn cục ≥ bài hiện tại.
- S05 `skills` không tồn tại trong bất kỳ `track.yaml` nào.
- S06 `vocab` chứa term đã được bài đứng trước khai báo, hoặc term không có trong `glossary.yaml`, hoặc `glossary.introduced_in` không khớp.
- S07 `example_files` không tồn tại trong repo ví dụ ở `example_tag` (kiểm bằng `git -C examples/don-hang show <tag>:<path>`, hoặc trong `--repo-dir`). Khi tag chưa tồn tại: W (cảnh báo) thay vì E; `tools/validate --manifest <stage>` in danh sách mọi `example_files` của giai đoạn để prompt 08 dùng làm manifest bắt buộc.
- S08 `related` trỏ tới id không tồn tại: **lỗi** nếu track/module của id đó đã có trong một `track.yaml`; **cảnh báo W** nếu module đó chưa được outline (id "hứa trước", cho phép; không chặn publish — app hiện chip "sắp có").

**Frontmatter & thân bài (L)**
- L01 frontmatter không qua `lesson-frontmatter.schema.json`; hoặc lệch với entry trong `track.yaml` (title, skills, prereqs, vocab, example_tag, main_path, duration_min).
- L02 thiếu/thừa/sai thứ tự mục H2. Danh sách chuẩn theo `lang` (docs/01 §4); bài level 4 có 11 mục (6 "Trade-offs"/"Đánh đổi", 7 "What would you choose if…"/"Bạn sẽ chọn gì nếu…"). So sánh sau chuẩn hóa: trim, gộp khoảng trắng, `...` ≡ `…`, không phân biệt hoa thường.
- L03 bài `main_path: false` thiếu blockquote "Skip this if:" / "Bỏ qua được nếu:" trước mục 1; bài main_path có blockquote đó.
- L04 mục 1 (mọi level): số bullet = số `prereqs`, mỗi bullet chứa đúng một `[[id]]` ∈ `prereqs`, tập id = `prereqs`. Bài có `prereqs: []`: đúng một bullet, không link, nội dung chính xác "No prerequisites — start here." / "Không cần gì trước — bắt đầu từ đây."
- L05 mục 2: 60–120 từ, câu cuối kết bằng `?`.
- L06 mục 3: 3–6 bullet; mọi term trong `vocab` xuất hiện in đậm **đúng một lần**, tại mục 3 (mục 1–2 được dùng từ ở dạng thường; từ mục 4 trở đi không in đậm lại).
- L07 mục 4: đúng 1 block ` ```mermaid `; parse được bằng mermaid CLI; ≤ 8 node; văn xuôi 150–300 từ.
- L08 code block: tổng ≤ 2 block có `file=` (mọi lang kể cả `markdown`/`text file=`); mỗi block ≤ 25 dòng; `file=` ∈ `example_files`, `tag=` = `example_tag`; nội dung khớp repo (xem `extract-code`). Block `text output=true` (không `file=`) phải đứng ngay sau một block `file=` trỏ tới script và khớp `outputs/<tag>/<script bỏ đuôi>.txt` (wildcard `...` = một vùng bất kỳ) — mã lỗi riêng L08b. Block `text` không có cả `file=` lẫn `output=true` → lỗi.
- L09 mục ngộ nhận (6, hoặc 8 ở level 4): ≥ 2 bullet; tiêu đề theo **stage** (0–2: Beginners…; 3–4: Seniors…); mỗi bullet bắt đầu bằng `**"…"**` rồi ` → `.
- L10 mục Thử ngay: có dòng bắt đầu "Expected result:" / "Kết quả mong đợi:".
- L11 mục Liên hệ: ≥ 2 `[[id]]`; ≥ 1 trong số đó trỏ tới bài **đã có trong một `track.yaml`**; phải chứa mọi id trong `related` đã tồn tại; id chưa tồn tại → W (không chặn publish; app hiện chip "sắp có").
- L12 mục Tóm tắt: đúng 5 dòng đánh số 1–5, mỗi dòng ≤ 25 từ, không có dòng khác.
- L13 tổng từ (bỏ code, frontmatter): 900–1.600 (level 1–3), 900–2.000 (level 4).
- L14 có URL (`http://`, `https://`, `www.`) trong thân bài.
- L15 dùng term trong `glossary` mà ∉ `known_vocab ∪ vocab` (thuật toán khớp Phụ lục A.2: bỏ code block, inline code, và từ viết HOA toàn bộ như `COMMIT`). Mức cảnh báo W, không chặn — reviewer 05 quyết.
- L16 in đậm một cụm không phải term của `vocab` — ngoại lệ duy nhất: câu ngộ nhận trích dẫn `**"..."**` ở đầu mỗi bullet mục ngộ nhận. Cảnh báo W.
- L17 chuỗi cấm: "latest version", "recently", "nowadays", "best practice" (không kèm "when"/"if" trong cùng câu), "In today's", "In conclusion", "!" ngoài code.
- L18 đoạn văn > 6 câu.

**Meta (M)**
- M01 `.meta.json` không qua schema; `id` lệch.
- M02 `coverage.outline_items_missing` khác rỗng; `outline_items_covered` không bằng tập 1..n của `outline`.
- M03 claim `kind ∈ {behavior, number, syntax, history}` có `needs_verification: false`.
- M04 `self_check.code_from_repo` hoặc `no_external_urls` là false.
- M05 số claim < 3 khi bài có ≥ 1 code block (nghi ngờ bỏ sót). Schema chỉ bắt ≥ 1.
- M06 `.meta.json` có `open_questions`/`repo_changes_needed` khác rỗng → W và in ra (người dùng quyết); validate bỏ qua hai trường này khi so schema.

**Quiz (Q)**
- Q01 không qua `quiz.schema.json`; `lesson`/`stage` lệch bài.
- Q02 số câu ∉ [5, 7] (bài) / < 90 (gate).
- Q03 phân bố Bloom lệch bảng docs/01 §6 quá ±1 câu (bài) / ±5% (gate).
- Q04 `section_ref` thiếu (bài) hoặc trỏ mục không có.
- Q05 phương án sai không có `explanation` tương ứng; `explanation` cho đáp án đúng thiếu `correct`.
- Q06 `misconception` không khớp (so gần đúng, ≥ 60% từ chung) một mục trong `misconceptions` của outline hoặc bullet mục 6.
- Q07 phương án chứa "all of the above"/"none of the above"/"tất cả"/"không ý nào".
- Q08 `single`/`scenario`: độ dài (ký tự EN) phương án đúng lệch > 60% so với trung bình các phương án (lộ đáp án).
- Q09 `truefalse`: 4 phương án; a,b có `polarity: "true"`, c,d `polarity: "false"`; văn bản EN bắt đầu "True, because"/"False, because", VI "Đúng, vì"/"Sai, vì".
- Q10 `scenario`: `context` < 40 hoặc > 150 từ; `explanation` của mỗi phương án sai không chứa "when"/"khi" (thiếu điều kiện nó đúng).
- Q11 `fill`: `question` không chứa `___`; `answer` rỗng.
- Q12 câu trùng ý (Jaccard token > 0.7) trong cùng quiz.
- Q13 `skills` của câu ⊄ `skills` của bài (quiz bài). Với gate: mọi skill phải tồn tại và ≥ 2 skill.
- Q14 gate: số câu mỗi track ∉ [round(100×bài_track/bài_stage) ± 20%] hoặc < 8; thiếu 3–5 câu `scenario` xuyên track.
- Q15 `order`: thứ tự `options` trong JSON trùng `answer` (chưa xáo).
- Q06 và Q13-bài không áp dụng cho gate (câu gate không thuộc một bài).

**Review (R)**
- R01 `.review.json` không qua schema; thiếu phần `technical` hoặc `junior` khi bài có `status ≥ reviewed`.
- R02 có claim `needs_verification: true` không có verdict (status ≥ reviewed).
- R03 còn `blocker` (status ≥ reviewed) hoặc còn `major` (status ≥ approved).
- R04 có claim verdict `wrong` (status ≥ reviewed — phải sửa bài rồi review lại), hoặc `unverified` với `kind ∈ {number, syntax}` (status ≥ approved). `unverified` với `fact`/`behavior`/`history` được phép ở `approved` nhưng in W để người dùng thấy khi duyệt.

**Parity VI/EN (P)** (`--parity`)
- P01 frontmatter khác nhau ngoài `lang`, `title` (trong đó `title` VI phải bằng `title.vi` trong `track.yaml`).
- P02 số mục H2, số code block, nội dung code block, số `[[id]]`, số bullet mục 1/3/6/8, số dòng mục 9 khác nhau.
- P03 term `vi_keep: true` bị dịch; term `vi_keep: false` không dùng đúng từ `vi` trong glossary (kiểm lần xuất hiện đầu).
- P04 bản VI có chuỗi "được thực hiện bởi", "một cách" (cảnh báo W).

**Path (T)** (`--structure-only`)
- T01 `path.yaml` không đủ 5 stage, module lặp, module không tồn tại.
- T02 bài main_path có prereq là bài nhánh phụ (cấm — nhánh phụ không được là điều kiện của main path).
- T03 `stage` của module trong `track.yaml` khác stage của nó trong `path.yaml`.

### Đầu ra phụ
- `validate --order`: in thứ tự toàn cục mọi bài (dùng cho debug S04).
- `validate --manifest <stage>`: in mọi `example_files` (kèm bài) của giai đoạn — manifest cho prompt 08.

## known-vocab
`known-vocab --before <lesson-id>` hoặc `--before-module <track>/<module>`: in mọi term có `introduced_in` đứng trước bài (hoặc trước bài đầu tiên của module) theo thứ tự toàn cục, JSON `[{term, en, vi, vi_keep, short_en, short_vi, aliases}]`. Đây là lệnh duy nhất cho việc này (không có `validate --known-vocab`).

## merge-outline
`merge-outline <track> <path-to-draft.yaml>`: kiểm draft theo `schemas/outline-draft.schema.json`; gộp `module` vào `content/tracks/<track>/track.yaml` (thêm mới hoặc thay module cùng id), gộp `skills` mới, gộp `glossary_additions` vào `content/glossary.yaml` (từ chối nếu term đã có với `introduced_in` khác); in `open_questions` và `repo_changes_needed`; rồi chạy `validate --structure-only --no-repo`. Đây là cách duy nhất glossary được sửa bởi công cụ — người dùng vẫn biên tập draft trước khi merge.

## extract-code
`extract-code <path> --tag <tag> [--lines a-b]` → in nguyên văn. Dùng `git show <tag>:<path>`. Chuẩn hóa khi so khớp: bỏ khoảng trắng cuối dòng, CRLF→LF, tab→4 space; không chuẩn hóa gì khác.

## capture-output
`capture-output <script-path> [--ref <ref>]` (mặc định working tree; nguồn sự thật là `scripts/capture-output.sh` trong repo Đơn Hàng, wrapper này gọi nó) → nếu ref ≠ HEAD thì checkout vào worktree tạm, `scripts/up.sh` (Compose) nếu chưa chạy, chạy script, ghi stdout+stderr vào `examples/don-hang/outputs/<tag>/<script bỏ đuôi>.txt`, rồi thay các vùng không ổn định bằng `...` theo `examples/don-hang/outputs/unstable.regex` (một regex mỗi dòng: Date header, ETag, id, timestamp). CI của repo ví dụ chạy lệnh này cho mọi script và fail nếu output đổi so với file đã commit (trừ vùng `...`).

## build
1. Chạy `validate` toàn bộ; dừng nếu có lỗi E. Chỉ đưa vào `content.json` các bài `status ∈ {approved, published}` (cả `.en.md` lẫn `.vi.md` phải có). `build --preview`: gồm cả `reviewed`, cho phép thiếu `.vi.md` (sections.vi rỗng), xuất `dist/preview/`, không tăng `content_version`.
2. Mermaid → SVG bằng `npx -y @mermaid-js/mermaid-cli` (`htmlLabels: false`, theme tùy chỉnh dùng **màu sentinel**: chữ/stroke `#010101`, nền node `#020202`, viền `#030303`, nền `#ffffff` → xóa), rồi hậu xử lý: inline CSS thành thuộc tính, xóa `<style>` và `<foreignObject>`; test: SVG không chứa hai thẻ đó. App thay 3 sentinel bằng token theme lúc load (docs/07 §6). SVG nhúng thẳng vào `content.json` (`lessons[id].diagram_svg`). `validate` không gọi mmdc (chỉ đếm node bằng Dart, A.5).
3. Tách thân bài theo H2 thành `sections[]` (giữ Markdown; block mermaid thay bằng dòng `{{diagram}}`; blockquote "Skip this if" đưa vào trường `skip_note`).
4. Gom `content.json` theo `schemas/content.schema.json`; bỏ `claims`, `review`, `status`, `reviewed_at`. Xuất `dist/content.json`, `dist/content.json.gz`, `dist/manifest.json` (`content_version`, `sha256`, `bytes`, `built_at`, `lessons_added[]`, `lessons_changed[]` so với build trước).
5. `content_version` = số trong `dist/VERSION` + 1 nếu hash nội dung đổi; ghi lại `dist/VERSION`.
6. `build --publish`: với mọi bài `approved` vừa được đưa vào build, đặt `status: published` ở cả `.en.md` và `.vi.md` (cách duy nhất status này được đặt).
7. In thống kê: số bài theo track/stage/status, số câu quiz, kích thước.

## fetch-refs · sync-app-content · fetch-web-sqlite
- `fetch-refs`: clone `--depth 1` 5 repo docs vào `refs/` và tải RFC 9110/9111/9112/6265 (txt) vào `refs/rfc/` (DECISIONS.md D9). Idempotent.
- `sync-app-content [--preview]`: cp `dist/(preview/)content.json` → `app/assets/content/content.json`, ghi `app/assets/content/VERSION`.
- `fetch-web-sqlite`: tải `sqlite3.wasm` + `drift_worker.js` đúng phiên bản gói trong `app/pubspec.lock`, kiểm sha256, ghi vào `app/web/`.

## gen (tự động hóa vòng lặp — bash, headless Claude Code)
`gen <track>/<module>`: bash script lặp qua các bài `draft`/chưa có của module theo thứ tự `track.yaml`, mỗi bước là một lệnh `claude -p` (xem docs/06 §6): `"/lesson $ID generate"` → `"/quiz $ID generate"` → `tools/validate $ID` → nếu lỗi, `"/lesson $ID fix-validation"`/`"/quiz $ID fix-validation"` (tối đa 2) → `"Dùng subagent review-technical cho bài $ID"` → `"Dùng subagent review-junior cho bài $ID; known_vocab: $(tools/known-vocab --before $ID)"` → nếu còn blocker/major: `"/lesson $ID apply-review"`, `"/quiz $ID apply-review"`, validate, review-technical lại (chỉ claim đã đổi) — tối đa 3 vòng. Bài chờ prereq được xếp lại cuối hàng. Sau vòng lặp: đặt `approved`/`approved_by: auto` theo DECISIONS.md D1; `claude -p --model sonnet "/translate $ID"`; `validate --parity`. `gen --stage <n>` chạy mọi module của giai đoạn theo `path.yaml`, rồi `"/gate <n> <track>"` cho từng track + `cross`, `build --publish`, `git add dist content && git commit`, `git push origin auto/stage-<n>`. Log `logs/gen-<date>.log`, báo cáo `logs/gen-<date>.md` (bảng bài × validate/technical/junior/status/approved_by/vòng, tổng lượt gọi). `/gen-module` (skill) là phiên bản tương tác của cùng vòng lặp cho một module.


## Phụ lục A — Thuật toán dùng chung (validate và app dùng cùng định nghĩa)

**A.1 Đếm từ.** Bỏ frontmatter, mọi code block (```…```), mọi dòng H2; thay `[[id]]` bằng một từ; inline code tính là một từ; tách theo khoảng trắng Unicode; số và ký hiệu đứng riêng là từ. Áp dụng cho L05, L07, L12, L13 và `self_check.word_count`.

**A.2 Khớp thuật ngữ (L15, tooltip app).** Với mỗi entry glossary, tập dạng hiển thị = {`en`, `vi`, `aliases`…}, thêm dạng số nhiều tiếng Anh đơn giản (+s/+es, y→ies). So khớp trên văn xuôi đã bỏ code block, inline code và các link `[[id]]`; không phân biệt hoa thường **trừ** token viết HOA toàn bộ ≥ 3 ký tự (`COMMIT`, `GET`) chỉ khớp entry có `en` viết HOA (`DNS`, `TCP`); ưu tiên cụm dài nhất tại một vị trí (`hash map` trước `map`); ranh giới từ Unicode hai phía. Kết quả: danh sách (term, vị trí). L15 báo term ∉ known ∪ vocab; app gắn tooltip cho mọi vị trí.

**A.3 Chuẩn hóa tiêu đề H2 (L02).** trim → gộp khoảng trắng → `...`→`…` → so sánh không phân biệt hoa thường với bảng tiêu đề theo `lang` và level.

**A.4 Làm tròn Bloom (Q03).** Với n câu và tỉ lệ p_i: kỳ vọng e_i = n·p_i; số câu hợp lệ cho mức i ∈ [⌊e_i⌋−1, ⌈e_i⌉+1] ∩ [0, n]; `analyze` và `evaluate` gộp chung. Gate: |thực tế − p_i| ≤ 5 điểm phần trăm.

**A.5 Đếm node Mermaid (L07).** `sequenceDiagram`: số `participant` (khai báo hoặc xuất hiện); `flowchart`: số node id duy nhất; `erDiagram`/`classDiagram`: số thực thể/lớp. ≤ 8.

**A.6 Khớp output (L08b).** Chuẩn hóa CRLF→LF, bỏ khoảng trắng cuối dòng; `...` trong block khớp `.*?` đa dòng (non-greedy) trong file output; so toàn bộ.

**A.7 So khớp code (L08).** Sau chuẩn hóa như `extract-code`: có `lines=a-b` → bằng đúng đoạn dòng a–b (số dòng của block phải = b−a+1); không có → block là chuỗi con liên tục của file.
