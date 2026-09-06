# 06 — Dùng bộ thiết kế này với Claude Code

Bộ thiết kế được đóng gói để **trở thành repo nội dung**: giải nén là có `CLAUDE.md`, `.claude/` (skill, subagent, quyền),
`prompts/`, `schemas/`, `content/`. Claude Code đọc `CLAUDE.md` mỗi phiên, gọi được các skill bằng `/tên`, và hai reviewer
chạy như subagent với ngữ cảnh riêng — đúng yêu cầu "phiên mới" trong docs/02.

## 1. Ánh xạ prompt → cách gọi trong Claude Code

| Việc | Prompt | Gọi trong Claude Code | Cơ chế |
|---|---|---|---|
| Outline một module | 01 | `/outline foundation computer 0 stage-0` | skill `.claude/skills/outline` |
| Sinh bài | 02 | `/lesson foundation.l1.program-to-process` · `/lesson <id> fix-validation` · `/lesson <id> apply-review` | skill `lesson` |
| Sinh quiz | 03 | `/quiz <id>` | skill `quiz` |
| Review kỹ thuật | 04 | "Dùng subagent review-technical cho bài <id>" hoặc `@"review-technical (agent)"` | subagent, **ngữ cảnh riêng**, có WebFetch tới docs chính thức |
| Review đọc như người mới | 05 | "Dùng subagent review-junior cho bài <id>" | subagent, ngữ cảnh riêng, **không** WebFetch/WebSearch |
| Dịch | 06 | `/translate <id>` | skill `translate` |
| Bài cổng | 07 | `/gate 0 foundation` · `/gate 0 cross` | skill `gate` |
| Repo ví dụ | 08 | `/repo-stage 0` | skill `repo-stage` (dừng chờ bạn duyệt kế hoạch) |
| Cả module tự động | 02→05 | `/gen-module foundation/computer` | skill `gen-module` gọi các skill trên + hai subagent, tối đa 3 vòng, dừng ở `reviewed` |
| Tình hình | — | `/status` | skill `status` |
| **Chạy tự trị toàn bộ** | RUNBOOK.md | `/autopilot` | skill `autopilot`: bước 1→7 tới PR bàn giao, đích DECISIONS.md D11 |

Mỗi skill chỉ là một file `SKILL.md` ngắn nói "đọc `prompts/0N-….md` và làm theo, với ngữ cảnh X" — prompt vẫn là **nguồn sự thật duy nhất**,
sửa prompt là mọi skill đổi theo. `outline`, `gate`, `repo-stage`, `gen-module` có `disable-model-invocation: true` (chỉ chạy khi bạn gõ `/…`);
`lesson`, `quiz`, `translate`, `status` không có cờ đó để `/gen-module` gọi được chúng.

> Nếu bản Claude Code của bạn chưa có `.claude/skills/`, copy nội dung mỗi `SKILL.md` sang `.claude/commands/<tên>.md` và thay `$id`, `$mode`… bằng `$ARGUMENTS` — cú pháp cũ vẫn chạy.

## 2. Thiết lập lần đầu (30 phút) — với DECISIONS.md, agent tự làm được toàn bộ mục này trừ việc tạo repo remote nếu `gh` chưa đăng nhập

