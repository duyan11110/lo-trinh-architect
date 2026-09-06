# 05 — Thiết kế UI/UX cho app Flutter V1

App V1 là **trình đọc giáo trình + làm quiz + theo dõi tiến độ** cho một người dùng (bạn, đọc như một junior), chạy trên
Android và web, offline-first, không tài khoản. Tài liệu này chốt: nguyên tắc, kiến trúc thông tin, luồng, đặc tả từng màn hình
với mọi trạng thái, hệ thống thiết kế ánh xạ sang Flutter, thư viện component, tương tác quiz cho 6 loại câu, microcopy, khả năng
tiếp cận, responsive, và thứ tự triển khai. Mockup các màn hình chính nằm trong design canvas đi kèm (chỉnh trực tiếp được).

---

## 1. Nguyên tắc thiết kế

| # | Nguyên tắc | Hệ quả cụ thể trong UI |
|---|---|---|
| P1 | **Đọc là trung tâm.** Mỗi phiên dùng app là 10–15 phút đọc một bài rồi làm quiz. | Màn đọc bài chiếm ≥ 90% thời gian → được đầu tư nhất: cỡ chữ, khoảng dòng, code block, sơ đồ, không có gì che nội dung. Không banner, không "gợi ý", không popup giữa bài. |
| P2 | **Luôn có đúng một bước tiếp theo.** Junior không nên phải chọn. | Trang chủ = một nút "Học tiếp" + vị trí trên lộ trình. Cây track là tab phụ để tra cứu. Cuối bài luôn có một hành động chính. "Học tiếp" bỏ qua bài đã `read` (đánh dấu đã đọc, quiz sau) — các bài đó nằm trong ô "Quiz đang chờ". |
| P3 | **Tiến độ theo kỹ năng, không theo thời gian.** | Không streak, không XP, không badge. Chỉ có: bài đã qua, điểm quiz, "còn N bài tới cổng", cổng đã qua. Sự tiến bộ hiện bằng vị trí trên 5 giai đoạn. |
| P4 | **Song ngữ là công dân hạng nhất.** | Nút VI/EN trên mọi màn đọc, đổi tức thì, giữ vị trí cuộn; thuật ngữ tiếng Anh có tooltip tiếng Việt; câu quiz đổi ngôn ngữ nhưng đáp án đã chọn giữ nguyên. |
| P5 | **Offline không phải trạng thái lỗi.** | Nội dung là asset; mọi màn hoạt động không mạng; "cập nhật nội dung" là hành động chủ động trong Cài đặt, không phải điều kiện để dùng. |
| P6 | **Sai là thông tin.** | Câu sai hiện giải thích ngay, có nút "Đọc lại mục N"; câu sai đi vào Ôn tập. Không màu đỏ chói, không âm thanh, không "Sai rồi!". |
| P7 | **Yên tĩnh.** | Motion ≤ 250 ms, chỉ để giữ ngữ cảnh (chuyển trang, mở panel). Không confetti, không rung trừ khi người dùng bật haptic. |

---

## 2. Người dùng và bối cảnh sử dụng

Một người dùng, hai bối cảnh — và hai bối cảnh này khác nhau đủ để ảnh hưởng layout:

**Điện thoại (Android), buổi tối hoặc trên đường.** Một tay, màn 6"–6.7", 10–15 phút, có thể mất mạng. Cần: nút chính ở tầm ngón cái (thanh dưới), code block cuộn ngang gọn, sơ đồ phóng to được, quiz một câu mỗi màn, tiếp tục đúng chỗ đang dở.

**Web (Chrome) trên máy làm việc.** Đọc bài cạnh terminal để làm mục "Thử ngay", màn rộng ≥ 1200 px, có bàn phím. Cần: bố cục hai cột (mục lục trái, nội dung giữa, tối đa 72 ch), phím tắt (`j/k` cuộn mục, `n` bài tiếp, `1–6` chọn đáp án, `Enter` xác nhận), URL bookmark được, cỡ chữ cố định theo hệ thống.

Cả hai dùng chung một cây widget; khác nhau ở `LayoutBuilder` tại ba điểm: shell (bottom nav ↔ rail + hai cột), màn đọc bài (một cột ↔ hai cột), quiz (toàn màn ↔ thẻ giữa màn tối đa 640 px).

---

## 3. Kiến trúc thông tin và điều hướng

### 3.1 Bốn đích chính + Cài đặt

```
[Học tiếp]   [Lộ trình]   [Ôn tập]   [Tìm]        (bottom nav / nav rail)
                                                   [⚙ Cài đặt] ở app bar của Học tiếp
```

- **Học tiếp** (home): bài tiếp theo trên main path, vị trí giai đoạn, ôn đến hạn hôm nay.
- **Lộ trình**: 5 giai đoạn → module → bài, theo `path.yaml`; tab phụ "Theo track" để tra cứu theo kho nội dung.
- **Ôn tập**: hàng đợi câu sai đến hạn; lịch sử quiz; từ vựng đã học (tab phụ).
- **Tìm**: tìm toàn văn, lọc theo track/giai đoạn.

### 3.2 Bảng route (go_router)

| Route | Màn | Ghi chú |
|---|---|---|
| `/` | Học tiếp | redirect từ `/home` |
| `/path` | Lộ trình | query `?stage=2` mở sẵn giai đoạn |
| `/path/tracks` | Theo track | |
| `/learn/:lessonId` | Đọc bài | `/learn/foundation.l1.http-request-response`; `#s4` cuộn tới mục 4 |
| `/learn/:lessonId/quiz` | Quiz bài | full-screen route, chặn back giữa chừng bằng hộp thoại |
| `/learn/:lessonId/result/:attemptId` | Kết quả quiz | |
| `/module/:track/:moduleId/quiz` | Quiz cuối module | |
| `/gate/:stage` | Giới thiệu bài cổng | |
| `/gate/:stage/exam/:attemptId` | Đang thi cổng | |
| `/gate/:stage/result/:attemptId` | Kết quả cổng | |
| `/review` | Ôn hôm nay | |
| `/review/session/:sessionId` | Phiên ôn | dùng lại màn Quiz với chế độ `review` |
| `/review/vocab` | Từ vựng | |
| `/search?q=` | Tìm | |
| `/settings` | Cài đặt | |
| `/settings/content` | Cập nhật nội dung | |
| `/settings/progress` | Xuất/nhập tiến độ | |

