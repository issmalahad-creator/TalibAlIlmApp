import 'package:flutter/material.dart';

import '../models/book_content.dart';
import '../theme/app_theme.dart';

/// Browses past announcements/banners (v6 relay's append-only log) — the
/// Book screen only ever shows the single *current* one live; this is for
/// looking back at what was said before.
class ContentHistoryScreen extends StatelessWidget {
  final List<ContentHistoryEntry> history;
  const ContentHistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الإعلانات والبانرات')),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا يوجد سجل بعد.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                final isBanner = entry.type == 'banner';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isBanner && entry.url.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(entry.url,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => const SizedBox()),
                          )
                        else
                          const Icon(Icons.campaign_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isBanner ? 'بانر' : 'إعلان',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              if (entry.text.isNotEmpty) Text(entry.text),
                              const SizedBox(height: 4),
                              Text(entry.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
