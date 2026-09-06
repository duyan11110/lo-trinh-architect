# 07 — Kiến trúc app Flutter V1 (đặc tả đủ để Claude Code dựng)

Tài liệu này là **nguồn sự thật kỹ thuật** của app: nơi app sống trong repo, gói và phiên bản, ngữ pháp Markdown mà renderer phải
hiểu, DDL đầy đủ, thuật toán ôn tập và rút đề, giao thức cập nhật nội dung, tô màu SVG, test bắt buộc, CI/deploy, và thứ tự
milestone cho Claude Code. docs/04 (hợp đồng dữ liệu) và docs/05 (UI/UX) mô tả *cái gì*; tài liệu này chốt *bằng cách nào* — khi
lệch nhau, tài liệu này thắng.

---

## 1. Vị trí và ranh giới

- App nằm trong **cùng monorepo**, thư mục `app/`, có `app/CLAUDE.md` riêng (Claude Code nạp CLAUDE.md lồng nhau khi làm việc trong `app/`).
  Lý do: app đọc `dist/content.json` của repo nội dung khi phát triển; một repo, một `git log`.
- Tên package Dart: `lta_app`. Android `applicationId`: `dev.lotrinharchitect.app`. `minSdk 26`, `targetSdk` theo Flutter stable.
  Web: renderer mặc định của Flutter (không dùng cờ `--web-renderer`, đã gỡ), base href `/lo-trinh-architect/app/`, PWA `--pwa-strategy offline-first`.
- **Không nhầm với `DonHang.App`** — đó là Flutter client trong repo ví dụ Đơn Hàng (đối tượng để *dạy*), không phải app này.
- Pin Flutter/Dart cho app **độc lập** với `content/versions.yaml` (file đó phục vụ nội dung dạy). App pin trong `app/pubspec.yaml`
  (`environment.sdk`) và `app/.fvmrc` (FVM); dùng đúng bản `flutter --version` bạn có, ghi vào `app/CLAUDE.md`.

```
app/
├─ CLAUDE.md
├─ pubspec.yaml            ← phiên bản pin, xem §2
├─ .fvmrc
├─ assets/
│  ├─ content/content.json         ← bản đóng gói (copy từ dist/ lúc build, xem §7)
│  ├─ fonts/BeVietnamPro-{Regular,Medium,Bold}.ttf, JetBrainsMono-{Regular,Medium}.ttf   (OFL, tải một lần, commit)
│  └─ l10n/ (sinh từ lib/l10n/*.arb)
├─ lib/
│  ├─ main.dart
│  ├─ app/            router.dart · shell.dart · theme/{tokens.dart, theme.dart, text.dart}
│  ├─ content/        models/ · content_repository.dart · content_loader.dart (asset | remote) · markdown/{grammar.dart, blocks.dart, prose.dart} · glossary_matcher.dart · svg_theming.dart
│  ├─ progress/       database.dart (drift) · tables.dart · migrations.dart · progress_repository.dart · review_scheduler.dart · gate_sampler.dart · export_import.dart
│  ├─ features/       home/ · path/ · lesson/ · quiz/ · review/ · gate/ · search/ · settings/
│  ├─ shared/         widgets dùng chung (docs/05 §6)
│  └─ l10n/           app_vi.arb · app_en.arb (microcopy docs/05 §7)
├─ test/              unit · widget · golden (fixture ở test/fixtures/, xem §9)
├─ integration_test/
└─ web/               index.html · manifest.json · sqlite3.wasm · drift_worker.js (copy từ package lúc build)
```

## 2. Gói và phiên bản (pubspec)

Pin theo **major** đã kiểm tra tồn tại tại thời điểm viết; Claude Code chạy `flutter pub outdated` và pin số cụ thể vào `pubspec.lock` (commit).