Deep link `[[id]]` trong bài → `/learn/:id` push (không replace) để nút back quay về bài đang đọc, giữ vị trí cuộn.

### 3.3 Ba luồng cốt lõi

**Luồng ngày thường (80% phiên):** Học tiếp → chạm "Học tiếp" → Đọc bài → cuối bài "Làm quiz" → Quiz (5–7 câu) → Kết quả → "Bài tiếp theo" → Đọc bài… Thoát ở bất kỳ đâu, lần sau mở app lại đúng chỗ.

**Luồng ôn (mỗi sáng, 3–5 phút):** Học tiếp thấy "Ôn hôm nay: 12 câu" → Phiên ôn (câu từ nhiều bài) → mỗi câu: trả lời → giải thích → tiếp → tổng kết ngắn "9/12, 3 câu về bậc 0" → về Học tiếp.

**Luồng cổng (cuối mỗi giai đoạn):** Lộ trình hoặc Học tiếp hiện "Sẵn sàng thi cổng GĐ1" khi mọi bài main path đã qua → Giới thiệu cổng (35 câu, ~40 phút, ≥ 75%, làm lại không giới hạn) → Thi (có thể tạm dừng, có đếm câu, không đếm giờ) → Kết quả theo track + danh sách bài nên đọc lại → mở khóa nhãn giai đoạn tiếp theo (mềm: bài GĐ sau vẫn mở được từ trước).

**Lần mở đầu tiên:** một màn duy nhất chọn ngôn ngữ đọc (VI / EN) và cỡ chữ (xem trước bằng một đoạn bài mẫu) → Học tiếp. Không tour, không onboarding nhiều bước — bài đầu tiên chính là onboarding.

---

## 4. Đặc tả màn hình

Quy ước: mỗi màn có **Mục đích · Bố cục · Thành phần · Trạng thái · Hành vi · Dữ liệu**. Wireframe là điện thoại; web nêu khác biệt ở cuối.

### S1 — Học tiếp (`/`)

**Mục đích:** đưa người dùng vào bài tiếp theo trong ≤ 2 chạm, cho thấy vị trí trên lộ trình, nhắc ôn đến hạn.

```
┌──────────────────────────────┐
│ Lộ Trình Architect        ⚙  │  app bar (tiêu đề nhỏ, không logo)
│                              │
│ GIAI ĐOẠN 0 · NỀN TẢNG       │  eyebrow mono
│ ●━━━━━●━━━━○━━━━○━━━━○       │  StageBar: 5 điểm, điểm hiện tại lớn hơn
│ Còn 23 bài tới cổng          │
│                              │
│ ┌──────────────────────────┐ │  NextLessonCard (một thẻ duy nhất, nổi)
│ │ TIẾP THEO · HTTP · 12 ph │ │
│ │ Cấu trúc một request     │ │
│ │ và một response          │ │
│ │ Bài 3/8 trong module     │ │
│ │ [ Học tiếp → ]           │ │  nút chính, full width, 56 dp
│ └──────────────────────────┘ │
│                              │
│ Ôn hôm nay            12 câu │  ReviewDueRow (ẩn khi 0)
│ [ Ôn 5 phút ]                │  nút phụ (outlined)
│                              │
│ Đang dở                      │  chỉ hiện khi có bài opened chưa read
│ · Từ file .exe đến process   │
│                              │
│ Module hiện tại              │
│ ✓ Từ lúc gõ URL…             │  danh sách bài trong module, trạng thái
│ ● Cấu trúc một request…      │  ● = tiếp theo
│ ○ GET, POST, PUT…            │
│ ○ Status code…               │
├──────────────────────────────┤
│ [Học tiếp] [Lộ trình] [Ôn] [Tìm] │
└──────────────────────────────┘
```

**Thành phần:** `StageBar`, `NextLessonCard`, `ReviewDueRow`, `LessonRow` (status dot + title + duration), bottom `NavigationBar`.

**Trạng thái:**
- *Mới cài, chưa học gì:* NextLessonCard trỏ bài đầu tiên; eyebrow "BẮT ĐẦU · GIAI ĐOẠN 0"; không có "Ôn hôm nay", không "Đang dở".
- *Bài tiếp theo là nhánh phụ:* main path bỏ qua nhánh phụ; nhánh phụ hiện trong "Module hiện tại" với nhãn "tùy chọn" mờ.
- *Đã học hết main path của giai đoạn, chưa thi cổng:* thẻ đổi thành `GateReadyCard`: "Sẵn sàng thi cổng Giai đoạn 0 · 35 câu · ~40 phút" + nút "Vào bài cổng"; bên dưới vẫn có "Hoặc học trước GĐ1" (link nhỏ).
- *Đã thi cổng, chưa đạt:* GateReadyCard đổi copy: "Cổng GĐ0: 68% — cần 75%. Nên đọc lại: 3 bài" + "Thi lại" + danh sách 3 bài.
- *Học xong toàn bộ:* thẻ "Bạn đã đi hết lộ trình" + gợi ý Ôn tập; không pháo hoa.
- *Nội dung có bản mới (đã kiểm tra khi có mạng):* một dòng nhỏ dưới app bar "Có nội dung mới (v38) · Cập nhật" — không chặn.

**Hành vi:** kéo xuống không refresh gì (không có gì để refresh — tránh thói quen web). Chạm StageBar → `/path?stage=n`. Chạm bài trong "Module hiện tại" → `/learn/:id` (không cần theo thứ tự; nếu chưa qua prereq → hộp thoại S5).

**Web (≥ 900 px):** NavigationRail trái; nội dung tối đa 720 px căn giữa; NextLessonCard và ReviewDueRow xếp cạnh nhau khi ≥ 1200 px.

### S2 — Lộ trình (`/path`)

**Mục đích:** nhìn toàn bộ 5 giai đoạn, biết mình ở đâu, mở bất kỳ bài nào.

```
┌──────────────────────────────┐
│ Lộ trình         [Giai đoạn|Theo track] │  SegmentedButton
│                              │
│ ▾ GIAI ĐOẠN 0 · Nền tảng   34/57 │  StageHeader (mở sẵn giai đoạn hiện tại)
│   Cổng: chưa thi             │
│   ▾ Máy tính chạy chương trình… 5/5 ✓ │ ModuleTile (thu gọn được)
│     ✓ Từ file .exe đến process   10 ph │
│     ✓ Biến của bạn nằm ở đâu     12 ph │
│     …                            │
│   ▸ Terminal và Linux          4/4 ✓ │
│   ▾ HTTP từ đầu đến cuối       2/8   │
│     ✓ Từ lúc gõ URL…                 │
│     ● Cấu trúc một request…   ← tiếp theo │
│     ○ GET, POST, PUT…                │
│       ○ Thời gian, múi giờ    tùy chọn │  nhánh phụ thụt vào, mờ 70%
│ ▸ GIAI ĐOẠN 1 · Làm được việc  0/130 │
│ ▸ GIAI ĐOẠN 2 · Vững nghề            │
│ …                                    │
└──────────────────────────────┘
```

