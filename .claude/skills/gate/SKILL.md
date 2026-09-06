---
name: "gate"
description: "Sinh ngân hàng câu hỏi bài cổng cho một giai đoạn theo prompts/07-gate-exam.md. Dùng khi người dùng nói 'sinh bài cổng giai đoạn N', '/gate <stage> <track|cross>'."
disable-model-invocation: true
arguments: [stage, scope]
allowed-tools: Read Write Edit Glob Grep Bash(tools/*) Bash(git -C examples/don-hang *) Agent
---
Giai đoạn `$stage`, phạm vi `$scope` (một track id, hoặc `cross` cho câu scenario xuyên track).

1. Đọc `prompts/00-system.md` rồi `prompts/07-gate-exam.md`; làm đúng theo nó.
2. Nạp: danh sách bài main path của giai đoạn từ `content/path.yaml` + `track.yaml` (lọc theo `$scope` nếu là track), với mỗi bài: frontmatter + "Five-line summary" + `misconceptions`; `STAGE.md` của tag `stage-$stage`; mọi `.quiz.json` của giai đoạn (chỉ `question.en`); bảng Bloom stage `$stage`.
3. Số câu cho track = round(100 × số bài main path của track trong giai đoạn / tổng bài main path của giai đoạn), tối thiểu 8; `cross` = 3–5 câu scenario xuyên track (được dùng cả ở GĐ0, context 40–80 từ). Ghi/gộp vào `content/gates/gate$stage.json` (tạo nếu chưa có; giữ id tiếp nối `next_index`).
4. Chạy `tools/validate content/gates/gate$stage.json` và in kết quả. Khi ngân hàng đủ (≥ 90 câu): giao cho subagent **review-technical** ở chế độ gate ("review gate bank content/gates/gate$stage.json") — nó chỉ chạy bước 6 (đáp án đúng/sai) trên toàn ngân hàng.
