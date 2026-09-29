import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// One short, sourced item from `assets/brand/daily_benefits.json`
/// (built by `tool/build_daily_benefits.py`): a whole hadith from the Nawawi
/// forty, an authentically graded dhikr from Hisn al-Muslim, an ayah, or a
/// standalone faida from Ibn al-Qayyim's «الفوائد».
@immutable
class DailyBenefit {
  final String id;
  final String kind; // hadith | dhikr | ayah | faida
  final String text;
  final String source;

  const DailyBenefit({required this.id, required this.kind, required this.text, required this.source});

  bool get isAyah => kind == 'ayah';

  factory DailyBenefit.fromJson(Map<String, dynamic> j) => DailyBenefit(
        id: j['id'] as String,
        kind: j['kind'] as String,
        text: j['text'] as String,
        source: j['source'] as String,
      );
}

/// Picks a fresh benefit on every app launch (Ismail 2026-09-27: «متجدد جدًا»).
///
/// - Never repeats anything shown in the last [recentMemory] picks (kept in
///   SharedPreferences, so it survives restarts).
/// - Rotates kinds: the next pick is never the same kind as the previous one,
///   so launches alternate hadith / dhikr / ayah / faida.
/// - The splash and the Home card get *different* items in the same launch.
///
/// Lightweight: the 110 KB pool is read once, lazily, on first use
/// (no DB, no network) — see `lightweight-feature-rules`.
class DailyBenefitService {
  DailyBenefitService._();
  static final DailyBenefitService instance = DailyBenefitService._();

  static const recentMemory = 120;
  static const _recentKey = 'daily_benefit_recent_v1';
  static const _asset = 'assets/brand/daily_benefits.json';

  final _rng = Random();
  Future<List<DailyBenefit>>? _pool;

  /// The item chosen for this launch's splash, available as soon as it is
  /// picked (the splash listens; null until then).
  final ValueNotifier<DailyBenefit?> splashPick = ValueNotifier(null);

  Future<List<DailyBenefit>> _load() => _pool ??= () async {
        final raw = await rootBundle.loadString(_asset);
        final items = (jsonDecode(raw)['items'] as List).cast<Map<String, dynamic>>();
        return items.map(DailyBenefit.fromJson).toList(growable: false);
      }();

  /// Picks the splash item. Called from `main()` without awaiting, while the
  /// first frame is held for the logo — never delays boot.
  Future<void> preloadForSplash() async {
    try {
      splashPick.value ??= await next();
    } catch (e) {
      debugPrint('DailyBenefitService: splash pick failed: $e');
    }
  }

  /// A new item, different from recent ones and from the previous kind.
  Future<DailyBenefit> next() async {
    final pool = await _load();
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentKey) ?? const <String>[];
    final recentSet = recent.toSet();
    final lastKind = recent.isEmpty ? null : _kindOf(recent.last);

    final unseen = pool.where((b) => !recentSet.contains(b.id)).toList();

    // Kind rotation that never starves the small pools: fawa'id (173) and
    // the small kinds (hadith 25 · dhikr 50 · ayat 34) alternate, so only
    // ~60 of the 120 remembered picks are small-kind — fewer than the 109
    // available — and "never the same kind twice" and "never a repeat" both
    // hold. (Picking uniformly among the other kinds spent the small pools
    // twice as fast; once they ran out, two fawa'id came in a row.)
    String? kind;
    final unseenFaida = unseen.where((b) => b.kind == 'faida').toList();
    if (lastKind != 'faida' && unseenFaida.isNotEmpty) {
      kind = 'faida';
    } else {
      // The small kind shown least often lately; ties broken at random.
      final small = unseen.where((b) => b.kind != 'faida' && b.kind != lastKind).map((b) => b.kind).toSet().toList()
        ..shuffle(_rng);
      if (small.isNotEmpty) {
        int shown(String k) => recent.where((id) => _kindOf(id) == k).length;
        small.sort((a, b) => shown(a).compareTo(shown(b)));
        kind = small.first;
      }
    }

    var candidates = kind == null ? const <DailyBenefit>[] : unseen.where((b) => b.kind == kind).toList();
    if (candidates.isEmpty) candidates = unseen; // rotation impossible — still never repeat
    if (candidates.isEmpty) candidates = pool; // everything seen recently — start over
    final ofKind = candidates;
    final pick = ofKind[_rng.nextInt(ofKind.length)];

    final updated = [...recent, pick.id];
    await prefs.setStringList(
      _recentKey,
      updated.length > recentMemory ? updated.sublist(updated.length - recentMemory) : updated,
    );
    return pick;
  }

  static String? _kindOf(String id) {
    final p = id.split(':').first;
    return switch (p) { 'nawawi' => 'hadith', 'hisn' => 'dhikr', 'ayah' => 'ayah', 'fawaid' => 'faida', _ => null };
  }

  @visibleForTesting
  void resetForTest({List<DailyBenefit>? pool}) {
    _pool = pool == null ? null : Future.value(pool);
    splashPick.value = null;
  }
}