**Thành phần:** `StageHeader` (tên, tiến độ x/y main path, trạng thái cổng, màu giai đoạn ở viền trái 4 dp), `ModuleTile` (ExpansionTile: tên, x/y, dấu ✓ khi hoàn thành, nút "Quiz module" khi mọi bài đã read), `LessonRow` với `StatusDot`.

**StatusDot:** ○ chưa mở (outline) · ◐ đã mở/đang đọc (nửa) · ● xám đã đọc chưa qua quiz · ✓ đã qua (đầy, màu giai đoạn) · ◉ (accent + vòng sáng) = bài "Học tiếp" hiện tại · nhánh phụ: cùng ký hiệu, mờ. Trong wireframe, ● ở dòng "tiếp theo" là ◉.

**Trạng thái:** giai đoạn chưa mở (chưa outline/không có trong content.json) → không hiện. Giai đoạn tương lai vẫn mở được, không khóa; chỉ giai đoạn hiện tại mở sẵn.

**Theo track:** cùng cấu trúc nhưng cấp 1 là 8 track, cấp 2 là L1–L4, cấp 3 module, cấp 4 bài; mỗi bài có nhãn GĐ nhỏ. Dùng để tra cứu, không phải để học.

**Web:** hai cột — trái là danh sách giai đoạn/module (sticky), phải là bài của module đang chọn.

### S3 — Đọc bài (`/learn/:id`)

Màn quan trọng nhất. **Mục đích:** đọc 900–1.600 từ, một sơ đồ, 1–2 code block, trong 10–15 phút, không mỏi.

```
┌──────────────────────────────┐
│ ←   HTTP · Bài 3/8     VI|EN  Aa ⋮ │  app bar mờ dần khi cuộn xuống, hiện lại khi cuộn lên
│ ▬▬▬▬▬▬▬▬░░░░░░░░░░░░░         │  ReadingProgress 2 dp, theo vị trí cuộn
│                              │
│ GIAI ĐOẠN 0 · HTTP · 12 PHÚT │  eyebrow
│ Cấu trúc một request         │  H1, 26 sp, Be Vietnam Pro 700
│ và một response              │
│                              │
│ Bạn cần biết trước           │  H2 mục 1 — dạng thẻ nhạt, có LessonLinkChip
│ ▸ Từ lúc gõ URL đến lúc…  ✓  │
│                              │
│ Tình huống                   │  H2
│ Bạn đang thử trang tĩnh…     │  body 17 sp / 1.6
│ …vì sao nó có hình dạng như  │
│ vậy?                         │
│                              │
│ Khái niệm cốt lõi            │
│ • request (thông điệp…) —    │  term: gạch chân chấm, chạm → tooltip
│ …                            │
│ Cơ chế hoạt động             │
│ ┌──────────────────────────┐ │  DiagramView: SVG, nền surface-2, chạm → toàn màn + pinch zoom
│ │  Client → Server …       │ │
│ └──────────────────────────┘ │
│ Trong tình huống trên…       │
│                              │
│ Trong hệ thống Đơn Hàng      │
│ ┌ scripts/http/raw-request.sh · stage-0 ┐ │  CodeBlock header: file chip + tag chip + copy
│ │ #!/usr/bin/env bash        │ │  mono 13 sp, cuộn ngang, không wrap
│ │ printf 'GET /index.html…   │ │
│ └──────────────────────────┘ │
│ ┌ output ────────────────────┐ │  block output: nền khác, nhãn "output"
│ │ HTTP/1.1 200 OK            │ │
│                              │
│ Người mới hay nghĩ rằng…     │  H2, mỗi bullet là thẻ: câu trích đậm → "Thực ra…"
│ Thử ngay (3 phút)            │  H2, nền nhấn nhẹ, "Kết quả mong đợi" in nghiêng
│ Liên hệ                      │  LessonLinkChip ×4, mỗi chip có trạng thái ✓/○
│ Tóm tắt 5 dòng               │  danh sách số, khung
│                              │
│ ┌──────────────────────────┐ │  BottomActionBar (sticky, chỉ hiện khi đã cuộn ≥ 80% hoặc ở cuối)
│ │ [ Làm quiz · 6 câu ]     │ │  nút chính
│ │ Đánh dấu đã đọc, quiz sau│ │  text button
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Thành phần:** `LessonAppBar` (back, "module · bài x/y", `LangToggle`, `FontSizeButton`, menu ⋮: mục lục, mở trong Theo track, báo lỗi nội dung), `ReadingProgress`, `SectionHeading` (có id để cuộn tới `#s4`), `Prose` (Markdown renderer tùy biến), `TermSpan`, `LessonLinkChip`, `DiagramView`, `CodeBlock`, `OutputBlock`, `MisconceptionCard`, `TryItPanel`, `SummaryBox`, `BottomActionBar`.

**Trạng thái:**
- *Chưa qua prereq* → hộp thoại S5 trước khi render.
- *Nhánh phụ* → banner mảnh dưới tiêu đề: "Tùy chọn · Bỏ qua được nếu: …" (từ blockquote).
- *Bài đã qua quiz* → BottomActionBar: "Làm lại quiz" (outlined) + "Bài tiếp theo" (chính).
- *Bài đã đọc, chưa qua quiz (< 70%)* → "Làm quiz" chính, kèm "Lần trước: 4/6".
- *Bài L4* → có thêm mục "Đánh đổi" render bảng cuộn ngang, và "Bạn sẽ chọn gì nếu…" dạng 2–3 thẻ.
- *Không có SVG (build lỗi)* → DiagramView hiện khung với chữ "Sơ đồ chưa render" — không crash.
- *Đổi ngôn ngữ* → giữ tỉ lệ cuộn (không phải offset pixel) vì độ dài khác nhau.