| Vai trò | Gói | Ghi chú |
|---|---|---|
| State | `flutter_riverpod ^3`, `riverpod_annotation`, `riverpod_generator` (dev) | `Notifier`/`AsyncNotifier`; không dùng `StateProvider` cho logic |
| Điều hướng | `go_router ^16` | `ShellRoute` cho bottom nav / rail |
| DB | `drift ^2.2x`, `drift_flutter` (native), `sqlite3_flutter_libs`; web: `drift` WASM (`sqlite3.wasm` + `drift_worker.js` trong `web/`) | FTS5 có sẵn trong sqlite3 bundle của cả hai |
| Markdown | `markdown ^7` (Dart AST) — **renderer tự viết** trên AST (§3). Không dùng `flutter_markdown` (đã ngừng phát triển) | `flutter_highlight`/`highlight` chỉ để tô màu code; nếu thiếu ngôn ngữ (`csharp`, `yaml`, `bash`, `dart`, `sql`, `json`) thì fallback không tô |
| SVG | `flutter_svg ^2` | SVG đã qua §6, dùng `SvgPicture.string` |
| File | `share_plus`, `file_picker` (xuất/nhập tiến độ) | web: tải/đọc qua `<a download>`/`FilePicker` |
| Nén | `archive` (gunzip `content.json.gz`) | |
| Hash | `crypto` (sha256 kiểm manifest) | |
| Mạng | `http` | chỉ cho §7 |
| Thông báo | — (bỏ khỏi V1, DECISIONS.md E5; setting giờ nhắc ẩn) | |
| i18n | `flutter_localizations`, `intl` | ARB → `gen-l10n` |
| Test | `flutter_test`, `alchemist` (golden, Linux CI only), `integration_test`, `mocktail` | |

Không dùng: `google_fonts` (font bundle), `webview_flutter` (sơ đồ là SVG), bất kỳ gói analytics nào.

## 3. Ngữ pháp Markdown mở rộng (hợp đồng build ↔ renderer)

Đầu vào renderer là `lessons[id].sections[lang][n].md` — Markdown CommonMark do `tools/build` cắt theo H2. Renderer parse bằng `markdown`
(`ExtensionSet.gitHubFlavored` + fenced code + tables) rồi duyệt AST thành widget. Các mở rộng, **tất cả xử lý ở tầng AST/inline, không regex trên chuỗi cuối**:

