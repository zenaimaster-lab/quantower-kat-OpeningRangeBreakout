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

            // Compute NY Open time on today's NY date
            DateTime nyOpenLocal = nyNow.Date.AddHours(nyHour).AddMinutes(nyMin).AddSeconds(nySec);
            
            // Check if we are past the end of the session for today's NY date
            DateTime nySessionEndLocal = nyOpenLocal.AddMinutes(sessionDurationMinutes);
            DateTime activeSessionDate = nyNow >= nySessionEndLocal ? nyNow.Date.AddDays(1) : nyNow.Date;

            // Target NY open time for the active session date
            DateTime targetNyOpenLocal = activeSessionDate.AddHours(nyHour).AddMinutes(nyMin).AddSeconds(nySec);
            
            // Convert NY time to UTC: UTC = NY - offset
            DateTime targetUtc = targetNyOpenLocal.AddHours(-utcOffset);

            // Convert to platform Selected TimeZone
            targetTimeServer = Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(targetUtc);
            lastCalculatedDay = activeSessionDate.Day;
        }
    }
}
