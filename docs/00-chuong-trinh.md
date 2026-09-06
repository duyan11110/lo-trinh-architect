# 00 — Chương trình học (từ brainstorm v0.3 — nguồn cho prompt 01)

Đây là bản chương trình đầy đủ dùng làm **đầu vào cho outline** (prompt 01 / skill `/outline`). Track = kho nội dung; giai đoạn = thứ tự học (`content/path.yaml`). Giai đoạn 0 đã được outline chi tiết trong `content/tracks/foundation/track.yaml` và `management/track.yaml`; các giai đoạn sau outline dần từ bảng này.

## 1. Lộ trình 5 giai đoạn

### Giai đoạn 0 — Nền tảng (6–8 tuần · ~80 bài)

Lấp những lỗ hổng mà trường không dạy và công ty giả định bạn đã biết. Hoàn toàn tuyến tính.

Module dự kiến: Máy tính, process, memory, file; Terminal & Linux cơ bản; Mạng: IP, port, DNS, TCP, TLS; HTTP từ đầu đến cuối; Git thật sự; SQL & mô hình quan hệ; OOP, cấu trúc dữ liệu, độ phức tạp; Clean code & đọc code người khác; Debug có phương pháp; Làm việc trong team Scrum.

**Cổng:** Giải thích được điều gì xảy ra từ lúc gõ URL đến lúc trang hiện ra; viết được truy vấn JOIN; dùng Git branch/rebase không sợ.

### Giai đoạn 1 — Làm được việc (3 tháng · ~130 bài)

Xây được một API có DB, một client gọi nó, chạy trong Docker, và hiểu code mình viết nằm đâu trong kiến trúc của team.

Module dự kiến: Web server & vòng đời request; REST API với .NET; ORM & EF Core; Validation, error, logging; Auth cơ bản: session, JWT; SOLID qua ví dụ; Layered architecture; Dependency Injection; Unit test & test double; Component & state (Flutter); Gọi API, loading/error; Docker & Compose; Biến môi trường & config; User story, DoD, ước lượng cơ bản; Code review tốt.

**Cổng:** Đọc một PR 300 dòng và nhận xét được về tầng, phụ thuộc, test. Đây là mốc "junior vững".

### Giai đoạn 2 — Vững nghề (4 tháng · ~150 bài)

Hệ thống có nhiều người dùng, nhiều môi trường, và bắt đầu hỏng theo cách thú vị. Tương đương mid-level.

Module dự kiến: API design chuẩn: versioning, pagination, RFC 9457; OAuth2/OIDC, RBAC; Caching & Redis; Background job; Index & query plan; GoF patterns (chọn lọc); Clean/Hexagonal; Domain model vs anemic; Integration test; State management & routing; Form, i18n, theming; CI/CD với GitHub Actions; Registry, versioning, release; Monitoring cơ bản; Cluster, Pod, Deployment, Service; ConfigMap, Secret, probe; Lập kế hoạch, risk, stakeholder; Viết tài liệu kỹ thuật.

**Cổng:** Deploy hệ thống ví dụ lên cluster qua pipeline, có dashboard và log; giải thích được vì sao cache làm dữ liệu cũ.

### Giai đoạn 3 — Senior (4 tháng · ~160 bài)

Hệ thống phân tán, vận hành ở quy mô, và các quyết định có hậu quả dài hạn.

Module dự kiến: Messaging, idempotency, outbox; Saga & giao dịch phân tán; Observability: OpenTelemetry; Resilience patterns; Multi-tenancy, sharding; DDD tactical & strategic; CQRS, Event Sourcing; Modular monolith; Performance & offline-first; Design system; IaC, GitOps; Secrets, backup, DR; Supply chain security; Ingress, Helm, StatefulSet, storage; RBAC, NetworkPolicy, operator; Bare-metal: MetalLB, Longhorn; Technical debt, RFC/ADR; Build vs buy, TCO.

**Cổng:** Viết một ADR cho việc tách một module thành service riêng, nêu 3 phương án và lý do chọn.

### Giai đoạn 4 — Architect (3 tháng · ~120 bài)

Toàn bộ L4 của mọi track, cộng track System Design tổng hợp — nơi các bài toán ghép mọi thứ đã học.

Module dự kiến: Chọn kiến trúc theo bối cảnh; Evolutionary architecture; Trade-off & ATAM rút gọn; CAP/PACELC, data ownership; Kiến trúc bảo mật, PKI, ký số; Capacity & SLO; Chọn stack, BFF, migrate legacy; Platform engineering, release strategy; Incident & postmortem; Multi-cluster, mesh, managed vs self-host; Governance, chiến lược, Team Topologies; Trình bày cho lãnh đạo; System Design: 8 bài toán tổng hợp.

