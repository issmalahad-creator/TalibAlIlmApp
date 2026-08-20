import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/companion_chat_session.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

class _ChatBubbleData {
  final String text;
  final bool fromUser;
  final String? actionLabel;
  final WidgetBuilder? actionBuilder;
  const _ChatBubbleData(this.text, this.fromUser, {this.actionLabel, this.actionBuilder});
}

/// The interactive messages-list + input-row, factored out of
/// `companion_chat_screen.dart` (2026-08-18) so the exact same chat works
/// both as a full page AND inside the floating-bubble popup
/// (`companion_floating_bubble.dart`) — one implementation, not two drifting
/// copies of the same logic.
class CompanionChatBody extends StatefulWidget {
  const CompanionChatBody({super.key});

  @override
  State<CompanionChatBody> createState() => _CompanionChatBodyState();
}

class _CompanionChatBodyState extends State<CompanionChatBody> {
  final _session = CompanionChatSession();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubbleData> _messages = [];
  bool _sending = false;

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _greet();
  }

  Future<void> _greet() async {
    final greeting = await _session.greetingForOpen(lang: _lang);
    if (!mounted) return;
    setState(() => _messages.add(_ChatBubbleData(greeting, false)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatBubbleData(text, true));
      _sending = true;
      _controller.clear();
    });
    _scrollToEnd();

    final reply = await _session.send(text, lang: _lang);
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatBubbleData(
        reply.text,
        false,
        actionLabel: reply.actionLabel,
        actionBuilder: reply.actionBuilder,
      ));
      _sending = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _Bubble(data: _messages[index]),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: basicText('companion_chat_hint', lang),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                  tooltip: basicText('companion_chat_send', lang),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatBubbleData data;
  const _Bubble({required this.data});

  @override
  Widget build(BuildContext context) {
    final isUser = data.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.text,
              style: AppTextStyles.body.copyWith(color: isUser ? Colors.white : null),
            ),
            if (data.actionLabel != null && data.actionBuilder != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: data.actionBuilder!),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isUser ? Colors.white : AppColors.primary,
                  side: BorderSide(color: isUser ? Colors.white : AppColors.primary),
                ),
                child: Text(data.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
