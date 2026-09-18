/// ورقة سفلية واحدة للقارئ الصوتي — تقبل أي `ReadableTextSource` (تراث أو
/// مكتبتي)، لا شاشتان منفصلتان (docs/audio-reader/TODO.md 4.1).
///
/// عناصر ودجت أساسية مُثبَتة فقط (Row/Column/IconButton/Text/Slider) — لا
/// ExpansionTile أو ودجت متحرِّك جديد، تحاشيًا لنفس فخ التجمّد الذي حدث في
/// بطاقة الختمة (`FilledButton.tonal` كشقيق TextField في Row) قبل هذه الحبة
/// مباشرة، حسب تقرير الوكيل.
library;

import 'package:flutter/material.dart';

import '../services/tts/audio_reader_controller.dart';
import '../services/tts/text_sources/readable_text_source.dart';
import '../theme/app_theme.dart';

class AudioReaderView extends StatefulWidget {
  const AudioReaderView({super.key, required this.source, required this.voiceId});

  final ReadableTextSource source;
  final String voiceId;

  static Future<void> open(BuildContext context, {required ReadableTextSource source, required String voiceId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AudioReaderView(source: source, voiceId: voiceId),
    );
  }

  @override
  State<AudioReaderView> createState() => _AudioReaderViewState();
}

class _AudioReaderViewState extends State<AudioReaderView> {
  late final AudioReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioReaderController(source: widget.source, voiceId: widget.voiceId);
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.source.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    textAlign: TextAlign.right,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 12),
            _buildBody(),
            const SizedBox(height: 12),
            _buildSpeedRow(),
            const SizedBox(height: 8),
            _buildControlsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.lastError != null) {
      return Text(
        _controller.lastError.toString(),
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.right,
      );
    }
    if (_controller.state == AudioReaderPlaybackState.loading && _controller.currentParagraphText.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller.state == AudioReaderPlaybackState.finished) {
      return const Text('انتهى الاستماع لهذه الوحدة.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Text(
        _controller.currentParagraphText,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildSpeedRow() {
    // Wrap لا Row — على شاشات أضيق (هواتف حقيقية بعرض أصغر من المحاكي الذي
    // اختُبِر عليه أولًا)، Row بلا حماية فيضان ينتج شريط "overflowed by N
    // pixels" الأصفر/الأسود المألوف في وضع التصحيح. Wrap ينقل الشريحة
    // الزائدة لسطر جديد بدل تجاوز الحدود، بلا حاجة لتمرير أفقي مخفي.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        const Text('السرعة:', style: TextStyle(color: AppColors.textMuted)),
        for (final s in const [0.75, 1.0, 1.25, 1.5])
          ChoiceChip(
            label: Text('${s}x'),
            selected: _controller.speed == s,
            onSelected: (_) => _controller.setSpeed(s),
          ),
      ],
    );
  }

  Widget _buildControlsRow() {
    final isPlaying = _controller.state == AudioReaderPlaybackState.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () => _controller.skip(const Duration(seconds: -10)),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _controller.replayParagraph),
        IconButton(
          iconSize: 48,
          color: AppColors.primary,
          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
          onPressed: isPlaying ? _controller.pause : _controller.resume,
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () => _controller.skip(const Duration(seconds: 10)),
        ),
      ],
    );
  }
}
