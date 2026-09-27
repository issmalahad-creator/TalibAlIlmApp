import 'dart:async';

import 'package:flutter/foundation.dart';

/// Zero-wait startup (docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md).
///
/// Heavy first-run work (seeding the Quran text, mushaf layout, corpus,
/// Turath catalog, notification schedules…) used to fire all at once from
/// `main.dart`, on one SQLite connection, while Home's six tiny queries
/// queued behind it — Home took 31 s and could hang for good. Now:
///
/// - tasks are registered, not started;
/// - nothing starts until Home says it has painted ([markHomeReady]), or a
///   safety timeout passes (e.g. the user is still in onboarding);
/// - then they run **one at a time**, in priority order, so interactive
///   queries interleave instead of waiting for six concurrent transactions;
/// - a screen that needs a task's data calls [ensure] to run it now —
///   idempotent: every caller shares the same Future, nothing runs twice.
class BootScheduler {
  BootScheduler._();
  static final BootScheduler instance = BootScheduler._();

  /// Started when `main()` first touches the scheduler — the reference point
  /// for the one-line boot timings in logcat (cheap: two log lines per launch).
  final Stopwatch sinceLaunch = Stopwatch()..start();

  final _tasks = <String, _BootTask>{};
  final _running = <String, Future<void>>{};
  bool _warmUpStarted = false;
  bool _homeReady = false;
  bool _afterHomeQueued = false;
  Timer? _safetyTimer;

  /// Registers a deferred task. Lower [priority] runs earlier.
  /// [afterHome] tasks never start from the safety timer — only once Home has
  /// really appeared (e.g. notification scheduling, which may ask for the
  /// location permission and must not pop up over first-launch onboarding).
  void register(String id, Future<void> Function() run,
      {int priority = 50, bool afterHome = false}) {
    _tasks[id] = _BootTask(id, run, priority, afterHome);
  }

  /// Runs [id] now (if it hasn't started) and completes when it finishes.
  /// Unknown ids complete immediately so callers never hang.
  Future<void> ensure(String id) {
    final existing = _running[id];
    if (existing != null) return existing;
    final task = _tasks[id];
    if (task == null) return Future.value();
    final started = Stopwatch()..start();
    final f = Future(() => task.run()).catchError((Object e, StackTrace s) {
      // A failed seed must not break boot; each sync already records its own
      // failure and retries on the next launch.
      debugPrint('BootScheduler: "$id" failed: $e');
    }).whenComplete(() {
      debugPrint('BootScheduler: "$id" done in ${started.elapsedMilliseconds} ms');
    });
    _running[id] = f;
    return f;
  }

  /// Starts the safety timer; call once after `runApp`.
  void armSafetyTimer({Duration after = const Duration(seconds: 4)}) {
    _safetyTimer ??= Timer(after, _startWarmUp);
  }

  /// True once the first real screen (Home, or first-launch onboarding) has
  /// content on screen — the brand splash listens to leave.
  final ValueNotifier<bool> firstScreenReady = ValueNotifier(false);

  /// Onboarding is on screen: the splash may leave; warm-up keeps waiting
  /// for its safety timer (so seeding overlaps the tutorial) and afterHome
  /// tasks keep waiting for Home.
  void markOnboardingShown() {
    if (!firstScreenReady.value) {
      debugPrint('BootScheduler: onboarding shown at ${sinceLaunch.elapsedMilliseconds} ms');
    }
    firstScreenReady.value = true;
  }

  /// Home has painted its real content — start background warm-up.
  void markHomeReady() {
    if (!_homeReady) {
      debugPrint('BootScheduler: home ready at ${sinceLaunch.elapsedMilliseconds} ms');
    }
    firstScreenReady.value = true;
    _homeReady = true;
    _startWarmUp();
  }

  Future<void>? _chain;

  void _startWarmUp() {
    _safetyTimer?.cancel();
    if (!_warmUpStarted) {
      _warmUpStarted = true;
      // One frame of breathing room, then strictly sequential.
      _chain = Future<void>.delayed(const Duration(milliseconds: 300), () => _runPending(false));
    }
    if (_homeReady && !_afterHomeQueued) {
      _afterHomeQueued = true;
      // afterHome tasks queue behind whatever is already running.
      _chain = (_chain ?? Future.value()).then((_) => _runPending(true));
    }
  }

  Future<void> _runPending(bool includeAfterHome) async {
    final ordered = _tasks.values
        .where((t) => includeAfterHome || !t.afterHome)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    for (final t in ordered) {
      await ensure(t.id);
    }
  }

  @visibleForTesting
  void resetForTest() {
    _tasks.clear();
    _running.clear();
    _warmUpStarted = false;
    _homeReady = false;
    firstScreenReady.value = false;
    _afterHomeQueued = false;
    _chain = null;
    _safetyTimer?.cancel();
    _safetyTimer = null;
  }
}

class _BootTask {
  final String id;
  final Future<void> Function() run;
  final int priority;
  final bool afterHome;
  _BootTask(this.id, this.run, this.priority, this.afterHome);
}

/// Task ids shared by `main.dart` (registration) and entry screens ([BootScheduler.ensure]).
abstract final class BootTasks {
  static const quranImport = 'quran_import';
  static const legacyTafsir = 'legacy_tafsir';
  static const mushafLayout = 'mushaf_layout';
  static const quranCorpus = 'quran_corpus';
  static const quranLearning = 'quran_learning';
  static const turathCatalog = 'turath_catalog';
  static const milestones = 'milestones';
  static const notifications = 'notifications';
  static const bookContent = 'book_content';
  static const contentPacks = 'content_packs';
}
