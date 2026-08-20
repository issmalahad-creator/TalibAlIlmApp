import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Thin wrapper around Anthropic's Messages API — used ONLY by the hidden
/// "اختبار شامل" diagnostics screen (Ismail's 2026-08-20 request) to help
/// analyze a self-test report generated on his real device. Not used by the
/// student-facing companion chat (`CompanionChatEngine` stays rule-based,
/// no AI, no network, no per-message cost). Deliberately calls the API
/// directly from the app with no server-side proxy: acceptable ONLY because
/// this tool is dev/single-user-only and never shipped to real end users —
/// see `AppConfig.anthropicApiKey`'s doc comment. Revisit with a real
/// server-side proxy before this (or anything like it) ever reaches a
/// distributed build.
class ClaudeDiagnosticsService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-5';
  static const _apiVersion = '2023-06-01';

  bool get isConfigured => AppConfig.anthropicApiKey != 'REPLACE_WITH_NEW_ANTHROPIC_API_KEY' && AppConfig.anthropicApiKey.isNotEmpty;

  /// Sends [reportText] (the self-test suite's collected findings) and
  /// returns Claude's plain-text analysis, or throws with a readable message
  /// on any failure — the caller shows that message directly rather than a
  /// generic "something went wrong", since this is a dev tool, not a
  /// polished end-user feature.
  Future<String> analyzeReport(String reportText) async {
    if (!isConfigured) {
      throw StateError('لم يتم ضبط مفتاح Anthropic API بعد — عدّل lib/config/app_config.dart محليًا.');
    }
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'x-api-key': AppConfig.anthropicApiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content':
                'هذا تقرير اختبار ذاتي (self-test) لتطبيق Flutter اسمه طالب العلم، تم تشغيله على جهاز أندرويد حقيقي. '
                    'حلّل النتائج، اذكر أي أخطاء أو تحذيرات حقيقية بوضوح، ورتّبها حسب الأهمية. '
                    'لا تخترع مشاكل غير موجودة في التقرير، ولا تكرر النتائج الناجحة بالتفصيل.\n\n$reportText',
          },
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('فشل الاتصال بـ Claude API (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw StateError('رد فارغ من Claude API.');
    }
    return (content.first as Map<String, dynamic>)['text'] as String? ?? '';
  }
}
