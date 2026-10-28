---
id: k8s.l4.node-autoscaling
lang: vi
track: k8s
level: 4
stage: 4
module: managed-vs-selfhosted
main_path: true
title: "Pod thêm cần chỗ: thêm node là việc của một autoscaler khác"
duration_min: 14
skills: [k8s.scaling.autoscaling]
prereqs: [k8s.l4.horizontal-pod-autoscaler, k8s.l4.managed-control-plane, backend.l4.capacity-planning, k8s.l3.draining-nodes]
related: [k8s.l1.requests-and-limits, k8s.l3.clusters-without-a-cloud, k8s.l4.sharing-a-cluster]
vocab: [cluster-autoscaler]
example_tag: stage-4
versions_used: [kubernetes, kind, postgresql]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-10-28T21:29:36+07:00"
---

## Bạn cần biết trước

- [[k8s.l4.horizontal-pod-autoscaler]] — bạn biết HPA đặt số replica của một Deployment trong khoảng `minReplicas` tới `maxReplicas`.
- [[k8s.l4.managed-control-plane]] — bạn biết worker node của cluster managed đến từ các node pool, tạo ra từ cùng một mẫu.
- [[backend.l4.capacity-planning]] — bạn biết kế hoạch dung lượng giữ khoảng dư dưới các giới hạn đã đo, trong đó có `max_connections` của PostgreSQL.
- [[k8s.l3.draining-nodes]] — bạn biết drain một node sẽ evict các Pod trên đó, để controller của chúng tạo lại chúng trên node khác.

## Tình huống

Kế hoạch dung lượng dự tính một đợt cao điểm buổi tối, và HPA ở bài trước sẽ tăng số replica khi CPU lên cao. Bạn diễn tập đợt cao điểm đó trên `donhang` với `cpu-echo`: giờ mỗi Pod xin gần hết CPU của một worker, và bạn bảo HPA giữ ít nhất 4 replica. `kubectl get hpa` hiện 4 replica, đúng như yêu cầu. Thế nhưng `kubectl get deployment` lại hiện `2/4` sẵn sàng, và hai Pod nằm ở `Pending`, không có node nào. HPA đã làm xong phần mình, vậy mà hai Pod vẫn không chạy. Thứ gì cho Pod một chỗ trên node, và ai thêm node khi không còn node nào có chỗ?

## Khái niệm cốt lõi

- Phần dung lượng chưa bị xin (không phải term mới) — phần node có thể cấp cho Pod, trừ đi request của các Pod đã đặt lên đó. kube-scheduler chỉ đặt Pod vào node mà phần này đủ cho request của Pod.
- Pod `Pending` (không phải term mới) — Pod mà API server đã nhận nhưng container chưa chạy. Pod nào kube-scheduler chưa đặt lên node nào thì nằm ở phase này và chờ.
- Event (không phải term mới) — một bản ghi ngắn mà cluster giữ về một object như Pod. kube-scheduler ghi event `FailedScheduling` khi không đặt được một Pod, và kubectl có thể hiện nó ra.
- **cluster autoscaler** (Thành phần thêm node vào node pool khi Pod không có chỗ, bớt node khi Pod trên đó dời được đi) — thành phần thêm một node vào node pool khi có Pod không xếp được vì thiếu tài nguyên, và bỏ một node khi mọi Pod trên đó đều chạy được trên các node còn lại.
- Thời gian khởi động node (không phải term mới) — khoảng thời gian từ lúc yêu cầu một node mới tới lúc node đó vào cluster, sẵn sàng nhận Pod. Nhà cung cấp phải tạo máy trước, thường là máy ảo, rồi máy đó phải khởi động và đăng ký, nên mất lâu hơn nhiều so với đặt Pod lên một node đang còn chỗ.

## Cơ chế hoạt động

```mermaid
flowchart LR
  H[HPA] -->|replica count| D[Deployment]
  D -->|new Pods (via ReplicaSet)| S[kube-scheduler]
  S -->|requests fit| N[Node with room]
  S -->|nothing fits| P[Pending Pod]
  P -->|noticed by| C[cluster autoscaler]
  C -->|add nodes| G[node pool]
  G -.->|node starts and joins| S
```

Trong tình huống trên, HPA đã làm đúng những gì nó vẫn làm: ghi số 4 vào số replica của Deployment. ReplicaSet tạo các Pod, và mỗi Pod mới được chuyển tới kube-scheduler. kube-scheduler so request của Pod với phần dung lượng chưa bị xin của từng node, và chỉ đặt Pod ở nơi vừa. Trên `donhang`, mỗi worker chỉ còn chỗ cho một Pod `cpu-echo`, nên hai Pod chạy, hai Pod nằm lại ở `Pending`, kèm một event `FailedScheduling` giải thích lý do.

