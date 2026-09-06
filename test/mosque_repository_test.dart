import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/mosque.dart';
import 'package:talib_alilm_app/repositories/mosque_repository.dart';
import 'package:talib_alilm_app/services/mosque/mosque_api_client.dart';
import 'package:talib_alilm_app/services/mosque/supabase_mosque_api.dart';

/// An http client that never reaches the network — every request fails, so
/// `SupabaseMosqueApi` exercises its offline-degradation path deterministically
/// (no dependency on the test VM actually being offline).
class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(const SocketException('offline (test)'));
}

/// A `SupabaseMosqueApi` that is definitely `isConfigured` — a fixed test URL
/// + key, injected rather than read from `AppConfig` (which is empty on CI /
/// a fresh worktree and set in the executor's tree → TD-01 flake).
SupabaseMosqueApi _configuredOfflineApi() => SupabaseMosqueApi(
      client: _OfflineClient(),
      url: 'https://td01.test.supabase.co',
      anonKey: 'td01-test-anon-key',
    );

/// «مساجدنا» (Phase 74) — the local layer, against a real SQLite database:
/// the v53 schema opens, the demo mosque seeds once, and the reads the UI
/// needs return sane data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_mosque_test.db';
    final f = File(join(
        '.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in const [
      'mosques',
      'mosque_sections',
      'mosque_content',
      'mosque_media',
      'mosque_meta'
    ]) {
      await db.delete(t);
    }
  });

  test('the demo mosque seeds once, with sections and content', () async {
    final repo = MosqueRepository(api: const LocalOnlyMosqueApi());

    final first = await repo.allMosques();
    expect(first.length, 1);
    final demo = first.single;
    expect(demo.isDemo, isTrue);
    expect(demo.verified, isTrue);
    expect(demo.locationLabel, contains('أديس أبابا'));

    // idempotent — a second read does not re-seed
    expect((await repo.allMosques()).length, 1);

    final secs = await repo.sections(demo.id);
    expect(secs.length, greaterThanOrEqualTo(5));
    expect(secs.map((s) => s.type), contains(MosqueContentKind.lesson));

    final lessons = await repo.content(demo.id, MosqueContentKind.lesson);
    expect(lessons, isNotEmpty);
    expect(lessons.first.title, isNotEmpty);

    final prof = await repo.profile(demo.id);
    expect(prof, isNotNull);
    expect(prof!.sections, isNotEmpty);
    expect(prof.previews[MosqueContentKind.lesson], isNotEmpty);
    expect(prof.gallery, isNotEmpty); // 📸 the profile's gallery strip
    expect(prof.gallery.first.url, startsWith('https://'));
  });

  test('"مسجدي" is a single exclusive choice', () async {
    final repo = MosqueRepository(api: const LocalOnlyMosqueApi());
    final id = (await repo.allMosques()).single.id;

    expect(await repo.myMosque(), isNull);
    await repo.setMyMosque(id);
    expect((await repo.myMosque())?.id, id);

    await repo.clearMyMosque();
    expect(await repo.myMosque(), isNull);
  });

  test('myMosqueBrief carries the mosque + its newest published item',
      () async {
    final repo = MosqueRepository(api: const LocalOnlyMosqueApi());
    final id = (await repo.allMosques()).single.id;

    expect(await repo.myMosqueBrief(), isNull); // nothing chosen yet
    await repo.setMyMosque(id);

    final brief = await repo.myMosqueBrief();
    expect(brief, isNotNull);
    expect(brief!.mosque.id, id);
    expect(brief.latest, isNotNull);
    expect(brief.latest!.title, isNotEmpty);
  });

  test('search matches name / imam / city', () async {
    final repo = MosqueRepository(api: const LocalOnlyMosqueApi());
    await repo.allMosques(); // seed

    expect((await repo.allMosques(query: 'التقوى')).length, 1);
    expect((await repo.allMosques(query: 'عبد الجليل')).length, 1); // imam
    expect((await repo.allMosques(query: 'لا يوجد')).length, 0);
  });

  test('local-only backend is inert — syncFromApi is a no-op', () async {
    final repo = MosqueRepository(api: const LocalOnlyMosqueApi());
    expect(repo.backendConfigured, isFalse);
    await repo.allMosques(); // seed
    await repo.syncFromApi(); // must not throw / must not wipe the demo
    expect((await repo.allMosques()).length, 1);
  });

  test('a configured Supabase api degrades offline reads to [] / null, not a '
      'throw', () async {
    final api = _configuredOfflineApi();
    expect(api.isConfigured, isTrue);
    // the injected client always fails → every call catches and returns empty
    expect(await api.listMosques(), isEmpty);
    expect(await api.fetchMosque('MOSQ_X'), isNull);

    // a backend-configured repo does NOT seed the demo mosque
    final repo = MosqueRepository(api: api);
    expect(repo.backendConfigured, isTrue);
    expect(await repo.allMosques(), isEmpty);
  });

  test('lastSyncOk turns false when a configured backend can\'t be reached',
      () async {
    final repo = MosqueRepository(api: _configuredOfflineApi());
    expect(repo.lastSyncOk, isTrue); // optimistic until proven otherwise
    // listMosques() degrades to [] → sync "fails"
    await repo.syncFromApi();
    expect(repo.lastSyncOk, isFalse);
  });
}
