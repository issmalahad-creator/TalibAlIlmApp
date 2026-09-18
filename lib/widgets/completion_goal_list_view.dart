import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../l10n/basic_translations.dart';
import '../models/completion_goal_session.dart';
import '../models/personal_book.dart';
import '../repositories/book_repository.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/personal_book_repository.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_display.dart';
import '../utils/hijri_date.dart';
import 'circular_percent_gauge.dart';
import 'completion_goal_session_editor.dart';
import 'completion_goal_werd_list.dart';
import 'loading_view.dart';

/// (content_type, book_ref, label, total_units) — the fixed set of
/// content this planner currently knows how to track. Add a row here when
/// a new book pillar ships. Personal-library books are appended
/// dynamically (see `_personalBookOptions`) since they vary per student.
// Labels starting with '@' are translation keys resolved via basicText() at
// display time (see `_resolveOptionLabel`); the rest are book/curriculum
// proper nouns that stay Arabic — real classical-text titles, not chrome.
const _fixedGoalOptions = [
  ('quran_reading', null, '@goal_quran_reading_label', 604),
  ('quran_memorization', null, '@goal_quran_memorization_label', 604),
  ('book', 'zad_almaad', 'زاد المعاد', 65),
  ('book', 'madarij', 'مدارج السالكين', 71),
  ('book', 'wasitiyyah', 'العقيدة الواسطية', 82),
  ('book', 'nawawi_hadith', 'الأربعين النووية', 42),
];

String _resolveOptionLabel(String label, String lang) => label.startsWith('@') ? basicText(label.substring(1), lang) : label;

/// The only two content types with a "juz"/page-range concept at all — used
/// both by the wizard's range slider and (§2.5) the werd-boundary list.
bool _isPageBasedGoal(String contentType) => contentType == 'quran_reading' || contentType == 'quran_memorization';

/// §2.3 field 3 — the "تحزيب الصحابة" info dialog's body, verbatim per
/// Ismail's exact instruction ("بلا أي إعادة صياغة"): a hadith citation +
/// scholarly framing, not chrome — kept Arabic-only regardless of app
/// language, same treatment as the classical book titles above.
const _kTahzeebInfoText =
    'نُقل عن السلف من الصحابة رضي الله عنهم قراءتهم للقرآن في سبعة أيام '
    'لحديث عبدالله بن عمرو: (... واقرأ في كل سبع ليال مرة ...) [صحيح '
    'البخاري، 5.052]، وقد عُرف عند العلماء بـ"تحزيب الصحابة"، وهو تقسيم '
    'القرآن إلى سبعة أوراد تُقرأ في سبعة أيام، اختُصرت بكلمة "فمي بشوق" '
    'اختصارًا للحروف الأولى للسور التي تبدأ بها الأوراد: الفاتحة، المائدة، '
    'يونس، بني إسرائيل-الإسراء، الشعراء، والصافات، ثم ق إلى آخر المصحف.';

/// Personal-library books that have a known page count (from having been
/// opened at least once — `book_bookmarks` is populated by
/// `BookViewerScreen`'s existing flutter_pdfview callbacks, not built new
/// here). Books never opened yet are silently excluded rather than shown
/// with a guessed page count.
Future<List<(String, String?, String, int)>> _personalBookOptions(String lang) async {
  final books = await PersonalBookRepository().all();
  final bookRepo = BookRepository();
  final options = <(String, String?, String, int)>[];
  for (final book in books) {
    if (book.id == null) continue;
    final bookmark = await bookRepo.getBookmark('personal_${book.id}');
    if (bookmark != null && bookmark.totalPages > 0) {
      options.add(('personal_book', book.id.toString(), '${basicText('from_my_library_prefix', lang)} ${book.title}', bookmark.totalPages));
    }
  }
  return options;
}