| Cú pháp | Ở đâu | Renderer làm gì |
|---|---|---|
| ` ```<lang> file=<path> tag=<tag> [lines=a-b]` | fence info string, thứ tự khóa cố định, phân tách bằng một dấu cách, không nháy | `CodeBlock(lang, file, tag, lines, code)`: header chip `file` + chip `tag` + "dòng a–b"; mono, cuộn ngang, không wrap, nút copy |
| ` ```text output=true` | fence | `OutputBlock`: nền `surface2`, nhãn "output", mono |
| ` ```mermaid` | **không xuất hiện** trong sections (build đã thay) | — |
| dòng đúng `{{diagram}}` | mục 4 | `DiagramView(lessons[id].diagram_svg)` (§6); nếu `diagram_svg` null → khung "Sơ đồ chưa render" |
| `[[lesson.id]]` | inline, bất kỳ đâu ngoài code | `LessonLinkChip`: có trong `lessons` → chip tiêu đề + StatusDot, chạm push `/learn/:id`; không có → chip "sắp có" mờ. Inline syntax đăng ký với `markdown` (`InlineSyntax` pattern `\[\[([a-z0-9.-]+)\]\]`) |
| `**term**` in đậm | mục 3 | `TermSpan` nếu văn bản (sau bỏ ngoặc đơn) khớp glossary `en`/`vi`/aliases; ngược lại bold thường |
| văn bản thường khớp glossary | mọi đoạn văn ngoài code | `TermSpan` (gạch chân chấm) theo thuật toán SPEC Phụ lục A.2 — chạy trên text node của AST, ưu tiên cụm dài nhất, bỏ token HOA toàn bộ trừ khi `en` HOA |
| bullet mục ngộ nhận: `- **"…"** → …` | mục 6 (L4: 8) | tách tại ` → ` đầu tiên: `MisconceptionCard(belief, truth)`; nếu không có ` → `, render bullet thường |
| bullet mục 1 / Liên hệ: `- [[id]] — …` | mục 1, 8/10 | `LessonLinkChip` + `relationText` (phần sau ` — `) |
| dòng `Expected result:` / `Kết quả mong đợi:` | mục Thử ngay | `TryItPanel.expected` (phần sau dấu hai chấm, có thể nhiều dòng tới hết mục) |
| `<details><summary>…</summary>…</details>` | mục Thử ngay | HTML block → `ExpansionTile(summary)`; nội dung bên trong parse lại như Markdown |
| bảng GFM | mục Đánh đổi (L4) | `DataTable` trong `SingleChildScrollView` ngang |
| blockquote đầu bài `> Skip this if:` | **không** trong sections (build đưa vào `skip_note`) | banner "Tùy chọn · …" dưới tiêu đề |
| inline code, italic, danh sách số/không số, đoạn văn | | widget chuẩn theo TextTheme |

Không hỗ trợ và không xuất hiện (validate chặn): HTML khác `<details>`, ảnh, link URL, H1/H3+, footnote.

## 4. SQLite — DDL đầy đủ và migration

Drift `schemaVersion = 1`. Mọi thời điểm là ISO 8601 UTC (`TEXT`). Không có khóa ngoại tới nội dung (nội dung có thể đổi phiên bản).

```sql
CREATE TABLE lesson_progress (
  lesson_id       TEXT PRIMARY KEY,
  status          TEXT NOT NULL CHECK (status IN ('new','opened','read','passed')),
  first_opened_at TEXT,
  read_at         TEXT,
  passed_at       TEXT,
  best_score      REAL,                 -- 0..1
  scroll_ratio    REAL NOT NULL DEFAULT 0,
  prereq_warned   INTEGER NOT NULL DEFAULT 0,
  content_version INTEGER               -- phiên bản bài lúc passed (hiện nhãn "đã cập nhật" khi khác)
);

CREATE TABLE quiz_attempt (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  kind         TEXT NOT NULL CHECK (kind IN ('lesson','module','review','gate')),
  ref_id       TEXT NOT NULL,           -- lesson id | track/module | review session id | gate id
  started_at   TEXT NOT NULL,
  finished_at  TEXT,                    -- NULL = đang dở (kể cả gate tạm dừng)
  score        INTEGER,
  total        INTEGER,
  question_ids TEXT NOT NULL            -- JSON array: thứ tự câu đã rút (để tiếp tục và để tránh lặp ở gate)
);

CREATE TABLE quiz_answer (
  attempt_id   INTEGER NOT NULL REFERENCES quiz_attempt(id) ON DELETE CASCADE,
  question_id  TEXT NOT NULL,
  answer       TEXT NOT NULL,           -- JSON: ["b"] | ["a","c"] | ["b","d","c","a"] | ["utf-8"]
  correct      INTEGER NOT NULL,        -- 0/1
  answered_at  TEXT NOT NULL,
  flagged      INTEGER NOT NULL DEFAULT 0,   -- gate: "đánh dấu xem lại"
  PRIMARY KEY (attempt_id, question_id)
);

CREATE TABLE review_item (
  item_id      TEXT PRIMARY KEY,        -- question id, hoặc "term:<slug>" cho flashcard thuật ngữ
  kind         TEXT NOT NULL CHECK (kind IN ('question','term')),
  source_lesson TEXT,                   -- lesson id (câu) / introduced_in (term); NULL cho câu gate
  tier         INTEGER NOT NULL DEFAULT 0,   -- bậc 0..4 (gọi là "bậc" trong UI, tránh nhầm "stage" giáo trình)
  due_at       TEXT NOT NULL,
  last_result  INTEGER,
  times_seen   INTEGER NOT NULL DEFAULT 0,
  retired      INTEGER NOT NULL DEFAULT 0    -- 1 = đã qua bậc 4 hoặc câu không còn trong nội dung
);