Đó là chỗ cluster autoscaler vào việc, trên cluster có node đến từ node pool. Nó tìm các Pod không xếp được vì thiếu tài nguyên. Khi node tạo từ mẫu của một pool chứa vừa các Pod đó, nó bảo nhà cung cấp thêm đủ số node mà các Pod đang chờ cần, nếu mức tối đa cấu hình cho pool còn cho phép. Mỗi node phải khởi động và vào cluster, rồi kube-scheduler mới đặt các Pod đang chờ lên đó. Trước lúc ấy, chúng vẫn ở `Pending`, và các Pod đang chạy gánh tải.

Thứ khiến nó thêm node ở đây là một Pod có request không vừa chỗ nào, không bao giờ là mức dùng CPU. Một cluster có các node chạy nóng, nhưng mọi Pod đều đã có chỗ, sẽ không được thêm node nào.

Nó cũng làm theo chiều ngược lại. Khi các Pod trên một node xin ít và đều chạy được trên các node khác, autoscaler evict chúng, giống như drain, để controller của chúng tạo lại chúng trên các node khác, rồi bỏ node đó đi.

`donhang` không có node pool và không có cluster autoscaler: kind chạy mỗi node dưới dạng một Docker container, tạo cùng lúc với cluster từ `deploy/k8s/kind-config.yaml` (một control plane, hai worker), và sau đó không gì thêm node vào. Hai Pod nằm ở `Pending` cho tới khi script trả mọi thứ về như cũ.

## Trong hệ thống Đơn Hàng

Trước tiên, `node-capacity.sh` đặt CPU request của mỗi Pod `cpu-echo` bằng 60% phần một worker có thể cấp, để mỗi worker chứa đúng một Pod, dù máy bạn có bao nhiêu CPU. Sau đó nó nâng mức sàn của HPA:

```bash file=scripts/k8s/node-capacity.sh tag=stage-4 lines=40-62
# lesson: k8s.l4.node-autoscaling
# The HPA must keep at least 4 replicas: it sets the count, the scheduler
# finds room for two Pods, one per worker; the other two stay Pending.
echo "\$ kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{\"spec\":{\"minReplicas\":4}}'"
kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{"spec":{"minReplicas":4}}'
for _ in $(seq 90); do
  [ "$(kubectl get hpa cpu-echo -n autoscale-lessons -o jsonpath='{.status.currentReplicas}')" = 4 ] && break
  sleep 2
done
for _ in $(seq 90); do
  pending=$(kubectl get pods -n autoscale-lessons -l app=cpu-echo --field-selector status.phase=Pending \
    -o name | wc -l)
  running=$(kubectl get pods -n autoscale-lessons -l app=cpu-echo --field-selector status.phase=Running \
    -o name | wc -l)
  [ "$pending" -eq 2 ] && [ "$running" -eq 2 ] && break
  sleep 2
done
show kubectl get hpa cpu-echo -n autoscale-lessons
show kubectl get deployment cpu-echo -n autoscale-lessons
echo "\$ kubectl get pods -n autoscale-lessons -l app=cpu-echo (how many in each phase)"
kubectl get pods -n autoscale-lessons -l app=cpu-echo -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' \
  | sort | uniq -c | awk '{ print $2 ": " $1 }'
echo
```

```text output=true
...
$ kubectl patch hpa cpu-echo -n autoscale-lessons --type=merge -p '{"spec":{"minReplicas":4}}'
horizontalpodautoscaler.autoscaling/cpu-echo patched
$ kubectl get hpa cpu-echo -n autoscale-lessons
NAME       REFERENCE             TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
cpu-echo   Deployment/cpu-echo   cpu: <unknown>/50%   4         5         4          ...
$ kubectl get deployment cpu-echo -n autoscale-lessons
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
cpu-echo   2/4     4            2           ...
$ kubectl get pods -n autoscale-lessons -l app=cpu-echo (how many in each phase)
Pending: 2
Running: 2

== FailedScheduling of a Pending cpu-echo Pod
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. no new claims to deallocate, preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
...
```

Hai vòng lặp chỉ chờ tới khi HPA báo 4 và có hai Pod ở `Pending`. Lệnh cuối đếm số Pod theo từng phase. `show` là helper trong `scripts/lib/network-lessons.sh`, in ra một lệnh rồi chạy nó. HPA hiện `REPLICAS 4` trong khi mục tiêu vẫn là `<unknown>`: chỉ riêng mức sàn mới đã đặt ra con số này. Deployment muốn 4 Pod và có 2 Pod sẵn sàng.

