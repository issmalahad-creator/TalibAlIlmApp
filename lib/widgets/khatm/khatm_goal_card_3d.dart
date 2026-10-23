import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/basic_translations.dart';
import '../../repositories/completion_goal_repository.dart';
import '../../services/language_preference_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/digits.dart';
import 'khatm_sheet_parts.dart';

/// A Quran khatma in the list, as its own muṣḥaf (Ismail 2026-10-22: «طوّر
/// قائمة الختمات إلى ٣د»): the 3D cover beside the progress, today's
/// portion as a page range, and one-tap actions — «تابع القراءة» opens the
/// reader on the next page, «قرأت حتى ص N» records the page the reader is
/// on. Typing a page is still there, one tap away, for anything else.
/// Rarely used actions (werd list, edit, reschedule, delete) sit in «⋮».
class KhatmGoalCard3D extends StatefulWidget {
  final CompletionGoalStatus status;
  final Color color;
  final MushafCoverStyle coverStyle;
  final Widget title;
  final int? currentPageHint;
  final ValueChanged<int>? onOpenPage;
  final ValueChanged<int> onRecordProgress;
  final VoidCallback onEdit;
  final VoidCallback? onWerdList;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;

  const KhatmGoalCard3D({
    super.key,
    required this.status,
    required this.color,
    required this.coverStyle,
    required this.title,
    required this.currentPageHint,
    required this.onOpenPage,
    required this.onRecordProgress,
    required this.onEdit,
    required this.onWerdList,
    required this.onReschedule,
    required this.onDelete,
  });

  @override
  State<KhatmGoalCard3D> createState() => _KhatmGoalCard3DState();
}

enum _Menu { werd, edit, reschedule, delete }

class _KhatmGoalCard3DState extends State<KhatmGoalCard3D> {
  final _field = TextEditingController();
  bool _typing = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String _t(String k) => basicText(k, LanguagePreferenceService.currentLanguage);

  /// Absolute muṣḥaf page of the last page read (0 = not started).
  int get _lastPage {
    final g = widget.status.goal;
    final p = widget.status.currentPosition;
    if (p <= 0) return (g.startUnit ?? 1) - 1;
    return (g.startUnit ?? 1) - 1 + p;
  }

  int get _endPage {
    final g = widget.status.goal;
    return g.endUnit ?? ((g.startUnit ?? 1) - 1 + g.totalUnits);
  }