/// The single "إنشاء خطة ختم" creation wizard — shared by the full "خطط
/// ختمي" screen's "+" FAB and the mushaf reader's "الختمات" bottom sheet
/// (Ismail 2026-09-16: "أضف التحكم أيضًا من popup يعني المستخدم لا يضطر
/// الذهاب والعودة" — don't make the reader user leave and come back to
/// create a plan). Exactly one implementation; callers only differ in what
/// they do with [onCreated] (typically reloading their own
/// `CompletionGoalListView` via its `GlobalKey`).
/// [lockedContentType], when passed, fixes the plan to that one
/// `content_type` (e.g. the mushaf reader's "الختمات" popup only ever
/// creates `quran_reading` plans — the type picker + "أضف من مكتبتك" hint
/// would be dead weight there) and hides the type picker entirely. The
/// full "خطط ختمي" screen calls this with no lock, so its picker (reading
/// vs memorization vs any book, personal library included) is unchanged.
Future<void> openNewCompletionGoalSheet(BuildContext context, {VoidCallback? onCreated, String? lockedContentType}) async {
  final lang = LanguagePreferenceService.currentLanguage;
  final personalOptions = lockedContentType == null ? await _personalBookOptions(lang) : <(String, String?, String, int)>[];
  final allOptions = [..._fixedGoalOptions, ...personalOptions];
  var selected = lockedContentType == null ? allOptions.first : allOptions.firstWhere((o) => o.$1 == lockedContentType);
  // §2.3 field 5 — a day-count stepper replaces the raw calendar picker;
  // `target_date` is only ever computed internally from this at creation
  // time (today + durationDays), never shown to the user as a date here.
  // `durationDays` is the source of truth used at creation; `durationController`
  // is kept in sync with it (both directions) so typing a number directly
  // and tapping −/+ never disagree.
  int durationDays = 30;
  final durationController = TextEditingController(text: '30');
  final repo = CompletionGoalRepository();

  // §2.3 field 4 — a juz-to-juz range, quran_reading/quran_memorization
  // only (the only content types with a "juz" concept at all; book goals
  // keep their fixed whole-book totalUnits, no slider shown for them).
  // Kept as juz numbers while the sheet is open — converted to real mushaf
  // pages via `MushafLayoutRepository.pageForJuz()` once, only at "إنشاء
  // الخطة" time, not on every drag frame (avoids a DB round-trip per pixel).
  RangeValues juzRange = const RangeValues(1, 30);
  bool isQuranRange(String contentType) => contentType == 'quran_reading' || contentType == 'quran_memorization';

  // §2.3 field 3, grain "تحزيب الصحابة" toggle — a one-time convenience
  // fill (full range + 7-day duration), not a lock: both stay freely
  // editable afterward, and this grain does NOT compute the seven واجب
  // boundaries themselves (that's the ورد map, a later grain) — only the
  // two field fills + the info text.
  bool tahzeebEnabled = false;

  // §2.3 grain 3.1 — the two simplest fields: an explicit colour pick
  // (null until tapped, so the existing cyclic stripe colour still applies
  // if the user never touches this) and a free-text name pre-filled with
  // the spec's suggested default ("ختمتي - <today>"), which is what gets
  // saved if the user leaves it untouched — only an explicitly emptied
  // field falls back to the auto-derived label.
  int? selectedColorIndex;
  final nameController = TextEditingController(
    text: '${basicText('khatm_default_name_prefix', lang)} - ${formatDateForDisplay(hijriDateStringForDate(DateTime.now()))}',
  );

  // §2.3 field 7أ — "توزيع الورد على الصلوات": off by default (keeps the
  // existing single daily-target behaviour unchanged for anyone who
  // doesn't opt in). `sessions` is only ever non-empty while the toggle is
  // on and a pattern has been chosen; persisted via `replaceSessions()`
  // right after `repo.create()` below.
  bool sessionsEnabled = false;
  List<CompletionGoalSession> sessions = const [];

  // A live estimate for the session editor's pattern previews — computed
  // from the juz range as a page-per-juz approximation (604/30), the same
  // "no DB round-trip while the sheet is open" rule the range slider itself
  // already follows (see field 4's comment above); the exact daily_target
  // (via `MushafLayoutRepository.pageForJuz()`) is only ever computed once,
  // at "إنشاء الخطة" time, same as before.
  int estimatedDailyTarget() {
    final (contentType, _, _, totalUnitsOpt) = selected;
    final days = durationDays < 1 ? 1 : durationDays;
    if (isQuranRange(contentType)) {
      final juzCount = (juzRange.end - juzRange.start + 1).round();
      return ((juzCount * 604 / 30) / days).ceil();
    }
    return (totalUnitsOpt / days).ceil();
  }

  // §2.3 field 8 — "وقت التذكير": a toggle + a time picker, per-goal.
  // Defaults (ON, 20:00) match the app's original one-size-fits-all fixed
  // reminder hour exactly, so a user who never touches this field gets
  // identical behaviour to every goal created before this field existed.
  bool reminderEnabled = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        // §2.3 field 8 pushed the wizard's total height (color+name+range+
        // tahzeeb+duration+reminder+create button) past the screen when the
        // keyboard is up for a text field near the bottom (confirmed live —
        // a real, if small, RenderFlex overflow) — SingleChildScrollView,
        // not a taller sheet: the fields don't need to shrink, only scroll.
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(basicText('new_completion_plan_title', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < kKhatmTabColors.length; i++)
                  GestureDetector(
                    onTap: () => setSheetState(() => selectedColorIndex = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: kKhatmTabColors[i]),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: 2,
                          color: selectedColorIndex == i ? AppColors.primary : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(basicText('khatm_name_field_label', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: nameController),
            const SizedBox(height: 16),
            if (lockedContentType == null)
              DropdownButton<(String, String?, String, int)>(
                isExpanded: true,
                value: selected,
                items: allOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(_resolveOptionLabel(o.$3, lang), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selected = v!),
              ),
            if (lockedContentType == null && personalOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  basicText('add_library_book_hint', lang),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            if (isQuranRange(selected.$1)) ...[
              const SizedBox(height: 16),
              Text(
                '${basicText('khatm_range_field_label', lang)}: ${basicText('juz_label', lang)} ${juzRange.start.round()} → ${basicText('juz_label', lang)} ${juzRange.end.round()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              RangeSlider(
                min: 1,
                max: 30,
                divisions: 29,
                labels: RangeLabels('${juzRange.start.round()}', '${juzRange.end.round()}'),
                values: juzRange,
                onChanged: (v) => setSheetState(() => juzRange = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(basicText('khatm_tahzeeb_toggle_label', lang), style: const TextStyle(fontSize: 13)),
                      value: tahzeebEnabled,
                      onChanged: (v) => setSheetState(() {
                        tahzeebEnabled = v;
                        // A convenience fill, not a lock — both stay
                        // freely editable afterward (per instruction).
                        if (v) {
                          juzRange = const RangeValues(1, 30);
                          durationDays = 7;
                          durationController.text = '7';
                        }
                      }),
                    ),
                  ),
                  IconButton(
                    tooltip: basicText('khatm_tahzeeb_info_tooltip', lang),
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(basicText('khatm_tahzeeb_toggle_label', lang)),
                        // Verbatim hadith citation + scholarly framing —
                        // kept Arabic-only regardless of app language, same
                        // as the classical book titles in
                        // `_fixedGoalOptions`: real quoted/classical
                        // content, not translatable UI chrome.
                        content: const SingleChildScrollView(child: Text(_kTahzeebInfoText, style: TextStyle(fontSize: 13, height: 1.6))),
                        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(basicText('onboarding_close', lang)))],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(basicText('khatm_duration_field_label', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: durationDays > 1
                      ? () => setSheetState(() {
                            durationDays--;
                            durationController.text = '$durationDays';
                          })
                      : null,
                ),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: durationController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                    // A value < 1 (or an empty/unparsable field, since
                    // digitsOnly already blocks "-") is silently ignored —
                    // durationDays just keeps its last valid value rather
                    // than crashing or accepting a bad plan length.
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 1) {
                        setSheetState(() => durationDays = parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setSheetState(() {
                    durationDays++;
                    durationController.text = '$durationDays';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(basicText('khatm_session_distribution_toggle_label', lang), style: const TextStyle(fontSize: 13)),
              value: sessionsEnabled,
              onChanged: (v) => setSheetState(() {
                sessionsEnabled = v;
                sessions = const [];
              }),
            ),
            if (sessionsEnabled)
              CompletionGoalSessionEditor(
                // A fresh estimate — and a fresh pattern-choice screen —
                // every time the range/duration changes; see
                // `estimatedDailyTarget()`'s own doc comment for why a
                // session list can't silently survive that.
                key: ValueKey(estimatedDailyTarget()),
                dailyTarget: estimatedDailyTarget(),
                onChanged: (next) => sessions = next,
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(basicText('khatm_reminder_toggle_label', lang), style: const TextStyle(fontSize: 13)),
              value: reminderEnabled,
              onChanged: (v) => setSheetState(() => reminderEnabled = v),
            ),
            if (reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, size: 20),
                title: Text(basicText('khatm_reminder_time_label', lang), style: const TextStyle(fontSize: 13)),
                trailing: Text(reminderTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: reminderTime);
                  if (picked != null) setSheetState(() => reminderTime = picked);
                },
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final (contentType, bookRef, _, totalUnits) = selected;
                final typedName = nameController.text.trim();
                int? startUnit;
                int? endUnit;
                if (isQuranRange(contentType)) {
                  final startJuz = juzRange.start.round();
                  final endJuz = juzRange.end.round();
                  final layoutRepo = MushafLayoutRepository();
                  startUnit = await layoutRepo.pageForJuz(startJuz);
                  // No juz 31 to derive the end from — the last mushaf page
                  // is a known constant, not another pageForJuz() call.
                  if (endJuz == 30) {
                    endUnit = 604;
                  } else {
                    final nextJuzStart = await layoutRepo.pageForJuz(endJuz + 1);
                    endUnit = nextJuzStart == null ? null : nextJuzStart - 1;
                  }
                  // A half-resolved range (one lookup failed) is worse than
                  // none — fall back to the full mushaf rather than storing
                  // a mismatched start/end pair.
                  if (startUnit == null || endUnit == null) {
                    startUnit = null;
                    endUnit = null;
                  }
                }
                // §2.3 field 9 — a pre-save summary, computed with the exact
                // same math `repo.create` itself uses (`effectiveTotalUnits`/
                // `dailyTarget`) so the numbers shown here never drift from
                // what actually gets saved.
                final days = durationDays < 1 ? 1 : durationDays;
                final targetDate = hijriDateStringForDate(DateTime.now().add(Duration(days: days)));
                final effectiveTotalUnits = (startUnit != null && endUnit != null) ? (endUnit - startUnit + 1) : totalUnits;
                final previewGoal = CompletionGoal(
                  id: 0,
                  contentType: contentType,
                  bookRef: bookRef,
                  totalUnits: effectiveTotalUnits,
                  startDate: hijriDateStringForDate(DateTime.now()),
                  targetDate: targetDate,
                  dailyTarget: effectiveTotalUnits / days,
                  status: 'active',
                  name: typedName.isEmpty ? null : typedName,
                );
                if (!context.mounted) return;
                // §2.3.7أ — "لا يُسمَح بالحفظ ما لم يتساويا بالضبط". The
                // editor's own rebalancing keeps this true by construction
                // for every ordinary edit; this is only a backstop for the
                // one edge it can't fully absorb (a session pushed high
                // enough that the last session's clamp-at-zero can't take
                // the whole difference back out).
                if (sessionsEnabled && sessions.isNotEmpty) {
                  final distributed = sessions.fold<int>(0, (sum, s) => sum + s.units);
                  final target = estimatedDailyTarget();
                  if (distributed != target) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${basicText('khatm_distributed_label', lang)}: $distributed ${basicText('khatm_of_label', lang)} $target')),
                    );
                    return;
                  }
                }
                final reminderSummary = reminderEnabled ? reminderTime.format(context) : basicText('reminder_off_label', lang);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(basicText('khatm_confirm_dialog_title', lang)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previewGoal.displayLabelFor(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text('${basicText('khatm_confirm_start_label', lang)}: ${formatDateForDisplay(previewGoal.startDate)}'),
                        Text('${basicText('khatm_confirm_end_label', lang)}: ${formatDateForDisplay(targetDate)}'),
                        Text('${basicText('khatm_confirm_daily_label', lang)}: ${previewGoal.dailyTarget.toStringAsFixed(1)} ${previewGoal.unitLabel}'),
                        Text('${basicText('khatm_reminder_toggle_label', lang)}: $reminderSummary'),
                        const SizedBox(height: 12),
                        Text(basicText('khatm_confirm_question', lang)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(basicText('cancel_action', lang))),
                      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(basicText('create_plan_action', lang))),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final created = await repo.create(
                  contentType: contentType,
                  bookRef: bookRef,
                  totalUnits: totalUnits,
                  targetDate: hijriDateStringForDate(DateTime.now().add(Duration(days: durationDays < 1 ? 1 : durationDays))),
                  name: typedName.isEmpty ? null : typedName,
                  colorIndex: selectedColorIndex,
                  startUnit: startUnit,
                  endUnit: endUnit,
                  reminderEnabled: reminderEnabled,
                  reminderHour: reminderTime.hour,
                  reminderMinute: reminderTime.minute,
                );
                if (sessionsEnabled && sessions.isNotEmpty) {
                  await repo.replaceSessions(created.id, sessions);
                }
                if (context.mounted) Navigator.pop(context);
                onCreated?.call();
              },
              child: Text(basicText('create_plan_action', lang)),
            ),
          ],
        )),
      ),
    ),
  );
}