Dòng `FailedScheduling` đến từ phần tiếp theo của script, ngoài đoạn trích này. Nó đếm ba node của `donhang`: `2 Insufficient cpu` là hai worker, mỗi worker đã giữ request của một Pod, còn node kia là node control plane, được kind đánh dấu để Pod thông thường không lên đó. Dấu đó chính là thứ `1 node(s) had untolerated taint(s)` báo. Phần còn lại của dòng nói về các tính năng của scheduler mà bài này để sang một bên, như mức ưu tiên của Pod. Bạn có thể bỏ qua.

Thứ vẫn giới hạn `maxReplicas` khi số node tăng được nằm trong kế hoạch dung lượng:

```markdown file=docs/design/capacity-plan.md tag=stage-4 lines=44-54
- Kết nối database: mỗi Pod api giữ một pool kết nối của Npgsql cho
  `ConnectionStrings:Default`, kích thước mặc định vì connection string không
  đặt. Payments, Notifications, các migration và job backup mở kết nối tới
  cùng server. Tổng số Pod × kết nối tối đa mỗi Pod của mọi service phải nhỏ
  hơn `max_connections` của PostgreSQL; đọc giá trị đó bằng
  `SHOW max_connections`, không đoán.

### Khoảng dư

Quy tắc: tải đỉnh không vượt một nửa trần của 2 Pod api, để một Pod gánh được
toàn bộ khi mất Pod kia (node hỏng, rolling update).
```

Mục đầu tiên nói mỗi Pod `api` giữ pool kết nối database riêng: các kết nối đang mở mà process giữ lại và dùng lại, tới một kích thước tối đa, nên một Pod giữ nhiều kết nối cùng lúc. Các service khác cũng mở kết nối tới cùng server. Số Pod nhân với số kết nối mỗi Pod, cộng trên mọi service, phải nhỏ hơn `max_connections` của PostgreSQL. Cluster autoscaler thêm node, không thêm kết nối database, nên giới hạn này vẫn đứng nguyên dù có bao nhiêu node. Quy tắc khoảng dư giữ tải đỉnh dưới một nửa mức 2 Pod `api` phục vụ được. Phần dư đó cũng gánh đoạn đầu của đợt cao điểm trong lúc node mới khởi động.

## Đánh đổi

| | Mua sẵn node cho đợt cao điểm dự tính | Cluster autoscaler trên một node pool |
|---|---|---|
| Ai thêm node | Đội, trước đợt cao điểm | Autoscaler, khi có Pod không xếp được |
| Trả tiền cho gì | Số node của lúc cao điểm, cả ngày | Số node cho các request đang được đặt lúc này |
| Đoạn đầu của một đợt cao điểm bất ngờ | Chỗ đã có sẵn | Pod mới chờ ở `Pending` trong lúc node khởi động |
| Thứ giới hạn `maxReplicas` | Sức chứa của số node đã mua, và tài nguyên dùng chung | Tài nguyên dùng chung như `max_connections` |
| Dùng được ở đâu | Ở bất kỳ đâu, kể cả máy của chính đội | Nơi nhà cung cấp tạo node theo yêu cầu |

## Bạn sẽ chọn gì nếu…

- …Đơn Hàng chuyển sang máy do đội tự vận hành: mua node cho đợt cao điểm dự tính cộng khoảng dư, và giữ `maxReplicas` trong mức các node đó chứa được theo request, vì không có gì tạo node theo nhu cầu, và Pod vượt mức đó chỉ nằm chờ ở `Pending`.
- …production chạy trên cluster managed và đợt cao điểm buổi tối dâng lên trong một giờ: HPA cho `api` cộng cluster autoscaler trên node pool của nó, với khoảng dư trong kế hoạch gánh tải trong lúc từng node khởi động.
- …một chương trình khuyến mãi đẩy tới một đợt cao điểm dựng đứng vào một phút biết trước: riêng cặp này phản ứng quá muộn, vì node chỉ nhận Pod sau khi máy của nó đã được tạo và khởi động xong. Hãy nâng `minReplicas` bằng một commit trước phút đó, để các node kịp vào cluster, rồi hạ xuống sau đó.

## Senior hay nhầm rằng…

