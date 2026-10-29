import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../repositories/recitation_repository.dart';
import '../services/language_preference_service.dart';
import '../services/platform_speech_recognition_engine.dart';
import '../services/speech_recognition_engine.dart';
import '../theme/app_theme.dart';
import '../utils/recitation_alignment.dart';
import '../utils/recitation_text.dart';
import 'recitation_mistakes_screen.dart';

/// Continuous, whole-page «تسميع» — rebuilt per
/// `docs/memorization/RECITATION_REBUILD_PLAN.md` (ت0–ت3):
///
/// * the page's words are the reader's own Madinah-muṣḥaf page
///   (`mushaf_words`, by line), not the old Tanzil page (ت3);
/// * both sides are compared as plain keys, waqf signs are skipped, and the
///   isti'ādha/basmala said before reciting is not counted (ت1);
/// * each pause commits only the words that segment really covered — the rest
///   of the page stays pending, and the session waits for the student until
///   they press Stop (ت2);
/// * what is saved is exactly what was shown (ت2).
///
/// Word-level only (correct / missing / wrong / extra). No tajwīd judgement.
class PageRecitationScreen extends StatefulWidget {
  final int pageNumber;
  const PageRecitationScreen({super.key, required this.pageNumber});

  @override
  State<PageRecitationScreen> createState() => _PageRecitationScreenState();
}

enum _Status { loading, empty, idle, initializing, listening, scoring, done, permissionDenied, noRecognizer, error }

const _correctColor = Color(0xFF1F7A4D);
const _missingColor = Color(0xFFB5651D);
const _wrongColor = Color(0xFFC0392B);

class _PageRecitationScreenState extends State<PageRecitationScreen> {
  final _repo = RecitationRepository();
  final SpeechRecognitionEngine _engine = PlatformSpeechRecognitionEngine();

  List<RecitationWord> _words = [];
  List<RecitationWordStatus?> _statuses = [];
  List<String?> _said = [];
  final Map<(int, int), int> _extras = {};

  /// Words before this index are committed; the student continues from here.
  int _cursor = 0;

  /// The listening run covers `[_runStart, _runEnd)`: the whole page, or a
  /// single ayah after «أعِد هذه الآية».
  int _runStart = 0;
  int _runEnd = 0;
  bool _anySaid = false;

  /// Live, uncommitted preview of the current pause-segment.
  List<String> _liveWords = [];
  List<RecitationWordResult> _liveResult = [];