**Hành vi:**
- Mở bài → `status = opened`, `first_opened_at`. Cuộn tới cuối (mục 9 vào viewport) → `status = read`. Không cần nút "đã đọc" trừ khi muốn bỏ qua quiz.
- Chạm term → `TermTooltip` (bottom sheet nhỏ trên mobile, popover trên web): term, `short_vi`/`short_en`, "Học ở: <bài>" (chip), nút "Thêm vào ôn" (tạo flashcard tự nhiên: term → short). Đóng bằng chạm ngoài.
- Chạm `LessonLinkChip` → push `/learn/:id`; trên chip hiện trạng thái để junior biết đó là bài đã học hay chưa. Id không có trong `content.json` → chip "sắp có" (mờ, không chạm được) — chuyện thường vì bài GĐ0 liên hệ tới bài GĐ1–4 chưa viết.
- CodeBlock: cuộn ngang bằng ngón; nút copy; chạm header file chip → hiện đường dẫn đầy đủ + tag (không mở repo trong V1). Không wrap dòng, không số dòng (block ≤ 25 dòng, số dòng thật nằm ở `lines=` — hiện ở header "dòng 1–7").
- DiagramView: chạm → `DiagramFullScreen` (InteractiveViewer, nền theme, nút đóng). SVG tô màu theo theme bằng cách thay `currentColor`.
- `Aa` → bottom sheet: cỡ chữ 4 nấc (15/17/19/21 sp), khoảng dòng 2 nấc, áp dụng ngay, lưu settings.
- Back khi đang đọc → không hỏi; vị trí cuộn lưu theo bài (`lesson_progress.scroll_ratio`, thêm cột) để "Đang dở" mở lại đúng chỗ.

**Dữ liệu:** `lessons[id].sections[lang]`, `diagram`, `glossary`, `lesson_progress`, `quiz_attempt` gần nhất.

**Web (≥ 1100 px):** ba vùng — trái 220 px mục lục 9 mục (sticky, mục đang đọc tô đậm), giữa nội dung 72 ch, phải 260 px thẻ meta (module, kỹ năng, thời lượng, prereq, related) — vùng phải ẩn ở 900–1100 px. Phím: `j/k` mục trước/sau, `n` bài tiếp, `q` quiz, `l` đổi ngôn ngữ, `/` tìm.

### S4 — Quiz (`/learn/:id/quiz`, `/module/…/quiz`, `/review/session/…`, `/gate/…/exam/…`)

Một màn dùng cho bốn chế độ: `lesson` (5–7 câu), `module` (12–15), `review` (n câu đến hạn), `gate` (35). **Mục đích:** một câu một màn, trả lời → biết ngay đúng/sai và vì sao → tiếp.

