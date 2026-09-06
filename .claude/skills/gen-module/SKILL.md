---
name: "gen-module"
description: "Chạy vòng lặp sinh → quiz → validate → review kỹ thuật → review junior → sửa cho mọi bài chưa approved của một module (tools/gen). Dùng khi người dùng nói 'gen module X', '/gen-module <track>/<module>'."
disable-model-invocation: true
arguments: [module]
allowed-tools: Read Write Edit Glob Grep Bash(tools/*) Bash(git -C examples/don-hang *) Agent
---
Module: `$module` (dạng `<track>/<module-id>`).

Với TỪNG bài trong module có `status: draft` hoặc chưa có file (theo thứ tự trong `track.yaml`). Trước mỗi bài: nếu một prereq chưa có `.en.md`, ghi "chờ prereq <id>" vào bảng tổng kết và bỏ qua bài đó (prompt 02 cần Five-line summary của prereq).

1. Nếu chưa có `.en.md`: chạy skill `lesson` với `$id generate`. Nếu bị `blocked`, ghi lý do vào bảng tổng kết và sang bài kế.
2. Nếu chưa có `.quiz.json`: chạy skill `quiz` với `$id generate`.
3. `tools/validate $id`. Nếu lỗi: `lesson $id fix-validation` và/hoặc `quiz $id fix-validation`, rồi validate lại (tối đa 2 lần).
4. Giao cho subagent **review-technical** (phiên độc lập) bài `$id`; chờ nó ghi phần `technical` vào `<slug>.review.json`.
5. Chạy `tools/known-vocab --before $id` và giao cho subagent **review-junior** (phiên độc lập) bài `$id` KÈM danh sách known_vocab đó trong lời giao việc (agent này không có Bash); chờ nó ghi phần `junior`.
6. Nếu còn `blocker` hoặc `major`: `lesson $id apply-review` và `quiz $id apply-review`, validate, rồi quay lại bước 4 **chỉ cho các claim/mục bị đổi** (nêu rõ trong lời giao việc). Tối đa 3 vòng.
7. Đặt `status: reviewed` khi không còn blocker, không còn verdict `wrong`, và mọi claim `needs_verification` có verdict. Rồi, nếu đủ điều kiện DECISIONS.md D1 (hai review `pass`, không major, không `unverified` số/cú pháp): đặt `status: approved`, `approved_by: auto`, `reviewed_at`.
8. Với bài vừa `approved`: chạy skill `translate` (Sonnet — dùng `/model sonnet` trước, `/model opus` sau), rồi `tools/validate --parity $id`.

Kết thúc: in bảng `bài × (validate, technical.verdict, junior.verdict, status, approved_by, vòng)`; bài hết 3 vòng chưa approved giữ `reviewed` và được liệt kê để chủ duyệt lô. `published` chỉ do `tools/build --publish` (DECISIONS.md D12).
