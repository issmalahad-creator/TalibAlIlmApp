import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// One turn in a free-form conversation with Claude.
class ClaudeChatMessage {
  final bool fromUser;
  final String text;
  const ClaudeChatMessage({required this.fromUser, required this.text});
}

/// Thin wrapper around Anthropic's Messages API for a free-form, private
/// chat — Ismail's own use only (single-user/dev-only, same key/proxy
/// caveat as `ClaudeDiagnosticsService`, whose request-shape this mirrors).
/// Not used by the student-facing companion chat (`CompanionChatEngine`
/// stays rule-based, no AI, no network, no per-message cost).
class ClaudeChatService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-5';
  static const _apiVersion = '2023-06-01';

  bool get isConfigured =>
      AppConfig.anthropicApiKey != 'REPLACE_WITH_NEW_ANTHROPIC_API_KEY' &&
      AppConfig.anthropicApiKey.isNotEmpty;

  /// Sends the full conversation so far (Anthropic's API is stateless — no
  /// server-side memory) and returns Claude's reply text, or throws with a
  /// readable Arabic message on any failure.
  Future<String> send(List<ClaudeChatMessage> history) async {
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
        'max_tokens': 1024,
        'messages': [
          for (final m in history)
            {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
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