```
┌──────────────────────────────┐
│ ✕   Câu 3/6            VI|EN │  ✕ = thoát (hộp thoại nếu đã trả lời ≥ 1)
│ ▬▬▬▬▬▬▬▬▬▬░░░░░░░░░░░░░       │  progress theo câu (không phải theo điểm)
│                              │
│ HIỂU · MỤC 4                 │  eyebrow: bloom (dịch: NHỚ/HIỂU/ÁP DỤNG/PHÂN TÍCH) · section_ref
│                              │
│ Client đang đọc một response │  câu hỏi 19 sp / 1.5
│ từ server Đơn Hàng. Nó dựa   │
│ vào đâu để biết phần thân    │
│ dài bao nhiêu…?              │
│                              │
│ ┌──────────────────────────┐ │  QuizOption ×4 — thẻ, 56 dp min, viền 1.5 dp
│ │ A  Giá trị của header    │ │
│ │    Content-Length…       │ │
│ ├──────────────────────────┤ │
│ │ B  Ký tự kết thúc đặc…   │ │
│ │ C  Số ba chữ số…         │ │
│ │ D  Server đóng kết nối…  │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │  BottomActionBar
│ │ [ Kiểm tra ]             │ │  disabled cho tới khi có lựa chọn
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Sau khi bấm Kiểm tra** (cùng màn, không chuyển trang): phương án đúng viền + nền `correct-soft`, phương án đã chọn sai viền `incorrect-soft` với nhãn "Bạn chọn"; các phương án còn lại mờ. `ExplanationPanel` trượt lên từ dưới (bottom sheet không che câu hỏi trên web; trên mobile chiếm 50% màn, kéo lên được):

```
│ ┌──────────────────────────┐ │
│ │ ✓ Đúng                   │ │  hoặc "✗ Chưa đúng — đáp án: A"
│ │ Sau dòng trống, client   │ │  explanation.correct
│ │ đọc đúng số byte…        │ │
│ │ ─────────────────────────│ │
│ │ Vì sao C không đúng      │ │  chỉ hiện explanation của phương án ĐÃ CHỌN (sai); các phương án khác: "Xem giải thích khác ▾"
│ │ Status code cho biết…    │ │
│ │ [ Đọc lại mục 4 ]  [ Tiếp → ] │  link mở bài tại #s4 (push, quay lại quiz đúng câu)
│ └──────────────────────────┘ │
```

**Tương tác theo loại câu:**

| Loại | Widget | Chọn | Kiểm tra | Ghi chú |
|---|---|---|---|---|
| `single` | 4 `QuizOption` radio | chạm 1 | so `answer[0]` | phím 1–4 trên web |
| `multi` | 4–6 `QuizOption` checkbox, câu có nhãn "Chọn tất cả ý đúng" | chạm nhiều | tập bằng nhau mới đúng; nếu sai hiện từng phương án ✓/✗ | không cho điểm một phần trong V1 |
| `truefalse` | 4 thẻ nhóm 2×2: hàng "Đúng, vì…" / "Sai, vì…" | chạm 1 | so `answer[0]` | nhãn hàng in đậm, lý do thường |
| `order` | `ReorderableListView` các bước, tay cầm ⋮⋮ bên phải, số thứ tự bên trái cập nhật khi kéo; trên mobile thêm nút ▲▼ mỗi dòng | kéo/thả hoặc ▲▼ | dãy id bằng `answer` | khi sai: hiện cột "Đúng" cạnh cột "Bạn xếp" |
| `fill` | câu hỏi render với ô `___` thành `TextField` inline (mono nếu trong code), bàn phím không tự sửa chính tả | gõ | trim, lower, so `answer[]` hoặc `answer_regex` | hiện các đáp án chấp nhận khi sai |
| `scenario` | `ContextCard` thu gọn được (mặc định mở, ghi nhớ trạng thái), 4 `QuizOption` dài hơn, cho phép wrap | chạm 1 | so `answer[0]` | ExplanationPanel hiện thêm "Khi nào phương án X lại đúng" |

**Thoát giữa chừng:** hộp thoại "Thoát quiz? Câu đã trả lời được lưu vào ôn tập; điểm không được tính." [Ở lại] [Thoát]. Chế độ `gate`: "Tạm dừng — bạn có thể quay lại trong 24 giờ" (lưu attempt dở).

**Chế độ `review`:** eyebrow thêm tên bài nguồn ("ÔN · HTTP · Cấu trúc một request…"); sau giải thích, dòng nhỏ "Bậc 1 → 2 · gặp lại sau 3 ngày" hoặc "Về bậc 0 · gặp lại ngày mai".

**Chế độ `gate`:** không hiện giải thích ngay (chỉ đúng/sai cuối bài) — cổng đo tích hợp, không dạy; có nút "Đánh dấu xem lại" và điều hướng câu ◀ ▶; câu `scenario` dài có `ContextCard` cuộn riêng.

**Trạng thái đặc biệt:** câu hỏi có code (`fill` hoặc code trong đề) → `CodeBlock` thu nhỏ; VI/EN đổi giữa chừng → giữ lựa chọn theo `option.id`.

### S5 — Hộp thoại tiền đề

```
┌──────────────────────────────┐
│ Bài này dựa trên 2 bài bạn   │
│ chưa qua quiz                │
│  ○ Từ lúc gõ URL… (12 ph)    │  chạm để mở bài đó thay thế
│  ◐ TCP, UDP và handshake     │
│                              │
│ [ Học bài trước ]  [ Cứ đọc ] │
└──────────────────────────────┘
```

"Học bài trước" mở prereq đầu tiên chưa qua, push bài hiện tại vào hàng chờ: sau khi qua quiz prereq, màn kết quả có nút "Quay lại: <bài đang định đọc>". Hộp thoại chỉ hiện một lần mỗi bài (lưu `prereq_warned`), không làm phiền lần sau.

### S6 — Kết quả quiz (`/learn/:id/result/:attemptId`)

```
┌──────────────────────────────┐
│ ←                            │
│ 5/6 · Đã qua                 │  hoặc "3/6 · Chưa qua (cần ≥ 70%)" — chữ, không vòng tròn to
│ Cấu trúc một request…        │
│                              │
│ Câu sai                      │
│ ┌ 3 · Bạn gửi GET /products… ┐ │  QuestionRecap: câu, bạn chọn, đáp án, [Đọc lại mục 6]
│ └──────────────────────────┘ │
│ Câu này sẽ xuất hiện trong   │
│ Ôn tập vào ngày mai.         │
│                              │
│ Kỹ năng                      │
│ Cấu trúc request/response  ▲ │  SkillDelta: tên skill + mũi tên/“mới” — không có số điểm kỹ năng trong V1
│                              │
│ [ Bài tiếp theo → ]          │  chính (nếu qua) / [ Đọc lại bài ] chính (nếu chưa qua) + "Làm lại quiz" phụ
│ Về Học tiếp                  │
└──────────────────────────────┘
```

Không có hoạt ảnh điểm số. Nếu 100%: dòng "Không có câu sai." và hết. Kết quả module: thêm bảng theo bài (x/y mỗi bài). Kết quả cổng: bảng theo track + "Nên đọc lại" (bài dạy các `skills` xuất hiện trong ≥ 2 câu sai — câu cổng không thuộc một bài) + nút "Thi lại" (nếu chưa đạt) hoặc "Sang Giai đoạn 1" (nếu đạt).

### S7 — Ôn tập (`/review`)

```
┌──────────────────────────────┐
│ Ôn tập           [Hôm nay|Từ vựng] │
│                              │
│ Đến hạn hôm nay        12 câu│
│ 5 bài · ~4 phút              │
│ [ Bắt đầu ôn ]               │
│                              │
│ Sắp tới                      │
│ Ngày mai 4 · T4 9 · T7 2     │  dòng chữ, không biểu đồ
│                              │
│ Lịch sử                      │
│ Hôm nay   6/6  Cấu trúc một… │
│ Hôm qua   4/6  GET, POST…    │
└──────────────────────────────┘
```

*Rỗng:* "Chưa có gì để ôn. Câu bạn trả lời sai sẽ xuất hiện ở đây sau 1 ngày." + nút "Học tiếp". *Nhiều (> 40 câu):* phiên ôn cắt 20 câu, ưu tiên quá hạn lâu nhất; ghi "còn 22 câu, ôn tiếp sau".

**Từ vựng:** danh sách term đã gặp (từ `vocab_seen`), nhóm theo track, mỗi dòng: term · short (theo ngôn ngữ) · chip bài. Ô tìm nhanh trên đầu. Chạm → TermTooltip đầy đủ.

### S8 — Bài cổng: giới thiệu (`/gate/:stage`)

Thẻ giải thích: số câu, thời gian ước tính, điều kiện đạt, "không có giải thích trong lúc thi, có thể tạm dừng", lịch sử các lần thi (điểm, ngày). Nút "Bắt đầu" — và nếu chưa học hết main path: cảnh báo mềm "Bạn còn 5 bài chưa qua trong giai đoạn này" + vẫn cho thi.

### S9 — Tìm (`/search`)

Ô tìm tự focus; kết quả nhóm theo track, mỗi kết quả: tiêu đề bài · GĐ · trạng thái · đoạn khớp (highlight). Bộ lọc chip: giai đoạn, track, "chưa học". Gõ ≥ 2 ký tự mới tìm; FTS5 với prefix. *Rỗng:* "Không thấy 'xyz'. Thử từ tiếng Anh — thuật ngữ trong bài giữ tiếng Anh." (gợi ý thật sự hữu ích với glossary `vi_keep`).

### S10 — Cài đặt (`/settings`)

Nhóm **Đọc**: ngôn ngữ nội dung (VI/EN), cỡ chữ, khoảng dòng, theme (Hệ thống/Sáng/Tối), font code. Nhóm **Ôn tập**: giờ nhắc (thông báo cục bộ, mặc định tắt), số câu tối đa mỗi phiên. Nhóm **Nội dung**: phiên bản đang dùng (v37 · 06/09/2026), "Kiểm tra bản mới" (cần mạng; hiện diff: "+12 bài, 3 bài cập nhật"), "Dùng bản đóng gói". Nhóm **Tiến độ**: xuất JSON (share sheet / tải file), nhập JSON (hộp thoại xác nhận ghi đè), đặt lại (hai bước). Nhóm **Về**: phiên bản app, giấy phép.

---

## 5. Hệ thống thiết kế (design tokens) và ánh xạ Flutter

### 5.1 Màu

Nguyên tắc: nền trung tính có ánh lạnh nhẹ, một màu nhấn (cobalt) cho hành động, **màu giai đoạn** cho tiến độ, màu ngữ nghĩa cho đúng/sai chỉ ở quiz. Không gradient.

| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| `bg` | `#F6F7FB` | `#0E1322` | nền màn |
| `surface` | `#FFFFFF` | `#161C30` | thẻ, sheet |
| `surface2` | `#EEF1F8` | `#1E2540` | code inline, khối nhấn nhẹ |
| `ink` | `#17203A` | `#E8EBF5` | chữ chính |
| `ink2` | `#4B5570` | `#B4BBD1` | chữ phụ |
| `muted` | `#7B849C` | `#8790AB` | eyebrow, meta |
| `line` | `#D9DEEB` | `#2B3352` | viền |
| `accent` | `#2B4EE6` | `#7C95FF` | nút chính, link, đang chọn |
| `accentSoft` | `#E3E9FF` | `#23305E` | nền nhấn |
| `correct` / `correctSoft` | `#1E7F5C` / `#DDF3EA` | `#5CCB9C` / `#143327` | đáp án đúng |
| `incorrect` / `incorrectSoft` | `#B4342E` / `#FBE3E1` | `#F08A84` / `#3D1A18` | đáp án sai đã chọn |
| `codeBg` / `codeInk` | `#1B2238` / `#E6EAF5` | `#0A0E1A` / `#DDE2F0` | code block (tối ở cả hai theme) |
| `stage0…4` | `#B4342E` `#1E7F5C` `#2B4EE6` `#1B35A8` `#C77C05` | `#F08A84` `#5CCB9C` `#7C95FF` `#B7C4FF` `#F2B85A` | StageBar, viền StageHeader, ✓ đã qua |

