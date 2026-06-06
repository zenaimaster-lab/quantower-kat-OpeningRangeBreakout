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

        public void UpdateTargetTime(int nyHour, int nyMin, int nySec, int utcOffset, int sessionDurationMinutes)
        {
            DateTime utcNow = Core.Instance.TimeUtils.DateTimeUtcNow;
            DateTime nyNow = utcNow.AddHours(utcOffset);

            // Check if we are past market close (e.g. 16:00 NY time) to transition target session to tomorrow
            DateTime shiftTime = nyNow.Date.AddHours(16);
            DateTime activeSessionDate = nyNow >= shiftTime ? nyNow.Date.AddDays(1) : nyNow.Date;

            // Target NY open time for the active session date
            DateTime targetNyOpenLocal = activeSessionDate.AddHours(nyHour).AddMinutes(nyMin).AddSeconds(nySec);
            
            // Convert NY time to UTC: UTC = NY - offset
            DateTime targetUtc = targetNyOpenLocal.AddHours(-utcOffset);

            // Convert to platform Selected TimeZone
            DateTime convertedTime = Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(targetUtc);
            targetTimeServer = new DateTime(convertedTime.Year, convertedTime.Month, convertedTime.Day, convertedTime.Hour, convertedTime.Minute, 0, DateTimeKind.Unspecified);
            lastCalculatedDay = activeSessionDate.Day;
        }
    }
}
