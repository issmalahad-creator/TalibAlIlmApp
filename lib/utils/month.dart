import 'hijri_date.dart';

/// The app uses the Hijri calendar as its primary calendar (per Ismail's
/// requirement) — "month" everywhere in this app means Hijri month.

String currentMonth() => currentHijriMonthKey();

String todayDate() => hijriDateStringForDate(DateTime.now());

String monthLabel(String monthKey) => hijriMonthLabel(monthKey);