Tương phản tối thiểu 4.5:1 cho chữ thường, 3:1 cho chữ ≥ 18 sp — đã kiểm cho các cặp `ink/bg`, `ink2/surface`, `accent/surface`, `correct/correctSoft`.

### 5.2 Chữ

| Vai trò | Font | Cỡ (sp) | Weight | Line-height | Ghi chú |
|---|---|---|---|---|---|
| Display / H1 bài | Be Vietnam Pro | 26 | 700 | 1.2 | `letterSpacing -0.3` |
| H2 mục | Be Vietnam Pro | 20 | 700 | 1.3 | |
| Body đọc bài | Be Vietnam Pro | 17 (mặc định, 15–21) | 400 | 1.6 | tiếng Việt cần line-height ≥ 1.55 để dấu không chạm |
| Body UI | Be Vietnam Pro | 15 | 400/500 | 1.45 | |
| Eyebrow / meta | JetBrains Mono | 11.5 | 500 | 1.4 | uppercase, `letterSpacing 1.2` |
| Code | JetBrains Mono | 13 | 400 | 1.55 | không ligature |
| Câu hỏi quiz | Be Vietnam Pro | 19 | 500 | 1.5 | |
| Phương án | Be Vietnam Pro | 16 | 400 | 1.45 | |

Be Vietnam Pro có đủ dấu tiếng Việt và cùng giọng với tài liệu brainstorm; JetBrains Mono có đủ ký tự cho code và tiếng Việt trong comment. Cả hai bundle trong `assets/fonts` (không tải mạng). Cỡ chữ đọc bài tôn trọng `MediaQuery.textScaler` tới 1.6, sau đó kẹp.

### 5.3 Khoảng cách, bo góc, độ cao

Lưới 4 dp: `s1=4, s2=8, s3=12, s4=16, s5=24, s6=32, s7=48`. Lề nội dung 20 dp mobile, 32 dp web. Bo góc: thẻ 12, nút 10, chip 999, code block 8. Elevation: gần như 0; thẻ dùng viền `line` 1 dp; chỉ `NextLessonCard` và bottom sheet có bóng mềm (`0 8 24 -12 rgba(23,32,58,.18)`).

### 5.4 Icon và hình

Material Symbols Rounded, 22 dp, weight 400, tô `ink2`; không icon màu. Không minh họa, không avatar. Sơ đồ là SVG từ Mermaid, tô lại theo theme: stroke/text = `ink`, fill node = `surface2`, viền = `line`.

### 5.5 Motion

Chuyển route: fade-through 200 ms (Material). ExplanationPanel: slide up 220 ms `easeOutCubic`. Đổi trạng thái QuizOption: 150 ms màu viền. Đổi ngôn ngữ: crossfade 150 ms. Tôn trọng `MediaQuery.disableAnimations`. Haptic: chỉ khi bật trong Cài đặt — `selectionClick` khi chọn, `lightImpact` khi đúng.

### 5.6 Ánh xạ sang Flutter

```dart
// theme/tokens.dart — ThemeExtension để giữ token ngoài ColorScheme
@immutable
class LtaColors extends ThemeExtension<LtaColors> {
  final Color bg, surface, surface2, ink, ink2, muted, line,
      accent, accentSoft, correct, correctSoft, incorrect, incorrectSoft, codeBg, codeInk;
  final List<Color> stage; // 5 màu
  // copyWith / lerp …
}

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.light ? LtaColors.light : LtaColors.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.accent, onPrimary: c.surface,
      secondary: c.accentSoft, onSecondary: c.ink,
      surface: c.surface, onSurface: c.ink,
      error: c.incorrect, onError: c.surface,
      outline: c.line, surfaceContainerHighest: c.surface2,
      // …
    ),
    scaffoldBackgroundColor: c.bg,
    textTheme: LtaText.theme(c),           // bảng 5.2
    extensions: [c],
    navigationBarTheme: …, filledButtonTheme: …, cardTheme: CardThemeData(elevation: 0, shape: …, side: BorderSide(color: c.line)),
  );
}
```

Quy tắc: widget **không** dùng màu literal; lấy `Theme.of(context).extension<LtaColors>()!`. Cỡ chữ đọc bài lấy từ `ReadingPrefs` (Riverpod) nhân với `textTheme.bodyLarge`.

---

## 6. Thư viện component

