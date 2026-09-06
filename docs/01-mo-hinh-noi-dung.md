# 01 — Mô hình nội dung

Tài liệu này định nghĩa mọi thực thể trong repo nội dung, quy ước đặt id, và quan hệ giữa chúng.
Schema máy đọc được nằm ở `schemas/`. Mọi thứ ở đây là **hợp đồng**: prompt sinh theo nó,
validate kiểm theo nó, app render theo nó.

## 1. Thực thể và quan hệ

```
Track ──has──▶ Level (1..4) ──has──▶ Module ──has──▶ Lesson ──has──▶ Quiz (5–7 Question)
  │                                     │
  └──declares──▶ Skill ◀──teaches───────┘  (Lesson.skills ⊆ Track.skills ∪ other tracks' skills)

Stage (0..4) ──groups──▶ Module (mỗi module thuộc đúng 1 stage)
Stage ──has──▶ GateExam (30–40 Question, lấy từ ngân hàng riêng)
Glossary ──defines──▶ Term ◀──introduces── Lesson.vocab
Versions ──pins──▶ mọi khẳng định phụ thuộc phiên bản
ExampleRepo (Đơn Hàng) ──tag stage-N──▶ mọi code block trong Lesson
```

## 2. Quy ước id

| Thực thể | Dạng | Ví dụ | Quy tắc |
|---|---|---|---|
| Track | `<track>` | `foundation`, `design`, `backend`, `frontend`, `devops`, `k8s`, `management`, `sysdesign` | 8 giá trị cố định |
| Module | `<slug>` | `http`, `web-server` | duy nhất trong track, kebab-case |
| Lesson | `<track>.l<level>.<slug>` | `backend.l1.request-lifecycle` | duy nhất toàn cục; slug ≤ 40 ký tự, kebab-case, tiếng Anh |
| Skill | `<track>.<area>.<name>` | `backend.http.pipeline` | 3 phần, không có level — skill không đổi khi bài đổi cấp |
| Question | `<lesson-id>.q<n>` | `backend.l1.request-lifecycle.q3` | n từ 1, liên tục |
| Gate question | `gate<stage>.q<n>` | `gate1.q17` | ngân hàng riêng mỗi giai đoạn |
| Term | slug tiếng Anh | `middleware`, `event-loop` | khóa trong `glossary.yaml` |
| Example tag | `stage-<n>` | `stage-1` | tag Git trong repo Đơn Hàng |

Id **không bao giờ đổi** sau khi publish (tiến độ người học tham chiếu id). Đổi tên bài → giữ id, đổi `title`.

## 3. `track.yaml`

Một file mỗi track. Là **nguồn sự thật về cấu trúc**: bài nào tồn tại, thuộc module nào, dạy skill gì,
cần gì trước, và mỗi bài phải phủ những ý nào (`outline`). Prompt sinh bài đọc từ đây, không tự bịa phạm vi.

```yaml
id: backend
title: { vi: "Backend Engineering", en: "Backend Engineering" }
description:
  vi: "Từ vòng đời một request đến kiến trúc backend chịu tải..."
  en: "..."
skills:                                   # skill do track này sở hữu
  - id: backend.http.pipeline
    title: { vi: "Pipeline xử lý request", en: "Request pipeline" }
    prereqs: [foundation.http.request-response]
levels:
  - level: 1
    title: { vi: "Foundation", en: "Foundation" }
    modules:
      - id: web-server
        title: { vi: "Web server & vòng đời request", en: "Web server & request lifecycle" }
        stage: 1                          # giai đoạn trên lộ trình (thứ tự module nằm ở content/path.yaml, §7)
        lessons:
          - id: backend.l1.request-lifecycle
            title: { vi: "Một request đi qua .NET API như thế nào", en: "How a request travels through a .NET API" }
            main_path: true
            duration_min: 12
            skills: [backend.http.pipeline, backend.middleware]
            prereqs: [foundation.http.request-response, foundation.os.process-port]
            related: [backend.l1.middleware-auth, devops.l1.reverse-proxy]
            vocab: [middleware, pipeline, endpoint, routing]
            example_tag: stage-1
            example_files:                # file trong repo Đơn Hàng mà bài được phép trích
              - src/DonHang.Api/Program.cs
              - src/DonHang.Api/Middleware/TimingMiddleware.cs
            outline:                      # 3–6 ý bài BẮT BUỘC phủ, theo thứ tự
              - "Kestrel nhận kết nối TCP và parse HTTP"
              - "Middleware pipeline: thứ tự đăng ký = thứ tự chạy; short-circuit"
              - "Routing chọn endpoint; model binding tạo DTO"
              - "Controller/handler chạy gần cuối pipeline, không phải đầu"
              - "Response đi ngược qua pipeline"
            misconceptions:               # tối thiểu 2, dùng cho mục 'Người mới hay nghĩ rằng' và phương án sai của quiz
              - "Controller là nơi request bắt đầu"
              - "Middleware và filter là một"
            depth_notes: "Không đi vào endpoint filters, minimal API vs controllers — để bài sau"
```

