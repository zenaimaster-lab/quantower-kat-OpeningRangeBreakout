using System;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    //+------------------------------------------------------------------+
    //| TimeManager — handles NY timezone conversion                     |
    //+------------------------------------------------------------------+
    public class TimeManager
    {
        private DateTime targetTimeServer = DateTime.MinValue;
        private int lastCalculatedDay = -1;

        public DateTime GetServerTime()
        {
            // Always return time in platform Selected TimeZone to align perfectly with charts and history bars.
            // Core.Instance.TimeUtils.DateTimeUtcNow is automatically mocked in backtesting.
            return Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(Core.Instance.TimeUtils.DateTimeUtcNow);
        }

        public DateTime GetTargetTime() => targetTimeServer;

        public void UpdateTargetTime(int nyHour, int nyMin, int nySec, int utcOffset)
        {
            DateTime serverNow = GetServerTime();
            if (serverNow.Day == lastCalculatedDay && targetTimeServer > DateTime.MinValue) return;

            // Target NY time in UTC: NY = UTC + offset -> UTC = NY - offset
            // utcOffset is negative for NY (e.g. -4), so subtracting negative adds offset hours
            int utcHour = nyHour - utcOffset;
            int dayAdjust = 0;

            if (utcHour >= 24) { utcHour -= 24; dayAdjust = 1; }
            if (utcHour < 0) { utcHour += 24; dayAdjust = -1; }

            // Tạo targetUtc sử dụng năm/tháng/ngày của serverNow để không bị lệch múi giờ
            DateTime targetUtc = new DateTime(
                serverNow.Year, serverNow.Month, serverNow.Day,
                utcHour, nyMin, nySec, DateTimeKind.Utc
            ).AddDays(dayAdjust);

            // Chuyển đổi trực tiếp thông qua Quantower API mà không cần tự tính offset
            targetTimeServer = Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(targetUtc);
            lastCalculatedDay = serverNow.Day;
        }
    }
}
