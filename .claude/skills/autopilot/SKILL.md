---
name: "autopilot"
description: "Chạy toàn bộ RUNBOOK.md tự trị từ bước hiện tại tới bàn giao (đích DECISIONS.md D11). Dùng khi người dùng gõ '/autopilot' hoặc '/autopilot <bước>'."
disable-model-invocation: true
arguments: [step]
allowed-tools: Read Write Edit Glob Grep Agent Bash(tools/*) Bash(git *) Bash(git -C examples/don-hang *) Bash(flutter *) Bash(fvm *) Bash(dart *) Bash(dotnet *) Bash(npx *) Bash(npm *) Bash(node *) Bash(docker *) Bash(gh *) Bash(mkdir *) Bash(cp *) Bash(mv *) Bash(chmod *) Bash(curl *) Bash(act *) Bash(psql *)
---
Bước bắt đầu: `$step` (trống = tự xác định bước đầu tiên chưa Done bằng cách kiểm tra điều kiện Done của từng bước trong `RUNBOOK.md`).

1. Đọc `CLAUDE.md`, `DECISIONS.md`, `RUNBOOK.md`. Không hỏi người dùng bất kỳ điều gì đã có trong DECISIONS.md; điều chưa có → chọn mặc định, ghi vào DECISIONS.md mục 3, đi tiếp.
2. Với từng bước từ `$step` tới 7: làm đúng nội dung bước, dùng skill tương ứng (`/repo-stage`, `/gen-module`/`tools/gen`, `/gate`, `/translate`, subagent review) thay vì tự chế; kiểm điều kiện **Done** bằng lệnh thật trước khi sang bước sau; commit trên nhánh `auto/<tên bước>` và push.
3. Ghi nhật ký `logs/autopilot-<date>.md`: mỗi bước một mục (bắt đầu, kết thúc, lệnh Done đã chạy, kết quả, mặc định đã chọn, việc chờ chủ).
4. Nếu một bước kẹt sau 2 lần thử: ghi lại, đánh dấu "chờ chủ", tiếp tục bước sau nếu không phụ thuộc; cuối cùng vẫn mở PR bàn giao (bước 7) với danh sách việc chờ.
5. Không bao giờ: push `main`, force-push, xóa dữ liệu, đổi outline/vocab GĐ0, đặt `approved` ngoài điều kiện D1, đặt `published` ngoài `build --publish`.