**Cổng:** Thiết kế hệ thống ký số tài liệu cho ngân hàng từ yêu cầu đến sơ đồ triển khai, trả lời được câu hỏi phản biện.

## 2. Hệ thống ví dụ xuyên suốt: Đơn Hàng

Toàn bộ khóa học dùng một hệ thống ví dụ duy nhất — một ứng dụng đặt hàng đơn giản (khách hàng, sản phẩm, đơn hàng, thanh toán, thông báo). Nó đủ quen thuộc để không cần giải thích nghiệp vụ, đủ giàu để chạm mọi chủ đề, và lớn dần theo giai đoạn. Mọi ví dụ code, sơ đồ, câu hỏi tình huống đều lấy từ nó, nên junior luôn biết "cái này nằm ở đâu trong bức tranh".

- **GĐ 0 — Bảng và truy vấn:** Chỉ có schema SQL: customers, products, orders, order_items. Dùng để dạy mô hình quan hệ, JOIN, HTTP request tới một trang tĩnh.
- **GĐ 1 — Một API + một app:** .NET API monolith 3 tầng, EF Core, JWT; Flutter client danh sách sản phẩm và tạo đơn; chạy bằng Docker Compose.
- **GĐ 2 — Có người dùng thật:** Thêm OAuth2, Redis cache, background job gửi email, pipeline CI/CD, deploy lên K8s đơn giản, Grafana.
- **GĐ 3 — Tách và phân tán:** Modular monolith → tách Payment và Notification thành service, RabbitMQ + outbox, saga hủy đơn, OpenTelemetry, Helm, GitOps.
- **GĐ 4 — Quyết định kiến trúc:** Multi-tenant cho nhiều cửa hàng, ký số hóa đơn điện tử, SLO, multi-cluster — mỗi bài L4 là một ADR của hệ thống này.

Repo `examples/don-hang` có tag Git `stage-0` … `stage-4`; mọi code block trong bài trích từ repo này (docs/03 A1).

## 3. Chương trình chi tiết theo track

Mỗi ô là các module dự kiến của một cấp; nhãn GĐx = giai đoạn trên lộ trình. Với junior, L1 dày hơn bình thường.

### Track 0 — Nền tảng & kỹ năng nghề (~80 bài · mới)

- **L1 Máy tính & hệ thống:** Chương trình chạy như thế nào: process, thread, memory, stack/heap; File system, quyền, biến môi trường; Terminal & Linux: điều hướng, pipe, grep, quyền, SSH; Mạng: IP, port, DNS, TCP/UDP, TLS, "localhost là gì"; HTTP từ đầu đến cuối: request/response, method, status, header, cookie, cache — một module 8 bài, xương sống cho mọi thứ sau; Encoding, JSON, thời gian & múi giờ GĐ0
- **L1 Dữ liệu & code:** Mô hình quan hệ: bảng, khóa, quan hệ, chuẩn hóa; SQL: SELECT, JOIN, GROUP BY, subquery, index là gì; Transaction lần đầu; OOP đúng nghĩa: đóng gói, đa hình, interface vs abstract; Cấu trúc dữ liệu & độ phức tạp cần cho dev ứng dụng; Bất đồng bộ: async/await thật sự làm gì; Clean code: đặt tên, hàm nhỏ, comment, code smell cơ bản GĐ0
- **L2 Kỹ năng nghề:** Git thật sự: commit tốt, branch, merge vs rebase, giải quyết conflict, bisect; Đọc code người khác có phương pháp; Debug có phương pháp: tái hiện, thu hẹp, giả thuyết; Đọc tài liệu & tiếng Anh kỹ thuật; Hỏi câu hỏi tốt, viết bug report; Dùng AI coding assistant đúng cách (và khi nào không tin) GĐ0

### Track 1 — Software Design & Patterns (~95 bài)

