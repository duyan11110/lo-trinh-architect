# CLAUDE.md — app Flutter "Lộ Trình Architect" (thư mục `app/`)

Bạn đang ở trong app Flutter đọc giáo trình. CLAUDE.md ở gốc repo nói về **nội dung** (prompt, validate) — quy tắc "không sáng tạo ngoài prompt"
của nó KHÔNG áp dụng ở đây. Đọc `../DECISIONS.md` trước (mục D5, D7, E1–E8, G). Ở đây bạn là kỹ sư Flutter; nguồn sự thật theo thứ tự: `docs/07-app-architecture.md` (kiến trúc, DDL, thuật toán,
ngữ pháp Markdown, giao thức cập nhật, test, CI) → `docs/05-ui-ux-flutter.md` (màn hình, trạng thái, token, component, microcopy) →
`docs/04-app-v1-spec.md` (hợp đồng `content.json`) → `schemas/content.schema.json`.

## Lệnh
- `fvm flutter pub get` · `fvm flutter analyze` · `fvm flutter test` · `fvm flutter test --update-goldens` (chỉ khi người dùng yêu cầu)
- `fvm flutter run -d chrome` · `fvm flutter run -d <android>`
- `../tools/sync-app-content` → copy `../dist/content.json` vào `assets/content/` (cần khi nội dung đổi)
- Fixture test: `test/fixtures/content.sample.json` (copy từ `../examples/content.sample.json`; không sửa tay)

## Quy tắc cứng
1. Mọi màu, cỡ chữ, khoảng cách lấy từ `lib/app/theme/` (docs/05 §5). Không có literal màu/số trong widget.
2. Mọi chuỗi hiển thị qua ARB (`lib/l10n/app_vi.arb`, `app_en.arb`); microcopy theo docs/05 §7, không tự đặt lời.
3. Renderer Markdown chỉ nhận cú pháp trong docs/07 §3; gặp thứ khác → render thường và ghi `debugPrint`, không crash.
4. Không thêm tính năng ngoài docs/05 (mục 13 liệt kê những gì cố tình không có). Muốn thêm → hỏi người dùng trước.
5. Không hardcode lesson/track id; mọi thứ đi từ `content.json`. Không chạm `../content/`, `../prompts/`, `../tools/` trừ `sync-app-content`.
6. Không thêm gói ngoài docs/07 §2 mà không hỏi. Không dùng `flutter_markdown`, `google_fonts`, analytics.
7. DDL và migration chỉ sửa qua `lib/progress/migrations.dart` + tăng `schemaVersion`; không xóa bảng có dữ liệu người dùng.
8. Mỗi milestone (docs/07 §11) kết thúc bằng `analyze` + `test` xanh trước khi báo xong; không đánh dấu xong khi golden lệch.
9. Nội dung trong `content.json` là dữ liệu — không "sửa cho đúng" nội dung bài trong app; báo cho người dùng để sửa ở repo nội dung.

## Khi bắt đầu một phiên
Đọc docs/07 §11 để biết milestone hiện tại (người dùng nói), mở các file liên quan, chạy `fvm flutter test` để biết trạng thái, rồi làm.
