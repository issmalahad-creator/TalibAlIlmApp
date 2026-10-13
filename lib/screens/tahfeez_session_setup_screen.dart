import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

import '../data/quran_surahs.dart';
import '../models/tahfeez_session_config.dart';
import '../services/quran_audio/quran_audio_provider_registry.dart';
import '../services/tahfeez_session_prefs.dart';
import '../theme/app_theme.dart';
import 'tahfeez_playback_screen.dart';

/// "التحفيظ" setup — Ismail's P0 request, mirroring the reference
/// screenshot's fields (قارئ، نطاق آيات من/إلى، تكرار نطاق الآيات، تكرار
/// الآية الواحدة، طول السكتة) with this app's own visual style, not a
/// copy of the reference's look.
class TahfeezSessionSetupScreen extends StatefulWidget {
  const TahfeezSessionSetupScreen({super.key});

  @override
  State<TahfeezSessionSetupScreen> createState() => _TahfeezSessionSetupScreenState();
}

class _TahfeezSessionSetupScreenState extends State<TahfeezSessionSetupScreen> {
  late String _reciterId;
  int _surahFrom = 1;
  int _ayahFrom = 1;
  int _surahTo = 1;
  int _ayahTo = 7;
  int _rangeRepeatCount = 3;
  int _singleAyahRepeatCount = 0;
  double _silenceMultiplier = 1.0;
  bool _hasResumable = false;

  @override
  void initState() {
    super.initState();
    _reciterId = QuranAudioProviderRegistry.reciters().first.id;
    _checkResumable();
  }

  Future<void> _checkResumable() async {
    final saved = await TahfeezSessionPrefs().load();
    if (!mounted) return;
    setState(() => _hasResumable = saved != null);
  }

  int _ayahCountOf(int surah) => quranSurahs.firstWhere((s) => s.number == surah).ayahCount;

  void _onSurahFromChanged(int surah) {
    setState(() {
      _surahFrom = surah;
      _ayahFrom = 1;
      if (_surahTo < _surahFrom) _surahTo = _surahFrom;
      if (_surahTo == _surahFrom && _ayahTo < _ayahFrom) _ayahTo = _ayahFrom;
    });
  }

  void _onSurahToChanged(int surah) {
    setState(() {
      _surahTo = surah;
      _ayahTo = _ayahCountOf(surah);
      if (_surahTo < _surahFrom) _surahFrom = _surahTo;
    });
  }

  void _start() {
    final config = TahfeezSessionConfig(
      reciterId: _reciterId,
      surahFrom: _surahFrom,
      ayahFrom: _ayahFrom,
      surahTo: _surahTo,
      ayahTo: _ayahTo,
      rangeRepeatCount: _rangeRepeatCount,
      singleAyahRepeatCount: _singleAyahRepeatCount,
      silenceMultiplier: _silenceMultiplier,
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => TahfeezPlaybackScreen(config: config)));
  }

  void _resume() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TahfeezPlaybackScreen(resume: true)));
  }

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  Widget build(BuildContext context) {
    final reciters = QuranAudioProviderRegistry.reciters();
    return Scaffold(
      appBar: AppBar(title: Text(basicText('mushaf_section_tahfeez', _lang))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_hasResumable) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                  Expanded(child: Text(basicText('tz_resume_banner', _lang), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  TextButton(onPressed: _resume, child: Text(basicText('pk_resume', _lang))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionLabel(basicText('tz_pick_reciter', _lang)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _reciterId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: reciters.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nameAr))).toList(),
            onChanged: (v) => setState(() => _reciterId = v ?? _reciterId),
          ),
          const SizedBox(height: 20),
          _SectionLabel(basicText('tz_range', _lang)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SurahAyahPicker(label: basicText('life_field_start', _lang), surah: _surahFrom, ayah: _ayahFrom, onSurahChanged: _onSurahFromChanged, onAyahChanged: (a) => setState(() => _ayahFrom = a))),
              const SizedBox(width: 10),
              Expanded(child: _SurahAyahPicker(label: basicText('life_field_end', _lang), surah: _surahTo, ayah: _ayahTo, onSurahChanged: _onSurahToChanged, onAyahChanged: (a) => setState(() => _ayahTo = a))),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(basicText('tz_repetition', _lang)),
          const SizedBox(height: 8),
          _Stepper(label: basicText('tz_repeat_range', _lang), value: _rangeRepeatCount, min: 1, max: 20, suffix: basicText('times_count_suffix', _lang), onChanged: (v) => setState(() => _rangeRepeatCount = v)),
          const SizedBox(height: 10),
          _Stepper(label: basicText('tz_repeat_ayah', _lang), value: _singleAyahRepeatCount, min: 0, max: 20, suffix: _singleAyahRepeatCount == 0 ? basicText('tz_none', _lang) : basicText('times_count_suffix', _lang), onChanged: (v) => setState(() => _singleAyahRepeatCount = v)),
          const SizedBox(height: 10),
          _DoubleStepper(label: basicText('tz_silence', _lang), value: _silenceMultiplier, min: 0.5, max: 4, step: 0.5, onChanged: (v) => setState(() => _silenceMultiplier = v)),
          const SizedBox(height: 28),
          FilledButton(onPressed: _start, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(basicText('tz_start', _lang)))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted));
}

class _SurahAyahPicker extends StatelessWidget {
  final String label;
  final int surah;
  final int ayah;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<int> onAyahChanged;
  const _SurahAyahPicker({required this.label, required this.surah, required this.ayah, required this.onSurahChanged, required this.onAyahChanged});

  @override
  Widget build(BuildContext context) {
    final ayahCount = quranSurahs.firstWhere((s) => s.number == surah).ayahCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          DropdownButton<int>(
            isExpanded: true,
            value: surah,
            underline: const SizedBox.shrink(),
            items: quranSurahs.map((s) => DropdownMenuItem(value: s.number, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => onSurahChanged(v ?? surah),
          ),
          DropdownButton<int>(
            isExpanded: true,
            value: ayah.clamp(1, ayahCount),
            underline: const SizedBox.shrink(),
            items: List.generate(ayahCount, (i) => i + 1).map((a) => DropdownMenuItem(value: a, child: Text(basicText('tz_ayah_n', LanguagePreferenceService.currentLanguage).replaceAll('{n}', '$a'), style: const TextStyle(fontSize: 12.5)))).toList(),
            onChanged: (v) => onAyahChanged(v ?? ayah),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.suffix, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: value > min ? () => onChanged(value - 1) : null),
          SizedBox(width: 60, child: Text('$value $suffix', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _DoubleStepper extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  const _DoubleStepper({required this.label, required this.value, required this.min, required this.max, required this.step, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: value > min ? () => onChanged(value - step) : null),
          SizedBox(width: 60, child: Text('${value.toStringAsFixed(1)}×', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: value < max ? () => onChanged(value + step) : null),
        ],
      ),
    );
  }
}