/// §2.6 — the goal-identity edit (✎) mini-dialog: colour + name + reminder
/// only, pre-filled from [goal]. Deliberately reuses the exact same colour-
/// swatch/name-field/reminder-toggle widgets as the creation wizard above
/// (same look, same behaviour) rather than a new set of controls — range and
/// duration are NOT editable here, per the spec (§2.6: "لا نطاق ولا مدة،
/// تلك ثابتة بعد الإنشاء").
Future<void> openEditGoalSheet(BuildContext context, CompletionGoal goal, {VoidCallback? onSaved}) async {
  final lang = LanguagePreferenceService.currentLanguage;
  final repo = CompletionGoalRepository();
  int? selectedColorIndex = goal.colorIndex;
  final nameController = TextEditingController(text: goal.name ?? '');
  bool reminderEnabled = goal.reminderEnabled;
  TimeOfDay reminderTime = TimeOfDay(hour: goal.reminderHour ?? 20, minute: goal.reminderMinute ?? 0);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(basicText('khatm_edit_plan_title', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < kKhatmTabColors.length; i++)
                  GestureDetector(
                    onTap: () => setSheetState(() => selectedColorIndex = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: kKhatmTabColors[i]),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: 2,
                          color: selectedColorIndex == i ? AppColors.primary : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(basicText('khatm_name_field_label', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: nameController),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(basicText('khatm_reminder_toggle_label', lang), style: const TextStyle(fontSize: 13)),
              value: reminderEnabled,
              onChanged: (v) => setSheetState(() => reminderEnabled = v),
            ),
            if (reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, size: 20),
                title: Text(basicText('khatm_reminder_time_label', lang), style: const TextStyle(fontSize: 13)),
                trailing: Text(reminderTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: reminderTime);
                  if (picked != null) setSheetState(() => reminderTime = picked);
                },
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                await repo.updateSettings(
                  goal.id,
                  name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  colorIndex: selectedColorIndex,
                  reminderEnabled: reminderEnabled,
                  reminderHour: reminderTime.hour,
                  reminderMinute: reminderTime.minute,
                );
                if (context.mounted) Navigator.pop(context);
                onSaved?.call();
              },
              child: Text(basicText('save_action', lang)),
            ),
          ],
        )),
      ),
    ),
  );
}

