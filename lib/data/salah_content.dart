/// "إقامة الصلاة" content — Ismail's request 2026-08-16. Original lessons
/// written for this app, grounded in well-established, uncontroversial
/// Sunni fiqh (arkan/wajibat/sunan of salah are agreed upon across the
/// four madhhabs in their essentials) — not a translation of any single
/// book. `recommendedSalahResources` cites the specific books Ismail
/// named by title/author for learners who want deeper, scholar-authored
/// treatment; their actual text is not reproduced here, same pattern as
/// every other resources screen in this app.
///
/// `salafStories`: a handful of well-known accounts of the Salaf's khushu
/// in prayer, widely circulated across Islamic literature (books like
/// Sifat al-Safwa). Written in original words, deliberately kept to the
/// well-known core of each account rather than embellished with invented
/// detail, and framed honestly as "قصة مشهورة" (a well-known account) —
/// not presented as a precisely chain-verified hadith-grade narration,
/// since that level of isnad verification isn't something to claim
/// without real specialist review.
library;

class SalahLesson {
  final String titleAr;
  final String bodyAr;
  const SalahLesson({required this.titleAr, required this.bodyAr});
}

class SalahLibraryCategory {
  final String key;
  final String titleAr;
  final List<SalahLesson> lessons;
  const SalahLibraryCategory({required this.key, required this.titleAr, required this.lessons});
}

