/// Whole calendar days from [from] to [to], by their dates only.
///
/// `DateTime.difference(...).inDays` on local times is wrong across a
/// daylight-saving change: the spring-forward day is 23 hours long, so
/// «yesterday → today» came out as 0 days (Egypt and others switch at
/// midnight). Comparing the dates as UTC has no such gaps.
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The date [days] calendar days after [d] (midnight, local) — never lands
/// on the same date twice or skips one across a DST change, as adding
/// `Duration(days: 1)` to a local midnight can.
DateTime addCalendarDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
