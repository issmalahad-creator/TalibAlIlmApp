import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/akhlaq.dart';
import '../../repositories/akhlaq_repository.dart';
import '../../services/akhlaq/akhlaq_content.dart';
import '../../services/akhlaq/akhlaq_engine.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';

/// AKHLAQ · P4 — one training scenario for the الرِّفق slice.
///
/// Recognition → deliberate response selection → sourced feedback →
/// reflection prompt. The result panel names the response's **verdict**
/// (aqrab / maqbul / baid) in words; it is never a score, a percentage,
/// or a judgement on the person (`AKHLAQ_SYSTEM_PHILOSOPHY §6/§7`).
class AkhlaqScenarioScreen extends StatefulWidget {
  final String scenarioId;
  const AkhlaqScenarioScreen({super.key, required this.scenarioId});

  @override
  State<AkhlaqScenarioScreen> createState() => _AkhlaqScenarioScreenState();
}

class _AkhlaqScenarioScreenState extends State<AkhlaqScenarioScreen> {
  final _repo = AkhlaqRepository();

  String get _lang => LanguagePreferenceService.currentLanguage;

  bool _loading = true;
  AkhlaqSlice? _slice;
  AkhlaqScenario? _scenario;
  String? _chosenKey;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slice = await _repo.slice();
    setState(() {
      _slice = slice;
      _scenario = slice?.scenarioById(widget.scenarioId);
      _loading = false;
    });
  }

  Future<void> _choose(String key) async {
    if (_recording || _chosenKey != null || _scenario == null) return;
    setState(() => _recording = true);
    await _repo.recordAttempt(scenario: _scenario!, chosenKey: key);
    if (!mounted) return;
    setState(() {
      _chosenKey = key;
      _recording = false;
    });
  }

  Future<void> _another() async {
    final sc = _scenario;
    final slice = _slice;
    if (sc == null || slice == null) return;
    final sub = sc.subskills.isNotEmpty ? sc.subskills.first : '';
    final attempts = await _repo.attempts();
    final prog = rollSubskillTrend(subskill: sub, attempts: attempts);
    final srList = await _repo.srStates();
    final sr = srList.where((s) => s.subskill == sub).toList();
    final diff = sr.isEmpty ? sc.difficulty : sr.first.difficulty;
    final next = pickNextScenario(
      subskill: sub,
      difficulty: diff,
      slice: slice,
      attempts: attempts,
      weakDimension: prog.weakDimension,
    );
    if (!mounted) return;
    if (next == null || next == sc.id) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AkhlaqScenarioScreen(scenarioId: next)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(basicText('akhlaq_home_title', _lang))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _scenario == null
                ? Center(child: Text(basicText('akhlaq_no_plan', _lang)))
                : _body(_scenario!),
      ),
    );
  }

  Widget _body(AkhlaqScenario sc) {
    final chosen = _chosenKey == null ? null : sc.optionByKey(_chosenKey!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Row(
          children: [
            _chip('${basicText('akhlaq_scenario_level', _lang)} ${sc.difficulty}'),
            const SizedBox(width: 8),
            if (sc.composite) _chip(basicText('akhlaq_composite', _lang)),
          ],
        ),
        const SizedBox(height: 4),
        Text(basicText('akhlaq_level_note', _lang),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(sc.stemAr,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      height: 1.8,
                      color: AppColors.textDark)),
              _translationLine(refKind: 'scenario', refId: sc.id, layer: 'stem'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(basicText('akhlaq_choose', _lang),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 10),
        for (final o in sc.options) _optionCard(sc.id, o),
        if (chosen != null) ...[
          const SizedBox(height: 20),
          _resultPanel(sc, chosen),
        ],
      ],
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
      );

  Widget _optionCard(String scenarioId, AkhlaqOption o) {
    final locked = _chosenKey != null;
    final isChosen = _chosenKey == o.key;
    Color border = AppColors.divider;
    Color bg = AppColors.surface;
    if (locked) {
      final c = _verdictColor(o.verdict);
      if (isChosen) {
        border = c;
        bg = c.withValues(alpha: 0.08);
      } else if (o.verdict == 'aqrab') {
        border = c.withValues(alpha: 0.5); // always reveal the closest one
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: locked || _recording ? null : () => _choose(o.key),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isChosen ? 1.8 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${o.key}. ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.textAr,
                        style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            height: 1.7,
                            color: AppColors.textDark)),
                    _translationLine(
                        refKind: 'scenario_option',
                        refId: '$scenarioId:${o.key}',
                        layer: 'text'),
                  ],
                ),
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 2),
                  child: Text(_verdictShort(o.verdict),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _verdictColor(o.verdict))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultPanel(AkhlaqScenario sc, AkhlaqOption chosen) {
    final c = _verdictColor(chosen.verdict);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_verdictLong(chosen.verdict),
              style: TextStyle(fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          _label(basicText('akhlaq_why', _lang)),
          Text(chosen.whyAr,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  height: 1.7,
                  color: AppColors.textDark)),
          _translationLine(
              refKind: 'scenario_option',
              refId: '${sc.id}:${chosen.key}',
              layer: 'why'),
          if (sc.feedbackAr.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(basicText('akhlaq_full_feedback', _lang)),
            Text(sc.feedbackAr,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.textDark)),
            _translationLine(refKind: 'scenario', refId: sc.id, layer: 'feedback'),
          ],
          const SizedBox(height: 12),
          _label(basicText('akhlaq_evidence', _lang)),
          for (final id in chosen.evidence) _evidenceBlock(id),
          if (sc.probeAr.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(basicText('akhlaq_probe', _lang)),
            Text(sc.probeAr,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.textDark)),
            _translationLine(refKind: 'scenario', refId: sc.id, layer: 'probe'),
          ],
          if (sc.reflectionAr.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(basicText('akhlaq_reflect', _lang)),
            Text(sc.reflectionAr,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.textDark)),
            _translationLine(refKind: 'scenario', refId: sc.id, layer: 'reflection'),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _another,
                  child: Text(basicText('akhlaq_another', _lang)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(basicText('akhlaq_done', _lang)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A real translation of `(refKind, refId, layer)` for the current app
  /// language, shown directly under the Arabic it belongs to — never
  /// merged into it, never shown when none exists (`AkhlaqContent
  /// .translation` already returns null rather than fabricate one).
  Widget _translationLine(
      {required String refKind, required String refId, required String layer}) {
    final tr = AkhlaqContent.instance
        .translation(refKind: refKind, refId: refId, layer: layer, lang: _lang);
    if (tr == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(tr.text,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
              fontSize: 12.5, height: 1.5, color: AppColors.textMuted)),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted)),
      );

  Widget _evidenceBlock(String id) {
    final ev = _slice?.evidenceById(id);
    if (ev == null) return const SizedBox.shrink();
    final tr = AkhlaqContent.instance.translation(
        refKind: 'evidence', refId: id, layer: 'text', lang: _lang);
    final srcLine = [
      ev.book,
      if (ev.hadithId.isNotEmpty) '#${ev.hadithId}',
      if (ev.page.isNotEmpty) 'ص${ev.page}',
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ev.textAr,
                style: TextStyle(
                    fontFamily: ev.isQuran ? 'AmiriQuran' : 'Amiri',
                    fontSize: ev.isQuran ? 18 : 16,
                    height: 1.9,
                    color: AppColors.textDark)),
            if (srcLine.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(srcLine,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
            if (ev.isMarfu && ev.grading.trim().isNotEmpty)
              Text('${basicText('akhlaq_grading', _lang)}: ${ev.grading}'
                  '${ev.grader.isNotEmpty ? ' — ${ev.grader}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            if (tr != null) ...[
              const SizedBox(height: 6),
              Text(tr.text,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textMuted)),
              Text(basicText('akhlaq_source_hint', _lang),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Color _verdictColor(String v) {
    switch (v) {
      case 'aqrab':
        return const Color(0xFF2E7D32);
      case 'maqbul':
        return const Color(0xFFB07D18);
      default:
        return const Color(0xFFB3261E);
    }
  }

  String _verdictShort(String v) =>
      basicText('akhlaq_verdict_short_$v', _lang);

  String _verdictLong(String v) {
    switch (v) {
      case 'aqrab':
        return basicText('akhlaq_verdict_aqrab', _lang);
      case 'maqbul':
        return basicText('akhlaq_verdict_maqbul', _lang);
      default:
        return basicText('akhlaq_verdict_baid', _lang);
    }
  }
}
