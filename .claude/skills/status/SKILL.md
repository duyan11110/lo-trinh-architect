---
name: "status"
description: "Tổng hợp tiến độ nội dung: số bài theo track/giai đoạn/status, bài đang chờ duyệt, blocker còn lại. Dùng khi người dùng nói 'tình hình', '/status'."
allowed-tools: Read Glob Grep Bash(tools/*) Bash(git -C examples/don-hang *)
---
Quét `content/tracks/**/**.en.md` (frontmatter `status`), `*.review.json` (blocker/major còn lại), `content/path.yaml`. In bảng theo giai đoạn → track: tổng bài trong outline / đã có draft / reviewed / approved / published, và danh sách bài `reviewed` đang chờ người dùng duyệt (bước 5 docs/02). Nếu `tools/validate` có, chạy toàn bộ và tóm tắt số lỗi theo mã. Không sửa gì.
