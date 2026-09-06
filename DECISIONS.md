# DECISIONS.md — Quyết định đã chốt và mặc định cho phiên chạy tự trị

**Claude Code: đọc file này ngay sau CLAUDE.md, trước mọi việc.** Mọi điều dưới đây đã được chủ (An) quyết ngày 06/09/2026.
Khi tài liệu khác nói khác, **file này thắng**. Không hỏi lại các điểm đã có ở đây; với điểm chưa có, chọn mặc định hợp lý,
ghi vào mục "Mặc định agent đã chọn" ở cuối file (kèm lý do một dòng) và tiếp tục — chỉ dừng khi hành động không đảo ngược
được VÀ không có mặc định nào ở đây bao phủ.

## 1. Quyết định của chủ

| # | Chủ đề | Quyết định |
|---|---|---|
| D1 | Cửa duyệt bài | **Tự động đặt `approved`** khi: review kỹ thuật `pass` và review junior `pass` (sau khi đã áp dụng sửa), không còn `blocker`/`major`, không claim `wrong`, không `unverified` với `kind ∈ {number, syntax}`. Ghi `approved_by: auto`, `reviewed_at`. Chủ duyệt lại theo lô sau; bài chủ sửa → `status: reviewed`, review kỹ thuật lại phần đổi, rồi `approved_by: owner`. |
| D2 | Database repo ví dụ | **PostgreSQL 17** xuyên suốt. Không SQL Server ở V1. |
| D3 | Model | **Opus** cho sinh bài, sinh quiz, sinh outline, gate, repo ví dụ và hai reviewer; **Sonnet** cho dịch (`/translate`, `claude -p --model sonnet`). |
| D4 | Hosting | **GitHub**: repo `duyan11110/lo-trinh-architect` (nội dung + app + tools, monorepo), repo ví dụ `duyan11110/don-hang` (submodule tại `examples/don-hang`). GitHub Pages phục vụ site `https://duyan11110.github.io/lo-trinh-architect/` với `app/` (web) và `content/` (manifest + content.json.gz). CI = GitHub Actions. APK cài tay, không Play Store. |
| D5 | Môi trường chạy | **Máy của chủ**, Claude Code CLI đã đăng nhập; có Docker Desktop, Flutter, .NET SDK, Node, git. Agent **được cài** công cụ còn thiếu (fvm, mermaid-cli, kubeconform, psql client, gh, Dart deps) bằng brew/apt/npm/dart pub. |
| D6 | Quyền git | Agent **được** `commit`, `tag stage-N` (khi manifest đủ + kiểm tra cục bộ xanh), `push` nhánh `auto/*` và tag lên `origin` của cả hai repo. **Không** push `main`; merge `auto/*` → `main` là việc của chủ (PR). |
| D7 | Định danh app | Tên "Lộ Trình Architect", `applicationId dev.lotrinharchitect.app`, package `lta_app`, `--org dev.lotrinharchitect`, platforms `android,web`, icon mặc định Flutter, Flutter **stable mới nhất** tại thời điểm chạy (pin vào `.fvmrc` + `pubspec environment` + `app/CLAUDE.md`). |
| D8 | Repo ví dụ GĐ0 | Caddy 2.10 **giả lập hành vi API** bằng `respond`/`header` (status code, cookie, cache, POST) — chấp nhận; file văn xuôi được trích (`docs/team`, `docs/craft`, `docs/git`, `docs/clean-code`) viết **tiếng Việt** và được trích nguyên văn trong cả bản EN lẫn VI (ngoại lệ có chủ đích của style guide EN). |
| D9 | Bằng chứng reviewer | **Clone `refs/`** (`dotnet/docs`, `dotnet/AspNetCore.Docs`, `kubernetes/website`, `docker/docs`, `flutter/website`, `--depth 1`) + tải RFC 9110/9111/9112/6265 vào `refs/rfc/` (`tools/fetch-refs`). Grep nguyên văn là bằng chứng ưu tiên; WebFetch là phụ. |
| D10 | Phiên bản | .NET 10 / C# 14 / ASP.NET Core 10 / EF Core 10, PostgreSQL 17, Caddy 2.10, Git 2.5x, Npgsql 9 (khóa mới `npgsql`), Flutter stable mới nhất. Agent copy `templates/versions.yaml` → `content/versions.yaml`, ghi số patch theo `dotnet --list-sdks`, `flutter --version`, `psql --version` trên máy chủ. |
| D11 | Đích lần chạy đầu | **App M0–M7 + toàn bộ Giai đoạn 0 `approved`, dịch, `published`, bài cổng gate0**, web trên Pages + APK debug. GĐ1–4 chạy theo lệnh sau. |
| D12 | Nới điều kiện | Bỏ điều kiện "chỉ chạy headless sau khi chủ tự đọc ≥ 10 bài" (docs/06 §6) cho GĐ0. `tools/build --publish` được `tools/gen --stage 0` chạy ở cuối khi mọi bài main path đã approved + có `.vi.md`. |

