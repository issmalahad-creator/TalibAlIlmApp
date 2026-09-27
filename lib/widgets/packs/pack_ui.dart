import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../services/language_preference_service.dart';
import '../../services/packs/content_pack_engine.dart';
import '../../services/packs/pack_manifest.dart';
import '../../services/packs/pack_state.dart';
import '../../theme/app_theme.dart';
import '../feedback/light_trail.dart';

/// Download UI for content packs (CONTENT_PACKS_ARCHITECTURE.md §3.5): the
/// sheet that asks — with the book's name, the size and the network — and
/// the in-place status that shows real progress, pause/cancel and honest
/// failures. Replaces the old generic «تنزيل؟» AlertDialog.

String packMb(int bytes) {
  final mb = bytes / (1024 * 1024);
  return mb >= 10 ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
}

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

enum _Net { wifi, mobile, none }

Future<_Net> _network() async {
  final r = await Connectivity().checkConnectivity();
  if (r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet)) return _Net.wifi;
  if (r.any((e) => e != ConnectivityResult.none)) return _Net.mobile;
  return _Net.none;
}

/// Asks, then queues. Returns true when a download was started or queued.
Future<bool> showPackDownloadSheet(BuildContext context, PackInfo pack, {ContentPackEngine? engine}) async {
  final lang = LanguagePreferenceService.currentLanguage;
  final choice = await askDownloadSheet(
    context,
    title: pack.titleFor(lang),
    author: pack.authorFor(lang),
    summary: pack.summaryFor(lang),
    kind: pack.kind,
    bytes: pack.bytes,
  );
  if (choice == null) return false;
  await (engine ?? ContentPackEngine.instance).download(pack.id, wifiOnly: choice == DownloadChoice.whenWifi);
  return true;
}

enum DownloadChoice { now, whenWifi }

/// The download question itself — book name, author, what it is, size,
/// the network you're on, and that it works offline afterwards. Null =
/// «ليس الآن». [allowWhenWifi] false for callers that can't queue.
Future<DownloadChoice?> askDownloadSheet(
  BuildContext context, {
  required String title,
  String? author,
  String? summary,
  required String kind,
  int? bytes,
  bool allowWhenWifi = true,
}) async {
  final net = await _network();
  if (!context.mounted) return null;
  final size = bytes == null ? null : '${packMb(bytes)} MB';
  return showModalBottomSheet<DownloadChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Icon(_iconFor(kind), color: AppColors.primaryDark, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      if (author != null && author.isNotEmpty)
                        Text(author, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(summary, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
            const SizedBox(height: 14),
            if (size != null) _factRow(Icons.sd_storage_outlined, '${_t('pk_size')}: $size'),
            _factRow(
              switch (net) {
                _Net.wifi => Icons.wifi,
                _Net.mobile => Icons.signal_cellular_alt,
                _Net.none => Icons.wifi_off,
              },
              switch (net) {
                _Net.wifi => _t('pk_on_wifi'),
                _Net.mobile => _t('pk_on_mobile').replaceAll('{mb}', bytes == null ? '?' : packMb(bytes)),
                _Net.none => _t('pk_no_connection'),
              },
              warn: net != _Net.wifi,
            ),
            _factRow(Icons.offline_pin_outlined, _t('pk_works_offline')),
            const SizedBox(height: 6),
            const Center(child: SizedBox(width: 60, height: 2, child: ColoredBox(color: kLightTrailGold))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: net == _Net.none ? null : () => Navigator.pop(ctx, DownloadChoice.now),
              icon: const Icon(Icons.download_rounded),
              label: Text(_t('pk_download_now')),
            ),
            if (allowWhenWifi && net != _Net.wifi) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, DownloadChoice.whenWifi),
                icon: const Icon(Icons.wifi),
                label: Text(_t('pk_when_wifi')),
              ),
            ],
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('pk_not_now'))),
          ],
        ),
      ),
    ),
  );
}

Widget _factRow(IconData icon, String text, {bool warn = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 19, color: warn ? Colors.orange.shade800 : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4))),
        ],
      ),
    );

IconData _iconFor(String kind) => switch (kind) {
      'tafsir' => Icons.menu_book_rounded,
      'translation' => Icons.translate_rounded,
      'voice' => Icons.record_voice_over_rounded,
      _ => Icons.auto_stories_rounded,
    };

