# 02 — Quy trình pipeline

Sáu bước, mỗi bước có đầu vào, đầu ra, prompt (nếu là bước AI), và điều kiện qua cửa.
Đơn vị làm việc là **module** (3–8 bài): sinh cả module một lượt để các bài nhất quán, nhưng
review và duyệt từng bài.

```
[0] Chuẩn bị ─▶ [1] Outline ─▶ [2] Sinh bài+quiz ─▶ [3] Validate ─▶ [4] Review AI ─▶ [5] Bạn duyệt ─▶ [6] Dịch & build
                 prompt 01       prompt 02, 03       tools/validate   prompt 04, 05     checklist        prompt 06, tools/build
```

## Bước 0 — Chuẩn bị (một lần mỗi giai đoạn)

1. Cập nhật `templates/versions.yaml` → copy vào `content/versions.yaml`. Kiểm tra bằng lệnh thật
   (`dotnet --version`, `kubectl version`, `flutter --version`) — không ghi phiên bản theo trí nhớ.
2. Repo ví dụ Đơn Hàng có tag `stage-<n>` build xanh và test xanh (prompt 08 để sinh/cập nhật; manifest bắt buộc = `tools/validate --manifest <n>`).
   Ghi `examples/don-hang/STAGE.md` mô tả trạng thái hệ thống ở tag đó (dùng làm `example_context`). Tag theo điều kiện DECISIONS.md C1.
3. `content/path.yaml` có thứ tự module của giai đoạn.

**Cửa:** `tools/validate --stage <n> --structure-only` xanh.

## Bước 1 — Outline (prompt 01)

Đầu vào: chương trình chi tiết (`docs/00-chuong-trinh.md`), `path.yaml`, `glossary.yaml`, `versions.yaml`,
danh sách skill đã có của các track khác.
Đầu ra: `content/tracks/<track>/outline-<module>.draft.yaml` → bạn biên tập → `tools/merge-outline` gộp vào `track.yaml` + `glossary.yaml`.

Bạn làm gì: cắt/ghép bài, sửa `outline` và `misconceptions`, quyết định `main_path`, chọn `example_files`, và **đặc biệt kiểm tra outline không dùng thuật ngữ mà bài chưa dạy** (lỗi hệ thống hay gặp nhất — xem AUDIT.md R1).
Đây là bước **bạn đầu tư nhiều nhất** — outline tốt thì bài tốt; outline mơ hồ thì AI bịa phạm vi.

**Cửa:** `tools/validate --structure-only --no-repo` xanh: id duy nhất, prereq đứng trước, vocab không trùng, skill tồn tại. `example_files` được kiểm ở bước 0 của giai đoạn (S07 chỉ W khi tag chưa có; `validate --manifest <stage>` cho prompt 08 danh sách file phải tạo).

## Bước 2 — Sinh bài + quiz (prompt 02 rồi 03)

Chạy trong Claude Code, mỗi lần **một module**. Prompt 02 sinh `.en.md` + `.meta.json` cho từng bài;
prompt 03 sinh `.quiz.json` **sau khi** bài đã có (quiz phải bám bài, không bám outline).

Ngữ cảnh bơm vào prompt (Claude Code đọc file, không copy tay):
- `00-system.md` (luôn), `versions.yaml`, `glossary.yaml`
- entry của bài trong `track.yaml` + entry của các bài prereq (chỉ frontmatter + Tóm tắt 5 dòng)
- `STAGE.md` của repo ví dụ + nội dung các `example_files`
- danh sách `known_vocab`: mọi term đã được bài đứng trước giới thiệu (`tools/known-vocab --before <id>`)
- 1 bài mẫu đã approved cùng track (hoặc `examples/` nếu chưa có) để giữ giọng

**Cửa:** không có — đi thẳng bước 3.

## Bước 3 — Validate (máy)

`tools/validate <lesson-id>` — không xanh thì quay lại bước 2 với thông báo lỗi dán vào prompt
("Fix only these validation errors, change nothing else"). Danh sách kiểm tra đầy đủ trong `tools/SPEC.md`;
nhóm chính:

- Cấu trúc: frontmatter đúng schema, 9 mục đúng thứ tự & tiêu đề, độ dài mỗi mục, 5 dòng tóm tắt.
- Ràng buộc: đúng 1 Mermaid (và parse được), ≤ 2 code block, mỗi block ≤ 25 dòng, có `file=`/`tag=`, nội dung **khớp repo**.
- Liên kết: mọi `[[id]]` tồn tại; ≥ 2 link ở mục 8; prereq ở mục 1 khớp frontmatter.
- Từ vựng: mọi `**term**` in đậm lần đầu ∈ `vocab` ∪ `known_vocab`; mọi `vocab` xuất hiện trong bài; không dùng term chưa dạy (thuật toán SPEC Phụ lục A.2).
- Meta: `claims` ≥ 3, mọi claim `behavior/number/syntax` có `needs_verification: true`; `coverage.outline_items_missing` rỗng.
- Quiz: 5–7 câu, phân bố Bloom theo stage ±1, `section_ref` hợp lệ, mọi phương án sai có `explanation`, `misconception` khớp, không có "tất cả các ý trên", đáp án `fill` không rỗng.

**Cửa:** exit code 0.

## Bước 4 — Review AI (prompt 04 rồi 05)

