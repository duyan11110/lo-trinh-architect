---
name: "translate"
description: "Dịch một bài .en.md đã approved sang .vi.md theo prompts/06-translate-vi.md và glossary. Dùng khi người dùng nói 'dịch <id>', '/translate <id>'."
arguments: [id]
allowed-tools: Read Write Glob Grep Bash(tools/*) Bash(git -C examples/don-hang *)
---
Bài: `$id`. Model: Sonnet (DECISIONS.md D3) — trong phiên tương tác gõ `/model sonnet` trước khi gọi; `tools/gen` dùng `claude -p --model sonnet`.

1. Kiểm tra `<slug>.en.md` có `status: approved` hoặc `published`; nếu không, dừng và báo (không dịch bản chưa duyệt).
2. Đọc `prompts/00-system.md` rồi `prompts/06-translate-vi.md`; làm đúng theo nó. Nạp: bài `.en.md`, các entry `content/glossary.yaml` cho mọi term trong `vocab` và `known_vocab` của bài, `docs/03-quy-tac-chat-luong.md` mục C2, và 1 bài `.vi.md` đã published cùng track làm mẫu giọng (nếu chưa có: `examples/foundation.l1.http-request-response.vi.md`).
3. Ghi `<slug>.vi.md`. Chạy `tools/validate --parity $id` và in kết quả; nếu lỗi P01–P03, sửa rồi chạy lại (tối đa 2 lần).
