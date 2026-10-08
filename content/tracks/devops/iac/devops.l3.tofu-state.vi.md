---
id: devops.l3.tofu-state
lang: vi
track: devops
level: 3
stage: 3
module: iac
main_path: true
title: "File state là cách OpenTofu biết object thật nào ứng với khối nào"
duration_min: 14
skills: [devops.iac.state]
prereqs: [devops.l3.plan-and-apply, k8s.l1.kubectl-and-the-api-server, devops.l1.secrets-vs-config]
related: [k8s.l1.manifests-and-kubectl-apply, k8s.l1.secrets]
vocab: [tofu-state]
example_tag: stage-3
versions_used: [opentofu, opentofu_provider_kind, kind, kubernetes, git]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-10-08T11:41:16+07:00"
---

## Bạn cần biết trước

- [[devops.l3.plan-and-apply]] — bạn đã thấy plan so `main.tf` với "các object OpenTofu đã tạo trước đó". Bài này nói về bản ghi mà phép so đó đọc.
- [[k8s.l1.kubectl-and-the-api-server]] — bạn đã thấy kubectl tới API server bằng thông tin đăng nhập trong kubeconfig. OpenTofu cũng giữ loại thông tin đăng nhập đó cho `donhang-iac`.
- [[devops.l1.secrets-vs-config]] — bạn đã thấy `.gitignore` giữ `.env` ngoài Git, vì ai đọc được secret thì có luôn quyền của nó. Bài này thêm một file nữa thuộc loại đó.

## Tình huống

`donhang-iac` đã chạy từ lúc bạn apply `deploy/tofu/lessons/first-cluster`. Một đồng nghiệp dọn thư mục đó và thấy, ngay cạnh `main.tf`, một file mà `git status` chưa bao giờ liệt kê: `terraform.tfstate`. Trông nó như output sinh tự động, nên họ muốn xóa đi. Họ cũng muốn xóa khối `resource`, để OpenTofu thôi quản lý cluster mà cluster vẫn chạy cho các bài test của họ. Theo họ, `main.tf` đã đặt tên cluster là `donhang-iac`, nên lúc nào OpenTofu cũng tìm lại được nó theo tên. File đó có thật là đồ thừa không, và OpenTofu dùng nó vào việc gì?

## Khái niệm cốt lõi

- **state (OpenTofu)** (Bản ghi của OpenTofu nối mỗi địa chỉ resource với object thật nó đã tạo, kèm thuộc tính đọc về, ở dạng chữ rõ) — bản ghi OpenTofu viết sau mỗi lần apply, nối mỗi địa chỉ resource trong configuration với object thật mà provider đã tạo cho nó, kèm các attribute đọc về từ object đó. Trong `first-cluster`, nó là một file văn bản thường.
- Attribute — một giá trị có tên của resource, như `name`, hoặc được viết trong khối, hoặc được đọc về từ object thật.
- Địa chỉ resource — tên mà plan và state dùng cho một resource. Với resource nằm ngay trong thư mục của configuration, đó là kiểu và tên cục bộ nối bằng dấu chấm, như `kind_cluster.this`.
- Giá trị sensitive — giá trị mà OpenTofu che đi trong những gì plan và apply in ra, hiện `(sensitive value)` ở chỗ của nó. Một giá trị trở thành sensitive khi configuration đánh dấu nó bằng `sensitive = true`.
- Plan đã lưu bị cũ — plan lưu bằng `-out` mà state đã đổi kể từ lúc lập, nên `tofu apply` từ chối nó.

## Cơ chế hoạt động

```mermaid
flowchart LR
  F["main.tf: kind_cluster.this"] --> P["tofu plan"]
  S["terraform.tfstate: kind_cluster.this is donhang-iac"] --> P
  P -->|"reads current values"| C["cluster donhang-iac"]
  P --> L["actions: create, update, replace, destroy"]
  L --> A["tofu apply"]
  A -->|"writes after acting"| S
```

Trong tình huống trên, `terraform.tfstate` chính là state. Sau mỗi lần apply, OpenTofu viết nó ra, mặc định với tên đó trong thư mục của configuration. `terraform.tfstate` chỉ đơn giản là tên file mặc định OpenTofu dùng. Với địa chỉ `kind_cluster.this`, nó ghi lại object thật nào provider đã tạo, ở đây là kind cluster `donhang-iac`, cùng các attribute đọc về từ cluster đó, như `client_key`.

Plan bắt đầu từ state. Nó đọc giá trị hiện tại của từng object được ghi trong đó, rồi so kết quả với các file, từng địa chỉ một. Địa chỉ có ở cả hai bên được so từng attribute, cho ra một lần sửa, một lần thay thế, hoặc không gì cả. Địa chỉ chỉ có trong file sẽ được lên plan tạo mới. Địa chỉ chỉ có trong state, không còn gì trong file nhắc tới nữa, sẽ được lên plan xóa: file không còn muốn object đó, còn state nói nó đang tồn tại.

