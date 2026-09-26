import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';

/// Asks before a Quran corpus book is downloaded (lite build) — shows the
/// size when the server reports it. Returns true only on an explicit tap.
Future<bool> askCorpusDownload(BuildContext context, int? bytes) async {
  final lang = LanguagePreferenceService.currentLanguage;
  final size = bytes == null
      ? null
      : bytes >= 1024 * 1024
          ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(bytes / 1024).ceil()} KB';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(basicText('ql_dl_title', lang)),
      content: Text(
        '${basicText('ql_dl_body', lang)}'
        '${size == null ? '' : '\n\n${basicText('ql_dl_size', lang)}: $size'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(basicText('ql_dl_cancel', lang)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(basicText('ql_dl_button', lang)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