Quy tắc:
- `prereqs` phải trỏ tới lesson id **đứng trước trên main path** (validate kiểm bằng thứ tự toàn cục, §7).
- `skills` phải tồn tại trong `skills:` của track này hoặc track khác.
- `vocab` là thuật ngữ **lần đầu** xuất hiện ở bài này; validate báo lỗi nếu thuật ngữ đã được bài trước khai báo.
- `outline` là hợp đồng nội dung: reviewer kiểm tra bài có phủ đủ và **không vượt** (`depth_notes`).
- `example_files` giới hạn phạm vi trích code — code block ngoài danh sách này bị validate từ chối.

## 4. Lesson — Markdown + frontmatter

Hai file mỗi bài: `<slug>.en.md` (bản gốc sinh trước) và `<slug>.vi.md` (bản dịch, bạn biên tập kỹ).
Frontmatter **giống hệt nhau** giữa hai bản (validate so sánh), chỉ `lang` và `title` khác.

```yaml
---
id: backend.l1.request-lifecycle
lang: vi
track: backend
level: 1
stage: 1
module: web-server
main_path: true
title: "Một request đi qua .NET API như thế nào"
duration_min: 12
skills: [backend.http.pipeline, backend.middleware]
prereqs: [foundation.http.request-response, foundation.os.process-port]
related: [backend.l1.middleware-auth, devops.l1.reverse-proxy]
vocab: [middleware, pipeline, endpoint, routing]
example_tag: stage-1
versions_used: [dotnet, aspnetcore]      # khóa trong versions.yaml mà bài dựa vào
content_version: 1                       # bắt đầu 1; CHỈ tăng khi sửa một bài đã `published` (fix/apply trước publish giữ nguyên)
status: draft                            # draft | reviewed | approved | published
reviewed_at: null                        # ngày bạn duyệt (ISO)
---
```

Thân bài: **9 mục cố định, đúng thứ tự, đúng tiêu đề** (validate kiểm tiêu đề H2 theo ngôn ngữ):

| # | VI | EN | Bắt buộc | Ghi chú |
|---|---|---|---|---|
| 1 | Bạn cần biết trước | Before you start | ✔ | đúng một gạch đầu dòng cho mỗi prereq (1–4), mỗi dòng link `[[id]]`; bài không có prereq: đúng một dòng "Không cần gì trước — bắt đầu từ đây." / "No prerequisites — start here." |
| 2 | Tình huống | The situation | ✔ | 60–120 từ, đặt trong Đơn Hàng, kết bằng một câu hỏi |
| 3 | Khái niệm cốt lõi | Core concepts | ✔ | 3–6 thuật ngữ, mỗi thuật ngữ một câu định nghĩa; thuật ngữ trong `vocab` **in đậm tại đây** (lần in đậm duy nhất); mục 1–2 được nhắc từ ở dạng thường, chưa định nghĩa |
| 4 | Cơ chế hoạt động | How it works | ✔ | Đúng **một** khối Mermaid + giải thích 150–300 từ |
| 5 | Trong hệ thống Đơn Hàng | In the Đơn Hàng system | ✔ | 1–2 code block, mỗi block ≤ 25 dòng, có `file=` và `tag=` |
| 6 | Người mới hay nghĩ rằng… | Beginners often think… | ✔ (GĐ0–2) / "Senior hay nhầm rằng…" (GĐ3–4) | ≥ 2 mục dạng "X → thực ra Y, vì Z" |
| 7 | Thử ngay (3 phút) | Try it (3 minutes) | ✔ | 1 việc nhỏ, có thể làm trong repo ví dụ hoặc terminal; có "kết quả mong đợi" |
| 8 | Liên hệ | Connections | ✔ | ≥ 2 link `[[id]]`, trong đó ≥ 1 tới bài **đã tồn tại**; link tới id chưa outline được phép (app hiện chip "sắp có"); phải chứa mọi id trong `related` đã tồn tại |
| 9 | Tóm tắt 5 dòng | Five-line summary | ✔ | đúng 5 dòng đánh số, mỗi dòng ≤ 25 từ |

