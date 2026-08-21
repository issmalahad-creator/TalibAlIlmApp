import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/book_content.dart';
import '../services/book_content_service.dart';
import '../services/language_preference_service.dart';
import '../services/telegram_service.dart';
import '../theme/app_theme.dart';

/// "الدعم والأسئلة الشائعة" — two things in one screen since both are
/// small: (1) a contact form that sends straight to both admin Telegram
/// chats via the same [TelegramService] already used for report submission,
/// and (2) a read-only FAQ list the admin builds up over time via Telegram
/// (see [FaqEntry] / Apps Script v6). Reached from the Profile screen.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _telegramService = TelegramService();
  final _contentService = BookContentService();
  final _messageController = TextEditingController();

  bool _sending = false;
  bool _loadingFaq = true;
  List<FaqEntry> _faq = [];

  @override
  void initState() {
    super.initState();
    _loadFaq();
  }

  Future<void> _loadFaq() async {
    final feed = await _contentService.fetch();
    if (!mounted) return;
    setState(() {
      _faq = feed.faq;
      _loadingFaq = false;
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await _telegramService.sendToAllAdmins('📩 رسالة من مستخدم التطبيق:\n\n$text');
    if (!mounted) return;
    setState(() => _sending = false);
    final lang = LanguagePreferenceService.currentLanguage;
    if (ok) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('support_send_success', lang))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(basicText('support_send_failure', lang))),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('support_title', lang))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('support_intro_title', lang),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(
                  basicText('support_intro_body', lang),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(basicText('contact_us_header', lang), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: basicText('support_message_hint', lang),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(basicText(_sending ? 'sending_in_progress' : 'send_action', lang)),
            ),
          ),
          const SizedBox(height: 28),
          Text(basicText('faq_header', lang), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingFaq)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_faq.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(basicText('no_faq_yet_text', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            )
          else
            ..._faq.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(f.answer, style: const TextStyle(color: AppColors.textMuted, height: 1.6))],
                  ),
                )),
        ],
      ),
      ),
    );
  }
}
