import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/mosque.dart';
import '../services/mosque/mosque_api_client.dart';
import '../services/mosque/supabase_mosque_api.dart';

/// «مساجدنا» (Phase 74) — app-shaped reads/writes over the local mosque
/// tables (`mosques`, `mosque_sections`, `mosque_content`, `mosque_media`).
/// The Supabase backend is the source of truth when configured
/// (`AppConfig.supabaseUrl`); [syncFromApi] folds its rows into the local
/// cache and reads serve from cache so the app works offline. With no
/// backend configured everything runs against a single seeded demo mosque.
class MosqueRepository {
  MosqueRepository({MosqueApiClient? api})
      : _api = api ?? _defaultApi();

  static MosqueApiClient _defaultApi() {
    final supa = SupabaseMosqueApi();
    return supa.isConfigured ? supa : const LocalOnlyMosqueApi();
  }

  final MosqueApiClient _api;
  Future<Database> get _db async => DatabaseHelper.instance.database;

  bool get backendConfigured => _api.isConfigured;

  /// One background pull per app run, kicked off from the first read.
  static Future<void>? _bootSync;
  void _kickSync() {
    if (!_api.isConfigured) return;
    _bootSync ??= syncFromApi().catchError((_) {});
  }

  // ---- reads -----------------------------------------------------------

  Future<List<Mosque>> allMosques({String? query}) async {
    _kickSync();
    await _seedDemoIfEmpty();
    final db = await _db;
    final q = (query ?? '').trim();
    final rows = await db.query(
      'mosques',
      where: q.isEmpty
          ? "status != 'suspended'"
          : "status != 'suspended' AND (name LIKE ? OR imam_name LIKE ? OR city LIKE ?)",
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%'],
      orderBy: 'is_mine DESC, verified DESC, name ASC',
    );
    return rows.map(Mosque.fromRow).toList();
  }