`kubectl apply -f`, theo cách Đơn Hàng dùng, không giữ bản ghi nào như vậy. Nó gửi đi các object trong những manifest bạn truyền vào và không biết gì về những cái bạn thôi truyền, nên object nào bị xóa manifest thì vẫn tiếp tục chạy.

Với OpenTofu, cái tên `donhang-iac` trong `main.tf` chỉ là giá trị của một attribute. OpenTofu không bao giờ tìm object đang có theo tên. Không có state, địa chỉ nào cũng chỉ có trong file, nên plan tạo lại mọi thứ.

Plan đã lưu chứa các hành động tính ra từ state ở đúng thời điểm đó. Nếu state đã đổi kể từ lúc ấy, `tofu apply` từ chối file thay vì làm các hành động trong đó.

## Trong hệ thống Đơn Hàng

`scripts/devops/tofu-state.sh` chạy sau `tofu-plan-apply.sh`, trong thư mục `first-cluster` nơi `donhang-iac` đã được apply. Khi kết thúc, nó trả mọi file về như cũ.

```bash file=scripts/devops/tofu-state.sh tag=stage-3 lines=8-28
# lesson: devops.l3.tofu-state
# After apply, the state maps each resource address to the real object and
# the attributes read back from it, in terraform.tfstate next to main.tf.
show tofu state list
echo
# The client key that administers the cluster sits in it as plain text
# (only its first line is printed here).
echo '$ grep -o '"'"'"client_key": *"-----BEGIN [A-Z ]*-----'"'"' terraform.tfstate'
grep -o '"client_key": *"-----BEGIN [A-Z ]*-----' terraform.tfstate
echo

# lesson: devops.l3.tofu-state
# A block removed from the files, still in the state: planned for destruction.
echo "== main.tf without its resource block"
cp main.tf main.tf.orig
trap 'mv main.tf.orig main.tf' EXIT
perl -0pi -e 's/\n# lesson: devops\.l3\.plan-and-apply\n.*//s' main.tf
tofu plan -no-color | grep -e '^  # ' -e '^Plan:'
mv main.tf.orig main.tf
trap - EXIT
echo
```

```text output=true
$ tofu state list
kind_cluster.this

$ grep -o '"client_key": *"-----BEGIN [A-Z ]*-----' terraform.tfstate
"client_key":"-----BEGIN RSA PRIVATE KEY-----

== main.tf without its resource block
  # kind_cluster.this will be destroyed
  # (because kind_cluster.this is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
...
```

`show` in lệnh sau dấu `$`, rồi chạy nó. `tofu state list` in các địa chỉ mà state đang giữ: một địa chỉ, `kind_cluster.this`. `grep` tìm thấy `client_key` được ghi nguyên văn trong file. Đó là private key của thông tin đăng nhập trong kubeconfig của cluster, thứ kubectl dùng để tới `donhang-iac`. Script cố ý chỉ in dòng đầu của nó. Ai đọc được `terraform.tfstate` cũng lấy được key đó. Ở đây không có dòng plan nào cho `client_key` được in ra, nên script không cho thấy plan có che nó hay không. Dù thế nào, state vẫn giữ nó.

Sau đó `perl` cắt `main.tf` từ comment `plan-and-apply` tới cuối file, tức là bỏ khối `resource`. Plan trả lời ý thứ hai của người đồng nghiệp: `will be destroyed`, `because kind_cluster.this is not in configuration`.

```bash file=scripts/devops/tofu-state.sh tag=stage-3 lines=30-45
# lesson: devops.l3.tofu-state
# Without its state OpenTofu knows of no cluster: it plans to create one,
# and creating it fails, because a cluster with that name already runs.
echo "== terraform.tfstate moved away"
mv terraform.tfstate state.saved
trap 'mv state.saved terraform.tfstate' EXIT
tofu plan -out=stale.tfplan -no-color | grep -e '^  # ' -e '^Plan:'
tofu apply -auto-approve -no-color 2>&1 | grep -e '^Error' || true
mv state.saved terraform.tfstate
trap - EXIT
echo

# The plan saved without the state no longer fits the state now in place.
echo "== the state is back; apply the plan saved without it"
show tofu apply -no-color stale.tfplan || echo "(exit $?)"
rm -f stale.tfplan
```

```text output=true
...
== terraform.tfstate moved away
  # kind_cluster.this will be created
Plan: 1 to add, 0 to change, 0 to destroy.
Error: node(s) already exist for a cluster with the name "donhang-iac"

== the state is back; apply the plan saved without it
$ tofu apply -no-color stale.tfplan

Error: Saved plan is stale

The given plan file can no longer be applied because the state was changed by
another operation after the plan was created.
(exit 1)
```