/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.2 — "5 ألوان ثابتة" for the
/// goal-card side stripe. Purely categorical/decorative (cycled by
/// creation order — `id % 5` — since manual per-goal colour choice is
/// §2.3's creation-wizard colour picker, not built yet). Only shown where
/// a caller opts in via [CompletionGoalListView.showStripeAndPercent] — the
/// original "خطط ختمي" full screen keeps its plain card, unchanged.
const kKhatmTabColors = <Color>[
  Color(0xFF3B82F6), // أزرق
  Color(0xFFF97316), // برتقالي
  Color(0xFF8D6E43), // كاكي/بني
  Color(0xFFEF4444), // أحمر
  Color(0xFF86C06C), // أخضر فاتح
];

/// The active-completion-goal list + cards — extracted out of
/// `CompletionGoalsScreen` so it can be reused unchanged by that full
/// "خطط ختمي" screen (all content types, plain card) **and** by a
/// content-type-filtered bottom sheet (e.g. the mushaf reader's "الختمات"
/// entry point, quran_reading only, with the §2.2 colour stripe + live
/// percentage). Owns no Scaffold/AppBar — callers provide their own chrome.
class CompletionGoalListView extends StatefulWidget {
  /// Narrows `activeGoals()` to one `content_type`; null shows every goal
  /// (the original "خطط ختمي" behaviour).
  final String? contentTypeFilter;