  Future<Mosque?> mosque(String id) async {
    final db = await _db;
    final rows = await db.query('mosques', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Mosque.fromRow(rows.first);
  }

  Future<Mosque?> myMosque() async {
    final db = await _db;
    final rows = await db.query('mosques',
        where: 'is_mine = 1 AND status != \'suspended\'', limit: 1);
    return rows.isEmpty ? null : Mosque.fromRow(rows.first);
  }

  Future<void> setMyMosque(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('mosques', {'is_mine': 0}, where: 'is_mine = 1');
      await txn.update('mosques', {'is_mine': 1}, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> clearMyMosque() async {
    final db = await _db;
    await db.update('mosques', {'is_mine': 0}, where: 'is_mine = 1');
  }

  Future<List<MosqueSection>> sections(String mosqueId) async {
    final db = await _db;
    final rows = await db.query('mosque_sections',
        where: 'mosque_id = ? AND enabled = 1',
        whereArgs: [mosqueId],
        orderBy: 'sort_order ASC, id ASC');
    return rows.map(MosqueSection.fromRow).toList();
  }

  Future<List<MosqueContent>> content(
    String mosqueId,
    MosqueContentKind kind, {
    int limit = 100,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'mosque_content',
      where: "mosque_id = ? AND kind = ? AND status = 'published'",
      whereArgs: [mosqueId, kind.key],
      orderBy: 'pinned DESC, COALESCE(event_date, updated_at) DESC, updated_at DESC',
      limit: limit,
    );
    return rows.map(MosqueContent.fromRow).toList();
  }

  Future<MosqueContent?> contentItem(String id) async {
    final db = await _db;
    final rows =
        await db.query('mosque_content', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : MosqueContent.fromRow(rows.first);
  }

  Future<List<MosqueMediaItem>> media(String mosqueId, {String? category, int limit = 60}) async {
    final db = await _db;
    final rows = await db.query(
      'mosque_media',
      where: category == null ? 'mosque_id = ?' : 'mosque_id = ? AND category = ?',
      whereArgs: category == null ? [mosqueId] : [mosqueId, category],
      orderBy: "COALESCE(date, '') DESC, id DESC",
      limit: limit,
    );
    return rows.map(MosqueMediaItem.fromRow).toList();
  }

  /// The mosque's home page in one read — profile + a few items per
  /// enabled section + a recent-media strip.
  Future<MosqueProfile?> profile(String mosqueId, {int perSection = 3}) async {
    if (_api.isConfigured) {
      try {
        await syncFromApi(mosqueId: mosqueId);
      } catch (_) {/* offline → serve cache */}
    }
    final m = await mosque(mosqueId);
    if (m == null) return null;
    final secs = await sections(mosqueId);
    final previews = <MosqueContentKind, List<MosqueContent>>{};
    for (final s in secs) {
      final items = await content(mosqueId, s.type, limit: perSection);
      if (items.isNotEmpty) previews[s.type] = items;
    }
    final gallery = await media(mosqueId, limit: 6);
    return MosqueProfile(
        mosque: m, sections: secs, previews: previews, gallery: gallery);
  }

  // ---- backend sync (inert until Phase 4) -----------------------------

  /// Pull the public directory + (optionally) one mosque's full record and
  /// mirror it locally. No-op with [LocalOnlyMosqueApi]. `is_mine` and any
  /// local demo rows are preserved.
  Future<void> syncFromApi({String? mosqueId}) async {
    if (!_api.isConfigured) return;
    final db = await _db;
    final list = await _api.listMosques();
    for (final m in list) {
      final existing = await db.query('mosques',
          columns: ['is_mine'], where: 'id = ?', whereArgs: [m.id], limit: 1);
      final mine = existing.isNotEmpty && existing.first['is_mine'] == 1;
      await db.insert('mosques', {...m.toRow(), 'is_mine': mine ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (mosqueId != null) {
      final dto = await _api.fetchMosque(mosqueId);
      if (dto != null) await _ingestProfile(db, dto);
    }
  }

  Future<void> _ingestProfile(Database db, MosqueProfileDto dto) async {
    await db.transaction((txn) async {
      final mine = (await txn.query('mosques',
                  columns: ['is_mine'],
                  where: 'id = ?',
                  whereArgs: [dto.mosque.id],
                  limit: 1))
              .firstOrNull?['is_mine'] ==
          1;
      await txn.insert('mosques', {...dto.mosque.toRow(), 'is_mine': mine ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('mosque_sections', where: 'mosque_id = ?', whereArgs: [dto.mosque.id]);
      await txn.delete('mosque_content', where: 'mosque_id = ?', whereArgs: [dto.mosque.id]);
      await txn.delete('mosque_media', where: 'mosque_id = ?', whereArgs: [dto.mosque.id]);
      for (final s in dto.sections) {
        await txn.insert('mosque_sections', s.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final c in dto.content) {
        await txn.insert('mosque_content', c.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final md in dto.media) {
        await txn.insert('mosque_media', md.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ---- demo seed -----------------------------------------------------

  Future<void> _seedDemoIfEmpty() async {
    // With a real backend the directory fills from Supabase — no demo row.
    if (_api.isConfigured) return;
    final db = await _db;
    final n = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM mosques')) ??
        0;
    if (n > 0) return;
    final now = DateTime.now().toUtc().toIso8601String();
    const id = 'MOSQ_DEMO_0001';
    await db.insert('mosques', Mosque(
      id: id,
      name: 'مسجد التقوى (نموذج)',
      imamName: 'الشيخ أحمد محمد',
      description:
          'مسجد نموذجي داخل «مساجدنا» — يظهر شكل صفحة المسجد وأقسامها قبل ربط أي مسجد حقيقي. '
          'تُدار محتويات كل مسجد لاحقًا من تيليجرام، وتُراجَع قبل النشر.',
      city: 'أديس أبابا',
      area: 'بولي',
      lat: 9.0108,
      lng: 38.7613,
      phone: '',
      verified: true,
      isDemo: true,
      createdAt: now,
    ).toRow());

    const kinds = [
      (MosqueContentKind.lesson, 'الدروس والمحاضرات', 0),
      (MosqueContentKind.recording, 'التسجيلات الصوتية', 1),
      (MosqueContentKind.khutbah, 'خطبة الجمعة', 2),
      (MosqueContentKind.announcement, 'الإعلانات', 3),
      (MosqueContentKind.activity, 'الأنشطة والفعاليات', 4),
      (MosqueContentKind.library, 'مكتبة المسجد', 5),
      (MosqueContentKind.need, 'احتياجات المسجد', 6),
    ];
    for (final (k, title, order) in kinds) {
      await db.insert('mosque_sections',
          MosqueSection(mosqueId: id, type: k, title: title, sortOrder: order).toRow());
    }

    Future<void> c(MosqueContentKind k, String title, String desc,
        {String? date, String? loc, String? mediaKind, String? mediaUrl}) async {
      await db.insert('mosque_content', MosqueContent(
        id: 'MC_${DateTime.now().microsecondsSinceEpoch}_${k.key}',
        mosqueId: id,
        kind: k,
        title: title,
        description: desc,
        eventDate: date,
        location: loc,
        mediaKind: mediaKind,
        mediaUrl: mediaUrl,
        createdAt: now,
        updatedAt: now,
      ).toRow());
    }

    await c(MosqueContentKind.lesson, 'تفسير سورة البقرة',
        'درس أسبوعي بعد صلاة المغرب — الشيخ أحمد.', date: '', loc: 'قاعة المسجد');
    await c(MosqueContentKind.lesson, 'شرح الأربعين النووية',
        'كل خميس بعد العشاء.', loc: 'المصلى الرئيسي');
    await c(MosqueContentKind.khutbah, 'خطبة: الإخلاص في العمل',
        'ملخص خطبة الجمعة الماضية مع رابط التسجيل.', mediaKind: 'audio');
    await c(MosqueContentKind.announcement, 'إعلان: حملة تنظيف المسجد',
        'يوم السبت بعد الفجر — نرحّب بمشاركة الجميع.');
    await c(MosqueContentKind.activity, 'مسابقة حفظ القرآن للأطفال',
        'الجمعة بعد صلاة العصر — جوائز قيّمة.', date: '', loc: 'ساحة المسجد');
    await c(MosqueContentKind.recording, 'محاضرة: بر الوالدين',
        'تسجيل صوتي كامل.', mediaKind: 'audio');
    await c(MosqueContentKind.need, 'سجّاد جديد للمصلى',
        'الحاجة قيد التوثيق من الإدارة قبل فتح باب المساهمة.');
  }
}