  bool _hidden = true;
  _Status _status = _Status.loading;
  PageRecitationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await _repo.pageWords(widget.pageNumber);
    if (!mounted) return;
    setState(() {
      _words = words;
      _statuses = List<RecitationWordStatus?>.filled(words.length, null);
      _said = List<String?>.filled(words.length, null);
      _status = words.isEmpty ? _Status.empty : _Status.idle;
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  List<String> get _remaining => [for (var k = _cursor; k < _runEnd; k++) _words[k].text];

  Future<void> _start({int from = 0, int? to}) async {
    setState(() {
      _status = _Status.initializing;
      _result = null;
      _cursor = from;
      _runStart = from;
      _runEnd = to ?? _words.length;
      _anySaid = false;
      for (var k = from; k < _runEnd; k++) {
        _statuses[k] = null;
        _said[k] = null;
      }
      if (from == 0) _extras.clear();
      _liveWords = [];
      _liveResult = [];
    });

    final readiness = await _engine.prepare();
    if (!mounted) return;
    if (readiness != RecognizerReadiness.ready) {
      setState(() => _status = readiness == RecognizerReadiness.permissionDenied ? _Status.permissionDenied : _Status.noRecognizer);
      return;
    }
    final arabic = await _engine.availableArabicLocaleIds();
    if (!mounted) return;
    setState(() => _status = _Status.listening);
    await _engine.startListening(
      // Some phones list no Arabic locale yet recognize it fine online: ask
      // for Saudi Arabic explicitly rather than the phone's own language.
      localeId: arabic.isNotEmpty ? arabic.first : 'ar_SA',
      // A breath between ayat must not end anything (ت2): segments close on
      // a 6 s silence and the engine reopens the next one by itself.
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      onError: (message, permanent) {
        if (!mounted) return;
        if (!permanent) {
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
        if (!mounted || _cursor >= _runEnd) return;
        final said = _withoutOpening(splitRecitedTranscript(text));
        final live = alignRecitationSegment(expectedWords: _remaining, saidWords: said);
        setState(() {
          _liveWords = said;
          _liveResult = live.words;
        });
      },
      onFinalResult: _commitSegment,
    );
  }

  /// The isti'ādha and the basmala said before starting are not part of the
  /// page (ت1, cause #3) — except on al-Fātiḥa, where the basmala is ayah 1.
  List<String> _withoutOpening(List<String> said) {
    if (_cursor != _runStart || _anySaid) return said;
    var out = said;
    for (final formula in const ['اعوذ بالله من الشيطان الرجيم', 'بسم الله الرحمن الرحيم']) {
      final f = formula.split(' ');
      final firstExpected = _cursor < _words.length ? recitationKey(_words[_cursor].text) : '';
      if (formula.startsWith('بسم') && firstExpected == 'بسم') continue;
      var k = 0;
      while (k < f.length && k < out.length && recitationWordsMatch(f[k], out[k])) {
        k++;
      }
      // Drop only a complete formula, or one still being said (a prefix of
      // a partial result) — never a lone «الله» that begins a real ayah.
      if (k == f.length || (k == out.length && k >= 2)) out = out.sublist(k);
    }
    return out;
  }

  Future<void> _commitSegment(String text) async {
    if (!mounted || _status != _Status.listening) return;
    final said = _withoutOpening(splitRecitedTranscript(text));
    if (said.isEmpty) return;
    final segment = alignRecitationSegment(expectedWords: _remaining, saidWords: said);
    final hasMistake = segment.words.any((w) => w.status != RecitationWordStatus.correct);
    if (hasMistake) HapticFeedback.mediumImpact();

    setState(() {
      _anySaid = true;
      for (var k = 0; k < segment.consumed; k++) {
        _statuses[_cursor + k] = segment.words[k].status;
        _said[_cursor + k] = segment.words[k].saidWord;
      }
      if (segment.extraWordCount > 0 && segment.consumed > 0) {
        final w = _words[_cursor + segment.consumed - 1];
        _extras[(w.surah, w.ayah)] = (_extras[(w.surah, w.ayah)] ?? 0) + segment.extraWordCount;
      }
      _cursor += segment.consumed;
      _liveWords = [];
      _liveResult = [];
    });

    if (_cursor >= _runEnd) await _finish();
  }

  Future<void> _finish() async {
    await _engine.stopListening();
    if (!mounted) return;
    setState(() => _status = _Status.scoring);
    // Save this run only (a redone ayah is a new attempt); show the whole page.
    await _repo.recordPageResult(
      words: _words,
      statuses: [for (var k = 0; k < _words.length; k++) k >= _runStart && k < _runEnd ? _statuses[k] : null],
      said: _said,
      extras: {
        for (final e in _extras.entries)
          if (_words.sublist(_runStart, _runEnd).any((w) => (w.surah, w.ayah) == e.key)) e.key: e.value,
      },
    );
    if (!mounted) return;
    setState(() {
      _result = RecitationRepository.slicePage(words: _words, statuses: _statuses, said: _said, extras: _extras);
      _status = _Status.done;
      _liveWords = [];
      _liveResult = [];
    });
  }

  Future<void> _stopManually() async {
    await _engine.stopListening();
    if (_cursor == _runStart) {
      if (!mounted) return;
      setState(() => _status = _result == null ? _Status.idle : _Status.done);
      return;
    }
    await _finish();
  }

  void _redoAyah(int surah, int ayah) {
    final from = _words.indexWhere((w) => w.surah == surah && w.ayah == ayah);
    if (from < 0) return;
    final to = _words.lastIndexWhere((w) => w.surah == surah && w.ayah == ayah) + 1;
    _extras.remove((surah, ayah));
    _start(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('${basicText('recitation_practice_title', lang)} — ${basicText('page_label', lang)} ${widget.pageNumber}'),
          actions: [
            if (_words.isNotEmpty)
              IconButton(
                tooltip: basicText('recitation_hide_text', lang),
                icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
          ],
        ),
        body: switch (_status) {
          _Status.loading => const Center(child: CircularProgressIndicator()),
          _Status.empty => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(basicText('recitation_no_page_words', lang), textAlign: TextAlign.center),
              ),
            ),
          _ => Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                    child: Column(children: [_buildPage(), if (_status == _Status.done) _buildAyahResults(lang)]),
                  ),
                ),
                _buildStatusBar(lang),
                Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: _buildActionButton(lang)),
              ],
            ),
        },
      ),
    );
  }

  /// The page as printed: the muṣḥaf's own 15 lines, one row each.
  Widget _buildPage() {
    final rows = <Widget>[];
    var k = 0;
    while (k < _words.length) {
      final line = _words[k].line;
      final spans = <InlineSpan>[];
      while (k < _words.length && _words[k].line == line) {
        spans.add(_wordSpan(k));
        final endsAyah = k + 1 >= _words.length || _words[k + 1].ayah != _words[k].ayah || _words[k + 1].surah != _words[k].surah;
        if (endsAyah) {
          spans.add(TextSpan(
            text: ' ﴿${_eastern(_words[k].ayah)}﴾',
            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 15, color: AppColors.textMuted),
          ));
        }
        spans.add(const TextSpan(text: ' '));
        k++;
      }
      rows.add(FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(textDirection: TextDirection.rtl, text: TextSpan(children: spans)),
      ));
      rows.add(const SizedBox(height: 4));
    }
    return Column(children: rows);
  }

  static String _eastern(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

  InlineSpan _wordSpan(int index) {
    const base = TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.0, color: AppColors.textDark);
    final word = _words[index].text;
    final status = _statuses[index];

    if (status != null) {
      final color = switch (status) {
        RecitationWordStatus.correct => _correctColor,
        RecitationWordStatus.missing => _missingColor,
        RecitationWordStatus.wrong => _wrongColor,
      };
      return TextSpan(
        text: word,
        style: base.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          decoration: status == RecitationWordStatus.correct ? null : TextDecoration.underline,
          decorationStyle: TextDecorationStyle.wavy,
          decorationColor: color,
        ),
      );
    }

    final liveIdx = index - _cursor;
    if (_status == _Status.listening && liveIdx >= 0 && liveIdx < _liveResult.length) {
      final live = _liveResult[liveIdx].status;
      final color = live == RecitationWordStatus.correct ? _correctColor : _wrongColor;
      return TextSpan(text: word, style: base.copyWith(color: color.withValues(alpha: 0.55), fontWeight: FontWeight.w700));
    }
    if (_status == _Status.listening && index == _cursor + _liveResult.length) {
      return TextSpan(
        text: _hidden ? '•••' : word,
        style: base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, backgroundColor: AppColors.primary.withValues(alpha: 0.14)),
      );
    }
    // Recite from memory: words not reached yet are covered.
    if (_hidden && index >= _cursor && _status != _Status.done) {
      return TextSpan(text: word, style: base.copyWith(color: AppColors.textMuted.withValues(alpha: 0.08)));
    }
    return TextSpan(text: word, style: base.copyWith(color: AppColors.textMuted.withValues(alpha: 0.65)));
  }

  /// One row per recited ayah: complete, or what went wrong, and a one-tap
  /// «أعِد هذه الآية».
  Widget _buildAyahResults(String lang) {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    final notReached = _statuses.where((s) => s == null).length;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in r.ayat)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: Icon(
                  _ayahOk(a) ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: _ayahOk(a) ? _correctColor : _wrongColor,
                ),
                title: Text('﴿${_eastern(a.ayah)}﴾  ${_ayahLabel(a, lang)}'),
                trailing: _ayahOk(a)
                    ? null
                    : TextButton(onPressed: () => _redoAyah(a.surah, a.ayah), child: Text(basicText('recitation_redo_ayah', lang))),
              ),
            ),
          if (notReached > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                basicText('recitation_not_reached', lang).replaceAll('{n}', '$notReached'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  static bool _ayahOk(AyahRecitationSlice a) => a.result.correctCount == a.result.totalExpected && a.result.extraWordCount == 0;

  String _ayahLabel(AyahRecitationSlice a, String lang) {
    if (a.result.correctCount < a.result.totalExpected) return basicText('recitation_ayah_has_mistake', lang);
    if (a.result.extraWordCount > 0) return basicText('recitation_ayah_has_extra', lang);
    return basicText('recitation_ayah_perfect', lang);
  }

  // Real Android SpeechRecognizer error codes mapped to honest messages —
  // never a raw error code shown to the student.
  String _friendlyError(String? code, String lang) {
    switch (code) {
      case 'error_permission':
      case 'error_insufficient_permissions':
        return basicText('recitation_mic_permission_denied', lang);
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        return basicText('recitation_network_error', lang);
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return basicText('recitation_no_arabic_locale', lang);
      default:
        return basicText('recitation_generic_error', lang);
    }
  }

  Widget _message(String text, {bool retry = false, String lang = 'ar'}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            if (retry) TextButton(onPressed: () => _start(from: _cursor, to: _runEnd > _cursor ? _runEnd : null), child: Text(basicText('retry_action', lang))),
          ],
        ),
      );

  Widget _buildStatusBar(String lang) {
    switch (_status) {
      case _Status.listening:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Text(basicText('recitation_listening_status', lang), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              Text(basicText('recitation_pause_hint', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
        return _message(_friendlyError(_errorMessage, lang), retry: true, lang: lang);
      case _Status.permissionDenied:
        return _message(basicText('recitation_mic_permission_denied', lang), retry: true, lang: lang);
      case _Status.noRecognizer:
        return _message(basicText('recitation_no_recognizer', lang), retry: true, lang: lang);
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
              if (r.ayat.any((a) => !_ayahOk(a)))
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecitationMistakesScreen())),
                  child: Text(basicText('recitation_mistakes_title', lang)),
                ),
            ],
          ),
        );
      case _Status.idle:
      case _Status.initializing:
      case _Status.loading:
      case _Status.empty:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(String lang) {
    final listening = _status == _Status.listening;
    return ElevatedButton.icon(
      onPressed: switch (_status) {
        _Status.initializing || _Status.scoring || _Status.loading => null,
        _Status.listening => _stopManually,
        _ => () => _start(),
      },
      icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
      label: Text(listening ? basicText('recitation_stop_action', lang) : basicText('recitation_start_action', lang)),
      style: ElevatedButton.styleFrom(
        backgroundColor: listening ? _wrongColor : AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
