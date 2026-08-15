/// "دليل المسلم الجديد" — QURAN_COMPANION_ROADMAP.md §4.9 (5د, expanded
/// 2026-08-15 per Ismail's request to help onboard new Muslims). Fixed
/// content, not DB-driven — same pattern as `wird_templates.dart`.
///
/// Content grounded in mainstream Sunni fiqh matching the already-sourced
/// scholars this app cites for fiqh (Ibn Uthaymeen's "الشرح الممتع" for
/// Taharah, Al-Shuwaie'r's work on the Salah chapter of the same base
/// text) — written here as simplified beginner steps, NOT a verbatim
/// translation of either book.
///
/// HONESTY NOTE on translations: the Arabic and English text below were
/// written directly and checked against standard Sunni practice. The
/// Amharic (`textAm`) is a best-effort AI translation using standard
/// Ethiopian Islamic terminology — it has NOT been reviewed by a native
/// Amharic-speaking scholar or translator. Flag this to users if this
/// guide ships broadly, and get a native review before relying on the
/// Amharic text as authoritative.
library;

class GuideStep {
  final String textAr;
  final String textEn;
  final String textAm;
  const GuideStep({required this.textAr, required this.textEn, required this.textAm});
}

class GuideTopic {
  final String key;
  final String titleAr;
  final String titleEn;
  final String titleAm;
  final List<GuideStep> steps;
  const GuideTopic({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.titleAm,
    required this.steps,
  });
}