const salahLibrary = [
  SalahLibraryCategory(key: 'arkan', titleAr: 'أركان الصلاة', lessons: [
    SalahLesson(titleAr: 'ما الركن؟', bodyAr: 'الركن جزء أساسي من الصلاة لا تصح الصلاة بدونه، ولا يُجبر تركه بسجود السهو — لو تركته عمدًا أو سهوًا بطلت تلك الركعة، ويجب أن تأتي بركعة بدلها.'),
    SalahLesson(titleAr: 'أركان الصلاة الأربعة عشر', bodyAr: 'القيام مع القدرة، تكبيرة الإحرام، قراءة الفاتحة، الركوع، الرفع منه، السجود على الأعضاء السبعة، الرفع منه، الجلوس بين السجدتين، الطمأنينة في كل ركن، الترتيب بين الأركان، التشهد الأخير، الجلوس له، الصلاة على النبي ﷺ فيه، والتسليمتان.'),
    SalahLesson(titleAr: 'الطمأنينة ركن، لا مجرد أدب', bodyAr: 'كثير من المصلين يستعجلون في الركوع والسجود حتى تصبح الصلاة "نقرًا كنقر الغراب" كما وصفها النبي ﷺ لمن أساء صلاته — الطمأنينة (السكون لحظة قبل الانتقال) ركن أساسي، لا تفصيلًا زائدًا.'),
  ]),
  SalahLibraryCategory(key: 'wajibat', titleAr: 'واجبات الصلاة', lessons: [
    SalahLesson(titleAr: 'الفرق بين الركن والواجب', bodyAr: 'الواجب — خلافًا للركن — إن تُرك سهوًا يُجبر بسجود السهو، ولا تبطل الصلاة به إن كان الترك سهوًا. أما تركه عمدًا فتبطل الصلاة به عند أكثر أهل العلم.'),
    SalahLesson(titleAr: 'واجبات الصلاة', bodyAr: 'من أبرزها: تكبيرات الانتقال (غير تكبيرة الإحرام)، قول "سمع الله لمن حمده" للإمام والمنفرد، قول "ربنا ولك الحمد"، قول "سبحان ربي العظيم" في الركوع مرة، "سبحان ربي الأعلى" في السجود مرة، "رب اغفر لي" بين السجدتين، والتشهد الأول والجلوس له.'),
  ]),
  SalahLibraryCategory(key: 'sunan', titleAr: 'سنن الصلاة', lessons: [
    SalahLesson(titleAr: 'سنن قولية وفعلية', bodyAr: 'السنن لا تبطل الصلاة بتركها عمدًا ولا سهوًا، لكنها من هدي النبي ﷺ الذي كان يحافظ عليه — تركها ينقص الأجر والكمال، لا صحة الصلاة.'),
    SalahLesson(titleAr: 'أمثلة على السنن', bodyAr: 'رفع اليدين عند تكبيرة الإحرام وعند الركوع والرفع منه، دعاء الاستفتاح، الاستعاذة والبسملة قبل الفاتحة، التأمين بعدها، قراءة سورة بعد الفاتحة في الركعتين الأوليين، وضع اليدين على الركبتين مفرّجتي الأصابع في الركوع.'),
  ]),
  SalahLibraryCategory(key: 'mubtilat', titleAr: 'مبطلات الصلاة', lessons: [
    SalahLesson(titleAr: 'ما يُبطل الصلاة', bodyAr: 'من أبرزها: الحدث (انتقاض الوضوء)، الكلام العمد لغير مصلحة الصلاة، الأكل والشرب عمدًا، كثرة الحركة غير الضرورية، انكشاف العورة، واستدبار القبلة عمدًا بلا عذر — تختلف تفاصيل بعضها بين المذاهب، فالرجوع لأهل العلم عند الإشكال أفضل من الاجتهاد الشخصي.'),
  ]),
  SalahLibraryCategory(key: 'khushu', titleAr: 'الخشوع', lessons: [
    SalahLesson(titleAr: 'الخشوع ليس شعورًا تلقائيًا', bodyAr: 'الخشوع اجتهاد وتدريب، لا حالة تأتي بلا سعي. من أعظم أسبابه: فهم معنى ما تقرأ، استحضار عظمة من تقف بين يديه، إبعاد مصادر التشويش قبل الصلاة (الهاتف، الأفكار المعلّقة)، والنظر إلى موضع السجود.'),
    SalahLesson(titleAr: 'علاج الوسوسة والشرود', bodyAr: 'الشرود الطارئ لا يُبطل الصلاة ولا يستحق الشعور بالذنب المفرط — العلاج العملي: إذا شردت، اردد انتباهك بهدوء لما تقرأ دون توبيخ نفسك، فالمحاولة المتكررة نفسها عبادة.'),
  ]),
  SalahLibraryCategory(key: 'adhkar_salah', titleAr: 'أذكار الصلاة', lessons: [
    SalahLesson(titleAr: 'أذكار داخل الصلاة', bodyAr: 'دعاء الاستفتاح، التسبيح في الركوع والسجود، دعاء الجلسة بين السجدتين، التشهد، الصلاة الإبراهيمية — كل ذكر منها موضعه ومعناه، لا مجرد ألفاظ تُقال.'),
    SalahLesson(titleAr: 'أذكار بعد السلام', bodyAr: 'الاستغفار ثلاثًا، "اللهم أنت السلام ومنك السلام..."، التسبيح والتحميد والتكبير (٣٣ مرة لكل، وتمام المئة بـ"لا إله إلا الله وحده لا شريك له...")، وآية الكرسي.'),
  ]),
  SalahLibraryCategory(key: 'tafsir_fatiha', titleAr: 'معاني الفاتحة', lessons: [
    SalahLesson(titleAr: 'لماذا نقرأ الفاتحة في كل ركعة؟', bodyAr: 'الفاتحة ركن في كل ركعة — "لا صلاة لمن لم يقرأ بفاتحة الكتاب" — وهي حوار بين العبد وربه: نصفها الأول ثناء وتمجيد، ونصفها الثاني دعاء بالهداية.'),
    SalahLesson(titleAr: '"إياك نعبد وإياك نستعين"', bodyAr: 'أعظم آية في السورة: تجمع أصلي الدين — إخلاص العبادة لله وحده، والاستعانة به وحده في كل أمر — بينهما لا يُعقل عمل صحيح بلا الاثنين معًا.'),
  ]),
  SalahLibraryCategory(key: 'rawatib', titleAr: 'السنن الرواتب', lessons: [
    SalahLesson(titleAr: 'السنن الرواتب الاثنتا عشرة', bodyAr: 'ركعتان قبل الفجر، أربع قبل الظهر وركعتان بعدها، ركعتان بعد المغرب، وركعتان بعد العشاء — من حافظ عليها بُني له بيت في الجنة كما ورد في الحديث.'),
    SalahLesson(titleAr: 'أفضلها: سنة الفجر', bodyAr: 'ركعتا الفجر تحديدًا وردت فيهما فضيلة خاصة: "ركعتا الفجر خير من الدنيا وما فيها" — يُستحب فيهما التخفيف.'),
  ]),
  SalahLibraryCategory(key: 'qiyam', titleAr: 'قيام الليل', lessons: [
    SalahLesson(titleAr: 'فضل قيام الليل', bodyAr: 'وقت استجابة خاص، وصفه ربنا بقوله "كانوا قليلاً من الليل ما يهجعون" — لا يشترط عددًا معينًا من الركعات، ولو ركعتان خفيفتان بخشوع خير من الانقطاع الكامل.'),
    SalahLesson(titleAr: 'كيف تبدأ؟', bodyAr: 'ابدأ بهدف صغير قابل للاستمرار (ركعتان قبل النوم بنية قيام الليل، أو الاستيقاظ قبل الفجر بعشر دقائق) — الاستمرار على القليل خير من انقطاع الكثير.'),
  ]),
  SalahLibraryCategory(key: 'jamaah', titleAr: 'صلاة الجماعة', lessons: [
    SalahLesson(titleAr: 'فضل الجماعة', bodyAr: '"صلاة الجماعة أفضل من صلاة الفذ بسبع وعشرين درجة" — وهي على الرجال آكد تأكيدًا من على النساء، وفيها من الأخوة والتعارف واجتماع القلوب ما ليس في الصلاة المنفردة.'),
  ]),
];