| Component | Props chính | Trạng thái | Ghi chú triển khai |
|---|---|---|---|
| `StageBar` | `current`, `passedGates[]`, `onTapStage` | — | 5 điểm nối bằng đường; điểm hiện tại 12 dp, khác 8 dp; màu `stage[i]` khi đã qua cổng, `line` khi chưa |
| `NextLessonCard` | `lesson`, `positionText`, `onStart` | default / gateReady / gateFailed / finished | một thẻ, không danh sách |
| `LessonRow` | `lesson`, `status`, `optional`, `onTap` | 4 trạng thái StatusDot | cao 56 dp; chữ 15 sp; thời lượng mono bên phải |
| `StatusDot` | `status`, `optional`, `stageColor` | new/opened/read/passed | 10 dp; ✓ vẽ bằng `CustomPainter` để không phụ thuộc icon |
| `StageHeader` | `stage`, `done/total`, `gateState` | collapsed/expanded | viền trái 4 dp màu stage |
| `ModuleTile` | `module`, `done/total`, `children` | collapsed/expanded/complete | `ExpansionTile` tùy biến, nhớ trạng thái |
| `Prose` | `markdown`, `lang`, `glossary`, `onLinkTap` | — | `flutter_markdown` + builders cho code fence, `[[id]]`, term bold; `selectable` trên web |
| `TermSpan` | `term`, `entry` | idle/open | gạch chân chấm màu `muted`; chạm mở `TermTooltip` |
| `TermTooltip` | `entry`, `lang`, `onOpenLesson`, `onAddReview` | — | mobile: bottom sheet 200 dp; web: popover |
| `LessonLinkChip` | `lessonId`, `status`, `relationText?` | 4 trạng thái + `upcoming` | `ActionChip` với StatusDot ở đầu; `upcoming` = mờ, không bấm |
| `DiagramView` | `svgPath` | loading/ready/missing | `flutter_svg`, `colorFilter` theo theme; chạm → full screen |
| `CodeBlock` | `code`, `lang`, `file`, `tag`, `lines`, `isOutput` | — | header chip; `SingleChildScrollView` ngang; `SelectableText` mono; nút copy → toast "Đã sao chép" |
| `MisconceptionCard` | `belief`, `truth` | — | thẻ `surface2`, belief đậm, mũi tên → |
| `TryItPanel` | `steps`, `expected`, `hint?` | hint hidden/shown | `<details>` → `ExpansionTile` "Gợi ý đáp án" |
| `SummaryBox` | `lines[5]` | — | khung viền `accent` 1.5 dp |
| `BottomActionBar` | `primary`, `secondary?` | hidden/visible | `SafeArea`, ẩn/hiện theo cuộn |
| `QuizOption` | `label`, `text`, `kind: radio/checkbox`, `state` | idle/selected/correct/wrong/dimmed | tối thiểu 56 dp, chữ wrap, chạm toàn thẻ; `Semantics(selected:)` |
| `OrderList` | `items`, `onReorder` | idle/checked | `ReorderableListView` + nút ▲▼ (mobile) |
| `FillField` | `prefix`, `suffix`, `mono` | idle/correct/wrong | `TextField` inline trong `RichText` bằng `WidgetSpan` |
| `ContextCard` | `text` | expanded/collapsed | nhớ theo phiên |
| `ExplanationPanel` | `result`, `explanation`, `sectionRef`, `onReread`, `onNext` | correct/wrong | `DraggableScrollableSheet` mobile, `Card` cố định web |
| `QuestionRecap` | `question`, `chosen`, `answer`, `sectionRef` | — | dùng ở kết quả |
| `ReviewDueRow` | `count`, `minutes`, `onStart` | hidden when 0 | |
| `EmptyState` | `title`, `body`, `action?` | — | chữ + một nút, không minh họa |

---

## 7. Microcopy (tiếng Việt, bản gốc; EN dịch song song trong ARB)

Quy tắc: nút nói đúng việc xảy ra; không dấu chấm than; không "Ôi", "Tuyệt vời"; lỗi nói chuyện gì và làm gì tiếp.

| Ngữ cảnh | VI | EN |
|---|---|---|
| Nút chính trang chủ | Học tiếp | Continue |
| Cuối bài | Làm quiz · 6 câu | Take the quiz · 6 questions |
| Cuối bài, phụ | Đánh dấu đã đọc, quiz sau | Mark as read, quiz later |
| Quiz, kiểm tra | Kiểm tra | Check |
| Quiz, đúng | Đúng | Correct |
| Quiz, sai | Chưa đúng — đáp án: B | Not quite — answer: B |
| Quiz, đọc lại | Đọc lại mục 4 | Reread section 4 |
| Quiz, tiếp | Tiếp | Next |
| Quiz, thoát | Thoát quiz? Câu đã trả lời được lưu vào ôn tập; điểm không được tính. | Leave the quiz? Answered questions go to review; no score is recorded. |
| Kết quả qua | 5/6 · Đã qua | 5/6 · Passed |
| Kết quả chưa qua | 3/6 · Chưa qua (cần ≥ 70%) | 3/6 · Not yet (need ≥ 70%) |
| Tiền đề | Bài này dựa trên 2 bài bạn chưa qua quiz | This lesson builds on 2 lessons you have not passed yet |
| Tiền đề, nút | Học bài trước / Cứ đọc | Learn those first / Read anyway |
| Ôn, rỗng | Chưa có gì để ôn. Câu bạn trả lời sai sẽ xuất hiện ở đây sau 1 ngày. | Nothing to review. Questions you miss show up here after a day. |
| Ôn, bậc | Bậc 1 → 2 · gặp lại sau 3 ngày | Level 1 → 2 · back in 3 days |
| Cổng, sẵn sàng | Sẵn sàng thi cổng Giai đoạn 0 · 35 câu · ~40 phút | Ready for the Stage 0 gate · 35 questions · ~40 min |
| Cổng, chưa đạt | Cổng GĐ0: 68% — cần 75%. Nên đọc lại: 3 bài | Stage 0 gate: 68% — need 75%. Worth rereading: 3 lessons |
| Nội dung mới | Có nội dung mới (v38) · Cập nhật | New content available (v38) · Update |
| Cập nhật lỗi mạng | Không tải được bản mới. Bạn vẫn dùng bản v37 bình thường. | Could not download the update. Version v37 keeps working. |
| Nhập tiến độ | Ghi đè tiến độ hiện tại bằng file này? Không hoàn tác được. | Replace current progress with this file? This cannot be undone. |
| Sao chép code | Đã sao chép | Copied |
| Tìm, rỗng | Không thấy "xyz". Thử từ tiếng Anh — thuật ngữ trong bài giữ tiếng Anh. | Nothing for "xyz". Try the English term — lessons keep technical terms in English. |
| Sơ đồ thiếu | Sơ đồ chưa render | Diagram not rendered |