const newMuslimGuideTopics = [
  GuideTopic(
    key: 'wudu',
    titleAr: 'الوضوء',
    titleEn: 'Wudu (Ablution)',
    titleAm: 'ውዱእ (የአካል ንጽሕና)',
    steps: [
      GuideStep(
        textAr: 'انوِ الوضوء بقلبك (لا حاجة للفظ النية بلسانك).',
        textEn: 'Make the intention (niyyah) for wudu in your heart — no need to say it out loud.',
        textAm: 'ውዱእ ለማድረግ በልብህ ውስጥ ንቢያ (ማሰብ) አድርግ — በአፍ መናገር አያስፈልግም።',
      ),
      GuideStep(
        textAr: 'قل "بسم الله" قبل البدء.',
        textEn: 'Say "Bismillah" (In the name of Allah) before you begin.',
        textAm: '"ቢስሚላህ" (በአላህ ስም) በል ከመጀመርህ በፊት።',
      ),
      GuideStep(
        textAr: 'اغسل كفّيك ثلاث مرات.',
        textEn: 'Wash both hands up to the wrists, three times.',
        textAm: 'ሁለቱንም እጆችህን እስከ አንጓ ድረስ ሦስት ጊዜ እጠብ።',
      ),
      GuideStep(
        textAr: 'تمضمض واستنشق الماء ثم أخرجه من أنفك، ثلاث مرات.',
        textEn: 'Rinse your mouth and sniff water into your nose then blow it out, three times.',
        textAm: 'አፍህን በውሃ ታጠብ እና ውሃ ወደ አፍንጫህ ውስጥ ጎትተህ አውጣው፣ ሦስት ጊዜ።',
      ),
      GuideStep(
        textAr: 'اغسل وجهك ثلاث مرات (من منابت الشعر إلى الذقن، ومن الأذن إلى الأذن).',
        textEn: 'Wash your face three times — from the hairline to the chin, ear to ear.',
        textAm: 'ፊትህን ሦስት ጊዜ እጠብ — ከጸጉር መስመር እስከ አገጭ፣ ከጆሮ እስከ ጆሮ።',
      ),
      GuideStep(
        textAr: 'اغسل ذراعيك إلى المرفقين ثلاث مرات، ابدأ باليمنى ثم اليسرى.',
        textEn: 'Wash both arms up to and including the elbows, three times — right arm first, then left.',
        textAm: 'ሁለቱንም ክንዶችህን እስከ ክርን ድረስ ሦስት ጊዜ እጠብ — መጀመሪያ ቀኝ፣ ከዚያ ግራ።',
      ),
      GuideStep(
        textAr: 'امسح رأسك مرة واحدة بيديك المبللتين (من مقدمه إلى مؤخره ثم ارجع)، وامسح أذنيك.',
        textEn: 'Wipe your head once with wet hands (front to back, then back to front), and wipe your ears.',
        textAm: 'ራስህን በእርጥብ እጅ አንድ ጊዜ ጥረግ (ከፊት ወደ ኋላ፣ ከዚያ ተመለስ)፣ ጆሮዎችህንም ጥረግ።',
      ),
      GuideStep(
        textAr: 'اغسل قدميك إلى الكعبين ثلاث مرات، ابدأ باليمنى ثم اليسرى.',
        textEn: 'Wash both feet up to and including the ankles, three times — right foot first, then left.',
        textAm: 'ሁለቱንም እግሮችህን እስከ ቁርጭምጭሚት ድረስ ሦስት ጊዜ እጠብ — መጀመሪያ ቀኝ፣ ከዚያ ግራ።',
      ),
      GuideStep(
        textAr: 'حافظ على الترتيب وعدم ترك فاصل طويل بين غسل كل عضو والذي يليه.',
        textEn: 'Keep the steps in this order, without a long pause between one step and the next.',
        textAm: 'ይህንን ቅደም ተከተል ጠብቅ፣ በእያንዳንዱ ደረጃ መካከል ረጅም ማቋረጥ ሳታደርግ።',
      ),
      GuideStep(
        textAr: 'بعد الانتهاء، قل: "أشهد أن لا إله إلا الله وحده لا شريك له، وأشهد أن محمدًا عبده ورسوله".',
        textEn: 'When finished, say: "Ash-hadu an la ilaha illallah wahdahu la sharika lah, wa ash-hadu anna Muhammadan abduhu wa rasuluh" (I bear witness that there is no god but Allah alone, without partner, and that Muhammad is His servant and messenger).',
        textAm: 'ከጨረስክ በኋላ በል፦ "አሽሀዱ አን ላ ኢላሀ ኢለላህ ወሕደሁ ላ ሸሪከ ለሁ፣ ወአሽሀዱ አነ ሙሐመደን ዐብዱሁ ወረሱሉህ" (ከአላህ በስተቀር ሌላ አምላክ እንደሌለ፣ ብቻውን፣ ተጋሪ እንደሌለው፣ እና ሙሐመድ ባሪያውና መልእክተኛው እንደሆኑ እመሰክራለሁ)።',
      ),
    ],
  ),
  GuideTopic(
    key: 'ghusl',
    titleAr: 'الغسل من الجنابة',
    titleEn: 'Ghusl (Ritual Bath) from Janabah',
    titleAm: 'ጉስል (የአካል ሙሉ ንጽሕና) ከጀናባ',
    steps: [
      GuideStep(
        textAr: 'انوِ الغسل بقلبك لرفع الجنابة.',
        textEn: 'Make the intention in your heart to perform ghusl to remove the state of major ritual impurity (janabah).',
        textAm: 'ከጀናባ (ትልቅ ርኩሰት) ለመንጻት ጉስል ለማድረግ በልብህ ንቢያ አድርግ።',
      ),
      GuideStep(
        textAr: 'اغسل يديك قبل إدخالهما في الإناء.',
        textEn: 'Wash your hands before dipping them into your water container.',
        textAm: 'እጆችህን ወደ ውሃ ማጠራቀሚያው ከማስገባትህ በፊት እጠብ።',
      ),
      GuideStep(
        textAr: 'اغسل فرجك وما أصابه من أذى.',
        textEn: 'Wash your private parts and any impurity on them.',
        textAm: 'የግል ክፍልህን እና በእሱ ላይ ያለውን ርኩሰት እጠብ።',
      ),
      GuideStep(
        textAr: 'توضأ وضوءًا كاملًا كوضوء الصلاة.',
        textEn: 'Perform a complete wudu, just as you would for prayer.',
        textAm: 'እንደ ሶላት ውዱእ ሙሉ ውዱእ አድርግ።',
      ),
      GuideStep(
        textAr: 'اغسل رأسك ثلاث مرات، وخلّل الماء في أصول شعرك حتى تتأكد أنه وصل لكل شعرة.',
        textEn: 'Pour water over your head three times, working it into the roots of your hair to make sure it reaches everywhere.',
        textAm: 'ውሃ በራስህ ላይ ሦስት ጊዜ አፍስስ፣ ወደ ጸጉርህ ሥር ውሃው እንዲደርስ አድርገህ አሽት።',
      ),
      GuideStep(
        textAr: 'أفض الماء على جسدك كله، ابدأ بالشق الأيمن ثم الأيسر.',
        textEn: 'Pour water over your entire body, starting with the right side then the left.',
        textAm: 'ውሃ በመላ ሰውነትህ ላይ አፍስስ፣ በቀኝ በኩል ጀምረህ ወደ ግራ ቀጥል።',
      ),
      GuideStep(
        textAr: 'تأكد من وصول الماء لكل مكان في جسدك (تحت الإبطين، السرة، خلف الأذنين، بين الأصابع).',
        textEn: 'Make sure water reaches every part of your body — underarms, navel, behind the ears, between fingers and toes.',
        textAm: 'ውሃ በሰውነትህ ሁሉም ክፍል ላይ መድረሱን አረጋግጥ — ብብት ስር፣ እምብርት፣ ከጆሮ ኋላ፣ በጣቶች መካከል።',
      ),
    ],
  ),
  GuideTopic(
    key: 'istinja',
    titleAr: 'الاستنجاء (آداب قضاء الحاجة)',
    titleEn: 'Istinja (Cleaning After Using the Bathroom)',
    titleAm: 'ኢስቲንጃ (ከመጸዳጃ ቤት በኋላ የመንጻት ስርዓት)',
    steps: [
      GuideStep(
        textAr: 'ادخل الخلاء برجلك اليسرى وقل: "اللهم إني أعوذ بك من الخبث والخبائث"، واخرج برجلك اليمنى.',
        textEn: 'Enter the bathroom with your left foot while saying "Allahumma inni a\'udhu bika minal-khubthi wal-khaba\'ith" (O Allah, I seek refuge in You from male and female devils/impurities), and exit with your right foot.',
        textAm: 'ወደ መጸዳጃ ቤት በግራ እግርህ ግባ እያልክ፦ "አላሁመ ኢኒ አዑዙ ቢከ ሚነል ኹብሲ ወልኸባኢስ" (አላህ ሆይ ከክፉ መናፍስት እጠበቅሃለሁ) በል፣ በቀኝ እግርህም ውጣ።',
      ),
      GuideStep(
        textAr: 'استتر عن أعين الناس.',
        textEn: 'Seek privacy, out of sight of others.',
        textAm: 'ከሰዎች ዓይን ተሰውር።',
      ),
      GuideStep(
        textAr: 'تجنّب استقبال القبلة أو استدبارها إن كنت في فضاء مكشوف.',
        textEn: 'If you\'re in an open area, avoid facing the Qibla or having your back to it.',
        textAm: 'በክፍት ቦታ ከሆንክ ወደ ቂብላ አትግጠም ወይም ጀርባህን አታድርግ።',
      ),
      GuideStep(
        textAr: 'استعمل يدك اليسرى في الاستنجاء، لا اليمنى.',
        textEn: 'Use your left hand for cleaning, not your right hand.',
        textAm: 'ለንጽሕና ግራ እጅህን ተጠቀም፣ ቀኝ እጅህን አትጠቀም።',
      ),
      GuideStep(
        textAr: 'الأفضل الاستنجاء بالماء، أو الجمع بينه وبين المناديل. إن تعذّر الماء يكفي التمسح بثلاثة مناديل أو أحجار نظيفة فأكثر حتى ينظف المحل.',
        textEn: 'Cleaning with water is preferred, or you can combine it with tissue. If water isn\'t available, wiping with at least three clean tissues (or the equivalent) until the area is clean is sufficient.',
        textAm: 'በውሃ መንጻት ይመረጣል፣ ወይም ከናፕኪን ጋር ማዋሃድ ይቻላል። ውሃ ከሌለ፣ ቦታው እስኪነጻ ድረስ ቢያንስ በሦስት ንጹህ ናፕኪን (ወይም ተመሳሳይ) ማጽዳት በቂ ነው።',
      ),
      GuideStep(
        textAr: 'اغسل يديك جيدًا بعد الانتهاء.',
        textEn: 'Wash your hands well when you\'re done.',
        textAm: 'ከጨረስክ በኋላ እጆችህን በደንብ እጠብ።',
      ),
    ],
  ),
  GuideTopic(
    key: 'salah',
    titleAr: 'كيفية الصلاة',
    titleEn: 'How to Pray (Salah)',
    titleAm: 'እንዴት እንደሚሰገድ (ሶላት)',
    steps: [
      GuideStep(
        textAr: 'استقبل القبلة (اتجاه الكعبة)، وانوِ الصلاة بقلبك.',
        textEn: 'Face the Qibla (direction of the Kaaba), and make the intention to pray in your heart.',
        textAm: 'ወደ ቂብላ (የካዕባ አቅጣጫ) ግጠም፣ ለመስገድም በልብህ ንቢያ አድርግ።',
      ),
      GuideStep(
        textAr: 'ارفع يديك وقل "الله أكبر" (تكبيرة الإحرام)، ثم ضع يدك اليمنى على اليسرى فوق صدرك.',
        textEn: 'Raise your hands and say "Allahu Akbar" (God is Greatest) — the opening takbeer — then place your right hand over your left on your chest.',
        textAm: 'እጆችህን አንሳ "አላሁ አክበር" (አላህ ታላቅ ነው) በል — የመክፈቻ ተክቢራ — ከዚያ ቀኝ እጅህን በደረትህ ላይ በግራ እጅህ ላይ አድርግ።',
      ),
      GuideStep(
        textAr: 'اقرأ سورة الفاتحة.',
        textEn: 'Recite Surat Al-Fatiha.',
        textAm: 'ሱረቱል ፋቲሓን አንብብ።',
      ),
      GuideStep(
        textAr: 'اقرأ ما تيسّر من القرآن بعد الفاتحة (في الركعتين الأوليين).',
        textEn: 'Recite any portion of the Quran you know after Al-Fatiha (in the first two rak\'ahs).',
        textAm: 'ከፋቲሓ በኋላ ከቁርአን የምታውቀውን ማንኛውንም ክፍል አንብብ (በመጀመሪያዎቹ ሁለት ረከዓዎች)።',
      ),
      GuideStep(
        textAr: 'اركع قائلًا "الله أكبر"، وضع يديك على ركبتيك، وقل "سبحان ربي العظيم" ثلاث مرات.',
        textEn: 'Bow (ruku) while saying "Allahu Akbar", place your hands on your knees, and say "Subhana Rabbiyal Adheem" (Glory be to my Lord, the Most Great) three times.',
        textAm: '"አላሁ አክበር" እያልክ ተስገድ (ሩኩዕ)፣ እጆችህን በጉልበቶችህ ላይ አድርግ፣ "ሱብሓነ ረቢየል ዐዚም" (የታላቁ ጌታዬ ክብር ይገባዋል) ሦስት ጊዜ በል።',
      ),
      GuideStep(
        textAr: 'ارفع من الركوع قائلًا "سمع الله لمن حمده"، ثم "ربنا ولك الحمد" وأنت واقف.',
        textEn: 'Rise from ruku while saying "Sami\' Allahu liman hamidah" (Allah hears whoever praises Him), then say "Rabbana wa lakal hamd" (Our Lord, praise be to You) while standing.',
        textAm: '"ሰሚዐ አላሁ ሊመን ሐሚደሁ" (አላህ ያመሰገነውን ይሰማል) እያልክ ከሩኩዕ ተነስ፣ ከዚያ "ረበና ወለከል ሐምድ" (ጌታችን ምስጋና ላንተ ይሁን) ቆመህ በል።',
      ),
      GuideStep(
        textAr: 'اسجد قائلًا "الله أكبر" (الجبهة والأنف واليدان والركبتان وأطراف القدمين على الأرض)، وقل "سبحان ربي الأعلى" ثلاث مرات.',
        textEn: 'Prostrate (sujood) while saying "Allahu Akbar" (forehead, nose, hands, knees, and toes touching the ground), and say "Subhana Rabbiyal A\'la" (Glory be to my Lord, the Most High) three times.',
        textAm: '"አላሁ አክበር" እያልክ ስገድ (ግንባር፣ አፍንጫ፣ እጆች፣ ጉልበቶች እና የእግር ጣቶች መሬት ላይ)፣ "ሱብሓነ ረቢየል አዕላ" (የላቀው ጌታዬ ክብር ይገባዋል) ሦስት ጊዜ በል።',
      ),
      GuideStep(
        textAr: 'اجلس بين السجدتين قائلًا "الله أكبر"، وقل "رب اغفر لي".',
        textEn: 'Sit up between the two prostrations while saying "Allahu Akbar", and say "Rabbighfir li" (My Lord, forgive me).',
        textAm: '"አላሁ አክበር" እያልክ በሁለቱ ስግደቶች መካከል ተቀመጥ፣ "ረብ ኢግፊር ሊ" (ጌታዬ ይቅር በለኝ) በል።',
      ),
      GuideStep(
        textAr: 'اسجد السجدة الثانية بنفس الطريقة.',
        textEn: 'Perform the second prostration the same way.',
        textAm: 'ሁለተኛውን ስግደት በተመሳሳይ መንገድ አድርግ።',
      ),
      GuideStep(
        textAr: 'قم للركعة الثانية وكرر من قراءة الفاتحة.',
        textEn: 'Stand up for the second rak\'ah and repeat from reciting Al-Fatiha.',
        textAm: 'ለሁለተኛው ረከዓ ተነስ እና ከፋቲሓ ንባብ ድገም።',
      ),
      GuideStep(
        textAr: 'بعد السجدة الثانية من الركعة الثانية، اجلس للتشهد واقرأ: "التحيات لله والصلوات والطيبات، السلام عليك أيها النبي ورحمة الله وبركاته، السلام علينا وعلى عباد الله الصالحين، أشهد أن لا إله إلا الله وأشهد أن محمدًا عبده ورسوله".',
        textEn: 'After the second prostration of the second rak\'ah, sit for the tashahhud and recite: "At-tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu \'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh, as-salamu \'alayna wa \'ala \'ibadillahis-salihin, ash-hadu an la ilaha illallah wa ash-hadu anna Muhammadan \'abduhu wa rasuluh" (All greetings, prayers, and good deeds are for Allah...).',
        textAm: 'ከሁለተኛው ረከዓ ሁለተኛ ስግደት በኋላ ለተሸሁድ ተቀመጥ እና አንብብ፦ "አትተሒያቱ ሊላሂ ወስሰለዋቱ ወጠይይባት፣ አስሰላሙ ዐለይከ አዩሀ ነቢዩ ወረሕመቱላሂ ወበረካቱህ፣ አስሰላሙ ዐለይና ወዐላ ዒባዲላሂ ስሳሊሒን፣ አሽሀዱ አን ላ ኢላሀ ኢለላህ ወአሽሀዱ አነ ሙሐመደን ዐብዱሁ ወረሱሉህ" (ሰላምታዎች፣ ጸሎቶች እና መልካም ስራዎች ሁሉ ለአላህ ናቸው...)።',
      ),
      GuideStep(
        textAr: 'صلِّ على النبي ﷺ: "اللهم صلِّ على محمد وعلى آل محمد...".',
        textEn: 'Send blessings on the Prophet ﷺ: "Allahumma salli \'ala Muhammad wa \'ala aali Muhammad..." (O Allah, send blessings upon Muhammad and the family of Muhammad...).',
        textAm: 'በነቢዩ ﷺ ላይ ጸሎት አድርግ፦ "አላሁመ ሰሊ ዐላ ሙሐመድ ወዐላ ኣሊ ሙሐመድ..." (አላህ ሆይ በሙሐመድ እና በሙሐመድ ቤተሰብ ላይ ጸሎትህን አድርግ...)።',
      ),
      GuideStep(
        textAr: 'سلّم عن يمينك قائلًا "السلام عليكم ورحمة الله"، ثم عن يسارك بنفس الكلمات، وبذلك تنتهي الصلاة.',
        textEn: 'Turn your head to the right saying "As-salamu \'alaykum wa rahmatullah" (Peace be upon you and Allah\'s mercy), then to the left with the same words — this ends the prayer.',
        textAm: 'ወደ ቀኝ ዞረህ "አስሰላሙ ዐለይኩም ወረሕመቱላህ" (ሰላም በእናንተ ላይ ይሁን፣ የአላህም ምህረት) በል፣ ከዚያ ወደ ግራ በተመሳሳይ ቃላት — በዚህ ሶላቱ ያበቃል።',
      ),
    ],
  ),
];