Bài **level 4** có 11 mục: 1–5 như trên, **6 Đánh đổi / Trade-offs** (bảng phương án × tiêu chí, 3×3 đến 4×5), **7 Bạn sẽ chọn gì nếu… / What would you choose if…** (2–3 bối cảnh, mỗi bối cảnh một đoạn), rồi 8 = mục 6 cũ, 9 = Thử ngay, 10 = Liên hệ, 11 = Tóm tắt. `section_ref` của quiz theo cách đánh số này (L1–L3: 1–9; L4: 1–11).

Tiêu đề mục ngộ nhận theo **giai đoạn** (không theo level): GĐ0–2 "Người mới hay nghĩ rằng… / Beginners often think…", GĐ3–4 "Senior hay nhầm rằng… / Seniors often assume…". Validate chuẩn hóa `…` (U+2026) và `...` như nhau.

Bài nhánh phụ (`main_path: false`) mở đầu bằng blockquote `> Bỏ qua được nếu: ...` trước mục 1.

### Cú pháp code block

````markdown
```csharp file=src/DonHang.Api/Program.cs tag=stage-1 lines=12-31
var builder = WebApplication.CreateBuilder(args);
...
```
````

- `file=` phải nằm trong `example_files` của bài; `tag=` = `example_tag`.
- `lines=` tùy chọn; nếu có, validate trích đúng dòng từ repo và so sánh sau khi chuẩn hóa khoảng trắng — **lệch là fail**. Nếu không có `lines=`, nội dung block phải là chuỗi con liên tục của file.
- Info string: `<lang> file=<path> tag=<tag> [lines=a-b]` — `lang` là tên ngôn ngữ highlight (`csharp`, `bash`, `yaml`, `sql`, `dart`, `json`, `markdown`, `text`); thứ tự ba khóa cố định như trên, không có dấu nháy.
- Shell/kubectl block dùng `bash file=scripts/...`. File văn xuôi của repo (ví dụ `docs/team/story-example.md`) trích bằng `markdown file=...` hoặc `text file=...`, cùng quy tắc so khớp.
- Block output: `text output=true` — không có `file=`, phải đứng ngay sau một block có `file=` trỏ tới script, và nội dung phải khớp `outputs/<tag>/<đường dẫn script, bỏ đuôi>.txt` trong repo (ví dụ `scripts/http/raw-request.sh` → `outputs/stage-0/scripts/http/raw-request.txt`), cho phép `...` thay một vùng bất kỳ.

### Cú pháp liên kết & thuật ngữ

- Liên kết bài: `[[backend.l1.middleware-auth]]` — app render thành chip tiêu đề bài (hoặc chip "sắp có" nếu id chưa có trong content.json); validate: id có trong một `track.yaml` → OK, chưa có → cảnh báo W (mục 8 vẫn cần ≥ 1 link tới bài đã tồn tại).
- Thuật ngữ: in đậm `**middleware**` đúng một lần, ở mục 3 (Khái niệm cốt lõi). App gắn tooltip cho **mọi** lần xuất hiện của dạng hiển thị (`en`/`vi`/`aliases`, thuật toán khớp ở docs/07 §4) ngoài code. Mục 1–2 có thể dùng từ ở dạng thường (tình huống nói bằng lời thường trước khi đặt tên). Bold chỉ dành cho việc này và cho câu ngộ nhận trích dẫn ở mục 6.
- Tuyệt đối không link URL ngoài trong thân bài (lỗi thời nhanh, không kiểm được). Nguồn tham khảo đặt trong `claims` (sidecar), không trong bài.

## 5. Sidecar `<slug>.meta.json` — claims và review

