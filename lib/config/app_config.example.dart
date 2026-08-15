/// Template for lib/config/app_config.dart — that real file is gitignored
/// because it holds live secrets. Copy this to app_config.dart and fill in
/// the real values after completing SETUP_NEW_BOT.md.
class AppConfig {
  static const telegramBotToken = 'REPLACE_WITH_NEW_BOT_TOKEN_FROM_BOTFATHER';

  static const telegramChatIds = <String>[
    'REPLACE_WITH_YOUR_OWN_CHAT_ID',
  ];

  static const appsScriptUrl = 'REPLACE_WITH_NEW_REPORT_APPS_SCRIPT_EXEC_URL';

  static const bookContentApiUrl =
      'REPLACE_WITH_NEW_CONTENT_RELAY_APPS_SCRIPT_EXEC_URL';
}
