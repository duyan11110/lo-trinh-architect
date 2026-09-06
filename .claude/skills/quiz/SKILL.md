---
name: "quiz"
description: "Sinh hoặc sửa quiz (.quiz.json) cho một bài đã có .en.md, theo prompts/03-quiz.md. Dùng khi người dùng nói 'sinh quiz <id>', '/quiz <id> [generate|fix-validation|apply-review]'."
arguments: [id, mode]
allowed-tools: Read Write Edit Glob Grep Bash(tools/*) Bash(git -C examples/don-hang *)
---
Bài: `$id`. Chế độ: `$mode` (mặc định `generate`).

1. Đọc `prompts/00-system.md` rồi `prompts/03-quiz.md`; làm đúng theo nó.
2. Nạp: toàn văn `<slug>.en.md` (phải tồn tại và qua validate — nếu chưa, dừng và báo), entry outline của bài (lấy `misconceptions`), `known_vocab` (`tools/known-vocab --before $id`), bảng Bloom theo stage ở `docs/01-mo-hinh-noi-dung.md` §6, `schemas/quiz.schema.json`, và câu hỏi của các quiz đã có trong cùng module (chỉ trường `question.en`, để tránh trùng). Với `vi`, đọc các entry glossary của term xuất hiện trong bài.
3. Ghi `<slug>.quiz.json`. Chạy `tools/validate $id` và in kết quả.