CREATE TABLE vocab_seen (term TEXT PRIMARY KEY, first_lesson_id TEXT NOT NULL, seen_at TEXT NOT NULL);
CREATE TABLE stage_progress (stage INTEGER PRIMARY KEY, gate_passed_at TEXT, best_gate_score REAL, attempts INTEGER NOT NULL DEFAULT 0);
CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
  -- keys: content_lang (vi|en), ui_lang (follows content_lang unless set), theme (system|light|dark), font_scale (0..3),
  --       line_height (0|1), haptics (0|1), review_max_per_session (20), review_reminder_time (HH:mm|''), content_version (int),
  --       content_source (asset|remote), remote_base_url
CREATE TABLE event (id INTEGER PRIMARY KEY AUTOINCREMENT, ts TEXT NOT NULL, kind TEXT NOT NULL, ref TEXT, value REAL);
  -- kinds: lesson_opened, lesson_read, quiz_finished, review_finished, gate_finished, content_updated

CREATE VIRTUAL TABLE search_index USING fts5(
  lesson_id UNINDEXED, lang UNINDEXED, title, body,
  tokenize = "unicode61 remove_diacritics 0"        -- giữ dấu tiếng Việt
);
```

Migration: mỗi lần tăng `schemaVersion` thêm một bước trong `migrations.dart` (`MigrationStrategy.onUpgrade`); không bao giờ xóa bảng
có dữ liệu người dùng. `search_index` được xây lại toàn bộ khi `content_version` đổi (chạy trong isolate, hiện tiến trình ở Cài đặt).

Xuất tiến độ = JSON `{schema: 1, exported_at, tables: {lesson_progress: [...], quiz_attempt: [...], quiz_answer: [...], review_item: [...],
vocab_seen: [...], stage_progress: [...], settings: [...]}}` (không gồm `event`, `search_index`). Nhập = xóa các bảng đó rồi chèn, trong một transaction.

## 5. Thuật toán

### 5.1 Trạng thái bài
- Mở bài → `opened` (+`first_opened_at`) nếu đang `new`.
- Mục Tóm tắt vào viewport ≥ 50% **hoặc** bấm "Đánh dấu đã đọc, quiz sau" → `read` (+`read_at`); mọi `vocab` của bài vào `vocab_seen`.
- Quiz bài ≥ 70% → `passed` (+`passed_at`, `best_score`, `content_version`); < 70% → giữ `read`.
- Không bao giờ hạ trạng thái. Bài `passed` mà nội dung có `content_version` lớn hơn → nhãn "đã cập nhật", trạng thái giữ nguyên.

### 5.2 "Học tiếp" và đếm
- Danh sách main path = duyệt `path.stages[].modules` → `tracks` → bài `main_path: true`, theo thứ tự.
- Học tiếp = bài đầu tiên có `status ∈ {new, opened}`; ưu tiên bài `opened` gần nhất (`first_opened_at` lớn nhất) nếu nó nằm trong cùng module với bài đầu tiên đó.
- "Quiz đang chờ" = bài main path `read` (tối đa 5 dòng, mới nhất trước).
- "Còn N bài tới cổng" = số bài main path trong giai đoạn hiện tại chưa `passed`. Giai đoạn hiện tại = giai đoạn nhỏ nhất chưa `gate_passed_at`.
- Sẵn sàng thi cổng = mọi bài main path của giai đoạn `passed`; cảnh báo mềm nếu thi khi chưa đủ.

### 5.3 Ôn tập (bốn bậc)
Bậc → khoảng tới lần ôn sau: `tier 0 → 1 ngày`, `1 → 3 ngày`, `2 → 7 ngày`, `3 → 21 ngày`, `4 → retired`.
- Câu trả lời **sai** trong quiz bài/module/ôn: nếu chưa có `review_item` → tạo `tier 0`, `due_at = now + 1 ngày`; nếu đã có → `tier = 0`, `due_at = now + 1 ngày`.
- Câu trả lời **đúng trong phiên ôn**: `tier += 1`, `due_at = now + khoảng(tier)`; `tier 4` → `retired = 1`.
- Câu trả lời đúng trong quiz bài/module: không tạo item; nếu item đã có và `tier ≥ 1` → không đổi; `tier 0` → không đổi (chỉ phiên ôn thăng bậc).
- Câu **gate**: không vào ôn (gate không có giải thích, mục đích là đo).
- "Ngày" = mốc 04:00 giờ địa phương (tránh 23:59/00:01 lệch một ngày). Đến hạn = `due_at ≤ mốc 04:00 hôm nay + 24 giờ`.
- Phiên ôn: lấy item đến hạn, `retired = 0`, câu còn tồn tại trong nội dung; sắp xếp `due_at` tăng dần (quá hạn lâu nhất trước); cắt `review_max_per_session` (mặc định 20); trộn câu hỏi và term flashcard (term: hỏi "term này nghĩa là gì?" với 4 `short` chọn từ glossary cùng track, 1 đúng).
- Sai lần thứ hai trong cùng ngày: giữ `tier 0`, `due_at` không đổi (vẫn ngày mai).
- Cập nhật nội dung: item có `question_id` không còn trong `content.json` → `retired = 1` (giữ hàng để nhập/xuất nhất quán).
- "Thêm vào ôn" từ TermTooltip → `review_item(item_id: "term:<slug>", kind: term, tier 0, due ngày mai)`.

### 5.4 Rút đề cổng
Đầu vào: ngân hàng `gates[gateN].questions` (≥ 90), số câu N = 35, tỉ lệ theo track = tỉ lệ số bài main path của track trong giai đoạn.
1. Lấy tập câu đã dùng ở **lần thi gần nhất** (từ `quiz_attempt.question_ids` của gate này) → ưu tiên loại; nếu ngân hàng còn ≥ N câu chưa dùng thì loại hẳn.
2. Bắt buộc chọn 3 câu `scenario` xuyên track (`track` rỗng) nếu có ≥ 3; nếu ít hơn, lấy hết.
3. Với mỗi track: `k_t = round((N − 3) × bài_t / tổng)`; điều chỉnh ±1 để tổng = N − 3; rút ngẫu nhiên `k_t` câu của track (seed = `attempt.id`), ưu tiên phủ nhiều `module` khác nhau (round-robin theo module).
4. Xáo toàn bộ; lưu `question_ids` vào attempt để tiếp tục được sau khi tạm dừng.
5. Kết quả: điểm = đúng/N; ≥ 75% → `stage_progress.gate_passed_at`. "Nên đọc lại" = với mỗi câu sai, lấy `skills` → `skills[].lessons`; đếm số câu sai theo bài; liệt kê bài có ≥ 2, hoặc top 3 nếu không bài nào ≥ 2.

### 5.5 Quiz module
Không có ngân hàng riêng: rút 12–15 câu từ `quizzes` của mọi bài trong module (mỗi bài ≥ 1 câu, ưu tiên bloom `apply`/`analyze`, ưu tiên câu người dùng từng sai), xáo, chấm như quiz bài; ≥ 70% → nhãn "Module ✓" (không ảnh hưởng `lesson_progress`). Câu sai vào ôn như quiz bài.

## 6. SVG theo theme

`tools/build` xuất SVG với 3 màu sentinel: `#010101` (chữ và nét), `#020202` (nền node), `#030303` (viền); mọi `fill="#ffffff"`/nền trắng bị xóa.
App `svg_theming.dart`: thay chuỗi `#010101 → ink`, `#020202 → surface2`, `#030303 → line` (giá trị hex của theme hiện tại) rồi `SvgPicture.string`.
Cache kết quả theo `(lesson id, brightness)`. Font trong SVG: build ép `font-family="Be Vietnam Pro, sans-serif"`; app không cần làm gì thêm.

