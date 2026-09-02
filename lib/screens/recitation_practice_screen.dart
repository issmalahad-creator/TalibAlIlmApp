import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/recitation_repository.dart';
import '../services/language_preference_service.dart';
import '../services/platform_speech_recognition_engine.dart';
import '../services/quran_audio/quran_audio_provider_registry.dart';
import '../services/quran_audio_engine.dart';
import '../services/speech_recognition_engine.dart';
import '../theme/app_theme.dart';
import '../utils/recitation_alignment.dart';

/// "تسميع" — Phase 76.3. Three modes matching Tarteel's real, proven UX
/// (screenshots verified 2026-08-26) rather than a redesign from scratch:
/// **Listen** (reciter audio, reuses the existing `QuranAudioEngine` —
/// nothing new to build there), **Recite** (ayah shown while recording,
/// scored after), **Test** (ayah text hidden until scored — real recall,
/// not read-along). Recite/Test both go through the same real pipeline:
/// record → transcribe (via [SpeechRecognitionEngine] — V1:
/// [PlatformSpeechRecognitionEngine], OS-native, see that file's doc
/// comment for why it's built behind an interface) → align against the
/// real ayah text ([alignRecitation]) → per-word correct/missing/wrong.
/// Scoped honestly, matching Tarteel's own real shipped feature: flags
/// word-level mistakes only, never claims to grade tajweed or makharij.
class RecitationPracticeScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  const RecitationPracticeScreen({super.key, required this.surah, required this.ayah});

  @override
  State<RecitationPracticeScreen> createState() => _RecitationPracticeScreenState();
}

enum _Mode { listen, recite, test }

enum _Status { idle, initializing, listening, scoring, done, unavailable, permissionDenied }

class _RecitationPracticeScreenState extends State<RecitationPracticeScreen> {
  final _repo = QuranReadingRepository();
  final _recitationRepo = RecitationRepository();
  final SpeechRecognitionEngine _engine = PlatformSpeechRecognitionEngine();
  final _audioEngine = QuranAudioEngine();
  final _reciterId = QuranAudioProviderRegistry.reciters().first.id;

