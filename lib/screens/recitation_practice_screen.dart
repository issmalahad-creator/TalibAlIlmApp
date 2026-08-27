import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/recitation_repository.dart';
import '../services/language_preference_service.dart';
import '../services/platform_speech_recognition_engine.dart';
import '../services/speech_recognition_engine.dart';
import '../theme/app_theme.dart';
import '../utils/recitation_alignment.dart';

/// "تسميع" — Phase 76.3. The student recites one ayah out loud; the app
/// records, transcribes (via [SpeechRecognitionEngine] — V1:
/// [PlatformSpeechRecognitionEngine], OS-native, see that file's doc
/// comment for why it's built behind an interface), aligns the transcript
/// against the real ayah text ([alignRecitation]), and shows exactly which
/// words were correct/missing/wrong. Scoped honestly, matching Tarteel's
/// own real shipped feature (verified via screenshots, 2026-08-26): flags
/// word-level mistakes only, never claims to grade tajweed or makharij.
class RecitationPracticeScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  const RecitationPracticeScreen({super.key, required this.surah, required this.ayah});

  @override
  State<RecitationPracticeScreen> createState() => _RecitationPracticeScreenState();
}

enum _Status { idle, initializing, listening, scoring, done, unavailable, permissionDenied }

class _RecitationPracticeScreenState extends State<RecitationPracticeScreen> {
  final _repo = QuranReadingRepository();
  final _recitationRepo = RecitationRepository();
  final SpeechRecognitionEngine _engine = PlatformSpeechRecognitionEngine();

  QuranAyahText? _ayahText;
  _Status _status = _Status.idle;
  String _partialTranscript = '';
  RecitationAlignmentResult? _result;
  String? _arabicLocaleId;

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
    super.dispose();
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

    final arabicLocales = await _engine.availableArabicLocaleIds();
    if (arabicLocales.isEmpty) {
      setState(() => _status = _Status.unavailable);
      return;
    }
    _arabicLocaleId = arabicLocales.first;

    setState(() => _status = _Status.listening);
    await _engine.startListening(
      localeId: _arabicLocaleId,
      onPartialResult: (text) {
        if (!mounted) return;
        setState(() => _partialTranscript = text);
      },
      onFinalResult: (text) async {
        if (!mounted) return;
        setState(() => _status = _Status.scoring);
        final ayah = _ayahText;
        if (ayah == null) return;
        final result = await _recitationRepo.recordAttempt(
          surah: widget.surah,
          ayah: widget.ayah,
          mode: 'recite',
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

  Widget _buildAyahDisplay(String lang) {
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
    switch (_status) {
      case _Status.listening:
        return Column(
          children: [
            Text(basicText('recitation_listening_status', lang), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_partialTranscript.isNotEmpty)
              Text(_partialTranscript, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted)),
          ],
        );
      case _Status.scoring:
        return const Center(child: CircularProgressIndicator());
      case _Status.done:
        final r = _result!;
        final percent = (r.score * 100).round();
        return Column(
          children: [
            Text('${basicText('recitation_score_label', lang)}: $percent%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            if (r.extraWordCount > 0) const SizedBox(height: 4),
          ],
        );
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