## 2. Mặc định bắt buộc (chủ đã ký, agent không hỏi lại)

### A. Setup
- A1 Repo ví dụ: nếu `examples/don-hang` chưa là submodule: `gh repo create duyan11110/don-hang --public` (nếu `gh` có và đã đăng nhập), rồi `git submodule add https://github.com/duyan11110/don-hang.git examples/don-hang`. Nếu không tạo được remote: làm việc trong `examples/don-hang` như repo con độc lập (không nested-commit vào repo mẹ; thêm vào `.gitignore` tạm) và ghi vào mục 3.
- A2 Hạt giống stage-0: copy nguyên văn `examples/don-hang-stage-0/*` vào repo Đơn Hàng (kể cả `outputs/`, `unstable.regex`, `STAGE.md` làm nháp).
- A3 Bài mẫu `examples/foundation.l1.http-request-response.*` là **bài chính thức**: copy vào `content/tracks/foundation/http/` (5 file), giữ `status: approved`, `approved_by: owner`; không sinh lại. Nếu output thật của `raw-request.sh` khác mẫu (Content-Length, số header), **cập nhật output và câu chữ tương ứng trong cả EN/VI** rồi tăng `content_version` không cần (chưa published).
- A4 Git identity headless: `user.name "An (Lộ Trình Architect)"`, `user.email nguyenduyan11110@gmail.com`. `TZ=Asia/Ho_Chi_Minh` cho mọi timestamp.
- A5 Tên thư mục checkout `lo-trinh-architect`; base href `/lo-trinh-architect/app/`; `remote_base_url = https://duyan11110.github.io/lo-trinh-architect/content/`.
- A6 Chủ làm **một lần** (agent nhắc ở đầu phiên nếu chưa có): bật GitHub Pages (Settings → Pages → GitHub Actions); tạo keystore + 4 secret (`KEYSTORE_B64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`) — tới lúc đó APK ký debug; merge PR `auto/*`.

