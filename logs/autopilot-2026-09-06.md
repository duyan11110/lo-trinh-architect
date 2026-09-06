# Autopilot log — 2026-09-06

## Bước 1 — Khởi tạo

**Bắt đầu:** 2026-09-06 18:08 +07.

Đọc `CLAUDE.md`, `DECISIONS.md`, `RUNBOOK.md`, `tools/SPEC.md`, `prompts/00-system.md`, `content/path.yaml`,
`content/tracks/foundation/track.yaml` trước khi hành động.

### Kiểm tra công cụ (D5)
| Công cụ | Kết quả |
|---|---|
| git | 2.46.0.windows.1 ✓ |
| dotnet | SDK 10.0.300 cài; runtime AspNetCore 10.0.11 ✓ |
| flutter | 3.47.2 / Dart 3.13.2 ✓ |
| node/npm/npx | v24.13.0 / 11.6.2 ✓ |
| docker (CLI) | 28.0.1 ✓, compose v2.33.1-desktop.1 ✓ |
| **docker (daemon)** | ✗ Docker Desktop cài nhưng không chạy — `docker ps` lỗi pipe. **Chờ chủ bật.** |
| **gh** | ✗ chưa cài, chưa đăng nhập, không có token trong env. **Chờ chủ**: `gh auth login`. |
| **psql** | ✗ chưa cài. Sẽ cài ở Bước 3 cùng lúc dựng Postgres. |
| winget/choco | có sẵn, dùng để cài công cụ còn thiếu khi cần (thay brew/apt trên Windows — D5 mặc định chọn). |

### Việc đã làm
1. Nhánh `auto/setup`.
2. `git config` local (không `--global`) cho `lo-trinh-architect` và `examples/don-hang`: `An (Lộ Trình Architect)` / `nguyenduyan11110@gmail.com` (A4, xem DECISIONS §3 lý do chỉ local).
3. `mkdir -p content/gates dist logs refs`.
4. `content/versions.yaml` từ template, điền số đã xác nhận bằng lệnh thật: dotnet 10.0/AspNetCore 10.0.11, flutter 3.47/dart 3.13, docker 28/compose 2.33, git 2.46 (khác gợi ý "2.5x" ban đầu). `postgresql`, `npgsql`, `efcore`, `riverpod`, `go_router` giữ giá trị D10 nhưng đánh dấu "chưa xác nhận qua dự án thật" — sẽ xác nhận ở Bước 3/4.
5. `content/glossary.yaml` copy nguyên văn từ template (seed Giai đoạn 0, 400 dòng) — không sửa (chỉ `merge-outline` được sửa file này).
6. Bài mẫu `foundation.l1.http-request-response` (5 file) copy vào `content/tracks/foundation/http/`, giữ nguyên `status: approved`, `approved_by: owner` (A3).
7. A1 (`gh` không dùng được): `examples/don-hang` khởi tạo là **repo git độc lập tại chỗ** (không submodule): seed từ `examples/don-hang-stage-0/*` (A2) + `.gitattributes` ép LF cho `.sh`/`.sql`/`Caddyfile` (script chạy trong container Linux). 2 commit. Thêm `/examples/don-hang/` vào `.gitignore` gốc — không nested-commit.
8. D9 (`tools/fetch-refs` chưa tồn tại — Bước 2 mới sinh — nên chạy trực tiếp `git clone --depth 1` + `curl` cho 5 repo docs + 4 RFC): **đang chạy nền** lúc ghi log này (dotnet/docs 687M, AspNetCore.Docs 328M xong; kubernetes/website, docker/docs, flutter/website, RFC đang tải). `/refs/` thêm vào `.gitignore` (cache tái tạo được, không commit — xem DECISIONS §3).
9. Mọi mặc định chưa có trong DECISIONS.md ghi vào mục 3 kèm ngày và lý do (định danh git local, fallback `gh`, Docker daemon chưa chạy, `psql` chưa cài, `.gitattributes` LF, `.gitignore` cho `dist/`/`examples/don-hang/`/`refs/`).

### Việc chờ chủ (không tự làm được ở phiên headless)
- Bật **Docker Desktop** (chặn Bước 3 và mọi capture-output).
- `gh auth login` (chặn tạo repo GitHub `don-hang` thật + mở PR Bước 7). Cho tới lúc đó `examples/don-hang` vẫn là repo cục bộ hợp lệ, không mất công.
- (tùy chọn, có thể sau — RUNBOOK Bước 0) keystore Android + PAT `AUTO_PUSH_TOKEN`.

### Done Bước 1 (theo RUNBOOK)
- [x] `content/versions.yaml`, `content/glossary.yaml` tồn tại.
- [x] `examples/don-hang` tồn tại (repo cục bộ, không phải submodule như kỳ vọng — xem lý do trên).
- [x] `refs/` tồn tại đủ 5 repo (`dotnet-docs`, `aspnetcore-docs`, `kubernetes-website`, `docker-docs`, `flutter-website`) + 4 RFC (`rfc9110.txt` 502 KB, `rfc9111.txt` 84 KB, `rfc9112.txt` 110 KB, `rfc6265.txt` 80 KB) — xác nhận 18:13.
- [x] `git status` sạch trên `auto/setup` (2 commit), đã push `origin/auto/setup`.

**Kết thúc Bước 1:** 2026-09-06 18:13 +07. **Bước 1 hoàn tất.**

## Bước 2 — Tools

**Bắt đầu:** 2026-09-06 18:18 +07, nhánh `auto/tools` (stacked trên `auto/setup`).

Giao việc cho subagent nền: sinh `tools/src/*.dart` + `tools/pubspec.yaml` + wrapper bash (`validate`, `known-vocab`, `extract-code`, `merge-outline`, `capture-output`, `build`) + bash thuần (`fetch-refs`, `sync-app-content`, `fetch-web-sqlite`, `gen`) theo `tools/SPEC.md` đầy đủ (~70 mã lỗi S/L/M/Q/R/P/T + Phụ lục A thuật toán dùng chung). Điều kiện Done trước khi nhận: `tools/validate --file examples/foundation.l1.http-request-response.en.md --repo-dir examples/don-hang-stage-0` exit 0 chỉ W; `tools/validate --structure-only --no-repo --stage 0` exit 0; `dart test` xanh. Agent không tự commit/push — sẽ kiểm tra rồi commit thủ công khi xong.
