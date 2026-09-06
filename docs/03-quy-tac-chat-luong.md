# 03 — Quy tắc chất lượng

Tài liệu này trả lời câu hỏi "bài học **đúng** và **tốt** nghĩa là gì", và là nguồn để prompt
`00-system.md` cùng hai reviewer đối chiếu. Chia làm ba phần: chống sai sót kỹ thuật, chất lượng sư phạm, và style guide.

---

## A. Chống sai sót kỹ thuật

Mô hình ngôn ngữ sai theo những cách đoán trước được: bịa API/flag nghe hợp lý, nhớ nhầm giá trị mặc định,
trộn hành vi giữa các phiên bản, khẳng định chắc nịch điều gây tranh cãi, và viết code "trông đúng" nhưng không chạy.
Mỗi quy tắc dưới đây chặn một kiểu sai.

### A1. Code chỉ đến từ repo ví dụ
Mọi code block phải trích **nguyên văn** từ repo Đơn Hàng ở tag khai báo (validate so khớp).
Hệ quả: code trong bài luôn compile, luôn chạy test, luôn nhất quán tên bảng/class/endpoint giữa các bài.
Nếu bài cần code chưa có → sửa repo trước (prompt 08), chạy CI xanh, rồi mới sinh bài.
Không chấp nhận "pseudo-code" trong block code; pseudo-code viết bằng văn xuôi hoặc Mermaid.

### A2. Mọi khẳng định cụ thể là một claim
"Cụ thể" = có thể sai theo cách kiểm chứng được: giá trị mặc định, giới hạn, thứ tự thực thi, tên cú pháp/flag/API,
hành vi khi lỗi, điều gì xảy ra ở phiên bản X. Người sinh bài liệt kê chúng trong `claims`; reviewer 04 kiểm từng cái.
Claim `wrong` → sửa bài, review lại. Claim không kiểm được (`unverified`) thuộc `kind ∈ {number, syntax}` → **phải** viết lại bài ở mức không phụ thuộc con số/cú pháp đó, hoặc bỏ; `unverified` ở `fact`/`behavior`/`history` được phép qua `approved` nhưng bạn là người quyết khi duyệt (validate in W).

### A3. Không chắc thì lên một tầng trừu tượng
Thay vì "Kestrel giữ tối đa N kết nối mặc định" (cần số) → "Kestrel có giới hạn số kết nối đồng thời, cấu hình được" (nguyên lý).
Bài học cho junior cần nguyên lý hơn con số; con số chỉ giữ lại khi reviewer verify được và nó thật sự dạy điều gì.

### A4. Phiên bản là tường
Mọi bài khai báo `versions_used`; mọi claim phụ thuộc phiên bản có `version_key`. Cấm các cụm "phiên bản mới nhất",
"gần đây", "hiện nay" — thay bằng phiên bản cụ thể từ `versions.yaml` hoặc bỏ thời tính.
Cấm nhắc tính năng preview/experimental trừ khi bài nói rõ đó là preview.

### A5. Tách sự thật khỏi khuyến nghị
Khuyến nghị ("nên", "tốt hơn", "thường") phải đi kèm điều kiện ("khi…", "nếu…") và đánh dấu `kind: opinion` trong claims.
Không có "best practice" trần trụi. Với chủ đề còn tranh luận (Repository trên EF Core, microservices, ORM vs SQL tay),
bài phải nêu ít nhất một quan điểm ngược và bối cảnh nó đúng.

### A6. Không bịa lịch sử, con người, trích dẫn
Cấm "Martin Fowler nói rằng…", "được Google phát minh năm…", số liệu thị trường. Nếu xuất xứ quan trọng về mặt sư phạm
(GoF, DDD của Evans), chỉ nêu tên tác phẩm, không trích dẫn, đánh dấu `kind: history` và verify.

### A7. Lệnh và output phải thật
Lệnh shell/kubectl trong block code lấy từ `scripts/` của repo và đã chạy trong CI. Output mẫu (`output=true`)
phải là output thật được ghi lại từ CI (`scripts/capture-output.sh`), không gõ tay. Nếu output không ổn định
(timestamp, id) → thay bằng `...` và ghi chú.

