# 08 — Repo ví dụ Đơn Hàng: tạo/cập nhật cho một giai đoạn (tag `stage-N`)

> Cách dùng: system = `00-system.md`. Chạy trong Claude Code **bên trong** `examples/don-hang/`. Đầu vào: `STAGE.md` mục tiêu
> (bạn viết hoặc để prompt đề xuất), `content/versions.yaml`, danh sách `repo_changes_needed` gom từ outline/bài của giai đoạn,
> tag trước đó (nếu có). Đầu ra: code, script, test, CI xanh, `STAGE.md`, `outputs/<tag>/`, và tag Git.
> Nguyên tắc: repo này là **sách giáo khoa bằng code** — đọc được quan trọng hơn thông minh.

---

## Task

Bring the Đơn Hàng repository to the state required for stage {{stage}} and tag it `stage-{{stage}}`.

### Inputs

- Target state description (`STAGE.md` draft or bullet list): {{stage_target}}
- Previous tag: {{prev_tag}} (or none)
- Pinned versions: {{versions_yaml}}
- Code the lessons need (from `repo_changes_needed`, each with lesson id, need, suggested path): {{repo_changes_needed}}
- **Mandatory file manifest** — every `example_files` path of every lesson in this stage (`tools/validate --manifest {{stage}}`): {{manifest}}.
  Each must exist at the tag with the behaviour its lesson's `outline` describes; missing any one blocks the tag.
- Fixed names: solution `DonHang`; projects `DonHang.Api`, `DonHang.Domain`, `DonHang.Infrastructure`, `DonHang.App` (Flutter),
  `DonHang.Tests`; tables `customers`, `products`, `orders`, `order_items`, `payments`, `notifications`; endpoints `/api/v1/<plural>`.

## Stage targets (reference — the curriculum's contract; adjust only via `STAGE.md`)

| Tag | State |
|---|---|
| `stage-0` | Root: `docker-compose.yml`, `Caddyfile`, `scripts/up.sh`/`down.sh` (start the lab: Caddy static site on :8080, PostgreSQL on :5432, an SSH lab box on :2222 — learners only run `up.sh`; what Compose is comes in stage 1). `db/schema.sql` + `db/seed.sql` and `db/queries/*.sql` for the SQL lessons; `www/` static site; `scripts/<module>/*.sh` for every terminal/`curl`/`git`/`psql` command the lessons show, with captured `outputs/stage-0/scripts/<module>/<name>.txt`; `docs/<module>/*.md` for quotable prose (team examples, question/bug-report templates, commit-message examples, doc-reading checklist); a small console project `samples/DonHang.Samples` (one file per lesson under `Samples/<Module>/`) for the OOP, collections, async, clean-code and debugging lessons — it reads from the same PostgreSQL schema but has no web API. A `git-playground/` script that builds a throwaway repo with a known history for the Git lessons. `docs/<module>/*.md`: worked examples (a sprint, a story with acceptance criteria, review comments, meeting notes, question and bug-report templates, commit-message examples, reading-order guide) **written in Vietnamese** (DECISIONS.md D8) — prose files are quotable like code and are quoted verbatim in both EN and VI lessons. Caddy routes, lab box, seed sizes and image tags: DECISIONS.md C2–C7. |
| `stage-1` | `DonHang.Api` 3-layer monolith (controllers → services → EF Core repositories), JWT login, orders/products endpoints, validation, structured logging, `DonHang.App` Flutter listing products and creating an order, `docker-compose.yml` (api + postgres + app-web), unit tests with test doubles. |
| `stage-2` | OAuth2/OIDC via an external provider in Compose (e.g. Keycloak), Redis cache-aside for products, background job for order emails, API versioning + pagination + RFC 9457 errors, GitHub Actions CI/CD building images, Helm-free plain K8s manifests under `deploy/k8s/`, Prometheus/Grafana/Loki Compose profile, integration tests with testcontainers. |
| `stage-3` | Modular monolith split into `Ordering`, `Payment`, `Notification` modules; then `Payment` and `Notification` extracted as services; RabbitMQ with outbox/inbox; order-cancellation saga; OpenTelemetry traces/metrics/logs; Helm chart under `deploy/helm/`; ArgoCD app manifests; NetworkPolicy, RBAC, StatefulSet for PostgreSQL. |
| `stage-4` | Multi-tenant (store per tenant, row-level), e-invoice signing module with PKI (test CA, no HSM), SLO definitions + alert rules, multi-cluster deploy overlay, ADRs under `docs/adr/`. |

## Rules

1. **Readable over clever.** Every file a lesson will quote must be understandable in isolation by a junior: small files,
   explicit names, no reflection tricks, no source generators, no clever LINQ chains, comments only where the *why* is not obvious.
   Prefer 3 obvious lines to 1 dense one.
2. **Stable names.** Once a class, table, endpoint or file path is quoted by an `approved` lesson at an earlier tag, it keeps its name
   and path in later tags unless a lesson is *about* renaming it (then the ADR says so).
3. **Every quoted region is quotable.** Files listed in `repo_changes_needed` must contain the needed behaviour in a contiguous block
   ≤ 25 lines, so a lesson can quote it with `lines=a-b`. Add a `// lesson: <id>` comment on the line *before* such a block (not inside it).
4. **Scripts are the lessons' commands.** Every shell/`kubectl`/`psql`/`git` command a lesson shows lives in `scripts/<module>/<name>.sh`
   with a one-line header comment, runs non-interactively, exits non-zero on failure, and is executed by CI. Outputs are captured by
   `tools/capture-output` into `outputs/<tag>/scripts/<module>/<name>.txt` (script path without extension); unstable parts are replaced by `...`
   according to `outputs/unstable.regex`.
5. **Versions exactly as pinned.** `global.json` pins the SDK; `Directory.Packages.props` pins packages; `pubspec.lock` committed;
   images in Compose/K8s pinned by tag, never `latest`.
6. **CI is the proof.** `.github/workflows/ci.yml` builds, tests, runs every script under `scripts/` against the Compose stack,
   validates K8s manifests with `kubeconform` (stage ≥ 2) and `helm lint` (stage ≥ 3), and fails on any warning the lessons would show.
   The tag is created only from a green CI run.
7. **`STAGE.md`** at the repo root describes the system at this tag in ≤ 400 words: components, data flow in one Mermaid diagram,
   what changed since the previous tag and why (one paragraph), and a table "file → what a lesson can learn from it" for every file
   listed in `repo_changes_needed`. This file is fed to prompt 02 as `example_context`.
8. **No business cleverness.** Đơn Hàng is deliberately boring: no discounts engine, no inventory reservation puzzles, unless a lesson needs them.
9. **Secrets** are development-only, obviously fake, and generated by `scripts/dev-secrets.sh`; nothing real, ever.

## Procedure

1. Read `{{prev_tag}}` (if any) and `STAGE.md`. List the delta required by `{{stage_target}}` and `{{repo_changes_needed}}`.
2. Propose the file-level plan (paths, one line each) and the `STAGE.md` draft. **Stop and wait for approval** before writing code.
3. Implement in small commits per concern. Keep the app runnable at every commit (`docker compose up` works).
4. Run CI locally (`act` or the same commands). Fix until green. Capture outputs.
5. Write `STAGE.md`. Create the tag `stage-{{stage}}` when the conditions in `DECISIONS.md` C1 hold (manifest complete, scripts run, outputs captured, build/test green, CI green); otherwise report what is missing and stop without tagging. Report: files added/changed, scripts, outputs captured, and any `repo_changes_needed` you could not satisfy and why.
