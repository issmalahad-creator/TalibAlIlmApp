import 'package:flutter/material.dart';

import '../data/life_plan_suggestions.dart';
import '../l10n/basic_translations.dart';
import '../theme/app_theme.dart';

/// The «ابدأ خطتك» picker (2026‑11‑12): one row per suggestion pack, with
/// its time-blocks under it, all ticked by default; «أضف المختار» hands the
/// chosen packs back. Used on the empty «اليوم» screen and from the plan
/// editor's «أضف من الاقتراحات».
class LifeSuggestionPicker extends StatefulWidget {
  final List<LifeSuggestionPack> packs;
  final String lang;
  final ValueChanged<List<LifeSuggestionPack>> onAdd;

  const LifeSuggestionPicker({
    super.key,
    required this.packs,
    required this.lang,
    required this.onAdd,
  });

  @override
  State<LifeSuggestionPicker> createState() => _LifeSuggestionPickerState();
}

class _LifeSuggestionPickerState extends State<LifeSuggestionPicker> {
  late final Set<String> _chosen = {for (final p in widget.packs) p.key};

  // the time pair is isolated LTR (U+2066…U+2069) so it doesn't swap
  // around the dash inside RTL text
  static final _lri = String.fromCharCode(0x2066);
  static final _pdi = String.fromCharCode(0x2069);

  String _times(LifeSuggestionPack p) => [
        for (final (i, s) in p.slots(widget.lang).indexed)
          '$_lri${s.timeLabel}$_pdi  ${basicText(p.blocks[i].$3, widget.lang)}',
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (widget.packs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(basicText('life_sug_none_left', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final p in widget.packs)
            CheckboxListTile(
              value: _chosen.contains(p.key),
              onChanged: (v) => setState(
                  () => v == true ? _chosen.add(p.key) : _chosen.remove(p.key)),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('${p.emoji} ${p.label(lang)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_times(p),
                  style: const TextStyle(fontSize: 12, height: 1.5)),
              isThreeLine: p.blocks.length > 1,
            ),
        ]),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _chosen.isEmpty
              ? null
              : () => widget.onAdd(
                  [for (final p in widget.packs) if (_chosen.contains(p.key)) p]),
          icon: const Icon(Icons.add_rounded),
          label: Text(basicText('life_start_add_selected', lang)),
        ),
      ),
    ]);
  }
}