class SalafStory {
  final String titleAr;
  final String bodyAr;
  const SalafStory({required this.titleAr, required this.bodyAr});
}

const salafStories = [
  SalafStory(
    titleAr: 'علي بن الحسين زين العابدين والنار',
    bodyAr: 'يُروى في قصة مشهورة عن علي بن الحسين (زين العابدين) رحمه الله أنه كان ساجدًا يصلي، فشبّ حريق قريب منه، فجعل من حوله ينادونه: "النار! النار!" وهو لا يرفع رأسه من سجوده حتى أُطفئت، فلما سُئل عن ذلك قال ما معناه: أن نار الآخرة شغلته عن نار الدنيا.',
  ),
  SalafStory(
    titleAr: 'استخراج السهم في الصلاة',
    bodyAr: 'من القصص المشهورة في كتب السيرة والزهد أن أحد الصالحين أُصيب بسهم في معركة فتعذّر نزعه لشدة الألم، فقيل لهم: انتظروا حتى يدخل في الصلاة وانزعوه حينئذ، ففعلوا وهو ساجد، فلم يشعر بذلك حتى أُخبر بعد فراغه من صلاته — دلالة على غياب الحس عن كل شيء سوى الوقوف بين يدي الله.',
  ),
  SalafStory(
    titleAr: 'سعيد بن المسيّب والصف الأول',
    bodyAr: 'يُذكر عن التابعي الجليل سعيد بن المسيّب أنه لم يفته التكبيرة الأولى مع الإمام في المسجد لعشرات السنين — مثال على المحافظة الدائمة على الصلاة في وقتها وأول وقتها، لا مجرد أداء متأخر أو متقطع.',
  ),
];

class SalahResource {
  final String titleAr;
  final String authorAr;
  final String noteAr;
  const SalahResource({required this.titleAr, required this.authorAr, required this.noteAr});
}

const recommendedSalahResources = [
  SalahResource(titleAr: 'صفة صلاة النبي ﷺ', authorAr: 'محمد ناصر الدين الألباني', noteAr: 'من أشهر كتب صفة الصلاة، يذكر كيفية الصلاة كاملة من التكبير إلى السلام مع الأدلة الحديثية لكل خطوة.'),
  SalahResource(titleAr: 'صفة صلاة النبي ﷺ', authorAr: 'عبد العزيز بن باز', noteAr: 'شرح مختصر وواضح للسنة العملية في الصلاة، مناسب للمبتدئ.'),
  SalahResource(titleAr: 'شرح صفة صلاة النبي ﷺ', authorAr: 'محمد بن صالح العثيمين', noteAr: 'أعمق من مجرد الحركات — يشرح مسائل الطمأنينة والقراءة والركوع والسجود والأذكار بتفصيل فقهي.'),
  SalahResource(titleAr: 'الخشوع في الصلاة', authorAr: 'ابن رجب الحنبلي', noteAr: 'أهم مرجع كلاسيكي في موضوع الخشوع تحديدًا — حضور القلب ومجاهدة النفس أثناء الصلاة.'),
  SalahResource(titleAr: 'الوابل الصيّب من الكلم الطيّب', authorAr: 'ابن القيّم الجوزية', noteAr: 'ليس خاصًا بالصلاة فقط، لكنه ممتاز لفهم الذكر وحياة القلب وأثرهما على الصلاة.'),
  SalahResource(titleAr: 'مدارج السالكين', authorAr: 'ابن القيّم الجوزية', noteAr: 'كتاب أعمق بكثير — يساعد على فهم مقامات العبودية والإخلاص والخشوع وحضور القلب. جزء منه متوفر فعلًا داخل هذا التطبيق.'),
];
