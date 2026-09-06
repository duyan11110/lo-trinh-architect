---
name: "outline"
description: "Outline một module (sinh entries cho track.yaml) theo prompts/01-outline.md. Dùng khi người dùng nói 'outline module X', '/outline'."
disable-model-invocation: true
arguments: [track, module, stage, tag]
allowed-tools: Read Write Glob Grep Bash(git -C examples/don-hang *) Bash(tools/*)
---
Bạn đang outline module `$module` của track `$track` (giai đoạn `$stage`, example tag `$tag`).

1. Đọc `prompts/00-system.md` và coi nó là system prompt của bạn cho nhiệm vụ này.
2. Đọc `prompts/01-outline.md` và làm đúng theo nó. Nạp ngữ cảnh mà prompt yêu cầu:
   - Chương trình chi tiết: `docs/00-chuong-trinh.md` (phần track `$track`, giai đoạn `$stage`) và mô tả module trong `content/path.yaml`.
   - `content/path.yaml`, `content/glossary.yaml`, `content/versions.yaml`.
   - Mọi `content/tracks/*/track.yaml` hiện có (để lấy skill, prereq, vocab đã tồn tại và danh sách bài đứng trước trên main path).
   - `known_vocab`: `tools/known-vocab --before-module $track/$module` (nếu tool chưa có: suy ra từ `introduced_in` trong glossary theo thứ tự `path.yaml`).
   - Kiểm tra CHÉO: mọi `outline`/`misconceptions` bạn viết không dùng term ngoài `known_vocab ∪ vocab` của chính bài đó (lỗi hay gặp nhất — term bị dùng trước khi bài dạy nó xuất hiện).
   - Cây file repo ví dụ ở tag: `git -C examples/don-hang ls-tree -r --name-only $tag`, và `git -C examples/don-hang show $tag:STAGE.md`.
3. Xuất YAML đúng định dạng đầu ra của prompt 01 vào `content/tracks/$track/outline-$module.draft.yaml` (KHÔNG tự gộp vào `track.yaml`). Người dùng biên tập draft rồi chạy `tools/merge-outline $track <draft>` — lệnh này gộp cả `glossary_additions`.
4. Kết thúc bằng danh sách `open_questions` và `repo_changes_needed` để người dùng quyết.