## 7. Nội dung: asset, cập nhật từ xa, nguyên tử

- **Asset**: `assets/content/content.json` copy từ `dist/content.json` của repo nội dung tại thời điểm build app (`tools/sync-app-content` = cp + ghi `assets/content/VERSION`).
- **Remote**: `remote_base_url` mặc định `https://duyan11110.github.io/lo-trinh-architect/content/` (GitHub Pages phục vụ nhánh `gh-pages`, thư mục `content/` do CI copy từ `dist/`, xem §10). Hai file: `manifest.json` và `content.json.gz`.
- `manifest.json`: `{ "content_version": 38, "built_at": "...", "sha256": "<hex của content.json.gz>", "bytes": 2100000, "lessons_added": [...], "lessons_changed": [...] }`.
- Kiểm tra: khi mở Cài đặt → Nội dung, hoặc mỗi 24 giờ khi có mạng (nền, không chặn): tải `manifest.json` (≤ 5 KB). `content_version` lớn hơn bản đang dùng → hiện dòng "Có nội dung mới (v38) · Cập nhật".
- Cập nhật (chủ động): tải `.gz` vào file tạm → sha256 khớp manifest → gunzip → parse thử (isolate) → ghi `content.<version>.json` trong thư mục app → đổi `settings.content_version`, `content_source = remote` trong một transaction → xóa bản cũ (trừ asset) → điều hướng về Học tiếp → xây lại `search_index` nền. Thất bại ở bất kỳ bước nào: giữ nguyên bản cũ, thông báo theo microcopy.
- "Dùng bản đóng gói": `content_source = asset`.
- Không bao giờ áp dụng bản mới giữa phiên đọc/quiz (chỉ từ màn Cài đặt).