### B. Tools
- B1 Dart tools + wrapper bash như SPEC; `tools/pubspec.yaml` dùng `yaml`, `json_schema`, `args`, `crypto`, `path`, `collection`; Dart SDK theo Flutter đang cài. W → exit 0.
- B2 Mermaid: `validate` chỉ parse/đếm node bằng Dart (A.5), báo W nếu không có `mmdc`; `build` bắt buộc `mmdc` (`npx -y @mermaid-js/mermaid-cli`, Chromium qua Playwright) với `htmlLabels: false`, rồi hậu xử lý: inline CSS → thuộc tính, xóa `<style>`/`<foreignObject>`, thay màu theo sentinel. Test build: SVG không chứa `<style>` và `<foreignObject>`.
- B3 `validate`: module trong `path.yaml` chưa có `track.yaml` → W (không E); `--file` bỏ S07 (chỉ kiểm L08 khớp code với `--repo-dir`); `--stage n` chỉ kiểm giai đoạn n.
- B4 `capture-output --ref <ref>` (mặc định working tree; worktree tạm chỉ khi ref ≠ HEAD). Nguồn sự thật là `scripts/capture-output.sh` **trong repo Đơn Hàng** (CI của nó chạy được); `tools/capture-output` chỉ là wrapper.
- B5 `build --preview` (gồm bài `reviewed`, cho phép thiếu `.vi.md`) → `dist/preview/`, không tăng `content_version`; `meta.versions` = phẳng hóa mọi khóa có `version`, `standards` → chuỗi `docs`.
- B6 `tools/sync-app-content [--preview]`: cp `dist/(preview/)content.json` → `app/assets/content/content.json` + ghi `VERSION`. `tools/fetch-refs`: clone/tải D9. `tools/fetch-web-sqlite`: tải `sqlite3.wasm` + `drift_worker.js` đúng phiên bản gói, pin sha256, commit vào `app/web/`.
- B7 Agent **được sửa lỗi kỹ thuật của schema/SPEC** (ví dụ `content.schema.json` khối `path` thiếu `type`) với commit message nêu rõ; không đổi ngữ nghĩa quy tắc.
- B8 Nếu Claude Code không hỗ trợ `arguments:`/`$id`/`maxTurns` trong skill/agent: chuyển sang `$ARGUMENTS`/`$0 $1` và `argument-hint`, bỏ khóa không hỗ trợ, ghi vào mục 3.

### C. Repo ví dụ Đơn Hàng (stage-0)
- C1 Manifest bắt buộc = `tools/validate --manifest 0` (81 file). Tag `stage-0` khi: manifest đủ, `scripts/up.sh` chạy, mọi script chạy exit 0 và output đã capture, `dotnet build`/`dotnet test` của Samples xanh, CI local (`act`) hoặc GitHub Actions xanh. Không cần xác nhận của chủ (D6).
- C2 Lab box: image `lscr.io/linuxserver/openssh-server` pin tag, user `dev`, xác thực bằng khóa sinh bởi `scripts/dev-secrets.sh`, cổng 2222; `scripts/terminal/ssh-into-lab.sh` chạy được non-interactive (`ssh … 'hostname; whoami'`) và tương tác.
- C3 Caddy: HTTP `:8080` site tĩnh `www/`; HTTPS `https://donhang.local:8443` với `tls internal` (thêm `127.0.0.1 donhang.local` hướng dẫn trong STAGE.md); route giả lập: `POST /api/v1/orders` → 201 + JSON, `GET /api/v1/orders/1` → 200, `/api/v1/orders/999` → 404, `/admin` → 401 khi không cookie / 403 khi cookie `role=guest`, `/login.html` set-cookie `sid` `HttpOnly; SameSite=Lax`, `/cached.html` `Cache-Control: max-age=60` + ETag, `/slow` → 503, `/conflict` → 409, `/redirect` → 302. Danh sách này là "hành vi hệ thống" mà 8 bài HTTP được khẳng định.
- C4 Images pin: `postgres:17.6-alpine`, `caddy:2.10.0` (đổi số patch theo `docker pull` mới nhất của major đó khi bắt đầu; ghi vào mục 3). `global.json` rollForward `latestPatch`; `Directory.Packages.props` pin Npgsql 9.x mới nhất.
- C5 Script của học viên gọi `docker compose exec …` **bên trong** (ẩn); học viên chỉ chạy `scripts/<module>/<name>.sh`; Docker Desktop là điều kiện tiên quyết duy nhất (ghi ở STAGE.md và bài `terminal-basics`).
- C6 Ổn định output: `git-playground/build-history.sh` cố định `GIT_AUTHOR_DATE/GIT_COMMITTER_DATE/GIT_AUTHOR_NAME/EMAIL`; `outputs/unstable.regex` gồm Date/ETag/Last-Modified/PID/thời lượng.
- C7 Seed: 5 khách (1 không có đơn), 8 sản phẩm, 12 đơn, id cố định, tiền VND số nguyên.
- C8 Samples console dùng Npgsql 9 (khóa `npgsql` trong versions.yaml, domain `www.npgsql.org` được WebFetch).
- C9 Nếu Docker không chạy được trong phiên: commit script + output placeholder `...` và nhãn "chờ CI capture"; GitHub Actions capture chính thức; không tag cho tới khi capture xong.

