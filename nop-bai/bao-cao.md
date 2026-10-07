| | |
|---|---|
| Họ và tên | Vũ Minh Diểm |
| MSSV | 202602858 |
| Lớp / Khóa | K4 |
| Repo GitHub | https://github.com/diemvu12369/K4-L3-Day21-VuMinhDiem-2A202602858-CI-CD-for-AI-Systems |
| Ngày nộp | 2026-10-07 |

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
| MLflow không chạy | Dependency mlflow/SQLAlchemy/alembic chưa tương thích | Cài đúng phiên bản trước khi track |
| Nhầm lẫn accuracy với F1 | Dữ liệu mất cân bằng | Chọn f1_score của lớp dương làm mục tiêu |
| Kiểm tra sau thêm dữ liệu | Dữ liệu đổi batch liên tục | Chạy lại train và so sánh metric |

---

## 4. So Sánh Bước 2 và Bước 3 (bắt buộc, 2 - 3 câu)

| | f1_score | accuracy |
|---|---|---|
| Bước 2 (chỉ `train_batch1`) | 0.7149 | 0.8740 |
| Bước 3 (thêm `train_batch2`) | 0.7354 | 0.8820 |

**Nhận xét:** Sau khi bổ sung dữ liệu mới, f1_score tăng từ 0.7149 lên 0.7354, và accuracy tăng từ 0.8740 lên 0.8820. Kết quả này hợp lý vì dữ liệu mới cùng phân phối với dữ liệu cũ, nên mô hình cải thiện nhẹ nhưng rõ ràng, không cần đưa ra kết luận sai rằng “thêm dữ liệu luôn tốt hơn”.

---

## 5. Phần Bonus Đã Thực Hiện (nếu có)

- [ ] Bonus 1 - Tracking MLflow từ xa với DagsHub: chưa thực hiện
- [ ] Bonus 2 - Điều chỉnh ngưỡng quyết định: chưa thực hiện
- [ ] Bonus 3 - Báo cáo precision / recall tự động: chưa thực hiện
- [ ] Bonus 4 - Hoàn trả về phiên bản trước: chưa thực hiện
- [ ] Bonus 5 - Cảnh báo lệch lạc dữ liệu: chưa thực hiện
