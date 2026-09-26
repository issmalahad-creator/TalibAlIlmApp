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

  // Quran Foundation API (api.quran.foundation) — a *confidential* OAuth
  // client. The secret must NEVER ship in the APK (extractable by
  // decompiling) and QF's docs forbid calling the token endpoint from
  // mobile code. These live server-side, in a tiny token-proxy the app
  // calls instead. Kept here only so the shape is documented; leave as
  // placeholders unless a proxy exists. See
  // docs/quran/QURAN_DATA_VERIFICATION_TASKS.md VT-4 and
  // lib/services/quran_audio/quran_foundation_provider.dart.
  static const qfTokenProxyUrl = 'REPLACE_WITH_SERVER_SIDE_QF_TOKEN_PROXY_URL';

  // «مساجدنا» backend (Phase 74). ONLY the project URL + the publishable /
  // anon key — both are meant to ship in a client app and are safe because
  // Row-Level Security gates the tables server-side. The DB password /
  // service_role key are SECRETS: never here, never in the app. Leave URL
  // empty to run mosque-offline (seeded demo mosque).
  static const supabaseUrl = '';
  static const supabaseAnonKey = 'REPLACE_WITH_SUPABASE_PUBLISHABLE_ANON_KEY';

  /// Anthropic API key — dev/private builds only. NEVER hardcode a real key
  /// here or anywhere in source: it is injected at build time with
  /// `--dart-define=ANTHROPIC_API_KEY=...` by `tool/build_all_apks.sh` from
  /// the gitignored local file `/.anthropic_key.local`. Public builds get
  /// the placeholder, so `ClaudeChatService.isConfigured` is false.
  static const anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: 'REPLACE_WITH_NEW_ANTHROPIC_API_KEY',
  );
}
