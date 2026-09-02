import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/recitation_repository.dart';
import '../services/language_preference_service.dart';
import '../services/mushaf_page_layout.dart';
import '../services/platform_speech_recognition_engine.dart';
import '../services/speech_recognition_engine.dart';
import '../theme/app_theme.dart';
import '../utils/recitation_alignment.dart';
import 'recitation_mistakes_screen.dart';

/// Continuous, whole-page "تسميع" (76.3-redesign, Ismail 2026-08-28: "لا
/// أريد آية بآية ... المشكلة الكبيرة جدًا الصفحة نفسها"). Replaces the
/// single-ayah stop-and-score model with one continuous listening session
/// across an entire Mushaf page: the student recites naturally, ayah after
/// ayah, and the page's own words light up live as they're recognized —
/// no per-ayah button presses.
///
/// Reuses the exact same word layout the real reading screen uses
/// (`flattenAyatToWords`/`packWordsIntoLines`, `mushaf_page_layout.dart`)
/// so this looks and paginates like the actual page, and the exact same
/// alignment/persistence engine as the single-ayah screen
/// (`alignRecitation`, `RecitationRepository`) — a page is just a longer
/// word sequence to that engine, not a different problem.
///
/// Scope, stated plainly (matches 76.3-redesign-verdict in TODO.md): word-
/// level mistakes only (missing/wrong/extra), no tajweed or letter-level
/// grading. Live position tracking is a real but approximate estimate from
/// re-aligning the in-progress partial transcript each update — it is
/// finalized (and only then persisted) once the recognizer reports a
/// finished pause-segment.
class PageRecitationScreen extends StatefulWidget {
  final int pageNumber;
  const PageRecitationScreen({super.key, required this.pageNumber});

  @override
  State<PageRecitationScreen> createState() => _PageRecitationScreenState();
}

enum _Status { loading, idle, initializing, listening, scoring, done, permissionDenied, error }

class _PageRecitationScreenState extends State<PageRecitationScreen> {
  final _repo = QuranReadingRepository();
  final _recitationRepo = RecitationRepository();
  final SpeechRecognitionEngine _engine = PlatformSpeechRecognitionEngine();

  List<QuranAyahText> _ayat = [];
  List<MushafWord> _flatWords = [];

  /// One committed (final, persisted-on-finish) status per word in
  /// [_flatWords] -- null means "not reached yet".
  List<RecitationWordStatus?> _statuses = [];
  int _committedCount = 0;
  final List<String> _allSaidWords = [];

  /// Live, uncommitted preview of the in-progress pause-segment -- recomputed
  /// on every partial-result callback, never persisted on its own.
  List<String> _liveWords = [];
  List<RecitationWordResult> _liveResult = [];
  int _liveCursor = 0;

  _Status _status = _Status.loading;
  PageRecitationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ayat = await _repo.ayatForPage(widget.pageNumber);
    if (!mounted) return;
    final flat = flattenAyatToWords(ayat);
    setState(() {
      _ayat = ayat;
      _flatWords = flat;
      _statuses = List<RecitationWordStatus?>.filled(flat.length, null);
      _status = _Status.idle;
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _status = _Status.initializing;
      _result = null;
      _committedCount = 0;
      _allSaidWords.clear();
      _statuses = List<RecitationWordStatus?>.filled(_flatWords.length, null);
      _liveWords = [];
      _liveResult = [];
      _liveCursor = 0;
    });

    final ok = await _engine.initialize();
    if (!ok) {
      setState(() => _status = _Status.permissionDenied);
      return;
    }
    final arabicLocales = await _engine.availableArabicLocaleIds();

