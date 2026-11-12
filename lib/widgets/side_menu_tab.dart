import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// The always-visible way into every section: a slim tab fixed to the side
/// edge of the main tabs that opens the side menu (`AppDrawer`). Ismail,
/// 2026-11-12: people don't guess that «المزيد» or ☰ hide more sections
/// («قد لا يفطن المستخدم أن هناك أيقونات داخل أيقونات»), so the way in
/// must be visible itself.
///
/// It sits on the drawer's own edge (the right in Arabic), narrow enough not
/// to cover content — unlike the floating companion bubble removed on
/// 2026-09-18. The first few times it stretches out with the words
/// «كل الأقسام» for a few seconds, then folds back to the icon.
class SideMenuTab extends StatefulWidget {
  final VoidCallback onOpen;
  const SideMenuTab({super.key, required this.onOpen});

  @override
  State<SideMenuTab> createState() => _SideMenuTabState();
}

class _SideMenuTabState extends State<SideMenuTab> {
  static const _hintCountKey = 'side_tab_hint_count';
  static const _hintTimes = 3;
  bool _expanded = false;
  Timer? _fold;

  @override
  void initState() {
    super.initState();
    _maybeHint();
  }

  Future<void> _maybeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getInt(_hintCountKey) ?? 0;
    if (shown >= _hintTimes || !mounted) return;
    await prefs.setInt(_hintCountKey, shown + 1);
    setState(() => _expanded = true);
    _fold = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _fold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final label = basicText('drawer_title', lang);
    // Rounded only on the inner side, so it reads as a tab pulled from the edge.
    const radius = BorderRadiusDirectional.horizontal(end: Radius.circular(16));
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.primary,
        elevation: 4,
        shadowColor: Colors.black38,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius.resolve(Directionality.of(context)),
          onTap: widget.onOpen,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(6, 14, _expanded ? 14 : 6, 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apps_rounded, color: Colors.white, size: 22),
                  if (_expanded) ...[
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
