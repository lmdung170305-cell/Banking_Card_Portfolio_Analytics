# Xóm Bank: Phân tích danh mục thẻ (SQL Server + Power BI)


Dự án phân tích dữ liệu thẻ của **Xóm Dataset**,  ngân hàng bán lẻ kết hợp phát hành thẻ tín dụng tại Mỹ, phục vụ hơn 2.000 khách hàng cá nhân với danh mục thẻ đa dạng (Visa, Mastercard, Amex, Discover) ở các loại Credit / Debit / Prepaid. Dự án đi từ dữ liệu thô đến bộ truy vấn nghiệp vụ T-SQL và báo cáo Power BI, phục vụ các nhóm Board, Marketing, Cards/Closure, Risk/Fraud và Geographic.

## Bộ dữ liệu

4 file CSV đã làm sạch, nạp vào SQL Server. Kỳ dữ liệu: 01/01/2022 – 31/10/2024.

| Bảng | Quy mô | Nội dung |
|---|---|---|
| `transactions` | 157,224 dòng | Giao dịch thẻ (số tiền, kênh, merchant, MCC, lỗi) |
| `users` | 2,000 khách | Thu nhập, credit score, nợ, thông tin cá nhân |
| `banking_cards` | 6,146 thẻ | Brand, loại thẻ, hạn mức, ngày mở |
| `codes` | 109 mã | Ánh xạ MCC sang tên ngành merchant |

## Cấu trúc thư mục

```
.
├── Banking.pbip                 # File mở dự án Power BI
├── Banking.Report/              # Định nghĩa báo cáo (6 trang)
├── Banking.SemanticModel/       # Mô hình dữ liệu, quan hệ, measure DAX (TMDL)
├── cleaned_banking_data/        # 4 file CSV đã làm sạch
└── Banking sql.md               # 15 câu truy vấn nghiệp vụ Q1–Q15
```

## Truy vấn SQL (Q1–Q15)

Các câu hỏi nghiệp vụ gồm: tổng giao dịch, top thành phố, phân phối credit score, cơ cấu brand, tỷ lệ lỗi, top khách chi tiêu, ngành chi tiêu lớn nhất, credit utilization, thẻ dormant, tín hiệu gian lận nhiều bang, chi tiêu lũy kế, churn, outlier theo MCC, tương quan credit score – chi tiêu và heatmap bang × ngành.

Một số view được Power BI đọc dưới tên khác:

| Trong file SQL | Trong Power BI |
|---|---|
| `vw_outlier` | `vw_fraud` |
| `vw_heatmap` | `vw_matrix` |
| `vw_multistate`, `vw_churn` | giữ nguyên tên |

## Báo cáo Power BI

| Trang | Nội dung chính |
|---|---|
| Overview | Quy mô giao dịch, top thành phố, loại lỗi, kênh chip/swipe/online |
| Customer & Credit | Phân phối credit score, top khách chi tiêu, tương quan điểm tín dụng – chi tiêu |
| Card Portfolio | Cơ cấu brand, mức sử dụng hạn mức, thẻ dormant |
| Risk Signals & Customer Inactivity | Giao dịch nhiều bang trong 1 ngày, khoảng nghỉ giao dịch, trạng thái churn |
| Merchant & Geography | Ngành chi tiêu lớn nhất, outlier theo MCC, heatmap bang × ngành |
| Customer details | Chi tiêu tháng và lũy kế của từng khách (drill-through) |

## Phát hiện chính

- Chi tiêu hợp lệ ổn định khoảng **$221K/tháng** ở cả ba năm; đường dốc xuống ở năm 2024 là do chỉ có 10 tháng dữ liệu.
- Tỷ lệ lỗi giao dịch **1.74%**, trong đó 64.4% là *Insufficient Balance*, không phải lỗi hệ thống.
- Credit score gần như không liên quan chi tiêu (r = 0.007); thu nhập có liên quan rõ hơn (r = 0.47).
- Outlier 5.00% là hệ quả của ngưỡng P95 theo MCC, không phải tỷ lệ gian lận.
- Hoàn tiền chiếm 11.1% chi tiêu gộp và tập trung ở hai ngành (Miscellaneous Food Stores, Service Stations).

## Lưu ý về dữ liệu

- Chỉ **303/2,000 khách** có giao dịch. Con số 5,250 thẻ dormant (85.42%) gồm 5,006 thẻ của khách không có dữ liệu giao dịch và chỉ 244 thẻ của khách đang hoạt động. Cần xác nhận phạm vi dữ liệu trước khi đóng thẻ.
- Chi tiêu (`Total Spend`) là số **gộp**: chỉ tính `amount > 0` và giao dịch không lỗi, chưa trừ hoàn tiền.
- Cột `expires` không đáng tin để suy luận thẻ dormant.

## Cách chạy

1. Tạo database SQL Server và nạp 4 file trong `cleaned_banking_data/` thành các bảng `transactions`, `users`, `banking_cards`, `codes`.
2. Chạy các truy vấn trong `Banking sql.md` (bao gồm việc tạo các view).
3. Mở `Banking.pbip` bằng Power BI Desktop (bật tính năng Power BI Project).
4. Mô hình đang trỏ tới máy chủ `DESKTOP-1KB4ADE\SQLEXPRESS02`. Đổi sang máy chủ của bạn trong Transform data, rồi Refresh.

## Bảo mật

Bảng `banking_cards` có chứa `card_number` và `cvv` ở dạng rõ. Đây là dữ liệu mô phỏng, nhưng nên che hoặc xóa hai cột này trước khi chia sẻ rộng rãi.

## Công nghệ

T-SQL (SQL Server) · Power BI (PBIP/TMDL, DAX)