Khi state bị chuyển đi, plan muốn tạo `kind_cluster.this`, dù `donhang-iac` đang chạy. `-auto-approve` khiến `tofu apply` làm luôn mà không hỏi `yes`, còn `2>&1` đưa thông báo lỗi của nó vào `grep`, nên dòng `Error` hiện ra. Lần tạo thất bại vì kind không cho tạo cluster thứ hai trùng tên. Khi state đã về chỗ cũ, `tofu apply` từ chối plan được lưu lúc không có state: `Saved plan is stale`.

`.gitignore` của Đơn Hàng liệt kê `*.tfstate` và `*.tfstate.*`, kèm comment ghi rằng file state chứa thông tin đăng nhập ở dạng chữ rõ. State không được vào Git: ai đọc được repository cũng dùng được các thông tin đăng nhập trong đó.

## Senior hay nhầm rằng…

- **"File state chỉ là cache. Xóa nó đi thì OpenTofu sẽ tự tìm lại resource của mình."** → Thực ra state là mối nối duy nhất giữa `kind_cluster.this` và `donhang-iac`. OpenTofu không tìm object đang có theo tên, nên không có state thì nó lên plan tạo lại mọi thứ. Bạn sẽ nhận ra khi plan ghi `will be created` cho một cluster mà `kind get clusters` đã liệt kê sẵn, và apply thất bại với `node(s) already exist`.
- **"Đánh dấu một giá trị là sensitive thì nó không vào file state."** → Thực ra `sensitive` chỉ đổi những gì plan và apply in ra, state vẫn ghi giá trị đó. State của `first-cluster`, state duy nhất bài này mở ra, cho thấy nó ở dạng rõ. Bạn sẽ nhận ra khi một giá trị bạn đánh dấu `sensitive` hiện `(sensitive value)` trong plan, vậy mà `grep` vẫn tìm thấy giá trị đó trong file state.
- **"Bỏ một khối khỏi file chỉ khiến OpenTofu thôi quản lý object đó, còn object thì vẫn ở lại."** → Thực ra địa chỉ vẫn nằm trong state, nên plan kế tiếp sẽ xóa object, và `tofu apply` sau đó xóa thật. Bỏ khối không phải cách để giữ object chạy tiếp, bài này chỉ cho thấy điều không nên làm. Khi bạn muốn giữ một object, hãy tìm `will be destroyed` trong plan trước khi gõ `yes`. Bạn sẽ nhận ra khi plan của một commit dọn dẹp kết thúc bằng `1 to destroy`.

## Thử ngay (3 phút)

`donhang-iac` phải đang tồn tại: nếu `kind get clusters` không liệt kê nó, hãy chạy `scripts/devops/tofu-first-cluster.sh` trước.

1. Chạy `scripts/devops/tofu-state.sh` từ thư mục gốc của repository. Script tự chuyển vào `first-cluster`.
2. Chạy `git check-ignore -v deploy/tofu/lessons/first-cluster/terraform.tfstate` từ thư mục gốc của repository.
3. Chạy `kind get clusters`.

Kết quả mong đợi: script in các dòng như phía trên và kết thúc bằng `(exit 1)`. `git check-ignore -v` in `.gitignore:27:*.tfstate` rồi tới đường dẫn của file: dòng 27 của `.gitignore` là pattern giữ state ngoài Git. `kind get clusters` vẫn liệt kê `donhang-iac`, vì lần xóa chỉ nằm trong plan, lần tạo thất bại, còn plan cũ bị từ chối.

## Liên hệ

- [[k8s.l1.manifests-and-kubectl-apply]] — cách khai báo object theo hướng ngược lại: `kubectl apply`, theo cách Đơn Hàng dùng (không có `--prune`), không ghi lại những gì nó đã tạo, nên xóa manifest không xóa gì cả. Còn bỏ một khối khỏi `main.tf` thì plan sẽ xóa.
- [[k8s.l1.secrets]] — cùng điểm yếu ở tầng dưới: Secret đọc được bởi bất kỳ ai có quyền đọc nó, còn state đọc được bởi bất kỳ ai đọc được file.
- [[devops.l3.remote-state-and-locking]] — vấn đề bài này để ngỏ: state nằm trên một laptop thì không dùng chung được, và bài đó cho thấy Đơn Hàng giữ state của các môi trường ở đâu.
- [[devops.l3.tofu-modules]] — bài tiếp theo, nơi địa chỉ của một resource thay đổi và state phải đi theo.

## Tóm tắt 5 dòng

1. File state là bản ghi duy nhất của OpenTofu cho biết mỗi địa chỉ resource, như `kind_cluster.this`, ứng với object thật nào.
2. Plan đề xuất xóa các địa chỉ chỉ có trong state và tạo các địa chỉ chỉ có trong file.
3. Không có state, OpenTofu lên plan tạo lại mọi thứ. Nó không bao giờ tìm object đang có theo tên.
4. State của `first-cluster` giữ attribute ở dạng chữ rõ, kể cả `client_key`, nên `.gitignore` giữ `*.tfstate` ngoài Git.
5. `tofu apply` từ chối một plan đã lưu khi state đã đổi kể từ lúc lập plan đó.
