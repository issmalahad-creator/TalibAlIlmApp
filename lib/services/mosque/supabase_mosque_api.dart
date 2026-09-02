import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/mosque.dart';
import 'mosque_api_client.dart';

/// «مساجدنا» backend over **Supabase's REST API (PostgREST)** — no SDK, just
/// `http`. Read-only from the app's side: the Telegram/n8n intake writes;
/// the app pulls the public, RLS-gated rows and mirrors them locally
/// ([MosqueRepository.syncFromApi]). Never throws — `[]` / null on any
/// failure, per the [MosqueApiClient] contract.
///
/// Only `AppConfig.supabaseUrl` + `AppConfig.supabaseAnonKey` are used (both
/// safe to ship — RLS protects the tables). The DB password / service_role
/// key must never reach this file.
class SupabaseMosqueApi implements MosqueApiClient {
  SupabaseMosqueApi({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  static const _timeout = Duration(seconds: 12);

  String get _base => '${AppConfig.supabaseUrl}/rest/v1';
  Map<String, String> get _headers => {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        'Accept': 'application/json',
      };

  @override
  bool get isConfigured =>
      AppConfig.supabaseUrl.startsWith('http') &&
      AppConfig.supabaseAnonKey.isNotEmpty &&
      !AppConfig.supabaseAnonKey.startsWith('REPLACE_');

  Future<List<Map<String, dynamic>>> _get(String pathAndQuery) async {
    try {
      final resp = await _http
          .get(Uri.parse('$_base/$pathAndQuery'), headers: _headers)
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('SupabaseMosqueApi: $pathAndQuery -> ${resp.statusCode}');
        return const [];
      }
      final body = jsonDecode(resp.body);
      return body is List ? body.cast<Map<String, dynamic>>() : const [];
    } catch (e) {
      debugPrint('SupabaseMosqueApi: $pathAndQuery failed ($e)');
      return const [];
    }
  }

  @override
  Future<List<Mosque>> listMosques() async {
    if (!isConfigured) return const [];
    final rows = await _get(
        'mosques?select=*&status=neq.suspended&order=verified.desc,name.asc');
    return rows.map(Mosque.fromJson).toList();
  }

  @override
  Future<MosqueProfileDto?> fetchMosque(String mosqueId) async {
    if (!isConfigured) return null;
    final id = Uri.encodeComponent(mosqueId);
    final mRows = await _get('mosques?select=*&id=eq.$id&limit=1');
    if (mRows.isEmpty) return null;
    final sRows = await _get(
        'mosque_sections?select=*&mosque_id=eq.$id&order=sort_order.asc');
    final cRows = await _get(
        'mosque_content?select=*&mosque_id=eq.$id&status=eq.published');
    final gRows = await _get('mosque_media?select=*&mosque_id=eq.$id');
    return MosqueProfileDto(
      mosque: Mosque.fromJson(mRows.first),
      sections: [
        for (final r in sRows)
          MosqueSection(
            mosqueId: mosqueId,
            type: MosqueContentKind.fromKey(r['type'] as String?),
            title: (r['title'] ?? '').toString(),
            icon: r['icon'] as String?,
            enabled: r['enabled'] == true || r['enabled'] == 1,
            sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
          ),
      ],
      content: [
        for (final r in cRows)
          MosqueContent(
            id: (r['id'] ?? '').toString(),
            mosqueId: mosqueId,
            kind: MosqueContentKind.fromKey(r['kind'] as String?),
            title: r['title'] as String?,
            description: r['description'] as String?,
            mediaUrl: r['media_url'] as String?,
            mediaKind: r['media_kind'] as String?,
            eventDate: r['event_date'] as String?,
            startsAt: r['starts_at'] as String?,
            endsAt: r['ends_at'] as String?,
            location: r['location'] as String?,
            organizer: r['organizer'] as String?,
            status: (r['status'] ?? 'published').toString(),
            pinned: r['pinned'] == true || r['pinned'] == 1,
            createdBy: r['created_by'] as String?,
            createdAt: (r['created_at'] ?? '').toString(),
            updatedAt: (r['updated_at'] ?? r['created_at'] ?? '').toString(),
          ),
      ],
      media: [
        for (final r in gRows)
          MosqueMediaItem(
            id: (r['id'] ?? '').toString(),
            mosqueId: mosqueId,
            category: (r['category'] ?? 'mosque').toString(),
            contentId: r['content_id'] as String?,
            url: (r['url'] ?? '').toString(),
            caption: r['caption'] as String?,
            date: r['date'] as String?,
          ),
      ],
    );
  }
}