- **L1 Foundation:** Vì sao cần thiết kế: đọc một hàm 400 dòng; Coupling & cohesion bằng ví dụ Đơn Hàng; SOLID, mỗi nguyên tắc một bài, có phản ví dụ; Layered architecture: Controller/Service/Repository và lý do tồn tại từng tầng; Dependency Injection: từ new đến container; Interface để làm gì; Unit test & test double GĐ1; DRY/KISS/YAGNI và khi nào vi phạm; Refactoring cơ bản GĐ2
- **L2 Practitioner:** GoF chọn lọc theo tần suất gặp: Strategy, Factory, Builder, Decorator, Observer, Command, Adapter, Facade, Template Method (mỗi pattern một bài, gắn tình huống Đơn Hàng); Clean vs Hexagonal: khác gì Layered; Repository & Unit of Work — và khi EF Core đã là UoW; Domain model vs anemic model; Thiết kế validation & error; Integration test với testcontainers; Cấu trúc project theo feature GĐ2
- **L3 Advanced:** DDD tactical: Entity, Value Object, Aggregate, invariant, Domain Event; DDD strategic: Bounded Context, Context Map, ACL; CQRS từ nhẹ đến đầy đủ; Event Sourcing: projection, snapshot, replay; Saga / Process Manager; Outbox/Inbox, idempotency; Mô hình nhất quán; Modular monolith và ranh giới module GĐ3
- **L4 Architect:** Monolith → modular → microservices → và đi ngược lại; Evolutionary architecture, fitness function; Viết ADR; ATAM rút gọn; Conway's law; Lượng hóa technical debt; Anti-pattern: distributed monolith, over-abstraction; Case study: Đơn Hàng ở 1 cửa hàng vs 1.000 cửa hàng GĐ4

### Track 2 — Backend Engineering (~120 bài)

- **L1 Foundation:** Web server làm gì: Kestrel, middleware, vòng đời một request; REST: tài nguyên, method, status đúng; Xây API Đơn Hàng đầu tiên với .NET; ORM & EF Core: mapping, migration, N+1; Validation, error handling, logging có cấu trúc; Config & environment; Auth cơ bản: session vs token, JWT, hash mật khẩu; Serialization & DTO GĐ1
- **L2 Practitioner:** API design: versioning, pagination, filtering, RFC 9457, OpenAPI; OAuth2/OIDC, RBAC/ABAC; Idempotent endpoint; Background job & scheduling; Caching: cache-aside, invalidation, stampede; Redis; File storage, email/notification; Rate limiting; Index & query plan; EF Core performance; Transaction & isolation level trong thực tế GĐ2
- **L3 Advanced:** Messaging: RabbitMQ vs Kafka, at-least-once, idempotent consumer, DLQ; Saga, 2PC và vì sao tránh; Partitioning, sharding, read replica; Multi-tenancy; gRPC, GraphQL — khi nào; Real-time: WebSocket/SignalR; Observability: log, metric, trace, OpenTelemetry; Resilience: retry, timeout, circuit breaker, bulkhead; OWASP, secrets, mã hóa GĐ3
- **L4 Architect:** Capacity planning, SLO/SLA, error budget; CAP/PACELC theo nghiệp vụ; Data ownership, schema evolution, zero-downtime migration; API gateway, BFF, contract; Kiến trúc bảo mật: PKI, ký số, HSM, audit; Thiết kế theo chi phí; Review checklist kiến trúc backend GĐ4

### Track 3 — Frontend Architecture (~75 bài)

- **L1 Foundation:** Nền web: HTML/CSS/JS, DOM, event loop, render; Flutter: widget tree, build/layout/paint, BuildContext; Tư duy component & state cục bộ; Gọi API, loading/error/empty; Responsive cơ bản; Accessibility cơ bản GĐ1
- **L2 Practitioner:** Quản lý state: Riverpod/Bloc, hooks/Zustand — tiêu chí chọn; Routing & deep link; Form & validation; Data fetching & cache, repository; i18n, theming, design token; Test widget; Kiến trúc thư mục theo feature GĐ2
- **L3 Advanced:** Performance: rebuild/re-render, list ảo, ảnh, bundle; Offline-first & đồng bộ; Real-time UI; Design system; SSR/SSG và Flutter Web trade-off; Bảo mật frontend: XSS, CSP, lưu token; CI frontend, error monitoring GĐ3
- **L4 Architect:** Chọn stack: Flutter vs React Native vs web vs native; Ranh giới module, feature-sliced; BFF & hợp đồng với backend; Migrate legacy; Đo trải nghiệm: Web Vitals, crash-free GĐ4

### Track 4 — Deployment & DevOps (~85 bài)