    setState(() => _status = _Status.listening);
    await _engine.startListening(
      localeId: arabicLocales.isNotEmpty ? arabicLocales.first : null,
      // Segment bounds, not session bounds (see SpeechRecognitionEngine's
      // doc comment) -- short pauseFor so ayah-to-ayah gaps are caught
      // promptly, generous listenFor as a per-segment safety cap.
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 3),
      onError: (message, permanent) {
        if (!mounted) return;
        if (!permanent) {
          // Transient (e.g. a pre-speech silence timeout) -- the engine is
          // already restarting the segment on its own; just clear any
          // stale partial text so the UI doesn't show leftover words.
          setState(() {
            _liveWords = [];
            _liveResult = [];
          });
          return;
        }
        setState(() {
          _status = _Status.error;
          _errorMessage = message;
        });
      },
      onPartialResult: (text) {
        if (!mounted || _committedCount >= _flatWords.length) return;
        final words = text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
        final remaining = _flatWords.sublist(_committedCount).map((w) => w.text).toList();
        final live = alignRecitation(expectedWords: remaining, saidWords: words);
        var advance = 0;
        for (final w in live.words) {
          if (w.status == RecitationWordStatus.missing) break;
          advance++;
        }
        setState(() {
          _liveWords = words;
          _liveResult = live.words;
          _liveCursor = _committedCount + advance;
        });
      },
      onFinalResult: (text) => _commitSegment(text),
    );
  }

  Future<void> _commitSegment(String text) async {
    if (!mounted) return;
    final saidWords = text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
    if (saidWords.isEmpty) return; // pure silence segment -- nothing to commit, keep listening

    final remaining = _flatWords.sublist(_committedCount).map((w) => w.text).toList();
    final segment = alignRecitation(expectedWords: remaining, saidWords: saidWords);
    final hasMistake = segment.words.any((w) => w.status != RecitationWordStatus.correct) || segment.extraWordCount > 0;
    if (hasMistake) HapticFeedback.mediumImpact();

    setState(() {
      for (var k = 0; k < segment.words.length; k++) {
        _statuses[_committedCount + k] = segment.words[k].status;
      }
      _committedCount += segment.words.length;
      _allSaidWords.addAll(saidWords);
      _liveWords = [];
      _liveResult = [];
      _liveCursor = _committedCount;
    });

    if (_committedCount >= _flatWords.length) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    await _engine.stopListening();
    if (!mounted) return;
    setState(() => _status = _Status.scoring);
    final result = await _recitationRepo.recordPageAttempt(ayat: _ayat, mode: 'recite', saidWords: _allSaidWords);
    if (!mounted) return;
    setState(() {
      _result = result;
      _status = _Status.done;
    });
  }

  Future<void> _stopManually() async {
    await _engine.stopListening();
    if (_allSaidWords.isEmpty) {
      setState(() => _status = _Status.idle);
      return;
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('${basicText('recitation_practice_title', lang)} — ${basicText('page_label', lang)} ${widget.pageNumber}')),
        body: _status == _Status.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: _buildPageText())),
                  _buildStatusBar(lang),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: _buildActionButton(lang)),
                ],
              ),
      ),
    );
  }

  Widget _buildPageText() {
    final lines = packWordsIntoLines(words: _flatWords, maxWidth: MediaQuery.of(context).size.width - 36, fontSize: 21, fontFamily: 'AmiriQuran');
    var index = 0;
    final rows = <Widget>[];
    for (final line in lines) {
      final spans = <InlineSpan>[];
      for (final word in line.words) {
        spans.add(_wordSpan(word, index));
        spans.add(const TextSpan(text: ' '));
        index++;
      }
      rows.add(RichText(textAlign: TextAlign.center, textDirection: TextDirection.rtl, text: TextSpan(children: spans)));
      rows.add(const SizedBox(height: 6));
    }
    return Column(children: rows);
  }

  InlineSpan _wordSpan(MushafWord word, int index) {
    const base = TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.0, color: AppColors.textDark);

    if (index < _committedCount) {
      final status = _statuses[index];
      final color = switch (status) {
        RecitationWordStatus.correct => const Color(0xFF1F7A4D),
        RecitationWordStatus.missing => const Color(0xFFB5651D),
        RecitationWordStatus.wrong => const Color(0xFFC0392B),
        null => AppColors.textDark,
      };
      final wrong = status == RecitationWordStatus.wrong;
      return TextSpan(
        text: word.text,
        style: base.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          decoration: wrong ? TextDecoration.underline : null,
          decorationStyle: TextDecorationStyle.wavy,
          decorationColor: color,
        ),
      );
    }

    // Not committed yet -- either the live tentative preview, the current
    // word (next expected), or genuinely not reached.
    final liveIdx = index - _committedCount;
    if (_liveWords.isNotEmpty && liveIdx < _liveResult.length && _liveResult[liveIdx].status != RecitationWordStatus.missing) {
      final status = _liveResult[liveIdx].status;
      final color = status == RecitationWordStatus.correct ? const Color(0xFF1F7A4D) : const Color(0xFFC0392B);
      return TextSpan(text: word.text, style: base.copyWith(color: color.withValues(alpha: 0.55), fontWeight: FontWeight.w700));
    }
    if (index == _liveCursor && _status == _Status.listening) {
      return TextSpan(
        text: word.text,
        style: base.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColors.primary.withValues(alpha: 0.14),
        ),
      );
    }
    return TextSpan(text: word.text, style: base.copyWith(color: AppColors.textMuted.withValues(alpha: 0.65)));
  }

  // Real Android SpeechRecognizer error codes (verified against the real
  // speech_to_text plugin source) mapped to honest, non-technical Arabic
  // messages -- never a raw error code shown to the student.
  String _friendlyError(String? code, String lang) {
    switch (code) {
      case 'error_permission':
        return basicText('recitation_mic_permission_denied', lang);
      case 'error_network':
      case 'error_network_timeout':
        return basicText('recitation_network_error', lang);
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return basicText('recitation_no_arabic_locale', lang);
      default:
        return basicText('recitation_generic_error', lang);
    }
  }

  Widget _buildStatusBar(String lang) {
    switch (_status) {
      case _Status.listening:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Text(basicText('recitation_listening_status', lang), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              // Real, visible proof the microphone is actually capturing
              // speech (real device bug found 2026-08-29, Ismail: "لا يدخل
              // الصوت" -- with no visible transcript there was no way to
              // tell audio capture from a silently-stalled session).
              if (_liveWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${basicText('recitation_heard_label', lang)} ${_liveWords.join(' ')}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      case _Status.error:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Text(_friendlyError(_errorMessage, lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              TextButton(onPressed: _start, child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _Status.scoring:
        return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
      case _Status.done:
        final r = _result!;
        final percent = (r.overallScore * 100).round();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Text('${basicText('recitation_score_label', lang)}: $percent%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              if (r.ayat.any((a) => a.result.correctCount < a.result.totalExpected || a.result.extraWordCount > 0))
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecitationMistakesScreen())),
                  child: Text(basicText('recitation_mistakes_title', lang)),
                ),
            ],
          ),
        );
      case _Status.permissionDenied:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(basicText('recitation_mic_permission_denied', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        );
      case _Status.idle:
      case _Status.initializing:
      case _Status.loading:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(String lang) {
    final listening = _status == _Status.listening;
    return ElevatedButton.icon(
      onPressed: switch (_status) {
        _Status.initializing || _Status.scoring || _Status.loading => null,
        _Status.listening => _stopManually,
        _ => _start,
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
