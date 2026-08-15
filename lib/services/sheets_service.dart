import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class SheetsService {
  Future<bool> submit(Map<String, dynamic> payload) async {
    try {
      final resp = await http
          .post(
            Uri.parse(AppConfig.appsScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      // Apps Script redirects through script.googleusercontent.com; the
      // http package follows redirects by default and preserves POST here.
      return resp.statusCode == 200 && resp.body.contains('"status":"ok"');
    } catch (_) {
      return false;
    }
  }
}