- **L1 Foundation:** Deploy là gì: từ máy mình đến máy người khác; Docker: image, layer, container, volume, network; Dockerfile cho .NET, multi-stage; Compose cho Đơn Hàng; Biến môi trường, secret cơ bản; 12-factor; Reverse proxy & TLS với Caddy/Nginx GĐ1
- **L2 Practitioner:** CI/CD với GitHub Actions: pipeline, cache, artifact, môi trường; Registry & tagging; Test & quality gate trong CI; DB migration trong pipeline; Semantic versioning, changelog, release; Deploy lên VPS rồi lên K8s; Monitoring: Prometheus, Grafana; Log tập trung: Loki GĐ2
- **L3 Advanced:** IaC: Terraform/OpenTofu, Ansible; GitOps: ArgoCD/Flux; Secret: Vault, SOPS, External Secrets; Alerting, on-call, runbook; Backup/restore, DR drill; Supply chain: SBOM, scanning, signing; Chi phí hạ tầng; mTLS GĐ3
- **L4 Architect:** Platform engineering, golden path; Blue-green, canary, feature flag; SLO, error budget, incident, postmortem; Multi-env, multi-region; Tuân thủ & audit ngân hàng/chính phủ; Tổ chức DevOps GĐ4

### Track 5 — Kubernetes (~90 bài)

- **L1 Foundation:** Vấn đề K8s giải quyết (sau khi đã đau với Compose nhiều máy); Kiến trúc cluster: control plane, kubelet, etcd, scheduler; Pod, ReplicaSet, Deployment; Service & DNS nội bộ; Namespace, label, selector; kubectl; ConfigMap, Secret; Probe, request/limit; Rolling update, rollback GĐ2
- **L2 Practitioner:** Ingress & controller; Helm: chart, values, template; Kustomize; StatefulSet, PV/PVC/StorageClass; Job/CronJob, DaemonSet; HPA, PDB; RBAC, ServiceAccount; Affinity, taint; Debug: event, log, exec; Deploy Đơn Hàng hoàn chỉnh GĐ3
- **L3 Advanced:** Networking sâu: CNI, kube-proxy, NetworkPolicy, CoreDNS; Bare-metal: MetalLB, Longhorn/Rook-Ceph, ingress HA; Vòng đời cluster: kubeadm, upgrade, etcd backup; Pod Security, OPA/Kyverno; Operator & CRD, cert-manager; Observability trong cluster; Quota, priority, VPA GĐ3
- **L4 Architect:** Multi-cluster, multi-tenant; Service mesh: khi nào thật sự cần; Platform trên K8s: ArgoCD, Backstage; HA/DR, capacity, cost; Managed vs self-hosted; Migration & anti-pattern; Review checklist cluster GĐ4

### Track 6 — Project & Engineering Management (~70 bài)

- **L1 Foundation:** Phần mềm được làm ra như thế nào: SDLC; Agile & Scrum: vai trò, sự kiện, artifact — nhìn từ ghế junior; Kanban; User story, acceptance criteria, DoD; Ước lượng cơ bản; Code review: nhận và cho; Họp hiệu quả GĐ0–1
- **L2 Practitioner:** Lập kế hoạch: three-point, velocity, buffer; Phạm vi & thay đổi; Risk register; Stakeholder & giao tiếp; Tài liệu yêu cầu; Technical writing; Retrospective; Metric: lead time, DORA GĐ2
- **L3 Advanced:** Technical debt như danh mục đầu tư; RFC/ADR trong team; Build vs buy; Ngân sách, TCO; Hợp đồng, SLA; Release planning, roadmap; Chiến lược chất lượng; Team topology cơ bản GĐ3
- **L4 Architect:** Governance nhẹ; Chiến lược kỹ thuật & hiện đại hóa; Scaling team, Team Topologies; Mentoring; Quyết định trong bất định; Trình bày cho lãnh đạo; Dự án tuân thủ ngân hàng/chính phủ GĐ4

### Track 7 — System Design tổng hợp (~35 bài · GĐ4)

- **L4 8 bài toán:** Mỗi bài toán 4 bài: yêu cầu → thiết kế → đánh đổi → phản biện. Đơn Hàng đa cửa hàng; Hệ thống thông báo; Thanh toán & đối soát; Ký số tài liệu cho ngân hàng; Tìm kiếm sản phẩm; Báo cáo & analytics; Chat hỗ trợ real-time; Nền tảng SaaS multi-tenant. Có bài mở đầu về khung trả lời system design và bài kết về "kiến trúc sư thật làm gì mỗi ngày".


## 4. Khối lượng

Tổng ≈ 650 bài, tất cả "Học" đầy đủ. Với junior không cắt GĐ0–GĐ1; nếu phải cắt, đánh dấu nhánh phụ (`main_path: false`) ở GĐ3 (bare-metal, Event Sourcing, micro-frontend) thay vì bỏ hẳn.
