import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/hifz/juz_shelf_3d.dart';

void main() {
  test('nothing memorized → every juzʼ empty', () {
    expect(juzMemorizedFractions({}), everyElement(0.0));
  });

  test('surahs 78–114 fill exactly juzʼ 30', () {
    final f = juzMemorizedFractions({for (var s = 78; s <= 114; s++) s});
    expect(f[29], 1.0);
    expect(f.take(29), everyElement(0.0));
  });

  test('al-Fatiha is 7 of juzʼ 1\'s 148 ayat; al-Baqara spans juzʼ 1–3', () {
    expect(juzMemorizedFractions({1})[0], closeTo(7 / 148, 1e-9));
    final b = juzMemorizedFractions({2});
    expect(b[0], closeTo(141 / 148, 1e-9));
    expect(b[1], 1.0);
    expect(b[2], closeTo(34 / 126, 1e-9)); // 2:253–286 of juzʼ 3
  });

  test('the whole Quran fills all 30', () {
    expect(juzMemorizedFractions({for (var s = 1; s <= 114; s++) s}), everyElement(1.0));
  });
}
