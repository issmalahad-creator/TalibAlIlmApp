/// ورقة سفلية واحدة للقارئ الصوتي — تقبل أي `ReadableTextSource` (تراث أو
/// مكتبتي)، لا شاشتان منفصلتان (docs/audio-reader/TODO.md 4.1).
///
/// عناصر ودجت أساسية مُثبَتة فقط (Row/Column/IconButton/Text/Slider/Wrap) —
/// لا ExpansionTile أو ودجت متحرِّك جديد، تحاشيًا لنفس فخ التجمّد الذي حدث
/// في بطاقة الختمة (`FilledButton.tonal` كشقيق TextField في Row). صفوف
/// التحكّم كلها `Wrap` لا `Row` — درس فيضان حقيقي حدث فعليًا على هاتف
/// إسماعيل الحقيقي (شاشة أضيق من المحاكي الذي اختُبِر عليه أولًا).
library;

import 'package:flutter/material.dart';

import '../services/tts/audio_reader_controller.dart';
import '../services/tts/text_sources/readable_text_source.dart';
import '../theme/app_theme.dart';
import '../services/packs/content_pack_engine.dart';
import 'packs/pack_ui.dart';
import '../services/tts/tts_voice_registry.dart';

class AudioReaderView extends StatefulWidget {
  const AudioReaderView({super.key, required this.source, required this.voiceId});

  final ReadableTextSource source;
  final String voiceId;

  static Future<void> open(BuildContext context, {required ReadableTextSource source, required String voiceId}) async {
    // Lite (S7): the voice model is a one-time download — offer it (size,
    // network) instead of opening a reader whose first paragraph would fail.
    final packId = TtsVoiceRegistry.byId(voiceId).packId;
    if (packId != null && !await ContentPackEngine.instance.isUsable(packId)) {
      final pack = (await ContentPackEngine.instance.manifest())?.byId(packId);
      if (pack != null && context.mounted) await showPackDownloadSheet(context, pack);
      return;
    }
    if (!context.mounted) return;
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
                _buildAutoAdvanceButton(),
                _buildSleepTimerButton(),
                _buildClearCacheButton(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 12),
            _buildBody(),
            _buildRemainingTimeLabel(),
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
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Text(
          // رسالة صديقة للمستخدم — لا نص استثناء تقني خام (docs/audio-reader/
          // AUDIO_100_ROADMAP.md §7.1). التفصيل التقني في debugPrint للمطوّر
          // فقط، لا في واجهة المستخدم.
          'تعذّر توليد الصوت لهذه الفقرة. تحقّق من المساحة المتاحة على الجهاز وحاول مجددًا.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDark),
        ),
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

  /// الوقت المتبقّي التقديري — لا يظهر حتى تُقاس أول فقرة فعليًا (لا تخمين
  /// مسبق بلا بيانات حقيقية).
  Widget _buildRemainingTimeLabel() {
    final remaining = _controller.estimatedTimeRemaining;
    if (remaining == null || _controller.state == AudioReaderPlaybackState.finished) {
      return const SizedBox.shrink();
    }
    final minutes = (remaining.inSeconds / 60).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        minutes <= 1 ? 'أقل من دقيقة متبقّية تقريبًا' : '~$minutes دقيقة متبقّية',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildAutoAdvanceButton() {
    final on = _controller.autoAdvancePage;
    return IconButton(
      icon: Icon(on ? Icons.playlist_play : Icons.playlist_play_outlined, color: on ? AppColors.primary : null),
      tooltip: on ? 'الانتقال التلقائي للصفحة التالية: مفعَّل' : 'الانتقال التلقائي للصفحة التالية: متوقّف',
      onPressed: () => _controller.autoAdvancePage = !on,
    );
  }

  Widget _buildSleepTimerButton() {
    final active = _controller.sleepTimerDuration != null;
    return PopupMenuButton<Duration?>(
      icon: Icon(active ? Icons.bedtime : Icons.bedtime_outlined, color: active ? AppColors.primary : null),
      tooltip: 'مؤقّت النوم',
      onSelected: _controller.setSleepTimer,
      itemBuilder: (context) => const [
        PopupMenuItem(value: Duration(minutes: 5), child: Text('5 دقائق')),
        PopupMenuItem(value: Duration(minutes: 15), child: Text('15 دقيقة')),
        PopupMenuItem(value: Duration(minutes: 30), child: Text('30 دقيقة')),
        PopupMenuItem(value: Duration(minutes: 60), child: Text('60 دقيقة')),
        PopupMenuItem(value: null, child: Text('إيقاف المؤقّت')),
      ],
    );
  }

  /// زر "حذف التراكم" (طلب إسماعيل 2026-09-18) — يعرض حجم الكاش الصوتي
  /// الكلي (كل الأصوات/الكتب المولَّدة سابقًا) قبل المسح، ويطلب تأكيدًا
  /// صريحًا (مسح فعلي غير قابل للتراجع، وإن كان قابلًا لإعادة التوليد لاحقًا).
  Widget _buildClearCacheButton() {
    return IconButton(
      icon: const Icon(Icons.cleaning_services_outlined),
      tooltip: 'مسح ذاكرة الصوت المؤقتة',
      onPressed: _showClearCacheDialog,
    );
  }

  Future<void> _showClearCacheDialog() async {
    final sizeBytes = await _controller.cacheSizeBytes();
    if (!mounted) return;
    final sizeMb = sizeBytes / (1024 * 1024);
    final sizeLabel = sizeMb < 0.1 ? 'أقل من 0.1' : sizeMb.toStringAsFixed(1);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح ذاكرة الصوت المؤقتة'),
        content: Text(
          sizeBytes == 0
              ? 'لا يوجد صوت مخزَّن مؤقّتًا حاليًا.'
              : 'الحجم الحالي: $sizeLabel م.ب.\n'
                  'سيُعاد توليد أي فقرة تُستمَع إليها لاحقًا من جديد (لا فقدان دائم — فقط وقت انتظار إضافي عند أول استماع تالٍ).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          if (sizeBytes > 0)
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('مسح')),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح ذاكرة الصوت المؤقتة.')));
    }
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
    final hasError = _controller.lastError != null;
    final isPlaying = _controller.state == AudioReaderPlaybackState.playing;
    final hasPrevious = _controller.paragraphIndex > 0;
    final hasNext = _controller.paragraphIndex < _controller.paragraphCount - 1;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          tooltip: 'الفقرة السابقة',
          onPressed: hasPrevious ? _controller.previousParagraph : null,
        ),
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () => _controller.skip(const Duration(seconds: -10)),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _controller.replayParagraph),
        // بعد فشل: زر "إعادة المحاولة" الفعلي (يُولِّد من جديد) لا
        // "استئناف" (لا يوجد مصدر صالح ليستأنفه — كان يُظهِر حالة تشغيل
        // مزيَّفة بلا صوت فعلي، خلل حقيقي وُجِد اليوم على جهاز حقيقي).
        IconButton(
          iconSize: 48,
          color: AppColors.primary,
          icon: Icon(
            hasError
                ? Icons.refresh_rounded
                : (isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
          ),
          tooltip: hasError ? 'إعادة المحاولة' : null,
          onPressed: hasError ? _controller.retry : (isPlaying ? _controller.pause : _controller.resume),
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () => _controller.skip(const Duration(seconds: 10)),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          tooltip: 'الفقرة التالية',
          onPressed: hasNext ? _controller.nextParagraph : null,
        ),
      ],
    );
  }
}
