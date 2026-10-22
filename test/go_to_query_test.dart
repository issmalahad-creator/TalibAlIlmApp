import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/mushaf/go_to_query.dart';

void main() {
  const p = GoToKind.page, j = GoToKind.juz, h = GoToKind.hizb, s = GoToKind.surah, a = GoToKind.ayah;

  test('numbers in any digit set', () {
    expect(parseGoToQuery('٣٢٣'), [const GoToHit(p, 323)]);
    expect(parseGoToQuery('18'), [const GoToHit(p, 18), const GoToHit(j, 18), const GoToHit(s, 18)]);
    expect(parseGoToQuery('700'), isEmpty);
  });

  test('keyword + number', () {
    expect(parseGoToQuery('جزء ١٧'), [const GoToHit(j, 17)]);
    expect(parseGoToQuery('الجزء 30'), [const GoToHit(j, 30)]);
    expect(parseGoToQuery('حزب ٣٣'), [const GoToHit(h, 33)]);
    expect(parseGoToQuery('ص 581'), [const GoToHit(p, 581)]);
    expect(parseGoToQuery('صفحة ٥٠'), [const GoToHit(p, 50)]);
    expect(parseGoToQuery('juz 3'), [const GoToHit(j, 3)]);
  });

  test('surah names with or without «ال» / «سورة»', () {
    expect(parseGoToQuery('الكهف').first, const GoToHit(s, 18));
    expect(parseGoToQuery('كهف').first, const GoToHit(s, 18));
    expect(parseGoToQuery('سورة يس').first, const GoToHit(s, 36));
    expect(parseGoToQuery('بقر').first, const GoToHit(s, 2));
  });

  test('surah + ayah', () {
    expect(parseGoToQuery('البقرة ٢٥٥').first, const GoToHit(a, 2, 255));
    expect(parseGoToQuery('2:255'), [const GoToHit(a, 2, 255)]);
    expect(parseGoToQuery('٢:٢٥٥'), [const GoToHit(a, 2, 255)]);
    expect(parseGoToQuery('الفاتحة 9'), isEmpty);
  });
}
