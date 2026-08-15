import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';

/// Wraps `adhan_dart` (MIT-licensed, published/audited astronomical
/// formulas — see QURAN_COMPANION_ROADMAP.md's Phase 9 decision record for
/// why this app uses a verified library core instead of hand-derived
/// astronomy) as the Prayer Calculation Engine. Calculation method and
/// madhab are configurable and persisted — different regions/schools
/// genuinely disagree on Fajr/Isha angles and Asr timing, so there is no
/// single "correct" default to silently assume.
class PrayerTimesRepository {
  static const _methodKey = 'prayer_calculation_method';
  static const _madhabKey = 'prayer_madhab';
  static const _highLatitudeRuleKey = 'prayer_high_latitude_rule';

  /// 'auto' uses adhan_dart's own `HighLatitudeRule.recommended(coordinates)`
  /// — the library picks the right rule based on the student's actual
  /// latitude, since a fixed default would be wrong for most locations
  /// (this only matters at all above ~48° latitude, where twilight never
  /// gets dark enough for normal Fajr/Isha angle calculations).
  static const highLatitudeRuleNames = ['auto', 'middleOfTheNight', 'seventhOfTheNight', 'twilightAngle'];

  Future<String> selectedHighLatitudeRule() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_highLatitudeRuleKey) ?? 'auto';
  }

  Future<void> setHighLatitudeRule(String rule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_highLatitudeRuleKey, rule);
  }

  static const methodNames = [
    'muslimWorldLeague',
    'egyptian',
    'karachi',
    'ummAlQura',
    'dubai',
    'qatar',
    'kuwait',
    'moonsightingCommittee',
    'singapore',
    'turkiye',
    'tehran',
    'northAmerica',
    'morocco',
  ];

  Future<String> selectedMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_methodKey) ?? 'muslimWorldLeague';
  }

  Future<void> setMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_methodKey, method);
  }

  Future<Madhab> selectedMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_madhabKey) ?? 'shafi') == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  Future<void> setMadhab(Madhab madhab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_madhabKey, madhab == Madhab.hanafi ? 'hanafi' : 'shafi');
  }

  CalculationParameters _paramsFor(String method, Madhab madhab, String highLatitudeRule, Coordinates coordinates) {
    final params = switch (method) {
      'egyptian' => CalculationMethodParameters.egyptian(),
      'karachi' => CalculationMethodParameters.karachi(),
      'ummAlQura' => CalculationMethodParameters.ummAlQura(),
      'dubai' => CalculationMethodParameters.dubai(),
      'qatar' => CalculationMethodParameters.qatar(),
      'kuwait' => CalculationMethodParameters.kuwait(),
      'moonsightingCommittee' => CalculationMethodParameters.moonsightingCommittee(),
      'singapore' => CalculationMethodParameters.singapore(),
      'turkiye' => CalculationMethodParameters.turkiye(),
      'tehran' => CalculationMethodParameters.tehran(),
      'northAmerica' => CalculationMethodParameters.northAmerica(),
      'morocco' => CalculationMethodParameters.morocco(),
      _ => CalculationMethodParameters.muslimWorldLeague(),
    };
    params.madhab = madhab;
    params.highLatitudeRule = switch (highLatitudeRule) {
      'middleOfTheNight' => HighLatitudeRule.middleOfTheNight,
      'seventhOfTheNight' => HighLatitudeRule.seventhOfTheNight,
      'twilightAngle' => HighLatitudeRule.twilightAngle,
      _ => HighLatitudeRule.recommended(coordinates),
    };
    return params;
  }

  /// Computes today's (or [date]'s) prayer times for [coordinates] using
  /// the student's saved method/madhab/high-latitude-rule preference.
  Future<PrayerTimes> prayerTimesFor(AppCoordinates coordinates, {DateTime? date}) async {
    final method = await selectedMethod();
    final madhab = await selectedMadhab();
    final highLatitudeRule = await selectedHighLatitudeRule();
    final coords = Coordinates(coordinates.latitude, coordinates.longitude);
    final params = _paramsFor(method, madhab, highLatitudeRule, coords);
    return PrayerTimes(
      coordinates: coords,
      date: date ?? DateTime.now(),
      calculationParameters: params,
      precision: true,
    );
  }

  double qiblaBearing(AppCoordinates coordinates) {
    return Qibla.qibla(Coordinates(coordinates.latitude, coordinates.longitude));
  }
}
