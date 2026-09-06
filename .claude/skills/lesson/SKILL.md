---
name: "lesson"
description: "Sinh hoặc sửa một bài học (.en.md + .meta.json) theo prompts/02-lesson.md. Dùng khi người dùng nói 'sinh bài <id>', '/lesson <id> [generate|fix-validation|apply-review]'."
arguments: [id, mode]
allowed-tools: Read Write Edit Glob Grep Bash(git show *) Bash(tools/*) Bash(git -C examples/don-hang *)
---
Bài: `$id`. Chế độ: `$mode` (mặc định `generate` nếu trống).

1. Đọc `prompts/00-system.md` (system prompt) rồi `prompts/02-lesson.md` và làm đúng theo nó.
2. Nạp ngữ cảnh đúng như đầu prompt 02 liệt kê. Lấy entry của bài từ `content/tracks/<track>/track.yaml` (track = phần đầu của id). Với mỗi prereq, chỉ đọc frontmatter + mục "Five-line summary" của file `.en.md` tương ứng. `known_vocab`: `tools/known-vocab --before $id`. Code ví dụ: `tools/extract-code <file> --tag <tag>` cho từng `example_files`, hoặc `git -C examples/don-hang show <tag>:<file>` nếu tool chưa có. Mẫu giọng: bài `.en.md` gần nhất có `status: approved` cùng track, nếu chưa có thì `examples/foundation.l1.http-request-response.en.md`.
3. Nếu `$mode` là `fix-validation`: chạy `tools/validate $id`, dán lỗi vào phần `{{validation_errors}}`, chỉ sửa đúng lỗi. Nếu `apply-review`: đọc `<slug>.review.json` và áp dụng theo quy tắc trong prompt.
4. Ghi hai file cạnh nhau trong thư mục module: `<slug>.en.md` và `<slug>.meta.json` (slug = phần cuối id). Giữ `status: draft`. Không tự đặt `approved`.
5. Chạy `tools/validate $id` và in kết quả. Nếu prompt yêu cầu dừng (`blocked`), KHÔNG ghi file bài — chỉ in JSON lý do.
