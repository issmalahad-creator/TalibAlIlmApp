import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../db/database_helper.dart';
import '../models/tahfeez_session_config.dart';
import '../services/quran_audio_engine.dart';
import '../theme/app_theme.dart';

/// The active تحفيظ session player — either started fresh with a
/// [config], or resumed from `TahfeezSessionPrefs` when [resume] is true.
class TahfeezPlaybackScreen extends StatefulWidget {
  final TahfeezSessionConfig? config;
  final bool resume;
  const TahfeezPlaybackScreen({super.key, this.config, this.resume = false}) : assert(config != null || resume);

  @override
  State<TahfeezPlaybackScreen> createState() => _TahfeezPlaybackScreenState();
}

class _TahfeezPlaybackScreenState extends State<TahfeezPlaybackScreen> {
  final _engine = QuranAudioEngine();
  TahfeezPlaybackState? _state;
  bool _running = false;
  bool _finished = false;
  String? _ayahText;
  (int, int)? _ayahTextFor;

  @override
  void initState() {
    super.initState();
    _engine.stateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _state = s;
        _finished = s.mode == TahfeezPlaybackMode.finished;
      });
      _loadAyahTextIfNeeded(s.surah, s.ayah);
    });
    _startOrResume();
  }

  /// Shows the actual ayah text on screen while it plays — Ismail's
  /// explicit request ("يتم التضليل على الآية") to follow along visually,
  /// not just see "سورة X — آية Y". Caches by (surah, ayah) so repeats of
  /// the same ayah (the whole point of a تحفيظ session) don't re-query.
  Future<void> _loadAyahTextIfNeeded(int surah, int ayah) async {
    if (_ayahTextFor == (surah, ayah)) return;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_ayat', columns: ['text_uthmani'], where: 'surah = ? AND ayah = ?', whereArgs: [surah, ayah], limit: 1);
    if (!mounted || rows.isEmpty) return;
    setState(() {
      _ayahText = rows.first['text_uthmani'] as String;
      _ayahTextFor = (surah, ayah);
    });
  }

  Future<void> _startOrResume() async {
    setState(() => _running = true);
    if (widget.resume) {
      await _engine.resumeSession();
    } else {
      await _engine.playListenAndRepeatSession(widget.config!);
    }
    if (!mounted) return;
    setState(() => _running = false);
  }

  void _stop() {
    _engine.stop();
    setState(() => _running = false);
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  String _surahName(int number) => quranSurahs.firstWhere((s) => s.number == number).name;

  String _modeLabel(TahfeezPlaybackMode mode) {
    switch (mode) {
      case TahfeezPlaybackMode.playing:
        return 'استماع';
      case TahfeezPlaybackMode.silence:
        return 'سكتة — كرر الآن';
      case TahfeezPlaybackMode.paused:
        return 'إيقاف مؤقت';
      case TahfeezPlaybackMode.finished:
        return 'انتهت الجلسة';
      case TahfeezPlaybackMode.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(title: const Text('جلسة التحفيظ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_finished) ...[
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
                      const SizedBox(height: 16),
                      const Text('أحسنت — أتممت الجلسة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ] else ...[
                      Text('${_surahName(state.surah)} — الآية ${state.ayah}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                      const SizedBox(height: 14),
                      if (_ayahText != null && _ayahTextFor == (state.surah, state.ayah))
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: state.mode == TahfeezPlaybackMode.silence ? const Color(0xFFD9A441).withValues(alpha: 0.15) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            _ayahText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, height: 1.9, color: AppColors.textDark),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text('جولة ${state.rangePass} — تكرار ${state.ayahRepeat}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: state.mode == TahfeezPlaybackMode.silence ? const Color(0xFFD9A441).withValues(alpha: 0.15) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.mode == TahfeezPlaybackMode.silence ? Icons.mic_none_outlined : Icons.volume_up_outlined,
                              size: 18,
                              color: state.mode == TahfeezPlaybackMode.silence ? const Color(0xFFB8860B) : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 8),
                            Text(_modeLabel(state.mode), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: _running
                            ? OutlinedButton.icon(onPressed: _stop, icon: const Icon(Icons.stop_circle_outlined), label: const Text('إيقاف الجلسة'))
                            : FilledButton.icon(onPressed: _startOrResume, icon: const Icon(Icons.play_circle_outline), label: const Text('استئناف')),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