Prompt sinh bài **bắt buộc** xuất kèm file này. Đây là cơ chế chống sai sót chính.

```json
{
  "id": "backend.l1.request-lifecycle",
  "generated_by": "claude-...",
  "generated_at": "2026-09-20T13:00:00+07:00",
  "claims": [
    {
      "n": 1,
      "text": "In ASP.NET Core, middleware runs in the order it is registered on the app builder.",
      "kind": "behavior",
      "version_key": "aspnetcore",
      "source_hint": "ASP.NET Core docs: Middleware ordering",
      "needs_verification": true
    },
    {
      "n": 2,
      "text": "Kestrel is the default cross-platform web server for ASP.NET Core.",
      "kind": "fact",
      "version_key": "aspnetcore",
      "source_hint": "ASP.NET Core docs: Kestrel",
      "needs_verification": false
    }
  ],
  "coverage": {
    "outline_items_covered": [1, 2, 3, 4, 5],
    "outline_items_missing": [],
    "beyond_scope": []
  },
  "self_check": {
    "one_concept": true,
    "vocab_all_defined": true,
    "code_from_repo": true,
    "no_external_urls": true,
    "word_count": 1240
  }
}
```

`kind`: `fact` (định nghĩa, tồn tại) · `behavior` (hành vi cụ thể, thứ tự, mặc định) · `number` (giới hạn, mặc định số) · `syntax` (cú pháp, flag, API) · `opinion` (khuyến nghị — phải được ghi rõ là khuyến nghị trong bài) · `history` (tránh; nếu có phải verify).

Quy tắc: mọi `behavior`, `number`, `syntax`, `history` bắt buộc `needs_verification: true`. Tối thiểu 1 claim (bài thuần khái niệm) — không bịa claim cho đủ; bài có code block mà < 3 claim bị nghi bỏ sót (M05). Prompt 02 có thể xuất thêm `open_questions` và `repo_changes_needed` ở cấp cao nhất; validate bỏ qua hai trường này. Reviewer kỹ thuật (prompt 04) phải xử lý từng claim và ghi kết quả vào `<slug>.review.json` (schema `schemas/review.schema.json`).

## 6. Quiz — `<slug>.quiz.json`

```json
{
  "lesson": "backend.l1.request-lifecycle",
  "stage": 1,
  "questions": [
    {
      "id": "backend.l1.request-lifecycle.q1",
      "type": "single",
      "bloom": "understand",
      "difficulty": 2,
      "skills": ["backend.http.pipeline"],
      "section_ref": 4,
      "question": { "vi": "...", "en": "..." },
      "options": [
        { "id": "a", "vi": "...", "en": "...", "misconception": "Controller là nơi request bắt đầu" },
        { "id": "b", "vi": "...", "en": "..." },
        { "id": "c", "vi": "...", "en": "..." },
        { "id": "d", "vi": "...", "en": "..." }
      ],
      "answer": ["b"],
      "explanation": {
        "vi": { "correct": "...", "a": "...", "c": "...", "d": "..." },
        "en": { "correct": "...", "a": "...", "c": "...", "d": "..." }
      }
    }
  ]
}
```

Sáu `type`: `single`, `multi`, `truefalse`, `order`, `fill`, `scenario`.
- `truefalse`: 4 `options`, mỗi option có `polarity: "true"|"false"` và văn bản bắt đầu bằng "Đúng, vì …"/"Sai, vì …" (EN: "True, because …"/"False, because …"); thứ tự cố định a,b = true, c,d = false; đúng một option là đáp án. Không chấp nhận Đúng/Sai trần.
- `order`: `options` là các bước **đã xáo** (thứ tự trong JSON ≠ `answer`; validate Q15), `answer` là mảng id theo thứ tự đúng; app hiển thị theo thứ tự JSON.
- `fill`: `question` chứa `___`; `answer` là mảng chuỗi chấp nhận (so sánh không phân biệt hoa thường, trim); có `answer_regex` tùy chọn.
- `scenario`: `context` bắt buộc (quy mô, team, ràng buộc — 40–150 từ trong quiz bài; 80–150 từ cho scenario xuyên track của bài cổng), 4 phương án, mỗi phương án trong `explanation` phải nêu **khi nào nó lại là lựa chọn đúng** (nếu có).
- `section_ref`: số mục (1–9) trong bài mà câu này kiểm tra — app link "đọc lại mục X".
- `misconception` trên phương án sai: phải khớp một mục trong `misconceptions` của outline hoặc mục 6 của bài.

