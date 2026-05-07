# Phiên làm việc: Tối giản NewsManager thành SessionManager
**Thời gian:** 2026-05-07
**Mục tiêu:** Loại bỏ tính năng bắt Red News từ bộ lịch kinh tế (Economic Calendar). Thay thế hoàn toàn bằng việc hiển thị "Next session: NY Open". Đảm bảo quy trình Auto-Run chỉ tập trung vào NY Open.

### 1. Các thay đổi chính:
* **Tự động Version Bump:**
  * Cập nhật `EA_VERSION` thành `0.02` (tăng 0.01 theo workflow) trong `Defines.mqh`.
* **Loại bỏ tính năng News Filter:**
  * Xóa hoàn toàn cấu trúc gọi tin tức từ `CalendarValueHistory` trong `NewsManager.mqh`. Class này hiện đã được viết lại, chỉ đóng vai trò như một **Session Manager**, tính toán và cung cấp mốc thời gian NY Open kế tiếp dựa trên các input `InpNyHour`, `InpNyMinute`, `InpNySecond` và hiển thị chuỗi "NY Open | HH:MM".
  * Xóa hoàn toàn nhóm tham số input `=== NEWS FILTER ===` trong `kat-Orb-Breakout.mq5`.
* **Dọn dẹp Giao diện (Dashboard.mqh):**
  * Sửa nhãn `"Next:"` thành `"Next session:"`.
  * Xóa các nút chọn chế độ tin tức: `m_btnNyoOnly` (NYO ONLY), `m_btnAutoApply` (AUTO APPLY), và `m_btnApplyNext` (APPLY NEXT) vì chúng không còn tác dụng.
  * Xóa các biến boolean `NYOOnlyMode`, `AutoNewsEnabled`, cùng mã xử lý `CMD_APPLY_NEXT` trong hàng đợi lệnh.

### 2. Trạng thái hiện tại:
* EA biên dịch thành công (0 lỗi, 0 cảnh báo).
* Giao diện đã gọn gàng tối đa. Phần "Next session" giờ đây chỉ dự báo thời gian phiên NY Open tiếp theo một cách độc lập và chính xác dựa vào múi giờ (UTC Offset).

### 3. Bước tiếp theo:
* Sẵn sàng chuyển trọng tâm sang logic Breakout và thực thi lệnh OCO theo đúng khung giờ NY Open.
