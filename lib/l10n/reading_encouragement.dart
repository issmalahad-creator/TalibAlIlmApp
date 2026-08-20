import 'dart:math';

/// Pools of short "gym coach" encouragement lines for the daily
/// Quran-reading minutes countdown (2026-08-17, Ismail: "مثل المدرب في
/// النوادي... تحسن مستمر ولو بسيط") — several phrases per outcome so the
/// same line doesn't repeat every day, one picked at random per
/// completion. Same honesty note as `basic_translations.dart`: only
/// Arabic/English are human-confident, the rest are AI-translated
/// best-effort.
enum ReadingTrend { improved, same, less, first }

const readingEncouragementPhrases = <String, Map<String, List<String>>>{
  'improved': {
    'ar': ['أحسنت! تقدّمت خطوة عن أمس 💪', 'استمر هكذا — كل دقيقة زيادة تُبنى عليها', 'قوة ثابتة، وارتفاع مستمر — واصل'],
    'en': ["Well done! A step up from yesterday 💪", 'Keep it up — every extra minute builds on the last', 'Steady strength, steady growth — carry on'],
    'am': ['በጣም ጥሩ! ከትናንት አንድ እርምጃ ገፋህ 💪', 'እንደዚህ ቀጥል — እያንዳንዷ ተጨማሪ ደቂቃ ትጠቅማለች', 'ቋሚ ጥንካሬ፣ ቀጣይ እድገት — ቀጥል'],
    'fr': ["Bravo ! Un pas de plus qu'hier 💪", 'Continue ainsi — chaque minute de plus compte', 'Force constante, progression continue — poursuis'],
    'sw': ['Hongera! Umepiga hatua zaidi kuliko jana 💪', 'Endelea hivyo — kila dakika ya ziada ina thamani', 'Nguvu thabiti, maendeleo endelevu — endelea'],
    'ur': ['شاباش! کل سے ایک قدم آگے 💪', 'اسی طرح جاری رکھیں — ہر اضافی منٹ اہم ہے', 'مستقل قوت، مسلسل ترقی — جاری رکھیں'],
    'tr': ["Aferin! Dünden bir adım öndesin 💪", 'Böyle devam et — her fazladan dakika değerli', 'İstikrarlı güç, sürekli gelişim — devam et'],
    'id': ['Bagus sekali! Selangkah lebih maju dari kemarin 💪', 'Terus lanjutkan — setiap menit tambahan berarti', 'Kekuatan stabil, kemajuan berkelanjutan — teruskan'],
    'bn': ['চমৎকার! গতকালের চেয়ে এক ধাপ এগিয়ে 💪', 'এভাবেই চালিয়ে যান — প্রতিটি অতিরিক্ত মিনিট গুরুত্বপূর্ণ', 'স্থির শক্তি, ক্রমাগত উন্নতি — চালিয়ে যান'],
    'ha': ['Madalla! Wani mataki gaba da jiya 💪', 'Ci gaba haka — kowane ƙarin minti yana da amfani', 'Ƙarfi tabbatacce, ci gaba mai ɗorewa — ci gaba'],
    'so': ['Waad ku mahadsan tahay! Tallaabo ka horeysay shalay 💪', 'Sidaas u sii wad — daqiiqad kasta oo dheeraad ah way muhiim tahay', 'Xoog joogto ah, horumar joogto ah — sii wad'],
    'fa': ['آفرین! یک قدم جلوتر از دیروز 💪', 'همینطور ادامه بده — هر دقیقه اضافه ارزشمند است', 'قدرت ثابت، پیشرفت مداوم — ادامه بده'],
    'ms': ['Syabas! Selangkah lebih maju dari semalam 💪', 'Teruskan begini — setiap minit tambahan bermakna', 'Kekuatan stabil, kemajuan berterusan — teruskan'],
  },
  'same': {
    'ar': ['ثبات رائع — استمراريتك هي القوة الحقيقية', 'حافظت على نفس الوتيرة، وهذا نجاح بحد ذاته', 'الانتظام أهم من الكم — أحسنت'],
    'en': ["Great consistency — that's real strength", "You kept the same pace, and that's a win on its own", 'Consistency matters more than quantity — well done'],
    'am': ['ግሩም ወጥነት — ቀጣይነትህ እውነተኛ ጥንካሬ ነው', 'ተመሳሳይ ፍጥነት ጠበቅህ፣ ይህም ራሱ ስኬት ነው', 'ወጥነት ከመጠን ይበልጣል — በጣም ጥሩ'],
    'fr': ["Belle constance — ta régularité est une vraie force", 'Tu as gardé le même rythme, et c\'est déjà une victoire', 'La régularité compte plus que la quantité — bravo'],
    'sw': ['Uthabiti mzuri — uthabiti wako ni nguvu ya kweli', 'Umedumisha kasi ile ile, na huo ni ushindi wenyewe', 'Uthabiti ni muhimu kuliko wingi — hongera'],
    'ur': ['شاندار استقامت — آپ کا تسلسل ہی اصل طاقت ہے', 'آپ نے وہی رفتار برقرار رکھی، اور یہ اپنی جگہ کامیابی ہے', 'باقاعدگی مقدار سے زیادہ اہم ہے — شاباش'],
    'tr': ['Harika istikrar — sürekliliğin gerçek güç', 'Aynı hızı korudun, bu da başlı başına bir başarı', 'Süreklilik miktardan önemlidir — aferin'],
    'id': ['Konsistensi yang luar biasa — keajekanmu adalah kekuatan sejati', 'Anda mempertahankan ritme yang sama, dan itu sudah menjadi kemenangan', 'Konsistensi lebih penting daripada jumlah — bagus sekali'],
    'bn': ['দারুণ ধারাবাহিকতা — আপনার ধারাবাহিকতাই আসল শক্তি', 'একই গতি বজায় রেখেছেন, এটাই একটা সাফল্য', 'পরিমাণের চেয়ে ধারাবাহিকতা গুরুত্বপূর্ণ — চমৎকার'],
    'ha': ['Daidaito mai kyau — ci gabanka shine ainihin ƙarfi', 'Ka ci gaba da irin wannan saurin, wannan kansa nasara ce', 'Daidaito ya fi yawa muhimmanci — madalla'],
    'so': ['Joogtaynta wanaagsan — sii wadidaadu waa xoogga dhabta ah', 'Waxaad sii wadday isla xawaaraha, taasina waa guul keligeed ah', 'Joogtaynta ayaa ka muhiimsan tirada — waad ku mahadsan tahay'],
    'fa': ['ثبات فوق‌العاده — تداوم تو قدرت واقعی است', 'همان سرعت را حفظ کردی، و این خودش موفقیت است', 'ثبات مهم‌تر از مقدار است — آفرین'],
    'ms': ['Konsisten yang hebat — keteguhan anda adalah kekuatan sebenar', 'Anda mengekalkan rentak yang sama, dan itu satu kejayaan', 'Konsistensi lebih penting daripada kuantiti — syabas'],
  },
  'less': {
    'ar': ['لا بأس، أنجزت اليوم — غدًا خطوة أخرى بإذن الله', 'كل دقيقة تُحسب، مهما كانت — استمر', 'لا تقارن نفسك إلا بأمسك — وقد بدأت بالفعل'],
    'en': ['No worries, you still showed up today — another step tomorrow, God willing', 'Every minute counts, however small — keep going', 'Only compare yourself to yesterday\'s you — and you already started'],
    'am': ['ችግር የለም፣ ዛሬ አድርገሃል — ነገ ሌላ እርምጃ በአላህ ፈቃድ', 'እያንዳንዷ ደቂቃ ትቆጠራለች፣ ምንም ያህል ብትሆን — ቀጥል', 'ራስህን ከትናንትናህ ጋር ብቻ አወዳድር — እና ቀድሞውኑ ጀምረሃል'],
    'fr': ["Ce n'est pas grave, tu l'as fait aujourd'hui — un autre pas demain, si Dieu le veut", 'Chaque minute compte, même petite — continue', "Compare-toi seulement à toi d'hier — et tu as déjà commencé"],
    'sw': ['Hakuna shida, umefanya leo — hatua nyingine kesho, Mungu akipenda', 'Kila dakika ina thamani, hata ikiwa ndogo — endelea', 'Jilinganishe na wewe wa jana pekee — na tayari umeanza'],
    'ur': ['کوئی بات نہیں، آپ نے آج کر لیا — کل ایک اور قدم، اللہ نے چاہا تو', 'ہر منٹ اہم ہے، خواہ کتنا ہی چھوٹا ہو — جاری رکھیں', 'صرف اپنے کل کے مقابلے میں خود کو دیکھیں — اور آپ پہلے ہی شروع کر چکے ہیں'],
    'tr': ['Sorun değil, bugün yine de yaptın — yarın bir adım daha, inşallah', 'Ne kadar küçük olursa olsun her dakika değerli — devam et', 'Sadece dünkü haline kıyasla kendini — ve zaten başladın'],
    'id': ['Tidak apa-apa, Anda tetap melakukannya hari ini — langkah lain besok, insyaAllah', 'Setiap menit berarti, sekecil apa pun — teruslah', 'Bandingkan dirimu hanya dengan dirimu kemarin — dan Anda sudah memulainya'],
    'bn': ['কোনো সমস্যা নেই, আজও করেছেন — আগামীকাল আরেক ধাপ, ইনশাআল্লাহ', 'প্রতিটি মিনিট গুরুত্বপূর্ণ, যত ছোটই হোক — চালিয়ে যান', 'শুধু গতকালের নিজের সাথে তুলনা করুন — আর আপনি ইতিমধ্যে শুরু করেছেন'],
    'ha': ['Babu matsala, ka yi shi yau — wani mataki gobe, in Allah ya so', 'Kowane minti yana da amfani, ko da ƙarami ne — ci gaba', 'Kwatanta kanka da kai na jiya kawai — kuma ka riga ka fara'],
    'so': ['Waxba ha ku dhicin, maanta waad qabatay — berri tallaabo kale, Ilaahay idmo haddii uu doono', 'Daqiiqad kasta way muhiim tahay, si kasta oo ay u yartahay — sii wad', 'Naftaada kaliya kula barbardhig shalaydaadii — waadna hore u bilowday'],
    'fa': ['اشکالی ندارد، امروز هم انجامش دادی — فردا قدمی دیگر، ان‌شاءالله', 'هر دقیقه ارزش دارد، هر چقدر هم کوچک — ادامه بده', 'خودت را فقط با دیروز خودت مقایسه کن — و تو قبلاً شروع کرده‌ای'],
    'ms': ['Tidak mengapa, anda tetap melakukannya hari ini — satu lagi langkah esok, insyaAllah', 'Setiap minit bermakna, walau sekecil mana — teruskan', 'Bandingkan diri anda hanya dengan diri semalam — dan anda sudah pun bermula'],
  },
  'first': {
    'ar': ['أول جلسة موثّقة — بداية طيبة بإذن الله', 'خطوتك الأولى أهم خطوة — أحسنت', 'بدأت اليوم، وهذا كل ما يهم'],
    'en': ['Your first recorded session — a fine start, God willing', 'Your first step is the most important one — well done', 'You started today, and that\'s what matters'],
    'am': ['የመጀመሪያ የተመዘገበ ክፍለ ጊዜህ — መልካም መጀመሪያ በአላህ ፈቃድ', 'የመጀመሪያ እርምጃህ በጣም አስፈላጊው ነው — በጣም ጥሩ', 'ዛሬ ጀምረሃል፣ እና ይህ ብቻ ነው የሚያሳስበው'],
    'fr': ["Ta première séance enregistrée — un bon début, si Dieu le veut", 'Ton premier pas est le plus important — bravo', 'Tu as commencé aujourd\'hui, et c\'est ce qui compte'],
    'sw': ['Kipindi chako cha kwanza kilichorekodiwa — mwanzo mzuri, Mungu akipenda', 'Hatua yako ya kwanza ndiyo muhimu zaidi — hongera', 'Umeanza leo, na hilo ndilo linalohesabika'],
    'ur': ['آپ کا پہلا ریکارڈ شدہ سیشن — اچھی شروعات، اللہ نے چاہا تو', 'آپ کا پہلا قدم سب سے اہم قدم ہے — شاباش', 'آپ نے آج شروع کیا، اور یہی اہم ہے'],
    'tr': ['İlk kaydedilen oturumun — güzel bir başlangıç, inşallah', 'İlk adımın en önemli adımdır — aferin', 'Bugün başladın, önemli olan bu'],
    'id': ['Sesi pertama Anda yang tercatat — awal yang baik, insyaAllah', 'Langkah pertama Anda adalah yang terpenting — bagus sekali', 'Anda memulai hari ini, dan itulah yang penting'],
    'bn': ['আপনার প্রথম রেকর্ড করা সেশন — একটি ভালো শুরু, ইনশাআল্লাহ', 'আপনার প্রথম পদক্ষেপই সবচেয়ে গুরুত্বপূর্ণ — চমৎকার', 'আপনি আজ শুরু করেছেন, এটাই গুরুত্বপূর্ণ'],
    'ha': ['Zamanka na farko da aka rubuta — kyakkyawan farawa, in Allah ya so', 'Mataki na farko shine mafi muhimmanci — madalla', 'Ka fara yau, kuma wannan shine abin da yake da muhimmanci'],
    'so': ['Fadhigaagii ugu horreeyay ee la duubay — bilow wanaagsan, Ilaahay idmo haddii uu doono', 'Tallaabadaada ugu horreysa waa tan ugu muhiimsan — waad ku mahadsan tahay', 'Maanta waad bilowday, taasna waa waxa muhiimka ah'],
    'fa': ['اولین جلسه ثبت‌شده‌ات — شروعی خوب، ان‌شاءالله', 'اولین قدمت مهم‌ترین قدم است — آفرین', 'امروز شروع کردی، و همین مهم است'],
    'ms': ['Sesi pertama anda yang direkodkan — permulaan yang baik, insyaAllah', 'Langkah pertama anda adalah yang paling penting — syabas', 'Anda telah bermula hari ini, dan itulah yang penting'],
  },
};

String randomEncouragement(ReadingTrend trend, String lang) {
  final key = switch (trend) {
    ReadingTrend.improved => 'improved',
    ReadingTrend.same => 'same',
    ReadingTrend.less => 'less',
    ReadingTrend.first => 'first',
  };
  final pool = readingEncouragementPhrases[key]?[lang] ?? readingEncouragementPhrases[key]!['ar']!;
  return pool[Random().nextInt(pool.length)];
}