String packFailureText(PackFailure f) => _t(switch (f) {
      PackFailure.offline => 'pk_fail_offline',
      PackFailure.noSpace => 'pk_fail_nospace',
      PackFailure.checksum => 'pk_fail_checksum',
      PackFailure.notFound => 'pk_fail_notfound',
      PackFailure.server || PackFailure.cancelled => 'pk_fail_server',
    });

String _eta(Duration? d) {
  if (d == null) return '';
  if (d.inSeconds < 60) return ' · ${_t('pk_eta_soon')}';
  return ' · ${_t('pk_eta_min').replaceAll('{n}', '${(d.inSeconds / 60).ceil()}')}';
}

/// One pack's live status + the single action that fits it. Used in
/// «التنزيلات والمساحة» and anywhere a feature shows «غير محمَّل».
class PackStatusView extends StatefulWidget {
  const PackStatusView({super.key, required this.pack, this.engine, this.compact = false, this.onDelete});

  final PackInfo pack;
  final ContentPackEngine? engine;

  /// Compact = one line (lists); otherwise a full block (inside a panel).
  final bool compact;
  final VoidCallback? onDelete;

  @override
  State<PackStatusView> createState() => _PackStatusViewState();
}

class _PackStatusViewState extends State<PackStatusView> {
  ContentPackEngine get _e => widget.engine ?? ContentPackEngine.instance;

  @override
  void initState() {
    super.initState();
    _e.refreshState(widget.pack.id);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PackState>(
      valueListenable: _e.stateOf(widget.pack.id),
      builder: (context, s, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(s.runtimeType), child: _body(context, s)),
      ),
    );
  }

  Widget _body(BuildContext context, PackState s) {
    final id = widget.pack.id;
    final size = '${packMb(widget.pack.bytes)} MB';
    return switch (s) {
      PackNotInstalled() => _action(Icons.download_rounded, size, () => showPackDownloadSheet(context, widget.pack, engine: _e)),
      PackBundled() => _label(Icons.check_circle_outline, _t('pk_bundled'), AppColors.textMuted),
      PackQueued() => _progress(null, _t('pk_queued'), onCancel: () => _e.cancel(id)),
      PackWaitingForWifi() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _label(Icons.wifi, _t('pk_waiting_wifi'), AppColors.textMuted),
            TextButton(onPressed: () => _e.download(id), child: Text(_t('pk_use_data'))),
          ],
        ),
      PackDownloading(:final received, :final total) => _progress(
          s.fraction,
          _t('pk_progress').replaceAll('{done}', packMb(received)).replaceAll('{total}', packMb(total)) +
              _eta(s.remaining),
          onPause: () => _e.pause(id),
          onCancel: () => _e.cancel(id),
        ),
      PackPaused(:final received, :final total) => _action(
          Icons.play_arrow_rounded,
          '${_t('pk_resume')} · ${_t('pk_paused').replaceAll('{pct}', '${total == 0 ? 0 : (received * 100 / total).round()}')}',
          () => _e.download(id),
        ),
      PackVerifying() || PackInstalling() => _progress(null, _t('pk_installing')),
      PackInstalled(:final updateAvailable) => updateAvailable
          ? _action(Icons.system_update_alt_rounded, _t('pk_update'), () => _e.download(id))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _label(Icons.offline_pin_rounded, _t('pk_installed'), AppColors.primary),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: _t('pk_delete'),
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
      PackFailed(:final reason) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(packFailureText(reason),
                textAlign: TextAlign.end, style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
            TextButton.icon(
              onPressed: () => _e.download(id),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_t('pk_retry')),
            ),
          ],
        ),
    };
  }

  Widget _action(IconData icon, String text, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );

  Widget _label(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _progress(double? fraction, String text, {VoidCallback? onPause, VoidCallback? onCancel}) => SizedBox(
        width: widget.compact ? 190 : double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                if (onPause != null)
                  InkWell(onTap: onPause, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.pause_rounded, size: 20))),
                if (onCancel != null)
                  InkWell(onTap: onCancel, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 20))),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: fraction, minHeight: 5, color: AppColors.primary),
            ),
          ],
        ),
      );
}