```bash
# 1. Repo nội dung
mkdir lo-trinh-architect && cd lo-trinh-architect   # repo: duyan11110/lo-trinh-architect
unzip ~/Downloads/lo-trinh-architect-design-v1.3.zip && mv lta/* lta/.claude . && rmdir lta
git init && git add -A && git commit -m "Design package v1.3"

# 2. Nguồn sự thật
cp templates/versions.yaml content/versions.yaml      # rồi sửa theo `dotnet --version`, `kubectl version`, `flutter --version`
cp templates/glossary.yaml content/glossary.yaml
mkdir -p content/gates dist

# 3. Repo ví dụ Đơn Hàng (submodule, để mọi code block tra được theo tag)
git submodule add https://github.com/duyan11110/don-hang.git examples/don-hang   # gh repo create duyan11110/don-hang --public
# hoặc, khi chưa có: mkdir -p examples/don-hang && git -C examples/don-hang init

# 4. (khuyến nghị) bản sao docs chính thức để reviewer Grep nguyên văn — bằng chứng mạnh hơn WebFetch
mkdir refs && cd refs
git clone --depth 1 https://github.com/dotnet/docs dotnet-docs
git clone --depth 1 https://github.com/dotnet/AspNetCore.Docs aspnetcore-docs
git clone --depth 1 https://github.com/kubernetes/website kubernetes-website
git clone --depth 1 https://github.com/docker/docs docker-docs
git clone --depth 1 https://github.com/flutter/website flutter-website
cd ..

# 5. Vào Claude Code
claude
```

Trong phiên đầu tiên, việc hợp lý là bảo Claude Code **sinh công cụ** từ đặc tả:

```
Đọc tools/SPEC.md (kể cả Phụ lục A), docs/01 và schemas/. Viết tools/src/*.dart với tools/pubspec.yaml riêng và các wrapper bash
tools/validate, tools/known-vocab, tools/extract-code, tools/merge-outline, tools/capture-output, tools/build; mỗi mã lỗi trong SPEC
là một test. Chạy thử: tools/validate --file examples/foundation.l1.http-request-response.en.md --repo-dir examples/don-hang-stage-0
phải xanh (chỉ W cho link hứa trước).
```

Đây là việc 1–2 buổi tối; xong thì mọi bước sau đều có "cửa" máy. Không nên sinh bài trước khi có `validate`.

## 3. Nhịp làm một module (đúng docs/02)

```
/repo-stage 0                        # lần đầu mỗi giai đoạn: kế hoạch → bạn duyệt → code → tag stage-0
/outline foundation computer 0 stage-0
# → content/tracks/foundation/outline-computer.draft.yaml
#   Bạn biên tập tay (cắt/ghép bài, sửa outline & misconceptions), rồi gộp vào track.yaml
tools/validate --structure-only

/gen-module foundation/computer      # sinh → quiz → validate → 2 review → sửa, tối đa 3 vòng
/status                              # xem bài nào đã 'reviewed', còn blocker gì
```

Bước 5 (bạn duyệt) không có skill — cố ý. Mở `.en.md` và `.review.json`, tick checklist trong docs/02, đặt `status: approved`
và `reviewed_at` bằng tay. Sau đó:

```
/translate foundation.l1.program-to-process
tools/build && git add -A && git commit -m "foundation/computer: 5 lessons" && git push   # GitHub Pages phục vụ dist/
```

Khi muốn kiểm soát từng bước thay vì `/gen-module`:

```
/lesson foundation.l1.program-to-process
/quiz   foundation.l1.program-to-process
Dùng subagent review-technical cho bài foundation.l1.program-to-process
Dùng subagent review-junior cho bài foundation.l1.program-to-process
/lesson foundation.l1.program-to-process apply-review
```

## 4. Vì sao reviewer là subagent chứ không phải một prompt nữa trong cùng phiên

Subagent có **cửa sổ ngữ cảnh riêng**: nó không thấy prompt sinh bài, không thấy lý do tác giả, không thấy bạn vừa bảo "viết ngắn thôi".
Đó chính là điều kiện A9 trong docs/03. Hai agent còn khác nhau ở công cụ: `review-technical` được WebFetch tới đúng các domain docs
chính thức liệt kê trong `.claude/settings.json` (và bị chặn WebSearch để không lấy blog làm bằng chứng); `review-junior` bị cấm
mọi truy cập mạng — nó phải "ngu" đúng mức một junior chỉ biết `known_vocab`.

