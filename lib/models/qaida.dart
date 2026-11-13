// The Noorani Qaida (القاعدة النورانية) — data shapes for
// `assets/qaida/qaida_lessons.json`, which `tool/qaida/build_lessons.py`
// generates (the one source for the app and for the recording list).

/// The lessons, in order. Kept here (not only in the JSON) so progress
/// counts — e.g. the curriculum map — need no asset load;
/// `test/qaida_test.dart` holds it equal to the JSON.
const kQaidaLessonIds = ['q01', 'q02', 'q03', 'q04', 'q05', 'q06', 'q07', 'q08', 'q09'];

/// Progress key in `arabic_curriculum_progress` for a finished lesson.
String qaidaProgressKey(String lessonId) => 'qaida_$lessonId';

class QaidaItem {
  /// What is shown, fully vocalized.
  final String text;

  /// The recorded sound: `assets/qaida/audio/<audioId>.m4a`. Items that
  /// sound the same (a letter and its joined shapes) share one id.
  final String audioId;

  /// The mushaf reference (`surah:ayah`) for the disjointed letters.
  final String? ref;

  const QaidaItem({required this.text, required this.audioId, this.ref});

  String get assetPath => 'assets/qaida/audio/$audioId.m4a';

  factory QaidaItem.fromJson(Map<String, dynamic> j) =>
      QaidaItem(text: j['t'] as String, audioId: j['a'] as String, ref: j['ref'] as String?);
}

class QaidaLesson {
  final String id;
  final int columns;
  final List<QaidaItem> items;
  const QaidaLesson({required this.id, required this.columns, required this.items});

  /// 1-based lesson number.
  int get number => kQaidaLessonIds.indexOf(id) + 1;
  String get titleKey => 'qaida_${id}_title';
  String get noteKey => 'qaida_${id}_note';

  /// Each sound once, in first-appearance order (what «استمع للدرس» plays).
  List<QaidaItem> get distinctSounds {
    final seen = <String>{};
    return [for (final i in items) if (seen.add(i.audioId)) i];
  }

  factory QaidaLesson.fromJson(Map<String, dynamic> j) => QaidaLesson(
        id: j['id'] as String,
        columns: j['cols'] as int,
        items: [for (final i in (j['items'] as List)) QaidaItem.fromJson(i as Map<String, dynamic>)],
      );
}
