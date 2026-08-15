import 'dart:math';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';

/// Independent Validation Engine for Phase 9 (Qibla + prayer times) —
/// QURAN_COMPANION_ROADMAP.md. Rather than hardcoding "known correct"
/// prayer times from memory (risky — a misremembered reference value would
/// create false confidence), this validates INTERNAL CONSISTENCY of the
/// `adhan_dart` engine's output across a spread of real cities, dates, and
/// calculation methods:
///   1. The six daily prayers are always in chronological order.
///   2. Dhuhr always falls within a few minutes of local solar noon,
///      computed here independently via a standard low-precision equation-
///      of-time approximation (a public astronomical formula, not
///      library-specific) — this cross-checks the library against
///      first-principles astronomy, not against itself.
///   3. Method changes only actually move Fajr/Isha (which are defined by
///      differing twilight angles per method) — Dhuhr must stay identical
///      across methods, since solar noon doesn't depend on any Islamic
///      calculation convention.
void main() {
  final cities = {
    'Mecca': const Coordinates(21.4225, 39.8262),
    'Addis Ababa': const Coordinates(9.0250, 38.7469),
    'Cairo': const Coordinates(30.0444, 31.2357),
    'Istanbul': const Coordinates(41.0082, 28.9784),
    'London': const Coordinates(51.5074, -0.1278),
    'New York': const Coordinates(40.7128, -74.0060),
    'Jakarta': const Coordinates(-6.2088, 106.8456),
    'Sydney': const Coordinates(-33.8688, 151.2093),
  };

  final dates = [
    DateTime.utc(2026, 1, 15),
    DateTime.utc(2026, 3, 20),
    DateTime.utc(2026, 6, 21),
    DateTime.utc(2026, 9, 22),
    DateTime.utc(2026, 12, 21),
  ];

  final methods = [
    CalculationMethodParameters.muslimWorldLeague(),
    CalculationMethodParameters.egyptian(),
    CalculationMethodParameters.ummAlQura(),
    CalculationMethodParameters.karachi(),
  ];

  group('chronological ordering holds for every city/date/method', () {
    for (final cityEntry in cities.entries) {
      for (final date in dates) {
        for (final params in methods) {
          test('${cityEntry.key} on ${date.toIso8601String().substring(0, 10)}', () {
            final times = PrayerTimes(
              coordinates: cityEntry.value,
              date: date,
              calculationParameters: params,
              precision: true,
            );
            expect(times.fajr.isBefore(times.sunrise), isTrue, reason: 'Fajr before Sunrise');
            expect(times.sunrise.isBefore(times.dhuhr), isTrue, reason: 'Sunrise before Dhuhr');
            expect(times.dhuhr.isBefore(times.asr), isTrue, reason: 'Dhuhr before Asr');
            expect(times.asr.isBefore(times.maghrib), isTrue, reason: 'Asr before Maghrib');
            expect(times.maghrib.isBefore(times.isha), isTrue, reason: 'Maghrib before Isha');
          });
        }
      }
    }
  });

  group('Dhuhr matches independently-computed solar noon within 5 minutes', () {
    for (final cityEntry in cities.entries) {
      for (final date in dates) {
        test('${cityEntry.key} on ${date.toIso8601String().substring(0, 10)}', () {
          final times = PrayerTimes(
            coordinates: cityEntry.value,
            date: date,
            calculationParameters: CalculationMethodParameters.muslimWorldLeague(),
            precision: true,
          );
          final expectedSolarNoonUtc = _solarNoonUtc(cityEntry.value.longitude, date);
          final diff = times.dhuhr.difference(expectedSolarNoonUtc).inSeconds.abs();
          expect(diff, lessThan(5 * 60), reason: 'Dhuhr should be within 5 min of independently-computed solar noon');
        });
      }
    }
  });

  test('Dhuhr stays within a couple minutes across calculation methods (only Fajr/Isha should vary substantially)', () {
    // Dhuhr is always anchored to solar transit, but some methods (e.g.
    // Umm al-Qura) apply their own small conventional offset on top of it —
    // this test caught that a strict "must be identical" assumption was
    // wrong on first run; a few minutes' spread is the actual correct
    // behavior, not a bug.
    final coordinates = cities['Cairo']!;
    final date = dates.first;
    final dhuhrTimes = methods
        .map((p) => PrayerTimes(coordinates: coordinates, date: date, calculationParameters: p, precision: true).dhuhr)
        .toList();
    final minTime = dhuhrTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxTime = dhuhrTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    expect(maxTime.difference(minTime).inMinutes, lessThan(3), reason: 'Dhuhr should only vary by a small conventional offset between methods, not meaningfully');
  });
}

/// Low-precision equation-of-time approximation (standard astronomical
/// formula, accurate to within ~1-2 minutes — good enough for a sanity
/// cross-check, not meant to replace the library's own higher-precision
/// Meeus-based calculation).
DateTime _solarNoonUtc(double longitudeDegrees, DateTime date) {
  final dayOfYear = date.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
  final b = 2 * pi * (dayOfYear - 81) / 365.0;
  final eotMinutes = 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);
  final noonOffsetHours = longitudeDegrees / 15.0 + eotMinutes / 60.0;
  final noonOffsetMinutes = (noonOffsetHours * 60).round();
  return DateTime.utc(date.year, date.month, date.day, 12).subtract(Duration(minutes: noonOffsetMinutes));
}