Hai lượt độc lập, **phiên mới** (không dùng lại ngữ cảnh đã sinh bài — reviewer không được "nhớ" ý định của người viết):

1. **Review kỹ thuật (04):** đi qua từng claim trong `.meta.json`, đối chiếu tài liệu chính thức
   (Claude Code dùng WebFetch tới docs theo `source_hint`; nếu không truy cập được → `unverified`),
   kiểm code với repo, kiểm phạm vi với `outline`/`depth_notes`. Xuất `.review.json`.
2. **Review "đọc như người mới" (05):** giả lập junior chỉ biết `known_vocab`; đánh dấu chỗ nhảy bước,
   thuật ngữ lạ, giả định ngầm, ví dụ không nối với Đơn Hàng, câu quiz mơ hồ. Ghi nối vào `.review.json`.

Xử lý: `blocker` → sửa (prompt 02/03 với chỉ dẫn "apply review fixes", rồi lặp lại bước 3–4 cho các claim bị đổi);
`major` → sửa hoặc bạn quyết ở bước 5; `minor` → tùy.

**Cửa (đặt `reviewed`):** không còn `blocker`; mọi claim `needs_verification` có verdict; không còn verdict `wrong` (đã sửa và review lại). **Cửa `approved` (bước 5):** thêm: không còn `major`; không còn `unverified` với `kind ∈ {number, syntax}`; `unverified` với `fact`/`behavior`/`history` được phép nhưng bạn phải thấy và chấp nhận khi duyệt.

## Bước 5 — Duyệt (tự động theo DECISIONS.md D1; bạn duyệt lô sau)

Trong phiên tự trị, agent đặt `approved` + `approved_by: auto` khi cả hai review `pass`, không blocker/major, không `wrong`, không `unverified` số/cú pháp. Bạn duyệt lại theo lô qua PR `auto/*` với checklist dưới đây; bài bạn sửa → `reviewed` → review kỹ thuật lại phần đổi → `approved_by: owner`.

Checklist khi duyệt (bản EN hoặc VI):

- [ ] Tình huống có thật sự là thứ junior gặp không? Câu hỏi cuối mục 2 có làm mình muốn đọc tiếp không?
- [ ] Sơ đồ có đúng cơ chế không, hay chỉ là hộp-mũi-tên trang trí?
- [ ] Mục 6: hai ngộ nhận có phải ngộ nhận **thật** bạn từng thấy ở junior không? Thay bằng cái bạn từng thấy nếu có.
- [ ] Có chỗ nào bạn — với kinh nghiệm thật — biết là "đúng trên giấy, sai trong thực tế"? Thêm một câu "Trong thực tế…".
- [ ] Mục 7 làm được trong 3 phút thật không?
- [ ] Đọc `review.json`: bạn đồng ý với các verdict `rephrased` không?
- [ ] Quiz: tự làm; câu nào bạn (senior) thấy mơ hồ thì junior chắc chắn mơ hồ → sửa.
- [ ] Đặt `approved_by: owner` (giữ `reviewed_at` của lần review gần nhất).

**Cửa:** `status: approved`.

## Bước 6 — Dịch & build (prompt 06, tools/build)

- Prompt 06 dịch EN → VI theo `glossary.yaml`; bạn đọc lướt bản VI (10 phút), sửa câu gượng. Tiêu chí: **bạn đọc bản VI không thấy "mùi dịch"**.
- `tools/validate --parity <id>`: frontmatter giống nhau, số mục, số code block, số link, 5 dòng tóm tắt khớp.
- `tools/build`: Mermaid → SVG, gom `content.json`, tăng `content_version`, commit, push → GitHub Pages.
- `tools/build --publish` đặt `status: published` ở cả hai file (cách duy nhất).

## Definition of Done cho một bài

Một bài "xong" khi và chỉ khi: validate xanh cho cả `.en.md`, `.vi.md`, `.quiz.json`, `.meta.json`, `.review.json`;
không blocker; mọi code block khớp repo ở tag; bạn đã tick checklist bước 5; parity VI/EN xanh; nằm trong `content.json` của một build thành công.

## Definition of Done cho một giai đoạn

Mọi bài main path của giai đoạn published; `gate<n>.json` có ≥ 90 câu qua validate và review 04;
`path.yaml` hiển thị đúng trong app; bạn đã tự làm bài cổng và ≥ 1 câu khiến bạn phải nghĩ.

## Nhịp làm việc gợi ý

| Buổi (2 giờ) | Việc |
|---|---|
| Tối 1 | Outline + validate structure cho 1 module (4–5 bài) |
| Tối 2 | Sinh bài + quiz cả module; validate; sửa lỗi máy |
| Tối 3 | Review 04 + 05 cả module; sửa blocker |
| Tối 4 | Duyệt 4–5 bài (15 phút/bài); dịch; parity; build |

≈ 8 giờ cho một module 4–5 bài, tức **~1,7 giờ/bài** kể cả overhead — cao hơn ước lượng 20 phút/bài
trong brainstorm vì tính cả outline, review và dịch. Với 650 bài ≈ 1.100 giờ nếu làm tay từng bước;
tự động hóa bước 2–3–4 thành một lệnh `tools/gen <module>` (Claude Code chạy vòng lặp sinh→validate→review→sửa
cho tới khi xanh) đưa công của bạn về ≈ 25–30 phút/bài (chỉ bước 1 và 5, đọc lướt bước 6), tức ≈ 300 giờ như brainstorm.
