import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class TelegramService {
  /// Sends [text] to every configured admin chat. Returns true only if
  /// every recipient succeeded.
  Future<bool> sendToAllAdmins(String text) async {
    var allOk = true;
    for (final chatId in AppConfig.telegramChatIds) {
      final ok = await _send(chatId, text);
      if (!ok) allOk = false;
    }
    return allOk;
  }

  Future<bool> _send(String chatId, String text) async {
    final uri = Uri.https(
      'api.telegram.org',
      '/bot${AppConfig.telegramBotToken}/sendMessage',
    );
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'chat_id': chatId, 'text': text}),
          )
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