- **"HPA thêm node khi cluster hết chỗ."** → Thực ra HPA chỉ ghi số replica. kube-scheduler đặt Pod, còn cluster autoscaler, nếu có chạy, mới thêm node. Bạn sẽ nhận ra khi `kubectl get hpa` hiện đúng con số bạn mong đợi, trong khi số Pod sẵn sàng của Deployment vẫn thấp hơn và có Pod nằm ở `Pending`.
- **"Cluster autoscaler thêm node ngay khi mức dùng CPU lên cao."** → Thực ra nó phản ứng với Pod không xếp được vì thiếu tài nguyên, tính theo request. Bạn sẽ nhận ra khi các node chạy nóng suốt một giờ mà số node không nhúc nhích, vì Pod nào cũng đã có chỗ.
- **"Đã bật autoscaling thì không cần kế hoạch dung lượng nữa."** → Thực ra cả hai autoscaler đều làm việc trong các giới hạn do kế hoạch đặt ra: node mới cần thời gian để vào cluster, và `max_connections` của PostgreSQL không tăng theo số node. Bạn sẽ nhận ra khi mấy phút đầu của đợt cao điểm có lỗi trong lúc node khởi động, hoặc các Pod `api` thêm vào không lấy được kết nối database.

## Thử ngay (3 phút)

Từ thư mục gốc của repo Đơn Hàng, với Docker Desktop đang chạy, và đã cài `kubectl` cùng kind:

1. Chạy `scripts/k8s/node-capacity.sh`. Script tạo `donhang` nếu chưa có, việc này mất lâu hơn bài tập này. Nếu script dừng vì một worker còn chưa tới 60% CPU chưa bị xin, nó sẽ nói cách sửa: xóa các namespace mà những bài trước để lại, rồi chạy lại.
2. Tìm `REPLICAS` của HPA, `READY` của Deployment và dòng `FailedScheduling`.
3. Giả sử cũng các Pod đó chạy trên một cluster managed, có cluster autoscaler trên node pool của các worker, mỗi node cỡ bằng một worker của `donhang`. Hai Pod `Pending` sẽ ra sao, và điều gì vẫn ngăn bạn đặt `maxReplicas` là 50 cho `api`?

Kết quả mong đợi: HPA ở 4 replica, Deployment ở `2/4`, `Pending: 2` và `Running: 2`, cùng một event có `2 Insufficient cpu`. Cuối cùng script trả lại request và `minReplicas` như cũ, rồi xóa `autoscale-lessons`.

<details><summary>Gợi ý đáp án</summary>

Autoscaler thấy hai Pod không vừa node nào. Một node tạo từ mẫu chứa được một Pod như vậy, và autoscaler xin đủ số node mà các Pod đang chờ cần. Vì thế, nếu mức tối đa cấu hình cho pool còn cho phép, nó bảo nhà cung cấp thêm hai node. Khi chúng khởi động và vào cluster, kube-scheduler đặt các Pod lên. Trước lúc đó, các Pod vẫn ở `Pending`. Còn với 50 Pod `api`, mỗi Pod sẽ giữ pool kết nối database riêng, và cộng với các service khác, tổng phải nhỏ hơn `max_connections`, con số mà thêm node nào cũng không nâng lên được.

</details>

## Liên hệ

- [[k8s.l4.horizontal-pod-autoscaler]] — autoscaler ở bước trước: nó đặt số Pod, rồi các Pod đó cần node.
- [[k8s.l1.requests-and-limits]] — request mà cả kube-scheduler lẫn cluster autoscaler đều đếm, không bao giờ là mức dùng.
- [[k8s.l4.managed-control-plane]] — nơi node pool ra đời. Cluster autoscaler làm chúng lớn lên và thu nhỏ lại.
- [[backend.l4.capacity-planning]] — kế hoạch có khoảng dư và giới hạn kết nối vẫn chặn `maxReplicas`.
- [[k8s.l3.draining-nodes]] — bỏ một node nghĩa là làm trống nó trước, giống như drain.
- [[k8s.l3.clusters-without-a-cloud]] — trên máy của chính đội, không có gì tạo node theo nhu cầu.
- [[k8s.l4.sharing-a-cluster]] — quota của namespace có thể từ chối Pod mới trước khi node nào thiếu chỗ.
- [[k8s.l4.requests-drive-cluster-cost]] — tiếp theo: node đi theo request, nên chi phí cũng vậy.

## Tóm tắt 5 dòng

1. HPA chỉ đặt số Pod chạy. Mỗi Pod thêm vẫn cần một node có phần dung lượng chưa bị xin đủ cho request của nó, nếu không thì nằm ở `Pending`.
2. kube-scheduler đặt Pod theo request, không theo mức dùng. Khi không node nào còn chỗ, nó ghi một event `FailedScheduling`.
3. Cluster autoscaler thêm node vào node pool khi có Pod không xếp được, và bỏ những node có Pod chạy được ở nơi khác.
4. Node mới phải khởi động và vào cluster trước, nên khoảng dư vẫn gánh đoạn đầu của đợt cao điểm. Với máy của chính đội, node được mua sẵn.
5. `maxReplicas` vẫn bị giới hạn bởi tài nguyên dùng chung như `max_connections` của PostgreSQL, dù có bao nhiêu node.
