import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// Picks a whole hour (0–23). For settings that are stored and scheduled
/// by the hour only — a full time picker there let the user choose 8:30
/// and silently fired at 8:00.
Future<int?> showHourPicker(BuildContext context, {required int initialHour, String? title}) {
  final lang = LanguagePreferenceService.currentLanguage;
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? basicText('pick_hour_title', lang)),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            for (var h = 0; h < 24; h++)
              Material(
                color: h == initialHour ? AppColors.primary : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, h),
                  child: Center(
                    child: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: h, minute: 0)),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: h == initialHour ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
