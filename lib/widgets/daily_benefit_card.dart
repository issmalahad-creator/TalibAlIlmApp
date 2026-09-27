import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../services/daily_benefit_service.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'feedback/light_trail.dart';
import 'feedback/talib_pressable.dart';

/// Home «فائدة اليوم / حديث اليوم / ذكر اليوم / آية اليوم» — a fresh sourced
/// item on every launch (different from the splash's), with «أخرى» for
/// another one and copy. Reads only the small bundled pool; no DB, no
/// network, so it never slows Home.
class DailyBenefitCard extends StatefulWidget {
  const DailyBenefitCard({super.key});

  @override
  State<DailyBenefitCard> createState() => _DailyBenefitCardState();
}

class _DailyBenefitCardState extends State<DailyBenefitCard> {
  DailyBenefit? _benefit;

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    try {
      final b = await DailyBenefitService.instance.next();
      if (mounted) setState(() => _benefit = b);
    } catch (e) {
      debugPrint('DailyBenefitCard: $e');
    }
  }

  Future<void> _copy(DailyBenefit b, String lang) async {
    await Clipboard.setData(ClipboardData(text: '${b.text}\n— ${b.source}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(basicText('benefit_copied', lang)), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final b = _benefit;
    if (b == null) return const SizedBox.shrink(); // a few ms at most; no placeholder flash
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: kLightTrailGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    basicText('benefit_today_${b.kind}', lang),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Column(
                key: ValueKey(b.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    b.text,
                    textDirection: TextDirection.rtl,
                    textAlign: b.isAyah ? TextAlign.center : TextAlign.start,
                    style: b.isAyah
                        ? AppTextStyles.quranBody.copyWith(fontSize: 19)
                        : const TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.source,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: basicText('benefit_copy', lang),
                  icon: const Icon(Icons.copy_rounded, size: 19),
                  onPressed: () => _copy(b, lang),
                ),
                TalibPressable(
                  onTap: null,
                  child: TextButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(basicText('benefit_another', lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
