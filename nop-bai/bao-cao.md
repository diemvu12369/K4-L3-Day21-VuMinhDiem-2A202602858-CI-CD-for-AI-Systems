# Báo Cáo Lab Day 21 - CI/CD cho AI Systems

| | |
|---|---|
| Họ và tên | Vũ Minh Điềm |
| MSSV | 202602858 |
| Lớp / Khóa | K4 |
| Repo GitHub | https://github.com/diemvu12369/K4-L3-Day21-VuMinhDiem-2A202602858-CI-CD-for-AI-Systems |
| Ngày nộp | 2026-10-08 |

---

## 1. Bộ Siêu Tham Số Đã Chọn và Lý Do

| Lần chạy | n_estimators | learning_rate | max_depth | f1_score | accuracy |
|---|---|---|---|---|---|
| 1 | 50 | 0.05 | 2 | 0.6051 | 0.8460 |
| 2 | 100 | 0.1 | 3 | 0.7109 | 0.8780 |
| 3 | 200 | 0.1 | 5 | 0.7149 | 0.8740 |

**Bộ siêu tham số đã chọn:** `n_estimators=200`, `learning_rate=0.1`, `max_depth=5`.

**Lý do:** Bộ này đạt f1_score cao nhất. Accuracy cao nhất không trùng với f1 cao nhất, nên accuracy không phản ánh đúng chất lượng trên dữ liệu mất cân bằng. Tăng n_estimators từ 100 lên 200 giúp f1_score tăng nhẹ, cho thấy đánh đổi giữa số cây và tốc độ học.

---

## 2. Vì Sao Ngưỡng Chất Lượng Đặt Trên F1 Chứ Không Phải Accuracy

Dữ liệu Adult có khoảng 24,8% mẫu thuộc lớp thu nhập cao. Một mô hình luôn dự đoán “thu nhập thấp” vẫn đạt accuracy gần 0.75, nhưng nó không phát hiện được lớp dương. F1 của lớp dương kết hợp precision và recall, nên đo chính xác khả năng nhắm đúng và không bỏ sót trường hợp thu nhập > 50K. Accuracy bị lớp đa số kéo lên và mất ý nghĩa. Vì thế, tôi không dùng `average="weighted"` hoặc `average="macro"` khi gọi `f1_score`, vì cách đó làm lớp đa số che lấp lớp dương.

---

## 3. Khó Khăn Gặp Phải và Cách Giải Quyết

| Khó khăn | Nguyên nhân | Cách giải quyết |
|---|---|---|
| `gcloud iam service-accounts keys create` bị từ chối | Organization bật sẵn chính sách `iam.disableServiceAccountKeyCreation` | Tắt ràng buộc này riêng cho project lab bằng `org-policies disable-enforce`, rồi tạo lại key |
| `train_batch1.csv` ở máy đã bị ghép sẵn batch2 trước Bước 2 | Đã chạy thử `append_batch.py` từ sớm | Chạy lại `prepare_data.py` (random_state=42) để có lại 22.361 mẫu gốc trước khi `dvc add` |
| `dvc pull` trên CI có nguy cơ lỗi vì không có file `sa-key.json` | `credentialpath` nằm trong `.dvc/config` được commit | Đặt `credentialpath` trong `.dvc/config.local`, CI xác thực qua `GOOGLE_APPLICATION_CREDENTIALS` |

---

## 4. So Sánh Bước 2 và Bước 3 (bắt buộc, 2 - 3 câu)

| | f1_score | accuracy |
|---|---|---|
| Bước 2 (chỉ `train_batch1`) | 0.7149 | 0.8740 |
| Bước 3 (thêm `train_batch2`) | 0.7354 | 0.8820 |

**Nhận xét:** Khi bổ sung 22.361 mẫu mới, f1_score tăng 0,0205 (0,7149 → 0,7354) và accuracy tăng 0,008 (0,8740 → 0,8820), cả hai lần đều qua quality gate và được triển khai tự động. Mức tăng nhỏ vì batch2 được chia ngẫu nhiên từ cùng phân phối, nên nhiều khả năng chỉ giúp mô hình `max_depth=5` ước lượng ổn định hơn chứ không mang thông tin mới; holdout chỉ 500 mẫu nên chênh lệch này cũng nằm gần mức dao động, không đủ để kết luận thêm dữ liệu luôn tốt hơn.