### D. Pipeline nội dung
- D-1 Thứ tự sinh theo `path.yaml` (`tools/gen --stage 0`), bài chờ prereq được xếp lại sau. `generated_by` = model id. `versions_used: []` cho bài không có công nghệ.
- D-2 Gate: `type_mix` mặc định single 40 / multi 15 / truefalse 10 / order 10 / fill 10 / scenario 15 (GĐ0: fill → single). `gate0.review.json` chỉ W, không chặn build.
- D-3 Vòng lặp mỗi bài tối đa 3; `claude -p --max-turns 60`; hết vòng mà chưa approved → `status: reviewed`, ghi vào báo cáo cuối và **đi tiếp bài khác** (không dừng cả pipeline).
- D-4 Sau khi mọi bài main path GĐ0 approved: `/translate` (Sonnet) từng bài → `--parity` → `gate 0` (từng track + cross) → `build --publish` → commit `dist/` → push `auto/stage-0`.
- D-5 Chủ duyệt lô sau qua PR `auto/stage-0` → `main`.

### E. App Flutter
- E1 Flutter stable mới nhất; cài `fvm` nếu chưa có (`dart pub global activate fvm`); nếu fvm lỗi, dùng `flutter` toàn cục và ghi vào mục 3. Bỏ cờ `--web-renderer` (đã gỡ ở Flutter mới); PWA `--pwa-strategy offline-first`.
- E2 `flutter create --org dev.lotrinharchitect --project-name lta_app --platforms android,web`; label "Lộ Trình Architect"; `minSdk 26`; icon mặc định.
- E3 Font: tải Be Vietnam Pro (github.com/googlefonts/be-vietnam-pro hoặc fonts.google.com) và JetBrains Mono (github.com/JetBrains/JetBrainsMono release), commit `.ttf` + `OFL.txt`.
- E4 Icon: `Icons.*_rounded` có sẵn, không thêm gói. Golden: `alchemist`, chỉ so trên Linux CI (`platformGoldens: false`); **được tạo golden lần đầu** mỗi milestone bằng `--update-goldens`, sau đó mới áp dụng quy tắc "chỉ khi chủ yêu cầu".
- E5 Bỏ `flutter_local_notifications` khỏi V1 (setting giờ nhắc ẩn). l10n: template `app_vi.arb`, class `L`, `nullable-getter: false`.
- E6 Asset content: M0–M6 dùng `examples/content.sample.json`; M7 `tools/sync-app-content --preview` rồi bản thật khi GĐ0 published. Test `gate_sampler` dùng fixture builder trong Dart (không sửa file sample).
- E7 Integration test chạy `-d chrome` với chromedriver trên CI; `review_scheduler`/`gate_sampler` nhận `Clock`/`Random` tiêm được. "Bài x/y trong module" đếm mọi bài trong module (kể cả nhánh phụ).
- E8 CI: `content.yml` (validate → build → commit `dist/` vào nhánh `auto/*` bằng PAT `AUTO_PUSH_TOKEN` nếu có, nếu không thì upload artifact) → `app.yml` (`workflow_run`, analyze/test/build web+APK) → `actions/deploy-pages` một site gồm `app/` + `content/`. APK ký debug cho tới khi có keystore (A6).

