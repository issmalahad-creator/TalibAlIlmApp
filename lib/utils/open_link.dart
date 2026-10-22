import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

/// Opens a link and never fails silently: the app that owns it (YouTube,
/// Maps, the dialer), then any browser, then an in-app browser tab; if all
/// fail, a snackbar offers to copy it. Ismail hit the silent case with
/// «لا يفتح اليوتيوب» (2026-10-22).
Future<bool> openLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri != null) {
    final web = uri.scheme == 'http' || uri.scheme == 'https';
    for (final mode in [
      if (web) LaunchMode.externalNonBrowserApplication,
      LaunchMode.externalApplication,
      if (web) LaunchMode.inAppBrowserView,
      if (!web) LaunchMode.platformDefault,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return true;
      } catch (_) {}
    }
  }
  if (!context.mounted) return false;
  final lang = LanguagePreferenceService.currentLanguage;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(basicText('link_open_failed', lang)),
    action: SnackBarAction(
      label: basicText('copy_action', lang),
      onPressed: () => Clipboard.setData(ClipboardData(text: url)),
    ),
  ));
  return false;
}
