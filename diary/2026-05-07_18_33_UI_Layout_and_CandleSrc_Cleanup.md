# Phiên làm việc: Tinh chỉnh Layout và xóa Candle Source
**Thời gian:** 2026-05-07
**Mục tiêu:** Căn chỉnh lại hiển thị chữ "Next session" và xóa hoàn toàn cấu hình Candle Source (Current/Previous).

### 1. Các thay đổi chính:
* **Tự động Version Bump:**
  * Cập nhật `EA_VERSION` thành `0.03` trong `Defines.mqh`.
* **Căn chỉnh UI (Dashboard.mqh):**
  * Đổi chiều dài vùng hiển thị label `"Next session:"` thành `LABEL_WIDTH` thay vì hardcode độ dài 80 (vốn bị cắt xén thành "Next sessio").
  * Đổi tọa độ bắt đầu của text hiển thị "NY Open | ..." từ `cx+84` sang biến chuẩn `rx` và độ rộng `rw`, giúp nó thẳng hàng dọc một cách hoàn hảo với các giá trị khác bên dưới (như M2, SL/TP...).
* **Loại bỏ Candle Source:**
  * Xóa hoàn toàn `m_lblCsTag` và `m_btnCandleSrc` khỏi giao diện, triệt tiêu tùy chọn "CURRENT"/"PREVIOUS".
  * Gỡ bỏ logic cập nhật `UpdCandleSrc`, `OnCandleSrc` trong `Dashboard.mqh`.
  * Xóa bỏ enum `ENUM_CANDLE_SOURCE` và tham số cấu hình `p.candleSource` trong `Defines.mqh` và `kat-Orb-Breakout.mq5` (`InpCandleSrc`).
  * **Core logic:** Cấu hình index `cIdx = 0` (tương đương với CURRENT candle) được đặt cố định (hardcoded) khi vẽ đường SL nến `iHigh()`/`iLow()` trong `OnTimer()` và thiết lập shift=0 trong `OrderManager.mqh` `PlaceOCOOrders()`. 

### 2. Trạng thái hiện tại:
* EA biên dịch thành công (0 lỗi, 0 cảnh báo).
* Giao diện rất gọn gàng và không còn bị lẹm chữ.

### 3. Bước tiếp theo:
* Sẵn sàng tùy biến sâu hơn vào logic giao dịch Breakout.
