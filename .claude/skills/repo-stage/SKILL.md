---
name: "repo-stage"
description: "Đưa repo ví dụ Đơn Hàng (examples/don-hang) tới trạng thái của một giai đoạn và tag stage-N, theo prompts/08-example-repo.md. Dùng khi người dùng nói 'cập nhật repo ví dụ stage N', '/repo-stage <stage>'."
disable-model-invocation: true
arguments: [stage]
allowed-tools: Read Write Edit Glob Grep Bash(git -C examples/don-hang *) Bash(tools/*) Bash(dotnet *) Bash(docker compose *) Bash(kubeconform *) Bash(helm *) Bash(examples/don-hang/scripts/*)
---
Giai đoạn `$stage`.

1. Đọc `prompts/00-system.md` rồi `prompts/08-example-repo.md`; làm đúng theo nó, làm việc bên trong `examples/don-hang/`.
2. Nạp: `content/versions.yaml`; `STAGE.md` hiện tại (nếu có); tag trước đó; **manifest bắt buộc** `tools/validate --manifest $stage` (mọi `example_files` của giai đoạn); `repo_changes_needed` từ mọi `outline-*.draft.yaml` và `.meta.json` của giai đoạn `$stage`.
3. Theo DECISIONS.md (A1–A2, C1–C9): không cần chờ duyệt kế hoạch trong phiên tự trị — in kế hoạch file rồi làm ngay. Tag `git -C examples/don-hang tag stage-$stage` và `push origin stage-$stage` khi đủ điều kiện C1; thiếu điều kiện → báo cáo và dừng không tag.
