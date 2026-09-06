# examples/ — bài mẫu chuẩn giọng

- `foundation.l1.http-request-response.en.md` — bản gốc tiếng Anh, đã theo đúng 9 mục, giới hạn độ dài, quy tắc bold, code trích từ repo.
- `foundation.l1.http-request-response.vi.md` — bản dịch theo prompt 06 và glossary (`vi_keep` giữ tiếng Anh + giải nghĩa trong ngoặc).
- `foundation.l1.http-request-response.quiz.json` — 6 câu, phân bố Bloom GĐ0 (1 remember / 3 understand / 2 apply), 4 loại câu, misconception khớp outline.
- `foundation.l1.http-request-response.review.json` — review mẫu đủ cả `technical` (10 verdict có bằng chứng RFC) và `junior`.
- `foundation.l1.http-request-response.meta.json` — sổ claims: 10 claim, mọi `behavior/syntax` đều `needs_verification: true` kèm `source_hint` tới RFC 9110/9112.
- `don-hang-stage-0/` — phần tối thiểu của repo ví dụ mà bài mẫu trích: `scripts/http/raw-request.sh` (code block trong bài khớp nguyên văn dòng 1–6),
  `outputs/stage-0/scripts/http/raw-request.txt` (block `text output=true`), `outputs/unstable.regex`, `STAGE.md` mẫu cho tag `stage-0`.

Dùng bài này làm `voice_sample` cho prompt 02 và 06 cho tới khi có bài `approved` đầu tiên của từng track.
Các file này đã được kiểm tra bằng script tương đương các quy tắc S/L/M/Q trong `tools/SPEC.md` (trừ L07 parse Mermaid và L15 so khớp thuật ngữ, cần công cụ thật).
