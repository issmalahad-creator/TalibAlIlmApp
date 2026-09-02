import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/db/turath_annotations_migration.dart';
import 'package:talib_alilm_app/repositories/turath_catalog_sync.dart';
import 'package:talib_alilm_app/repositories/turath_repository.dart';
import 'package:talib_alilm_app/utils/study_annotation_anchor.dart';

/// Phase 79 «علامات الدراسة» — Phase A proof against a real SQLite database.
///  - a highlight stores the FULL selection (never a first-word fragment);
///    char_end - char_start == selected_len == selected_text.length.
///  - CRUD + the notebook filters work.
///  - migrating turath_notes / turath_quotes loses nothing and is idempotent.

const _page = 'قال المصنّف رحمه الله: بابُ ما جاء في الإخلاص والنيّة.\n'
    'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.\n'
    'فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_annotations_test.db';
    final dbFile = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in const ['turath_annotations', 'turath_notes', 'turath_quotes', 'turath_benefits']) {
      await db.delete(t);
    }
  });

  group('addAnnotation stores the full selection', () {
    test('selected_text is verbatim and complete; char_end - char_start == selected_len', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final target = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.'; // a full sentence w/ tashkeel + punctuation
      final start = norm.indexOf(target);
      final end = start + target.length;

      final id = await repo.addAnnotation(
        bookId: 1401, pageNumber: 7, volume: '1',
        normalizedPageText: norm, selectedText: target, charStartHint: start,
        colorKey: 'benefit', noteType: 'benefit', noteBody: 'أصل الباب',
        bookName: 'الأربعون النووية', authorName: 'النووي',
      );

      final page = await repo.annotationsForPage(1401, 7);
      expect(page, hasLength(1));
      final a = page.single;
      expect(a.id, id);
      expect(a.selectedText, target, reason: 'the ENTIRE selection, not the first word');
      expect(a.selectedText!.length, target.length);
      expect(a.selectedLen, target.length);
      expect(a.charEnd! - a.charStart!, a.selectedLen);
      expect(a.charStart, start);
      expect(a.charEnd, end);
      expect(a.anchorStatus, 'exact');
      expect(a.headAnchor, isNotNull);
      expect(a.tailAnchor, isNotNull);
      // acceptance assertions, stated literally
      expect(a.selectedText == norm.substring(a.charStart!, a.charEnd!), isTrue);
      expect(a.charEnd! - a.charStart! == a.selectedLen, isTrue);
    });

    test('a selection with spaces is stored whole even when the offset hint is wrong', () async {
      // Ismail's bug: a highlight over text containing a space was saving
      // only the first word. selectedText is authoritative; a bad hint must
      // not truncate it.
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final target = 'الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى'; // several words + spaces + punctuation
      final realStart = norm.indexOf(target);
      expect(realStart, greaterThan(0));

      final id = await repo.addAnnotation(
        bookId: 4242, pageNumber: 1, normalizedPageText: norm,
        selectedText: target,
        charStartHint: 999999, // deliberately nonsense
        colorKey: 'benefit', bookName: 'ك',
      );
      final a = (await repo.annotationsForPage(4242, 1)).single;
      expect(a.id, id);
      expect(a.selectedText, target, reason: 'the WHOLE multi-word selection, not "الأعمال"');
      expect(a.selectedLen, target.length);
      expect(a.charStart, realStart, reason: 'located by string search despite the bad hint');
      expect(a.charEnd! - a.charStart!, target.length);
      expect(a.anchorStatus, 'exact');
    });

    test('a selection that is not on the page is still stored in full, just unanchored', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      const target = 'نصٌّ ليس موجودًا في هذه الصفحة أبدًا';
      await repo.addAnnotation(bookId: 4343, pageNumber: 1, normalizedPageText: norm, selectedText: target, colorKey: 'explain', bookName: 'ك');
      final a = (await repo.annotationsForPage(4343, 1)).single;
      expect(a.selectedText, target);
      expect(a.selectedLen, target.length);
      expect(a.charStart, isNull);
      expect(a.anchorStatus, 'unanchored');
    });

    test('updateAnnotationRange grows a highlight to a longer selection', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final small = 'الأعمال بالنيّات';
      final big = 'الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';
      final id = await repo.addAnnotation(bookId: 51, pageNumber: 1, normalizedPageText: norm, selectedText: small, charStartHint: norm.indexOf(small), colorKey: 'memorize', bookName: 'ك');

      await repo.updateAnnotationRange(id, normalizedPageText: norm, selectedText: big, charStartHint: norm.indexOf(big));
      final a = (await repo.annotationsForPage(51, 1)).single;
      expect(a.selectedText, big);
      expect(a.selectedLen, big.length);
      expect(a.charEnd! - a.charStart!, big.length);
      expect(norm.substring(a.charStart!, a.charEnd!), big);
    });

    test('updateAnnotationRange shrinks a highlight and recomputes the locators for the NEW text', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final big = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';
      final small = 'الأعمال بالنيّات';
      final id = await repo.addAnnotation(bookId: 52, pageNumber: 1, normalizedPageText: norm, selectedText: big, charStartHint: norm.indexOf(big), colorKey: 'benefit', bookName: 'ك');
      final before = (await repo.annotationsForPage(52, 1)).single;

      await repo.updateAnnotationRange(id, normalizedPageText: norm, selectedText: small, charStartHint: norm.indexOf(small));
      final after = (await repo.annotationsForPage(52, 1)).single;

      expect(after.selectedText, small);
      expect(after.charEnd! - after.charStart!, small.length);
      expect(norm.substring(after.charStart!, after.charEnd!), small);
      expect(after.anchorStatus, 'exact');
      expect(after.headAnchor, small); // whole small selection <= 64 chars
      expect(after.headAnchor, isNot(before.headAnchor), reason: 'locators must reflect the new range, not the old');
      // the new range still re-anchors cleanly on load
      final resolved = await repo.resolvedAnnotationsForPage(52, 1, norm);
      expect(resolved.single.resolved.status.name, 'exact');
      expect(norm.substring(resolved.single.resolved.start!, resolved.single.resolved.end!), small);
    });

    test('updateAnnotationRange stores a spaced selection whole even with a wrong hint', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final target = 'وأنّ لكلّ امرئٍ ما نوى';
      final id = await repo.addAnnotation(bookId: 53, pageNumber: 1, normalizedPageText: norm, selectedText: 'اعلم', charStartHint: norm.indexOf('اعلم'), colorKey: 'explain', bookName: 'ك');

      await repo.updateAnnotationRange(id, normalizedPageText: norm, selectedText: target, charStartHint: 999999);
      final a = (await repo.annotationsForPage(53, 1)).single;
      expect(a.selectedText, target, reason: 'the whole multi-word range, not "وأنّ"');
      expect(a.charStart, norm.indexOf(target));
      expect(a.charEnd! - a.charStart!, target.length);
    });

    test('a multi-line selection keeps every character including the newlines', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final start = norm.indexOf('بابُ ما جاء');
      final end = norm.indexOf('ما نوى.') + 'ما نوى.'.length; // crosses one newline
      final target = norm.substring(start, end);
      final id = await repo.addAnnotation(
        bookId: 1, pageNumber: 1, normalizedPageText: norm,
        selectedText: target, charStartHint: start, colorKey: 'memorize',
        bookName: 'ك',
      );
      final a = (await repo.annotationsForPage(1, 1)).single;
      expect(a.id, id);
      expect(a.selectedText, contains('\n'));
      expect(a.selectedText, target);
      expect(a.charEnd! - a.charStart!, a.selectedText!.length);
    });
  });

  group('CRUD + resolve persistence', () {
    test('recolor, edit note, delete', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final id = await repo.addAnnotation(
        bookId: 5, pageNumber: 2, normalizedPageText: norm,
        selectedText: norm.substring(0, 12), charStartHint: 0, colorKey: 'benefit', bookName: 'ك',
      );

      await repo.recolorAnnotation(id, 'important');
      await repo.updateAnnotationNote(id, noteType: 'question', noteBody: 'لماذا؟');
      var a = (await repo.annotationsForPage(5, 2)).single;
      expect(a.colorKey, 'important');
      expect(a.noteType, 'question');
      expect(a.noteBody, 'لماذا؟');

      await repo.updateAnnotationNote(id, noteType: null, noteBody: '   ');
      a = (await repo.annotationsForPage(5, 2)).single;
      expect(a.noteBody, isNull, reason: 'blank note body normalizes to NULL');

      await repo.deleteAnnotation(id);
      expect(await repo.annotationsForPage(5, 2), isEmpty);
    });

    test('saveResolvedAnchor persists a shifted result for the next visit', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final id = await repo.addAnnotation(
        bookId: 9, pageNumber: 3, normalizedPageText: norm,
        selectedText: norm.substring(5, 25), charStartHint: 5, colorKey: 'explain', bookName: 'ك',
      );
      final shifted = 'مقدمة\n\n$norm';
      final resolved = resolveAnchor(shifted, StoredAnchor(
        selectedText: norm.substring(5, 25),
        charStart: 5, charEnd: 25, normVersion: kNormVersion,
        textChecksum: pageChecksum(norm), textLength: norm.length,
        prefixContext: norm.substring(0, 5), suffixContext: norm.substring(25, 60),
        headAnchor: norm.substring(5, 21), tailAnchor: norm.substring(5, 25),
        occurrenceIndex: 0,
      ));
      expect(resolved.status, AnchorStatus.shifted);
      await repo.saveResolvedAnchor(id, resolved, normalizedPageText: shifted);

      final a = (await repo.annotationsForPage(9, 3)).single;
      expect(a.anchorStatus, 'shifted');
      expect(a.charStart, resolved.start);
      expect(a.charEnd, resolved.end);
      expect(shifted.substring(a.charStart!, a.charEnd!), norm.substring(5, 25));
    });
  });

  group('notebook filters (allAnnotations)', () {
    Future<void> seed(TurathRepository repo) async {
      final norm = normalizePageText(_page);
      await repo.addAnnotation(bookId: 100, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 10), charStartHint: 0, colorKey: 'benefit', noteType: 'benefit', noteBody: 'فائدة في الإخلاص', bookName: 'كتاب أ');
      await repo.addAnnotation(bookId: 100, pageNumber: 2, normalizedPageText: norm, selectedText: norm.substring(10, 20), charStartHint: 10, colorKey: 'question', noteType: 'question', noteBody: 'إشكال', bookName: 'كتاب أ');
      await repo.addAnnotation(bookId: 200, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 8), charStartHint: 0, colorKey: 'benefit', noteType: 'benefit', noteBody: 'فائدة أخرى', bookName: 'كتاب ب');
    }

    test('by colour, by book, by free text', () async {
      final repo = TurathRepository();
      await seed(repo);

      expect((await repo.allAnnotations()).length, 3);
      expect((await repo.allAnnotations(colorKeys: ['benefit'])).length, 2);
      expect((await repo.allAnnotations(colorKeys: ['question'])).length, 1);
      expect((await repo.allAnnotations(bookId: 100)).length, 2);
      expect((await repo.allAnnotations(query: 'الإخلاص')).length, 1);
      expect(await repo.annotationCountForBook(100), 2);
      expect(await repo.annotationCountForBook(200), 1);
    });

    test('by category joins the catalog', () async {
      final gz = File(join('assets', 'turath', 'catalog-v3.json.gz'));
      final manifest = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync()))) as Map<String, dynamic>;
      await TurathCatalogSync().ingestFromJson(manifest);

      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final aqeedahIds = await repo.categoryMemberIds(1);
      final tafsirIds = await repo.categoryMemberIds(3);
      final aqeedahBook = aqeedahIds.first; // a real العقيدة book id
      final tafsirBook = tafsirIds.firstWhere((b) => !aqeedahIds.contains(b)); // a real non-Aqeedah book id

      await repo.addAnnotation(bookId: aqeedahBook, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 6), charStartHint: 0, colorKey: 'benefit', bookName: 'عقيدة');
      await repo.addAnnotation(bookId: tafsirBook, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 6), charStartHint: 0, colorKey: 'benefit', bookName: 'تفسير');

      final inAqeedah = await repo.allAnnotations(catId: 1);
      expect(inAqeedah, hasLength(1));
      expect(inAqeedah.single.bookId, aqeedahBook);
    });
  });

  group('benefits map + digest (79-sa-E)', () {
    test('annotationStats aggregates by colour / book / author, and counts notes + orphans', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      await repo.addAnnotation(bookId: 10, pageNumber: 1, normalizedPageText: norm, selectedText: 'اعلم أنّ الأعمال', charStartHint: norm.indexOf('اعلم'), colorKey: 'benefit', noteType: 'benefit', noteBody: 'فائدة', bookName: 'كتاب أ', authorName: 'المؤلف س');
      await repo.addAnnotation(bookId: 10, pageNumber: 2, normalizedPageText: norm, selectedText: 'بالنيّات', charStartHint: norm.indexOf('بالنيّات'), colorKey: 'benefit', bookName: 'كتاب أ', authorName: 'المؤلف س');
      await repo.addAnnotation(bookId: 20, pageNumber: 1, normalizedPageText: norm, selectedText: 'ما نوى', charStartHint: norm.indexOf('ما نوى'), colorKey: 'question', noteType: 'question', noteBody: 'إشكال', bookName: 'كتاب ب', authorName: 'المؤلف ص');
      // an orphan
      final db = await DatabaseHelper.instance.database;
      await repo.addAnnotation(bookId: 20, pageNumber: 1, normalizedPageText: norm, selectedText: 'نصٌّ غير موجود', colorKey: 'benefit', bookName: 'كتاب ب');
      await db.update('turath_annotations', {'anchor_status': 'orphan'}, where: "selected_text = ?", whereArgs: ['نصٌّ غير موجود']);

      final s = await repo.annotationStats();
      expect(s.total, 4);
      expect(s.withNote, 2);
      expect(s.orphans, 1);
      expect(s.byColor['benefit'], 3);
      expect(s.byColor['question'], 1);
      expect(s.byBook.first.name, 'كتاب أ'); // richest book first
      expect(s.byBook.first.count, 2);
      expect(s.byAuthor.map((a) => a.name), containsAll(<String>['المؤلف س', 'المؤلف ص']));
    });

    test('annotationsDigest is plain text, grouped by book, with quote + note + citation', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      await repo.addAnnotation(bookId: 30, pageNumber: 5, volume: '2', normalizedPageText: norm, selectedText: 'الأعمال بالنيّات', charStartHint: norm.indexOf('الأعمال'), colorKey: 'benefit', noteType: 'benefit', noteBody: 'أصل عظيم', bookName: 'عمدة الأحكام', authorName: 'المقدسي');

      final digest = await repo.annotationsDigest();
      expect(digest, contains('عمدة الأحكام — المقدسي'));
      expect(digest, contains('«الأعمال بالنيّات»'));
      expect(digest, contains('— أصل عظيم'));
      expect(digest, contains('ص 5'));
      expect(digest, contains('ج 2'));
      expect(digest, contains('فائدة، من مكتبة turath.io'));
    });

    test('annotationsDigest scoped to one book only includes that book', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      await repo.addAnnotation(bookId: 41, pageNumber: 1, normalizedPageText: norm, selectedText: 'اعلم', charStartHint: norm.indexOf('اعلم'), colorKey: 'benefit', bookName: 'كتاب واحد');
      await repo.addAnnotation(bookId: 42, pageNumber: 1, normalizedPageText: norm, selectedText: 'نوى', charStartHint: norm.indexOf('نوى'), colorKey: 'benefit', bookName: 'كتاب آخر');

      final digest = await repo.annotationsDigest(bookId: 41);
      expect(digest, contains('كتاب واحد'));
      expect(digest, isNot(contains('كتاب آخر')));
    });
  });

  group('unified notebook (79-sa-D — a view, not a copy)', () {
    test('every entry carries text, note, colour, type, book, author and page', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final t = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';
      await repo.addAnnotation(
        bookId: 500, pageNumber: 12, volume: '1', normalizedPageText: norm,
        selectedText: t, charStartHint: norm.indexOf(t),
        colorKey: 'memorize', noteType: 'memorize', noteBody: 'يُحفظ',
        bookName: 'صحيح مسلم', authorName: 'مسلم',
      );

      final entries = await repo.notebookEntries();
      expect(entries, hasLength(1));
      final e = entries.single.annotation;
      expect(e.selectedText, t);
      expect(e.noteBody, 'يُحفظ');
      expect(e.colorKey, 'memorize');
      expect(e.noteType, 'memorize');
      expect(e.bookName, 'صحيح مسلم');
      expect(e.authorName, 'مسلم');
      expect(e.pageNumber, 12);
    });

    test('category is resolved by joining the catalog, and migrated legacy rows show up', () async {
      final gz = File(join('assets', 'turath', 'catalog-v3.json.gz'));
      final manifest = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync()))) as Map<String, dynamic>;
      await TurathCatalogSync().ingestFromJson(manifest);

      final db = await DatabaseHelper.instance.database;
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final aqeedahBook = (await repo.categoryMemberIds(1)).first;

      await repo.addAnnotation(bookId: aqeedahBook, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 8), colorKey: 'benefit', bookName: 'كتاب عقيدة');
      // a legacy note for the same book -> migrated -> must also appear
      await db.insert('turath_notes', {'book_id': aqeedahBook, 'book_name': 'كتاب عقيدة', 'page_number': 2, 'selected_text': 'مقطع قديم', 'note': 'ملاحظة قديمة', 'created_at': '1447-01-01'});
      await migrateLegacyToAnnotations(db);

      final entries = await repo.notebookEntries(bookId: aqeedahBook);
      expect(entries.length, 2, reason: 'the new highlight + the migrated legacy note');
      expect(entries.every((e) => e.catId == 1), isTrue);
      expect(entries.every((e) => e.categoryName == 'العقيدة'), isTrue);
      expect(entries.map((e) => e.annotation.noteBody), containsAll(<String>['ملاحظة قديمة']));
    });

    test('filters compose: colour + free text + book', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      await repo.addAnnotation(bookId: 7, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 6), colorKey: 'benefit', noteType: 'benefit', noteBody: 'عن الإخلاص', bookName: 'ك7');
      await repo.addAnnotation(bookId: 7, pageNumber: 2, normalizedPageText: norm, selectedText: norm.substring(6, 12), colorKey: 'question', noteType: 'question', noteBody: 'عن الإخلاص أيضًا', bookName: 'ك7');
      await repo.addAnnotation(bookId: 8, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 6), colorKey: 'benefit', noteType: 'benefit', noteBody: 'عن الإخلاص', bookName: 'ك8');

      expect((await repo.notebookEntries(bookId: 7)).length, 2);
      expect((await repo.notebookEntries(bookId: 7, colorKeys: ['benefit'])).length, 1);
      expect((await repo.notebookEntries(query: 'الإخلاص')).length, 3);
      expect((await repo.notebookEntries(bookId: 7, query: 'أيضًا')).length, 1);
    });

    test('newest first, and annotationById round-trips for the deep-link', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final id1 = await repo.addAnnotation(bookId: 9, pageNumber: 1, normalizedPageText: norm, selectedText: norm.substring(0, 6), colorKey: 'benefit', bookName: 'ك');
      final id2 = await repo.addAnnotation(bookId: 9, pageNumber: 2, normalizedPageText: norm, selectedText: norm.substring(6, 12), colorKey: 'explain', bookName: 'ك');

      final entries = await repo.notebookEntries();
      expect(entries.first.annotation.id, id2, reason: 'ordered by updated_at desc');

      final fetched = await repo.annotationById(id1);
      expect(fetched, isNotNull);
      expect(fetched!.id, id1);
      expect(await repo.annotationById(999999), isNull);
    });
  });

  group('resolvedAnnotationsForPage (Phase B — re-anchor on load)', () {
    test('an unchanged page resolves every annotation to exact, full-span, drawable', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final t = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';
      final s = norm.indexOf(t);
      await repo.addAnnotation(bookId: 77, pageNumber: 1, normalizedPageText: norm, selectedText: t, charStartHint: s, colorKey: 'benefit', bookName: 'ك');

      final resolved = await repo.resolvedAnnotationsForPage(77, 1, norm);
      expect(resolved, hasLength(1));
      final r = resolved.single;
      expect(r.resolved.status.name, 'exact');
      expect(r.resolved.drawable, isTrue);
      expect(norm.substring(r.resolved.start!, r.resolved.end!), t);
      expect(r.resolved.end! - r.resolved.start!, t.length);
    });

    test('a drifted page re-anchors to the full span and persists the new offsets', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final t = 'فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله.';
      final s = norm.indexOf(t);
      final id = await repo.addAnnotation(bookId: 88, pageNumber: 2, normalizedPageText: norm, selectedText: t, charStartHint: s, colorKey: 'memorize', bookName: 'ك');

      final drifted = 'حاشية الناسخ في الأعلى\n\n$norm';
      final resolved = await repo.resolvedAnnotationsForPage(88, 2, drifted);
      expect(resolved.single.resolved.status.name, 'shifted');
      expect(drifted.substring(resolved.single.resolved.start!, resolved.single.resolved.end!), t);

      // persisted: a second call takes the exact path, offsets already updated
      final again = await repo.resolvedAnnotationsForPage(88, 2, drifted);
      expect(again.single.resolved.status.name, 'exact');
      final stored = (await repo.annotationsForPage(88, 2)).single;
      expect(stored.id, id);
      expect(drifted.substring(stored.charStart!, stored.charEnd!), t);
    });

    test('text gone → orphan: not drawable, annotation + note kept', () async {
      final repo = TurathRepository();
      final norm = normalizePageText(_page);
      final t = 'اعلم أنّ الأعمال بالنيّات، وأنّ لكلّ امرئٍ ما نوى.';
      final s = norm.indexOf(t);
      await repo.addAnnotation(bookId: 91, pageNumber: 3, normalizedPageText: norm, selectedText: t, charStartHint: s, colorKey: 'question', noteType: 'question', noteBody: 'سؤال مهم', bookName: 'ك');

      final resolved = await repo.resolvedAnnotationsForPage(91, 3, 'صفحة مختلفة تمامًا بلا أي تطابق');
      expect(resolved.single.resolved.status.name, 'orphan');
      expect(resolved.single.resolved.drawable, isFalse);
      final kept = (await repo.annotationsForPage(91, 3)).single;
      expect(kept.selectedText, t, reason: 'the full text is not lost');
      expect(kept.noteBody, 'سؤال مهم');
    });

    test('a migrated legacy quote is drawn on its page after the first visit', () async {
      final db = await DatabaseHelper.instance.database;
      final norm = normalizePageText(_page);
      final quote = 'قال المصنّف رحمه الله: بابُ ما جاء في الإخلاص والنيّة.';
      await db.insert('turath_quotes', {'book_id': 95, 'book_name': 'ك', 'page_number': 1, 'quoted_text': quote, 'created_at': '1447-01-01'});
      await migrateLegacyToAnnotations(db);

      final repo = TurathRepository();
      final resolved = await repo.resolvedAnnotationsForPage(95, 1, norm);
      expect(resolved, hasLength(1));
      expect(resolved.single.resolved.drawable, isTrue);
      expect(norm.substring(resolved.single.resolved.start!, resolved.single.resolved.end!), quote);
      // status upgraded from 'unanchored' and persisted
      expect((await repo.annotationsForPage(95, 1)).single.anchorStatus, isNot('unanchored'));
    });
  });

  group('legacy migration — no data loss, idempotent', () {
    test('every turath_notes and turath_quotes row becomes an annotation, nothing dropped', () async {
      final db = await DatabaseHelper.instance.database;

      await db.insert('turath_notes', {'book_id': 11, 'book_name': 'كتاب النون', 'page_number': 3, 'selected_text': 'النص المحدد كاملًا هنا', 'note': 'ملاحظة قديمة', 'created_at': '1447-01-01'});
      await db.insert('turath_notes', {'book_id': 11, 'book_name': 'كتاب النون', 'page_number': 4, 'selected_text': null, 'note': 'ملاحظة على مستوى الصفحة', 'created_at': '1447-01-02'});
      await db.insert('turath_quotes', {'book_id': 22, 'book_name': 'كتاب القاف', 'author_name': 'المؤلف', 'volume': '2', 'page_number': 9, 'quoted_text': 'اقتباس حرفي طويل نسبيًا من الكتاب', 'note': 'تعليق على الاقتباس', 'created_at': '1447-02-02'});
      await db.insert('turath_quotes', {'book_id': 22, 'book_name': 'كتاب القاف', 'author_name': null, 'volume': null, 'page_number': 10, 'quoted_text': 'اقتباس بلا تعليق', 'note': null, 'created_at': '1447-02-03'});

      final notesBefore = (await db.query('turath_notes')).length;
      final quotesBefore = (await db.query('turath_quotes')).length;

      await migrateLegacyToAnnotations(db);

      final anns = await db.query('turath_annotations', orderBy: 'source_kind, legacy_id');
      expect(anns.length, notesBefore + quotesBefore, reason: 'one annotation per legacy row, none dropped');

      final fromNote = anns.firstWhere((r) => r['source_kind'] == 'legacy_note' && r['legacy_id'] != null && r['page_number'] == 3);
      expect(fromNote['selected_text'], 'النص المحدد كاملًا هنا');
      expect(fromNote['selected_len'], 'النص المحدد كاملًا هنا'.length);
      expect(fromNote['note_body'], 'ملاحظة قديمة');
      expect(fromNote['book_name'], 'كتاب النون');
      expect(fromNote['anchor_status'], 'unanchored');
      expect(fromNote['created_at'], '1447-01-01');

      final pageLevel = anns.firstWhere((r) => r['source_kind'] == 'legacy_note' && r['page_number'] == 4);
      expect(pageLevel['selected_text'], isNull);
      expect(pageLevel['note_body'], 'ملاحظة على مستوى الصفحة');
      expect(pageLevel['anchor_status'], 'orphan');

      final fromQuote = anns.firstWhere((r) => r['source_kind'] == 'legacy_quote' && r['page_number'] == 9);
      expect(fromQuote['selected_text'], 'اقتباس حرفي طويل نسبيًا من الكتاب');
      expect(fromQuote['note_body'], 'تعليق على الاقتباس');
      expect(fromQuote['author_name'], 'المؤلف');
      expect(fromQuote['volume'], '2');
      expect(fromQuote['color_key'], 'benefit');

      // the old rows are left intact as a safety net
      expect((await db.query('turath_notes')).length, notesBefore);
      expect((await db.query('turath_quotes')).length, quotesBefore);

      // re-running does not duplicate
      await migrateLegacyToAnnotations(db);
      expect((await db.query('turath_annotations')).length, notesBefore + quotesBefore);
    });

    test('a migrated legacy row re-anchors to its full span on the page', () async {
      final db = await DatabaseHelper.instance.database;
      final norm = normalizePageText(_page);
      final quote = 'فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله.';
      await db.insert('turath_quotes', {'book_id': 33, 'book_name': 'ك', 'page_number': 1, 'quoted_text': quote, 'created_at': '1447-03-03'});
      await migrateLegacyToAnnotations(db);

      final repo = TurathRepository();
      final a = (await repo.annotationsForPage(33, 1)).single;
      expect(a.anchorStatus, 'unanchored');
      expect(a.charStart, isNull);

      final resolved = resolveAnchor(norm, StoredAnchor(
        selectedText: a.selectedText, charStart: null, charEnd: null,
        normVersion: 0, textChecksum: null, textLength: null,
        prefixContext: null, suffixContext: null,
        headAnchor: null, tailAnchor: null, occurrenceIndex: 0,
      ));
      expect(resolved.status, AnchorStatus.shifted);
      expect(norm.substring(resolved.start!, resolved.end!), quote,
          reason: 'resolves to the WHOLE quote, not its first word');

      await repo.saveResolvedAnchor(a.id, resolved, normalizedPageText: norm);
      final a2 = (await repo.annotationsForPage(33, 1)).single;
      expect(a2.anchorStatus, 'shifted');
      expect(norm.substring(a2.charStart!, a2.charEnd!), quote);
    });
  });

  group('page notes — the durable alternative to highlighting', () {
    test('addPageNote stores a colour + note with no text anchor, and reads back',
        () async {
      final repo = TurathRepository();
      final id = await repo.addPageNote(
        bookId: 55,
        pageNumber: 4,
        colorKey: 'important',
        noteBody: 'خلاصة هذه الصفحة كاملة',
        bookName: 'شرح تسهيل العقيدة',
        authorName: 'ابن عثيمين',
      );
      expect(id, greaterThan(0));

      final notes = await repo.pageNotesForPage(55, 4);
      expect(notes.length, 1);
      final n = notes.single;
      expect(n.sourceKind, 'page_note');
      expect(n.isPageLevel, isTrue);
      expect(n.selectedText, isNull);
      expect(n.charStart, isNull);
      expect(n.charEnd, isNull);
      expect(n.colorKey, 'important');
      expect(n.noteBody, 'خلاصة هذه الصفحة كاملة');
      expect(n.bookName, 'شرح تسهيل العقيدة');
    });

    test('page notes stay on their own page and do not leak into another', () async {
      final repo = TurathRepository();
      await repo.addPageNote(
          bookId: 55, pageNumber: 4, colorKey: 'benefit', noteBody: 'ص٤',
          bookName: 'كتاب');
      await repo.addPageNote(
          bookId: 55, pageNumber: 9, colorKey: 'benefit', noteBody: 'ص٩',
          bookName: 'كتاب');
      expect((await repo.pageNotesForPage(55, 4)).single.noteBody, 'ص٤');
      expect((await repo.pageNotesForPage(55, 9)).single.noteBody, 'ص٩');
      expect(await repo.pageNotesForPage(55, 5), isEmpty);
    });

    test('resolvedAnnotationsForPage returns the page note without re-anchoring it',
        () async {
      final repo = TurathRepository();
      await repo.addPageNote(
          bookId: 7, pageNumber: 2, colorKey: 'question',
          noteBody: 'سؤال على الصفحة', bookName: 'كتاب');
      final norm = normalizePageText(_page);
      final resolved = await repo.resolvedAnnotationsForPage(7, 2, norm);
      expect(resolved.length, 1);
      expect(resolved.single.annotation.isPageLevel, isTrue);
      expect(resolved.single.resolved.drawable, isFalse,
          reason: 'a page note has no span to draw');
      // still no anchor columns written — status left as stored
      final stored = (await repo.annotationsForPage(7, 2)).single;
      expect(stored.anchorStatus, 'page');
      expect(stored.charStart, isNull);
    });

    test('a page note shows in the unified notebook and can be recoloured + deleted',
        () async {
      final repo = TurathRepository();
      final id = await repo.addPageNote(
          bookId: 3, pageNumber: 1, colorKey: 'benefit',
          noteBody: 'ملاحظة', bookName: 'كتاب');

      var all = await repo.allAnnotations();
      expect(all.any((a) => a.id == id && a.isPageLevel), isTrue);

      await repo.recolorAnnotation(id, 'memorize');
      await repo.updateAnnotationNote(id, noteType: 'memorize', noteBody: 'ملاحظة معدَّلة');
      final n = (await repo.pageNotesForPage(3, 1)).single;
      expect(n.colorKey, 'memorize');
      expect(n.noteBody, 'ملاحظة معدَّلة');
      expect(n.id, id, reason: 'edit keeps the same row');

      await repo.deleteAnnotation(id);
      expect(await repo.pageNotesForPage(3, 1), isEmpty);
    });
  });
}
