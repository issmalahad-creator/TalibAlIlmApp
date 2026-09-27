import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/packs/content_pack_engine.dart';
import '../services/packs/pack_manifest.dart';
import '../theme/app_theme.dart';
import '../widgets/packs/pack_ui.dart';

/// «التنزيلات والمساحة» — every content pack in one place, grouped, with its
/// size, live state and the one action that fits (download / pause / delete
/// and how much it frees). CONTENT_PACKS_ARCHITECTURE.md §3.5.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.initialKind});

  /// Scroll-to group when opened from a specific place (e.g. the tafsir picker).
  final String? initialKind;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _engine = ContentPackEngine.instance;
  PackManifest? _manifest;
  int _used = 0;
  bool _loading = true;

  static const _groups = ['tafsir', 'translation', 'corpus', 'voice'];

  @override
  void initState() {
    super.initState();
    // Instant from the snapshot/cache, then the live manifest in the background.
    _load(refresh: false).then((_) => _load());
  }

  Future<void> _load({bool refresh = true}) async {
    final m = await _engine.manifest(refresh: refresh);
    final used = await _engine.bytesUsed();
    if (!mounted) return;
    setState(() {
      _manifest = m;
      _used = used;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(PackInfo pack) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                basicText('pk_delete_confirm', lang)
                    .replaceAll('{name}', pack.titleFor(lang))
                    .replaceAll('{mb} MB', packSize(pack.bytes)),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(basicText('pk_delete', lang)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(basicText('pk_not_now', lang))),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    await _engine.remove(pack.id);
    await _load(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(title: Text(basicText('downloads_title', lang))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sd_storage_rounded, color: AppColors.primaryDark, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(basicText('downloads_used', lang).replaceAll('{mb} MB', packSize(_used)),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(basicText('downloads_intro', lang),
                                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final kind in _groups) ..._group(kind, lang),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _group(String kind, String lang) {
    final packs = [...?_manifest?.packs.where((p) => p.kind == kind)]
      ..sort((a, b) => b.bytes.compareTo(a.bytes));
    if (packs.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Text(basicText('group_$kind', lang), style: AppTextStyles.headline),
      ),
      for (final p in packs)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.titleFor(lang), style: AppTextStyles.title),
                  ],
                ),
              ),
              PackStatusView(pack: p, compact: true, onDelete: () => _confirmDelete(p)),
            ],
          ),
        ),
    ];
  }
}