  /// Opt-in §2.2 visual: coloured side stripe (cyclic, 5 fixed colours) +
  /// a live `%` progress figure next to the title. Off by default so the
  /// plain original card is untouched.
  final bool showStripeAndPercent;

  /// §2.3 item 4, "متبقي اليوم" — a suggested default for each card's
  /// "سجّل موضعك" entry field, read once from the mushaf reader's own
  /// current-page state by the caller (e.g. `_current` in
  /// `MushafSemanticReaderScreen`) when this list is shown inside the
  /// reader's own "الختمات" sheet. Null (the full "خطط ختمي" screen, with
  /// no live reader context) just leaves every card's field blank.
  final int? currentPageHint;

  const CompletionGoalListView({super.key, this.contentTypeFilter, this.showStripeAndPercent = false, this.currentPageHint});

  @override
  State<CompletionGoalListView> createState() => CompletionGoalListViewState();
}

class CompletionGoalListViewState extends State<CompletionGoalListView> {
  final _repo = CompletionGoalRepository();
  final _notificationService = NotificationService();
  List<CompletionGoalStatus> _statuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Public so a host screen that also creates/edits goals elsewhere (e.g.
  /// `CompletionGoalsScreen`'s own creation wizard) can refresh this list
  /// via a `GlobalKey<CompletionGoalListViewState>` after that action.
  Future<void> reload() async {
    setState(() => _loading = true);
    var goals = await _repo.activeGoals();
    if (widget.contentTypeFilter != null) {
      goals = goals.where((g) => g.contentType == widget.contentTypeFilter).toList();
    }
    final statuses = await Future.wait(goals.map(_repo.statusFor));
    if (widget.showStripeAndPercent) {
      // Deterministic creation-order for the cyclic stripe colour —
      // `activeGoals()` itself has no ORDER BY.
      statuses.sort((a, b) => a.goal.id.compareTo(b.goal.id));
    }
    await _syncReminders(statuses);
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  /// Keeps each active goal's daily reminder in sync with real progress:
  /// cancels it the moment today's target is already met (or the goal is
  /// fully done, or the goal's own §2.3 field 8 toggle is off), otherwise
  /// (re)schedules it at the goal's own per-goal time — falling back to the
  /// app's original fixed hour for any goal created before that field
  /// existed — with the current KPI so the wording never goes stale after a
  /// reschedule. Safe to call on every load — scheduling is idempotent
  /// (cancel-then-schedule under the same id).
  Future<void> _syncReminders(List<CompletionGoalStatus> statuses) async {
    final lang = LanguagePreferenceService.currentLanguage;
    for (final s in statuses) {
      final doneToday = s.remaining == 0 || await _repo.hasProgressedToday(s.goal);
      if (doneToday || !s.goal.reminderEnabled) {
        await _notificationService.cancelGoalReminder(s.goal.id);
      } else {
        final target = s.recalculatedDailyTarget.ceil().clamp(1, 1 << 30);
        await _notificationService.scheduleGoalReminder(
          goalId: s.goal.id,
          goalTitle: s.goal.displayLabelFor(lang),
          dailyTargetLabel: '$target ${s.goal.unitLabel} ${basicText('today_label', lang)}',
          hour: s.goal.reminderHour,
          minute: s.goal.reminderMinute,
        );
      }
    }
  }

  /// §2.3 item 4 — "سجّل موضعك" confirm action. Calls the existing
  /// `recordProgress` (the one write path for a goal's own progress, see
  /// its own doc comment) with no new write logic of its own.
  Future<void> _recordProgress(CompletionGoalStatus s, int page) async {
    await _repo.recordProgress(s.goal.id, page);
    reload();
  }

  Future<void> _reschedule(CompletionGoalStatus s) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    await _repo.reschedule(s.goal.id, hijriDateStringForDate(picked));
    reload();
  }

  /// "مسح الخطة" (Ismail's request 2026-08-16) — `CompletionGoalRepository
  /// .abandon()` already existed (used nowhere in the UI until now). Marks
  /// the goal 'abandoned' rather than deleting the row, so past progress on
  /// the underlying content (pages memorized, book position, etc.) is
  /// untouched — only the plan/target itself goes away. Confirmed first
  /// since there's no UI path back to an abandoned goal.
  Future<void> _confirmAndDelete(CompletionGoalStatus s) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('delete_plan_title', lang)),
        content: Text(
            '${basicText('delete_plan_confirm_prefix', lang)} "${s.goal.displayLabelFor(lang)}" ${basicText('delete_plan_confirm_suffix', lang)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('undo_action', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('delete', lang))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.abandon(s.goal.id);
    await _notificationService.cancelGoalReminder(s.goal.id);
    reload();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    if (_loading) {
      return AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang));
    }
    if (_statuses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(basicText('no_active_plans_message', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    // A plain Column in a SingleChildScrollView, not ListView.builder — this
    // list is always a handful of goals (never worth lazy-building), and a
    // Sliver-based list's lazy-child machinery (AutomaticKeepAlive/KeepAlive/
    // RepaintBoundary) left the sliver's own layout permanently unresolved
    // the moment a card contained a real TextField (confirmed live: a real
    // device render-tree dump showed `geometry: null` / "currently live
    // children: 0 to 0" indefinitely, reproduced identically whether this
    // list was inside a modal sheet or a plain pushed screen — removing the
    // TextField alone fixed it, isolating the cause to Sliver+TextField, not
    // to anything specific to this widget's card layout). A plain Column
    // sidesteps that machinery entirely.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < _statuses.length; i++)
            _GoalCard(
              status: _statuses[i],
              // grain 3.1 — an explicit `color_index` chosen at creation
              // wins; null (every goal created before this field, or left
              // unset) falls back to the original cyclic-by-creation-order
              // colour.
              stripeColor: widget.showStripeAndPercent
                  ? kKhatmTabColors[(_statuses[i].goal.colorIndex ?? i) % kKhatmTabColors.length]
                  : null,
              currentPageHint: widget.currentPageHint,
              onReschedule: () => _reschedule(_statuses[i]),
              onDelete: () => _confirmAndDelete(_statuses[i]),
              onEdit: () => openEditGoalSheet(context, _statuses[i].goal, onSaved: reload),
              onRecordProgress: (page) => _recordProgress(_statuses[i], page),
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final CompletionGoalStatus status;
  final Color? stripeColor;
  final int? currentPageHint;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<int> onRecordProgress;
  const _GoalCard({
    required this.status,
    required this.stripeColor,
    required this.currentPageHint,
    required this.onReschedule,
    required this.onDelete,
    required this.onEdit,
    required this.onRecordProgress,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  late final TextEditingController _pageController;

  /// §2.5 — whether this goal even has a werd-list concept at all (a page
  /// range to divide); `false` for content types with no page/juz concept,
  /// in which case the section is hidden entirely rather than shown empty.
  /// The list itself (now dynamic — one werd per actual plan day, not a
  /// fixed 7 — and editable) lives in [CompletionGoalWerdList], now its own
  /// pushed page (see the GestureDetector below) rather than mounted inline.
  late final bool _isWerdListGoal;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(text: widget.currentPageHint?.toString() ?? '');
    final g = widget.status.goal;
    _isWerdListGoal = _isPageBasedGoal(g.contentType);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  (Color, String) _badge(String lang) => switch (widget.status.scheduleStatus) {
        ScheduleStatus.ahead => (AppColors.primary, basicText('ahead_of_plan_badge', lang)),
        ScheduleStatus.onTrack => (AppColors.primaryDark, basicText('on_track_badge', lang)),
        ScheduleStatus.behind => (AppColors.textMuted, basicText('behind_plan_badge', lang)),
      };

  void _confirmPosition() {
    final parsed = int.tryParse(_pageController.text.trim());
    // An empty/unparsable/negative entry is silently ignored — same
    // no-crash-on-bad-input treatment as the wizard's duration field.
    if (parsed != null && parsed >= 0) widget.onRecordProgress(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final stripeColor = widget.stripeColor;
    final lang = LanguagePreferenceService.currentLanguage;
    final (color, label) = _badge(lang);
    final g = status.goal;
    final stripe = stripeColor;
    final percent = g.totalUnits > 0 ? (status.currentPosition / g.totalUnits * 100).clamp(0, 100).round() : 0;

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _GoalTitle(goal: g)),
              // §2.4/§2.6 — the goal-identity edit (✎) icon, right next to
              // the title (colour + name + reminder only; see
              // `openEditGoalSheet`'s own doc comment for why range/duration
              // aren't here).
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              if (stripe != null) ...[
                CircularPercentGauge(percent: percent, size: 36, strokeWidth: 4),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${status.currentPosition} ${basicText('weekly_progress_middle', lang)} ${g.totalUnits} — ${basicText('remaining_count_prefix', lang)} ${status.remaining}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            status.daysLeft > 0
                ? '${basicText('days_left_rate_message_prefix', lang)} ${status.daysLeft} ${basicText('day_word_label', lang)} — ${basicText('days_left_rate_message_suffix', lang)} ${status.recalculatedDailyTarget.toStringAsFixed(1)} ${basicText('daily_to_finish_on_time_suffix', lang)}'
                : basicText('target_date_passed_message', lang),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          // §2.3 item 4 — "متبقي اليوم": the one quantitative figure shown
          // (never a separate "تأخر" number), a no-blame reframing of any
          // catch-up backlog as simply what's due today.
          Text(
            status.pagesRemainingToday > 0
                ? '${basicText('khatm_remaining_today_prefix', lang)} ${status.pagesRemainingToday} ${g.unitLabel}'
                : basicText('khatm_completed_today_label', lang),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: status.pagesRemainingToday > 0 ? AppColors.primaryDark : AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          // The save action lives as the field's own suffixIcon, not a
          // sibling FilledButton.tonal in the Row — a live render-tree dump
          // isolated FilledButton.tonal (specifically, next to this
          // TextField in this list) as the one thing that left the sliver's
          // layout permanently unresolved (`geometry: null`, `size: MISSING`
          // cascading down from the card); every other piece of this field
          // (controller, keyboardType, inputFormatters, decoration with a
          // floating label + OutlineInputBorder) was bisected clean.
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: basicText('khatm_record_position_label', lang),
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              suffixIcon: IconButton(
                tooltip: basicText('save_action', lang),
                icon: const Icon(Icons.check_circle_outline),
                onPressed: _confirmPosition,
              ),
            ),
          ),
          if (_isWerdListGoal) ...[
            const SizedBox(height: 10),
            // Pushed as its own full page (Navigator.push), not expanded
            // inline — this card already lives inside a scrollable list,
            // inside a DraggableScrollableSheet, over the always-on mushaf
            // reader, and a khatm plan can have 30+ werd rows. Keeping that
            // list off the nested-sheet-over-reader stack avoids the jank/
            // hang risk that stack has already shown once before with an
            // unrelated widget, and gives the list a normal full-height
            // page to scroll in.
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CompletionGoalWerdList(goal: g)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(basicText('khatm_werd_list_title', lang), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: widget.onReschedule, child: Text(basicText('reschedule_plan_action', lang), style: const TextStyle(fontSize: 12))),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: Text(basicText('delete_plan_action', lang), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );

    if (stripe == null) {
      // Original "خطط ختمي" look — unchanged.
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.divider)),
        child: content,
      );
    }

    // Stack, not IntrinsicHeight+Row — an IntrinsicHeight ancestor forces an
    // intrinsic-dimension layout pass on every descendant, and TextField's
    // internal EditableText/Scrollable doesn't support that: with the new
    // "سجّل موضعك" field inside `content`, IntrinsicHeight left the sliver's
    // layout permanently unresolved (confirmed via a live render-tree dump —
    // `geometry: null`, 0 live children — the card built with correct text
    // but never actually painted). A Stack sizes children with the Card's
    // own ordinary constraints instead, so the stripe just needs to match
    // whatever height `content` naturally takes.
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          content,
          PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 6, color: stripe)),
        ],
      ),
    );
  }
}

