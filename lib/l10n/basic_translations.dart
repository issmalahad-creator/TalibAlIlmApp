/// "الأساسيات" — QURAN_COMPANION_ROADMAP.md Phase 10. A curated set of
/// navigation/hub labels translated into a broad set of languages, per
/// Ismail's explicit scoping: basics as widely as possible, deep Islamic
/// content stays Arabic-only. NOT a full app-wide i18n system (that would
/// mean migrating every screen's hardcoded Arabic strings to a lookup —
/// a much larger follow-on task) — this covers HomeScreen/ProfileScreen's
/// main navigation only, the first thing any new user sees.
///
/// HONESTY NOTE: only Arabic and English are human-native-level confident.
/// The rest are AI-translated using standard terminology for each
/// language's Muslim community — not reviewed by native speakers. Treat
/// as a solid best-effort start, not a certified translation.
library;

/// Supported language codes, in the order they're offered in the picker.
/// 'ar' (the source language) is intentionally listed first.
const supportedLanguages = {
  'ar': 'العربية',
  'en': 'English',
  'am': 'አማርኛ (Amharic)',
  'fr': 'Français (French)',
  'sw': 'Kiswahili (Swahili)',
  'ur': 'اردو (Urdu)',
  'tr': 'Türkçe (Turkish)',
  'id': 'Bahasa Indonesia (Indonesian)',
  'bn': 'বাংলা (Bengali)',
  'ha': 'Hausa',
  'so': 'Soomaali (Somali)',
  'fa': 'فارسی (Persian)',
  'ms': 'Bahasa Melayu (Malay)',
};