### A8. Khác biệt giữa các công nghệ tương đương phải chính xác hoặc không nêu
So sánh (RabbitMQ vs Kafka, Riverpod vs Bloc, Helm vs Kustomize) chỉ nêu khác biệt **về mô hình**, không nêu
khác biệt về số (throughput, kích thước) trừ khi verify. Không xếp hạng "tốt hơn" trần.

### A9. Reviewer không được tin người viết
Reviewer 04 chạy trong phiên mới, không thấy prompt sinh bài, không thấy lý do tác giả. Verdict phải dựa vào
tài liệu chính thức (docs của .NET, Kubernetes, Docker, Flutter, PostgreSQL, Redis, RabbitMQ, GitHub…) hoặc
kết quả chạy thật. "Nghe hợp lý" = `unverified`, không phải `verified`. WebFetch trả về bản tóm tắt chứ không phải HTML thô,
nên bằng chứng mạnh nhất là **bản sao docs cục bộ** trong `refs/` (git clone `dotnet/docs`, `kubernetes/website`, `docker/docs`, `flutter/website`…) mà reviewer Grep được nguyên văn — xem docs/06 §4.

### A10. Sửa một chỗ → kiểm lại chỗ đó
Sau khi sửa theo review, chỉ những claim/đoạn bị đổi cần review lại — nhưng **phải** review lại,
không "sửa nhỏ nên bỏ qua". Validate chạy lại toàn bộ (rẻ).

---

## B. Chất lượng sư phạm (cho junior)

### B1. Một bài, một khái niệm
Kiểm tra: mục "Tóm tắt 5 dòng" có thể viết thành **một** câu chủ đề không? Nếu cần hai câu → tách bài, sửa outline.

### B2. Cụ thể trước, trừu tượng sau
Mục 2 (Tình huống) đến trước mục 3 (Khái niệm). Trong mục 4, mỗi khái niệm được giới thiệu bằng "trong tình huống trên, X là…"
trước khi được định nghĩa tổng quát.

### B3. Chỉ dùng từ đã dạy
Bài chỉ được dùng thuật ngữ ∈ `known_vocab` ∪ `vocab`. Cần thuật ngữ khác → hoặc thêm vào `vocab` (và định nghĩa tại chỗ),
hoặc diễn giải bằng lời thường, hoặc sửa outline để bài đi sau bài dạy thuật ngữ đó. Reviewer 05 chuyên bắt lỗi này.

### B4. Ngộ nhận phải thật
Mục 6 lấy từ `misconceptions` trong outline — thứ bạn (senior) đã thấy junior nghĩ. AI có thể đề xuất, bạn xác nhận.
Ngộ nhận tốt có dạng: "X → thực ra Y, và bạn nhận ra khi Z" (Z = triệu chứng gặp trong thực tế).

### B5. Sơ đồ phải chỉ ra cơ chế
Mermaid phải trả lời "cái gì đi đâu theo thứ tự nào" hoặc "cái gì chứa cái gì". Cấm sơ đồ chỉ liệt kê hộp có tên.
Sequence diagram cho luồng; flowchart cho quyết định; class/ER cho cấu trúc. ≤ 8 node.

### B6. Thử ngay phải thật sự 3 phút
Một hành động, một quan sát, một "kết quả mong đợi" cụ thể. Không được yêu cầu cài đặt gì ngoài repo ví dụ.
Nếu chủ đề thuần khái niệm (PM, kiến trúc) → "Thử ngay" là bài tập suy nghĩ có đáp án gợi ý ẩn (`<details>`).

### B7. Liên hệ là nơi sinh ra "hệ thống"
Mục 8 nói rõ **quan hệ** chứ không chỉ link: "cùng một ý ở tầng khác", "điều kiện tiên quyết cho", "giải pháp cho vấn đề ở",
"đối lập với". Tối thiểu 2 link, ưu tiên 1 link sang track khác.