  QuranAyahText? _ayahText;
  _Mode _mode = _Mode.recite;
  _Status _status = _Status.idle;
  String _partialTranscript = '';
  RecitationAlignmentResult? _result;
  bool _playingAudio = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await _repo.ayahAt(widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() => _ayahText = a);
  }

  @override
  void dispose() {
    _engine.dispose();
    _audioEngine.stop();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    if (_status == _Status.listening) _engine.stopListening();
    _audioEngine.stop();
    setState(() {
      _mode = mode;
      _status = _Status.idle;
      _result = null;
      _partialTranscript = '';
      _playingAudio = false;
    });
  }

  Future<void> _playReciterAudio() async {
    setState(() => _playingAudio = true);
    await _audioEngine.playAyah(_reciterId, widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() => _playingAudio = false);
  }

  Future<void> _startRecitation() async {
    setState(() {
      _status = _Status.initializing;
      _result = null;
      _partialTranscript = '';
    });

    final ok = await _engine.initialize();
    if (!ok) {
      setState(() => _status = _Status.permissionDenied);
      return;
    }

    // 2026-08-28 (Ismail, real-device test): pre-checking availableArabicLocaleIds()
    // and refusing to even try was too strict -- some real devices don't
    // list Arabic in locales() even though the underlying recognizer can
    // still handle it (or handles it via the system default). Attempt to
    // listen with an explicit Arabic locale when one is reported, otherwise
    // fall back to the device's default locale instead of blocking outright
    // -- a real listen attempt is a better test than a locale-list lookup.
    final arabicLocales = await _engine.availableArabicLocaleIds();
    setState(() => _status = _Status.listening);
    await _engine.startListening(
      localeId: arabicLocales.isNotEmpty ? arabicLocales.first : null,
      // Real device bug found 2026-08-29 ("لا يدخل الصوت"): a segment that
      // ends via error (very commonly just a pre-speech silence timeout)
      // used to silently kill the whole listen session with no visible
      // sign anything was wrong. The engine now auto-retries transient
      // errors on its own; only a real, non-recoverable error reaches here.
      onError: (message, permanent) {
        if (!mounted || !permanent) return;
        setState(() => _status = _Status.unavailable);
      },
      onPartialResult: (text) {
        if (!mounted) return;
        setState(() => _partialTranscript = text);
      },
      onFinalResult: (text) async {
        // This screen is still single-ayah scoped (76.3-redesign phases
        // 3-6 move page-level continuous sessions into the reader itself).
        // The engine now keeps listening across pause-segments by default
        // (for that future page mode), so explicitly stop it after the
        // first segment here or it would keep listening past this ayah.
        await _engine.stopListening();
        if (!mounted) return;
        setState(() => _status = _Status.scoring);
        final ayah = _ayahText;
        if (ayah == null) return;
        final result = await _recitationRepo.recordAttempt(
          surah: widget.surah,
          ayah: widget.ayah,
          mode: _mode == _Mode.test ? 'test' : 'recite',
          expectedWords: ayah.text.split(' '),
          saidWords: text.trim().isEmpty ? [] : text.trim().split(' '),
        );
        if (!mounted) return;
        setState(() {
          _result = result;
          _status = _Status.done;
        });
      },
    );
  }

  Future<void> _stopRecitation() async {
    await _engine.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('recitation_practice_title', lang))),
        body: _ayahText == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildModeSwitcher(lang),
                    const SizedBox(height: 20),
                    _buildAyahDisplay(lang),
                    const SizedBox(height: 24),
                    _buildStatusArea(lang),
                    const SizedBox(height: 24),
                    _buildActionButton(lang),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModeSwitcher(String lang) {
    Widget segment(_Mode mode, IconData icon, String labelKey) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textMuted),
                const SizedBox(height: 2),
                Text(
                  basicText(labelKey, lang),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          segment(_Mode.listen, Icons.play_arrow_rounded, 'recitation_mode_listen'),
          segment(_Mode.recite, Icons.mic_rounded, 'recitation_mode_recite'),
          segment(_Mode.test, Icons.visibility_off_rounded, 'recitation_mode_test'),
        ],
      ),
    );
  }

  Widget _buildAyahDisplay(String lang) {
    // Test mode hides the ayah text until it's scored -- real recall, not
    // read-along. Listen/Recite always show it.
    final hideText = _mode == _Mode.test && _result == null;
    if (hideText) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            const Icon(Icons.visibility_off_outlined, color: AppColors.textMuted, size: 28),
            const SizedBox(height: 10),
            Text(basicText('recitation_hidden_ayah_hint', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    // Before a result exists, show the plain ayah text. Once scored, replace
    // each word with its own color per alignRecitation's real result --
    // this *is* the actual comparison, not a cosmetic highlight.
    if (_result == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
        child: Text(
          _ayahText!.text,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, height: 1.9, color: AppColors.textDark),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Wrap(
        alignment: WrapAlignment.center,
        textDirection: TextDirection.rtl,
        spacing: 8,
        runSpacing: 10,
        children: _result!.words.map((w) {
          final color = switch (w.status) {
            RecitationWordStatus.correct => const Color(0xFF1F7A4D),
            RecitationWordStatus.missing => const Color(0xFFB5651D),
            RecitationWordStatus.wrong => const Color(0xFFC0392B),
          };
          return Text(
            w.expectedWord,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9, color: color, fontWeight: FontWeight.w700),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusArea(String lang) {
    if (_mode == _Mode.listen) return const SizedBox.shrink();
    switch (_status) {
      case _Status.listening:
        return Column(
          children: [
            Text(basicText('recitation_listening_status', lang), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_partialTranscript.isNotEmpty && _mode != _Mode.test)
              Text(_partialTranscript, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted)),
          ],
        );
      case _Status.scoring:
        return const Center(child: CircularProgressIndicator());
      case _Status.done:
        final r = _result!;
        final percent = (r.score * 100).round();
        return Text('${basicText('recitation_score_label', lang)}: $percent%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark));
      case _Status.unavailable:
        return Text(basicText('recitation_no_arabic_locale', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted));
      case _Status.permissionDenied:
        return Text(basicText('recitation_mic_permission_denied', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted));
      case _Status.idle:
      case _Status.initializing:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(String lang) {
    if (_mode == _Mode.listen) {
      return ElevatedButton.icon(
        onPressed: _playingAudio ? null : _playReciterAudio,
        icon: Icon(_playingAudio ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
        label: Text(basicText(_playingAudio ? 'recitation_playing_status' : 'recitation_play_action', lang)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
      );
    }

    final listening = _status == _Status.listening;
    return ElevatedButton.icon(
      onPressed: switch (_status) {
        _Status.initializing || _Status.scoring => null,
        _Status.listening => _stopRecitation,
        _ => _startRecitation,
      },
      icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
      label: Text(listening ? basicText('recitation_stop_action', lang) : basicText('recitation_start_action', lang)),
      style: ElevatedButton.styleFrom(
        backgroundColor: listening ? const Color(0xFFC0392B) : AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
