import 'package:flutter/material.dart';

import '../services/claude_chat_service.dart';
import '../theme/app_theme.dart';

/// A free-form, private chat with Claude — Ismail's own use only, separate
/// from the deterministic student-facing "الرفيق" (`CompanionChatEngine`).
/// Reached from the same hidden icon row as "اختبار شامل"
/// (`companion_chat_screen.dart`). Requires a real key in
/// `AppConfig.anthropicApiKey` (see `ClaudeChatService.isConfigured`) —
/// shows a clear Arabic message instead of a generic error if it's missing.
class ClaudeChatScreen extends StatefulWidget {
  const ClaudeChatScreen({super.key});

  @override
  State<ClaudeChatScreen> createState() => _ClaudeChatScreenState();
}

class _ClaudeChatScreenState extends State<ClaudeChatScreen> {
  final _service = ClaudeChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ClaudeChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

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
      _messages.add(ClaudeChatMessage(fromUser: true, text: text));
      _sending = true;
      _error = null;
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final reply = await _service.send(_messages);
      if (!mounted) return;
      setState(() {
        _messages.add(ClaudeChatMessage(fromUser: false, text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      // `.message`, not toString(): release builds are obfuscated, so the
      // «StateError: » prefix can't be stripped by its type name.
      setState(() => _error = e is StateError ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('محادثة Claude (خاصة)')),
      body: Column(
        children: [
          if (!_service.isConfigured)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لم يتم ضبط مفتاح Anthropic API بعد — عدّل lib/config/app_config.dart محليًا.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('اكتب أي سؤال — هذه محادثة حرة مع Claude، خاصة بك فقط.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _Bubble(message: _messages[i]),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
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
                        hintText: 'اكتب رسالتك...',
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ClaudeChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
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
        child: Text(
          message.text,
          style: AppTextStyles.body.copyWith(color: isUser ? Colors.white : null),
        ),
      ),
    );
  }
}