### B8. Quiz kiểm tra hiểu
Câu hỏi tốt: đặt trong tình huống, có thể trả lời bằng suy luận từ bài, phương án sai là ngộ nhận thật.
Câu hỏi cấm: hỏi định nghĩa nguyên văn, hỏi con số, hỏi tên flag, "tất cả các ý trên", phủ định kép, phương án dài ngắn lộ đáp án.
Giải thích cho phương án sai phải nói **vì sao người ta chọn nó** rồi mới "nhưng…".

### B9. Độ dài
Bài "Học": 900–1.600 từ (EN), 10–15 phút. Mục 4 dài nhất (≤ 40% bài). Không có đoạn văn > 6 câu.
Bài L4: tới 2.000 từ vì có bảng đánh đổi.

---

## C. Style guide

### C1. Bản tiếng Anh (bản gốc)
- Ngôi thứ hai ("you"), thì hiện tại, câu chủ động, câu ≤ 25 từ trung bình.
- Không mở bài kiểu "In today's world…", "As developers, we…". Không kết bài kiểu "In conclusion".
- Không emoji, không dấu chấm than, không bold để nhấn mạnh (bold **chỉ** cho thuật ngữ trong `vocab` tại mục 3 và câu ngộ nhận trích dẫn ở mục 6).
- Tên sản phẩm viết đúng chính tả chính thức: ASP.NET Core, EF Core, Kubernetes, PostgreSQL, RabbitMQ, GitHub Actions, Flutter, Riverpod.
- Code inline bằng backtick cho mọi tên file, lệnh, class, biến, endpoint, HTTP method, status code.

### C2. Bản tiếng Việt (bản dịch, bạn biên tập)
- Xưng hô: "bạn"; người viết không tự xưng ("tôi") trừ mục "Trong thực tế…" do bạn thêm.
- Thuật ngữ theo `glossary.yaml`, không tự dịch. Lần đầu xuất hiện: **term** (giải nghĩa ngắn) — ví dụ **middleware** (thành phần đứng giữa request và response).
- Không dịch tên sản phẩm, tên lệnh, tên file, tên HTTP method/status, tên pattern (Strategy, Observer…).
- Dịch ý, không dịch từ: câu tiếng Việt phải tự nhiên khi đọc to. Tránh "được thực hiện bởi", "một cách", "việc" thừa.
- Dấu câu tiếng Việt: dấu phẩy sát chữ trước, cách chữ sau; không dùng dấu chấm phẩy trong văn xuôi; ngoặc kép " ".
- Số: dùng dấu chấm ngăn hàng nghìn (1.000), dấu phẩy thập phân (0,5); đơn vị cách số (10 ms, 4 GB).

### C3. Mermaid
- `flowchart LR` mặc định; `sequenceDiagram` cho luồng request; `erDiagram` cho schema; `classDiagram` chỉ khi dạy pattern.
- Nhãn ngắn (≤ 4 từ), tiếng Anh trong cả hai bản (sơ đồ dùng chung; app hiện chú giải VI dưới sơ đồ nếu cần).
- Không màu, không style tùy chỉnh (app tô theo theme).

### C4. Đặt tên trong repo Đơn Hàng
- Solution `DonHang`, project `DonHang.Api`, `DonHang.Domain`, `DonHang.Infrastructure`, `DonHang.App` (Flutter), `DonHang.Tests`.
- Bảng: `customers`, `products`, `orders`, `order_items`, `payments`, `notifications` (snake_case, số nhiều).
- Endpoint: `/api/v1/orders`, `/api/v1/products`, … (số nhiều, kebab-case).
- Tên miền nghiệp vụ trong code bằng tiếng Anh (`Order`, `Customer`) — tên tiếng Việt chỉ ở UI và tài liệu.

---

## D. Checklist tổng hợp trước khi `approved`

Máy (validate): cấu trúc · độ dài · Mermaid · code khớp repo · link · từ vựng · claims · quiz.
Reviewer 04: từng claim có verdict · phạm vi khớp outline · code đúng ngữ cảnh · so sánh không bịa số · khuyến nghị có điều kiện.
Reviewer 05: không từ lạ · không nhảy bước · tình huống nối Đơn Hàng · thử ngay làm được · quiz không mơ hồ.
Bạn: ngộ nhận thật · "trong thực tế" · sơ đồ đúng cơ chế · tự làm quiz.
