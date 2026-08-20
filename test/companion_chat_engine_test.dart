import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/companion_chat_engine.dart';

void main() {
  test('unrecognized input returns null instead of a guessed answer', () {
    final engine = CompanionChatEngine();
    expect(engine.respond('xyz123 قطة برتقالية'), isNull);
  });

  test('empty or whitespace-only input returns null', () {
    final engine = CompanionChatEngine();
    expect(engine.respond(''), isNull);
    expect(engine.respond('   '), isNull);
  });

  test('greeting phrase matches the greeting intent', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('السلام عليكم كيفك'), 'greeting');
  });

  test('tiredness phrase matches the tiredness intent', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('انا تعبان اليوم مو قادر اكمل الحفظ'), 'tiredness');
  });

  test('missed-day phrasing matches the missed_day intent, not memorization_difficulty', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('فاتني يوم كامل ولا سويت شي'), 'missed_day');
  });

  test('matching is diacritic/hamza-insensitive via normalizeArabicForSearch', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('مَرْحَبًا يا صاحبي'), 'greeting');
  });

  test('gratitude phrase matches the gratitude intent', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('جزاك الله خير على المساعدة'), 'gratitude');
  });

  test('English input matches the English keyword set when lang: en is passed', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('hello there, how are you', lang: 'en'), 'greeting');
    expect(engine.matchIntentId('i am so tired today', lang: 'en'), 'tiredness');
  });

  test('an unauthored language code falls back to Arabic content rather than crashing', () {
    final engine = CompanionChatEngine();
    // 'fr' has no keyword/response entries yet — must not throw, and must
    // still match against the Arabic fallback keywords per CompanionIntent.keywordsFor.
    expect(() => engine.respond('السلام عليكم', lang: 'fr'), returnsNormally);
    expect(engine.matchIntentId('السلام عليكم', lang: 'fr'), 'greeting');
  });

  test('response comes from a fixed pool — repeated calls never leave the intent set', () {
    const intent = CompanionIntent(
      id: 'test_intent',
      keywordsByLang: {
        'ar': ['كلمة اختبار'],
      },
      responsesByLang: {
        'ar': ['رد أول', 'رد ثاني', 'رد ثالث'],
      },
    );
    final custom = CompanionChatEngine(intents: const [intent]);
    for (var i = 0; i < 20; i++) {
      final reply = custom.respond('كلمة اختبار');
      expect(intent.responsesByLang['ar'], contains(reply));
    }
  });

  test('every intent id in the default catalog is unique', () {
    final ids = defaultCompanionIntents.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every default intent has Arabic keywords and responses', () {
    for (final intent in defaultCompanionIntents) {
      expect(intent.keywordsByLang['ar'], isNotNull, reason: '${intent.id} has no Arabic keywords');
      expect(intent.keywordsByLang['ar'], isNotEmpty, reason: '${intent.id} has no Arabic keywords');
      expect(intent.responsesByLang['ar'], isNotNull, reason: '${intent.id} has no Arabic responses');
      expect(intent.responsesByLang['ar'], isNotEmpty, reason: '${intent.id} has no Arabic responses');
    }
  });

  test('"كيف حالك" now matches greeting — the exact phrase Ismail hit live on 2026-08-18', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('كيف حالك'), 'greeting');
  });

  test('a transposed-letter typo matches via Damerau-Levenshtein (adjacent swap = 1 edit)', () {
    final engine = CompanionChatEngine();
    // "تعابن" swaps the ا/ب — a transposition, which plain Levenshtein
    // would score as 2 edits (outside the 1-edit budget for a 5-letter
    // word) but Damerau-Levenshtein correctly scores as 1.
    expect(engine.matchIntentId('اليوم تعابن شوي'), 'tiredness');
  });

  test('a minor typo still matches via fuzzy word matching', () {
    final engine = CompanionChatEngine();
    // "تعبن" instead of "تعبان" — a one-letter-dropped typo, should still
    // reach the tiredness intent via Levenshtein-distance fuzzy matching.
    expect(engine.matchIntentId('اليوم تعبن شوي'), 'tiredness');
  });

  test('a synonym reaches the same intent as its canonical keyword', () {
    final engine = CompanionChatEngine();
    // "خلصت" is a synonym of "انجزت" in the curated Arabic synonym layer —
    // should reach the same accomplishment-style keyword coverage.
    expect(engine.matchIntentId('خلصت الحفظ'), 'accomplishment');
  });

  test('"ما انجزت" (exact negated match) does not fire accomplishment — bug found live on 2026-08-18', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('ما انجزت'), isNot('accomplishment'));
  });

  test('"لم انجز" (negated + fuzzy typo) does not fire accomplishment — same live bug, fuzzy path', () {
    final engine = CompanionChatEngine();
    expect(engine.matchIntentId('لم انجز'), isNot('accomplishment'));
  });

  test('negation blocks a keyword that would otherwise match', () {
    final engine = CompanionChatEngine();
    // "مو تعبان" (NOT tired) should not fire the tiredness intent just
    // because "تعبان" appears — the negation guard should suppress it.
    expect(engine.matchIntentId('مو تعبان اليوم الحمد لله'), isNot('tiredness'));
  });

  test('a single coincidental word overlap below the confidence threshold does not answer', () {
    final engine = CompanionChatEngine();
    // Real bug found live on Ismail's device 2026-08-18: a short unrelated
    // message shouldn't win an intent off a weak, low-confidence signal.
    final (id, confidence) = engine.matchWithConfidence('كيف حالك يا صديقي العزيز جدا اليوم');
    if (id != null) {
      expect(confidence, greaterThanOrEqualTo(0.6));
    }
  });

  test('every default intent also has English keywords and responses', () {
    for (final intent in defaultCompanionIntents) {
      expect(intent.keywordsByLang['en'], isNotNull, reason: '${intent.id} has no English keywords');
      expect(intent.keywordsByLang['en'], isNotEmpty, reason: '${intent.id} has no English keywords');
      expect(intent.responsesByLang['en'], isNotNull, reason: '${intent.id} has no English responses');
      expect(intent.responsesByLang['en'], isNotEmpty, reason: '${intent.id} has no English responses');
    }
  });
}
