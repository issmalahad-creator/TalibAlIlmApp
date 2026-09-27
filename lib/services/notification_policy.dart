import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'quiet_hours_prefs.dart';

/// Reminders the app sends on its own initiative (NOTIFICATIONS_ARCHITECTURE.md
/// §3.1, tier «تشجيع»). Prayer times and anything the student timed
/// themselves (tasks, custom adhkar, khatm goals, life-plan slots) are not
/// here — those are honoured exactly as set.
enum Encouragement { hifz, timeLog, companion, reading }

/// Where [want] may actually fire: out of the quiet window, and on a day
/// that still has room under [cap]. [bookedDays] holds the calendar days
/// (local midnight) other encouragement reminders already occupy — one entry
/// per reminder, so a day can appear twice. [dailyRecurring] is how many
/// repeat-every-day encouragement reminders exist; they occupy every day.
/// Returns null when no day within [horizonDays] has room — the reminder is
/// skipped rather than pushed ever later.
///
/// Pure (no prefs, no clock) so every rule is unit-tested directly.
DateTime? planEncouragement({
  required DateTime want,
  required List<DateTime> bookedDays,
  required int dailyRecurring,
  required int cap,
  required bool quietEnabled,
  required int quietStart,
  required int quietEnd,
  int horizonDays = 7,
}) {
  var at = _outOfQuiet(want, quietEnabled, quietStart, quietEnd);
  for (var i = 0; i < horizonDays; i++) {
    final day = DateTime(at.year, at.month, at.day);
    final used = dailyRecurring + bookedDays.where((d) => d == day).length;
    if (used < cap) return at;
    at = DateTime(at.year, at.month, at.day + 1, at.hour, at.minute);
  }
  return null;
}

DateTime _outOfQuiet(DateTime t, bool enabled, int start, int end) {
  if (!enabled) return t;
  final hour = applyQuietHours(hour: t.hour, quietEnabled: true, quietStart: start, quietEnd: end);
  if (hour == t.hour) return t;
  // Inside the window: fire when it ends — later today, or tomorrow when the
  // window wraps past midnight and we're in its evening part.
  final sameDay = DateTime(t.year, t.month, t.day, end);
  return sameDay.isAfter(t) ? sameDay : DateTime(t.year, t.month, t.day + 1, end);
}

/// The student's encouragement settings + the booking ledger that makes the
/// daily cap work across separate scheduling calls (they happen at different
/// moments — boot, a hifz check-in, opening a book).
class NotificationPolicy {
  NotificationPolicy._();
  static final instance = NotificationPolicy._();

  static const defaultCap = 2;
  static const _capKey = 'notif_encouragement_cap';
  static const _ledgerKey = 'notif_encouragement_ledger';
  static String _enabledKey(Encouragement k) => 'notif_enc_${k.name}_enabled';

  /// Quiet hours always apply to encouragement, using the student's window
  /// (default 22→6) even when the global switch — which also governs their
  /// own timed reminders — is off.
  Future<({int start, int end})> quietWindow() async {
    final q = QuietHoursPrefs();
    return (start: await q.startHour(), end: await q.endHour());
  }

  Future<int> cap() async => (await SharedPreferences.getInstance()).getInt(_capKey) ?? defaultCap;

  Future<void> setCap(int value) async =>
      (await SharedPreferences.getInstance()).setInt(_capKey, value.clamp(1, 4));

  Future<bool> isEnabled(Encouragement kind) async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey(kind)) ?? true;

  Future<void> setEnabled(Encouragement kind, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_enabledKey(kind), value);

  /// Decides when [kind] fires given it wants [want] (null = don't schedule),
  /// and books it. [daily] marks a repeat-every-day reminder. Other kinds'
  /// bookings in the past are dropped; this kind's old booking is replaced.
  Future<DateTime?> place(Encouragement kind, DateTime want, {bool daily = false, DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final ledger = _readLedger(prefs, now ?? DateTime.now())..remove(kind.name);
    if (!await isEnabled(kind)) {
      await _writeLedger(prefs, ledger);
      return null;
    }
    final quiet = await quietWindow();
    final booked = <DateTime>[];
    var recurring = 0;
    for (final v in ledger.values) {
      if (v == 'daily') {
        recurring++;
      } else {
        final t = DateTime.parse(v);
        booked.add(DateTime(t.year, t.month, t.day));
      }
    }
    final at = daily
        ? (recurring < await cap() ? _outOfQuiet(want, true, quiet.start, quiet.end) : null)
        : planEncouragement(
            want: want,
            bookedDays: booked,
            dailyRecurring: recurring,
            cap: await cap(),
            quietEnabled: true,
            quietStart: quiet.start,
            quietEnd: quiet.end,
          );
    if (at != null) ledger[kind.name] = daily ? 'daily' : at.toIso8601String();
    await _writeLedger(prefs, ledger);
    return at;
  }

  /// Forget [kind]'s booking (its reminder was cancelled).
  Future<void> release(Encouragement kind) async {
    final prefs = await SharedPreferences.getInstance();
    final ledger = _readLedger(prefs, DateTime.now())..remove(kind.name);
    await _writeLedger(prefs, ledger);
  }

  Map<String, String> _readLedger(SharedPreferences prefs, DateTime now) {
    try {
      final raw = prefs.getString(_ledgerKey);
      if (raw == null) return {};
      final map = Map<String, String>.from(jsonDecode(raw) as Map);
      map.removeWhere((_, v) => v != 'daily' && DateTime.parse(v).isBefore(now));
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeLedger(SharedPreferences prefs, Map<String, String> ledger) =>
      prefs.setString(_ledgerKey, jsonEncode(ledger));
}
