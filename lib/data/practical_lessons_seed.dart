/// Hand-curated practical lessons — Phase 3 "مطبّق" pillar,
/// QURAN_COMPANION_ROADMAP.md section 4.8. Deliberately starts with a
/// handful of juz-amma/short surahs (per the roadmap's own scoping — this
/// is editorial content with no ready-made source, unlike the imported
/// tafsir editions) and grows surah by surah in future sessions, not all
/// at once. Each lesson is a short, concrete, doable-today action distilled
/// from these very well-established short surahs' well-known meaning, not
/// quoted verbatim from any single copyrighted source.
class PracticalLessonSeed {
  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final String lessonText;
  final String valueTag;
  const PracticalLessonSeed(this.surah, this.ayahFrom, this.ayahTo, this.lessonText, this.valueTag);
}

const practicalLessonsSeed = [
  PracticalLessonSeed(1, 1, 7, 'استحضر معنى "إياك نعبد وإياك نستعين" قبل أمر تتردد فيه اليوم — اطلب العون من الله قبل أن تتحرك.', 'التوكل'),
  PracticalLessonSeed(112, 1, 4, 'أخلص نيتك اليوم في عمل واحد تفعله — أدّه لله وحده، لا لتُمدح أو يُقال عنك.', 'الإخلاص'),
  PracticalLessonSeed(113, 1, 5, 'استعذ بالله من شر أمر يقلقك اليوم، بدل أن تستسلم للقلق نفسه طوال يومك.', 'التوكل'),
  PracticalLessonSeed(114, 1, 6, 'انتبه اليوم لوسواس نفسك أو وسوسة من حولك، واستعذ بالله منه بدل الاستسلام له.', 'التوكل'),
  PracticalLessonSeed(103, 1, 3, 'اغتنم وقتك اليوم بعمل صالح واحد على الأقل — فالوقت الذي يمضي لا يعود.', 'الصبر'),
  PracticalLessonSeed(108, 1, 3, 'قدّم اليوم شيئًا شكرًا لنعمة أنعم الله بها عليك — صدقة، أو مساعدة، أو حتى كلمة طيبة.', 'الشكر'),
  PracticalLessonSeed(107, 1, 7, 'تفقّد اليوم يتيمًا أو مسكينًا قريبًا منك، ولو بكلمة طيبة أو مساعدة بسيطة.', 'الرحمة'),
  PracticalLessonSeed(110, 1, 3, 'إذا أنعم الله عليك بنجاح اليوم، بادر بالحمد والاستغفار، لا بالإعجاب بنفسك.', 'الشكر'),
];
