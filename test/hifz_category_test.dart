import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/memorization_repository.dart';
import 'package:talib_alilm_app/utils/hijri_date.dart';

MemorizationUnit _unitMemorizedDaysAgo(int days) {
  final date = DateTime.now().subtract(Duration(days: days));
  return MemorizationUnit(
    id: 1,
    surahStart: 1,
    ayahStart: 1,
    surahEnd: 1,
    ayahEnd: 7,
    status: 'reviewing',
    memorizedDate: hijriDateStringForDate(date),
  );
}

void main() {
  test('a page memorized today is سبق', () {
    expect(_unitMemorizedDaysAgo(0).hifzCategory(), HifzCategory.sabaq);
  });

  test('a page memorized within the last 15 days is سبقي', () {
    expect(_unitMemorizedDaysAgo(1).hifzCategory(), HifzCategory.sabqi);
    expect(_unitMemorizedDaysAgo(15).hifzCategory(), HifzCategory.sabqi);
  });

  test('a page memorized more than 15 days ago is منزل', () {
    expect(_unitMemorizedDaysAgo(16).hifzCategory(), HifzCategory.manzil);
    expect(_unitMemorizedDaysAgo(90).hifzCategory(), HifzCategory.manzil);
  });

  test('a page never memorized has no category', () {
    final unit = MemorizationUnit(id: 1, surahStart: 1, ayahStart: 1, surahEnd: 1, ayahEnd: 7, status: 'not_started');
    expect(unit.hifzCategory(), HifzCategory.notStarted);
  });
}