/// Resolves the real title for 'personal_book' goals (looked up live, since
/// `CompletionGoal` deliberately doesn't cache a title that could go stale
/// if the book is renamed/deleted) — every other content type already has
/// a fixed label via `CompletionGoal.displayLabel`.
class _GoalTitle extends StatelessWidget {
  final CompletionGoal goal;
  const _GoalTitle({required this.goal});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    const style = TextStyle(fontWeight: FontWeight.w800, fontSize: 14);
    // grain 3.1 — a user-set name wins for every content type, personal
    // books included; only fall through to the live book-title lookup
    // below when the goal has no name of its own.
    final customName = goal.name;
    if (customName != null && customName.trim().isNotEmpty) {
      return Text(customName, style: style, overflow: TextOverflow.ellipsis);
    }
    if (goal.contentType != 'personal_book') {
      return Text(goal.displayLabelFor(lang), style: style);
    }
    return FutureBuilder<List<PersonalBook>>(
      future: PersonalBookRepository().all(),
      builder: (context, snapshot) {
        final books = snapshot.data;
        if (books == null) return Text(goal.displayLabelFor(lang), style: style);
        final match = books.where((b) => b.id.toString() == goal.bookRef);
        final title = match.isEmpty ? basicText('deleted_library_book_label', lang) : match.first.title;
        return Text('${basicText('from_my_library_prefix', lang)} $title', style: style, overflow: TextOverflow.ellipsis);
      },
    );
  }
}