## 8. Nạp và hiệu năng

- Parse `content.json` (≈ 10 MB) trong `Isolate.run` → model bất biến; giữ `lessons` dạng `Map<String, Lesson>` nhưng `sections` chỉ parse Markdown → AST **khi mở bài** (cache LRU 10 bài).
- FTS index xây trong isolate lần đầu và khi đổi nội dung; màn Tìm hiện "đang lập chỉ mục" nếu chưa xong.
- Web: `content.json` nằm trong asset bundle; bật service worker mặc định của Flutter web để offline; SQLite qua WASM + OPFS.
- Khởi động mục tiêu: < 1,5 s tới màn Học tiếp trên Android tầm trung (đo bằng `event` local).

## 9. Kiểm thử bắt buộc

Fixture: `test/fixtures/content.sample.json` (từ `examples/content.sample.json` của repo nội dung — một bài, một quiz, một glossary, một gate rút gọn).

| Loại | Test |
|---|---|
| Unit | `markdown/grammar`: parse fence info (đủ 3 khóa, thiếu khóa, `output=true`), `[[id]]` inline, `{{diagram}}`, bullet ngộ nhận tách ` → `, `Expected result`, `<details>` |
| Unit | `glossary_matcher`: cụm dài nhất, số nhiều, HOA toàn bộ, bỏ inline code, ranh giới từ Unicode với tiếng Việt |
| Unit | `review_scheduler`: bảng bậc, mốc 04:00, sai lần hai trong ngày, retired, câu gate không vào ôn, nội dung gỡ câu |
| Unit | `gate_sampler`: tỉ lệ theo track, 3 scenario, tránh lặp lần trước, seed cố định cho tái lập |
| Unit | `content_loader`: manifest → sha mismatch → giữ bản cũ; gunzip lỗi → giữ bản cũ; nguyên tử |
| Unit | `progress`: chuyển trạng thái không hạ; Học tiếp bỏ qua `read`; đếm tới cổng |
| Widget | `Prose` render bài mẫu: đúng số CodeBlock/OutputBlock/DiagramView/TermSpan/LessonLinkChip (kể cả chip "sắp có") |
| Widget | 6 loại câu × (idle, đã chọn, đúng, sai); `truefalse` dùng `polarity`; `order` hiển thị theo thứ tự JSON |
| Golden | S3 với bài mẫu: light/dark × font_scale 0/2; S4 `scenario` sau kiểm tra |
| Integration | Luồng ngày thường: mở app → Học tiếp → đọc tới cuối → quiz 6 câu (1 sai) → kết quả → Ôn hôm nay có 1 câu sau khi đổi giờ hệ thống |

