import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/completion_goal_session.dart';

/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.3.7أ — pure, no-DB tests for the
/// two ready-made session patterns' exact math (§2.3.7أ's own table),
/// matching this app's "explicit rules, no AI" philosophy.
void main() {
  group('equalSessionPattern', () {
    test('7 sessions always sum to the exact daily target', () {
      for (final target in [1, 6, 7, 8, 20, 21, 100]) {
        final sessions = equalSessionPattern(target);
        expect(sessions.length, 7);
        expect(sessions.fold<int>(0, (s, e) => s + e.units), target);
      }
    });

    test('remainder goes one-per-session from the first session, in order', () {
      // 22 / 7 = base 3, remainder 1 -> first session gets +1, rest base.
      final sessions = equalSessionPattern(22);
      expect(sessions[0].units, 4);
      for (var i = 1; i < 7; i++) {
        expect(sessions[i].units, 3);
      }
    });

    test('below 7 still never goes negative — early sessions absorb the 1s', () {
      final sessions = equalSessionPattern(3);
      expect(sessions.fold<int>(0, (s, e) => s + e.units), 3);
      expect(sessions.every((s) => s.units >= 0), isTrue);
    });

    test('wake/sleep sessions are fixed-time, the 5 prayers are prayer-anchored', () {
      final sessions = equalSessionPattern(21);
      expect(sessions.first.anchorType, 'fixed');
      expect(sessions.last.anchorType, 'fixed');
      for (final s in sessions.sublist(1, 6)) {
        expect(s.anchorType, 'prayer');
      }
    });
  });

  group('focusedSessionPattern', () {
    test('3 light sessions fixed at 2 pages, remainder goes fully to isha', () {
      // target 20 -> remaining after 3*2=6 is 14, /4 main = base 3 rem 2 -> isha = 3+2=5
      final sessions = focusedSessionPattern(20);
      final byLabel = {for (final s in sessions) s.label: s};
      expect(byLabel['الشروق']!.units, 2);
      expect(byLabel['المغرب']!.units, 2);
      expect(byLabel['قبل النوم']!.units, 2);
      expect(byLabel['الفجر']!.units, 3);
      expect(byLabel['الظهر']!.units, 3);
      expect(byLabel['العصر']!.units, 3);
      expect(byLabel['العشاء']!.units, 5);
      expect(sessions.fold<int>(0, (s, e) => s + e.units), 20);
    });

    test('hidden below 7 per the spec\'s own edge case', () {
      expect(focusedPatternApplicable(6), isFalse);
      expect(focusedPatternApplicable(7), isTrue);
    });
  });
}