---

## 8. Khả năng tiếp cận

- Mọi thứ chạm được ≥ 48×48 dp; QuizOption ≥ 56 dp; khoảng cách giữa các option ≥ 8 dp.
- Tương phản theo 5.1; trạng thái đúng/sai **không chỉ bằng màu**: có ✓/✗ và chữ.
- `Semantics`: QuizOption có `selected`, `label` = "Phương án A, <text>"; StatusDot có nhãn trạng thái; ReadingProgress `excludeSemantics`.
- Cỡ chữ hệ thống tới 1.6× không vỡ layout: NextLessonCard cao theo nội dung; bottom nav dùng nhãn ngắn; bảng L4 cuộn ngang.
- Tiếng Việt: line-height ≥ 1.55 ở body; không cắt chữ bằng `ellipsis` ở tiêu đề bài (cho wrap 2 dòng, dòng 3 mới ellipsis).
- Bàn phím web: focus ring 2 dp `accent`; thứ tự tab hợp lý; `Escape` đóng sheet/tooltip.
- Không phụ thuộc hover: mọi tooltip mở bằng chạm/click.

---

## 9. Responsive

| Bề rộng | Shell | Đọc bài | Quiz | Lộ trình |
|---|---|---|---|---|
| < 600 | bottom nav | 1 cột, lề 20 | toàn màn, sheet giải thích | 1 cột |
| 600–899 | bottom nav | 1 cột, nội dung tối đa 640 căn giữa | thẻ 560 căn giữa | 1 cột |
| 900–1099 | nav rail | mục lục trái 200 + nội dung 72 ch | thẻ 600 căn giữa, panel giải thích dưới thẻ | 2 cột |
| ≥ 1100 | nav rail | mục lục 220 + nội dung 72 ch + meta 260 | như trên | 2 cột |

Không có layout "desktop app" riêng: web là cùng app với nhiều chỗ hơn. Chuột: hover chỉ tăng nhẹ viền, không đổi kích thước.

---

## 10. Trạng thái toàn cục và cạnh

- **Lần đầu mở, không có `content.json`** (build lỗi): màn lỗi có nút "Dùng bản đóng gói" và "Thử lại" — không màn trắng.
- **Đang đọc thì nội dung cập nhật:** không bao giờ áp dụng bản mới giữa phiên đọc; cập nhật chỉ áp dụng khi người dùng bấm trong Cài đặt, sau đó khởi động lại route về Học tiếp.
- **Bài bị gỡ trong bản mới** (hiếm; id đã published không đổi, nhưng phòng hờ): tiến độ giữ nguyên, bài hiện trong Lộ trình với nhãn "không còn trong giáo trình", vẫn mở được từ cache cũ nếu có.
- **Quiz đang dở khi app bị kill:** attempt lưu từng câu; mở lại app → Học tiếp hiện "Tiếp tục quiz: Cấu trúc một request… (3/6)".
- **Mất kết nối khi đang cập nhật:** giữ bản cũ, thông báo theo microcopy; không xóa gì trước khi bản mới tải xong và qua checksum.

---

## 11. Đo lường cục bộ (chỉ cho bạn)

Không có analytics gửi đi. Bảng `event(ts, kind, ref)` cục bộ ghi: lesson_opened, lesson_read, quiz_finished(score), review_finished, gate_finished. Màn Cài đặt → "Thống kê" (V1.1): bài/tuần, phút đọc ước tính (duration_min của bài đã read), tỉ lệ đúng lần đầu theo track. Đủ để trả lời "mình có đang học đều không" mà không biến app thành dashboard.

---

## 12. Thứ tự triển khai UI và cấu trúc thư mục

Thứ tự khớp kế hoạch tuần trong brainstorm v0.3:

1. Theme + tokens + fonts; `Prose` với code fence, `[[id]]`, term bold (đọc được bài mẫu trong `examples/`).
2. S3 Đọc bài đầy đủ trạng thái; S1 Học tiếp tối giản (chỉ NextLessonCard).
3. S4 Quiz 6 loại + S6 Kết quả; lưu `quiz_attempt`, `lesson_progress`.
4. S2 Lộ trình (Giai đoạn + Theo track); S5 hộp thoại tiền đề; StageBar.
5. S7 Ôn tập + lịch bốn bậc; S9 Tìm; S10 Cài đặt (ngôn ngữ, cỡ chữ, theme, xuất/nhập).
6. S8 Cổng; cập nhật nội dung từ GitHub Pages; responsive web; phím tắt.

```
lib/
├─ app/            router.dart, shell.dart (bottom nav / rail), theme/
├─ content/        models (Track, Lesson, Quiz…), content_repository.dart (asset | remote), markdown/ (Prose, builders)
├─ progress/       drift db, progress_repository.dart, review_scheduler.dart (4 bậc)
├─ features/
│  ├─ home/        S1
│  ├─ path/        S2
│  ├─ lesson/      S3, S5, widgets/ (CodeBlock, DiagramView, TermTooltip…)
│  ├─ quiz/        S4, S6, question_widgets/ (6 loại)
│  ├─ review/      S7
│  ├─ gate/        S8
│  ├─ search/      S9
│  └─ settings/    S10
└─ shared/         StatusDot, LessonRow, EmptyState, BottomActionBar…
```

Gói và phiên bản pin ở docs/07 §2 (renderer dùng `markdown` (Dart, AST) + widget tự viết — không dùng `flutter_markdown` vì đã ngừng phát triển).

Kiểm thử: danh sách test bắt buộc và fixture ở docs/07 §9.

---

## 13. Những gì cố tình không có trong V1

Streak, XP, badge, leaderboard; tài khoản, đồng bộ; bình luận; chấm code; mentor AI; chế độ nghe (TTS); widget màn hình chính; ghi chú cá nhân trong bài (V1.1 nếu thấy cần khi tự học); highlight văn bản (V1.1). Mỗi thứ trên có chỗ trong brainstorm v0.1 và sẽ được cân nhắc sau khi bạn học xong hai giai đoạn bằng chính app này.
