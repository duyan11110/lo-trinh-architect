# RUNBOOK.md — Lần chạy tự trị đầu tiên (đích: DECISIONS.md D11)

Thứ tự bắt buộc. Mỗi bước có **Done** để agent tự kiểm; không nhảy bước. Mọi thứ cần chủ làm nằm ở **Bước 0** — sau đó agent chạy tới hết
mà không hỏi (DECISIONS.md thắng khi có nghi ngờ). Skill `/autopilot` thực thi runbook này; `/autopilot <bước>` chạy lại từ một bước.

## Bước 0 — Chủ làm một lần (5 phút)
- [ ] Máy có: Docker Desktop đang chạy, Flutter stable, .NET 10 SDK, Node ≥ 20, git, `claude` đã đăng nhập, `gh auth login` (để tạo repo `don-hang` và mở PR).
- [ ] Tạo repo `duyan11110/lo-trinh-architect` (public), push bộ thiết kế này lên `main`.
- [ ] Settings → Pages → Source: **GitHub Actions**.
- [ ] (tùy chọn, có thể sau) keystore + 4 secret; PAT `AUTO_PUSH_TOKEN` để CI commit `dist/`.
- [ ] Mở Claude Code tại gốc repo, gõ `/autopilot`.

## Bước 1 — Khởi tạo (agent, ~1 giờ)
1. Đọc `CLAUDE.md`, `DECISIONS.md`, `docs/06`. Ghi `git config` theo A4; `export TZ=Asia/Ho_Chi_Minh`.
2. `cp templates/versions.yaml content/versions.yaml`, `cp templates/glossary.yaml content/glossary.yaml`; điền số patch theo lệnh thật (D10). `mkdir -p content/gates dist logs refs`.
3. Repo ví dụ theo A1 (`gh repo create` → submodule) và hạt giống A2.
4. Bài mẫu thành bài chính thức theo A3.
5. `tools/fetch-refs` (D9). Cài công cụ thiếu (D5): fvm, mermaid-cli (`npx`), kubeconform (chưa cần GĐ0), psql client, `act` (tùy chọn).
6. Nếu skill/agent frontmatter không được Claude Code hỗ trợ → sửa theo B8.
**Done:** `git status` sạch trên nhánh `auto/setup`; `content/versions.yaml`, `content/glossary.yaml`, `examples/don-hang` (submodule), `refs/` tồn tại; commit + push `auto/setup`.

## Bước 2 — Tools (agent, 1–2 phiên)
Sinh `tools/src/*.dart`, `tools/pubspec.yaml`, wrapper bash, `tools/gen` (bash), `tools/fetch-refs`, `tools/sync-app-content`, `tools/fetch-web-sqlite` theo `tools/SPEC.md` + DECISIONS B1–B7. Mỗi mã lỗi = một test.
**Done:** `tools/validate --file examples/foundation.l1.http-request-response.en.md --repo-dir examples/don-hang-stage-0` exit 0 (chỉ W); `tools/validate --structure-only --no-repo --stage 0` exit 0; `dart test` trong `tools/` xanh; commit + push `auto/tools`.

## Bước 3 — Repo ví dụ stage-0 (agent, 1–2 phiên)
`/repo-stage 0` theo prompt 08 + DECISIONS C1–C9. Manifest = `tools/validate --manifest 0`.
**Done:** tag `stage-0` tồn tại và đã push; `tools/validate --structure-only --stage 0` exit 0 **không** W S07; output đã capture cho mọi script; bài mẫu vẫn xanh với `--repo-dir examples/don-hang` ở tag.

## Bước 4 — App M0–M6 (agent, song song với bước 5 nếu chạy 2 phiên; nếu một phiên thì làm sau bước 5)
Trong `app/` theo `app/CLAUDE.md` + docs/07 §11, asset = `examples/content.sample.json` (E6).
**Done mỗi milestone:** `flutter analyze` 0 cảnh báo, `flutter test` xanh, golden tạo lần đầu (E4); commit `auto/app-mN` + push.

## Bước 5 — Nội dung GĐ0 (agent, chạy dài — `tools/gen --stage 0`)
Theo SPEC gen + DECISIONS D-1…D-4: sinh → quiz → validate → 2 review → sửa (≤ 3 vòng) → approved (D1) → translate (Sonnet) → parity; hết 11 module → gate0 (từng track + cross) → `build --publish` → commit `dist/` → push `auto/stage-0`.
**Done:** `tools/status` (hoặc `/status`) cho thấy: 55 bài main path GĐ0 `published` (bài nhánh phụ có thể `reviewed`), `content/gates/gate0.json` ≥ 90 câu, `dist/manifest.json` `content_version ≥ 1`; `logs/gen-<date>.md` có bảng tổng kết; những bài kẹt `reviewed` được liệt kê rõ lý do.

## Bước 6 — App M7 + CI + deploy (agent)
`tools/sync-app-content`; CI theo docs/07 §10 + DECISIONS E8; build web + APK.
**Done:** workflow `app.yml` xanh trên nhánh `auto/stage-0`; site Pages mở được `…/app/` và `…/content/manifest.json`; APK artifact tải được; app trên web đọc được bài GĐ0 và cập nhật nội dung từ xa thành công (kiểm bằng integration test hoặc log).

## Bước 7 — Bàn giao (agent)
Mở PR `auto/stage-0` → `main` (gh) với mô tả: số bài theo status, bài cần chủ xem (`unverified` fact/behavior, hết 3 vòng), link Pages, link APK artifact, tổng lượt gọi model. Ghi `logs/handover-<date>.md`. **Dừng.** Việc còn lại của chủ: duyệt lô, merge, học.

## Khi kẹt
- Thiếu công cụ mà không cài được → ghi vào DECISIONS.md mục 3 cách vòng qua (ví dụ C9), tiếp tục các phần không phụ thuộc.
- Bài không qua được 3 vòng → giữ `reviewed`, đi tiếp (D-3). Không sửa outline/vocab tự ý; ghi đề xuất vào `logs/`.
- Lệnh bị chặn quyền → kiểm `.claude/settings.json`; nếu là hành động trong deny (push main, force) → đó là cố ý, tìm đường khác (nhánh `auto/*`).
- Mọi lỗi khác lặp 2 lần → ghi lại, đánh dấu bước đó "chờ chủ", tiếp tục bước sau nếu độc lập.