Cả hai dùng `model: opus`. Sinh bài và dịch chạy bằng model của phiên chính (khuyến nghị Opus cho sinh bài; dịch có thể hạ xuống
Sonnet bằng `/model` trước khi gọi `/translate` nếu muốn tiết kiệm — nhưng đọc lướt bản VI kỹ hơn).

## 5. Quyền (`.claude/settings.json`)

Đã pre-approve: đọc/ghi file, `git` cục bộ (không `push`), chạy `tools/*`, `dotnet build/test`, `kubeconform`, `helm lint/template`,
`docker compose`, `flutter`, `dotnet`, `npx`, `gh`, `curl` tới GitHub/RFC/Google Fonts, `git push origin auto/*` và tag, WebFetch tới ~30 domain docs chính thức. Bị từ chối: `git push origin main`, force-push, `rm -rf`, `WebSearch`. Mọi thứ khác Claude Code
sẽ hỏi. Thêm domain vào `permissions.allow` khi `versions.yaml` có `docs` mới — reviewer không được lấy bằng chứng từ nơi không có trong danh sách.

## 6. Chạy không tương tác (khi đã tin pipeline)

Sau vài module đầu, bạn có thể để `tools/gen` gọi Claude Code headless thay vì gõ tay:

```bash
claude -p "/lesson $ID generate" --output-format json --allowedTools "Read,Write,Edit,Glob,Grep,Bash(tools/*),Bash(git show *)"
claude -p "Dùng subagent review-technical cho bài $ID" --output-format json
```

`tools/gen --stage 0` lặp qua các module theo `path.yaml` với vòng lặp giống `gen-module`, đặt `approved` theo điều kiện DECISIONS.md D1, dịch (Sonnet),
sinh gate, `build --publish`, commit `dist/` và push nhánh `auto/stage-0`. Chạy qua đêm; sáng hôm sau `/status`, mở PR `auto/stage-0` → `main` và duyệt lô.
(Chủ đã bỏ điều kiện "tự đọc ≥ 10 bài trước" cho GĐ0 — DECISIONS.md D12.)

## 7. Lỗi hay gặp và cách xử lý

| Triệu chứng | Nguyên nhân thường gặp | Làm gì |
|---|---|---|
| `/lesson` trả `blocked: missing code` | `example_files` chưa có ở tag | `/repo-stage N` với `repo_changes_needed`, tag lại, chạy lại |
| Nhiều L15 (term chưa dạy) | outline đặt bài quá sớm hoặc thiếu `vocab` | sửa `track.yaml`: thêm term + glossary, hoặc dời bài ra sau |
| review-technical toàn `unverified` | WebFetch chỉ trả bản tóm tắt; domain docs không trong `permissions.allow`; `source_hint` mơ hồ | clone docs vào `refs/` (mục 2) để Grep nguyên văn; thêm domain; yêu cầu `source_hint` cụ thể hơn |
| Bài dài quá 1.600 từ | outline có 6 ý quá rộng | tách bài trong outline, không cắt bớt trong bài |
| Bản VI "mùi dịch" | thiếu mẫu giọng VI | duyệt kỹ 2 bài VI đầu tiên của track; các bài sau dùng chúng làm `voice_sample` |
| Claude "sửa cho hợp lý" thay vì dừng | vi phạm CLAUDE.md quy tắc 1–3 | nhắc lại đúng số quy tắc; nếu lặp lại, chạy skill trong phiên mới (`/clear`) để bỏ ngữ cảnh đã lệch |

## 8. Những gì KHÔNG giao cho Claude Code

Biên tập outline (bước 1) cho GĐ1–4 (GĐ0 đã chốt), duyệt lô qua PR, merge `auto/*` → `main`, bật GitHub Pages, tạo keystore/secrets, đổi `versions.yaml` khi nâng phiên bản. Mọi thứ khác — kể cả `approved` tự động, tag `stage-N`, push `auto/*`, `build --publish` — agent làm theo DECISIONS.md.
Đây là các điểm mà một sai sót lan ra hàng chục bài — chúng cần một người, và người đó là bạn.