  void _submitTyped() {
    final v = parseAnyDigits(_field.text);
    if (v == null || v < 0) return;
    HapticFeedback.lightImpact();
    widget.onRecordProgress(v);
    setState(() => _typing = false);
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final g = s.goal;
    final accent = widget.color;
    final percent = g.totalUnits > 0 ? (s.currentPosition / g.totalUnits).clamp(0.0, 1.0) : 0.0;
    final done = s.remaining == 0;
    final next = (_lastPage + 1).clamp(1, _endPage);
    final wirdEnd = (_lastPage + s.pagesRemainingToday).clamp(next, _endPage);
    final hint = widget.currentPageHint;
    final canRecordHint = hint != null && hint != _lastPage && !done;

    final (badgeColor, badge) = switch (s.scheduleStatus) {
      ScheduleStatus.ahead => (AppColors.primary, _t('ahead_of_plan_badge')),
      ScheduleStatus.onTrack => (AppColors.primaryDark, _t('on_track_badge')),
      ScheduleStatus.behind => (const Color(0xFFB7791F), _t('behind_plan_badge')),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color.lerp(accent, Colors.white, 0.88)!, Color.lerp(accent, Colors.white, 0.72)!],
        ),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 9))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KhatmBook3D(color: accent, style: widget.coverStyle, turn: '${g.id}-${s.currentPosition}', size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w800), child: widget.title)),
                PopupMenuButton<_Menu>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  onSelected: (m) => switch (m) {
                    _Menu.werd => widget.onWerdList?.call(),
                    _Menu.edit => widget.onEdit(),
                    _Menu.reschedule => widget.onReschedule(),
                    _Menu.delete => widget.onDelete(),
                  },
                  itemBuilder: (_) => [
                    if (widget.onWerdList != null)
                      PopupMenuItem(value: _Menu.werd, child: _MenuRow(Icons.list_alt_rounded, _t('khatm_werd_list_title'))),
                    PopupMenuItem(value: _Menu.edit, child: _MenuRow(Icons.edit_outlined, _t('khatm_edit_plan_title'))),
                    PopupMenuItem(value: _Menu.reschedule, child: _MenuRow(Icons.event_repeat_rounded, _t('reschedule_plan_action'))),
                    PopupMenuItem(
                        value: _Menu.delete,
                        child: _MenuRow(Icons.delete_outline, _t('delete_plan_action'), color: Colors.redAccent)),
                  ],
                ),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: Text(badge, style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${(percent * 100).round()}%',
                    style: const TextStyle(fontSize: 24, height: 1, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${s.currentPosition} ${_t('weekly_progress_middle')} ${g.totalUnits}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 6),
              _PageEdgeBar(value: percent, color: accent),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        // today's portion
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(done || s.pagesRemainingToday == 0 ? Icons.check_circle_rounded : Icons.menu_book_rounded,
                color: Color.lerp(accent, Colors.black, 0.2), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t('wird'), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                Text(
                  s.pagesRemainingToday == 0 || done
                      ? _t('khatm_completed_today_label')
                      : _t('khatm_wird_range').replaceAll('{a}', '$next').replaceAll('{b}', '$wirdEnd'),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ]),
            ),
            if (s.daysLeft > 0)
              Text(_t('khatm_days_left').replaceAll('{n}', '${s.daysLeft}'),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (widget.onOpenPage != null && !done)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Color.lerp(accent, Colors.black, 0.18),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => widget.onOpenPage!(next),
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: Text(_t('khatm_continue_reading'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          if (widget.onOpenPage != null && !done && canRecordHint) const SizedBox(width: 8),
          if (canRecordHint)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: Color.lerp(accent, Colors.black, 0.3),
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onRecordProgress(hint);
                },
                icon: const Icon(Icons.bookmark_added_outlined, size: 18),
                label: Text(_t('khatm_read_up_to').replaceAll('{n}', '$hint'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
        if (!done)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _typing
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: _field,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [const AnyDigitsFormatter(), LengthLimitingTextInputFormatter(3)],
                      onSubmitted: (_) => _submitTyped(),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: _t('khatm_record_position_label'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        suffixIcon: IconButton(icon: const Icon(Icons.check_circle_rounded), onPressed: _submitTyped),
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => setState(() => _typing = true),
                    icon: const Icon(Icons.dialpad_rounded, size: 16),
                    label: Text(_t('khatm_other_page'), style: const TextStyle(fontSize: 12.5)),
                  ),
          ),
      ]),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ]);
}

/// Progress drawn as the page edge of a book: read pages darker, the rest
/// paper, fine page lines across both.
class _PageEdgeBar extends StatelessWidget {
  final double value;
  final Color color;
  const _PageEdgeBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12,
        child: CustomPaint(painter: _EdgePainter(value, color), size: const Size.fromHeight(12)),
      );
}

class _EdgePainter extends CustomPainter {
  final double v;
  final Color c;
  _EdgePainter(this.v, this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(4));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFDF8EE), Color(0xFFE6D8BD)],
    ).createShader(Offset.zero & s));
    // RTL: a muṣḥaf is read from the right, so progress fills from the right.
    final w = s.width * v;
    final read = Rect.fromLTWH(s.width - w, 0, w, s.height);
    canvas.drawRect(read, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(c, Colors.white, 0.15)!, Color.lerp(c, Colors.black, 0.25)!],
    ).createShader(read));
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 0.6;
    for (var y = 2.5; y < s.height; y += 2.5) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), line);
    }
    canvas.restore();
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFD9B26A));
  }

  @override
  bool shouldRepaint(covariant _EdgePainter o) => o.v != v || o.c != c;
}