Phân bố Bloom theo giai đoạn (validate cho phép lệch ±1 câu):

| Stage | remember | understand | apply | analyze/evaluate |
|---|---|---|---|---|
| 0 | 25% | 45% | 25% | 5% (không dùng `scenario` trong quiz bài; bài cổng GĐ0 vẫn có 3–5 scenario ngắn) |
| 1 | 15% | 40% | 35% | 10% |
| 2 | 10% | 30% | 40% | 20% |
| 3 | 5% | 20% | 40% | 35% |
| 4 | 0% | 10% | 30% | 60% |

## 7. Stage, main path và thứ tự toàn cục

`content/path.yaml` liệt kê thứ tự **module** trên main path cho toàn khóa học (module là đơn vị sắp xếp, bài trong module theo thứ tự trong `track.yaml`):

```yaml
stages:
  - stage: 0
    title: { vi: "Nền tảng", en: "Foundations" }
    gate: gate0
    modules: [foundation/computer, foundation/terminal, foundation/network, foundation/http, foundation/data-sql, foundation/oop-ds, foundation/clean-code, foundation/git, foundation/debugging, foundation/craft, management/team-basics]
  - stage: 1
    ...
```

Thứ tự toàn cục của một bài = (vị trí module trong `path.yaml`, vị trí bài trong module). `prereqs` phải có thứ tự nhỏ hơn. Bài nhánh phụ vẫn nằm trong module nhưng app không tính vào "còn N bài tới cổng".

## 8. `glossary.yaml`

```yaml
- term: middleware
  en: "middleware"
  vi_keep: true                 # giữ nguyên tiếng Anh trong bản VI
  vi: "middleware"
  short_vi: "Thành phần xử lý đứng giữa request và response, xếp thành chuỗi"
  short_en: "A component in the request/response chain"
  introduced_in: backend.l1.request-lifecycle
  aliases: []
- term: event-loop
  en: "event loop"
  vi_keep: true
  vi: "event loop"
  short_vi: "Vòng lặp lấy việc từ hàng đợi và chạy lần lượt trên một luồng"
  ...
- term: transaction
  en: "transaction"
  vi_keep: false
  vi: "giao dịch"
  short_vi: "Nhóm thao tác DB hoặc thành công hết hoặc không gì cả"
```

Quy tắc `vi_keep`: giữ tiếng Anh nếu (a) cộng đồng dev Việt dùng nguyên tiếng Anh, hoặc (b) dịch gây mơ hồ. Dịch nếu từ tiếng Việt đã phổ biến và không mơ hồ (giao dịch, khóa chính, luồng). Prompt dịch (06) phải tuân theo file này, không tự quyết.

## 9. `versions.yaml`

Nguồn sự thật duy nhất về phiên bản. Mọi prompt nhận nội dung file này; mọi claim phụ thuộc phiên bản ghi `version_key`. Khi nâng phiên bản: tìm mọi bài có `versions_used` chứa key đó → đưa lại qua review kỹ thuật.

Xem `templates/versions.yaml`.

## 10. Gate exam — `content/gates/gate<stage>.json`

Ngân hàng 90–120 câu mỗi giai đoạn (gấp 3 số câu một lần thi), cùng schema Question, thêm `track` và `module` trên mỗi câu để app trộn đều. 3–5 câu `scenario` xuyên track (context 80–150 từ) đặt trong Đơn Hàng ở trạng thái của giai đoạn — kể cả GĐ0 (ngoại lệ so với quiz bài). Mỗi câu ghi `track`, `module`, `skills` (≥ 2 skill); "bài nên đọc lại" suy từ `skills` → bài dạy skill đó.

## 11. `content.json` (đầu ra build)

Xem `docs/04-app-v1-spec.md` và `docs/07-app-architecture.md` (schema `schemas/content.schema.json`). Tóm tắt: một file JSON gồm `meta` (content_version, built_at, versions), `path`, `tracks` (cây đầy đủ), `lessons` (body VI/EN đã render sẵn Mermaid → SVG path), `quizzes`, `gates`, `glossary`. Không chứa `claims`/`review` (nội bộ).