Tiêu chí xanh: `flutter analyze` 0 lỗi/cảnh báo; `flutter test` 100%; golden không lệch.

## 10. CI/CD và phát hành

`.github/workflows/app.yml` (trigger: push vào `app/**`, `dist/**`):
1. `flutter --version` theo `.fvmrc`; `flutter pub get`; `flutter analyze`; `flutter test`.
2. `tools/sync-app-content` (copy `dist/content.json` → asset) — build app luôn kèm bản nội dung mới nhất đã publish.
3. `flutter build web --base-href /lo-trinh-architect/app/` → deploy nhánh `gh-pages` vào `app/`; đồng thời copy `dist/content.json.gz` + `dist/manifest.json` → `gh-pages/content/`.
4. `flutter build apk` — ký release nếu 4 secret keystore tồn tại, nếu không thì debug (DECISIONS.md A6) → artifact.

`.github/workflows/content.yml` (trigger: push vào `content/**` trên nhánh `auto/*` và `main`): checkout `submodules: true`, `fetch-depth: 0`; Dart SDK; Node + mermaid-cli + Playwright Chromium; `tools/validate` → `tools/build` → commit `dist/` vào cùng nhánh bằng `AUTO_PUSH_TOKEN` (nếu không có secret: upload artifact) → `app.yml` chạy qua `workflow_run`. Deploy bằng `actions/deploy-pages` một site: `app/` + `content/`.

## 11. Milestone cho Claude Code (mỗi milestone một phiên, có Definition of Done)

| # | Milestone | Done khi |
|---|---|---|
| M0 | Scaffold: `flutter create`, cấu trúc §1, theme tokens (docs/05 §5), font, ARB, router rỗng, Drift schema §4 + test migration | `flutter analyze`/`test` xanh; app mở màn trắng có bottom nav |
| M1 | `content_loader` (asset) + models + `Prose` renderer đủ ngữ pháp §3 + `glossary_matcher` | Widget test bài mẫu xanh; S3 đọc được bài mẫu cả VI/EN, 2 theme |
| M2 | S1 Học tiếp (tối giản) + S3 đầy đủ trạng thái + tiến độ bài | Unit test progress xanh; luồng mở → đọc → read |
| M3 | S4 Quiz 6 loại + S6 Kết quả + `quiz_attempt`/`quiz_answer` + ôn tập tạo item | Widget test 6 loại; integration luồng ngày thường (trừ ôn) |
| M4 | S2 Lộ trình + Theo track + S5 tiền đề + StageBar + chip "sắp có" | Golden S2 |
| M5 | S7 Ôn tập + `review_scheduler` + Từ vựng + S9 Tìm (FTS) | Unit scheduler; tìm có dấu tiếng Việt |
| M6 | S10 Cài đặt + cập nhật từ xa §7 + xuất/nhập + S8 Cổng + `gate_sampler` + quiz module | Unit loader/sampler; integration cập nhật thất bại giữ bản cũ |
| M7 | Responsive web + phím tắt + CI §10 + APK | Deploy gh-pages chạy được; APK cài được |

Nguyên tắc cho mọi milestone: không thêm tính năng ngoài docs/05 §13; mọi màu/chữ qua tokens; mọi chuỗi UI qua ARB; không hardcode lesson id.
