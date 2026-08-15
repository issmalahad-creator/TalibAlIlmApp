/// "باب الأدب" — Ismail's request 2026-08-15: a manners/character pillar,
/// plus a companion set on the value of staying close to the Quran daily.
/// Same pattern as `practical_lessons_seed.dart`: short, concrete, actionable
/// lessons written directly by Claude, inspired by well-established Islamic
/// teachings on character and Quran recitation — not verbatim quotations
/// from any specific hadith collection or its translation. Grows over time,
/// not meant to be exhaustive from day one.
class AdabLesson {
  final String lessonText;
  final String theme;
  const AdabLesson({required this.lessonText, required this.theme});
}

const adabLessonsSeed = [
  AdabLesson(
    lessonText: 'حسن الخلق ليس شعارًا بل سلوك يومي — اختر اليوم موقفًا واحدًا تتعامل فيه بابتسامة وكلمة طيبة بدل الانفعال.',
    theme: 'حسن الخلق',
  ),
  AdabLesson(
    lessonText: 'التزم الصدق اليوم في أمر قد يكون فيه إغراء للكذب أو المبالغة، ولو كان صغيرًا.',
    theme: 'الصدق',
  ),
  AdabLesson(
    lessonText: 'اتصل بأحد والديك أو زره اليوم، أو أدِّ له خدمة بسيطة دون أن يطلبها منك.',
    theme: 'بر الوالدين',
  ),
  AdabLesson(
    lessonText: 'تواصل اليوم مع قريب انقطعت عنه — رسالة قصيرة أو اتصال كافٍ لصلة الرحم.',
    theme: 'صلة الرحم',
  ),
  AdabLesson(
    lessonText: 'اسأل عن حال جارك اليوم، أو قدّم له شيئًا بسيطًا — الجوار له مكانة كبيرة في هدي النبي ﷺ.',
    theme: 'حسن الجوار',
  ),
  AdabLesson(
    lessonText: 'إذا شعرت بالغضب اليوم، توقف قبل أن تتكلم أو تتصرف — التحكم بالنفس عند الغضب علامة القوة الحقيقية.',
    theme: 'كظم الغيظ',
  ),
  AdabLesson(
    lessonText: 'ابحث اليوم عن فرصة لمساعدة شخص محتاج أو ضعيف — الرحمة بالخلق سبب لرحمة الله بك.',
    theme: 'الرحمة',
  ),
  AdabLesson(
    lessonText: 'ابدأ اليوم بالسلام على من تعرفهم ومن لا تعرفهم — عادة بسيطة تبني الألفة بين الناس.',
    theme: 'إفشاء السلام',
  ),
  AdabLesson(
    lessonText: 'إن استضفت أحدًا اليوم أو زرت أحدًا، أحسن الضيافة — إكرام الضيف من علامات الإيمان الحقيقي.',
    theme: 'إكرام الضيف',
  ),
  AdabLesson(
    lessonText: 'راقب لسانك اليوم — إن لم يكن ما ستقوله خيرًا، فالصمت أفضل.',
    theme: 'حفظ اللسان',
  ),
  AdabLesson(
    lessonText: 'ابتسم في وجه من تلقاه اليوم — أبسط عمل يمكن أن يكون له أجر عظيم.',
    theme: 'حسن الخلق',
  ),
  AdabLesson(
    lessonText: 'أزل اليوم أذى واحدًا عن طريق الناس (زجاجة مكسورة، عائق، قمامة) — الإيمان يشمل أدق التفاصيل.',
    theme: 'حسن الخلق',
  ),
];

const quranVirtueLessonsSeed = [
  AdabLesson(
    lessonText: 'إن كنت تحفظ آية أو صفحة، علّمها لشخص آخر اليوم — تعليم القرآن من أفضل ما يمكن أن تفعله.',
    theme: 'فضل تعلم القرآن وتعليمه',
  ),
  AdabLesson(
    lessonText: 'اقرأ اليوم من القرآن ولو لم تفهم كل كلمة بسهولة — من يجتهد رغم الصعوبة له أجر مضاعف.',
    theme: 'أجر من يتعب في القراءة',
  ),
  AdabLesson(
    lessonText: 'اجعل قراءتك اليوم بتمهل وتدبر، لا بسرعة لإنهاء الورد فقط — الترتيل يرفع درجتك عند كل آية.',
    theme: 'الترتيل والتدبر',
  ),
  AdabLesson(
    lessonText: 'لا تكتفِ بحفظ القرآن — اسأل نفسك اليوم: هل غيّر ما حفظته شيئًا في تصرفاتي؟',
    theme: 'أثر القرآن في الحياة',
  ),
  AdabLesson(
    lessonText: 'حافظ على وردك اليومي من القرآن ولو آيات قليلة — القرآن يتفلّت من الصدر إن لم يُتعاهد باستمرار.',
    theme: 'المداومة على المراجعة',
  ),
  AdabLesson(
    lessonText: 'اقرأ اليوم عشر آيات على الأقل قبل النوم — عادة بسيطة توصلك بالقرآن كل يوم دون انقطاع.',
    theme: 'المداومة على الورد',
  ),
];