### G. Quyền & headless
- G1 `.claude/settings.json` v1.4 đã mở: `flutter`, `fvm`, `dart`, `dotnet`, `npx/npm/node`, `docker`, `psql`, `gh`, `curl` (chỉ github.com, fonts.google.com, rfc-editor.org, sqlite.org), `mkdir/cp/chmod/mv`, `git init/clone/submodule/worktree/checkout/switch/tag`, `git push origin auto/*` và tag; **deny** `git push origin main`, `git push --force`, `rm -rf`, `WebSearch`.
- G2 Headless: `tools/gen` gọi `claude -p … --model opus` (sinh/quiz/review) và `--model sonnet` (dịch) với `--max-turns 60`; chạy tuần tự theo bài; log vào `logs/gen-<date>.log`; báo cáo cuối `logs/gen-<date>.md`.
- G3 Ngân sách: không có trần cứng ở V1 (chủ chấp nhận ≈ 300–500 lượt Opus cho GĐ0); `gen` in tổng lượt/tokens từ `--output-format json` sau mỗi module.

## 3. Mặc định agent đã chọn trong lúc chạy (agent tự ghi, một dòng mỗi mục, kèm ngày)

- (2026-09-06) A4 áp dụng ở phạm vi **local** (`git config` trong từng repo: `lo-trinh-architect` và `examples/don-hang`), không đổi `--global` — tránh ảnh hưởng cấu hình git khác của chủ trên cùng máy; vẫn đúng danh tính headless yêu cầu.
- (2026-09-06, đã gỡ) Lúc đầu tưởng `gh` chưa cài/chưa đăng nhập (không thấy trên PATH của phiên bash) → hóa ra `gh` ĐÃ cài qua winget (2.100.0) và ĐÃ đăng nhập `duyan11110` (keyring), chỉ là `C:\Program Files\GitHub CLI` chưa nằm trong PATH của phiên bash headless này (mỗi lệnh Bash khởi tạo PATH mới từ profile, không tự thấy thư mục cài thêm giữa phiên) → mọi lệnh `gh` trong phiên này cần `export PATH="/c/Program Files/GitHub CLI:$PATH"` trước. Đã xin phép chủ (bị auto-mode classifier chặn `gh repo create` vì tạo repo public là hành động hướng ngoại) rồi tạo `duyan11110/don-hang` (public), push 2 commit có sẵn, chuyển `examples/don-hang` thành submodule thật theo A1. Repo ví dụ giờ đúng D4/A1.
- (2026-09-06) **Chặn một phần (chờ chủ):** Docker Desktop đã cài (28.0.1, compose v2.33.1) nhưng **daemon không chạy** đầu phiên (`docker ps` lỗi pipe). Đây là điều kiện Bước 0 của RUNBOOK chưa đủ. Bước 3 (repo ví dụ, cần `docker compose up`, C1 manifest, capture-output) phải chờ chủ bật Docker Desktop. Agent đi tiếp Bước 2 (Tools) và phần không cần Docker.
- (2026-09-06) `psql` client chưa cài trên máy này → `content/versions.yaml.data.postgresql.version` giữ `"17"` theo D2 nhưng CHƯA xác nhận bằng `psql --version` thật (ghi rõ trong file). Sẽ cài và xác nhận khi vào Bước 3 (cùng lúc dựng container Postgres).
- (2026-09-06) Thêm `examples/don-hang/.gitattributes` (`* text=auto eol=lf`, ép LF cho `.sh`/`.sql`/`Caddyfile`) — không có trong DECISIONS gốc; máy chủ là Windows nên checkout mặc định CRLF, script chạy trong container Linux cần LF để không lỗi `$'\r': command not found`. Lý do: tránh lỗi thực thi, không đổi hành vi được dạy.
- (2026-09-06) `.gitignore` gốc: thêm `/dist/` (output `tools/build`, không commit tới khi Bước 5 cần), `/examples/don-hang/` (xem mục fallback A1 ở trên), và `/refs/` (D9 clone `dotnet/docs` + `AspNetCore.Docs` + `kubernetes/website` + `docker/docs` + `flutter/website` --depth 1 vẫn nặng ~300–700 MB/repo — commit vào git sẽ làm phình repo nội dung; DECISIONS không nói rõ nên coi đây là cache tái tạo được bằng `tools/fetch-refs`, giống `node_modules`).