const Map<String, Map<String, String>> basicTranslations = {
  'nav_home': {
    'ar': 'الرئيسية', 'en': 'Home', 'am': 'መነሻ', 'fr': 'Accueil', 'sw': 'Nyumbani',
    'ur': 'ہوم', 'tr': 'Ana Sayfa', 'id': 'Beranda', 'bn': 'হোম', 'ha': 'Gida',
    'so': 'Bogga Hore', 'fa': 'خانه', 'ms': 'Laman Utama',
  },
  'nav_profile': {
    'ar': 'الملف الشخصي', 'en': 'Profile', 'am': 'መገለጫ', 'fr': 'Profil', 'sw': 'Wasifu',
    'ur': 'پروفائل', 'tr': 'Profil', 'id': 'Profil', 'bn': 'প্রোফাইল', 'ha': 'Bayanan Kai',
    'so': 'Xogtaada', 'fa': 'پروفایل', 'ms': 'Profil',
  },
  'save': {
    'ar': 'حفظ', 'en': 'Save', 'am': 'አስቀምጥ', 'fr': 'Enregistrer', 'sw': 'Hifadhi',
    'ur': 'محفوظ کریں', 'tr': 'Kaydet', 'id': 'Simpan', 'bn': 'সংরক্ষণ করুন', 'ha': 'Ajiye',
    'so': 'Kaydi', 'fa': 'ذخیره', 'ms': 'Simpan',
  },
  'daily_session': {
    'ar': 'جلسة اليوم', 'en': "Today's Session", 'am': 'የዛሬው ክፍለ ጊዜ', 'fr': "Séance du jour", 'sw': 'Kipindi cha Leo',
    'ur': 'آج کا سیشن', 'tr': 'Bugünkü Oturum', 'id': 'Sesi Hari Ini', 'bn': 'আজকের সেশন', 'ha': 'Zaman Yau',
    'so': 'Fadhiga Maanta', 'fa': 'جلسه امروز', 'ms': 'Sesi Hari Ini',
  },
  'prayer_times': {
    'ar': 'أوقات الصلاة', 'en': 'Prayer Times', 'am': 'የጸሎት ሰዓቶች', 'fr': 'Heures de prière', 'sw': 'Nyakati za Sala',
    'ur': 'اوقاتِ نماز', 'tr': 'Namaz Vakitleri', 'id': 'Waktu Salat', 'bn': 'নামাজের সময়', 'ha': 'Lokutan Sallah',
    'so': 'Waqtiyada Salaadda', 'fa': 'اوقات نماز', 'ms': 'Waktu Solat',
  },
  'qibla': {
    'ar': 'اتجاه القبلة', 'en': 'Qibla Direction', 'am': 'የቂብላ አቅጣጫ', 'fr': 'Direction de la Qibla', 'sw': 'Mwelekeo wa Kibla',
    'ur': 'قبلہ کی سمت', 'tr': 'Kıble Yönü', 'id': 'Arah Kiblat', 'bn': 'কিবলার দিক', 'ha': 'Alkiblar Sallah',
    'so': 'Jihada Qiblada', 'fa': 'جهت قبله', 'ms': 'Arah Kiblat',
  },
  'adhkar': {
    'ar': 'حصن المسلم', 'en': 'Daily Adhkar', 'am': 'የዕለት ተዘክሮዎች', 'fr': 'Invocations quotidiennes', 'sw': 'Dhikr za Kila Siku',
    'ur': 'روزانہ اذکار', 'tr': 'Günlük Zikirler', 'id': 'Dzikir Harian', 'bn': 'দৈনিক জিকির', 'ha': 'Ambaton Yau da Kullum',
    'so': 'Adhkarka Maalinlaha ah', 'fa': 'اذکار روزانه', 'ms': 'Zikir Harian',
  },
  'wird': {
    'ar': 'ورد اليوم', 'en': "Today's Wird", 'am': 'የዛሬው ውርድ', 'fr': 'Wird du jour', 'sw': 'Wird ya Leo',
    'ur': 'آج کا ورد', 'tr': 'Bugünkü Vird', 'id': 'Wirid Hari Ini', 'bn': 'আজকের ওয়াজিফা', 'ha': 'Wirdin Yau',
    'so': 'Wirdka Maanta', 'fa': 'ورد امروز', 'ms': 'Wirid Hari Ini',
  },
  'new_muslim_guide': {
    'ar': 'دليل المسلم الجديد', 'en': 'New Muslim Guide', 'am': 'ለአዲስ ሙስሊም መመሪያ', 'fr': 'Guide du nouveau musulman', 'sw': 'Mwongozo wa Muislamu Mpya',
    'ur': 'نو مسلم رہنما', 'tr': 'Yeni Müslüman Rehberi', 'id': 'Panduan Muslim Baru', 'bn': 'নতুন মুসলিমদের গাইড', 'ha': 'Jagorar Sabon Musulmi',
    'so': 'Hage Muslinka Cusub', 'fa': 'راهنمای مسلمان جدید', 'ms': 'Panduan Muslim Baharu',
  },
  'my_journey': {
    'ar': 'رحلتي', 'en': 'My Journey', 'am': 'ጉዞዬ', 'fr': 'Mon parcours', 'sw': 'Safari Yangu',
    'ur': 'میرا سفر', 'tr': 'Yolculuğum', 'id': 'Perjalanan Saya', 'bn': 'আমার যাত্রা', 'ha': 'Tafiyata',
    'so': 'Safarkayga', 'fa': 'سفر من', 'ms': 'Perjalanan Saya',
  },
  'completion_plans': {
    'ar': 'خطط ختمي', 'en': 'My Completion Plans', 'am': 'የማጠናቀቂያ እቅዶቼ', 'fr': 'Mes plans de complétion', 'sw': 'Mipango Yangu ya Kukamilisha',
    'ur': 'میرے تکمیل کے منصوبے', 'tr': 'Hatim Planlarım', 'id': 'Rencana Khatam Saya', 'bn': 'আমার সমাপ্তি পরিকল্পনা', 'ha': 'Shirye-shiryen Kammalawa',
    'so': 'Qorshayaashayda Dhamaystirka', 'fa': 'برنامه‌های ختم من', 'ms': 'Rancangan Khatam Saya',
  },
  'support_faq': {
    'ar': 'الدعم والأسئلة الشائعة', 'en': 'Support & FAQ', 'am': 'ድጋፍ እና ተደጋጋሚ ጥያቄዎች', 'fr': 'Assistance et FAQ', 'sw': 'Msaada na Maswali',
    'ur': 'مدد اور اکثر پوچھے گئے سوالات', 'tr': 'Destek ve SSS', 'id': 'Dukungan & FAQ', 'bn': 'সহায়তা ও সাধারণ প্রশ্ন', 'ha': 'Taimako da Tambayoyi',
    'so': 'Taageero iyo Su\'aalaha', 'fa': 'پشتیبانی و سوالات متداول', 'ms': 'Sokongan & Soalan Lazim',
  },
  'personal_commitment': {
    'ar': 'التزامي الشخصي', 'en': 'My Personal Commitment', 'am': 'የግል ቁርጠኝነቴ', 'fr': 'Mon engagement personnel', 'sw': 'Ahadi Yangu Binafsi',
    'ur': 'میرا ذاتی عزم', 'tr': 'Kişisel Taahhüdüm', 'id': 'Komitmen Pribadi Saya', 'bn': 'আমার ব্যক্তিগত অঙ্গীকার', 'ha': 'Alkawarina na Kai',
    'so': 'Ballanqaadkayga Shakhsiga', 'fa': 'تعهد شخصی من', 'ms': 'Komitmen Peribadi Saya',
  },
  'adab': {
    'ar': 'باب الأدب', 'en': 'Manners & Character', 'am': 'ስነምግባር', 'fr': 'Bonnes manières', 'sw': 'Tabia Njema',
    'ur': 'اخلاق و آداب', 'tr': 'Ahlak ve Edep', 'id': 'Adab & Akhlak', 'bn': 'আদব ও চরিত্র', 'ha': 'Halaye da Ɗabi\'a',
    'so': 'Anshaxa iyo Akhlaaqda', 'fa': 'اخلاق و آداب', 'ms': 'Adab & Akhlak',
  },
  'browse_quran': {
    'ar': 'تصفّح القرآن', 'en': 'Browse the Quran', 'am': 'ቁርኣንን ያስሱ', 'fr': 'Parcourir le Coran', 'sw': 'Vinjari Qur\'an',
    'ur': 'قرآن دیکھیں', 'tr': 'Kur\'an\'a Göz At', 'id': 'Jelajahi Al-Qur\'an', 'bn': 'কুরআন ব্রাউজ করুন', 'ha': 'Bincika Alkur\'ani',
    'so': 'Baadh Qur\'aanka', 'fa': 'مرور قرآن', 'ms': 'Semak Al-Quran',
  },
  'read_quran': {
    'ar': 'قراءة القرآن (ختمة)', 'en': 'Read the Quran (Khatm)', 'am': 'ቁርኣንን ያንብቡ', 'fr': 'Lire le Coran (Khatm)', 'sw': 'Soma Qur\'an (Khatm)',
    'ur': 'قرآن پڑھیں (ختم)', 'tr': 'Kur\'an Oku (Hatim)', 'id': 'Baca Al-Qur\'an (Khatam)', 'bn': 'কুরআন পড়ুন (খতম)', 'ha': 'Karanta Alkur\'ani',
    'so': 'Akhri Qur\'aanka', 'fa': 'خواندن قرآن (ختم)', 'ms': 'Baca Al-Quran (Khatam)',
  },
};

/// Looks up [key] in the student's current language, falling back to
/// Arabic (the source language) if a translation is missing for that key.
String basicText(String key, String languageCode) {
  final entry = basicTranslations[key];
  if (entry == null) return key;
  return entry[languageCode] ?? entry['ar'] ?? key;
}
