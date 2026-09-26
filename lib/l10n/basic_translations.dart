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
  // 2026-08-17: added for `main_shell.dart`'s bottom nav bar — the single
  // most persistent, always-visible piece of chrome in the app, found
  // still 100% hardcoded Arabic during Ismail's "why doesn't everything
  // change with the language" audit.
  'nav_activities': {
    'ar': 'الأنشطة', 'en': 'Activities', 'am': 'እንቅስቃሴዎች', 'fr': 'Activités', 'sw': 'Shughuli',
    'ur': 'سرگرمیاں', 'tr': 'Etkinlikler', 'id': 'Aktivitas', 'bn': 'কার্যক্রম', 'ha': 'Ayyuka',
    'so': 'Hawlaha', 'fa': 'فعالیت‌ها', 'ms': 'Aktiviti',
  },
  'nav_goals': {
    'ar': 'الأهداف', 'en': 'Goals', 'am': 'ግቦች', 'fr': 'Objectifs', 'sw': 'Malengo',
    'ur': 'اہداف', 'tr': 'Hedefler', 'id': 'Target', 'bn': 'লক্ষ্য', 'ha': 'Manufofi',
    'so': 'Yoolalka', 'fa': 'اهداف', 'ms': 'Matlamat',
  },
  'nav_book': {
    'ar': 'الكتاب', 'en': 'Library', 'am': 'ቤተ መጻሕፍት', 'fr': 'Bibliothèque', 'sw': 'Maktaba',
    'ur': 'کتب خانہ', 'tr': 'Kütüphane', 'id': 'Perpustakaan', 'bn': 'লাইব্রেরি', 'ha': 'Laburare',
    'so': 'Maktabadda', 'fa': 'کتابخانه', 'ms': 'Perpustakaan',
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
  // 2026-08-17: the remaining 4 of 7 home-screen NavGrid tiles — before
  // this, a student switching language saw 3 tiles in this exact grid
  // change and 4 stay Arabic, the specific inconsistency Ismail flagged.
  'salah_companion': {
    'ar': 'إقامة الصلاة', 'en': 'Salah Companion', 'am': 'የሶላት ጓደኛ', 'fr': 'Compagnon de prière', 'sw': 'Msaidizi wa Swala',
    'ur': 'اقامتِ نماز', 'tr': 'Namaz Yoldaşı', 'id': 'Pendamping Salat', 'bn': 'নামাজ সহচর', 'ha': 'Abokin Sallah',
    'so': 'La-taliyaha Salaadda', 'fa': 'همراه نماز', 'ms': 'Rakan Solat',
  },
  'audio_library': {
    'ar': 'كتب صوتية', 'en': 'Audio Library', 'am': 'የድምጽ ቤተ መጻሕፍት', 'fr': 'Livres audio', 'sw': 'Maktaba ya Sauti',
    'ur': 'صوتی کتابیں', 'tr': 'Sesli Kitaplar', 'id': 'Buku Audio', 'bn': 'অডিও লাইব্রেরি', 'ha': 'Littattafan Murya',
    'so': 'Maktabadda Codka', 'fa': 'کتابخانه صوتی', 'ms': 'Perpustakaan Audio',
  },
  'curriculum_map': {
    'ar': 'خريطتي التعليمية', 'en': 'Learning Map', 'am': 'የትምህርት ካርታዬ', 'fr': "Ma carte d'apprentissage", 'sw': 'Ramani Yangu ya Kujifunza',
    'ur': 'میرا تعلیمی نقشہ', 'tr': 'Öğrenme Haritam', 'id': 'Peta Belajar Saya', 'bn': 'আমার শিক্ষা মানচিত্র', 'ha': 'Taswirar Karatuna',
    'so': 'Khariidadda Waxbarashadayda', 'fa': 'نقشه یادگیری من', 'ms': 'Peta Pembelajaran Saya',
  },
  'tasbih': {
    'ar': 'التسبيح', 'en': 'Tasbih Counter', 'am': 'ተስቢሕ ቆጣሪ', 'fr': 'Compteur de Tasbih', 'sw': 'Kihesabu Tasbihi',
    'ur': 'تسبیح شمار', 'tr': 'Tesbih Sayacı', 'id': 'Penghitung Tasbih', 'bn': 'তাসবিহ কাউন্টার', 'ha': 'Na\'urar Kirga Tasbihi',
    'so': 'Tirinta Tasbiixa', 'fa': 'شمارشگر تسبیح', 'ms': 'Kiraan Tasbih',
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
  // Short generic form (no possessive "my") for the mushaf reader's
  // persistent "الختمات" entry point + its filtered bottom-sheet title
  // (KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.2) — distinct from
  // 'completion_plans' which labels the full "خطط ختمي" screen/nav tile.
  'khatm_reading_plans_short': {
    'ar': 'الختمات', 'en': 'Completion Plans', 'am': 'የማጠናቀቂያ እቅዶች', 'fr': 'Plans de complétion', 'sw': 'Mipango ya Kukamilisha',
    'ur': 'تکمیل کے منصوبے', 'tr': 'Hatim Planları', 'id': 'Rencana Khatam', 'bn': 'সমাপ্তি পরিকল্পনা', 'ha': 'Shirye-shiryen Kammalawa',
    'so': 'Qorshayaasha Dhamaystirka', 'fa': 'برنامه‌های ختم', 'ms': 'Rancangan Khatam',
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
  // 2026-08-17: `profile_screen.dart`'s NavGrid + settings section — the
  // rest of its labels found still hardcoded during Ismail's "لماذا بعض
  // الحروف تتغير وبعضها لا" question, after a screenshot showed some tiles
  // already translated (the ones below) sitting next to others that
  // weren't.
  'teacher_hifz': {
    'ar': 'أستاذ التحفيظ', 'en': 'Hifz Teacher', 'am': 'የሂፍዝ አስተማሪ', 'fr': 'Professeur de Hifz', 'sw': 'Mwalimu wa Hifz',
    'ur': 'حفظ کے استاد', 'tr': 'Hıfız Öğretmeni', 'id': 'Guru Hafalan (Hifz)', 'bn': 'হিফজ শিক্ষক', 'ha': 'Malamin Hifzi',
    'so': 'Macalinka Xifdhiga', 'fa': 'معلم حفظ', 'ms': 'Guru Hafazan',
  },
  'time_accountability': {
    'ar': 'محاسبة الوقت', 'en': 'Time Accountability', 'am': 'የጊዜ ተጠያቂነት', 'fr': 'Bilan du temps', 'sw': 'Uwajibikaji wa Muda',
    'ur': 'وقت کا حساب', 'tr': 'Zaman Muhasebesi', 'id': 'Evaluasi Waktu', 'bn': 'সময়ের হিসাব', 'ha': 'Lissafin Lokaci',
    'so': 'Xisaabinta Waqtiga', 'fa': 'محاسبه وقت', 'ms': 'Perakaunan Masa',
  },
  'hadith_arbaeen': {
    'ar': 'الأربعين النووية', 'en': "An-Nawawi's Forty Hadith", 'am': 'አርባ ነዋዊ ሐዲሶች', 'fr': 'Les Quarante Hadiths de An-Nawawi', 'sw': 'Arobaini za Nawawi',
    'ur': 'اربعین نوویؒ', 'tr': "Nevevî'nin Kırk Hadisi", 'id': 'Hadits Arbain Nawawi', 'bn': 'আরবাঈন নববী', 'ha': "Hadisai Arba'in na Nawawi",
    'so': "Arba'iin Nawawi", 'fa': 'اربعین نووی', 'ms': "Hadis Arba'in Nawawi",
  },
  'aqeedah_wasitiyyah': {
    'ar': 'العقيدة الواسطية', 'en': 'Al-Aqeedah Al-Wasitiyyah', 'am': 'አል-አቂዳህ አል-ዋሲጢያህ', 'fr': "Al-'Aqîdah Al-Wâsitiyyah", 'sw': 'Al-Aqeedah Al-Waasitiyyah',
    'ur': 'العقیدہ الواسطیہ', 'tr': "Akīdetü'l-Vasıtiyye", 'id': "Al-'Aqidah Al-Wasithiyyah", 'bn': 'আল-আকীদাহ আল-ওয়াসিতিয়্যাহ', 'ha': 'Al-Aqeedah Al-Waasitiyyah',
    'so': 'Aqiidada Waasitiyyah', 'fa': 'عقیده واسطیه', 'ms': 'Al-Aqidah Al-Wasitiyyah',
  },
  'zad_almaad': {
    'ar': 'زاد المعاد', 'en': "Zad al-Ma'ad", 'am': 'ዛድ አል-መዓድ', 'fr': "Zâd al-Ma'âd", 'sw': "Zaad al-Ma'aad",
    'ur': 'زاد المعاد', 'tr': "Zâdü'l-Meâd", 'id': "Zad Al-Ma'ad", 'bn': 'যাদুল মাআদ', 'ha': "Zaadul Ma'ad",
    'so': "Zaadul Ma'aad", 'fa': 'زاد المعاد', 'ms': "Zad Al-Ma'ad",
  },
  'madarij_salikeen': {
    'ar': 'مدارج السالكين', 'en': 'Madarij as-Salikin', 'am': 'መዳሪጅ አስ-ሳሊኪን', 'fr': 'Madârij as-Sâlikîn', 'sw': 'Madaarij as-Saalikiin',
    'ur': 'مدارج السالکین', 'tr': "Medâricü's-Sâlikîn", 'id': 'Madarij As-Salikin', 'bn': 'মাদারিজুস সালিকীন', 'ha': 'Madaarijus Saalikiin',
    'so': 'Madaarijus Saalikiin', 'fa': 'مدارج السالکین', 'ms': 'Madarij As-Salikin',
  },
  'arabic_curriculum': {
    'ar': 'منهج تعلم العربية', 'en': 'Arabic Learning Curriculum', 'am': 'የዐረብኛ ትምህርት ስርዓተ ትምህርት', 'fr': "Programme d'apprentissage de l'arabe", 'sw': 'Mtaala wa Kujifunza Kiarabu',
    'ur': 'عربی سیکھنے کا نصاب', 'tr': 'Arapça Öğrenim Müfredatı', 'id': 'Kurikulum Belajar Bahasa Arab', 'bn': 'আরবি শেখার পাঠ্যক্রম', 'ha': 'Manhajin Koyon Larabci',
    'so': 'Manhajka Barashada Carabiga', 'fa': 'برنامه آموزش عربی', 'ms': 'Kurikulum Pembelajaran Bahasa Arab',
  },
  'tajweed': {
    'ar': 'التجويد', 'en': 'Tajweed', 'am': 'ተጅዊድ', 'fr': 'Tajwid', 'sw': 'Tajwidi',
    'ur': 'تجوید', 'tr': 'Tecvid', 'id': 'Tajwid', 'bn': 'তাজবীদ', 'ha': 'Tajweed',
    'so': 'Tajwiid', 'fa': 'تجوید', 'ms': 'Tajwid',
  },
  'adhkar_notifications': {
    'ar': 'إشعارات الأذكار', 'en': 'Adhkar Notifications', 'am': 'የዚክር ማሳወቂያዎች', 'fr': "Notifications d'Adhkar", 'sw': 'Arifa za Adhkar',
    'ur': 'اذکار کی اطلاعات', 'tr': 'Zikir Bildirimleri', 'id': 'Notifikasi Dzikir', 'bn': 'আযকারের বিজ্ঞপ্তি', 'ha': 'Sanarwar Azkaari',
    'so': 'Ogeysiisyada Adhkaarka', 'fa': 'اعلان‌های اذکار', 'ms': 'Notifikasi Zikir',
  },
  'saved_confirmation': {
    'ar': 'تم الحفظ', 'en': 'Saved', 'am': 'ተቀምጧል', 'fr': 'Enregistré', 'sw': 'Imehifadhiwa',
    'ur': 'محفوظ ہو گیا', 'tr': 'Kaydedildi', 'id': 'Tersimpan', 'bn': 'সংরক্ষিত হয়েছে', 'ha': 'An Ajiye',
    'so': 'La Kaydiyay', 'fa': 'ذخیره شد', 'ms': 'Disimpan',
  },
  'loading_generic': {
    'ar': 'جاري التحميل...', 'en': 'Loading...', 'am': 'በመጫን ላይ...', 'fr': 'Chargement...', 'sw': 'Inapakia...',
    'ur': 'لوڈ ہو رہا ہے...', 'tr': 'Yükleniyor...', 'id': 'Memuat...', 'bn': 'লোড হচ্ছে...', 'ha': 'Ana Loda...',
    'so': 'Waa la soo raraya...', 'fa': 'در حال بارگذاری...', 'ms': 'Memuatkan...',
  },
  'add_certificate_photo': {
    'ar': 'إضافة صورة للشهادات', 'en': 'Add Certificate Photo', 'am': 'የምስክር ወረቀት ፎቶ ጨምር', 'fr': 'Ajouter une photo de certificat', 'sw': 'Ongeza Picha ya Cheti',
    'ur': 'سرٹیفکیٹ کی تصویر شامل کریں', 'tr': 'Sertifika Fotoğrafı Ekle', 'id': 'Tambah Foto Sertifikat', 'bn': 'সার্টিফিকেট ছবি যোগ করুন', 'ha': 'Ƙara Hoton Takardar Shaida',
    'so': 'Ku dar Sawirka Shahaadada', 'fa': 'افزودن عکس گواهی', 'ms': 'Tambah Gambar Sijil',
  },
  'change_certificate_photo': {
    'ar': 'تغيير صورة الشهادات', 'en': 'Change Certificate Photo', 'am': 'የምስክር ወረቀት ፎቶ ቀይር', 'fr': 'Changer la photo du certificat', 'sw': 'Badilisha Picha ya Cheti',
    'ur': 'سرٹیفکیٹ کی تصویر تبدیل کریں', 'tr': 'Sertifika Fotoğrafını Değiştir', 'id': 'Ubah Foto Sertifikat', 'bn': 'সার্টিফিকেট ছবি পরিবর্তন করুন', 'ha': 'Canza Hoton Takardar Shaida',
    'so': 'Beddel Sawirka Shahaadada', 'fa': 'تغییر عکس گواهی', 'ms': 'Tukar Gambar Sijil',
  },
  'full_name_label': {
    'ar': 'الاسم الكامل', 'en': 'Full Name', 'am': 'ሙሉ ስም', 'fr': 'Nom complet', 'sw': 'Jina Kamili',
    'ur': 'پورا نام', 'tr': 'Ad Soyad', 'id': 'Nama Lengkap', 'bn': 'পূর্ণ নাম', 'ha': 'Cikakken Suna',
    'so': 'Magaca Buuxa', 'fa': 'نام کامل', 'ms': 'Nama Penuh',
  },
  'residence_label': {
    'ar': 'محل الإقامة', 'en': 'Residence', 'am': 'መኖሪያ', 'fr': 'Lieu de résidence', 'sw': 'Makazi',
    'ur': 'رہائش', 'tr': 'İkamet Yeri', 'id': 'Tempat Tinggal', 'bn': 'বসবাসের স্থান', 'ha': 'Wurin Zama',
    'so': 'Deganaanshaha', 'fa': 'محل سکونت', 'ms': 'Tempat Tinggal',
  },
  'study_track_label': {
    'ar': 'المسار العلمي', 'en': 'Study Track', 'am': 'የትምህርት መስመር', 'fr': "Parcours d'études", 'sw': 'Njia ya Elimu',
    'ur': 'تعلیمی راستہ', 'tr': 'Öğrenim Yolu', 'id': 'Jalur Studi', 'bn': 'অধ্যয়ন পথ', 'ha': 'Hanyar Karatu',
    'so': 'Habka Waxbarashada', 'fa': 'مسیر تحصیلی', 'ms': 'Laluan Pengajian',
  },
  'study_source_label': {
    'ar': 'مصدر الدراسة (مثال: الراسخون في العلم)', 'en': "Study Source (e.g. Ar-Rasikhun fil-'Ilm)", 'am': "የትምህርት ምንጭ (ምሳሌ: አር-ራሲኹን ፊል ዒልም)", 'fr': "Source d'étude (ex. : Ar-Rasikhun fil-'Ilm)", 'sw': "Chanzo cha Masomo (mfano: Ar-Rasikhun fil-'Ilm)",
    'ur': 'ذریعہ تعلیم (مثال: الراسخون فی العلم)', 'tr': "Öğrenim Kaynağı (örn. Er-Râsihûn fi'l-İlm)", 'id': "Sumber Belajar (contoh: Ar-Rasikhun fil-'Ilm)", 'bn': 'অধ্যয়নের উৎস (উদাহরণ: আর-রাসিখুন ফিল-ইলম)', 'ha': "Tushen Karatu (misali: Ar-Rasikhun fil-'Ilm)",
    'so': "Isha Waxbarashada (tusaale: Ar-Rasikhun fil-'Ilm)", 'fa': 'منبع مطالعه (مثال: الراسخون فی العلم)', 'ms': "Sumber Pengajian (cth: Ar-Rasikhun fil-'Ilm)",
  },
  'gregorian_toggle_title': {
    'ar': 'عرض التواريخ بالتقويم الميلادي', 'en': 'Show Dates in Gregorian Calendar', 'am': 'ቀናትን በጎርጎርያን ካላንደር አሳይ', 'fr': 'Afficher les dates en calendrier grégorien', 'sw': 'Onyesha Tarehe kwa Kalenda ya Kigregori',
    'ur': 'تاریخیں عیسوی کیلنڈر میں دکھائیں', 'tr': 'Tarihleri Miladi Takvimde Göster', 'id': 'Tampilkan Tanggal dengan Kalender Masehi', 'bn': 'গ্রেগরিয়ান ক্যালেন্ডারে তারিখ দেখান', 'ha': 'Nuna Kwanan Wata da Kalandar Miladiyya',
    'so': 'Tusaalayaal Taariikhaha Kalandarka Miilaadiga', 'fa': 'نمایش تاریخ‌ها با تقویم میلادی', 'ms': 'Papar Tarikh dalam Kalendar Masihi',
  },
  'gregorian_toggle_subtitle': {
    'ar': 'التخزين الداخلي يبقى هجريًا دائمًا — هذا يغيّر طريقة العرض فقط', 'en': 'Internal storage always stays Hijri — this only changes how dates are displayed', 'am': 'ውስጣዊ ማከማቻ ሁልጊዜ ሂጅሪ ሆኖ ይቆያል — ይህ የማሳያ መንገድን ብቻ ይቀይራል', 'fr': "Le stockage interne reste toujours hégirien — cela ne change que l'affichage", 'sw': 'Uhifadhi wa ndani unabaki Hijri kila wakati — hii inabadilisha tu jinsi tarehe zinavyoonyeshwa',
    'ur': 'اندرونی ذخیرہ ہمیشہ ہجری رہتا ہے — یہ صرف دکھانے کا طریقہ بدلتا ہے', 'tr': 'Dahili depolama her zaman Hicri kalır — bu yalnızca gösterim biçimini değiştirir', 'id': 'Penyimpanan internal selalu tetap Hijriah — ini hanya mengubah cara tampilan', 'bn': 'অভ্যন্তরীণ সংরক্ষণ সবসময় হিজরি থাকে — এটি শুধু প্রদর্শনের ধরন পরিবর্তন করে', 'ha': 'Ajiyar ciki koyaushe tana zama Hijira — wannan yana canza yadda ake nuna kwanan wata kawai',
    'so': 'Kaydinta gudaha had iyo jeer wuxuu ahaan doonaa Hijri — tani waxay bedeshaa oo keliya sida loo muujiyo', 'fa': 'ذخیره‌سازی داخلی همیشه هجری باقی می‌ماند — این فقط نحوه نمایش را تغییر می‌دهد', 'ms': 'Storan dalaman kekal Hijrah — ini hanya menukar cara paparan',
  },
  'basic_titles_language_label': {
    'ar': 'لغة العناوين الأساسية', 'en': 'Basic Titles Language', 'am': 'የመሠረታዊ ርዕሶች ቋንቋ', 'fr': 'Langue des titres de base', 'sw': 'Lugha ya Vichwa vya Msingi',
    'ur': 'بنیادی عنوانات کی زبان', 'tr': 'Temel Başlıklar Dili', 'id': 'Bahasa Judul Dasar', 'bn': 'মৌলিক শিরোনামের ভাষা', 'ha': 'Harshen Manyan Take-take',
    'so': 'Luqadda Cinwaannada Aasaasiga ah', 'fa': 'زبان عناوین پایه', 'ms': 'Bahasa Tajuk Asas',
  },
  'basic_titles_language_desc': {
    'ar': 'يبقى المحتوى الإسلامي العميق (القرآن، الأذكار، الفقه) بالعربية دائمًا — هذا يترجم فقط عناوين التنقل الأساسية', 'en': 'Deep Islamic content (Quran, Adhkar, Fiqh) always stays in Arabic — this only translates basic navigation titles', 'am': 'ጥልቅ የእስልምና ይዘት (ቁርኣን፣ ዚክር፣ ፊቅህ) ሁልጊዜ በዐረብኛ ይቆያል — ይህ የመሠረታዊ አሰሳ ርዕሶችን ብቻ ይተረጉማል', 'fr': 'Le contenu islamique approfondi (Coran, Adhkar, Fiqh) reste toujours en arabe — cela ne traduit que les titres de navigation de base', 'sw': 'Maudhui ya kina ya Kiislamu (Qur\'an, Adhkar, Fiqh) yanabaki kwa Kiarabu kila wakati — hii inatafsiri tu vichwa vya msingi vya kutembeza',
    'ur': 'گہرا اسلامی مواد (قرآن، اذکار، فقہ) ہمیشہ عربی میں رہتا ہے — یہ صرف بنیادی نیویگیشن عنوانات کا ترجمہ کرتا ہے', 'tr': 'Derin İslami içerik (Kur\'an, Zikir, Fıkıh) her zaman Arapça kalır — bu yalnızca temel gezinme başlıklarını çevirir', 'id': 'Konten Islam yang mendalam (Al-Qur\'an, Dzikir, Fiqih) selalu tetap dalam bahasa Arab — ini hanya menerjemahkan judul navigasi dasar', 'bn': 'গভীর ইসলামি বিষয়বস্তু (কুরআন, আযকার, ফিকহ) সবসময় আরবিতে থাকে — এটি শুধু মৌলিক নেভিগেশন শিরোনাম অনুবাদ করে', 'ha': 'Zurfin abin da ke ciki na Musulunci (Alkur\'ani, Azkaari, Fikihu) koyaushe yana zama da Larabci — wannan yana fassara manyan take-take na kewayawa kawai',
    'so': 'Waxyaabaha diinta oo qoto dheer (Qur\'aanka, Adhkaarka, Fiqhiga) had iyo jeer waxay ku sii jiri doonaan Carabi — tani waxay tarjumaysaa oo keliya cinwaannada aasaasiga ah ee dhaqdhaqaaqa', 'fa': 'محتوای عمیق اسلامی (قرآن، اذکار، فقه) همیشه به عربی باقی می‌ماند — این فقط عناوین اصلی پیمایش را ترجمه می‌کند', 'ms': 'Kandungan Islam yang mendalam (Al-Quran, Zikir, Fiqh) sentiasa kekal dalam bahasa Arab — ini hanya menterjemah tajuk navigasi asas',
  },
  // 2026-08-17: `goals_screen.dart` — the "الأهداف" tab, found 100%
  // hardcoded during the same sweep as `profile_screen.dart`.
  'no_goals_yet': {
    'ar': 'لا توجد أهداف بعد — اضغط + لإضافة هدف', 'en': 'No goals yet — tap + to add one', 'am': 'እስካሁን ግቦች የሉም — + ተጫን አንድ ለመጨመር', 'fr': 'Aucun objectif pour le moment — appuyez sur + pour en ajouter un', 'sw': 'Bado hakuna malengo — bonyeza + kuongeza',
    'ur': 'ابھی تک کوئی ہدف نہیں — شامل کرنے کے لیے + دبائیں', 'tr': 'Henüz hedef yok — eklemek için + dokun', 'id': 'Belum ada target — ketuk + untuk menambahkan', 'bn': 'এখনও কোনো লক্ষ্য নেই — যোগ করতে + চাপুন', 'ha': 'Babu manufofi tukuna — danna + don ƙarawa',
    'so': 'Wali yoolal ma jiraan — taabo + si aad u darto mid', 'fa': 'هنوز هدفی نیست — برای افزودن + را بزنید', 'ms': 'Belum ada matlamat — ketik + untuk menambah',
  },
  'goal_title_label': {
    'ar': 'عنوان الهدف', 'en': 'Goal Title', 'am': 'የግብ ርዕስ', 'fr': "Titre de l'objectif", 'sw': 'Kichwa cha Lengo',
    'ur': 'ہدف کا عنوان', 'tr': 'Hedef Başlığı', 'id': 'Judul Target', 'bn': 'লক্ষ্যের শিরোনাম', 'ha': 'Take na Manufa',
    'so': 'Cinwaanka Yoolka', 'fa': 'عنوان هدف', 'ms': 'Tajuk Matlamat',
  },
  'goal_target_label': {
    'ar': 'الرقم المستهدف', 'en': 'Target Number', 'am': 'የታለመ ቁጥር', 'fr': 'Nombre cible', 'sw': 'Nambari Lengwa',
    'ur': 'ہدف نمبر', 'tr': 'Hedef Sayı', 'id': 'Angka Target', 'bn': 'লক্ষ্য সংখ্যা', 'ha': 'Adadin da Ake Nufi',
    'so': 'Lambarka Bartilmaameedka', 'fa': 'عدد هدف', 'ms': 'Nombor Sasaran',
  },
  'goal_current_label': {
    'ar': 'المُنجز حتى الآن', 'en': 'Completed So Far', 'am': 'እስካሁን የተጠናቀቀ', 'fr': "Réalisé jusqu'à présent", 'sw': 'Ilyofikiwa Hadi Sasa',
    'ur': 'اب تک مکمل', 'tr': 'Şimdiye Kadar Tamamlanan', 'id': 'Selesai Sejauh Ini', 'bn': 'এখন পর্যন্ত সম্পন্ন', 'ha': 'An Kammala Har Yanzu',
    'so': 'Ilaa Hadda La Dhammeeyay', 'fa': 'تاکنون انجام‌شده', 'ms': 'Selesai Setakat Ini',
  },
  'new_goal_title': {
    'ar': 'هدف جديد', 'en': 'New Goal', 'am': 'አዲስ ግብ', 'fr': 'Nouvel objectif', 'sw': 'Lengo Jipya',
    'ur': 'نیا ہدف', 'tr': 'Yeni Hedef', 'id': 'Target Baru', 'bn': 'নতুন লক্ষ্য', 'ha': 'Sabuwar Manufa',
    'so': 'Yool Cusub', 'fa': 'هدف جدید', 'ms': 'Matlamat Baharu',
  },
  'edit_goal_title': {
    'ar': 'تعديل الهدف', 'en': 'Edit Goal', 'am': 'ግብ አርትዕ', 'fr': "Modifier l'objectif", 'sw': 'Hariri Lengo',
    'ur': 'ہدف میں ترمیم کریں', 'tr': 'Hedefi Düzenle', 'id': 'Ubah Target', 'bn': 'লক্ষ্য সম্পাদনা করুন', 'ha': 'Gyara Manufa',
    'so': 'Wax ka Beddel Yoolka', 'fa': 'ویرایش هدف', 'ms': 'Edit Matlamat',
  },
  'cancel': {
    'ar': 'إلغاء', 'en': 'Cancel', 'am': 'ሰርዝ', 'fr': 'Annuler', 'sw': 'Ghairi',
    'ur': 'منسوخ کریں', 'tr': 'İptal', 'id': 'Batal', 'bn': 'বাতিল করুন', 'ha': 'Soke',
    'so': 'Jooji', 'fa': 'لغو', 'ms': 'Batal',
  },
  'add': {
    'ar': 'إضافة', 'en': 'Add', 'am': 'ጨምር', 'fr': 'Ajouter', 'sw': 'Ongeza',
    'ur': 'شامل کریں', 'tr': 'Ekle', 'id': 'Tambah', 'bn': 'যোগ করুন', 'ha': 'Ƙara',
    'so': 'Kudar', 'fa': 'افزودن', 'ms': 'Tambah',
  },
  // 2026-08-17: `book_screen.dart` — the "الكتاب" tab, same sweep as
  // `goals_screen.dart`. Note per Ismail's own scope rule ("فقط كتب و قران
  // واحاديث هم deep Islamic content"): these are the SCREEN's own UI labels
  // (buttons, section titles, hints) — the actual book titles/content
  // pulled from the Telegram feed stay exactly as sent, untranslated.
  'announcements_history': {
    'ar': 'سجل الإعلانات والبانرات', 'en': 'Announcements & Banners History', 'am': 'የማስታወቂያዎች ታሪክ', 'fr': 'Historique des annonces', 'sw': 'Historia ya Matangazo',
    'ur': 'اعلانات کی تاریخ', 'tr': 'Duyuru Geçmişi', 'id': 'Riwayat Pengumuman', 'bn': 'ঘোষণার ইতিহাস', 'ha': 'Tarihin Sanarwowi',
    'so': 'Taariikhda Ogeysiisyada', 'fa': 'تاریخچه اعلان‌ها', 'ms': 'Sejarah Pengumuman',
  },
  'my_stats': {
    'ar': 'إحصائياتي', 'en': 'My Statistics', 'am': 'ስታቲስቲኮቼ', 'fr': 'Mes statistiques', 'sw': 'Takwimu Zangu',
    'ur': 'میرے اعداد و شمار', 'tr': 'İstatistiklerim', 'id': 'Statistik Saya', 'bn': 'আমার পরিসংখ্যান', 'ha': 'Kididdigata',
    'so': 'Tirakoobkayga', 'fa': 'آمار من', 'ms': 'Statistik Saya',
  },
  'my_library': {
    'ar': 'مكتبتي', 'en': 'My Library', 'am': 'ቤተ መጻሕፍቴ', 'fr': 'Ma bibliothèque', 'sw': 'Maktaba Yangu',
    'ur': 'میری لائبریری', 'tr': 'Kütüphanem', 'id': 'Perpustakaan Saya', 'bn': 'আমার লাইব্রেরি', 'ha': 'Laburarena',
    'so': 'Maktabadayda', 'fa': 'کتابخانه من', 'ms': 'Perpustakaan Saya',
  },
  'my_library_desc': {
    'ar': 'نظّم كتبك الخاصة (من جهازك) في أقسام مثل الفقه والعقيدة، واقرأها هنا حتى بدون إنترنت.', 'en': 'Organize your own books (from your device) into sections like Fiqh and Aqeedah, and read them here even offline.', 'am': 'የራስህን መጻሕፍት (ከመሳሪያህ) እንደ ፊቅህ እና ዐቂዳህ ባሉ ክፍሎች አደራጅ፣ እና ከበይነመረብ ውጭም እዚህ አንብባቸው።', 'fr': 'Organisez vos propres livres (depuis votre appareil) en sections comme le Fiqh et l\'Aqeedah, et lisez-les ici même hors ligne.', 'sw': 'Panga vitabu vyako mwenyewe (kutoka kifaa chako) katika sehemu kama Fiqh na Aqeedah, na uvisome hapa hata bila mtandao.',
    'ur': 'اپنی کتابیں (اپنے آلے سے) فقہ اور عقیدہ جیسے حصوں میں منظم کریں، اور یہاں بغیر انٹرنیٹ کے بھی پڑھیں۔', 'tr': 'Kendi kitaplarını (cihazından) Fıkıh ve Akide gibi bölümlere ayır ve internetsizken bile burada oku.', 'id': 'Atur buku Anda sendiri (dari perangkat) ke dalam bagian seperti Fiqih dan Akidah, dan baca di sini bahkan tanpa internet.', 'bn': 'আপনার নিজের বই (ডিভাইস থেকে) ফিকহ ও আকীদার মতো বিভাগে সাজান, এবং ইন্টারনেট ছাড়াই এখানে পড়ুন।', 'ha': "Tsara littattafanka (daga na'ura) cikin sassa kamar Fikihu da Aqeedah, ka karanta su nan ko da babu intanet.",
    'so': 'U qaybi buugagtaada gaarka ah (jihaska aad) qaybo sida Fiqhiga iyo Caqiidada, kuna akhri halkan xitaa adiga oo aan internet lahayn.', 'fa': 'کتاب‌های خودت (از دستگاهت) را در بخش‌هایی مثل فقه و عقیده سازماندهی کن، و اینجا حتی بدون اینترنت بخوان.', 'ms': 'Susun buku anda sendiri (dari peranti) ke dalam bahagian seperti Fiqh dan Akidah, dan baca di sini walaupun tanpa internet.',
  },
  'open_my_library': {
    'ar': 'فتح مكتبتي', 'en': 'Open My Library', 'am': 'ቤተ መጻሕፍቴን ክፈት', 'fr': 'Ouvrir ma bibliothèque', 'sw': 'Fungua Maktaba Yangu',
    'ur': 'میری لائبریری کھولیں', 'tr': 'Kütüphanemi Aç', 'id': 'Buka Perpustakaan Saya', 'bn': 'আমার লাইব্রেরি খুলুন', 'ha': 'Buɗe Laburarena',
    'so': 'Fur Maktabadayda', 'fa': 'باز کردن کتابخانه من', 'ms': 'Buka Perpustakaan Saya',
  },
  'cannot_open_file': {
    'ar': 'تعذر فتح الملف', 'en': 'Could not open the file', 'am': 'ፋይሉን መክፈት አልተቻለም', 'fr': "Impossible d'ouvrir le fichier", 'sw': 'Imeshindwa kufungua faili',
    'ur': 'فائل کھولنا ممکن نہیں ہوا', 'tr': 'Dosya açılamadı', 'id': 'Tidak dapat membuka berkas', 'bn': 'ফাইল খুলতে পারা যায়নি', 'ha': 'An kasa buɗe fayil',
    'so': 'Faylka lama furi karin', 'fa': 'باز کردن فایل ممکن نشد', 'ms': 'Tidak dapat membuka fail',
  },
  'cannot_download_file': {
    'ar': 'تعذر تحميل الملف', 'en': 'Could not download the file', 'am': 'ፋይሉን ማውረድ አልተቻለም', 'fr': 'Impossible de télécharger le fichier', 'sw': 'Imeshindwa kupakua faili',
    'ur': 'فائل ڈاؤن لوڈ نہیں ہو سکی', 'tr': 'Dosya indirilemedi', 'id': 'Tidak dapat mengunduh berkas', 'bn': 'ফাইল ডাউনলোড করা যায়নি', 'ha': 'An kasa saukar da fayil',
    'so': 'Faylka lama soo dejin karin', 'fa': 'دانلود فایل ممکن نشد', 'ms': 'Tidak dapat memuat turun fail',
  },
  'no_books_yet': {
    'ar': 'لم يتم إضافة أي كتاب بعد.\nسيظهر هنا بمجرد إرساله من قبل المشرف.', 'en': 'No books added yet.\nIt will appear here once the admin sends it.', 'am': 'እስካሁን ምንም መጽሐፍ አልተጨመረም።\nአስተዳዳሪው ልኮ ወዲያውኑ እዚህ ይታያል።', 'fr': "Aucun livre ajouté pour le moment.\nIl apparaîtra ici dès que l'administrateur l'enverra.", 'sw': 'Bado hakuna kitabu kilichoongezwa.\nKitaonekana hapa mara msimamizi atakapokituma.',
    'ur': 'ابھی تک کوئی کتاب شامل نہیں کی گئی۔\nایڈمن کے بھیجتے ہی یہاں ظاہر ہوگی۔', 'tr': 'Henüz kitap eklenmedi.\nYönetici gönderdiğinde burada görünecek.', 'id': 'Belum ada buku yang ditambahkan.\nAkan muncul di sini setelah admin mengirimkannya.', 'bn': 'এখনও কোনো বই যোগ করা হয়নি।\nঅ্যাডমিন পাঠালেই এখানে দেখা যাবে।', 'ha': 'Babu littafi da aka ƙara tukuna.\nZai bayyana nan da zarar mai kula ya aiko shi.',
    'so': 'Wali buug lama darin.\nWuxuu ka muuqan doonaa halkan marka maamulaha uu soo diro.', 'fa': 'هنوز کتابی اضافه نشده.\nبه محض ارسال توسط مدیر، اینجا نمایش داده می‌شود.', 'ms': 'Belum ada buku ditambah.\nAkan muncul di sini sebaik sahaja pentadbir menghantarnya.',
  },
  'books_label': {
    'ar': 'الكتب', 'en': 'Books', 'am': 'መጻሕፍት', 'fr': 'Livres', 'sw': 'Vitabu',
    'ur': 'کتابیں', 'tr': 'Kitaplar', 'id': 'Buku', 'bn': 'বইসমূহ', 'ha': 'Littattafai',
    'so': 'Buugagta', 'fa': 'کتاب‌ها', 'ms': 'Buku',
  },
  'search_book_hint': {
    'ar': 'ابحث عن كتاب...', 'en': 'Search for a book...', 'am': 'መጽሐፍ ፈልግ...', 'fr': 'Rechercher un livre...', 'sw': 'Tafuta kitabu...',
    'ur': 'کتاب تلاش کریں...', 'tr': 'Kitap ara...', 'id': 'Cari buku...', 'bn': 'একটি বই খুঁজুন...', 'ha': 'Nemo littafi...',
    'so': 'Raadi buug...', 'fa': 'جستجوی کتاب...', 'ms': 'Cari buku...',
  },
  'no_results': {
    'ar': 'لا توجد نتائج.', 'en': 'No results.', 'am': 'ምንም ውጤት የለም።', 'fr': 'Aucun résultat.', 'sw': 'Hakuna matokeo.',
    'ur': 'کوئی نتیجہ نہیں۔', 'tr': 'Sonuç yok.', 'id': 'Tidak ada hasil.', 'bn': 'কোনো ফলাফল নেই।', 'ha': 'Babu sakamako.',
    'so': 'Natiijo lama helin.', 'fa': 'نتیجه‌ای یافت نشد.', 'ms': 'Tiada keputusan.',
  },
  'show_action': {
    'ar': 'إظهار', 'en': 'Show', 'am': 'አሳይ', 'fr': 'Afficher', 'sw': 'Onyesha',
    'ur': 'دکھائیں', 'tr': 'Göster', 'id': 'Tampilkan', 'bn': 'দেখান', 'ha': 'Nuna',
    'so': 'Tus', 'fa': 'نمایش', 'ms': 'Papar',
  },
  // 2026-08-17: `home_screen.dart` — the single most-visited screen, per
  // Ismail's own repeated flagging ("أرى في الصفحة الرئيسية كلمات عربية
  // بعد تغير اللغة"). Same rule confirmed by him directly: every string
  // authored for this app's UI translates; only not-yet-sourced hadith/
  // tafsir CONTENT stays Arabic.
  'splash_tagline': {'ar': '«من سلك طريقًا يلتمس فيه علمًا، سهّل الله له به طريقًا إلى الجنة» — رواه مسلم', 'en': '“Whoever follows a path seeking knowledge, Allah makes easy for him a path to Paradise.” — Muslim', 'am': '«ዕውቀትን ፍለጋ መንገድ የሄደ ሰው፣ አላህ ወደ ጀነት የሚያደርሰውን መንገድ ያገራለታል።» — ሙስሊም', 'fr': '« Quiconque emprunte un chemin à la recherche du savoir, Allah lui facilite un chemin vers le Paradis. » — Muslim', 'sw': '“Mwenye kushika njia akitafuta elimu, Allah humsahilishia njia ya kwenda Peponi.” — Muslim', 'ur': '«جو علم کی تلاش میں کسی راستے پر چلا، اللہ اس کے لیے جنت کا راستہ آسان کر دیتا ہے۔» — مسلم', 'tr': '“Kim ilim talebiyle bir yola girerse, Allah ona cennete giden bir yolu kolaylaştırır.” — Müslim', 'id': '“Barang siapa menempuh jalan untuk mencari ilmu, Allah mudahkan baginya jalan menuju surga.” — Muslim', 'bn': '“যে ব্যক্তি জ্ঞানের সন্ধানে কোনো পথে চলে, আল্লাহ তার জন্য জান্নাতের পথ সহজ করে দেন।” — মুসলিম', 'ha': '“Duk wanda ya bi hanya yana neman ilimi, Allah zai sauƙaƙa masa hanyar zuwa Aljanna.” — Muslim', 'so': '“Qofkii mara waddo uu cilmi ku raadinayo, Alle wuxuu u fududeeyaa waddo Jannada gaarsiisa.” — Muslim', 'fa': '«هر کس راهی را در طلب علم بپیماید، خداوند راهی به سوی بهشت را برایش آسان می‌کند.» — مسلم', 'ms': '“Sesiapa yang menempuh jalan untuk menuntut ilmu, Allah mudahkan baginya jalan ke syurga.” — Muslim'},
  'splash_status_env': {'ar': 'جاري إعداد بيئتك…', 'en': 'Setting up your space…', 'am': 'ቦታህን በማዘጋጀት ላይ…', 'fr': 'Préparation de votre espace…', 'sw': 'Inaandaa mazingira yako…', 'ur': 'آپ کا ماحول تیار ہو رہا ہے…', 'tr': 'Alanınız hazırlanıyor…', 'id': 'Menyiapkan ruang Anda…', 'bn': 'আপনার পরিসর প্রস্তুত হচ্ছে…', 'ha': 'Ana shirya wurinka…', 'so': 'Waxaa la diyaarinayaa goobtaada…', 'fa': 'در حال آماده‌سازی فضای شما…', 'ms': 'Menyediakan ruang anda…'},
  'splash_status_library': {'ar': 'جاري تجهيز مكتبتك…', 'en': 'Preparing your library…', 'am': 'ቤተ-መጻሕፍትህን በማዘጋጀት ላይ…', 'fr': 'Préparation de votre bibliothèque…', 'sw': 'Inaandaa maktaba yako…', 'ur': 'آپ کی لائبریری تیار ہو رہی ہے…', 'tr': 'Kütüphaneniz hazırlanıyor…', 'id': 'Menyiapkan perpustakaan Anda…', 'bn': 'আপনার গ্রন্থাগার প্রস্তুত হচ্ছে…', 'ha': 'Ana shirya ɗakin karatunka…', 'so': 'Waxaa la diyaarinayaa maktabaddaada…', 'fa': 'در حال آماده‌سازی کتابخانهٔ شما…', 'ms': 'Menyediakan perpustakaan anda…'},
  'splash_status_app': {'ar': 'جاري تجهيز طالب العلم…', 'en': 'Getting Talib al-Ilm ready…', 'am': 'ጣሊብ አል-ዒልምን በማዘጋጀት ላይ…', 'fr': 'Préparation de Talib al-Ilm…', 'sw': 'Inaandaa Talib al-Ilm…', 'ur': 'طالب العلم تیار ہو رہا ہے…', 'tr': 'Talib al-Ilm hazırlanıyor…', 'id': 'Menyiapkan Talib al-Ilm…', 'bn': 'তালিব আল-ইলম প্রস্তুত হচ্ছে…', 'ha': 'Ana shirya Talib al-Ilm…', 'so': 'Waxaa la diyaarinayaa Talib al-Ilm…', 'fa': 'در حال آماده‌سازی طالب العلم…', 'ms': 'Menyediakan Talib al-Ilm…'},
  'splash_version': {'ar': 'الإصدار', 'en': 'Version', 'am': 'ስሪት', 'fr': 'Version', 'sw': 'Toleo', 'ur': 'ورژن', 'tr': 'Sürüm', 'id': 'Versi', 'bn': 'সংস্করণ', 'ha': 'Sigar', 'so': 'Nooca', 'fa': 'نسخه', 'ms': 'Versi'},
  'home_loading_message': {
    'ar': 'جاري تحضير صفحتك الرئيسية...', 'en': 'Preparing your home page...', 'am': 'መነሻ ገጽህን በማዘጋጀት ላይ...', 'fr': "Préparation de votre page d'accueil...", 'sw': 'Inaandaa ukurasa wako wa nyumbani...',
    'ur': 'آپ کا ہوم پیج تیار کیا جا رہا ہے...', 'tr': 'Ana sayfanız hazırlanıyor...', 'id': 'Menyiapkan halaman utama Anda...', 'bn': 'আপনার হোম পেজ প্রস্তুত করা হচ্ছে...', 'ha': 'Ana Shirya Shafinka na Gida...',
    'so': 'Waa la diyaarinayaa boggaaga hore...', 'fa': 'در حال آماده‌سازی صفحه اصلی شما...', 'ms': 'Menyediakan halaman utama anda...',
  },
  'default_user_name': {
    'ar': 'طالب العلم', 'en': 'Student', 'am': 'ተማሪ', 'fr': 'Étudiant', 'sw': 'Mwanafunzi',
    'ur': 'طالب علم', 'tr': 'Öğrenci', 'id': 'Pelajar', 'bn': 'শিক্ষার্থী', 'ha': 'Ɗalibi',
    'so': 'Ardayga', 'fa': 'دانش‌آموز', 'ms': 'Pelajar',
  },
  'app_help_tooltip': {
    'ar': 'شرح استخدام التطبيق', 'en': 'How to use the app', 'am': 'መተግበሪያውን እንዴት መጠቀም እንደሚቻል', 'fr': "Comment utiliser l'application", 'sw': 'Jinsi ya kutumia programu',
    'ur': 'ایپ استعمال کرنے کا طریقہ', 'tr': 'Uygulama nasıl kullanılır', 'id': 'Cara menggunakan aplikasi', 'bn': 'অ্যাপ কীভাবে ব্যবহার করবেন', 'ha': 'Yadda ake amfani da manhaja',
    'so': 'Sida loo isticmaalo barnaamijka', 'fa': 'نحوه استفاده از برنامه', 'ms': 'Cara menggunakan aplikasi',
  },
  'home_greeting_prefix': {
    'ar': 'مرحباً 👋', 'en': 'Welcome 👋', 'am': 'እንኳን ደህና መጣህ 👋', 'fr': 'Bienvenue 👋', 'sw': 'Karibu 👋',
    'ur': 'خوش آمدید 👋', 'tr': 'Hoş geldin 👋', 'id': 'Selamat datang 👋', 'bn': 'স্বাগতম 👋', 'ha': 'Barka da zuwa 👋',
    'so': 'Soo dhawoow 👋', 'fa': 'خوش آمدی 👋', 'ms': 'Selamat datang 👋',
  },
  'home_greeting_subtitle': {
    'ar': 'كل إنجاز جديد يقربك من هدفك!', 'en': 'Every new accomplishment brings you closer to your goal!', 'am': 'እያንዳንዱ አዲስ ስኬት ወደ ግብህ ያቀርብሃል!', 'fr': 'Chaque nouvelle réalisation vous rapproche de votre objectif !', 'sw': 'Kila mafanikio mapya yanakuleta karibu na lengo lako!',
    'ur': 'ہر نئی کامیابی آپ کو آپ کے ہدف کے قریب لاتی ہے!', 'tr': 'Her yeni başarı seni hedefine yaklaştırıyor!', 'id': 'Setiap pencapaian baru mendekatkan Anda pada target Anda!', 'bn': 'প্রতিটি নতুন অর্জন আপনাকে লক্ষ্যের কাছে নিয়ে যায়!', 'ha': 'Kowane sabon nasara yana kusantar da kai ga manufarka!',
    'so': 'Guul kasta oo cusub ayaa kuu soo dhoweeya yoolkaaga!', 'fa': 'هر دستاورد جدید تو را به هدفت نزدیک‌تر می‌کند!', 'ms': 'Setiap pencapaian baharu membawa anda lebih dekat kepada matlamat anda!',
  },
  'quran_hero_title': {
    'ar': 'القرآن الكريم', 'en': 'The Noble Quran', 'am': 'ቅዱስ ቁርኣን', 'fr': 'Le Saint Coran', 'sw': 'Qur\'an Tukufu',
    'ur': 'قرآن کریم', 'tr': "Kur'an-ı Kerim", 'id': 'Al-Qur\'an Al-Karim', 'bn': 'পবিত্র কুরআন', 'ha': "Al-Qur'ani Mai Girma",
    'so': "Qur'aanka Kariimka ah", 'fa': 'قرآن کریم', 'ms': 'Al-Quran Al-Karim',
  },
  'quran_hero_subtitle': {
    'ar': 'حفظ، تكرار، تفسير، قراءة، وبحث', 'en': 'Memorization, repetition, tafsir, reading, and search', 'am': 'ማጥናት፣ መደጋገም፣ ትርጓሜ፣ ማንበብ እና መፈለግ', 'fr': 'Mémorisation, répétition, tafsir, lecture et recherche', 'sw': 'Kuhifadhi, kurudia, tafsiri, kusoma, na kutafuta',
    'ur': 'حفظ، تکرار، تفسیر، مطالعہ، اور تلاش', 'tr': 'Ezber, tekrar, tefsir, okuma ve arama', 'id': 'Hafalan, pengulangan, tafsir, bacaan, dan pencarian', 'bn': 'হিফজ, পুনরাবৃত্তি, তাফসীর, পড়া, ও অনুসন্ধান', 'ha': 'Hifzi, maimaitawa, tafsiri, karatu, da bincike',
    'so': 'Xifdhid, ku celcelin, tafsiir, akhris, iyo raadinta', 'fa': 'حفظ، تکرار، تفسیر، خواندن و جستجو', 'ms': 'Hafazan, ulangan, tafsir, bacaan, dan carian',
  },
  'pages_memorized_so_far': {
    'ar': 'صفحة محفوظة حتى الآن', 'en': 'pages memorized so far', 'am': 'ገጾች እስካሁን ተጠንተዋል', 'fr': "pages mémorisées jusqu'à présent", 'sw': 'kurasa zilizohifadhiwa hadi sasa',
    'ur': 'صفحات اب تک حفظ ہوئیں', 'tr': 'sayfa şimdiye kadar ezberlendi', 'id': 'halaman dihafal sejauh ini', 'bn': 'পৃষ্ঠা এখন পর্যন্ত মুখস্থ হয়েছে', 'ha': 'shafuka an haddace su har yanzu',
    'so': 'bog oo la xifdhay ilaa hadda', 'fa': 'صفحه تاکنون حفظ شده', 'ms': 'muka surat dihafaz setakat ini',
  },
  'month_progress_label': {
    'ar': 'تقدم شهر', 'en': 'Progress for', 'am': 'የ ወር እድገት', 'fr': 'Progrès du mois de', 'sw': 'Maendeleo ya mwezi',
    'ur': 'ماہ کی پیش رفت', 'tr': 'Ay ilerlemesi', 'id': 'Kemajuan bulan', 'bn': 'মাসের অগ্রগতি', 'ha': 'Ci gaban wata',
    'so': 'Horumarka bisha', 'fa': 'پیشرفت ماه', 'ms': 'Kemajuan bulan',
  },
  'stay_on_track_goals': {
    'ar': 'استمر على الطريق الصحيح لتحقيق أهدافك', 'en': 'Stay on track to reach your goals', 'am': 'ግቦችህን ለማሳካት በትክክለኛው መንገድ ላይ ቀጥል', 'fr': 'Restez sur la bonne voie pour atteindre vos objectifs', 'sw': 'Endelea kwenye njia sahihi kufikia malengo yako',
    'ur': 'اپنے اہداف تک پہنچنے کے لیے صحیح راستے پر رہیں', 'tr': 'Hedeflerine ulaşmak için doğru yolda kal', 'id': 'Tetap di jalur untuk mencapai target Anda', 'bn': 'লক্ষ্যে পৌঁছাতে সঠিক পথে থাকুন', 'ha': 'Ci gaba a kan hanya madaidaiciya don cimma manufofinka',
    'so': 'Sii wad jidka saxda ah si aad u gaarto yoolalkaaga', 'fa': 'برای رسیدن به اهدافت در مسیر درست بمان', 'ms': 'Kekal di landasan untuk mencapai matlamat anda',
  },
  'completed_label': {
    'ar': 'مكتملة', 'en': 'Completed', 'am': 'የተጠናቀቀ', 'fr': 'Terminé', 'sw': 'Imekamilika',
    'ur': 'مکمل', 'tr': 'Tamamlandı', 'id': 'Selesai', 'bn': 'সম্পন্ন', 'ha': 'An Kammala',
    'so': 'La Dhammeeyay', 'fa': 'تکمیل‌شده', 'ms': 'Selesai',
  },
  'remaining_label': {
    'ar': 'متبقية', 'en': 'Remaining', 'am': 'የቀረ', 'fr': 'Restant', 'sw': 'Iliyobaki',
    'ur': 'باقی', 'tr': 'Kalan', 'id': 'Tersisa', 'bn': 'বাকি', 'ha': 'Sauran',
    'so': 'Haray', 'fa': 'باقی‌مانده', 'ms': 'Baki',
  },
  'add_goals_this_month': {
    'ar': 'أضف أهدافاً لهذا الشهر لمتابعة تقدمك', 'en': 'Add goals for this month to track your progress', 'am': 'እድገትህን ለመከታተል ለዚህ ወር ግቦችን ጨምር', 'fr': 'Ajoutez des objectifs pour ce mois pour suivre vos progrès', 'sw': 'Ongeza malengo kwa mwezi huu kufuatilia maendeleo yako',
    'ur': 'اپنی پیش رفت دیکھنے کے لیے اس ماہ کے اہداف شامل کریں', 'tr': 'İlerlemeni takip etmek için bu ay için hedefler ekle', 'id': 'Tambahkan target untuk bulan ini guna melacak kemajuan Anda', 'bn': 'অগ্রগতি ট্র্যাক করতে এই মাসের লক্ষ্য যোগ করুন', 'ha': 'Ƙara manufofi na wannan wata don bin diddigin ci gabanka',
    'so': 'Ku dar yoolal bishan si aad u raadraacdo horumarkaaga', 'fa': 'برای پیگیری پیشرفتت، برای این ماه هدف اضافه کن', 'ms': 'Tambah matlamat untuk bulan ini untuk menjejak kemajuan anda',
  },
  'today_tasks_label': {
    'ar': 'مهام اليوم', 'en': "Today's Tasks", 'am': 'የዛሬ ተግባራት', 'fr': "Tâches du jour", 'sw': 'Kazi za Leo',
    'ur': 'آج کے کام', 'tr': 'Bugünün Görevleri', 'id': 'Tugas Hari Ini', 'bn': 'আজকের কাজ', 'ha': 'Ayyukan Yau',
    'so': 'Hawlaha Maanta', 'fa': 'کارهای امروز', 'ms': 'Tugasan Hari Ini',
  },
  'view_all': {
    'ar': 'عرض الكل', 'en': 'View All', 'am': 'ሁሉንም አሳይ', 'fr': 'Tout afficher', 'sw': 'Ona Zote',
    'ur': 'سب دیکھیں', 'tr': 'Tümünü Gör', 'id': 'Lihat Semua', 'bn': 'সব দেখুন', 'ha': 'Duba Duka',
    'so': 'Dhammaan Fiiri', 'fa': 'مشاهده همه', 'ms': 'Lihat Semua',
  },
  'add_task_today': {
    'ar': 'إضافة مهمة لليوم', 'en': "Add a task for today", 'am': 'ለዛሬ ተግባር ጨምር', 'fr': "Ajouter une tâche pour aujourd'hui", 'sw': 'Ongeza kazi kwa leo',
    'ur': 'آج کے لیے کام شامل کریں', 'tr': 'Bugün için görev ekle', 'id': 'Tambah tugas untuk hari ini', 'bn': 'আজকের জন্য কাজ যোগ করুন', 'ha': 'Ƙara aiki na yau',
    'so': 'Ku dar hawl maanta', 'fa': 'افزودن کار برای امروز', 'ms': 'Tambah tugasan untuk hari ini',
  },
  'recent_activities_label': {
    'ar': 'آخر الأنشطة', 'en': 'Recent Activities', 'am': 'የቅርብ ጊዜ እንቅስቃሴዎች', 'fr': 'Activités récentes', 'sw': 'Shughuli za Hivi Karibuni',
    'ur': 'حالیہ سرگرمیاں', 'tr': 'Son Etkinlikler', 'id': 'Aktivitas Terbaru', 'bn': 'সাম্প্রতিক কার্যক্রম', 'ha': 'Ayyukan Kwanan Nan',
    'so': 'Hawlaha Dhawaan', 'fa': 'فعالیت‌های اخیر', 'ms': 'Aktiviti Terkini',
  },
  'no_activities_this_month': {
    'ar': 'لم تُسجَّل أي أنشطة هذا الشهر بعد', 'en': 'No activities recorded this month yet', 'am': 'ለዚህ ወር እስካሁን ምንም እንቅስቃሴ አልተመዘገበም', 'fr': "Aucune activité enregistrée ce mois-ci pour l'instant", 'sw': 'Bado hakuna shughuli zilizorekodiwa mwezi huu',
    'ur': 'اس مہینے ابھی تک کوئی سرگرمی درج نہیں ہوئی', 'tr': 'Bu ay henüz etkinlik kaydedilmedi', 'id': 'Belum ada aktivitas tercatat bulan ini', 'bn': 'এই মাসে এখনও কোনো কার্যক্রম রেকর্ড হয়নি', 'ha': 'Ba a rubuta wani aiki ba tukuna a wannan watan',
    'so': 'Wali bishan hawl lama duubin', 'fa': 'هنوز فعالیتی برای این ماه ثبت نشده', 'ms': 'Belum ada aktiviti direkodkan bulan ini',
  },
  'quran_memorization_label': {
    'ar': 'حفظ القرآن', 'en': 'Quran Memorization', 'am': 'የቁርኣን ማጥናት', 'fr': 'Mémorisation du Coran', 'sw': 'Kuhifadhi Qur\'an',
    'ur': 'قرآن حفظ کرنا', 'tr': "Kur'an Ezberi", 'id': 'Hafalan Al-Qur\'an', 'bn': 'কুরআন হিফজ', 'ha': "Hifzin Alkur'ani",
    'so': "Xifdhinta Qur'aanka", 'fa': 'حفظ قرآن', 'ms': 'Hafazan Al-Quran',
  },
  'of_label': {
    'ar': 'من', 'en': 'of', 'am': 'ከ', 'fr': 'sur', 'sw': 'kati ya',
    'ur': 'میں سے', 'tr': '/', 'id': 'dari', 'bn': 'এর মধ্যে', 'ha': 'daga cikin',
    'so': 'ee', 'fa': 'از', 'ms': 'daripada',
  },
  'surah_unit_label': {
    'ar': 'سورة', 'en': 'Surahs', 'am': 'ሱራዎች', 'fr': 'sourates', 'sw': 'Sura',
    'ur': 'سورتیں', 'tr': 'sure', 'id': 'Surah', 'bn': 'সূরা', 'ha': 'Sura',
    'so': 'Suuradood', 'fa': 'سوره', 'ms': 'Surah',
  },
  'review_label': {
    'ar': 'المراجعة', 'en': 'Review', 'am': 'ግምገማ', 'fr': 'Révision', 'sw': 'Mapitio',
    'ur': 'مراجعہ', 'tr': 'Tekrar', 'id': 'Ulasan', 'bn': 'পর্যালোচনা', 'ha': 'Bitawa',
    'so': 'Dib u eegis', 'fa': 'مرور', 'ms': 'Ulasan',
  },
  'pages_due_today': {
    'ar': 'صفحة مستحقة اليوم', 'en': 'pages due today', 'am': 'ገጾች ዛሬ የሚገባቸው', 'fr': "pages dues aujourd'hui", 'sw': 'kurasa zinazostahili leo',
    'ur': 'صفحات آج واجب الادا', 'tr': 'sayfa bugün tekrar için', 'id': 'halaman jatuh tempo hari ini', 'bn': 'পৃষ্ঠা আজ প্রাপ্য', 'ha': 'shafuka sun cancanci yau',
    'so': 'bog maanta waajib ku ah', 'fa': 'صفحه امروز سررسید', 'ms': 'muka surat perlu diulang hari ini',
  },
  'no_reviews_due_today': {
    'ar': 'لا مراجعات مستحقة اليوم 🌱', 'en': 'No reviews due today 🌱', 'am': 'ዛሬ ምንም ግምገማ የለም 🌱', 'fr': "Aucune révision due aujourd'hui 🌱", 'sw': 'Hakuna mapitio yanayostahili leo 🌱',
    'ur': 'آج کوئی مراجعہ واجب نہیں 🌱', 'tr': 'Bugün tekrar edilecek yok 🌱', 'id': 'Tidak ada ulasan jatuh tempo hari ini 🌱', 'bn': 'আজ কোনো পর্যালোচনা প্রাপ্য নেই 🌱', 'ha': 'Babu bitawa da ta cancanta yau 🌱',
    'so': 'Maanta dib u eegis waajib ma ahan 🌱', 'fa': 'امروز مروری سررسید نیست 🌱', 'ms': 'Tiada ulasan perlu hari ini 🌱',
  },
  'end_of_day_title': {
    'ar': 'انتهت رحلة اليوم', 'en': "Today's journey has ended", 'am': 'የዛሬው ጉዞ አልቋል', 'fr': "Le parcours d'aujourd'hui est terminé", 'sw': 'Safari ya leo imekwisha',
    'ur': 'آج کا سفر ختم ہوا', 'tr': "Bugünün yolculuğu sona erdi", 'id': 'Perjalanan hari ini telah berakhir', 'bn': 'আজকের যাত্রা শেষ হয়েছে', 'ha': 'Tafiyar yau ta ƙare',
    'so': 'Safarkii maanta wuu dhammaaday', 'fa': 'سفر امروز به پایان رسید', 'ms': 'Perjalanan hari ini telah berakhir',
  },
  'end_of_day_subtitle': {
    'ar': 'ماذا أنجزت اليوم؟ سجّله الآن', 'en': 'What did you accomplish today? Log it now', 'am': 'ዛሬ ምን አሳካህ? አሁን መዝግበው', 'fr': "Qu'avez-vous accompli aujourd'hui ? Enregistrez-le maintenant", 'sw': 'Umetimiza nini leo? Rekodi sasa',
    'ur': 'آج آپ نے کیا حاصل کیا؟ ابھی درج کریں', 'tr': 'Bugün ne başardın? Şimdi kaydet', 'id': 'Apa yang Anda capai hari ini? Catat sekarang', 'bn': 'আজ আপনি কী অর্জন করলেন? এখনই লিখুন', 'ha': 'Me ka cim ma yau? Rubuta yanzu',
    'so': 'Maxaad maanta gaadhay? Hadda diwaan geli', 'fa': 'امروز چه کاری انجام دادی؟ همین حالا ثبتش کن', 'ms': 'Apa yang anda capai hari ini? Rekodkan sekarang',
  },
  // 2026-08-17: `journey_screen.dart`'s `_DashboardView` — the live رحلتي
  // dashboard shown after the wizard, flagged by Ismail's own screenshot
  // ("هذا مجرد مثال وأنت توسع") as still 100% hardcoded despite the
  // wizard itself (`_WizardView`) already being translated earlier.
  'day_number_prefix': {
    'ar': 'أنت اليوم في اليوم', 'en': "You're on day", 'am': 'ዛሬ ቀን ላይ ነህ', 'fr': "Vous êtes au jour", 'sw': 'Uko siku ya',
    'ur': 'آپ آج دن پر ہیں', 'tr': 'Bugün gündesin', 'id': 'Anda berada di hari ke-', 'bn': 'আপনি আজ দিনে আছেন', 'ha': 'Kana kan rana',
    'so': 'Waxaad joogtaa maalinta', 'fa': 'امروز در روز هستی', 'ms': 'Anda berada pada hari',
  },
  'schedule_ahead': {
    'ar': 'متقدّم على الخطة', 'en': 'Ahead of plan', 'am': 'ከዕቅዱ ቀድሟል', 'fr': 'En avance sur le plan', 'sw': 'Mbele ya mpango',
    'ur': 'منصوبے سے آگے', 'tr': 'Plandan ileride', 'id': 'Lebih cepat dari rencana', 'bn': 'পরিকল্পনার চেয়ে এগিয়ে', 'ha': 'Gaba da shiri',
    'so': 'Ka horreeya qorshaha', 'fa': 'جلوتر از برنامه', 'ms': 'Mendahului rancangan',
  },
  'schedule_on_track': {
    'ar': 'في الموعد', 'en': 'On track', 'am': 'በትክክለኛው ጊዜ', 'fr': 'Dans les temps', 'sw': 'Kwa wakati',
    'ur': 'وقت پر', 'tr': 'Zamanında', 'id': 'Sesuai jadwal', 'bn': 'সময়মতো', 'ha': 'A kan lokaci',
    'so': 'Waqtiga saxda ah', 'fa': 'طبق برنامه', 'ms': 'Mengikut jadual',
  },
  'schedule_behind': {
    'ar': 'متأخر عن الخطة', 'en': 'Behind plan', 'am': 'ከዕቅዱ ኋላ ቀርቷል', 'fr': 'En retard sur le plan', 'sw': 'Nyuma ya mpango',
    'ur': 'منصوبے سے پیچھے', 'tr': 'Plandan geride', 'id': 'Tertinggal dari rencana', 'bn': 'পরিকল্পনার চেয়ে পিছিয়ে', 'ha': 'Baya da shiri',
    'so': 'Ka dib qorshaha', 'fa': 'عقب‌تر از برنامه', 'ms': 'Ketinggalan rancangan',
  },
  'current_pace_label': {
    'ar': 'الوتيرة الحالية', 'en': 'Current pace', 'am': 'የአሁኑ ፍጥነት', 'fr': 'Rythme actuel', 'sw': 'Kasi ya Sasa',
    'ur': 'موجودہ رفتار', 'tr': 'Mevcut Hız', 'id': 'Kecepatan Saat Ini', 'bn': 'বর্তমান গতি', 'ha': 'Gudun Yanzu',
    'so': 'Xawaaraha Hadda', 'fa': 'سرعت فعلی', 'ms': 'Kadar Semasa',
  },
  'daily_suffix': {
    'ar': 'يوميًا', 'en': 'per day', 'am': 'በቀን', 'fr': 'par jour', 'sw': 'kwa siku',
    'ur': 'روزانہ', 'tr': 'günlük', 'id': 'per hari', 'bn': 'প্রতিদিন', 'ha': 'a rana',
    'so': 'maalintii', 'fa': 'روزانه', 'ms': 'sehari',
  },
  'remaining_prefix': {
    'ar': 'بقي', 'en': 'remaining', 'am': 'ቀርቷል', 'fr': 'restant', 'sw': 'imebaki',
    'ur': 'باقی', 'tr': 'kaldı', 'id': 'tersisa', 'bn': 'বাকি', 'ha': 'ya rage',
    'so': 'haray', 'fa': 'باقی‌مانده', 'ms': 'baki',
  },
  'days_unit_label': {
    'ar': 'يومًا', 'en': 'days', 'am': 'ቀናት', 'fr': 'jours', 'sw': 'siku',
    'ur': 'دن', 'tr': 'gün', 'id': 'hari', 'bn': 'দিন', 'ha': 'kwanaki',
    'so': 'maalmood', 'fa': 'روز', 'ms': 'hari',
  },
  'replan_button': {
    'ar': 'أعِد التخطيط', 'en': 'Re-plan', 'am': 'እንደገና እቅድ አውጣ', 'fr': 'Replanifier', 'sw': 'Panga Upya',
    'ur': 'دوبارہ منصوبہ بندی کریں', 'tr': 'Yeniden Planla', 'id': 'Rencanakan Ulang', 'bn': 'পুনরায় পরিকল্পনা করুন', 'ha': 'Sake Shirya',
    'so': 'Dib u Qorshee', 'fa': 'برنامه‌ریزی دوباره', 'ms': 'Rancang Semula',
  },
  'today_assignment_label': {
    'ar': 'تكليف اليوم', 'en': "Today's Assignment", 'am': 'የዛሬ ስራ', 'fr': "Tâche du jour", 'sw': 'Kazi ya Leo',
    'ur': 'آج کا کام', 'tr': 'Bugünün Görevi', 'id': 'Tugas Hari Ini', 'bn': 'আজকের কাজ', 'ha': 'Aikin Yau',
    'so': 'Hawsha Maanta', 'fa': 'تکلیف امروز', 'ms': 'Tugasan Hari Ini',
  },
  'page_label': {
    'ar': 'صفحة', 'en': 'Page', 'am': 'ገጽ', 'fr': 'Page', 'sw': 'Ukurasa',
    'ur': 'صفحہ', 'tr': 'Sayfa', 'id': 'Halaman', 'bn': 'পৃষ্ঠা', 'ha': 'Shafi',
    'so': 'Bogga', 'fa': 'صفحه', 'ms': 'Muka Surat',
  },
  'from_ayah_label': {
    'ar': 'من آية', 'en': 'from ayah', 'am': 'ከአንቀጽ', 'fr': 'à partir du verset', 'sw': 'kutoka aya',
    'ur': 'آیت سے', 'tr': 'ayetten itibaren', 'id': 'dari ayat', 'bn': 'আয়াত থেকে', 'ha': 'daga aya',
    'so': 'aayad ka bilaabma', 'fa': 'از آیه', 'ms': 'daripada ayat',
  },
  'max_realistic_pace_label': {
    'ar': 'الوتيرة الواقعية القصوى لمستواك', 'en': 'Maximum realistic pace for your level', 'am': 'ለደረጃህ ተጨባጭ ከፍተኛ ፍጥነት', 'fr': 'Rythme réaliste maximal pour votre niveau', 'sw': 'Kasi halisi ya juu kwa kiwango chako',
    'ur': 'آپ کے درجے کے لیے زیادہ سے زیادہ حقیقت پسندانہ رفتار', 'tr': 'Seviyen için gerçekçi azami hız', 'id': 'Kecepatan realistis maksimum untuk level Anda', 'bn': 'আপনার স্তরের জন্য সর্বোচ্চ বাস্তবসম্মত গতি', 'ha': 'Iyakar gudu na gaskiya don matsayinka',
    'so': 'Xawaaraha ugu badan ee dhabta ah ee heerkaaga', 'fa': 'حداکثر سرعت واقع‌بینانه برای سطح تو', 'ms': 'Kadar realistik maksimum untuk tahap anda',
  },
  'pages_per_day_label': {
    'ar': 'صفحة/يوم', 'en': 'pages/day', 'am': 'ገጽ/ቀን', 'fr': 'pages/jour', 'sw': 'kurasa/siku',
    'ur': 'صفحات/دن', 'tr': 'sayfa/gün', 'id': 'halaman/hari', 'bn': 'পৃষ্ঠা/দিন', 'ha': 'shafuka/rana',
    'so': 'bog/maalin', 'fa': 'صفحه/روز', 'ms': 'muka surat/hari',
  },
  'start_memorizing_button': {
    'ar': 'ابدأ الحفظ', 'en': 'Start Memorizing', 'am': 'መጥናት ጀምር', 'fr': 'Commencer la mémorisation', 'sw': 'Anza Kuhifadhi',
    'ur': 'حفظ شروع کریں', 'tr': 'Ezberlemeye Başla', 'id': 'Mulai Menghafal', 'bn': 'মুখস্থ করা শুরু করুন', 'ha': 'Fara Hifzi',
    'so': 'Bilow Xifdhinta', 'fa': 'شروع حفظ', 'ms': 'Mula Menghafaz',
  },
  'mastery_percent_label': {
    'ar': 'إتقان', 'en': 'Mastery', 'am': 'ብቃት', 'fr': 'Maîtrise', 'sw': 'Umahiri',
    'ur': 'مہارت', 'tr': 'Ustalık', 'id': 'Penguasaan', 'bn': 'দক্ষতা', 'ha': 'Ƙwarewa',
    'so': 'Aqoonta Buuxda', 'fa': 'تسلط', 'ms': 'Penguasaan',
  },
  'pages_fully_mastered_suffix': {
    'ar': 'صفحة متقنة تمامًا (بعد مراجعات متكررة، لا بمجرد "حفظتها")', 'en': 'pages fully mastered (after repeated reviews, not just marked "memorized")', 'am': 'ገጾች ሙሉ በሙሉ ተካኑ (ደጋግሞ ከመገምገም በኋላ፣ "ተጠንቷል" ተብሎ ብቻ ሳይሆን)', 'fr': 'pages entièrement maîtrisées (après révisions répétées, pas seulement marquées « mémorisées »)', 'sw': 'kurasa zilizomudu kikamilifu (baada ya mapitio ya mara kwa mara, si tu kuwekwa alama "imehifadhiwa")',
    'ur': 'صفحات مکمل طور پر مہارت حاصل (بار بار مراجعے کے بعد، صرف "حفظ ہوگئی" نشان زد کرنے سے نہیں)', 'tr': 'tamamen ustalaşılmış sayfa (tekrar tekrar gözden geçirildikten sonra, sadece "ezberlendi" işaretlenerek değil)', 'id': 'halaman dikuasai sepenuhnya (setelah tinjauan berulang, bukan hanya ditandai "dihafal")', 'bn': 'পৃষ্ঠা সম্পূর্ণরূপে আয়ত্ত (বারবার পর্যালোচনার পরে, শুধু "মুখস্থ" চিহ্নিত করে নয়)', 'ha': 'shafuka da aka ƙware su gaba ɗaya (bayan sake dubawa akai-akai, ba kawai a alamta "an haddace" ba)',
    'so': 'bog si buuxda loo yaqaan (ka dib dib-u-eegis soo noqnoqda, ee aan ahayn oo la calaamadeeyay "waa la xifdhay" oo keliya)', 'fa': 'صفحه کاملاً تسلط‌یافته (پس از مرورهای مکرر، نه فقط با علامت‌گذاری "حفظ شد")', 'ms': 'muka surat dikuasai sepenuhnya (selepas ulangan berulang, bukan hanya ditanda "dihafaz")',
  },
  'hizb_completed_prefix': {
    'ar': 'بالحزب', 'en': 'By Hizb', 'am': 'በሂዝብ', 'fr': 'Par Hizb', 'sw': 'Kwa Hizb',
    'ur': 'حزب کے حساب سے', 'tr': 'Hizip Bazında', 'id': 'Berdasarkan Hizb', 'bn': 'হিজব অনুযায়ী', 'ha': 'Ta Hizbi',
    'so': 'Xisbiga ahaan', 'fa': 'بر اساس حزب', 'ms': 'Mengikut Hizb',
  },
  'hizb_completed_suffix': {
    'ar': 'حزبًا مكتملًا', 'en': 'Hizb completed', 'am': 'ሂዝብ ተጠናቅቋል', 'fr': 'Hizb complété', 'sw': 'Hizb zilizokamilika',
    'ur': 'حزب مکمل', 'tr': 'hizip tamamlandı', 'id': 'Hizb selesai', 'bn': 'হিজব সম্পন্ন', 'ha': 'Hizbi da aka kammala',
    'so': 'Xisbi la dhammeeyay', 'fa': 'حزب تکمیل‌شده', 'ms': 'Hizb selesai',
  },
  'days_ago_had_pages_prefix': {
    'ar': 'قبل 30 يومًا كان لديك', 'en': '30 days ago you had', 'am': 'ከ30 ቀናት በፊት ነበረህ', 'fr': "Il y a 30 jours, vous aviez", 'sw': 'Siku 30 zilizopita ulikuwa na',
    'ur': '30 دن پہلے آپ کے پاس تھیں', 'tr': '30 gün önce vardı', 'id': '30 hari lalu Anda memiliki', 'bn': '৩০ দিন আগে আপনার ছিল', 'ha': 'Kwana 30 da suka wuce kana da',
    'so': '30 maalmood ka hor waxaad lahayd', 'fa': '۳۰ روز پیش داشتی', 'ms': '30 hari lalu anda mempunyai',
  },
  'pages_word': {
    'ar': 'صفحة', 'en': 'pages', 'am': 'ገጾች', 'fr': 'pages', 'sw': 'kurasa',
    'ur': 'صفحات', 'tr': 'sayfa', 'id': 'halaman', 'bn': 'পৃষ্ঠা', 'ha': 'shafuka',
    'so': 'bog', 'fa': 'صفحه', 'ms': 'muka surat',
  },
  'added_since_then_prefix': {
    'ar': 'أضفت', 'en': 'you added', 'am': 'ጨምረሃል', 'fr': 'vous avez ajouté', 'sw': 'umeongeza',
    'ur': 'آپ نے شامل کیں', 'tr': 'eklediniz', 'id': 'Anda menambahkan', 'bn': 'আপনি যোগ করেছেন', 'ha': 'ka ƙara',
    'so': 'waxaad ku dartay', 'fa': 'اضافه کردی', 'ms': 'anda menambah',
  },
  'pages_since_then_suffix': {
    'ar': 'صفحة منذ ذلك الحين', 'en': 'pages since then', 'am': 'ገጾች ከዚያ ጊዜ ጀምሮ', 'fr': 'pages depuis lors', 'sw': 'kurasa tangu wakati huo',
    'ur': 'صفحات اس وقت سے', 'tr': 'sayfa o zamandan beri', 'id': 'halaman sejak saat itu', 'bn': 'পৃষ্ঠা তখন থেকে', 'ha': 'shafuka tun daga wannan lokaci',
    'so': 'bog tan iyo markaas', 'fa': 'صفحه از آن زمان', 'ms': 'muka surat sejak itu',
  },
  'longest_streak_label': {
    'ar': '🏆 أطول فترة استمرار', 'en': '🏆 Longest streak', 'am': '🏆 ረጅሙ ተከታታይ ጊዜ', 'fr': '🏆 Plus longue série', 'sw': '🏆 Mfululizo Mrefu Zaidi',
    'ur': '🏆 طویل ترین تسلسل', 'tr': '🏆 En Uzun Seri', 'id': '🏆 Rentetan Terpanjang', 'bn': '🏆 দীর্ঘতম ধারাবাহিকতা', 'ha': '🏆 Dogon Jerin Ci Gaba',
    'so': '🏆 Xilliga ugu dheer ee Joogtaynta', 'fa': '🏆 طولانی‌ترین توالی', 'ms': '🏆 Jujukan Terpanjang',
  },
  'review_success_rate_prefix': {
    'ar': 'معدل نجاحك في المراجعة', 'en': 'Your review success rate', 'am': 'የግምገማ ስኬት መጠንህ', 'fr': 'Votre taux de réussite en révision', 'sw': 'Kiwango chako cha mafanikio ya mapitio',
    'ur': 'مراجعے میں آپ کی کامیابی کی شرح', 'tr': 'Tekrar başarı oranın', 'id': 'Tingkat keberhasilan ulasan Anda', 'bn': 'আপনার পর্যালোচনার সাফল্যের হার', 'ha': 'Adadin nasarar bitawarka',
    'so': 'Heerka guusha dib-u-eegistaada', 'fa': 'نرخ موفقیت مرور تو', 'ms': 'Kadar kejayaan ulasan anda',
  },
  'excellent_good_label': {
    'ar': '(ممتاز/جيد)', 'en': '(excellent/good)', 'am': '(በጣም ጥሩ/ጥሩ)', 'fr': '(excellent/bien)', 'sw': '(bora/nzuri)',
    'ur': '(بہترین/اچھا)', 'tr': '(mükemmel/iyi)', 'id': '(sangat baik/baik)', 'bn': '(চমৎকার/ভালো)', 'ha': '(mafi kyau/kyau)',
    'so': '(heersare/wanaagsan)', 'fa': '(عالی/خوب)', 'ms': '(cemerlang/baik)',
  },
  'my_certificates_label': {
    'ar': 'شهاداتي', 'en': 'My Certificates', 'am': 'የምስክር ወረቀቶቼ', 'fr': 'Mes certificats', 'sw': 'Vyeti Vyangu',
    'ur': 'میرے سرٹیفکیٹس', 'tr': 'Sertifikalarım', 'id': 'Sertifikat Saya', 'bn': 'আমার সার্টিফিকেট', 'ha': 'Takardun Shaidata',
    'so': 'Shahaadooyinkayga', 'fa': 'گواهی‌های من', 'ms': 'Sijil Saya',
  },
  'my_curriculum_map_label': {
    'ar': 'خريطتي التعليمية', 'en': 'My Curriculum Map', 'am': 'የትምህርት ካርታዬ', 'fr': "Ma carte d'apprentissage", 'sw': 'Ramani Yangu ya Elimu',
    'ur': 'میرا نصابی نقشہ', 'tr': 'Müfredat Haritam', 'id': 'Peta Kurikulum Saya', 'bn': 'আমার পাঠ্যক্রম মানচিত্র', 'ha': 'Taswirar Manhajina',
    'so': 'Khariidadda Waxbarashadayda', 'fa': 'نقشه برنامه درسی من', 'ms': 'Peta Kurikulum Saya',
  },
  'my_mission_label': {
    'ar': '🎯 رسالتي', 'en': '🎯 My Mission', 'am': '🎯 ተልእኮዬ', 'fr': '🎯 Ma mission', 'sw': '🎯 Dhamira Yangu',
    'ur': '🎯 میرا مشن', 'tr': '🎯 Misyonum', 'id': '🎯 Misi Saya', 'bn': '🎯 আমার লক্ষ্য', 'ha': '🎯 Manufata',
    'so': '🎯 Hadafkayga', 'fa': '🎯 مأموریت من', 'ms': '🎯 Misi Saya',
  },
  'command_center_label': {
    'ar': 'لوحة القيادة', 'en': 'Command Center', 'am': 'የቁጥጥር ማዕከል', 'fr': 'Centre de contrôle', 'sw': 'Kituo cha Amri',
    'ur': 'کمانڈ سینٹر', 'tr': 'Kumanda Merkezi', 'id': 'Pusat Kendali', 'bn': 'কমান্ড সেন্টার', 'ha': 'Cibiyar Umarni',
    'so': 'Xarunta Amarka', 'fa': 'مرکز فرماندهی', 'ms': 'Pusat Arahan',
  },
  'personal_commitment_label': {
    'ar': 'التزامي الشخصي', 'en': 'My Personal Commitment', 'am': 'የግል ቁርጠኝነቴ', 'fr': 'Mon engagement personnel', 'sw': 'Ahadi Yangu Binafsi',
    'ur': 'میرا ذاتی عزم', 'tr': 'Kişisel Taahhüdüm', 'id': 'Komitmen Pribadi Saya', 'bn': 'আমার ব্যক্তিগত অঙ্গীকার', 'ha': 'Alkawarina na Kai',
    'so': 'Ballanqaadkayga Shakhsiga', 'fa': 'تعهد شخصی من', 'ms': 'Komitmen Peribadi Saya',
  },
  'no_commitment_yet': {
    'ar': 'لم تكتب التزامًا بعد', 'en': "You haven't written a commitment yet", 'am': 'እስካሁን ቁርጠኝነት አልፃፍክም', 'fr': "Vous n'avez pas encore écrit d'engagement", 'sw': 'Bado hujaandika ahadi',
    'ur': 'آپ نے ابھی تک کوئی عزم نہیں لکھا', 'tr': 'Henüz bir taahhüt yazmadın', 'id': 'Anda belum menulis komitmen', 'bn': 'আপনি এখনও কোনো অঙ্গীকার লেখেননি', 'ha': 'Ba ka rubuta alkawari ba tukuna',
    'so': 'Wali ballanqaad ma qorin', 'fa': 'هنوز تعهدی ننوشته‌ای', 'ms': 'Anda belum menulis komitmen',
  },
  'edit_action': {
    'ar': 'تعديل', 'en': 'Edit', 'am': 'አርትዕ', 'fr': 'Modifier', 'sw': 'Hariri',
    'ur': 'ترمیم کریں', 'tr': 'Düzenle', 'id': 'Ubah', 'bn': 'সম্পাদনা করুন', 'ha': 'Gyara',
    'so': 'Wax ka beddel', 'fa': 'ویرایش', 'ms': 'Edit',
  },
  'behind_schedule_title': {
    'ar': 'أنت متأخر قليلًا عن الخطة — لا بأس', 'en': "You're a bit behind schedule — that's okay", 'am': 'ከዕቅዱ ትንሽ ኋላ ቀርተሃል — ችግር የለውም', 'fr': "Vous êtes un peu en retard sur le plan — ce n'est pas grave", 'sw': 'Uko nyuma kidogo ya mpango — hakuna shida',
    'ur': 'آپ منصوبے سے تھوڑا پیچھے ہیں — کوئی بات نہیں', 'tr': 'Plandan biraz geridesin — sorun değil', 'id': 'Anda sedikit tertinggal dari rencana — tidak apa-apa', 'bn': 'আপনি পরিকল্পনার চেয়ে সামান্য পিছিয়ে — কোনো সমস্যা নেই', 'ha': 'Kana bayan shiri kaɗan — babu matsala',
    'so': 'Wax yar baad ka dib joogtaa qorshaha — waxba ha ka welwelin', 'fa': 'کمی از برنامه عقب هستی — اشکالی ندارد', 'ms': 'Anda sedikit ketinggalan rancangan — tidak mengapa',
  },
  'choose_whats_right_for_you': {
    'ar': 'اختر ما يناسبك، بلا أي ضغط:', 'en': 'Choose what works for you, no pressure:', 'am': 'ምንም ጫና ሳይኖር የሚስማማህን ምረጥ:', 'fr': 'Choisissez ce qui vous convient, sans pression :', 'sw': 'Chagua kinachokufaa, bila shinikizo:',
    'ur': 'جو آپ کے لیے موزوں ہے وہ منتخب کریں، کوئی دباؤ نہیں:', 'tr': 'Sana uygun olanı seç, baskı yok:', 'id': 'Pilih yang cocok untuk Anda, tanpa tekanan:', 'bn': 'আপনার জন্য যা উপযুক্ত তা বেছে নিন, কোনো চাপ নেই:', 'ha': 'Zaɓi abin da ya dace da kai, babu matsin lamba:',
    'so': 'Dooro waxa kuu habboon, cadaadis la\'aan:', 'fa': 'هرچه برایت مناسب است انتخاب کن، بدون فشار:', 'ms': 'Pilih apa yang sesuai untuk anda, tanpa tekanan:',
  },
  'continue_current_pace_title': {
    'ar': 'أكمل بوتيرتي الحالية', 'en': 'Continue at my current pace', 'am': 'በአሁኑ ፍጥነቴ ቀጥል', 'fr': 'Continuer à mon rythme actuel', 'sw': 'Endelea kwa kasi yangu ya sasa',
    'ur': 'اپنی موجودہ رفتار سے جاری رکھیں', 'tr': 'Mevcut hızımda devam et', 'id': 'Lanjutkan dengan kecepatan saya saat ini', 'bn': 'আমার বর্তমান গতিতে চালিয়ে যান', 'ha': 'Ci gaba da gudun yanzu',
    'so': 'Sii wad xawaaraha aan haddaba haysto', 'fa': 'با سرعت فعلی‌ام ادامه بده', 'ms': 'Teruskan pada kadar semasa saya',
  },
  'continue_current_pace_subtitle': {
    'ar': 'سيتأخر تاريخ الختم قليلًا، وهذا طبيعي', 'en': 'The completion date will be a bit later, and that\'s normal', 'am': 'የማጠናቀቂያ ቀኑ ትንሽ ይዘገያል፣ ይህም የተለመደ ነው', 'fr': 'La date de fin sera un peu retardée, et c\'est normal', 'sw': 'Tarehe ya kukamilisha itacheleweshwa kidogo, na hii ni kawaida',
    'ur': 'تکمیل کی تاریخ تھوڑی دیر ہو جائے گی، اور یہ معمول ہے', 'tr': 'Bitiş tarihi biraz gecikecek, bu normal', 'id': 'Tanggal penyelesaian akan sedikit tertunda, dan itu wajar', 'bn': 'সমাপ্তির তারিখ কিছুটা দেরি হবে, এবং এটি স্বাভাবিক', 'ha': 'Ranar kammalawa za ta ɗan jinkirta, wannan al\'ada ce',
    'so': 'Taariikhda dhammaadku wax yar buu daahi doonaa, taasna waa caadi', 'fa': 'تاریخ اتمام کمی دیرتر می‌شود، و این طبیعی است', 'ms': 'Tarikh siap akan sedikit lewat, dan itu perkara biasa',
  },
  'intensify_title': {
    'ar': 'كثّف للوصول للهدف الأصلي', 'en': 'Intensify to reach the original goal', 'am': 'ወደ መጀመሪያው ግብ ለመድረስ አጠናክር', 'fr': "Intensifier pour atteindre l'objectif initial", 'sw': 'Ongeza nguvu kufikia lengo la awali',
    'ur': 'اصل ہدف تک پہنچنے کے لیے شدت بڑھائیں', 'tr': 'Orijinal hedefe ulaşmak için yoğunlaştır', 'id': 'Tingkatkan untuk mencapai target awal', 'bn': 'মূল লক্ষ্যে পৌঁছাতে তীব্র করুন', 'ha': 'Ƙara ƙarfi don cimma manufa ta asali',
    'so': 'Kordhi si aad u gaarto yoolkii asalka ahaa', 'fa': 'برای رسیدن به هدف اصلی شدت بده', 'ms': 'Tingkatkan usaha untuk mencapai matlamat asal',
  },
  'target_pace_now_prefix': {
    'ar': 'وتيرتك المطلوبة الآن', 'en': 'Your required pace now', 'am': 'አሁን የሚያስፈልግህ ፍጥነት', 'fr': 'Votre rythme requis maintenant', 'sw': 'Kasi unayohitaji sasa',
    'ur': 'اب آپ کی مطلوبہ رفتار', 'tr': 'Şimdi gereken hızın', 'id': 'Kecepatan yang Anda perlukan sekarang', 'bn': 'এখন আপনার প্রয়োজনীয় গতি', 'ha': 'Gudun da ake buƙata a yanzu',
    'so': 'Xawaaraha aad hadda u baahan tahay', 'fa': 'سرعت لازم تو اکنون', 'ms': 'Kadar yang anda perlukan sekarang',
  },
  'calculated_pace_prefix': {
    'ar': 'الوتيرة المحسوبة', 'en': 'Calculated pace', 'am': 'የተሰላ ፍጥነት', 'fr': 'Rythme calculé', 'sw': 'Kasi Iliyokokotolewa',
    'ur': 'حساب شدہ رفتار', 'tr': 'Hesaplanan Hız', 'id': 'Kecepatan yang Dihitung', 'bn': 'গণনাকৃত গতি', 'ha': 'Gudun da Aka Ƙididdige',
    'so': 'Xawaaraha la Xisaabiyay', 'fa': 'سرعت محاسبه‌شده', 'ms': 'Kadar Dikira',
  },
  'ambitious_pace_warning': {
    'ar': 'هذه وتيرة أعلى مما يحفظه حتى الطالب المتفرغ بالكامل عادة (أعلى سقف واقعي معروف: صفحتان يوميًا) — لا بأس أن تجرّبها، لكن قد تحتاج إطالة المدة لاحقًا. سنعرض هذا التذكير دون منعك، القرار لك.', 'en': "This pace is higher than what even a full-time student typically memorizes (highest known realistic ceiling: 2 pages/day) — it's fine to try, but you may need to extend the duration later. We'll show this reminder without stopping you; the decision is yours.", 'am': 'ይህ ፍጥነት ሙሉ ጊዜ ከሚያጠናው ተማሪ እንኳ ከሚጠናው በላይ ነው (የሚታወቀው ከፍተኛ ተጨባጭ ገደብ: 2 ገጽ/ቀን) — ልትሞክረው ይቻላል፣ ግን ኋላ ጊዜውን ማራዘም ሊኖርብህ ይችላል። ይህን ማስታወሻ ሳናግድህ እናሳይሃለን፣ ውሳኔው የአንተ ነው።', 'fr': "Ce rythme est plus élevé que ce qu'un étudiant à temps plein mémorise habituellement (plafond réaliste le plus élevé connu : 2 pages/jour) — c'est bien de l'essayer, mais vous devrez peut-être prolonger la durée plus tard. Nous afficherons ce rappel sans vous en empêcher ; la décision vous appartient.", 'sw': 'Kasi hii ni ya juu kuliko ile ambayo hata mwanafunzi wa muda wote huhifadhi kwa kawaida (kiwango cha juu halisi kinachojulikana: kurasa 2/siku) — si vibaya kujaribu, lakini huenda ukahitaji kurefusha muda baadaye. Tutaonyesha ukumbusho huu bila kukuzuia; uamuzi ni wako.',
    'ur': 'یہ رفتار اس سے زیادہ ہے جو مکمل وقت کا طالب علم بھی عام طور پر حفظ کرتا ہے (معروف زیادہ سے زیادہ حقیقت پسندانہ حد: 2 صفحات/دن) — آزمانا ٹھیک ہے، لیکن بعد میں مدت بڑھانی پڑ سکتی ہے۔ ہم یہ یاددہانی آپ کو روکے بغیر دکھائیں گے؛ فیصلہ آپ کا ہے۔', 'tr': 'Bu hız, tam zamanlı bir öğrencinin bile genellikle ezberlediğinden daha yüksek (bilinen en yüksek gerçekçi tavan: günde 2 sayfa) — denemek sorun değil, ancak süreyi daha sonra uzatman gerekebilir. Bu hatırlatmayı seni durdurmadan göstereceğiz; karar sana ait.', 'id': 'Kecepatan ini lebih tinggi dari yang biasanya dihafal bahkan oleh siswa penuh waktu (batas realistis tertinggi yang diketahui: 2 halaman/hari) — tidak apa-apa untuk mencoba, tetapi Anda mungkin perlu memperpanjang durasinya nanti. Kami akan menampilkan pengingat ini tanpa menghentikan Anda; keputusan ada di tangan Anda.', 'bn': 'এই গতি এমনকি একজন পূর্ণ-সময়ের শিক্ষার্থী সাধারণত যা মুখস্থ করে তার চেয়ে বেশি (পরিচিত সর্বোচ্চ বাস্তবসম্মত সীমা: ২ পৃষ্ঠা/দিন) — চেষ্টা করা ঠিক আছে, তবে পরে সময়কাল বাড়াতে হতে পারে। আমরা আপনাকে না থামিয়ে এই অনুস্মারক দেখাব; সিদ্ধান্ত আপনার।', 'ha': 'Wannan gudu ya fi yadda koda ɗalibi na cikakken lokaci yakan haddace (mafi girman iyaka ta gaskiya da aka sani: shafuka 2/rana) — babu laifi a gwada, amma kana iya buƙatar tsawaita lokacin daga baya. Za mu nuna wannan tunatarwa ba tare da hana ka ba; shawarar naka ce.',
    'so': 'Xawaaraan waa ka sarreysa xitaa waxa uu ardaygu wakhtiga buuxa caadi ahaan xifdho (saqafka ugu sarreeya ee dhabta ah ee la yaqaan: 2 bog/maalin) — waa ok inaad isku dayto, laakiin waxaad u baahan kartaa inaad dheereyso muddada goor dambe. Waxaan ku tusi doonaa xasuusintan adiga oo aan lagaa hor joogsan; go\'aanku waa kaaga.', 'fa': 'این سرعت بیشتر از چیزی است که حتی یک دانشجوی تمام‌وقت معمولاً حفظ می‌کند (بالاترین سقف واقع‌بینانه شناخته‌شده: ۲ صفحه در روز) — امتحان کردنش اشکالی ندارد، اما ممکن است بعداً نیاز به تمدید مدت داشته باشی. این یادآوری را بدون جلوگیری از تو نشان می‌دهیم؛ تصمیم با توست.', 'ms': 'Kadar ini lebih tinggi daripada yang biasanya dihafaz oleh pelajar sepenuh masa (siling realistik tertinggi yang diketahui: 2 muka surat/hari) — tidak mengapa untuk mencuba, tetapi anda mungkin perlu melanjutkan tempoh kemudian. Kami akan memaparkan peringatan ini tanpa menghalang anda; keputusan di tangan anda.',
  },
  // 2026-08-18: `time_awareness_screen.dart` — caught via Ismail's own
  // screenshot showing this screen still 100% Arabic despite Amharic being
  // selected everywhere else. Note: `timeAwarenessTips`/the hadith text in
  // `time_awareness_content.dart` are left untouched in this pass — the
  // hadith is scripture (stays Arabic per the established rule), and the
  // tip cards are a larger separate content-translation job, not this
  // screen's own chrome.
  'hijri_year_hours_label': {
    'ar': 'ساعات سنتك الهجرية', 'en': 'Hours in your Hijri year', 'am': 'የሂጅሪ ዓመትህ ሰዓቶች', 'fr': 'Heures de votre année hégirienne', 'sw': 'Saa za Mwaka Wako wa Hijri',
    'ur': 'آپ کے ہجری سال کے گھنٹے', 'tr': 'Hicri Yılının Saatleri', 'id': 'Jam dalam Tahun Hijriah Anda', 'bn': 'আপনার হিজরি বছরের ঘণ্টা', 'ha': 'Sa\'o\'i na Shekararka ta Hijira',
    'so': 'Saacadaha Sanadkaaga Hijriga ah', 'fa': 'ساعات سال هجری تو', 'ms': 'Jam dalam Tahun Hijrah Anda',
  },
  'elapsed_approx_prefix': {
    'ar': 'مضى منها تقريبًا', 'en': 'About', 'am': 'ወደ', 'fr': 'Environ', 'sw': 'Takriban',
    'ur': 'تقریباً گزر چکے', 'tr': 'Yaklaşık', 'id': 'Sekitar', 'bn': 'প্রায়', 'ha': 'Kusan',
    'so': 'Ku dhawaad', 'fa': 'تقریباً', 'ms': 'Anggaran',
  },
  'remaining_and_prefix': {
    'ar': 'وبقي', 'en': 'has passed, and', 'am': 'አልፏል፣ እና', 'fr': 'sont passées, et il en reste', 'sw': 'zimepita, na zimebaki',
    'ur': 'گزر چکے، اور باقی ہیں', 'tr': 'geçti, ve kaldı', 'id': 'telah berlalu, dan tersisa', 'bn': 'কেটে গেছে, এবং বাকি আছে', 'ha': 'sun wuce, kuma sun rage',
    'so': 'ayaa dhaafay, waxaana haray', 'fa': 'گذشته، و باقی مانده', 'ms': 'telah berlalu, dan berbaki',
  },
  'hour_unit_label': {
    'ar': 'ساعة', 'en': 'hours', 'am': 'ሰዓት', 'fr': 'heures', 'sw': 'saa',
    'ur': 'گھنٹے', 'tr': 'saat', 'id': 'jam', 'bn': 'ঘণ্টা', 'ha': 'sa\'o\'i',
    'so': 'saacadood', 'fa': 'ساعت', 'ms': 'jam',
  },
  'today_your_day_label': {
    'ar': 'يومك اليوم', 'en': 'Your Day Today', 'am': 'ዛሬ ቀንህ', 'fr': "Votre journée d'aujourd'hui", 'sw': 'Siku Yako Leo',
    'ur': 'آپ کا آج کا دن', 'tr': 'Bugünün Günün', 'id': 'Hari Anda Hari Ini', 'bn': 'আজ আপনার দিন', 'ha': 'Ranarka na Yau',
    'so': 'Maalintaada Maanta', 'fa': 'روز امروز تو', 'ms': 'Hari Anda Hari Ini',
  },
  'time_honesty_desc': {
    'ar': 'بصدق مع نفسك — كم ساعة نمت، وكم ضاعت منك، وكم درست، وكم اشتغلت؟ النوم المعتاد لا يُحسب لك ولا عليك، وما زاد عنه يُحسب ضياعًا؛ وما لم تُسجّله يُحسب ضياعًا أيضًا — هذا لك أنت، لا أحد سيحاسبك عليه هنا سوى نفسك.', 'en': "Be honest with yourself — how many hours did you sleep, waste, study, and work? Normal sleep isn't counted for or against you, but anything beyond it counts as wasted; and whatever you don't log also counts as wasted — this is for you alone, no one holds you accountable here but yourself.", 'am': 'ከራስህ ጋር ታማኝ ሁን — ስንት ሰዓት ተኛህ፣ ስንት አባከንክ፣ ስንት ተማርክ፣ ስንት ሠራህ? መደበኛ እንቅልፍ ለወይም በላይህ አይቆጠርም፣ ከዚያ በላይ ግን እንደ ብክነት ይቆጠራል፤ ያልመዘገብከውም እንዲሁ ብክነት ይቆጠራል — ይህ ለራስህ ብቻ ነው፣ ከራስህ በስተቀር እዚህ ማንም አይቆጣጠርህም።', 'fr': "Soyez honnête avec vous-même — combien d'heures avez-vous dormi, perdu, étudié, travaillé ? Le sommeil normal ne compte ni pour ni contre vous, mais tout excès compte comme perdu ; et ce que vous n'enregistrez pas compte aussi comme perdu — ceci est pour vous seul, personne ne vous en tient compte ici sauf vous-même.", 'sw': 'Kuwa mkweli na nafsi yako — ni saa ngapi ulilala, zilipotea, ulisoma, ulifanya kazi? Usingizi wa kawaida haukuhesabiwi kwako wala dhidi yako, lakini kilichozidi kinahesabiwa kama kilichopotea; na usichokirekodi pia kinahesabiwa kama kilichopotea — hii ni kwa ajili yako pekee, hakuna atakayekuhesabu isipokuwa wewe mwenyewe.',
    'ur': 'اپنے آپ سے سچے رہیں — آپ نے کتنے گھنٹے سوئے، ضائع کیے، پڑھا، اور کام کیا؟ معمول کی نیند نہ آپ کے حق میں شمار ہوتی ہے نہ خلاف، لیکن اس سے زیادہ ضائع شمار ہوتی ہے؛ اور جو آپ درج نہیں کرتے وہ بھی ضائع شمار ہوتا ہے — یہ صرف آپ کے لیے ہے، یہاں آپ کے سوا کوئی آپ کا حساب نہیں لے گا۔', 'tr': 'Kendine karşı dürüst ol — kaç saat uyudun, kaybettin, çalıştın, iş yaptın? Normal uyku lehine ya da aleyhine sayılmaz, ama fazlası kayıp sayılır; kaydetmediğin de kayıp sayılır — bu yalnızca senin için, burada seni kendinden başka kimse hesaba çekmez.', 'id': 'Jujurlah pada diri sendiri — berapa jam Anda tidur, terbuang, belajar, dan bekerja? Tidur normal tidak dihitung untuk atau melawan Anda, tetapi kelebihannya dihitung sebagai terbuang; dan yang tidak Anda catat juga dihitung terbuang — ini untuk Anda sendiri, tidak ada yang akan menghitung Anda di sini selain diri Anda sendiri.', 'bn': 'নিজের সাথে সৎ থাকুন — আপনি কত ঘণ্টা ঘুমিয়েছেন, নষ্ট করেছেন, পড়েছেন, কাজ করেছেন? স্বাভাবিক ঘুম আপনার পক্ষে বা বিপক্ষে গণনা হয় না, তবে তার চেয়ে বেশি অপচয় হিসেবে গণনা হয়; এবং যা আপনি লিপিবদ্ধ করেন না তাও অপচয় হিসেবে গণনা হয় — এটি শুধুই আপনার জন্য, এখানে আপনি ছাড়া কেউ আপনার হিসাব নেবে না।', 'ha': 'Ka zama gaskiya da kanka — sa\'o\'i nawa ka yi barci, suka ɓace, ka yi karatu, ka yi aiki? Barci na yau da kullun ba a ƙidaya maka ko akanka ba, amma abin da ya wuce hakan ana ƙidaya shi a matsayin ɓarna; abin da ba ka rubuta ba shi ma ana ƙidaya shi a matsayin ɓarna — wannan naka ne kawai, babu wanda zai tambaye ka a nan sai kanka.',
    'so': 'La daacad ahaw naftaada — imisa saacadood baad seexatay, ku lumisay, wax baratay, shaqaysay? Hurdada caadiga ah lagaaguma xisaabiyo dhinac wanaagsan iyo mid xun midna, laakiin waxa ka badan waxaa loo xisaabiyaa lumis; waxaanad diiwaan gelin sidoo kale waxaa loo xisaabiyaa lumis — tani waa adiga kaliya, cidna kuma xisaabin doonto halkan naftaada mooyaane.', 'fa': 'با خودت صادق باش — چند ساعت خوابیدی، هدر دادی، درس خواندی، کار کردی؟ خواب معمولی نه به نفعت حساب می‌شود نه به ضررت، اما اضافه بر آن هدررفت حساب می‌شود؛ و آنچه ثبت نکنی هم هدررفت حساب می‌شود — این فقط برای خودت است، اینجا کسی جز خودت از تو حساب نمی‌خواهد.', 'ms': 'Jujurlah dengan diri sendiri — berapa jam anda tidur, terbuang, belajar, dan bekerja? Tidur biasa tidak dikira untuk atau menentang anda, tetapi lebihan daripadanya dikira sebagai terbuang; dan apa yang tidak anda rekodkan juga dikira terbuang — ini untuk anda sahaja, tiada sesiapa akan mengambil kira di sini selain diri anda sendiri.',
  },
  'how_much_slept': {
    'ar': 'كم نمت؟', 'en': 'How much did you sleep?', 'am': 'ስንት ተኛህ?', 'fr': 'Combien avez-vous dormi ?', 'sw': 'Ulilala saa ngapi?',
    'ur': 'آپ کتنی دیر سوئے؟', 'tr': 'Ne kadar uyudun?', 'id': 'Berapa lama Anda tidur?', 'bn': 'আপনি কতটা ঘুমিয়েছেন?', 'ha': 'Nawa ka yi barci?',
    'so': 'Immisa baad seexatay?', 'fa': 'چقدر خوابیدی؟', 'ms': 'Berapa lama anda tidur?',
  },
  'how_much_wasted': {
    'ar': 'كم ضاع منك؟', 'en': 'How much did you waste?', 'am': 'ስንት አባከንክ?', 'fr': 'Combien avez-vous perdu ?', 'sw': 'Ni saa ngapi zilipotea kwako?',
    'ur': 'کتنا وقت ضائع ہوا؟', 'tr': 'Ne kadar kaybettin?', 'id': 'Berapa banyak yang terbuang?', 'bn': 'কতটা নষ্ট হয়েছে?', 'ha': 'Nawa ya ɓace maka?',
    'so': 'Immisa kaa lumay?', 'fa': 'چقدر از تو هدر رفت؟', 'ms': 'Berapa banyak yang terbuang?',
  },
  'how_much_studied': {
    'ar': 'كم درست؟', 'en': 'How much did you study?', 'am': 'ስንት ተማርክ?', 'fr': 'Combien avez-vous étudié ?', 'sw': 'Ulisoma saa ngapi?',
    'ur': 'کتنا مطالعہ کیا؟', 'tr': 'Ne kadar çalıştın?', 'id': 'Berapa lama Anda belajar?', 'bn': 'কতটা পড়াশোনা করেছেন?', 'ha': 'Nawa ka yi karatu?',
    'so': 'Immisa baad wax barattay?', 'fa': 'چقدر درس خواندی؟', 'ms': 'Berapa lama anda belajar?',
  },
  'how_much_worked': {
    'ar': 'كم اشتغلت؟', 'en': 'How much did you work?', 'am': 'ስንት ሠራህ?', 'fr': 'Combien avez-vous travaillé ?', 'sw': 'Ulifanya kazi saa ngapi?',
    'ur': 'کتنا کام کیا؟', 'tr': 'Ne kadar çalıştın (iş)?', 'id': 'Berapa lama Anda bekerja?', 'bn': 'কতটা কাজ করেছেন?', 'ha': 'Nawa ka yi aiki?',
    'so': 'Immisa baad shaqaysay?', 'fa': 'چقدر کار کردی؟', 'ms': 'Berapa lama anda bekerja?',
  },
  'benefited_label': {
    'ar': 'استفدت', 'en': 'Benefited', 'am': 'ተጠቅመሃል', 'fr': 'Profité', 'sw': 'Ulinufaika',
    'ur': 'فائدہ اٹھایا', 'tr': 'Yararlandın', 'id': 'Bermanfaat', 'bn': 'উপকৃত হয়েছেন', 'ha': 'Ka amfana',
    'so': 'Faa\'iidaystay', 'fa': 'بهره بردی', 'ms': 'Mendapat manfaat',
  },
  'wasted_label': {
    'ar': 'ضاع', 'en': 'Wasted', 'am': 'ባክኗል', 'fr': 'Perdu', 'sw': 'Ilipotea',
    'ur': 'ضائع ہوا', 'tr': 'Kayboldu', 'id': 'Terbuang', 'bn': 'নষ্ট হয়েছে', 'ha': 'Ya ɓace',
    'so': 'Way lumtay', 'fa': 'هدر رفت', 'ms': 'Terbuang',
  },
  'of_which_prefix': {
    'ar': 'منها', 'en': 'of which', 'am': 'ከዚህ ውስጥ', 'fr': 'dont', 'sw': 'ambapo',
    'ur': 'جن میں سے', 'tr': 'bunun', 'id': 'di mana', 'bn': 'যার মধ্যে', 'ha': 'daga cikinsu',
    'so': 'oo ka mid ah', 'fa': 'که از آن', 'ms': 'yang mana',
  },
  'unaccounted_hours_suffix': {
    'ar': 'ساعة لم تُسجَّل بعد', 'en': 'hours not yet logged', 'am': 'ሰዓት እስካሁን አልተመዘገበም', 'fr': 'heures pas encore enregistrées', 'sw': 'saa ambazo bado hazijarekodiwa',
    'ur': 'گھنٹے ابھی تک درج نہیں ہوئے', 'tr': 'saat henüz kaydedilmedi', 'id': 'jam belum dicatat', 'bn': 'ঘণ্টা এখনও লগ করা হয়নি', 'ha': 'sa\'o\'i da ba a rubuta ba tukuna',
    'so': 'saacadood aan weli la diiwaangelin', 'fa': 'ساعت هنوز ثبت نشده', 'ms': 'jam belum direkodkan',
  },
  'excess_sleep_over_label': {
    'ar': 'ساعة نوم زائد عن', 'en': 'hours of excess sleep beyond', 'am': 'ሰዓት ትርፍ እንቅልፍ ከ', 'fr': "heures de sommeil excédentaire au-delà de", 'sw': 'saa za usingizi wa ziada zaidi ya',
    'ur': 'اضافی نیند کے گھنٹے اس سے زیادہ', 'tr': 'fazladan uyku saati, şundan fazla:', 'id': 'jam tidur berlebih melebihi', 'bn': 'অতিরিক্ত ঘুমের ঘণ্টা এর বেশি', 'ha': 'sa\'o\'i na barci fiye da',
    'so': 'saacadood hurdo dheeraad ah oo ka badan', 'fa': 'ساعت خواب اضافی بیش از', 'ms': 'jam tidur berlebihan melebihi',
  },
  'hours_plural_label': {
    'ar': 'ساعات', 'en': 'hours', 'am': 'ሰዓቶች', 'fr': 'heures', 'sw': 'saa',
    'ur': 'گھنٹے', 'tr': 'saat', 'id': 'jam', 'bn': 'ঘণ্টা', 'ha': 'sa\'o\'i',
    'so': 'saacadood', 'fa': 'ساعت', 'ms': 'jam',
  },
  'time_note_hint': {
    'ar': 'ملاحظة (اختياري): بم استفدت؟ وأين ضاع وقتك؟', 'en': 'Note (optional): What did you benefit from? Where did your time go?', 'am': 'ማስታወሻ (አማራጭ): ምን ተጠቀምክ? ጊዜህ የት ሄደ?', 'fr': "Note (facultatif) : Qu'avez-vous tiré profit ? Où est passé votre temps ?", 'sw': 'Kumbuka (si lazima): Ulinufaika na nini? Muda wako ulienda wapi?',
    'ur': 'نوٹ (اختیاری): آپ نے کس چیز سے فائدہ اٹھایا؟ آپ کا وقت کہاں ضائع ہوا؟', 'tr': 'Not (isteğe bağlı): Neden yararlandın? Vaktin nereye gitti?', 'id': 'Catatan (opsional): Apa manfaat yang Anda dapat? Ke mana waktu Anda pergi?', 'bn': 'নোট (ঐচ্ছিক): আপনি কী থেকে উপকৃত হয়েছেন? আপনার সময় কোথায় গেল?', 'ha': 'Bayani (na son rai): Me ka amfana da shi? Ina lokacinka ya tafi?',
    'so': 'Xusuus (ikhtiyaari): Maxaad ka faa\'iidaysatay? Xaggee waqtigaagu tegey?', 'fa': 'یادداشت (اختیاری): از چه بهره بردی؟ وقتت کجا رفت؟', 'ms': 'Nota (pilihan): Apa manfaat yang anda perolehi? Ke mana masa anda hilang?',
  },
  'how_to_benefit_hours_title': {
    'ar': 'كيف تستفيد من كل ساعة؟', 'en': 'How to benefit from every hour?', 'am': 'ከእያንዳንዷ ሰዓት እንዴት ትጠቀማለህ?', 'fr': 'Comment tirer profit de chaque heure ?', 'sw': 'Jinsi ya kunufaika na kila saa?',
    'ur': 'ہر گھنٹے سے کیسے فائدہ اٹھائیں؟', 'tr': 'Her saatten nasıl yararlanılır?', 'id': 'Bagaimana memanfaatkan setiap jam?', 'bn': 'প্রতিটি ঘণ্টা থেকে কীভাবে উপকৃত হবেন?', 'ha': 'Yadda za a amfana da kowace sa\'a?',
    'so': 'Sideed uga faa\'iidaysan kartaa saacad kasta?', 'fa': 'چگونه از هر ساعت بهره ببریم؟', 'ms': 'Bagaimana untuk memanfaatkan setiap jam?',
  },
  'recent_days_label': {
    'ar': 'آخر أيامك (ساعات مُستفادة)', 'en': 'Your recent days (hours benefited)', 'am': 'የቅርብ ቀናትህ (የተጠቀሙ ሰዓቶች)', 'fr': 'Vos derniers jours (heures profitées)', 'sw': 'Siku zako za hivi karibuni (saa zilizonufaika)',
    'ur': 'آپ کے حالیہ دن (فائدہ مند گھنٹے)', 'tr': 'Son günlerin (yararlanılan saatler)', 'id': 'Hari-hari terbaru Anda (jam bermanfaat)', 'bn': 'আপনার সাম্প্রতিক দিনগুলো (উপকৃত ঘণ্টা)', 'ha': 'Kwanakinka na kwanan nan (sa\'o\'in da aka amfana)',
    'so': 'Maalmahaagii dhawaa (saacadaha la faa\'iidaystay)', 'fa': 'روزهای اخیرت (ساعات مفید)', 'ms': 'Hari-hari terkini anda (jam bermanfaat)',
  },
  'time_saved_confirmation': {
    'ar': 'بارك الله في وقتك — تم تسجيل يومك، جزاك الله خيرًا على صدقك مع نفسك', 'en': 'May Allah bless your time — your day has been logged, may Allah reward you for your honesty with yourself', 'am': 'አላህ ጊዜህን ይባርክ — ቀንህ ተመዝግቧል፣ ከራስህ ጋር ላለው ታማኝነትህ አላህ ይክፈልህ', 'fr': "Qu'Allah bénisse votre temps — votre journée a été enregistrée, qu'Allah vous récompense pour votre honnêteté envers vous-même", 'sw': 'Mwenyezi Mungu abariki muda wako — siku yako imerekodiwa, Mwenyezi Mungu akulipe kwa uaminifu wako na nafsi yako',
    'ur': 'اللہ آپ کے وقت میں برکت دے — آپ کا دن درج ہو گیا، اللہ آپ کو اپنے آپ سے سچائی پر جزائے خیر دے', 'tr': 'Allah vaktini mübarek kılsın — günün kaydedildi, kendine karşı dürüstlüğün için Allah seni mükafatlandırsın', 'id': 'Semoga Allah memberkati waktu Anda — hari Anda telah dicatat, semoga Allah membalas kejujuran Anda pada diri sendiri', 'bn': 'আল্লাহ আপনার সময়ে বরকত দিন — আপনার দিন লগ করা হয়েছে, নিজের প্রতি সততার জন্য আল্লাহ আপনাকে প্রতিদান দিন', 'ha': 'Allah Ya albarkaci lokacinka — an rubuta ranarka, Allah Ya saka maka da gaskiyarka da kanka',
    'so': 'Ilaahay ha ku barakeeyo waqtigaaga — maalintaadu waa la diiwaangeliyay, Ilaahay ha kuu abaal mariyo run ka ahaanshahaaga naftaada', 'fa': 'خدا وقتت را برکت دهد — روزت ثبت شد، خدا صداقتت با خودت را پاداش دهد', 'ms': 'Semoga Allah memberkati masa anda — hari anda telah direkodkan, semoga Allah membalas kejujuran anda terhadap diri sendiri',
  },
  'retry_action': {
    'ar': 'إعادة المحاولة', 'en': 'Retry', 'am': 'እንደገና ሞክር', 'fr': 'Réessayer', 'sw': 'Jaribu Tena',
    'ur': 'دوبارہ کوشش کریں', 'tr': 'Tekrar Dene', 'id': 'Coba Lagi', 'bn': 'আবার চেষ্টা করুন', 'ha': 'Sake Gwadawa',
    'so': 'Isku Day Mar Kale', 'fa': 'تلاش دوباره', 'ms': 'Cuba Lagi',
  },
  'cancel_action': {
    'ar': 'إلغاء', 'en': 'Cancel', 'am': 'ሰርዝ', 'fr': 'Annuler', 'sw': 'Ghairi',
    'ur': 'منسوخ کریں', 'tr': 'İptal', 'id': 'Batal', 'bn': 'বাতিল', 'ha': 'Soke',
    'so': 'Jooji', 'fa': 'لغو', 'ms': 'Batal',
  },
  'go_action': {
    'ar': 'اذهب', 'en': 'Go', 'am': 'ሂድ', 'fr': 'Aller', 'sw': 'Nenda',
    'ur': 'جائیں', 'tr': 'Git', 'id': 'Pergi', 'bn': 'যান', 'ha': 'Tafi',
    'so': 'Aad', 'fa': 'برو', 'ms': 'Pergi',
  },
  'previous_page_action': {
    'ar': 'الصفحة السابقة', 'en': 'Previous Page', 'am': 'ቀዳሚ ገጽ', 'fr': 'Page précédente', 'sw': 'Ukurasa Uliopita',
    'ur': 'پچھلا صفحہ', 'tr': 'Önceki Sayfa', 'id': 'Halaman Sebelumnya', 'bn': 'পূর্ববর্তী পৃষ্ঠা', 'ha': 'Shafin da Ya Gabata',
    'so': 'Bogga Hore', 'fa': 'صفحه قبلی', 'ms': 'Halaman Sebelumnya',
  },
  'next_page_action': {
    'ar': 'الصفحة التالية', 'en': 'Next Page', 'am': 'ቀጣይ ገጽ', 'fr': 'Page suivante', 'sw': 'Ukurasa Unaofuata',
    'ur': 'اگلا صفحہ', 'tr': 'Sonraki Sayfa', 'id': 'Halaman Berikutnya', 'bn': 'পরবর্তী পৃষ্ঠা', 'ha': 'Shafi na Gaba',
    'so': 'Bogga Xiga', 'fa': 'صفحه بعدی', 'ms': 'Halaman Seterusnya',
  },
  'turath_library_title': {
    'ar': 'المكتبة التراثية', 'en': 'Heritage Library', 'am': 'የቅርስ ቤተ መጻሕፍት', 'fr': 'Bibliothèque du patrimoine', 'sw': 'Maktaba ya Urithi',
    'ur': 'ترکہ لائبریری', 'tr': 'Miras Kütüphanesi', 'id': 'Perpustakaan Warisan', 'bn': 'ঐতিহ্য গ্রন্থাগার', 'ha': 'Laburaren Gado',
    'so': 'Maktabadda Dhaqanka', 'fa': 'کتابخانه میراث', 'ms': 'Perpustakaan Warisan',
  },
  'turath_search_hint': {
    'ar': 'ابحث في آلاف الكتب...', 'en': 'Search thousands of books...', 'am': 'በሺዎች የሚቆጠሩ መጻሕፍትን ፈልግ...', 'fr': 'Recherchez parmi des milliers de livres...',
    'sw': 'Tafuta kati ya vitabu maelfu...', 'ur': 'ہزاروں کتابوں میں تلاش کریں...', 'tr': 'Binlerce kitapta ara...',
    'id': 'Cari di ribuan buku...', 'bn': 'হাজার হাজার বই অনুসন্ধান করুন...', 'ha': 'Bincika cikin dubban littattafai...',
    'so': 'Ka raadi kumanaan buug...', 'fa': 'جستجو در هزاران کتاب...', 'ms': 'Cari beribu-ribu buku...',
  },
  'turath_search_prompt': {
    'ar': 'اكتب كلمة للبحث في المكتبة التراثية', 'en': 'Type a word to search the heritage library', 'am': 'የቅርስ ቤተ መጻሕፍትን ለመፈለግ ቃል ይጻፉ',
    'fr': "Tapez un mot pour rechercher dans la bibliothèque du patrimoine", 'sw': 'Andika neno kutafuta maktaba ya urithi',
    'ur': 'ترکہ لائبریری میں تلاش کے لیے ایک لفظ لکھیں', 'tr': 'Miras kütüphanesinde aramak için bir kelime yazın',
    'id': 'Ketik kata untuk mencari di perpustakaan warisan', 'bn': 'ঐতিহ্য গ্রন্থাগারে অনুসন্ধান করতে একটি শব্দ টাইপ করুন',
    'ha': 'Rubuta kalma don bincike a laburaren gado', 'so': 'Qor eray si aad u raadiso maktabadda dhaqanka',
    'fa': 'برای جستجو در کتابخانه میراث کلمه‌ای تایپ کنید', 'ms': 'Taip perkataan untuk mencari perpustakaan warisan',
  },
  'turath_no_results': {
    'ar': 'لم يعثر على نتائج', 'en': 'No results found', 'am': 'ምንም ውጤት አልተገኘም', 'fr': 'Aucun résultat trouvé', 'sw': 'Hakuna matokeo yaliyopatikana',
    'ur': 'کوئی نتیجہ نہیں ملا', 'tr': 'Sonuç bulunamadı', 'id': 'Tidak ada hasil ditemukan', 'bn': 'কোনো ফলাফল পাওয়া যায়নি', 'ha': 'Ba a sami sakamako ba',
    'so': 'Natiijo lama helin', 'fa': 'نتیجه‌ای یافت نشد', 'ms': 'Tiada hasil dijumpai',
  },
  'turath_network_error': {
    'ar': 'تعذر تحميل المكتبة، تحقق من اتصال الإنترنت', 'en': 'Could not load the library, check your internet connection',
    'am': 'ቤተ መጻሕፍትን መጫን አልተቻለም፣ የበይነመረብ ግንኙነትዎን ያረጋግጡ', 'fr': "Impossible de charger la bibliothèque, vérifiez votre connexion internet",
    'sw': 'Imeshindwa kupakia maktaba, angalia muunganisho wako wa intaneti', 'ur': 'لائبریری لوڈ نہیں ہو سکی، انٹرنیٹ کنکشن چیک کریں',
    'tr': 'Kütüphane yüklenemedi, internet bağlantınızı kontrol edin', 'id': 'Tidak dapat memuat perpustakaan, periksa koneksi internet Anda',
    'bn': 'লাইব্রেরি লোড করা যায়নি, ইন্টারনেট সংযোগ পরীক্ষা করুন', 'ha': 'An kasa loda laburare, duba haɗin intanet ɗinka',
    'so': 'Maktabadda lama soo rari karin, hubi xiriirka internetka', 'fa': 'بارگذاری کتابخانه ممکن نشد، اتصال اینترنت را بررسی کنید',
    'ms': 'Tidak dapat memuatkan perpustakaan, semak sambungan internet anda',
  },
  'turath_page_load_error': {
    'ar': 'تعذر تحميل الصفحة، تحقق من اتصال الإنترنت', 'en': 'Could not load the page, check your internet connection',
    'am': 'ገጹን መጫን አልተቻለም፣ የበይነመረብ ግንኙነትዎን ያረጋግጡ', 'fr': "Impossible de charger la page, vérifiez votre connexion internet",
    'sw': 'Imeshindwa kupakia ukurasa, angalia muunganisho wako wa intaneti', 'ur': 'صفحہ لوڈ نہیں ہو سکا، انٹرنیٹ کنکشن چیک کریں',
    'tr': 'Sayfa yüklenemedi, internet bağlantınızı kontrol edin', 'id': 'Tidak dapat memuat halaman, periksa koneksi internet Anda',
    'bn': 'পৃষ্ঠা লোড করা যায়নি, ইন্টারনেট সংযোগ পরীক্ষা করুন', 'ha': 'An kasa loda shafi, duba haɗin intanet ɗinka',
    'so': 'Bogga lama soo rari karin, hubi xiriirka internetka', 'fa': 'بارگذاری صفحه ممکن نشد، اتصال اینترنت را بررسی کنید',
    'ms': 'Tidak dapat memuatkan halaman, semak sambungan internet anda',
  },
  'turath_go_to_page': {
    'ar': 'اذهب إلى صفحة', 'en': 'Go to page', 'am': 'ወደ ገጽ ሂድ', 'fr': 'Aller à la page', 'sw': 'Nenda kwenye ukurasa',
    'ur': 'صفحے پر جائیں', 'tr': 'Sayfaya git', 'id': 'Pergi ke halaman', 'bn': 'পৃষ্ঠায় যান', 'ha': 'Tafi shafi',
    'so': 'Aad bogga', 'fa': 'برو به صفحه', 'ms': 'Pergi ke halaman',
  },
  'turath_start_reading_action': {
    'ar': 'بدء القراءة', 'en': 'Start Reading', 'am': 'ማንበብ ጀምር', 'fr': 'Commencer la lecture', 'sw': 'Anza Kusoma',
    'ur': 'پڑھنا شروع کریں', 'tr': 'Okumaya Başla', 'id': 'Mulai Membaca', 'bn': 'পড়া শুরু করুন', 'ha': 'Fara Karatu',
    'so': 'Bilow Akhrinta', 'fa': 'شروع مطالعه', 'ms': 'Mula Membaca',
  },
  'turath_index_action': {
    'ar': 'الفهرس', 'en': 'Table of Contents', 'am': 'ማውጫ', 'fr': 'Table des matières', 'sw': 'Yaliyomo',
    'ur': 'فہرست', 'tr': 'İçindekiler', 'id': 'Daftar Isi', 'bn': 'সূচিপত্র', 'ha': 'Fihirisa',
    'so': 'Tusmada', 'fa': 'فهرست مطالب', 'ms': 'Kandungan',
  },
  'turath_search_in_book_action': {
    'ar': 'بحث داخل الكتاب', 'en': 'Search Inside This Book', 'am': 'በዚህ መጽሐፍ ውስጥ ፈልግ', 'fr': 'Rechercher dans ce livre', 'sw': 'Tafuta Ndani ya Kitabu Hiki',
    'ur': 'اس کتاب کے اندر تلاش کریں', 'tr': 'Bu Kitapta Ara', 'id': 'Cari di Dalam Buku Ini', 'bn': 'এই বইয়ের মধ্যে অনুসন্ধান করুন', 'ha': 'Bincika Cikin Wannan Littafi',
    'so': 'Ka raadi buugan gudihiisa', 'fa': 'جستجو در این کتاب', 'ms': 'Cari Dalam Buku Ini',
  },
  'turath_favorites_title': {
    'ar': 'المفضلة', 'en': 'Favorites', 'am': 'ተወዳጆች', 'fr': 'Favoris', 'sw': 'Vipendwa',
    'ur': 'پسندیدہ', 'tr': 'Favoriler', 'id': 'Favorit', 'bn': 'পছন্দসমূহ', 'ha': 'Abubuwan So',
    'so': 'Kuwa la jecel yahay', 'fa': 'موردعلاقه‌ها', 'ms': 'Kegemaran',
  },
  'turath_recently_read_title': {
    'ar': 'قرأت مؤخرًا', 'en': 'Recently Read', 'am': 'በቅርቡ የተነበቡ', 'fr': 'Lus récemment', 'sw': 'Iliyosomwa Hivi Karibuni',
    'ur': 'حال ہی میں پڑھی گئیں', 'tr': 'Son Okunanlar', 'id': 'Baru Dibaca', 'bn': 'সম্প্রতি পঠিত', 'ha': 'Karatun Kwanan Nan',
    'so': 'Dhawaan la akhriyay', 'fa': 'اخیراً خوانده‌شده', 'ms': 'Baru Dibaca',
  },
  'turath_notes_title': {
    'ar': 'ملاحظاتي', 'en': 'My Notes', 'am': 'ማስታወሻዎቼ', 'fr': 'Mes notes', 'sw': 'Vidokezo Vyangu',
    'ur': 'میرے نوٹس', 'tr': 'Notlarım', 'id': 'Catatan Saya', 'bn': 'আমার নোটসমূহ', 'ha': 'Bayanaina',
    'so': 'Xusuus-qorkayga', 'fa': 'یادداشت‌های من', 'ms': 'Nota Saya',
  },
  'turath_add_note_action': {
    'ar': 'أضف ملاحظة', 'en': 'Add Note', 'am': 'ማስታወሻ ጨምር', 'fr': 'Ajouter une note', 'sw': 'Ongeza Kidokezo',
    'ur': 'نوٹ شامل کریں', 'tr': 'Not Ekle', 'id': 'Tambah Catatan', 'bn': 'নোট যোগ করুন', 'ha': 'Ƙara Bayani',
    'so': 'Ku dar Xusuus-qor', 'fa': 'افزودن یادداشت', 'ms': 'Tambah Nota',
  },
  'turath_note_hint': {
    'ar': 'اكتب ملاحظتك هنا...', 'en': 'Write your note here...', 'am': 'ማስታወሻዎን እዚህ ይጻፉ...', 'fr': 'Écrivez votre note ici...', 'sw': 'Andika kidokezo chako hapa...',
    'ur': 'اپنا نوٹ یہاں لکھیں...', 'tr': 'Notunuzu buraya yazın...', 'id': 'Tulis catatan Anda di sini...', 'bn': 'আপনার নোট এখানে লিখুন...', 'ha': 'Rubuta bayaninka a nan...',
    'so': 'Halkan ku qor xusuus-qorkaaga...', 'fa': 'یادداشت خود را اینجا بنویسید...', 'ms': 'Tulis nota anda di sini...',
  },
  'turath_no_favorites_empty': {
    'ar': 'لا توجد كتب أو صفحات مفضّلة بعد', 'en': 'No favorite books or pages yet', 'am': 'እስካሁን ተወዳጅ መጻሕፍት ወይም ገጾች የሉም',
    'fr': "Aucun livre ou page favori pour l'instant", 'sw': 'Hakuna vitabu au kurasa vipendwa bado', 'ur': 'ابھی تک کوئی پسندیدہ کتاب یا صفحہ نہیں',
    'tr': 'Henüz favori kitap veya sayfa yok', 'id': 'Belum ada buku atau halaman favorit', 'bn': 'এখনও কোনো প্রিয় বই বা পৃষ্ঠা নেই',
    'ha': 'Babu littattafai ko shafuka da aka fi so tukuna', 'so': 'Wali ma jiraan buugag ama bogag la jecel yahay',
    'fa': 'هنوز کتاب یا صفحه موردعلاقه‌ای نیست', 'ms': 'Tiada buku atau halaman kegemaran lagi',
  },
  'turath_no_notes_empty': {
    'ar': 'لا توجد ملاحظات بعد', 'en': 'No notes yet', 'am': 'እስካሁን ማስታወሻዎች የሉም', 'fr': "Aucune note pour l'instant", 'sw': 'Hakuna vidokezo bado',
    'ur': 'ابھی تک کوئی نوٹ نہیں', 'tr': 'Henüz not yok', 'id': 'Belum ada catatan', 'bn': 'এখনও কোনো নোট নেই', 'ha': 'Babu bayanai tukuna',
    'so': 'Wali xusuus-qor lama haysto', 'fa': 'هنوز یادداشتی نیست', 'ms': 'Tiada nota lagi',
  },
  'turath_no_recent_empty': {
    'ar': 'لم تبدأ قراءة أي كتاب بعد', 'en': "You haven't started reading any book yet", 'am': 'እስካሁን ማንኛውንም መጽሐፍ ማንበብ አልጀመሩም',
    'fr': "Vous n'avez encore commencé aucun livre", 'sw': 'Bado hujaanza kusoma kitabu chochote', 'ur': 'ابھی تک آپ نے کوئی کتاب پڑھنا شروع نہیں کی',
    'tr': 'Henüz hiçbir kitap okumaya başlamadınız', 'id': 'Anda belum mulai membaca buku apa pun', 'bn': 'আপনি এখনও কোনো বই পড়া শুরু করেননি',
    'ha': 'Ba ka fara karanta wani littafi ba tukuna', 'so': 'Wali ma bilaabin akhrinta buug', 'fa': 'هنوز مطالعه هیچ کتابی را شروع نکرده‌اید',
    'ms': 'Anda belum mula membaca mana-mana buku',
  },
  'turath_last_read_label': {
    'ar': 'آخر قراءة: صفحة', 'en': 'Last read: page', 'am': 'መጨረሻ የተነበበ: ገጽ', 'fr': 'Dernière lecture : page', 'sw': 'Iliyosomwa mwisho: ukurasa',
    'ur': 'آخری مطالعہ: صفحہ', 'tr': 'Son okunan: sayfa', 'id': 'Terakhir dibaca: halaman', 'bn': 'সর্বশেষ পঠিত: পৃষ্ঠা', 'ha': 'Karatun ƙarshe: shafi',
    'so': 'Akhriskii ugu dambeeyay: bogga', 'fa': 'آخرین مطالعه: صفحه', 'ms': 'Terakhir dibaca: halaman',
  },
  'turath_about_book_label': {
    'ar': 'عن الكتاب', 'en': 'About This Book', 'am': 'ስለ መጽሐፉ', 'fr': 'À propos de ce livre', 'sw': 'Kuhusu Kitabu Hiki',
    'ur': 'اس کتاب کے بارے میں', 'tr': 'Bu Kitap Hakkında', 'id': 'Tentang Buku Ini', 'bn': 'এই বই সম্পর্কে', 'ha': 'Game da Wannan Littafi',
    'so': 'Ku saabsan buugan', 'fa': 'درباره این کتاب', 'ms': 'Tentang Buku Ini',
  },
  'turath_source_attribution': {
    'ar': 'المحتوى من مكتبة turath.io', 'en': 'Content from the turath.io library', 'am': 'ይዘት ከ turath.io ቤተ መጻሕፍት', 'fr': 'Contenu de la bibliothèque turath.io',
    'sw': 'Maudhui kutoka maktaba ya turath.io', 'ur': 'مواد turath.io لائبریری سے', 'tr': 'İçerik turath.io kütüphanesinden', 'id': 'Konten dari perpustakaan turath.io',
    'bn': 'বিষয়বস্তু turath.io লাইব্রেরি থেকে', 'ha': 'Abin ciki daga laburaren turath.io', 'so': 'Content-ka wuxuu ka yimid maktabadda turath.io',
    'fa': 'محتوا از کتابخانه turath.io', 'ms': 'Kandungan daripada perpustakaan turath.io',
  },
  'turath_topics_title': {
    'ar': 'تصفح حسب الموضوع', 'en': 'Browse by Topic', 'am': 'በርዕስ አስስ', 'fr': 'Parcourir par sujet', 'sw': 'Vinjari kwa Mada',
    'ur': 'موضوع کے لحاظ سے دیکھیں', 'tr': 'Konuya Göre Gözat', 'id': 'Jelajahi Berdasarkan Topik', 'bn': 'বিষয় অনুযায়ী ব্রাউজ করুন', 'ha': 'Bincika ta Batun',
    'so': 'Ku baadh Mawduuca', 'fa': 'مرور بر اساس موضوع', 'ms': 'Layari Mengikut Topik',
  },
  'turath_categories_title': {
    'ar': 'الأقسام', 'en': 'Categories', 'am': 'ምድቦች', 'fr': 'Catégories', 'sw': 'Aina',
    'ur': 'اقسام', 'tr': 'Kategoriler', 'id': 'Kategori', 'bn': 'বিভাগসমূহ', 'ha': 'Rukuni',
    'so': 'Qaybaha', 'fa': 'دسته‌بندی‌ها', 'ms': 'Kategori',
  },
  'turath_categories_subtitle': {
    'ar': 'تصفح المكتبة عبر أقسامها الأربعين كاملة', 'en': 'Browse the library through all 40 categories', 'am': 'ቤተ መጻሕፍትን በ40ዱ ምድቦች ሙሉ ያስሱ',
    'fr': "Parcourez la bibliothèque à travers ses 40 catégories complètes", 'sw': 'Vinjari maktaba kupitia aina zote 40', 'ur': 'لائبریری کو اس کے چالیس اقسام کے ذریعے دیکھیں',
    'tr': 'Kütüphaneyi 40 kategorinin tamamı üzerinden gözden geçirin', 'id': 'Jelajahi perpustakaan melalui 40 kategori lengkap', 'bn': 'সম্পূর্ণ ৪০টি বিভাগের মাধ্যমে লাইব্রেরি ব্রাউজ করুন',
    'ha': 'Bincika laburare ta cikin dukkan rukuni 40', 'so': 'Ka baadh maktabadda 40-ka qaybood oo dhan', 'fa': 'کتابخانه را از طریق هر ۴۰ دسته‌بندی مرور کنید',
    'ms': 'Layari perpustakaan melalui kesemua 40 kategori',
  },
  'turath_categories_search_hint': {
    'ar': 'ابحث في الأقسام...', 'en': 'Search categories...', 'am': 'ምድቦችን ፈልግ...', 'fr': 'Rechercher des catégories...', 'sw': 'Tafuta aina...',
    'ur': 'اقسام میں تلاش کریں...', 'tr': 'Kategorilerde ara...', 'id': 'Cari kategori...', 'bn': 'বিভাগ অনুসন্ধান করুন...', 'ha': 'Bincika rukuni...',
    'so': 'Ka raadi qaybaha...', 'fa': 'جستجو در دسته‌بندی‌ها...', 'ms': 'Cari kategori...',
  },
  'turath_add_quote_action': {
    'ar': 'اقتباس', 'en': 'Quote', 'am': 'ጥቅስ', 'fr': 'Citer', 'sw': 'Nukuu',
    'ur': 'اقتباس', 'tr': 'Alıntı', 'id': 'Kutip', 'bn': 'উদ্ধৃতি', 'ha': 'Ambato',
    'so': 'Xigasho', 'fa': 'نقل‌قول', 'ms': 'Petikan',
  },
  'turath_quote_saved_toast': {
    'ar': 'تم حفظ الاقتباس', 'en': 'Quote saved', 'am': 'ጥቅሱ ተቀምጧል', 'fr': 'Citation enregistrée', 'sw': 'Nukuu imehifadhiwa',
    'ur': 'اقتباس محفوظ ہو گیا', 'tr': 'Alıntı kaydedildi', 'id': 'Kutipan disimpan', 'bn': 'উদ্ধৃতি সংরক্ষিত হয়েছে', 'ha': 'An ajiye ambaton',
    'so': 'Xigashada waa la kaydiyay', 'fa': 'نقل‌قول ذخیره شد', 'ms': 'Petikan disimpan',
  },
  'turath_quotes_title': {
    'ar': 'اقتباساتي', 'en': 'My Quotes', 'am': 'ጥቅሶቼ', 'fr': 'Mes citations', 'sw': 'Nukuu Zangu',
    'ur': 'میرے اقتباسات', 'tr': 'Alıntılarım', 'id': 'Kutipan Saya', 'bn': 'আমার উদ্ধৃতিসমূহ', 'ha': 'Ambatoina',
    'so': 'Xigashooyinkayga', 'fa': 'نقل‌قول‌های من', 'ms': 'Petikan Saya',
  },
  'turath_no_quotes_empty': {
    'ar': 'لا توجد اقتباسات محفوظة بعد', 'en': 'No saved quotes yet', 'am': 'እስካሁን የተቀመጡ ጥቅሶች የሉም', 'fr': "Aucune citation enregistrée pour l'instant",
    'sw': 'Hakuna nukuu zilizohifadhiwa bado', 'ur': 'ابھی تک کوئی اقتباس محفوظ نہیں', 'tr': 'Henüz kaydedilmiş alıntı yok', 'id': 'Belum ada kutipan tersimpan',
    'bn': 'এখনও কোনো উদ্ধৃতি সংরক্ষিত নেই', 'ha': 'Babu ambaton da aka ajiye tukuna', 'so': 'Wali xigashooyin lama kaydin', 'fa': 'هنوز نقل‌قولی ذخیره نشده',
    'ms': 'Tiada petikan disimpan lagi',
  },
  'turath_benefits_title': {
    'ar': 'فوائدي', 'en': 'My Benefits', 'am': 'ጥቅሞቼ', 'fr': 'Mes bénéfices', 'sw': 'Manufaa Yangu',
    'ur': 'میرے فوائد', 'tr': 'Faydalarım', 'id': 'Manfaat Saya', 'bn': 'আমার উপকারিতা', 'ha': 'Amfaninaina',
    'so': 'Faa\'iidooyinkayga', 'fa': 'فواید من', 'ms': 'Manfaat Saya',
  },
  'turath_no_benefits_empty': {
    'ar': 'لا توجد فوائد مسجَّلة بعد', 'en': 'No benefits recorded yet', 'am': 'እስካሁን የተመዘገበ ጥቅም የለም', 'fr': "Aucun bénéfice enregistré pour l'instant",
    'sw': 'Hakuna manufaa yaliyorekodiwa bado', 'ur': 'ابھی تک کوئی فائدہ درج نہیں', 'tr': 'Henüz kaydedilmiş fayda yok', 'id': 'Belum ada manfaat yang dicatat',
    'bn': 'এখনও কোনো উপকারিতা রেকর্ড করা হয়নি', 'ha': 'Babu amfanin da aka rubuta tukuna', 'so': 'Wali faa\'iido lama duubin', 'fa': 'هنوز فایده‌ای ثبت نشده',
    'ms': 'Tiada manfaat direkodkan lagi',
  },
  'turath_add_benefit_action': {
    'ar': 'أضف فائدة', 'en': 'Add Benefit', 'am': 'ጥቅም ጨምር', 'fr': 'Ajouter un bénéfice', 'sw': 'Ongeza Faida',
    'ur': 'فائدہ شامل کریں', 'tr': 'Fayda Ekle', 'id': 'Tambah Manfaat', 'bn': 'উপকারিতা যোগ করুন', 'ha': 'Ƙara Amfani',
    'so': 'Ku dar Faa\'iido', 'fa': 'افزودن فایده', 'ms': 'Tambah Manfaat',
  },
  'turath_benefit_hint': {
    'ar': 'اكتب الفائدة هنا...', 'en': 'Write the benefit here...', 'am': 'ጥቅሙን እዚህ ይጻፉ...', 'fr': 'Écrivez le bénéfice ici...', 'sw': 'Andika faida hapa...',
    'ur': 'فائدہ یہاں لکھیں...', 'tr': 'Faydayı buraya yazın...', 'id': 'Tulis manfaat di sini...', 'bn': 'এখানে উপকারিতা লিখুন...', 'ha': 'Rubuta amfani a nan...',
    'so': 'Halkan ku qor faa\'iidada...', 'fa': 'فایده را اینجا بنویسید...', 'ms': 'Tulis manfaat di sini...',
  },
  'turath_benefit_topic_hint': {
    'ar': 'الموضوع (اختياري)', 'en': 'Topic (optional)', 'am': 'ርዕስ (አማራጭ)', 'fr': 'Sujet (facultatif)', 'sw': 'Mada (si lazima)',
    'ur': 'موضوع (اختیاری)', 'tr': 'Konu (isteğe bağlı)', 'id': 'Topik (opsional)', 'bn': 'বিষয় (ঐচ্ছিক)', 'ha': 'Batu (na zaɓi)',
    'so': 'Mawduuca (ikhtiyaari)', 'fa': 'موضوع (اختیاری)', 'ms': 'Topik (pilihan)',
  },
  'turath_categories_snapshot_label': {
    'ar': 'الأعداد بتاريخ', 'en': 'Counts as of', 'am': 'ቁጥሮች እስከ', 'fr': 'Nombres au', 'sw': 'Idadi hadi',
    'ur': 'تعداد بمطابق', 'tr': 'Sayılar şu tarihte:', 'id': 'Jumlah per', 'bn': 'গণনা এই তারিখ অনুযায়ী', 'ha': 'Adadi kamar na',
    'so': 'Tirooyinka ilaa', 'fa': 'تعداد تا تاریخ', 'ms': 'Kiraan sehingga',
  },
  'turath_category_book_count': {
    'ar': 'عدد الكتب:', 'en': 'Books:', 'am': 'መጻሕፍት:', 'fr': 'Livres :', 'sw': 'Vitabu:',
    'ur': 'کتب کی تعداد:', 'tr': 'Kitaplar:', 'id': 'Buku:', 'bn': 'বই:', 'ha': 'Littattafai:',
    'so': 'Buugag:', 'fa': 'شمار کتاب‌ها:', 'ms': 'Buku:',
  },
  'turath_catalog_preparing': {
    'ar': 'فهرس المكتبة قيد التحضير، أعد المحاولة بعد قليل.', 'en': 'The library index is being prepared, try again shortly.',
    'am': 'የቤተ‑መጻሕፍቱ ማውጫ በመዘጋጀት ላይ ነው፣ ከጥቂት ጊዜ በኋላ እንደገና ይሞክሩ።', 'fr': "L'index de la bibliothèque est en préparation, réessayez bientôt.",
    'sw': 'Faharasa ya maktaba inaandaliwa, jaribu tena baada ya muda.', 'ur': 'لائبریری فہرست تیار کی جا رہی ہے، تھوڑی دیر بعد دوبارہ کوشش کریں۔',
    'tr': 'Kütüphane dizini hazırlanıyor, birazdan tekrar deneyin.', 'id': 'Indeks perpustakaan sedang disiapkan, coba lagi sebentar.',
    'bn': 'লাইব্রেরি সূচি প্রস্তুত করা হচ্ছে, একটু পরে আবার চেষ্টা করুন।', 'ha': 'Ana shirya ƙididdigar ɗakin karatu, sake gwadawa nan ba da jimawa ba.',
    'so': 'Tusmada maktabadda waa la diyaarinayaa, isku day mar kale wax yar ka dib.', 'fa': 'فهرست کتابخانه در حال آماده‌سازی است، کمی بعد دوباره تلاش کنید.',
    'ms': 'Indeks perpustakaan sedang disediakan, cuba lagi sebentar.',
  },
  'turath_pages_unit': {
    'ar': 'صفحة', 'en': 'pages', 'am': 'ገጾች', 'fr': 'pages', 'sw': 'kurasa',
    'ur': 'صفحات', 'tr': 'sayfa', 'id': 'halaman', 'bn': 'পৃষ্ঠা', 'ha': 'shafuka',
    'so': 'bogag', 'fa': 'صفحه', 'ms': 'halaman',
  },
  'turath_search_in_category_hint': {
    'ar': 'ابحث داخل هذا القسم...', 'en': 'Search within this category...', 'am': 'በዚህ ምድብ ውስጥ ይፈልጉ...', 'fr': 'Rechercher dans cette catégorie...', 'sw': 'Tafuta ndani ya kategoria hii...',
    'ur': 'اس زمرے میں تلاش کریں...', 'tr': 'Bu kategoride ara...', 'id': 'Cari dalam kategori ini...', 'bn': 'এই বিভাগে খুঁজুন...', 'ha': 'Bincika cikin wannan rukunin...',
    'so': 'Ka raadi qaybtan gudaheeda...', 'fa': 'در این دسته جست‌وجو کنید...', 'ms': 'Cari dalam kategori ini...',
  },
  'turath_pdf_only_filter': {
    'ar': 'لها PDF فقط', 'en': 'PDF only', 'am': 'PDF ብቻ', 'fr': 'PDF uniquement', 'sw': 'PDF pekee',
    'ur': 'صرف PDF', 'tr': 'Sadece PDF', 'id': 'Hanya PDF', 'bn': 'শুধু PDF', 'ha': 'PDF kaɗai',
    'so': 'PDF kaliya', 'fa': 'فقط PDF', 'ms': 'PDF sahaja',
  },
  'turath_pdf_count_label': {
    'ar': 'لها PDF:', 'en': 'With PDF:', 'am': 'ከPDF ጋር:', 'fr': 'Avec PDF :', 'sw': 'Zenye PDF:',
    'ur': 'PDF کے ساتھ:', 'tr': 'PDF olanlar:', 'id': 'Dengan PDF:', 'bn': 'PDF সহ:', 'ha': 'Masu PDF:',
    'so': 'Leh PDF:', 'fa': 'دارای PDF:', 'ms': 'Dengan PDF:',
  },
  'turath_category_search_results': {
    'ar': 'نتائج داخل', 'en': 'Results within', 'am': 'ውጤቶች በ', 'fr': 'Résultats dans', 'sw': 'Matokeo ndani ya',
    'ur': 'نتائج بمقام', 'tr': 'Şu kategoride sonuçlar:', 'id': 'Hasil dalam', 'bn': 'ফলাফল এর মধ্যে', 'ha': 'Sakamako cikin',
    'so': 'Natiijooyinka gudaha', 'fa': 'نتایج در', 'ms': 'Keputusan dalam',
  },
  'turath_annotation_sheet_title': {
    'ar': 'علامة دراسة', 'en': 'Study mark', 'am': 'የጥናት ምልክት', 'fr': "Marque d'étude", 'sw': 'Alama ya somo',
    'ur': 'مطالعہ نشان', 'tr': 'Çalışma işareti', 'id': 'Tanda belajar', 'bn': 'অধ্যয়ন চিহ্ন', 'ha': 'Alamar karatu',
    'so': 'Calaamad waxbarasho', 'fa': 'نشان مطالعه', 'ms': 'Tanda kajian',
  },
  'turath_highlight_action': {
    'ar': 'تظليل', 'en': 'Highlight', 'am': 'ማድመቅ', 'fr': 'Surligner', 'sw': 'Angazia',
    'ur': 'نمایاں کریں', 'tr': 'Vurgula', 'id': 'Sorot', 'bn': 'হাইলাইট', 'ha': 'Haskaka',
    'so': 'Muuji', 'fa': 'هایلایت', 'ms': 'Serlah',
  },
  'turath_page_note_action': {
    'ar': 'ملاحظة على هذه الصفحة', 'en': 'Note on this page', 'am': 'በዚህ ገጽ ላይ ማስታወሻ', 'fr': 'Note sur cette page', 'sw': 'Dokezo kwenye ukurasa huu',
    'ur': 'اس صفحہ پر نوٹ', 'tr': 'Bu sayfaya not', 'id': 'Catatan di halaman ini', 'bn': 'এই পৃষ্ঠায় নোট', 'ha': 'Bayani a wannan shafi',
    'so': 'Qoraal boggan', 'fa': 'یادداشت روی این صفحه', 'ms': 'Nota pada halaman ini',
  },
  'turath_notebook_kind_all': {
    'ar': 'الكل', 'en': 'All', 'am': 'ሁሉም', 'fr': 'Tout', 'sw': 'Zote',
    'ur': 'سب', 'tr': 'Tümü', 'id': 'Semua', 'bn': 'সব', 'ha': 'Duka',
    'so': 'Dhammaan', 'fa': 'همه', 'ms': 'Semua',
  },
  'night_mode': {
    'ar': 'الوضع الليلي', 'en': 'Night mode', 'am': 'የሌሊት ሁነታ', 'fr': 'Mode nuit', 'sw': 'Hali ya usiku',
    'ur': 'نائٹ موڈ', 'tr': 'Gece modu', 'id': 'Mode malam', 'bn': 'রাত্রি মোড', 'ha': 'Yanayin dare',
    'so': 'Habka habeenka', 'fa': 'حالت شب', 'ms': 'Mod malam',
  },
  'mushaf_tajweed_mode': {
    'ar': 'وضع التجويد', 'en': 'Tajwīd colouring', 'am': 'የተጅዊድ ቀለም', 'fr': 'Couleurs du tajwīd',
    'sw': 'Rangi za tajwidi', 'ur': 'تجوید رنگ', 'tr': 'Tecvid renklendirme', 'id': 'Pewarnaan tajwid',
    'bn': 'তাজবিদ রঙ', 'ha': 'Launukan Tajweed', 'so': 'Midabaynta Tajwiid', 'fa': 'رنگ‌آمیزی تجوید',
    'ms': 'Pewarnaan tajwid',
  },
  'mushaf_tajweed_mode_hint': {
    'ar': 'طبقة دراسية اختيارية — لا تغيّر القراءة العادية', 'en': 'An optional study layer — ordinary reading is unchanged',
    'am': 'አማራጭ የጥናት ሽፋን — መደበኛ ንባብ አይለወጥም', 'fr': 'Une couche d’étude optionnelle — la lecture ordinaire ne change pas',
    'sw': 'Safu ya kujifunza ya hiari — usomaji wa kawaida haubadiliki', 'ur': 'ایک اختیاری مطالعاتی تہہ — عام قراءت میں کوئی تبدیلی نہیں',
    'tr': 'İsteğe bağlı bir çalışma katmanı — normal okuma değişmez', 'id': 'Lapisan belajar opsional — bacaan biasa tidak berubah',
    'bn': 'একটি ঐচ্ছিক অধ্যয়ন স্তর — সাধারণ পাঠ অপরিবর্তিত', 'ha': 'Sashen karatu na zaɓi — karatun yau da kullum bai canza ba',
    'so': 'Lakab barasho ah oo ikhtiyaari ah — akhrinta caadiga ah ma beddesho', 'fa': 'یک لایهٔ مطالعاتی اختیاری — خواندن عادی تغییری نمی‌کند',
    'ms': 'Lapisan pembelajaran pilihan — bacaan biasa tidak berubah',
  },
  'mushaf_index_surahs': {
    'ar': 'الفهرس', 'en': 'Index', 'am': 'ማውጫ', 'fr': 'Index', 'sw': 'Faharasi',
    'ur': 'فہرست', 'tr': 'Fihrist', 'id': 'Indeks', 'bn': 'সূচি', 'ha': 'Fihirisi',
    'so': 'Tusmada', 'fa': 'فهرست', 'ms': 'Indeks',
  },
  'index_tab_surahs': {
    'ar': 'السور', 'en': 'Sūrahs', 'am': 'ሱራዎች', 'fr': 'Sourates', 'sw': 'Sura',
    'ur': 'سورتیں', 'tr': 'Sûreler', 'id': 'Surah', 'bn': 'সূরা', 'ha': 'Surori',
    'so': 'Suurado', 'fa': 'سوره‌ها', 'ms': 'Surah',
  },
  'index_tab_juz': {
    'ar': 'الأجزاء', 'en': 'Juzʼ', 'am': 'ጁዞች', 'fr': 'Juz’', 'sw': 'Juzuu',
    'ur': 'پارے', 'tr': 'Cüzler', 'id': 'Juz', 'bn': 'পারা', 'ha': 'Juzu’i',
    'so': 'Juuzyada', 'fa': 'اجزاء', 'ms': 'Juzuk',
  },
  'juz_label': {
    'ar': 'الجزء', 'en': 'Juzʼ', 'am': 'ጁዝ', 'fr': 'Juz’', 'sw': 'Juzuu',
    'ur': 'پارہ', 'tr': 'Cüz', 'id': 'Juz', 'bn': 'পারা', 'ha': 'Juzu’i',
    'so': 'Juuz', 'fa': 'جزء', 'ms': 'Juzuk',
  },
  'search_action': {
    'ar': 'البحث', 'en': 'Search', 'am': 'ፍለጋ', 'fr': 'Recherche', 'sw': 'Tafuta',
    'ur': 'تلاش', 'tr': 'Ara', 'id': 'Cari', 'bn': 'অনুসন্ধান', 'ha': 'Bincike',
    'so': 'Raadi', 'fa': 'جستجو', 'ms': 'Cari',
  },
  'favorites_title': {
    'ar': 'المفضلة', 'en': 'Favorites', 'am': 'ተወዳጆች', 'fr': 'Favoris', 'sw': 'Vipendwa',
    'ur': 'پسندیدہ', 'tr': 'Favoriler', 'id': 'Favorit', 'bn': 'প্রিয়', 'ha': 'Abubuwan so',
    'so': 'La jecel yahay', 'fa': 'برگزیده‌ها', 'ms': 'Kegemaran',
  },
  'favorites_empty': {
    'ar': 'لم تُضِف أي آية للمفضلة بعد', 'en': 'No favorite ayat yet', 'am': 'እስካሁን የተወደደ አንቀጽ የለም', 'fr': 'Aucun verset favori pour l’instant', 'sw': 'Bado hakuna aya vipendwa',
    'ur': 'ابھی کوئی آیت پسندیدہ میں نہیں', 'tr': 'Henüz favori âyet yok', 'id': 'Belum ada ayat favorit', 'bn': 'এখনও কোনো প্রিয় আয়াত নেই', 'ha': 'Babu ayoyin da aka fi so tukuna',
    'so': 'Weli aayado la jecel yahay ma jiraan', 'fa': 'هنوز آیهٔ برگزیده‌ای نیست', 'ms': 'Belum ada ayat kegemaran',
  },
  'mushaf_mark_memorized': {
    'ar': 'حدّد ما حفظته', 'en': 'Mark what you’ve memorized', 'am': 'ያጠናከርከውን ምልክት አድርግ', 'fr': 'Marquer ce que vous avez mémorisé', 'sw': 'Weka alama uliyohifadhi',
    'ur': 'جو حفظ کیا اسے نشان زد کریں', 'tr': 'Ezberlediğini işaretle', 'id': 'Tandai yang sudah dihafal', 'bn': 'যা মুখস্থ করেছ তা চিহ্নিত কর', 'ha': 'Yi wa abin da ka haddace alama',
    'so': 'Calaamadee waxaad xafiday', 'fa': 'آنچه حفظ کرده‌ای را علامت بزن', 'ms': 'Tandakan yang telah dihafal',
  },
  'turath_page_note_body_label': {
    'ar': 'الملاحظة', 'en': 'Note', 'am': 'ማስታወሻ', 'fr': 'Note', 'sw': 'Dokezo',
    'ur': 'نوٹ', 'tr': 'Not', 'id': 'Catatan', 'bn': 'নোট', 'ha': 'Bayani',
    'so': 'Qoraalka', 'fa': 'یادداشت', 'ms': 'Nota',
  },
  'turath_page_note_empty': {
    'ar': 'اكتب نص الملاحظة أولًا', 'en': 'Write the note text first', 'am': 'መጀመሪያ የማስታወሻ ጽሑፍ ይጻፉ', 'fr': "Écrivez d'abord le texte de la note", 'sw': 'Andika maandishi ya dokezo kwanza',
    'ur': 'پہلے نوٹ کا متن لکھیں', 'tr': 'Önce not metnini yazın', 'id': 'Tulis teks catatan dahulu', 'bn': 'আগে নোটের লেখা লিখুন', 'ha': 'Rubuta rubutun bayani da farko',
    'so': 'Marka hore qor qoraalka', 'fa': 'ابتدا متن یادداشت را بنویسید', 'ms': 'Tulis teks nota dahulu',
  },
  'turath_highlight_pick_color': {
    'ar': 'اختر لونًا', 'en': 'Pick a colour', 'am': 'ቀለም ይምረጡ', 'fr': 'Choisir une couleur', 'sw': 'Chagua rangi',
    'ur': 'رنگ منتخب کریں', 'tr': 'Bir renk seçin', 'id': 'Pilih warna', 'bn': 'একটি রঙ বেছে নিন', 'ha': 'Zaɓi launi',
    'so': 'Dooro midab', 'fa': 'یک رنگ انتخاب کنید', 'ms': 'Pilih warna',
  },
  'turath_highlight_add_note_optional': {
    'ar': 'أضف فائدة (اختياري)', 'en': 'Add a note (optional)', 'am': 'ማስታወሻ ያክሉ (አማራጭ)', 'fr': 'Ajouter une note (facultatif)', 'sw': 'Ongeza dokezo (si lazima)',
    'ur': 'نوٹ شامل کریں (اختیاری)', 'tr': 'Not ekle (isteğe bağlı)', 'id': 'Tambahkan catatan (opsional)', 'bn': 'একটি নোট যোগ করুন (ঐচ্ছিক)', 'ha': 'Ƙara bayanin kula (na zaɓi)',
    'so': 'Ku dar qoraal (ikhtiyaari)', 'fa': 'یادداشت اضافه کنید (اختیاری)', 'ms': 'Tambah nota (pilihan)',
  },
  'turath_highlight_done': {
    'ar': 'تم', 'en': 'Done', 'am': 'ተጠናቀቀ', 'fr': 'Terminé', 'sw': 'Imekamilika',
    'ur': 'ہو گیا', 'tr': 'Tamam', 'id': 'Selesai', 'bn': 'সম্পন্ন', 'ha': 'An gama',
    'so': 'Dhammaad', 'fa': 'انجام شد', 'ms': 'Selesai',
  },
  'turath_annotation_edit_range': {
    'ar': 'تعديل النطاق', 'en': 'Edit range', 'am': 'ክልል አርትዕ', 'fr': "Modifier l'étendue", 'sw': 'Hariri eneo',
    'ur': 'حد میں ترمیم', 'tr': 'Aralığı düzenle', 'id': 'Edit rentang', 'bn': 'পরিসর সম্পাদনা', 'ha': 'Gyara iyaka',
    'so': 'Wax ka beddel xadka', 'fa': 'ویرایش محدوده', 'ms': 'Sunting julat',
  },
  'turath_edit_range_banner': {
    'ar': 'حدّد النص الجديد لهذا التظليل ثم اختر «تحديث النطاق» من قائمة التحديد',
    'en': 'Select the new text for this highlight, then choose "Update range" from the selection menu',
    'am': 'ለዚህ ማድመቅ አዲሱን ጽሑፍ ይምረጡ፣ ከዚያ ከምርጫ ዝርዝሩ «ክልል አዘምን» ይምረጡ',
    'fr': 'Sélectionnez le nouveau texte pour ce surlignage, puis choisissez « Mettre à jour l’étendue » dans le menu',
    'sw': 'Chagua maandishi mapya kwa mstari huu, kisha chagua "Sasisha eneo" kwenye menyu ya uteuzi',
    'ur': 'اس ہائی لائٹ کے لیے نیا متن منتخب کریں، پھر مینو سے «حد کو اپ ڈیٹ کریں» چنیں',
    'tr': 'Bu vurgu için yeni metni seçin, ardından seçim menüsünden "Aralığı güncelle" seçeneğini seçin',
    'id': 'Pilih teks baru untuk sorotan ini, lalu pilih "Perbarui rentang" dari menu seleksi',
    'bn': 'এই হাইলাইটের জন্য নতুন টেক্সট নির্বাচন করুন, তারপর মেনু থেকে "পরিসর হালনাগাদ" বেছে নিন',
    'ha': 'Zaɓi sabon rubutu don wannan haske, sannan zaɓi "Sabunta iyaka" daga menu',
    'so': 'Dooro qoraalka cusub ee muujintan, ka dibna ka dooro "Cusboonaysii xadka" liiska',
    'fa': 'متن جدید این هایلایت را انتخاب کنید، سپس از منو «به‌روزرسانی محدوده» را انتخاب کنید',
    'ms': 'Pilih teks baharu untuk serlahan ini, kemudian pilih "Kemas kini julat" daripada menu',
  },
  'turath_update_range_action': {
    'ar': 'تحديث النطاق', 'en': 'Update range', 'am': 'ክልል አዘምን', 'fr': "Mettre à jour l'étendue", 'sw': 'Sasisha eneo',
    'ur': 'حد کو اپ ڈیٹ کریں', 'tr': 'Aralığı güncelle', 'id': 'Perbarui rentang', 'bn': 'পরিসর হালনাগাদ', 'ha': 'Sabunta iyaka',
    'so': 'Cusboonaysii xadka', 'fa': 'به‌روزرسانی محدوده', 'ms': 'Kemas kini julat',
  },
  'turath_range_updated_toast': {
    'ar': 'تم تحديث نطاق التظليل', 'en': 'Highlight range updated', 'am': 'የማድመቅ ክልል ተዘምኗል', 'fr': "Étendue du surlignage mise à jour", 'sw': 'Eneo la mstari limesasishwa',
    'ur': 'ہائی لائٹ کی حد اپ ڈیٹ ہو گئی', 'tr': 'Vurgu aralığı güncellendi', 'id': 'Rentang sorotan diperbarui', 'bn': 'হাইলাইট পরিসর হালনাগাদ হয়েছে', 'ha': 'An sabunta iyakar haske',
    'so': 'Xadka muujinta waa la cusboonaysiiyay', 'fa': 'محدوده هایلایت به‌روزرسانی شد', 'ms': 'Julat serlahan dikemas kini',
  },

  // ---- Ayah Study Notebook (79-sa-D-ayah) — full 13-language coverage.
  'ayah_notebook_title': {
    'ar': 'دفتر الآية', 'en': 'Ayah notebook', 'am': 'የአንቀጽ ማስታወሻ', 'fr': "Carnet du verset", 'sw': 'Daftari la aya',
    'ur': 'آیت کی نوٹ بک', 'tr': 'Ayet defteri', 'id': 'Buku catatan ayat', 'bn': 'আয়াত নোটবুক', 'ha': "Littafin rubutun aya",
    'so': 'Buugga aayadda', 'fa': 'دفترچه آیه', 'ms': 'Buku nota ayat',
  },
  'ayah_notebook_add_action': {
    'ar': 'إضافة إلى دفتر الآية', 'en': 'Add to ayah notebook', 'am': 'ወደ አንቀጽ ማስታወሻ ጨምር', 'fr': "Ajouter au carnet du verset", 'sw': 'Ongeza kwenye daftari la aya',
    'ur': 'آیت کی نوٹ بک میں شامل کریں', 'tr': 'Ayet defterine ekle', 'id': 'Tambahkan ke buku catatan ayat', 'bn': 'আয়াত নোটবুকে যোগ করুন', 'ha': "Ƙara cikin littafin rubutun aya",
    'so': 'Ku dar buugga aayadda', 'fa': 'افزودن به دفترچه آیه', 'ms': 'Tambah ke buku nota ayat',
  },
  'ayah_notebook_open_action': {
    'ar': 'دفتري لهذه الآية', 'en': 'My notebook for this ayah', 'am': 'ለዚህ አንቀጽ ማስታወሻዬ', 'fr': "Mon carnet pour ce verset", 'sw': 'Daftari langu la aya hii',
    'ur': 'اس آیت کے لیے میری نوٹ بک', 'tr': 'Bu ayet için defterim', 'id': 'Buku catatan saya untuk ayat ini', 'bn': 'এই আয়াতের জন্য আমার নোটবুক', 'ha': "Littafin rubutuna na wannan aya",
    'so': 'Buugayga aayaddan', 'fa': 'دفترچه من برای این آیه', 'ms': 'Buku nota saya untuk ayat ini',
  },
  'ayah_notebook_empty': {
    'ar': 'لا مداخل بعد — أضف أول ما تعلّمته عن هذه الآية', 'en': 'Nothing yet — add the first thing you learned about this ayah',
    'am': 'እስካሁን ምንም የለም — ስለዚህ አንቀጽ የተማርከውን የመጀመሪያ ነገር ጨምር', 'fr': "Rien encore — ajoutez la première chose apprise sur ce verset",
    'sw': 'Bado hakuna — ongeza jambo la kwanza ulilojifunza kuhusu aya hii', 'ur': 'ابھی کچھ نہیں — اس آیت کے بارے میں جو پہلی بات سیکھی وہ شامل کریں',
    'tr': 'Henüz bir şey yok — bu ayet hakkında öğrendiğin ilk şeyi ekle', 'id': 'Belum ada — tambahkan hal pertama yang Anda pelajari tentang ayat ini',
    'bn': 'এখনও কিছু নেই — এই আয়াত সম্পর্কে শেখা প্রথম বিষয়টি যোগ করুন', 'ha': "Babu kome tukuna — ƙara abu na farko da ka koya game da wannan aya",
    'so': 'Weli waxba ma jiraan — ku dar waxa ugu horreeya ee aad ka baratay aayaddan', 'fa': 'هنوز چیزی نیست — اولین چیزی که درباره این آیه آموختی اضافه کن',
    'ms': 'Belum ada apa-apa — tambah perkara pertama yang anda pelajari tentang ayat ini',
  },
  'ayah_notebook_all_filter': {
    'ar': 'الكل', 'en': 'All', 'am': 'ሁሉም', 'fr': 'Tout', 'sw': 'Yote',
    'ur': 'سب', 'tr': 'Tümü', 'id': 'Semua', 'bn': 'সব', 'ha': 'Duka',
    'so': 'Dhammaan', 'fa': 'همه', 'ms': 'Semua',
  },
  'ayah_notebook_newest_first': {
    'ar': 'الأحدث أولًا', 'en': 'Newest first', 'am': 'አዲሱ መጀመሪያ', 'fr': "Le plus récent d'abord", 'sw': 'Mpya kwanza',
    'ur': 'نئے پہلے', 'tr': 'Önce en yeni', 'id': 'Terbaru dulu', 'bn': 'নতুন আগে', 'ha': "Sabo da farko",
    'so': 'Kii ugu cusub marka hore', 'fa': 'جدیدترین اول', 'ms': 'Terbaharu dahulu',
  },
  'ayah_notebook_oldest_first': {
    'ar': 'الأقدم أولًا', 'en': 'Oldest first', 'am': 'የቆየው መጀመሪያ', 'fr': "Le plus ancien d'abord", 'sw': 'Ya zamani kwanza',
    'ur': 'پرانے پہلے', 'tr': 'Önce en eski', 'id': 'Terlama dulu', 'bn': 'পুরনো আগে', 'ha': "Tsoho da farko",
    'so': 'Kii ugu duugga ah marka hore', 'fa': 'قدیمی‌ترین اول', 'ms': 'Terlama dahulu',
  },
  'ayah_entry_body_hint': {
    'ar': 'اكتب هنا ما تعلّمته عن هذه الآية...', 'en': 'Write what you learned about this ayah...', 'am': 'ስለዚህ አንቀጽ የተማርከውን እዚህ ጻፍ...', 'fr': "Écrivez ce que vous avez appris sur ce verset...", 'sw': 'Andika ulichojifunza kuhusu aya hii...',
    'ur': 'اس آیت کے بارے میں جو سیکھا وہ یہاں لکھیں...', 'tr': 'Bu ayet hakkında öğrendiklerini buraya yaz...', 'id': 'Tulis apa yang Anda pelajari tentang ayat ini...', 'bn': 'এই আয়াত সম্পর্কে যা শিখেছেন তা লিখুন...', 'ha': "Rubuta abin da ka koya game da wannan aya...",
    'so': 'Halkan ku qor waxa aad ka baratay aayaddan...', 'fa': 'آنچه درباره این آیه آموختی اینجا بنویس...', 'ms': 'Tulis apa yang anda pelajari tentang ayat ini...',
  },
  'ayah_entry_more_types': {
    'ar': 'المزيد', 'en': 'More', 'am': 'ተጨማሪ', 'fr': 'Plus', 'sw': 'Zaidi',
    'ur': 'مزید', 'tr': 'Daha fazla', 'id': 'Lainnya', 'bn': 'আরও', 'ha': "Ƙari",
    'so': 'Wax badan', 'fa': 'بیشتر', 'ms': 'Lagi',
  },
  'ayah_entry_topic_hint': {
    'ar': 'وسم (اختياري): عقيدة، بلاغة، الطهارة...', 'en': 'Tag (optional): aqeedah, balagha, purity...', 'am': 'መለያ (አማራጭ): እምነት፣ ንግግር፣ ንፅህና...', 'fr': "Étiquette (facultatif) : croyance, rhétorique, pureté...", 'sw': 'Lebo (si lazima): akida, balagha, tohara...',
    'ur': 'ٹیگ (اختیاری): عقیدہ، بلاغت، طہارت...', 'tr': 'Etiket (isteğe bağlı): akide, belagat, taharet...', 'id': 'Tag (opsional): akidah, balaghah, kesucian...', 'bn': 'ট্যাগ (ঐচ্ছিক): আকিদা, বালাগাত, পবিত্রতা...', 'ha': "Alama (na zaɓi): akida, balaga, tsarki...",
    'so': 'Tag (ikhtiyaari): caqiido, balaagha, daahirnimo...', 'fa': 'برچسب (اختیاری): عقیده، بلاغت، طهارت...', 'ms': 'Tag (pilihan): akidah, balaghah, kesucian...',
  },
  'ayah_entry_source_section': {
    'ar': 'المصدر (اختياري)', 'en': 'Source (optional)', 'am': 'ምንጭ (አማራጭ)', 'fr': 'Source (facultatif)', 'sw': 'Chanzo (si lazima)',
    'ur': 'ماخذ (اختیاری)', 'tr': 'Kaynak (isteğe bağlı)', 'id': 'Sumber (opsional)', 'bn': 'উৎস (ঐচ্ছিক)', 'ha': "Tushe (na zaɓi)",
    'so': 'Isha (ikhtiyaari)', 'fa': 'منبع (اختیاری)', 'ms': 'Sumber (pilihan)',
  },
  'ayah_entry_source_name_hint': {
    'ar': 'اسم التفسير / الكتاب / سلسلة الدروس', 'en': 'Tafsir / book / lesson series name', 'am': 'የተፍሲር / የመጽሐፍ / የትምህርት ስም', 'fr': "Nom du tafsir / livre / série de cours", 'sw': 'Jina la tafsiri / kitabu / mfululizo wa masomo',
    'ur': 'تفسیر / کتاب / سلسلۂ دروس کا نام', 'tr': 'Tefsir / kitap / ders serisi adı', 'id': 'Nama tafsir / kitab / seri pelajaran', 'bn': 'তাফসির / কিতাব / পাঠ সিরিজের নাম', 'ha': "Sunan tafsiri / littafi / jerin darussa",
    'so': 'Magaca tafsiirka / kitaabka / taxanaha casharrada', 'fa': 'نام تفسیر / کتاب / سلسله دروس', 'ms': 'Nama tafsir / kitab / siri pelajaran',
  },
  'ayah_entry_source_author_hint': {
    'ar': 'المؤلف / الشيخ', 'en': 'Author / sheikh', 'am': 'ደራሲ / ሸይኽ', 'fr': "Auteur / cheikh", 'sw': 'Mwandishi / sheikh',
    'ur': 'مصنف / شیخ', 'tr': 'Yazar / şeyh', 'id': 'Penulis / syekh', 'bn': 'লেখক / শায়খ', 'ha': "Marubuci / shehi",
    'so': 'Qoraaga / sheekh', 'fa': 'مؤلف / شیخ', 'ms': 'Pengarang / syeikh',
  },
  'ayah_entry_source_ref_hint': {
    'ar': 'الجزء / الصفحة / رقم الدرس', 'en': 'Volume / page / lesson number', 'am': 'ጥራዝ / ገጽ / የትምህርት ቁጥር', 'fr': "Tome / page / numéro du cours", 'sw': 'Juzuu / ukurasa / namba ya somo',
    'ur': 'جلد / صفحہ / درس نمبر', 'tr': 'Cilt / sayfa / ders numarası', 'id': 'Jilid / halaman / nomor pelajaran', 'bn': 'খণ্ড / পৃষ্ঠা / পাঠ নম্বর', 'ha': "Juzu'i / shafi / lambar darasi",
    'so': 'Mug / bog / lambarka casharka', 'fa': 'جلد / صفحه / شماره درس', 'ms': 'Jilid / halaman / nombor pelajaran',
  },
  'ayah_entry_source_date_hint': {
    'ar': 'التاريخ', 'en': 'Date', 'am': 'ቀን', 'fr': 'Date', 'sw': 'Tarehe',
    'ur': 'تاریخ', 'tr': 'Tarih', 'id': 'Tanggal', 'bn': 'তারিখ', 'ha': "Kwanan wata",
    'so': 'Taariikhda', 'fa': 'تاریخ', 'ms': 'Tarikh',
  },
  'ayah_entry_question_open': {
    'ar': 'سؤال مفتوح', 'en': 'Open question', 'am': 'ክፍት ጥያቄ', 'fr': "Question ouverte", 'sw': 'Swali wazi',
    'ur': 'کھلا سوال', 'tr': 'Açık soru', 'id': 'Pertanyaan terbuka', 'bn': 'উন্মুক্ত প্রশ্ন', 'ha': "Tambaya a buɗe",
    'so': "Su'aal furan", 'fa': 'پرسش باز', 'ms': 'Soalan terbuka',
  },
  'ayah_entry_question_resolved': {
    'ar': 'مُجاب', 'en': 'Answered', 'am': 'ተመልሷል', 'fr': 'Répondu', 'sw': 'Imejibiwa',
    'ur': 'جواب مل گیا', 'tr': 'Cevaplandı', 'id': 'Terjawab', 'bn': 'উত্তর দেওয়া হয়েছে', 'ha': "An amsa",
    'so': 'La jawaabay', 'fa': 'پاسخ داده شد', 'ms': 'Dijawab',
  },
  'ayah_entry_for_review': {
    'ar': 'للمراجعة', 'en': 'For review', 'am': 'ለክለሳ', 'fr': "À réviser", 'sw': 'Kwa mapitio',
    'ur': 'دہرائی کے لیے', 'tr': 'Tekrar için', 'id': 'Untuk ditinjau', 'bn': 'পুনরালোচনার জন্য', 'ha': "Don bita",
    'so': 'Dib-u-eegis', 'fa': 'برای مرور', 'ms': 'Untuk ulang kaji',
  },
  'ayah_entry_saved_toast': {
    'ar': 'أُضيف إلى دفتر الآية', 'en': 'Added to the ayah notebook', 'am': 'ወደ አንቀጽ ማስታወሻ ተጨምሯል', 'fr': "Ajouté au carnet du verset", 'sw': 'Imeongezwa kwenye daftari la aya',
    'ur': 'آیت کی نوٹ بک میں شامل ہو گیا', 'tr': 'Ayet defterine eklendi', 'id': 'Ditambahkan ke buku catatan ayat', 'bn': 'আয়াত নোটবুকে যোগ হয়েছে', 'ha': "An ƙara cikin littafin rubutun aya",
    'so': 'Waxaa lagu daray buugga aayadda', 'fa': 'به دفترچه آیه افزوده شد', 'ms': 'Ditambah ke buku nota ayat',
  },
  'ayah_type_personal': {
    'ar': 'ملاحظة', 'en': 'Note', 'am': 'ማስታወሻ', 'fr': 'Note', 'sw': 'Dokezo',
    'ur': 'نوٹ', 'tr': 'Not', 'id': 'Catatan', 'bn': 'নোট', 'ha': "Bayanin kula",
    'so': 'Qoraal', 'fa': 'یادداشت', 'ms': 'Nota',
  },
  'ayah_type_tafsir': {
    'ar': 'قول مفسّر', 'en': 'Mufassir saying', 'am': 'የተፍሲር አባባል', 'fr': "Parole d'un exégète", 'sw': 'Kauli ya mfasiri',
    'ur': 'مفسر کا قول', 'tr': 'Müfessir sözü', 'id': 'Perkataan mufassir', 'bn': 'মুফাসসিরের বক্তব্য', 'ha': "Maganar mai tafsiri",
    'so': 'Hadalka mufassirka', 'fa': 'سخن مفسّر', 'ms': 'Kata-kata mufassir',
  },
  'ayah_type_meaning': {
    'ar': 'معنى / سياق', 'en': 'Meaning / context', 'am': 'ትርጉም / አውድ', 'fr': "Sens / contexte", 'sw': 'Maana / muktadha',
    'ur': 'معنی / سیاق', 'tr': 'Anlam / bağlam', 'id': 'Makna / konteks', 'bn': 'অর্থ / প্রসঙ্গ', 'ha': "Ma'ana / mahalli",
    'so': 'Macne / macnaha guud', 'fa': 'معنا / سیاق', 'ms': 'Makna / konteks',
  },
  'ayah_type_benefit': {
    'ar': 'فائدة', 'en': 'Benefit', 'am': 'ጥቅም', 'fr': 'Bénéfice', 'sw': 'Faida',
    'ur': 'فائدہ', 'tr': 'Fayda', 'id': 'Faedah', 'bn': 'উপকার', 'ha': "Amfani",
    'so': "Faa'iido", 'fa': 'فایده', 'ms': 'Faedah',
  },
  'ayah_type_linguistic': {
    'ar': 'فائدة لغوية', 'en': 'Linguistic point', 'am': 'የቋንቋ ነጥብ', 'fr': "Point linguistique", 'sw': 'Nukta ya kiisimu',
    'ur': 'لغوی فائدہ', 'tr': 'Dilsel nokta', 'id': 'Faedah bahasa', 'bn': 'ভাষাগত পয়েন্ট', 'ha': "Fa'idar harshe",
    'so': "Faa'iido luqadeed", 'fa': 'نکته زبانی', 'ms': 'Poin linguistik',
  },
  'ayah_type_fiqh': {
    'ar': 'فائدة فقهية', 'en': 'Fiqh point', 'am': 'የፊቅህ ነጥብ', 'fr': "Point de fiqh", 'sw': 'Nukta ya fiqhi',
    'ur': 'فقہی فائدہ', 'tr': 'Fıkhi nokta', 'id': 'Faedah fikih', 'bn': 'ফিকহি পয়েন্ট', 'ha': "Fa'idar fikihu",
    'so': "Faa'iido fiqhi", 'fa': 'نکته فقهی', 'ms': 'Poin fiqh',
  },
  'ayah_type_aqeedah': {
    'ar': 'فائدة عقدية', 'en': 'Aqeedah point', 'am': 'የእምነት ነጥብ', 'fr': "Point de croyance", 'sw': 'Nukta ya akida',
    'ur': 'عقدی فائدہ', 'tr': 'Akide noktası', 'id': 'Faedah akidah', 'bn': 'আকিদা পয়েন্ট', 'ha': "Fa'idar akida",
    'so': "Faa'iido caqiido", 'fa': 'نکته عقیدتی', 'ms': 'Poin akidah',
  },
  'ayah_type_tarbawi': {
    'ar': 'فائدة تربوية', 'en': 'Tarbawi point', 'am': 'የአስተዳደግ ነጥብ', 'fr': "Point éducatif", 'sw': 'Nukta ya malezi',
    'ur': 'تربیتی فائدہ', 'tr': 'Terbiyevi nokta', 'id': 'Faedah tarbawi', 'bn': 'তারবিয়াতি পয়েন্ট', 'ha': "Fa'idar tarbiyya",
    'so': "Faa'iido tarbiyadeed", 'fa': 'نکته تربیتی', 'ms': 'Poin tarbawi',
  },
  'ayah_type_hadith': {
    'ar': 'حديث متعلّق', 'en': 'Related hadith', 'am': 'ተዛማጅ ሐዲስ', 'fr': "Hadith en lien", 'sw': 'Hadithi inayohusiana',
    'ur': 'متعلقہ حدیث', 'tr': 'İlgili hadis', 'id': 'Hadis terkait', 'bn': 'সম্পর্কিত হাদিস', 'ha': "Hadisi mai alaƙa",
    'so': 'Xadiis la xiriira', 'fa': 'حدیث مرتبط', 'ms': 'Hadis berkaitan',
  },
  'ayah_type_comparison': {
    'ar': 'مقارنة أقوال', 'en': 'Comparison of sayings', 'am': 'የአባባሎች ንፅፅር', 'fr': "Comparaison d'avis", 'sw': 'Kulinganisha kauli',
    'ur': 'اقوال کا موازنہ', 'tr': 'Görüşlerin karşılaştırması', 'id': 'Perbandingan pendapat', 'bn': 'উক্তির তুলনা', 'ha': "Kwatanta ra'ayoyi",
    'so': 'Isbarbardhigga hadallada', 'fa': 'مقایسه اقوال', 'ms': 'Perbandingan pendapat',
  },
  'ayah_type_question': {
    'ar': 'سؤال', 'en': 'Question', 'am': 'ጥያቄ', 'fr': 'Question', 'sw': 'Swali',
    'ur': 'سوال', 'tr': 'Soru', 'id': 'Pertanyaan', 'bn': 'প্রশ্ন', 'ha': "Tambaya",
    'so': "Su'aal", 'fa': 'پرسش', 'ms': 'Soalan',
  },
  'ayah_type_link': {
    'ar': 'رابط', 'en': 'Link', 'am': 'ማገናኛ', 'fr': 'Lien', 'sw': 'Kiungo',
    'ur': 'ربط', 'tr': 'Bağlantı', 'id': 'Tautan', 'bn': 'সংযোগ', 'ha': "Haɗi",
    'so': 'Xiriir', 'fa': 'پیوند', 'ms': 'Pautan',
  },
  'ayah_type_lesson_summary': {
    'ar': 'ملخّص درس', 'en': 'Lesson summary', 'am': 'የትምህርት ማጠቃለያ', 'fr': "Résumé de cours", 'sw': 'Muhtasari wa somo',
    'ur': 'درس کا خلاصہ', 'tr': 'Ders özeti', 'id': 'Ringkasan pelajaran', 'bn': 'পাঠের সারসংক্ষেপ', 'ha': "Taƙaitaccen darasi",
    'so': 'Kooban casharka', 'fa': 'خلاصه درس', 'ms': 'Ringkasan pelajaran',
  },
  'ayah_type_review': {
    'ar': 'للحفظ والمراجعة', 'en': 'To memorise / review', 'am': 'ለማስታወስ / ለክለሳ', 'fr': "À mémoriser / réviser", 'sw': 'Kukariri / kupitia',
    'ur': 'حفظ اور دہرائی کے لیے', 'tr': 'Ezber / tekrar için', 'id': 'Untuk dihafal / diulang', 'bn': 'মুখস্থ / পুনরালোচনার জন্য', 'ha': "Don haddacewa / bita",
    'so': 'Xafid / dib-u-eegis', 'fa': 'برای حفظ / مرور', 'ms': 'Untuk hafalan / ulang kaji',
  },
  'ayah_stance_naql': {
    'ar': 'نقل', 'en': 'Quoted', 'am': 'የተጠቀሰ', 'fr': 'Rapporté', 'sw': 'Imenukuliwa',
    'ur': 'منقول', 'tr': 'Nakil', 'id': 'Nukilan', 'bn': 'উদ্ধৃত', 'ha': "An ruwaito",
    'so': 'La soo xigtay', 'fa': 'نقل', 'ms': 'Petikan',
  },
  'ayah_stance_fahm': {
    'ar': 'فهمي', 'en': 'My understanding', 'am': 'የእኔ ግንዛቤ', 'fr': "Ma compréhension", 'sw': 'Ufahamu wangu',
    'ur': 'میری سمجھ', 'tr': 'Benim anlayışım', 'id': 'Pemahaman saya', 'bn': 'আমার বোঝা', 'ha': "Fahimtata",
    'so': 'Fahamkayga', 'fa': 'فهم من', 'ms': 'Kefahaman saya',
  },
  'ayah_stance_istinbat': {
    'ar': 'استنباط', 'en': 'Derived', 'am': 'የተገኘ', 'fr': 'Déduit', 'sw': 'Nilichokitoa',
    'ur': 'استنباط', 'tr': 'İstinbat', 'id': 'Istinbath', 'bn': 'ইস্তিমবাত', 'ha': "An cirato",
    'so': 'La soo saaray', 'fa': 'استنباط', 'ms': 'Istinbat',
  },
  'ayah_stance_sual': {
    'ar': 'سؤال', 'en': 'Question', 'am': 'ጥያቄ', 'fr': 'Question', 'sw': 'Swali',
    'ur': 'سوال', 'tr': 'Soru', 'id': 'Pertanyaan', 'bn': 'প্রশ্ন', 'ha': "Tambaya",
    'so': "Su'aal", 'fa': 'پرسش', 'ms': 'Soalan',
  },
  'ayah_source_tafsir_book': {
    'ar': 'كتاب تفسير', 'en': 'Tafsir book', 'am': 'የተፍሲር መጽሐፍ', 'fr': "Livre de tafsir", 'sw': 'Kitabu cha tafsiri',
    'ur': 'کتابِ تفسیر', 'tr': 'Tefsir kitabı', 'id': 'Kitab tafsir', 'bn': 'তাফসির গ্রন্থ', 'ha': "Littafin tafsiri",
    'so': 'Kitaab tafsiir', 'fa': 'کتاب تفسیر', 'ms': 'Kitab tafsir',
  },
  'ayah_source_tafsir_lesson': {
    'ar': 'درس تفسير', 'en': 'Tafsir lesson', 'am': 'የተፍሲር ትምህርት', 'fr': "Cours de tafsir", 'sw': 'Somo la tafsiri',
    'ur': 'درسِ تفسیر', 'tr': 'Tefsir dersi', 'id': 'Pelajaran tafsir', 'bn': 'তাফসির পাঠ', 'ha': "Darasin tafsiri",
    'so': 'Cashar tafsiir', 'fa': 'درس تفسیر', 'ms': 'Pelajaran tafsir',
  },
  'ayah_source_sheikh_lesson': {
    'ar': 'درس شيخ', 'en': 'Sheikh lesson', 'am': 'የሸይኽ ትምህርት', 'fr': "Cours d'un cheikh", 'sw': 'Somo la sheikh',
    'ur': 'شیخ کا درس', 'tr': 'Şeyh dersi', 'id': 'Pelajaran syekh', 'bn': 'শায়খের পাঠ', 'ha': "Darasin shehi",
    'so': 'Cashar sheekh', 'fa': 'درس شیخ', 'ms': 'Pelajaran syeikh',
  },
  'ayah_source_book': {
    'ar': 'كتاب', 'en': 'Book', 'am': 'መጽሐፍ', 'fr': 'Livre', 'sw': 'Kitabu',
    'ur': 'کتاب', 'tr': 'Kitap', 'id': 'Kitab', 'bn': 'কিতাব', 'ha': "Littafi",
    'so': 'Kitaab', 'fa': 'کتاب', 'ms': 'Kitab',
  },
  'ayah_source_hadith': {
    'ar': 'حديث', 'en': 'Hadith', 'am': 'ሐዲስ', 'fr': 'Hadith', 'sw': 'Hadithi',
    'ur': 'حدیث', 'tr': 'Hadis', 'id': 'Hadis', 'bn': 'হাদিস', 'ha': "Hadisi",
    'so': 'Xadiis', 'fa': 'حدیث', 'ms': 'Hadis',
  },
  'ayah_source_personal': {
    'ar': 'شخصي', 'en': 'Personal', 'am': 'የግል', 'fr': 'Personnel', 'sw': 'Binafsi',
    'ur': 'ذاتی', 'tr': 'Kişisel', 'id': 'Pribadi', 'bn': 'ব্যক্তিগত', 'ha': "Na kaina",
    'so': 'Shakhsi ah', 'fa': 'شخصی', 'ms': 'Peribadi',
  },
  'ayah_source_other': {
    'ar': 'أخرى', 'en': 'Other', 'am': 'ሌላ', 'fr': 'Autre', 'sw': 'Nyingine',
    'ur': 'دیگر', 'tr': 'Diğer', 'id': 'Lainnya', 'bn': 'অন্যান্য', 'ha': "Wani",
    'so': 'Kale', 'fa': 'دیگر', 'ms': 'Lain',
  },
  'quran_notebook_title': {
    'ar': 'دفتر القرآن', 'en': 'Quran notebook', 'am': 'የቁርኣን ማስታወሻ', 'fr': "Carnet du Coran", 'sw': 'Daftari la Qurani',
    'ur': 'قرآن نوٹ بک', 'tr': 'Kur’an defteri', 'id': 'Buku catatan Al-Qur’an', 'bn': 'কুরআন নোটবুক', 'ha': "Littafin rubutun Alkur'ani",
    'so': 'Buugga Qurʼaanka', 'fa': 'دفترچه قرآن', 'ms': 'Buku nota Al-Quran',
  },
  'quran_notebook_subtitle': {
    'ar': 'كل فوائدك ودراستك للآيات', 'en': 'All your ayah study and benefits', 'am': 'ሁሉም የአንቀጽ ጥናትዎና ጥቅሞችዎ', 'fr': "Toutes vos études et bénéfices sur les versets", 'sw': 'Masomo yako yote ya aya na faida',
    'ur': 'آیات کے بارے میں آپ کی تمام دراسات اور فوائد', 'tr': 'Ayetlerle ilgili tüm çalışmaların ve faydaların', 'id': 'Semua kajian dan faedah ayat Anda', 'bn': 'আয়াত সম্পর্কে আপনার সমস্ত অধ্যয়ন ও উপকারিতা', 'ha': "Duk karatunka da fa'idodinka na ayoyi",
    'so': 'Dhammaan daraasadaada aayadaha iyo faaʼiidooyinka', 'fa': 'همه مطالعه و فوایدت درباره آیات', 'ms': 'Semua kajian dan faedah ayat anda',
  },
  'quran_notebook_search_hint': {
    'ar': 'ابحث في دفتر القرآن...', 'en': 'Search the Quran notebook...', 'am': 'የቁርኣን ማስታወሻን ይፈልጉ...', 'fr': "Rechercher dans le carnet du Coran...", 'sw': 'Tafuta katika daftari la Qurani...',
    'ur': 'قرآن نوٹ بک میں تلاش کریں...', 'tr': 'Kur’an defterinde ara...', 'id': 'Cari di buku catatan Al-Qur’an...', 'bn': 'কুরআন নোটবুকে খুঁজুন...', 'ha': "Bincika littafin rubutun Alkur'ani...",
    'so': 'Ka raadi buugga Qurʼaanka...', 'fa': 'در دفترچه قرآن جست‌وجو کنید...', 'ms': 'Cari dalam buku nota Al-Quran...',
  },
  'quran_notebook_empty': {
    'ar': 'لا مداخل بعد — افتح أي آية وأضف أول فائدة', 'en': 'Nothing yet — open any ayah and add your first entry',
    'am': 'እስካሁን ምንም የለም — ማንኛውንም አንቀጽ ክፈት እና የመጀመሪያ ግቤትህን ጨምር', 'fr': "Rien encore — ouvrez un verset et ajoutez votre première entrée",
    'sw': 'Bado hakuna — fungua aya yoyote na uongeze ingizo lako la kwanza', 'ur': 'ابھی کچھ نہیں — کوئی بھی آیت کھولیں اور پہلی انٹری شامل کریں',
    'tr': 'Henüz bir şey yok — herhangi bir ayeti aç ve ilk kaydını ekle', 'id': 'Belum ada — buka ayat mana pun dan tambahkan entri pertama',
    'bn': 'এখনও কিছু নেই — যেকোনো আয়াত খুলে প্রথম এন্ট্রি যোগ করুন', 'ha': "Babu kome tukuna — buɗe kowace aya ka ƙara shigarwarka ta farko",
    'so': 'Weli waxba ma jiraan — fur aayad kasta oo ku dar gelitaankaaga koowaad', 'fa': 'هنوز چیزی نیست — هر آیه‌ای را باز کن و اولین ورودی‌ات را اضافه کن',
    'ms': 'Belum ada apa-apa — buka mana-mana ayat dan tambah entri pertama anda',
  },
  'quran_notebook_sort_recent': {
    'ar': 'الأحدث', 'en': 'Most recent', 'am': 'የቅርብ ጊዜ', 'fr': "Le plus récent", 'sw': 'Za hivi karibuni',
    'ur': 'حالیہ', 'tr': 'En yeni', 'id': 'Terbaru', 'bn': 'সাম্প্রতিকতম', 'ha': "Mafi kwanan nan",
    'so': 'Kuwa ugu dambeeyay', 'fa': 'جدیدترین', 'ms': 'Terkini',
  },
  'quran_notebook_sort_mushaf': {
    'ar': 'ترتيب المصحف', 'en': 'Mushaf order', 'am': 'የሙስሐፍ ቅደም ተከተል', 'fr': "Ordre du Mushaf", 'sw': 'Mpangilio wa Msahafu',
    'ur': 'ترتیبِ مصحف', 'tr': 'Mushaf sırası', 'id': 'Urutan mushaf', 'bn': 'মুসহাফ ক্রম', 'ha': "Tsarin Mushaf",
    'so': 'Nidaamka Mushafka', 'fa': 'ترتیب مصحف', 'ms': 'Susunan mushaf',
  },
  'quran_notebook_sort_richest': {
    'ar': 'الآيات الأكثر ثراءً', 'en': 'Richest ayat', 'am': 'እጅግ የበለጸጉ አንቀጾች', 'fr': "Versets les plus riches", 'sw': 'Aya zenye maudhui mengi zaidi',
    'ur': 'سب سے زیادہ مواد والی آیات', 'tr': 'En zengin ayetler', 'id': 'Ayat terkaya', 'bn': 'সবচেয়ে সমৃদ্ধ আয়াত', 'ha': "Ayoyi mafi wadata",
    'so': 'Aayadaha ugu hodanka badan', 'fa': 'غنی‌ترین آیات', 'ms': 'Ayat terkaya',
  },
  // ---- Semantic Mushaf reader (79-mushaf)
  'mushaf_semantic_title': {
    'ar': 'المصحف الدلالي', 'en': 'Semantic Mushaf', 'am': 'የፍቺ ሙስሐፍ', 'fr': 'Mushaf sémantique', 'sw': 'Msahafu wa kimaana',
    'ur': 'دلالتی مصحف', 'tr': 'Anlamsal Mushaf', 'id': 'Mushaf semantik', 'bn': 'অর্থবাহী মুসহাফ', 'ha': 'Mushaf mai ma’ana',
    'so': 'Mushaf macne leh', 'fa': 'مصحف معنایی', 'ms': 'Mushaf semantik',
  },
  'mushaf_semantic_subtitle': {
    'ar': 'تصفّح صفحات المصحف كلها، والمس أي كلمة لتعرف موضعها الكامل', 'en': 'Browse all Mushaf pages; tap any word to see its full location',
    'am': 'ሁሉንም የሙስሐፍ ገጾች ያስሱ፤ ሙሉ ቦታውን ለማየት ማንኛውንም ቃል ይንኩ', 'fr': 'Parcourez toutes les pages du Mushaf ; touchez un mot pour voir sa position complète',
    'sw': 'Vinjari kurasa zote za Msahafu; gusa neno lolote uone mahali pake kamili', 'ur': 'مصحف کے تمام صفحات دیکھیں؛ کسی بھی لفظ کو چھو کر اس کا مکمل مقام جانیں',
    'tr': 'Tüm Mushaf sayfalarına göz atın; tam konumunu görmek için herhangi bir kelimeye dokunun', 'id': 'Jelajahi semua halaman Mushaf; ketuk kata mana pun untuk melihat letak lengkapnya',
    'bn': 'মুসহাফের সব পৃষ্ঠা দেখুন; যেকোনো শব্দে চাপ দিয়ে তার পূর্ণ অবস্থান জানুন', 'ha': 'Binciko dukkan shafukan Mushaf; taɓa kowace kalma don ganin cikakken wurinta',
    'so': 'Fiiri dhammaan bogagga Mushafka; taabo erey kasta si aad u aragto meesha buuxda ee uu ku yaal', 'fa': 'همه صفحات مصحف را مرور کنید؛ روی هر کلمه بزنید تا موقعیت کامل آن را ببینید',
    'ms': 'Layari semua halaman Mushaf; ketik mana-mana perkataan untuk melihat kedudukan penuhnya',
  },
  'mushaf_beta_badge': {
    'ar': 'تجريبي', 'en': 'Beta', 'am': 'ሙከራ', 'fr': 'Bêta', 'sw': 'Jaribio',
    'ur': 'آزمائشی', 'tr': 'Beta', 'id': 'Beta', 'bn': 'বেটা', 'ha': 'Gwaji',
    'so': 'Tijaabo', 'fa': 'آزمایشی', 'ms': 'Beta',
  },
  'mushaf_word_label': {
    'ar': 'الكلمة', 'en': 'Word', 'am': 'ቃል', 'fr': 'Mot', 'sw': 'Neno',
    'ur': 'لفظ', 'tr': 'Kelime', 'id': 'Kata', 'bn': 'শব্দ', 'ha': 'Kalma',
    'so': 'Erey', 'fa': 'کلمه', 'ms': 'Perkataan',
  },
  'mushaf_surah_label': {
    'ar': 'السورة', 'en': 'Surah', 'am': 'ሱራ', 'fr': 'Sourate', 'sw': 'Sura',
    'ur': 'سورت', 'tr': 'Sûre', 'id': 'Surah', 'bn': 'সূরা', 'ha': 'Sura',
    'so': 'Suurad', 'fa': 'سوره', 'ms': 'Surah',
  },
  'mushaf_position_label': {
    'ar': 'الموضع', 'en': 'Position', 'am': 'ቦታ', 'fr': 'Position', 'sw': 'Nafasi',
    'ur': 'مقام', 'tr': 'Konum', 'id': 'Posisi', 'bn': 'অবস্থান', 'ha': 'Wuri',
    'so': 'Meel', 'fa': 'موقعیت', 'ms': 'Kedudukan',
  },
  'mushaf_line_label': {
    'ar': 'السطر', 'en': 'Line', 'am': 'መስመር', 'fr': 'Ligne', 'sw': 'Mstari',
    'ur': 'سطر', 'tr': 'Satır', 'id': 'Baris', 'bn': 'পঙক্তি', 'ha': 'Layi',
    'so': 'Sadar', 'fa': 'خط', 'ms': 'Baris',
  },
  'mushaf_word_order_label': {
    'ar': 'ترتيب الكلمة في الآية', 'en': 'Word order in ayah', 'am': 'በአንቀጹ ውስጥ የቃሉ ቅደም ተከተል', 'fr': 'Rang du mot dans le verset', 'sw': 'Mpangilio wa neno katika aya',
    'ur': 'آیت میں لفظ کی ترتیب', 'tr': 'Ayette kelimenin sırası', 'id': 'Urutan kata dalam ayat', 'bn': 'আয়াতে শব্দের ক্রম', 'ha': 'Jerin kalma a cikin aya',
    'so': 'Kala horreynta ereyga aayadda', 'fa': 'ترتیب کلمه در آیه', 'ms': 'Susunan perkataan dalam ayat',
  },
  'mushaf_open_ayah_notebook': {
    'ar': 'دفتري لهذه الآية', 'en': 'My notebook for this ayah', 'am': 'ለዚህ አንቀጽ ማስታወሻዬ', 'fr': 'Mon carnet pour ce verset', 'sw': 'Daftari langu la aya hii',
    'ur': 'اس آیت کے لیے میری نوٹ بک', 'tr': 'Bu ayet için defterim', 'id': 'Buku catatan saya untuk ayat ini', 'bn': 'এই আয়াতের জন্য আমার নোটবুক', 'ha': 'Littafina na wannan aya',
    'so': 'Buuggayga aayaddan', 'fa': 'دفترچه من برای این آیه', 'ms': 'Buku nota saya untuk ayat ini',
  },
  'mushaf_go_to_page': {
    'ar': 'اذهب إلى صفحة', 'en': 'Go to page', 'am': 'ወደ ገጽ ሂድ', 'fr': 'Aller à la page', 'sw': 'Nenda ukurasa',
    'ur': 'صفحہ پر جائیں', 'tr': 'Sayfaya git', 'id': 'Ke halaman', 'bn': 'পৃষ্ঠায় যান', 'ha': 'Je shafi',
    'so': 'Aad bogga', 'fa': 'رفتن به صفحه', 'ms': 'Pergi ke halaman',
  },
  'mushaf_not_ready': {
    'ar': 'لم تُجهَّز طبقة المصحف بعد — حاول بعد قليل', 'en': 'The Mushaf layer isn’t ready yet — try again shortly',
    'am': 'የሙስሐፍ ንብርብር ገና አልተዘጋጀም — ከጥቂት ጊዜ በኋላ ይሞክሩ', 'fr': 'La couche Mushaf n’est pas encore prête — réessayez bientôt',
    'sw': 'Safu ya Msahafu haijawa tayari — jaribu tena baadaye kidogo', 'ur': 'مصحف کی پرت ابھی تیار نہیں — تھوڑی دیر بعد کوشش کریں',
    'tr': 'Mushaf katmanı henüz hazır değil — birazdan tekrar deneyin', 'id': 'Lapisan Mushaf belum siap — coba lagi sebentar',
    'bn': 'মুসহাফ স্তর এখনও প্রস্তুত নয় — একটু পরে চেষ্টা করুন', 'ha': 'Sashen Mushaf bai shirya ba tukuna — sake gwadawa nan da nan',
    'so': 'Lakabka Mushafku weli diyaar ma aha — isku day mar kale wax yar ka dib', 'fa': 'لایه مصحف هنوز آماده نیست — کمی بعد دوباره تلاش کنید',
    'ms': 'Lapisan Mushaf belum sedia — cuba sebentar lagi',
  },
  'mushaf_word_type_juz_star': {
    'ar': 'علامة ربع الحزب', 'en': 'Rub‘ el-hizb mark', 'am': 'የሩብዕ ሒዝብ ምልክት', 'fr': 'Marque de rub‘ el-hizb', 'sw': 'Alama ya robo ya hizb',
    'ur': 'ربع حزب کا نشان', 'tr': 'Rub‘u’l-hizb işareti', 'id': 'Tanda rub‘ el-hizb', 'bn': 'রুবউল হিজব চিহ্ন', 'ha': 'Alamar rub‘ el-hizb',
    'so': 'Calaamadda rubuc-xisbi', 'fa': 'نشان ربع حزب', 'ms': 'Tanda rub‘ el-hizb',
  },
  'mushaf_word_type_sajda': {
    'ar': 'موضع سجدة تلاوة', 'en': 'Recitation sajdah', 'am': 'የቅራአት ሱጁድ ቦታ', 'fr': 'Prosternation de récitation', 'sw': 'Sijda ya kisomo',
    'ur': 'سجدۂ تلاوت', 'tr': 'Tilavet secdesi', 'id': 'Sajdah tilawah', 'bn': 'তিলাওয়াতের সিজদা', 'ha': 'Sujadar karatu',
    'so': 'Sujuudda akhriska', 'fa': 'سجده تلاوت', 'ms': 'Sujud tilawah',
  },
  // ---- Quran Learning Layer (79-ql) — ar + en now; other langs fall back to ar.
  'ql_lesson_title': {'ar': 'درس علمي', 'en': 'Lesson', 'am': 'ትምህርት', 'fr': 'Leçon', 'sw': 'Somo', 'ur': 'سبق', 'tr': 'Ders', 'id': 'Pelajaran', 'bn': 'পাঠ', 'ha': 'Darasi', 'so': 'Cashar', 'fa': 'درس', 'ms': 'Pelajaran'},
  'ql_lesson_stub': {'ar': 'درس هذا المفهوم قيد الإعداد — تظهر هنا الحقيقة الموثقة فقط.', 'en': 'This concept’s lesson is being prepared — only the sourced fact is shown here.', 'am': 'የዚህ ጽንሰ-ሐሳብ ትምህርት እየተዘጋጀ ነው — እዚህ የተረጋገጠ መረጃ ብቻ ይታያል።', 'fr': 'La leçon de ce concept est en préparation — seul le fait sourcé est montré ici.', 'sw': 'Somo la dhana hii linaandaliwa — hapa unaonyeshwa ukweli wenye chanzo pekee.', 'ur': 'اس تصور کا سبق تیار ہو رہا ہے — یہاں صرف مستند حقیقت دکھائی گئی ہے۔', 'tr': 'Bu kavramın dersi hazırlanıyor — burada yalnızca kaynaklı bilgi gösterilir.', 'id': 'Pelajaran konsep ini sedang disiapkan — hanya fakta bersumber yang ditampilkan di sini.', 'bn': 'এই ধারণার পাঠ প্রস্তুত হচ্ছে — এখানে কেবল উৎসসহ তথ্য দেখানো হয়েছে।', 'ha': 'Ana shirya darasin wannan ra’ayin — a nan ana nuna gaskiyar da ke da tushe kaɗai.', 'so': 'Casharka fikraddan waa la diyaarinayaa — halkan waxaa lagu tusayaa xaqiiqada isha leh kaliya.', 'fa': 'درس این مفهوم در حال آماده‌سازی است — تنها واقعیت مستند اینجا نشان داده می‌شود.', 'ms': 'Pelajaran konsep ini sedang disediakan — hanya fakta bersumber ditunjukkan di sini.'},
  'ql_block_short_def': {'ar': 'تعريف موجز', 'en': 'In brief', 'am': 'በአጭሩ', 'fr': 'En bref', 'sw': 'Kwa kifupi', 'ur': 'مختصراً', 'tr': 'Kısaca', 'id': 'Ringkasnya', 'bn': 'সংক্ষেপে', 'ha': 'A taƙaice', 'so': 'Kooban', 'fa': 'به‌طور خلاصه', 'ms': 'Ringkas'},
  'ql_block_definition': {'ar': 'التعريف / القاعدة', 'en': 'Definition / rule', 'am': 'ትርጓሜ / ደንብ', 'fr': 'Définition / règle', 'sw': 'Ufafanuzi / kanuni', 'ur': 'تعریف / قاعدہ', 'tr': 'Tanım / kural', 'id': 'Definisi / aturan', 'bn': 'সংজ্ঞা / নিয়ম', 'ha': 'Ma’ana / ƙa’ida', 'so': 'Qeexid / xeer', 'fa': 'تعریف / قاعده', 'ms': 'Definisi / peraturan'},
  'ql_block_explanation': {'ar': 'الشرح', 'en': 'Explanation', 'am': 'ማብራሪያ', 'fr': 'Explication', 'sw': 'Maelezo', 'ur': 'تشریح', 'tr': 'Açıklama', 'id': 'Penjelasan', 'bn': 'ব্যাখ্যা', 'ha': 'Bayani', 'so': 'Sharraxaad', 'fa': 'توضیح', 'ms': 'Penerangan'},
  'ql_block_example': {'ar': 'أمثلة', 'en': 'Examples', 'am': 'ምሳሌዎች', 'fr': 'Exemples', 'sw': 'Mifano', 'ur': 'مثالیں', 'tr': 'Örnekler', 'id': 'Contoh', 'bn': 'উদাহরণ', 'ha': 'Misalai', 'so': 'Tusaalooyin', 'fa': 'مثال‌ها', 'ms': 'Contoh'},
  'ql_block_quranic_example': {'ar': 'أمثلة قرآنية', 'en': 'Quranic examples', 'am': 'ቁርኣናዊ ምሳሌዎች', 'fr': 'Exemples coraniques', 'sw': 'Mifano ya Kikurani', 'ur': 'قرآنی مثالیں', 'tr': 'Kur’ânî örnekler', 'id': 'Contoh Al-Qur’an', 'bn': 'কুরআনি উদাহরণ', 'ha': 'Misalan Alƙur’ani', 'so': 'Tusaalooyin Qur’aan', 'fa': 'مثال‌های قرآنی', 'ms': 'Contoh Al-Quran'},
  'ql_block_application': {'ar': 'التطبيق', 'en': 'Application', 'am': 'ተግባራዊነት', 'fr': 'Application', 'sw': 'Matumizi', 'ur': 'اطلاق / عمل', 'tr': 'Uygulama', 'id': 'Penerapan', 'bn': 'প্রয়োগ', 'ha': 'Aiwatarwa', 'so': 'Dabbaqid', 'fa': 'کاربرد', 'ms': 'Penerapan'},
  'ql_block_note': {'ar': 'ملاحظة', 'en': 'Note', 'am': 'ማስታወሻ', 'fr': 'Note', 'sw': 'Dokezo', 'ur': 'نوٹ', 'tr': 'Not', 'id': 'Catatan', 'bn': 'নোট', 'ha': 'Bayani', 'so': 'Qoraal', 'fa': 'یادداشت', 'ms': 'Nota'},
  'ql_add_to_notebook': {'ar': 'أضف إلى دفتري', 'en': 'Add to my notebook', 'am': 'ወደ ማስታወሻዬ አክል', 'fr': 'Ajouter à mon carnet', 'sw': 'Ongeza kwenye daftari langu', 'ur': 'میری نوٹ بک میں شامل کریں', 'tr': 'Defterime ekle', 'id': 'Tambahkan ke buku catatan saya', 'bn': 'আমার নোটবুকে যোগ করুন', 'ha': 'Ƙara cikin littafina', 'so': 'Ku dar buuggayga', 'fa': 'به دفترچه‌ام افزودن', 'ms': 'Tambah ke buku nota saya'},
  'ql_apply_in_quran': {'ar': 'طبّق ما تعلمت في القرآن', 'en': 'Apply what you learned in the Quran', 'am': 'የተማርከውን በቁርኣን ተግብር', 'fr': 'Appliquez ce que vous avez appris dans le Coran', 'sw': 'Tumia uliyojifunza katika Qur’an', 'ur': 'جو سیکھا اسے قرآن میں لاگو کریں', 'tr': 'Öğrendiğini Kur’an’da uygula', 'id': 'Terapkan yang kamu pelajari di Al-Qur’an', 'bn': 'যা শিখেছ তা কুরআনে প্রয়োগ কর', 'ha': 'Yi amfani da abin da ka koya a cikin Alƙur’ani', 'so': 'Ku dabbaq wixii aad baratay Qur’aanka', 'fa': 'آنچه آموختی در قرآن به‌کار ببر', 'ms': 'Terapkan apa yang dipelajari dalam Al-Quran'},
  'ql_sources': {'ar': 'المصادر', 'en': 'Sources', 'am': 'ምንጮች', 'fr': 'Sources', 'sw': 'Vyanzo', 'ur': 'مآخذ', 'tr': 'Kaynaklar', 'id': 'Sumber', 'bn': 'সূত্র', 'ha': 'Majiya', 'so': 'Ilo', 'fa': 'منابع', 'ms': 'Sumber'},
  'ql_irab_title': {'ar': 'إعراب الآية', 'en': 'Iʿrāb of the ayah', 'am': 'የአንቀጹ ኢዕራብ', 'fr': 'Iʿrāb du verset', 'sw': 'Iʿrāb ya aya', 'ur': 'آیت کا اعراب', 'tr': 'Âyetin i‘râbı', 'id': 'I‘rab ayat', 'bn': 'আয়াতের ইরাব', 'ha': 'I‘rabin aya', 'so': 'I‘raabka aayadda', 'fa': 'اعراب آیه', 'ms': 'I‘rab ayat'},
  'ql_no_verified_data': {'ar': 'لا توجد بيانات موثقة لهذا الموضع حاليًا.', 'en': 'No verified data for this spot yet.', 'am': 'ለዚህ ቦታ የተረጋገጠ መረጃ ገና የለም።', 'fr': 'Aucune donnée vérifiée pour cet endroit pour l’instant.', 'sw': 'Bado hakuna data iliyothibitishwa kwa nafasi hii.', 'ur': 'اس مقام کے لیے ابھی کوئی مستند معلومات نہیں۔', 'tr': 'Bu konum için henüz doğrulanmış veri yok.', 'id': 'Belum ada data terverifikasi untuk bagian ini.', 'bn': 'এই স্থানের জন্য এখনও যাচাইকৃত তথ্য নেই।', 'ha': 'Babu tabbatattun bayanai don wannan wuri tukuna.', 'so': 'Weli xog la xaqiijiyay uma jirto meeshan.', 'fa': 'هنوز داده تأییدشده‌ای برای این جایگاه نیست.', 'ms': 'Belum ada data disahkan untuk tempat ini.'},
  'ql_no_verified_data_short': {'ar': 'لا بيانات موثقة بعد', 'en': 'no verified data yet', 'am': 'ገና የተረጋገጠ መረጃ የለም', 'fr': 'pas encore de données vérifiées', 'sw': 'bado hakuna data', 'ur': 'ابھی مستند معلومات نہیں', 'tr': 'henüz doğrulanmış veri yok', 'id': 'belum ada data terverifikasi', 'bn': 'যাচাইকৃত তথ্য নেই', 'ha': 'babu tabbatattun bayanai tukuna', 'so': 'weli xog la xaqiijiyay ma jirto', 'fa': 'هنوز داده تأییدشده نیست', 'ms': 'belum ada data disahkan'},
  'ql_available': {'ar': 'متاح', 'en': 'available', 'am': 'ይገኛል', 'fr': 'disponible', 'sw': 'inapatikana', 'ur': 'دستیاب', 'tr': 'mevcut', 'id': 'tersedia', 'bn': 'উপলব্ধ', 'ha': 'akwai', 'so': 'la heli karo', 'fa': 'در دسترس', 'ms': 'tersedia'},
  'ql_role': {'ar': 'الوظيفة النحوية', 'en': 'Grammatical role', 'am': 'ሰዋሰዋዊ ሚና', 'fr': 'Rôle grammatical', 'sw': 'Nafasi ya kisarufi', 'ur': 'نحوی حیثیت', 'tr': 'Dilbilgisel işlev', 'id': 'Peran gramatikal', 'bn': 'ব্যাকরণগত ভূমিকা', 'ha': 'Matsayin nahawu', 'so': 'Doorka naxwaha', 'fa': 'نقش نحوی', 'ms': 'Peranan tatabahasa'},
  'ql_sign': {'ar': 'العلامة الإعرابية', 'en': 'Case sign', 'am': 'የኢዕራብ ምልክት', 'fr': 'Signe de cas', 'sw': 'Alama ya i‘rāb', 'ur': 'علامتِ اعراب', 'tr': 'İ‘rab işareti', 'id': 'Tanda i‘rab', 'bn': 'ইরাবের চিহ্ন', 'ha': 'Alamar i‘rab', 'so': 'Calaamadda i‘raabka', 'fa': 'نشانه اعرابی', 'ms': 'Tanda i‘rab'},
  'ql_why': {'ar': 'لماذا أُعربت هكذا؟', 'en': 'Why is it parsed this way?', 'am': 'ለምን እንዲህ ተመረመረ?', 'fr': 'Pourquoi est-ce analysé ainsi ?', 'sw': 'Kwa nini imefanywa i‘rāb hivi?', 'ur': 'ایسا اعراب کیوں؟', 'tr': 'Neden böyle i‘rab edildi?', 'id': 'Mengapa di-i‘rab begini?', 'bn': 'কেন এভাবে ইরাব?', 'ha': 'Me ya sa aka yi i‘rab haka?', 'so': 'Muxuu sidan u i‘raaban?', 'fa': 'چرا این‌گونه اعراب شده؟', 'ms': 'Mengapa di-i‘rab begini?'},
  'ql_pron_effect': {'ar': 'أثر العلامة في النطق:', 'en': 'Effect on pronunciation:', 'am': 'በአነባበብ ላይ ያለው ተጽዕኖ፦', 'fr': 'Effet sur la prononciation :', 'sw': 'Athari kwenye matamshi:', 'ur': 'تلفظ پر اثر:', 'tr': 'Telaffuza etkisi:', 'id': 'Pengaruh pada pengucapan:', 'bn': 'উচ্চারণে প্রভাব:', 'ha': 'Tasiri kan furuci:', 'so': 'Saamaynta ku-dhufashada:', 'fa': 'تأثیر در تلفظ:', 'ms': 'Kesan pada sebutan:'},
  'ql_pron_hint': {'ar': 'استمع إلى الآية لتسمعها في موضعها', 'en': 'listen to the ayah to hear it in place', 'am': 'በቦታው ለመስማት አንቀጹን አዳምጥ', 'fr': 'écoutez le verset pour l’entendre en contexte', 'sw': 'sikiliza aya ili uisikie mahali pake', 'ur': 'آیت سنیں تاکہ اسے اپنی جگہ سنیں', 'tr': 'yerinde duymak için âyeti dinleyin', 'id': 'dengarkan ayat untuk mendengarnya pada tempatnya', 'bn': 'স্থানে শুনতে আয়াতটি শুনুন', 'ha': 'saurari aya don jinsa a wurinsa', 'so': 'dhagayso aayadda si aad meesheeda uga maqasho', 'fa': 'آیه را بشنوید تا در جای خود بشنوید', 'ms': 'dengar ayat untuk mendengarnya pada tempatnya'},
  'ql_listen': {'ar': 'استماع', 'en': 'Listen', 'am': 'አዳምጥ', 'fr': 'Écouter', 'sw': 'Sikiliza', 'ur': 'سنیں', 'tr': 'Dinle', 'id': 'Dengar', 'bn': 'শুনুন', 'ha': 'Saurara', 'so': 'Dhagayso', 'fa': 'گوش‌دادن', 'ms': 'Dengar'},
  'ql_relations': {'ar': 'علاقتها بما حولها (اضغط لإبراز الكلمة المرتبطة)', 'en': 'Relations (tap to highlight the linked word)', 'am': 'ግንኙነቶች (የተያያዘውን ቃል ለማጉላት ንካ)', 'fr': 'Relations (touchez pour surligner le mot lié)', 'sw': 'Uhusiano (gusa kuangazia neno lililohusishwa)', 'ur': 'تعلقات (منسلک لفظ نمایاں کرنے کے لیے دبائیں)', 'tr': 'İlişkiler (bağlı kelimeyi vurgulamak için dokun)', 'id': 'Relasi (ketuk untuk menyorot kata terkait)', 'bn': 'সম্পর্ক (যুক্ত শব্দ হাইলাইট করতে চাপুন)', 'ha': 'Alaƙa (danna don haskaka kalmar mai alaƙa)', 'so': 'Xiriirrada (taabo si aad u iftiimiso ereyga la xiriira)', 'fa': 'روابط (برای برجسته‌سازی واژهٔ مرتبط بزنید)', 'ms': 'Hubungan (ketik untuk serlahkan perkataan berkait)'},
  'ql_learn_this': {'ar': 'تعلّم هذا', 'en': 'Learn this', 'am': 'ይህን ተማር', 'fr': 'Apprendre ceci', 'sw': 'Jifunze hili', 'ur': 'یہ سیکھیں', 'tr': 'Bunu öğren', 'id': 'Pelajari ini', 'bn': 'এটি শিখুন', 'ha': 'Koyi wannan', 'so': 'Baro tan', 'fa': 'این را بیاموز', 'ms': 'Pelajari ini'},
  'ql_source': {'ar': 'المصدر', 'en': 'Source', 'am': 'ምንጭ', 'fr': 'Source', 'sw': 'Chanzo', 'ur': 'ماخذ', 'tr': 'Kaynak', 'id': 'Sumber', 'bn': 'সূত্র', 'ha': 'Majiya', 'so': 'Isha', 'fa': 'منبع', 'ms': 'Sumber'},
  'ql_domain_nahw': {'ar': 'النحو والإعراب', 'en': 'Grammar & iʿrāb', 'am': 'ሰዋሰውና ኢዕራብ', 'fr': 'Grammaire et iʿrāb', 'sw': 'Nahwu na iʿrāb', 'ur': 'نحو و اعراب', 'tr': 'Nahiv ve i‘rab', 'id': 'Nahwu & i‘rab', 'bn': 'নাহু ও ইরাব', 'ha': 'Nahawu da i‘rab', 'so': 'Naxwa & i‘raab', 'fa': 'نحو و اعراب', 'ms': 'Nahu & i‘rab'},
  'ql_domain_sarf': {'ar': 'الصرف', 'en': 'Morphology', 'am': 'ሰርፍ (ቅርጸ-ቃል)', 'fr': 'Morphologie', 'sw': 'Sarfu', 'ur': 'صرف', 'tr': 'Sarf (yapıbilgisi)', 'id': 'Saraf (morfologi)', 'bn': 'সরফ (রূপতত্ত্ব)', 'ha': 'Sarfi', 'so': 'Sarfi', 'fa': 'صرف', 'ms': 'Saraf (morfologi)'},
  'ql_domain_tajweed': {'ar': 'التجويد', 'en': 'Tajwīd', 'am': 'ተጅዊድ', 'fr': 'Tajwīd', 'sw': 'Tajwidi', 'ur': 'تجوید', 'tr': 'Tecvid', 'id': 'Tajwid', 'bn': 'তাজবিদ', 'ha': 'Tajweed', 'so': 'Tajwiid', 'fa': 'تجوید', 'ms': 'Tajwid'},
  'ql_open_lesson': {'ar': 'الدرس', 'en': 'Lesson', 'am': 'ትምህርት', 'fr': 'Leçon', 'sw': 'Somo', 'ur': 'سبق', 'tr': 'Ders', 'id': 'Pelajaran', 'bn': 'পাঠ', 'ha': 'Darasi', 'so': 'Casharka', 'fa': 'درس', 'ms': 'Pelajaran'},
  'mushaf_tajweed_legend': {'ar': 'تجويد', 'en': 'Tajwīd', 'am': 'ተጅዊድ', 'fr': 'Tajwīd', 'sw': 'Tajwidi', 'ur': 'تجوید', 'tr': 'Tecvid', 'id': 'Tajwid', 'bn': 'তাজবিদ', 'ha': 'Tajweed', 'so': 'Tajwiid', 'fa': 'تجوید', 'ms': 'Tajwid'},
  'mushaf_tajweed_legend_title': {'ar': 'ألوان التجويد', 'en': 'Tajwīd colours', 'am': 'የተጅዊድ ቀለማት', 'fr': 'Couleurs du tajwīd', 'sw': 'Rangi za tajwidi', 'ur': 'تجوید کے رنگ', 'tr': 'Tecvid renkleri', 'id': 'Warna tajwid', 'bn': 'তাজবিদ রঙ', 'ha': 'Launukan Tajweed', 'so': 'Midabbada Tajwiidka', 'fa': 'رنگ‌های تجوید', 'ms': 'Warna tajwid'},
  'ql_domain_tafsir': {'ar': 'التفسير', 'en': 'Tafsīr', 'am': 'ተፍሲር', 'fr': 'Tafsīr', 'sw': 'Tafsiri', 'ur': 'تفسیر', 'tr': 'Tefsir', 'id': 'Tafsir', 'bn': 'তাফসির', 'ha': 'Tafsiri', 'so': 'Tafsiir', 'fa': 'تفسیر', 'ms': 'Tafsir'},
  'ql_root': {'ar': 'الجذر', 'en': 'Root', 'am': 'ስር', 'fr': 'Racine', 'sw': 'Mzizi', 'ur': 'مادہ / جڑ', 'tr': 'Kök', 'id': 'Akar kata', 'bn': 'ধাতু', 'ha': 'Saiwar kalma', 'so': 'Xidid', 'fa': 'ریشه', 'ms': 'Akar kata'},
  'ql_pattern': {'ar': 'الوزن', 'en': 'Pattern', 'am': 'ንድፍ (ወዝን)', 'fr': 'Schème', 'sw': 'Mwazani', 'ur': 'وزن', 'tr': 'Vezin', 'id': 'Wazan / pola', 'bn': 'ওজন', 'ha': 'Awo (wazan)', 'so': 'Miisaan', 'fa': 'وزن', 'ms': 'Wazan / pola'},
  'ql_lemma': {'ar': 'المادّة', 'en': 'Lemma', 'am': 'ቃል-መሠረት', 'fr': 'Lemme', 'sw': 'Neno-msingi', 'ur': 'بنیادی لفظ', 'tr': 'Sözcük kökü', 'id': 'Lema', 'bn': 'মূলশব্দ', 'ha': 'Kalmar tushe', 'so': 'Ereyga aasaasiga', 'fa': 'واژهٔ پایه', 'ms': 'Perkataan asas'},
  // ---- Knowledge Surfaces (خطة القارئ الموحّد P0) — ar + en; other langs fall back to ar.
  'ql_word': {'ar': 'الكلمة', 'en': 'Word', 'am': 'ቃል', 'fr': 'Mot', 'sw': 'Neno', 'ur': 'لفظ', 'tr': 'Kelime', 'id': 'Kata', 'bn': 'শব্দ', 'ha': 'Kalma', 'so': 'Erey', 'fa': 'واژه', 'ms': 'Perkataan'},
  'ql_details': {'ar': 'التفاصيل', 'en': 'Details', 'am': 'ዝርዝሮች', 'fr': 'Détails', 'sw': 'Maelezo zaidi', 'ur': 'تفصیلات', 'tr': 'Ayrıntılar', 'id': 'Rincian', 'bn': 'বিস্তারিত', 'ha': 'Cikakkun bayanai', 'so': 'Faahfaahin', 'fa': 'جزئیات', 'ms': 'Butiran'},
  'ql_top_relation': {'ar': 'أبرز علاقة نحوية', 'en': 'Key grammatical relation', 'am': 'ዋና ሰዋሰዋዊ ግንኙነት', 'fr': 'Relation grammaticale clé', 'sw': 'Uhusiano mkuu wa kisarufi', 'ur': 'اہم نحوی تعلق', 'tr': 'Temel dilbilgisel ilişki', 'id': 'Relasi gramatikal utama', 'bn': 'প্রধান ব্যাকরণগত সম্পর্ক', 'ha': 'Muhimmiyar alaƙar nahawu', 'so': 'Xiriirka naxwe ee muhiimka ah', 'fa': 'رابطهٔ نحوی کلیدی', 'ms': 'Hubungan tatabahasa utama'},
  'ql_related_tafsir': {'ar': 'التفسير المرتبط', 'en': 'Related tafsīr', 'am': 'ተዛማጅ ተፍሲር', 'fr': 'Tafsīr associé', 'sw': 'Tafsiri inayohusiana', 'ur': 'متعلقہ تفسیر', 'tr': 'İlgili tefsir', 'id': 'Tafsir terkait', 'bn': 'সম্পর্কিত তাফসির', 'ha': 'Tafsirin da ya danganta', 'so': 'Tafsiirka la xiriira', 'fa': 'تفسیر مرتبط', 'ms': 'Tafsir berkaitan'},
  'ql_interactive_irab': {'ar': 'الإعراب التفاعلي', 'en': 'Interactive iʿrāb', 'am': 'መስተጋባራዊ ኢዕራብ', 'fr': 'Iʿrāb interactif', 'sw': 'Iʿrāb shirikishi', 'ur': 'متعامل اعراب', 'tr': 'Etkileşimli i‘rab', 'id': 'I‘rab interaktif', 'bn': 'ইন্টারঅ্যাক্টিভ ইরাব', 'ha': 'I‘rab mai hulɗa', 'so': 'I‘raab is-dhexgal ah', 'fa': 'اعراب تعاملی', 'ms': 'I‘rab interaktif'},
  'ql_no_data_element': {
    'ar': 'لا توجد بيانات موثقة لهذا العنصر حاليًا.', 'en': 'No verified data for this element yet.',
    'am': 'ለዚህ አካል የተረጋገጠ መረጃ ገና የለም።', 'fr': 'Aucune donnée vérifiée pour cet élément pour l’instant.',
    'sw': 'Bado hakuna data iliyothibitishwa kwa kipengele hiki.', 'ur': 'اس عنصر کے لیے ابھی کوئی مستند معلومات نہیں۔',
    'tr': 'Bu öğe için henüz doğrulanmış veri yok.', 'id': 'Belum ada data terverifikasi untuk elemen ini.',
    'bn': 'এই উপাদানের জন্য এখনও যাচাইকৃত তথ্য নেই।', 'ha': 'Babu tabbatattun bayanai don wannan sinadari tukuna.',
    'so': 'Weli xog la xaqiijiyay uma jirto curiyahan.', 'fa': 'هنوز داده تأییدشده‌ای برای این عنصر نیست.',
    'ms': 'Belum ada data disahkan untuk elemen ini.',
  },
  'ql_ayah_learn_q': {
    'ar': 'ماذا أتعلم من هذه الآية؟', 'en': 'What can I learn from this ayah?',
    'am': 'ከዚህ አንቀጽ ምን እማራለሁ?', 'fr': 'Que puis-je apprendre de ce verset ?',
    'sw': 'Ninaweza kujifunza nini kutoka aya hii?', 'ur': 'اس آیت سے میں کیا سیکھ سکتا ہوں؟',
    'tr': 'Bu âyetten ne öğrenebilirim?', 'id': 'Apa yang bisa kupelajari dari ayat ini?',
    'bn': 'এই আয়াত থেকে আমি কী শিখতে পারি?', 'ha': 'Me zan iya koya daga wannan aya?',
    'so': 'Maxaan ka baran karaa aayaddan?', 'fa': 'از این آیه چه می‌آموزم؟',
    'ms': 'Apa yang boleh saya pelajari daripada ayat ini?',
  },
  'ql_translation': {'ar': 'الترجمة', 'en': 'Translation', 'am': 'ትርጉም', 'fr': 'Traduction', 'sw': 'Tafsiri (lugha)', 'ur': 'ترجمہ', 'tr': 'Çeviri', 'id': 'Terjemahan', 'bn': 'অনুবাদ', 'ha': 'Fassara', 'so': 'Turjumaad', 'fa': 'ترجمه', 'ms': 'Terjemahan'},
  'ql_related_sciences': {'ar': 'العلوم المرتبطة', 'en': 'Related sciences', 'am': 'ተዛማጅ ዕውቀቶች', 'fr': 'Sciences associées', 'sw': 'Elimu zinazohusiana', 'ur': 'متعلقہ علوم', 'tr': 'İlgili ilimler', 'id': 'Ilmu terkait', 'bn': 'সম্পর্কিত বিদ্যা', 'ha': 'Ilimomin da suka danganta', 'so': 'Cilmiyada la xiriira', 'fa': 'دانش‌های مرتبط', 'ms': 'Ilmu berkaitan'},
  'ql_full_tafsir': {'ar': 'التفسير كاملًا', 'en': 'Full tafsīr', 'am': 'ሙሉ ተፍሲር', 'fr': 'Tafsīr complet', 'sw': 'Tafsiri kamili', 'ur': 'مکمل تفسیر', 'tr': 'Tam tefsir', 'id': 'Tafsir lengkap', 'bn': 'সম্পূর্ণ তাফসির', 'ha': 'Cikakken tafsiri', 'so': 'Tafsiir dhameystiran', 'fa': 'تفسیر کامل', 'ms': 'Tafsir penuh'},
  'ql_read_page': {'ar': 'اقرأ في المصحف', 'en': 'Read on the mushaf', 'am': 'በሙስሐፍ አንብብ', 'fr': 'Lire dans le mushaf', 'sw': 'Soma katika msahafu', 'ur': 'مصحف میں پڑھیں', 'tr': 'Mushafta oku', 'id': 'Baca di mushaf', 'bn': 'মুসহাফে পড়ুন', 'ha': 'Karanta a cikin mushaf', 'so': 'Ku akhri mushafka', 'fa': 'در مصحف بخوان', 'ms': 'Baca dalam mushaf'},
  // ---- Knowledge Surface — Quran Corpus panels (QC3, corpus_panels.dart)
  'ql_word_sciences': {'ar': 'علوم الكلمة', 'en': 'Word sciences', 'am': 'የቃል ዕውቀቶች', 'fr': 'Sciences du mot', 'sw': 'Elimu za neno', 'ur': 'کلمے کے علوم', 'tr': 'Kelime ilimleri', 'id': 'Ilmu kata', 'bn': 'শব্দের বিদ্যা', 'ha': 'Ilimomin kalma', 'so': 'Cilmiga ereyga', 'fa': 'دانش‌های واژه', 'ms': 'Ilmu perkataan'},
  'ql_word_type': {'ar': 'نوع الكلمة', 'en': 'Word type', 'am': 'የቃል ዓይነት', 'fr': 'Type de mot', 'sw': 'Aina ya neno', 'ur': 'کلمے کی قسم', 'tr': 'Kelime türü', 'id': 'Jenis kata', 'bn': 'শব্দের প্রকার', 'ha': "Nau'in kalma", 'so': 'Nooca ereyga', 'fa': 'نوع واژه', 'ms': 'Jenis perkataan'},
  // KHATM_SYSTEM_AND_STYLE_REFERENCE.md §3 — the word panel's "المعنى" row,
  // the QAC per-word gloss (100% word coverage, distinct from the partial
  // gharib-word explanation shown separately below it).
  'ql_word_meaning': {'ar': 'المعنى', 'en': 'Meaning', 'am': 'ትርጉም', 'fr': 'Sens', 'sw': 'Maana', 'ur': 'معنی', 'tr': 'Anlam', 'id': 'Makna', 'bn': 'অর্থ', 'ha': 'Ma\'ana', 'so': 'Macnaha', 'fa': 'معنی', 'ms': 'Makna'},
  'ql_features': {'ar': 'السمات', 'en': 'Features', 'am': 'ባህሪያት', 'fr': 'Traits', 'sw': 'Sifa', 'ur': 'خصوصیات', 'tr': 'Özellikler', 'id': 'Ciri', 'bn': 'বৈশিষ্ট্য', 'ha': 'Sifofi', 'so': 'Sifooyin', 'fa': 'ویژگی‌ها', 'ms': 'Ciri'},
  'ql_word_structure': {'ar': 'بنية الكلمة', 'en': 'Word structure', 'am': 'የቃል አወቃቀር', 'fr': 'Structure du mot', 'sw': 'Muundo wa neno', 'ur': 'کلمے کی ساخت', 'tr': 'Kelime yapısı', 'id': 'Struktur kata', 'bn': 'শব্দ গঠন', 'ha': 'Tsarin kalma', 'so': 'Qaab-dhismeedka ereyga', 'fa': 'ساختار واژه', 'ms': 'Struktur perkataan'},
  'ql_iraab_syntax': {'ar': 'الإعراب النحوي (شجرة الإعراب)', 'en': 'Syntactic iʿrāb (treebank)', 'am': 'አገባባዊ ኢዕራብ', 'fr': 'Iʿrāb syntaxique (treebank)', 'sw': 'Iʿrāb ya kisintaksia', 'ur': 'نحوی اعراب (ٹری بینک)', 'tr': 'Sözdizimsel i‘rab (treebank)', 'id': 'I‘rab sintaksis (treebank)', 'bn': 'বাক্যতাত্ত্বিক ইরাব (ট্রিব্যাংক)', 'ha': 'I‘rab na jimla (treebank)', 'so': 'I‘raab naxwe (treebank)', 'fa': 'اعراب نحوی (تری‌بانک)', 'ms': 'I‘rab sintaksis (treebank)'},
  'ql_ghareeb_word': {'ar': 'غريب الكلمة', 'en': 'Rare-word meaning', 'am': 'የቃሉ ብርቅ ትርጉም', 'fr': 'Sens du mot rare', 'sw': 'Maana ya neno adimu', 'ur': 'کلمے کا غریب معنی', 'tr': 'Garîb kelime anlamı', 'id': 'Makna kata garib', 'bn': 'দুর্লভ শব্দের অর্থ', 'ha': "Ma'anar kalma mai wuya", 'so': 'Macnaha ereyga naadirka ah', 'fa': 'معنای واژهٔ غریب', 'ms': 'Makna perkataan garib'},
  'ql_ghareeb_ayah': {'ar': 'غريب الآية', 'en': 'Rare words in the ayah', 'am': 'የአንቀጹ ብርቅ ቃላት', 'fr': 'Mots rares du verset', 'sw': 'Maneno adimu katika aya', 'ur': 'آیت کے غریب الفاظ', 'tr': 'Âyetteki garîb kelimeler', 'id': 'Kata-kata garib dalam ayat', 'bn': 'আয়াতের দুর্লভ শব্দ', 'ha': 'Kalmomi masu wuya a cikin aya', 'so': 'Erayada naadirka ah ee aayadda', 'fa': 'واژه‌های غریب آیه', 'ms': 'Perkataan garib dalam ayat'},
  'ql_qiraat': {'ar': 'القراءات', 'en': 'Qirāʾāt (variant readings)', 'am': 'ቅርኣኣት (የንባብ ልዩነቶች)', 'fr': 'Qirāʾāt (lectures)', 'sw': 'Qirāʾāt (visomo)', 'ur': 'قراءات', 'tr': 'Kıraatler', 'id': 'Qiraat (ragam bacaan)', 'bn': 'কিরাআত (পাঠভেদ)', 'ha': 'Karatuttuka (qiraat)', 'so': 'Qiraaʾaat (akhris kala duwan)', 'fa': 'قراءات', 'ms': 'Qiraat (bacaan berbeza)'},
  'ql_readers': {'ar': 'الرواة', 'en': 'Readers', 'am': 'አንባቢዎች', 'fr': 'Transmetteurs', 'sw': 'Wasomaji', 'ur': 'راوی', 'tr': 'Râvîler', 'id': 'Perawi', 'bn': 'বর্ণনাকারী', 'ha': 'Marawaita', 'so': 'Aqristayaal', 'fa': 'راویان', 'ms': 'Perawi'},
  'ql_riwayat_section': {'ar': 'الروايات — نصّ الآية في كل قراءة', 'en': 'Riwāyāt — the ayah in each reading', 'am': 'ሪዋያዎች — አንቀጹ በእያንዳንዱ ንባብ', 'fr': 'Riwāyāt — le verset dans chaque lecture', 'sw': 'Riwāyāt — aya katika kila kisomo', 'ur': 'روایات — ہر قراءت میں آیت کا متن', 'tr': 'Rivayetler — âyetin her kıraattaki metni', 'id': 'Riwayat — teks ayat dalam tiap bacaan', 'bn': 'রিওয়ায়াত — প্রতিটি কিরাআতে আয়াতের পাঠ', 'ha': 'Riwayoyi — rubutun aya a kowace karatu', 'so': 'Riwaayadaha — qoraalka aayadda akhris kastaa', 'fa': 'روایات — متن آیه در هر قرائت', 'ms': 'Riwayat — teks ayat dalam setiap bacaan'},
  'ql_asbab': {'ar': 'سبب النزول', 'en': 'Occasion of revelation', 'am': 'የመውረድ ምክንያት', 'fr': 'Circonstances de la révélation', 'sw': 'Sababu ya kuteremshwa', 'ur': 'شانِ نزول', 'tr': 'Nüzul sebebi', 'id': 'Sebab turunnya ayat', 'bn': 'শানে নুযুল', 'ha': 'Dalilin saukar aya', 'so': 'Sababta soo-degista', 'fa': 'سبب نزول', 'ms': 'Sebab penurunan'},
  'ql_iraab_prose': {'ar': 'إعراب الآية من الكتب', 'en': 'Iʿrāb from the books', 'am': 'ከመጻሕፍት የተወሰደ ኢዕራብ', 'fr': "Iʿrāb d'après les ouvrages", 'sw': 'Iʿrāb kutoka vitabuni', 'ur': 'کتب سے آیت کا اعراب', 'tr': 'Kitaplardan i‘rab', 'id': 'I‘rab dari kitab', 'bn': 'গ্রন্থ থেকে ইরাব', 'ha': 'I‘rab daga littattafai', 'so': 'I‘raab kutubta laga soo qaatay', 'fa': 'اعراب آیه از کتاب‌ها', 'ms': 'I‘rab daripada kitab'},
  'ql_nasekh': {'ar': 'الناسخ والمنسوخ', 'en': 'Abrogating & abrogated', 'am': 'ናሲኽና መንሱኽ', 'fr': 'Abrogeant et abrogé', 'sw': 'Kufuta na kufutwa', 'ur': 'ناسخ و منسوخ', 'tr': 'Nâsih ve mensûh', 'id': 'Nasikh dan mansukh', 'bn': 'নাসিখ ও মানসূখ', 'ha': 'Nāsikh da mansūkh', 'so': 'Nāsikh iyo mansūkh', 'fa': 'ناسخ و منسوخ', 'ms': 'Nasikh dan mansukh'},
  'ql_faidah': {'ar': 'الفوائد والوقفات', 'en': 'Reflections & benefits', 'am': 'ጥቅሞችና ማሰላሰያዎች', 'fr': 'Réflexions et bénéfices', 'sw': 'Tafakari na faida', 'ur': 'فوائد و وقفات', 'tr': 'Faydalar ve tefekkürler', 'id': 'Faedah dan perenungan', 'bn': 'উপকারিতা ও অনুধ্যান', 'ha': "Fa'idodi da tsokaci", 'so': "Faa'idooyin iyo taammulo", 'fa': 'فوائد و وقفه‌ها', 'ms': 'Faedah dan renungan'},
  'ql_mutashabihat': {'ar': 'المتشابهات اللفظية', 'en': 'Similar wordings', 'am': 'ተመሳሳይ አገላለጾች', 'fr': 'Formulations similaires', 'sw': 'Maneno yanayofanana', 'ur': 'متشابہاتِ لفظی', 'tr': 'Benzer lafızlar (müteşâbih)', 'id': 'Kemiripan lafaz (mutasyabihat)', 'bn': 'সদৃশ শব্দবিন্যাস', 'ha': 'Kamance kalmomi', 'so': 'Isku-ekaanshaha lafdhiga', 'fa': 'متشابهات لفظی', 'ms': 'Persamaan lafaz'},
  'ql_athar': {'ar': 'الآثار وأقوال السلف', 'en': 'Reports of the Salaf', 'am': 'የሰለፎች ዘገባዎችና ንግግሮች', 'fr': 'Propos des anciens (Salaf)', 'sw': 'Athari na kauli za Salaf', 'ur': 'آثار و اقوالِ سلف', 'tr': "Selef'in rivayet ve sözleri", 'id': 'Atsar dan perkataan salaf', 'bn': 'সালাফের আসার ও উক্তি', 'ha': "Al'āthār da maganganun magabata", 'so': 'Aathaarta iyo hadalka Salafta', 'fa': 'آثار و اقوال سلف', 'ms': 'Athar dan kata-kata salaf'},
  'ql_narrators': {'ar': 'الرواة', 'en': 'Narrators', 'am': 'ዘጋቢዎች', 'fr': 'Rapporteurs', 'sw': 'Wapokezi', 'ur': 'راوی', 'tr': 'Râvîler', 'id': 'Perawi', 'bn': 'বর্ণনাকারী', 'ha': 'Marawaita', 'so': 'Weriyayaal', 'fa': 'راویان', 'ms': 'Perawi'},
  'ql_topics': {'ar': 'الموضوعات', 'en': 'Topics', 'am': 'ርዕሶች', 'fr': 'Thèmes', 'sw': 'Mada', 'ur': 'موضوعات', 'tr': 'Konular', 'id': 'Topik', 'bn': 'বিষয়', 'ha': 'Jigogi', 'so': 'Mowduucyada', 'fa': 'موضوعات', 'ms': 'Topik'},
  // ---- QC4 — Quran Knowledge Index (topic_index_screen.dart)
  'ql_topic_index_title': {'ar': 'فهرس الموضوعات القرآنية', 'en': 'Quran topic index', 'am': 'የቁርኣን ርዕሰ-ጉዳይ ማውጫ', 'fr': 'Index thématique du Coran', 'sw': 'Faharasa ya mada za Qur’an', 'ur': 'قرآنی موضوعات کی فہرست', 'tr': 'Kur’an konu dizini', 'id': 'Indeks topik Al-Qur’an', 'bn': 'কুরআনের বিষয়সূচি', 'ha': 'Ƙididdigar jigogin Alƙur’ani', 'so': 'Tusmada mowduucyada Qur’aanka', 'fa': 'نمایهٔ موضوعات قرآن', 'ms': 'Indeks topik Al-Quran'},
  'ql_topic_search_hint': {'ar': 'ابحث عن موضوع…', 'en': 'Search for a topic…', 'am': 'ርዕስ ፈልግ…', 'fr': 'Rechercher un thème…', 'sw': 'Tafuta mada…', 'ur': 'موضوع تلاش کریں…', 'tr': 'Konu ara…', 'id': 'Cari topik…', 'bn': 'বিষয় খুঁজুন…', 'ha': 'Nemi jigo…', 'so': 'Raadi mowduuc…', 'fa': 'جستجوی موضوع…', 'ms': 'Cari topik…'},
  'ql_topic_no_results': {'ar': 'لا توجد موضوعات مطابقة', 'en': 'No matching topics', 'am': 'ተመሳሳይ ርዕሶች የሉም', 'fr': 'Aucun thème correspondant', 'sw': 'Hakuna mada zinazolingana', 'ur': 'کوئی مماثل موضوع نہیں', 'tr': 'Eşleşen konu yok', 'id': 'Tidak ada topik yang cocok', 'bn': 'মিলে এমন কোনো বিষয় নেই', 'ha': 'Babu jigogin da suka dace', 'so': 'Ma jiraan mowduucyo u dhigma', 'fa': 'موضوع منطبقی یافت نشد', 'ms': 'Tiada topik sepadan'},
  'ql_topic_subtopics': {'ar': 'موضوعات فرعية', 'en': 'Sub-topics', 'am': 'ንዑስ ርዕሶች', 'fr': 'Sous-thèmes', 'sw': 'Mada ndogo', 'ur': 'ذیلی موضوعات', 'tr': 'Alt konular', 'id': 'Subtopik', 'bn': 'উপ-বিষয়', 'ha': 'Ƙananan jigogi', 'so': 'Mowduucyo hoosaad', 'fa': 'زیرموضوع‌ها', 'ms': 'Subtopik'},
  'ql_topic_places': {'ar': 'مواضع الموضوع في القرآن', 'en': 'Places in the Quran', 'am': 'በቁርኣን ውስጥ ያሉ ስፍራዎች', 'fr': 'Occurrences dans le Coran', 'sw': 'Mahali katika Qur’an', 'ur': 'قرآن میں مقامات', 'tr': 'Kur’an’daki yerler', 'id': 'Tempat dalam Al-Qur’an', 'bn': 'কুরআনে স্থানসমূহ', 'ha': 'Wuraren cikin Alƙur’ani', 'so': 'Meelaha Qur’aanka', 'fa': 'جایگاه‌ها در قرآن', 'ms': 'Tempat dalam Al-Quran'},
  'ql_topic_ayah_word': {'ar': 'آية', 'en': 'ayah', 'am': 'አንቀጽ', 'fr': 'verset', 'sw': 'aya', 'ur': 'آیت', 'tr': 'âyet', 'id': 'ayat', 'bn': 'আয়াত', 'ha': 'aya', 'so': 'aayad', 'fa': 'آیه', 'ms': 'ayat'},
  // ---- QC5a — «عن المصادر» (sources_screen.dart)
  'ql_sources_screen_title': {'ar': 'عن المصادر', 'en': 'About the sources', 'am': 'ስለ ምንጮቹ', 'fr': 'À propos des sources', 'sw': 'Kuhusu vyanzo', 'ur': 'مآخذ کے بارے میں', 'tr': 'Kaynaklar hakkında', 'id': 'Tentang sumber', 'bn': 'সূত্র সম্পর্কে', 'ha': 'Game da majiyoyi', 'so': 'Ku saabsan ilaha', 'fa': 'دربارهٔ منابع', 'ms': 'Tentang sumber'},
  'ql_sources_quran_text': {'ar': 'نصّ القرآن', 'en': 'Quran text', 'am': 'የቁርኣን ጽሑፍ', 'fr': 'Texte du Coran', 'sw': 'Matni ya Qur’an', 'ur': 'قرآنی متن', 'tr': 'Kur’an metni', 'id': 'Teks Al-Qur’an', 'bn': 'কুরআনের মূল পাঠ', 'ha': 'Rubutun Alƙur’ani', 'so': 'Qoraalka Qur’aanka', 'fa': 'متن قرآن', 'ms': 'Teks Al-Quran'},
  'ql_sources_primary_text_note': {'ar': 'النص الأساسي — لا يُشتقّ من غيره ولا يُعدَّل', 'en': 'The primary text — never derived from anything else, never altered', 'am': 'ዋናው ጽሑፍ — ከሌላ አይወሰድም አይሻሻልም', 'fr': 'Le texte de référence — jamais dérivé ni modifié', 'sw': 'Matni ya msingi — haitokani na kingine wala haibadilishwi', 'ur': 'بنیادی متن — کسی اور سے اخذ نہیں، نہ تبدیل', 'tr': 'Ana metin — başka bir şeyden türetilmez, değiştirilmez', 'id': 'Teks utama — tidak diturunkan dari yang lain, tidak diubah', 'bn': 'মূল পাঠ — অন্য কিছু থেকে নেওয়া বা পরিবর্তিত নয়', 'ha': 'Rubutu na asali — ba a samo shi daga wani ba, ba a sauya shi', 'so': 'Qoraalka aasaasiga ah — laguma soo qaadan wax kale, lama beddelo', 'fa': 'متن اصلی — از چیزی گرفته یا تغییر داده نمی‌شود', 'ms': 'Teks utama — tidak diterbitkan daripada yang lain, tidak diubah'},
  'ql_sources_grammar': {'ar': 'الصرف والإعراب', 'en': 'Morphology & syntax', 'am': 'ሰርፍና ኢዕራብ', 'fr': 'Morphologie et syntaxe', 'sw': 'Sarfu na i‘rāb', 'ur': 'صرف و نحو', 'tr': 'Sarf ve i‘rab', 'id': 'Morfologi & sintaksis', 'bn': 'সরফ ও নাহু', 'ha': 'Sarfi da nahawu', 'so': 'Sarfi & naxwe', 'fa': 'صرف و نحو', 'ms': 'Morfologi & sintaksis'},
  'ql_sources_gpl_note': {'ar': 'يُضمَّن حرفيًا · الإحالة إلى corpus.quran.com واجبة', 'en': 'bundled verbatim · attribution + link to corpus.quran.com required', 'am': 'ቃል በቃል ተካቷል · ወደ corpus.quran.com ማጣቀሻ ግዴታ ነው', 'fr': 'inclus tel quel · attribution + lien vers corpus.quran.com obligatoires', 'sw': 'imejumuishwa kama ilivyo · rejeleo + kiungo cha corpus.quran.com kinahitajika', 'ur': 'من و عن شامل · corpus.quran.com کا حوالہ لازم', 'tr': 'aynen dâhil · corpus.quran.com’a atıf + bağlantı zorunlu', 'id': 'disertakan apa adanya · atribusi + tautan corpus.quran.com wajib', 'bn': 'হুবহু অন্তর্ভুক্ত · corpus.quran.com-এর উল্লেখ ও লিংক আবশ্যক', 'ha': 'an haɗa kai tsaye · ana buƙatar ambato + hanyar corpus.quran.com', 'so': 'sida ay tahay ayaa lagu daray · tixraac + xiriirka corpus.quran.com waa waajib', 'fa': 'بی‌کم‌وکاست گنجانده شده · ارجاع و پیوند به corpus.quran.com الزامی', 'ms': 'disertakan sepenuhnya · atribusi + pautan corpus.quran.com diwajibkan'},
  'ql_sources_tafsir': {'ar': 'التفاسير', 'en': 'Tafsīrs', 'am': 'ተፍሲሮች', 'fr': 'Tafsīrs', 'sw': 'Tafsiri', 'ur': 'تفاسیر', 'tr': 'Tefsirler', 'id': 'Tafsir', 'bn': 'তাফসিরসমূহ', 'ha': 'Tafsirori', 'so': 'Tafsiirrada', 'fa': 'تفاسیر', 'ms': 'Tafsir'},
  'ql_sources_bundled': {'ar': 'مضمّن', 'en': 'bundled', 'am': 'የተካተተ', 'fr': 'inclus', 'sw': 'imejumuishwa', 'ur': 'شامل', 'tr': 'dâhil', 'id': 'disertakan', 'bn': 'অন্তর্ভুক্ত', 'ha': 'an haɗa', 'so': 'ku jira', 'fa': 'گنجانده‌شده', 'ms': 'disertakan'},
  'ql_sources_translations': {'ar': 'الترجمات', 'en': 'Translations', 'am': 'ትርጉሞች', 'fr': 'Traductions', 'sw': 'Tafsiri za lugha', 'ur': 'تراجم', 'tr': 'Çeviriler', 'id': 'Terjemahan', 'bn': 'অনুবাদসমূহ', 'ha': 'Fassarori', 'so': 'Turjumaadaha', 'fa': 'ترجمه‌ها', 'ms': 'Terjemahan'},
  'ql_sources_ip_note': {'ar': 'كل ترجمة محفوظة الحقوق لمؤلفها أو ناشرها؛ تُعرض الإحالة مع النص.', 'en': 'Each translation is its author’s / publisher’s copyright; attribution is shown with the text.', 'am': 'እያንዳንዱ ትርጉም የደራሲው/አሳታሚው መብት ነው፤ ማጣቀሻ ከጽሑፉ ጋር ይታያል።', 'fr': 'Chaque traduction relève du droit d’auteur de son auteur/éditeur ; l’attribution est affichée avec le texte.', 'sw': 'Kila tafsiri ni hakimiliki ya mwandishi/mchapishaji wake; rejeleo huonyeshwa pamoja na matni.', 'ur': 'ہر ترجمہ اس کے مصنف/ناشر کے جملہ حقوق میں ہے؛ حوالہ متن کے ساتھ دکھایا جاتا ہے۔', 'tr': 'Her çeviri, yazarının/yayıncısının telif hakkındadır; atıf metinle birlikte gösterilir.', 'id': 'Setiap terjemahan adalah hak cipta penulis/penerbitnya; atribusi ditampilkan bersama teks.', 'bn': 'প্রতিটি অনুবাদ তার লেখক/প্রকাশকের কপিরাইট; উল্লেখ পাঠের সাথে দেখানো হয়।', 'ha': 'Kowace fassara mallakar marubucinta/mai bugawa ce; ana nuna ambato tare da rubutu.', 'so': 'Turjumaad kastaa waa xuquuqda qoraaga/daabacaha; tixraaca ayaa lala muujiyaa qoraalka.', 'fa': 'هر ترجمه حق مؤلف/ناشر آن است؛ ارجاع همراه متن نمایش داده می‌شود.', 'ms': 'Setiap terjemahan ialah hak cipta penulis/penerbitnya; atribusi dipaparkan bersama teks.'},
  'ql_sources_riwayat': {'ar': 'الروايات', 'en': 'Riwāyāt', 'am': 'ሪዋያዎች', 'fr': 'Riwāyāt', 'sw': 'Riwāyāt', 'ur': 'روایات', 'tr': 'Rivayetler', 'id': 'Riwayat', 'bn': 'রিওয়ায়াত', 'ha': 'Riwayoyi', 'so': 'Riwaayadaha', 'fa': 'روایات', 'ms': 'Riwayat'},
  'ql_sources_primary': {'ar': 'الأساسية', 'en': 'primary', 'am': 'ዋና', 'fr': 'principale', 'sw': 'kuu', 'ur': 'بنیادی', 'tr': 'ana', 'id': 'utama', 'bn': 'প্রধান', 'ha': 'ta asali', 'so': 'aasaasi', 'fa': 'اصلی', 'ms': 'utama'},
  'ql_sources_reciters': {'ar': 'القرّاء', 'en': 'Reciters', 'am': 'አንባቢዎች', 'fr': 'Récitateurs', 'sw': 'Wasomaji', 'ur': 'قُرّاء', 'tr': 'Kâriler', 'id': 'Qari', 'bn': 'ক্বারিগণ', 'ha': 'Makaranta', 'so': 'Aqristayaasha', 'fa': 'قاریان', 'ms': 'Qari'},
  'ql_sources_quranpedia_layers': {'ar': 'طبقات المعرفة', 'en': 'Knowledge layers', 'am': 'የዕውቀት ንብርብሮች', 'fr': 'Couches de savoir', 'sw': 'Tabaka za maarifa', 'ur': 'علمی طبقات', 'tr': 'Bilgi katmanları', 'id': 'Lapisan pengetahuan', 'bn': 'জ্ঞানস্তর', 'ha': 'Sassan ilimi', 'so': 'Laylasyada aqoonta', 'fa': 'لایه‌های دانش', 'ms': 'Lapisan ilmu'},
  'ql_sources_quranpedia_list': {'ar': 'غريب · أسباب النزول · الناسخ · الفوائد · المتشابهات · الآثار · الموضوعات · الفتاوى', 'en': 'rare words · occasions of revelation · abrogation · reflections · similar wordings · reports · topics · fatwās', 'am': 'ብርቅ ቃላት · የመውረድ ምክንያቶች · ናሲኽ · ጥቅሞች · ተመሳሳዮች · ዘገባዎች · ርዕሶች · ፈትዋዎች', 'fr': 'mots rares · circonstances de la révélation · abrogation · réflexions · formulations similaires · propos · thèmes · fatwās', 'sw': 'maneno adimu · sababu za kuteremshwa · nasikh · faida · yanayofanana · athari · mada · fatwa', 'ur': 'غریب · اسبابِ نزول · ناسخ · فوائد · متشابہات · آثار · موضوعات · فتاویٰ', 'tr': 'garîb kelimeler · nüzul sebepleri · nesh · faydalar · benzer lafızlar · rivayetler · konular · fetvalar', 'id': 'kata garib · sebab turun · nasikh · faedah · kemiripan lafaz · atsar · topik · fatwa', 'bn': 'দুর্লভ শব্দ · শানে নুযুল · নাসিখ · উপকারিতা · সদৃশ শব্দ · আসার · বিষয় · ফতোয়া', 'ha': 'kalmomi masu wuya · dalilan sauka · nāsikh · fa’idodi · kamance · al’āthār · jigogi · fatawoyi', 'so': 'erayo naadir ah · sababaha soo-degista · nāsikh · faa’idooyin · isku-ekaansho · aathaar · mowduucyo · fatwooyin', 'fa': 'واژه‌های غریب · اسباب نزول · ناسخ · فوائد · متشابهات · آثار · موضوعات · فتاوا', 'ms': 'perkataan garib · sebab penurunan · nasikh · faedah · persamaan lafaz · athar · topik · fatwa'},
  'ql_sources_dump_version': {'ar': 'إصدار البيانات', 'en': 'data version', 'am': 'የውሂብ ስሪት', 'fr': 'version des données', 'sw': 'toleo la data', 'ur': 'ڈیٹا ورژن', 'tr': 'veri sürümü', 'id': 'versi data', 'bn': 'ডেটা সংস্করণ', 'ha': 'sigar bayanai', 'so': 'nooca xogta', 'fa': 'نسخهٔ داده', 'ms': 'versi data'},
  'ql_sources_mushaf_art': {'ar': 'فنّ المصحف', 'en': 'Mushaf artwork', 'am': 'የሙስሐፍ ሥነ-ጥበብ', 'fr': 'Illustration du mushaf', 'sw': 'Sanaa ya msahafu', 'ur': 'مصحف کا فن', 'tr': 'Mushaf görseli', 'id': 'Seni mushaf', 'bn': 'মুসহাফ শিল্পকর্ম', 'ha': 'Zanen mushaf', 'so': 'Farshaxanka mushafka', 'fa': 'هنر مصحف', 'ms': 'Seni mushaf'},
  'ql_sources_sadaqa_note': {'ar': 'رخصة «صدقة جارية» · لا يُعدَّل الرسم ولا الضبط', 'en': '“Sadaqa Jāriya” licence · the rasm and ḍabṭ are never altered', 'am': '«ሰደቃ ጃሪያ» ፈቃድ · ራስም እና ደብጥ አይሻሻልም', 'fr': 'licence « Sadaqa Jāriya » · le rasm et le ḍabṭ ne sont jamais modifiés', 'sw': 'leseni ya “Sadaka Jāriya” · rasm na ḍabṭ havibadilishwi kamwe', 'ur': '«صدقہ جاریہ» لائسنس · رسم و ضبط تبدیل نہیں ہوتا', 'tr': '“Sadaka-i Câriye” lisansı · resm ve zabt asla değiştirilmez', 'id': 'lisensi “Sedekah Jariyah” · rasm dan ḍabṭ tidak pernah diubah', 'bn': '“সদকা জারিয়া” লাইসেন্স · রসম ও যবত কখনো পরিবর্তন করা হয় না', 'ha': 'lasisin “Sadaka Jāriya” · ba a taɓa sauya rasm da ḍabṭ ba', 'so': 'shatiga “Sadaqa Jāriya” · rasmka iyo ḍabṭka waligood lama beddelo', 'fa': 'مجوز «صدقهٔ جاریه» · رسم و ضبط هرگز تغییر نمی‌کند', 'ms': 'lesen “Sedekah Jariah” · rasm dan ḍabṭ tidak pernah diubah'},
  'ql_choose_tafsir': {'ar': 'اختر التفسير', 'en': 'Choose a tafsīr', 'am': 'ተፍሲር ምረጥ', 'fr': 'Choisir un tafsīr', 'sw': 'Chagua tafsiri', 'ur': 'تفسیر منتخب کریں', 'tr': 'Bir tefsir seç', 'id': 'Pilih tafsir', 'bn': 'একটি তাফসির বাছুন', 'ha': 'Zaɓi tafsiri', 'so': 'Dooro tafsiir', 'fa': 'یک تفسیر برگزینید', 'ms': 'Pilih tafsir'},
  'ql_choose_translation': {'ar': 'اختر الترجمة', 'en': 'Choose a translation', 'am': 'ትርጉም ምረጥ', 'fr': 'Choisir une traduction', 'sw': 'Chagua tafsiri ya lugha', 'ur': 'ترجمہ منتخب کریں', 'tr': 'Bir çeviri seç', 'id': 'Pilih terjemahan', 'bn': 'একটি অনুবাদ বাছুন', 'ha': 'Zaɓi fassara', 'so': 'Dooro turjumaad', 'fa': 'یک ترجمه برگزینید', 'ms': 'Pilih terjemahan'},
  'ql_choose_language': {'ar': 'اللغة', 'en': 'Language', 'am': 'ቋንቋ', 'fr': 'Langue', 'sw': 'Lugha', 'ur': 'زبان', 'tr': 'Dil', 'id': 'Bahasa', 'bn': 'ভাষা', 'ha': 'Harshe', 'so': 'Luqad', 'fa': 'زبان', 'ms': 'Bahasa'},
  'ql_online': {'ar': 'عبر الإنترنت', 'en': 'online', 'am': 'በመስመር ላይ', 'fr': 'en ligne', 'sw': 'mtandaoni', 'ur': 'آن لائن', 'tr': 'çevrimiçi', 'id': 'daring', 'bn': 'অনলাইন', 'ha': 'kan layi', 'so': 'online', 'fa': 'برخط', 'ms': 'dalam talian'},
  'ql_dl_title': {'ar': 'تحميل هذا الكتاب؟', 'en': 'Download this book?', 'fr': 'Télécharger ce livre ?', 'tr': 'Bu kitap indirilsin mi?', 'ur': 'یہ کتاب ڈاؤن لوڈ کریں؟', 'id': 'Unduh buku ini?', 'ms': 'Muat turun buku ini?', 'fa': 'این کتاب دانلود شود؟', 'bn': 'এই বইটি ডাউনলোড করবেন?', 'am': 'ይህ መጽሐፍ ይውረድ?', 'sw': 'Pakua kitabu hiki?', 'ha': 'Zazzage wannan littafin?', 'so': 'Soo dejiso buuggan?'},
  'ql_dl_body': {'ar': 'هذا الكتاب غير محمَّل على جهازك. يُحمَّل مرة واحدة ثم يعمل بدون إنترنت.', 'en': 'This book is not on your device. It downloads once, then works offline.', 'fr': 'Ce livre n’est pas sur votre appareil. Il se télécharge une fois, puis fonctionne hors ligne.', 'tr': 'Bu kitap cihazınızda yok. Bir kez indirilir, sonra çevrimdışı çalışır.', 'ur': 'یہ کتاب آپ کے آلے پر نہیں ہے۔ ایک بار ڈاؤن لوڈ ہو کر پھر آف لائن چلے گی۔', 'id': 'Buku ini belum ada di perangkat. Diunduh sekali, lalu berfungsi tanpa internet.', 'ms': 'Buku ini belum ada pada peranti. Dimuat turun sekali, kemudian berfungsi tanpa internet.', 'fa': 'این کتاب روی دستگاه شما نیست. یک بار دانلود می‌شود و سپس آفلاین کار می‌کند.', 'bn': 'এই বইটি আপনার ডিভাইসে নেই। একবার ডাউনলোড হলে অফলাইনে চলবে।', 'am': 'ይህ መጽሐፍ በመሣሪያዎ ላይ የለም። አንድ ጊዜ ይወርዳል፣ ከዚያ ያለ በይነመረብ ይሠራል።', 'sw': 'Kitabu hiki hakipo kwenye kifaa. Kinapakuliwa mara moja kisha kinafanya kazi bila mtandao.', 'ha': 'Wannan littafin baya kan na’urarka. Ana zazzage shi sau ɗaya, sannan yana aiki ba tare da intanet ba.', 'so': 'Buuggan ma jiro qalabkaaga. Mar buu soo degayaa, kadibna wuxuu shaqeeyaa internet la’aan.'},
  'ql_dl_size': {'ar': 'الحجم', 'en': 'Size', 'fr': 'Taille', 'tr': 'Boyut', 'ur': 'سائز', 'id': 'Ukuran', 'ms': 'Saiz', 'fa': 'حجم', 'bn': 'আকার', 'am': 'መጠን', 'sw': 'Ukubwa', 'ha': 'Girma', 'so': 'Cabbirka'},
  'ql_dl_button': {'ar': 'تحميل', 'en': 'Download', 'fr': 'Télécharger', 'tr': 'İndir', 'ur': 'ڈاؤن لوڈ', 'id': 'Unduh', 'ms': 'Muat turun', 'fa': 'دانلود', 'bn': 'ডাউনলোড', 'am': 'አውርድ', 'sw': 'Pakua', 'ha': 'Zazzage', 'so': 'Soo deji'},
  'ql_dl_cancel': {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler', 'tr': 'İptal', 'ur': 'منسوخ', 'id': 'Batal', 'ms': 'Batal', 'fa': 'لغو', 'bn': 'বাতিল', 'am': 'ሰርዝ', 'sw': 'Ghairi', 'ha': 'Soke', 'so': 'Jooji'},
  'ql_downloading': {'ar': 'جارٍ التحميل', 'en': 'Downloading', 'am': 'በማውረድ ላይ', 'fr': 'Téléchargement', 'sw': 'Inapakua', 'ur': 'ڈاؤن لوڈ ہو رہا ہے', 'tr': 'İndiriliyor', 'id': 'Mengunduh', 'bn': 'ডাউনলোড হচ্ছে', 'ha': 'Ana zazzagewa', 'so': 'Soo dejinaya', 'fa': 'در حال دانلود', 'ms': 'Memuat turun'},
  'ql_open_ayah_page': {'ar': 'توسّع في صفحة الآية', 'en': 'Expand on the ayah page', 'am': 'በአንቀጹ ገጽ ላይ ዘርጋ', 'fr': 'Développer sur la page du verset', 'sw': 'Panua kwenye ukurasa wa aya', 'ur': 'آیت کے صفحے پر تفصیل دیکھیں', 'tr': 'Âyet sayfasında genişlet', 'id': 'Perluas di halaman ayat', 'bn': 'আয়াতের পৃষ্ঠায় বিস্তারিত দেখুন', 'ha': 'Faɗaɗa a shafin aya', 'so': 'Ku ballaari bogga aayadda', 'fa': 'در صفحهٔ آیه گسترده ببینید', 'ms': 'Kembangkan di halaman ayat'},
  'ql_family_tafsir_translation': {'ar': 'تفسير وترجمة', 'en': 'Tafsir & translation', 'am': 'ተፍሲርና ትርጉም', 'fr': 'Tafsīr et traduction', 'sw': 'Tafsiri na Tafsiri (Lugha)', 'ur': 'تفسیر و ترجمہ', 'tr': 'Tefsir ve çeviri', 'id': 'Tafsir & terjemahan', 'bn': 'তাফসির ও অনুবাদ', 'ha': 'Tafsiri da fassara', 'so': 'Tafsiir iyo turjumaad', 'fa': 'تفسیر و ترجمه', 'ms': 'Tafsir & terjemahan'},
  'ql_asbab_documented_badge': {'ar': 'سبب النزول موثّق', 'en': 'Occasion of revelation documented', 'am': 'የመውረድ ምክንያት ተመዝግቧል', 'fr': 'Circonstance de la révélation documentée', 'sw': 'Sababu ya kuteremshwa imethibitishwa', 'ur': 'شانِ نزول موجود ہے', 'tr': 'Nüzul sebebi belgeli', 'id': 'Sebab turunnya ayat tercatat', 'bn': 'শানে নুযুল নথিভুক্ত আছে', 'ha': 'An rubuta dalilin saukar aya', 'so': 'Sababta soo-degista waa la xujeeyay', 'fa': 'سبب نزول ثبت شده است', 'ms': 'Sebab penurunan direkodkan'},
  'ql_asbab_not_for_ayah': {'ar': 'لم يرد نص خاص بهذه الآية تحديدًا في مصادرنا الحالية — تحتوي هذه السورة على مواضع أخرى موثّقة.', 'en': 'No account specific to this ayah in our current sources — this surah has other documented occasions.', 'am': 'በአሁኑ ምንጮቻችን ለዚህ ልዩ አንቀጽ የተመዘገበ ዘገባ የለም — ይህ ሱራ ሌሎች የተመዘገቡ ስፍራዎች አሉት።', 'fr': 'Aucun récit spécifique à ce verset dans nos sources actuelles — cette sourate contient d\'autres passages documentés.', 'sw': 'Hakuna riwaya mahususi kwa aya hii katika vyanzo vyetu vya sasa — sura hii ina maeneo mengine yaliyothibitishwa.', 'ur': 'ہمارے موجودہ مصادر میں خاص طور پر اس آیت کے لیے کوئی روایت موجود نہیں — اس سورت میں دیگر مقامات موجود ہیں۔', 'tr': 'Mevcut kaynaklarımızda bu âyete özel bir rivayet yok — bu surede belgelenmiş başka yerler var.', 'id': 'Tidak ada riwayat khusus untuk ayat ini dalam sumber kami saat ini — surah ini memiliki bagian lain yang terdokumentasi.', 'bn': 'আমাদের বর্তমান সূত্রে এই আয়াতের জন্য নির্দিষ্ট কোনো বিবরণ নেই — এই সূরায় অন্য নথিভুক্ত স্থান রয়েছে।', 'ha': 'Babu wani labari na musamman ga wannan ayar a cikin tushenmu na yanzu — wannan sura tana da wasu wurare da aka rubuta.', 'so': 'Sheeko gaar ah oo aayaddan ku saabsan kuma jirto ilahayaga hadda — suuraddan waxay leedahay meelo kale oo la xujeeyay.', 'fa': 'در منابع کنونی ما روایتی مخصوص این آیه یافت نشد — این سوره دارای مواضع مستندشدهٔ دیگری است.', 'ms': 'Tiada riwayat khusus untuk ayat ini dalam sumber kami sekarang — surah ini mempunyai bahagian lain yang direkodkan.'},
  'ql_asbab_not_for_surah': {'ar': 'لم يرد نص موثّق في مصادرنا الحالية لهذه السورة.', 'en': 'No documented account in our current sources for this surah.', 'am': 'በአሁኑ ምንጮቻችን ለዚህ ሱራ የተመዘገበ ዘገባ የለም።', 'fr': 'Aucun récit documenté dans nos sources actuelles pour cette sourate.', 'sw': 'Hakuna riwaya iliyothibitishwa katika vyanzo vyetu vya sasa kwa sura hii.', 'ur': 'ہمارے موجودہ مصادر میں اس سورت کے لیے کوئی مستند روایت موجود نہیں۔', 'tr': 'Mevcut kaynaklarımızda bu sure için belgelenmiş bir rivayet yok.', 'id': 'Tidak ada riwayat terdokumentasi dalam sumber kami saat ini untuk surah ini.', 'bn': 'আমাদের বর্তমান সূত্রে এই সূরার জন্য কোনো নথিভুক্ত বিবরণ নেই।', 'ha': 'Babu wani labari da aka rubuta a cikin tushenmu na yanzu ga wannan sura.', 'so': 'Sheeko la xujeeyay kuma jirto ilahayaga hadda ee suuraddan.', 'fa': 'در منابع کنونی ما روایت مستندی برای این سوره یافت نشد.', 'ms': 'Tiada riwayat direkodkan dalam sumber kami sekarang untuk surah ini.'},
  'ql_tafsir_mirror': {'ar': 'هذا التفسير مطوّل ويُتاح عند الاتصال بالإنترنت (قريبًا).', 'en': 'This tafsīr is large and will be available online (coming soon).', 'am': 'ይህ ተፍሲር ትልቅ ነው፣ በበይነመረብ ይገኛል (በቅርቡ)።', 'fr': 'Ce tafsīr est volumineux ; il sera disponible en ligne (bientôt).', 'sw': 'Tafsiri hii ni kubwa, itapatikana mtandaoni (hivi karibuni).', 'ur': 'یہ تفسیر طویل ہے اور آن لائن دستیاب ہوگی (جلد)۔', 'tr': 'Bu tefsir büyüktür, çevrimiçi olarak sunulacaktır (yakında).', 'id': 'Tafsir ini besar dan akan tersedia daring (segera).', 'bn': 'এই তাফসিরটি বড়, শীঘ্রই অনলাইনে পাওয়া যাবে।', 'ha': 'Wannan tafsirin yana da girma, zai kasance kan layi (nan ba da jimawa ba).', 'so': 'Tafsiirkani waa mid weyn, wuxuu online ku diyaar noqon doonaa (dhawaan).', 'fa': 'این تفسیر حجیم است و به‌زودی به‌صورت برخط در دسترس خواهد بود.', 'ms': 'Tafsir ini besar dan akan tersedia dalam talian (tidak lama lagi).'},
  // ---- Life Engine «مُحرّك الحياة» (docs/LIFE_ENGINE.md, L2)
  'life_engine_title': {'ar': 'مُحرّك الحياة', 'en': 'Life Engine', 'am': 'የሕይወት ሞተር', 'fr': 'Moteur de vie', 'sw': 'Injini ya maisha', 'ur': 'لائف انجن', 'tr': 'Hayat motoru', 'id': 'Mesin kehidupan', 'bn': 'লাইফ ইঞ্জিন', 'ha': 'Injin rayuwa', 'so': 'Mishiinka nolosha', 'fa': 'موتور زندگی', 'ms': 'Enjin kehidupan'},
  'life_engine_tagline': {'ar': 'خطّتك اليومية — تقدّم لا يتوقّف', 'en': 'Your daily plan — progress that never ends', 'am': 'የዕለት ተዕለት እቅድህ — የማይቆም እድገት', 'fr': 'Votre plan quotidien — un progrès sans fin', 'sw': 'Mpango wako wa kila siku — maendeleo yasiyoisha', 'ur': 'آپ کا روزانہ منصوبہ — پیش رفت جو رکتی نہیں', 'tr': 'Günlük planın — hiç bitmeyen ilerleme', 'id': 'Rencana harianmu — kemajuan tanpa akhir', 'bn': 'আপনার দৈনিক পরিকল্পনা — অগ্রগতি যা থামে না', 'ha': 'Shirin ka na yau da kullum — ci gaba mara ƙarewa', 'so': 'Qorshahaaga maalinlaha ah — horumar aan dhammaan', 'fa': 'برنامهٔ روزانه‌ات — پیشرفتی که پایان ندارد', 'ms': 'Pelan harian anda — kemajuan tanpa henti'},
  'life_day_word': {'ar': 'اليوم', 'en': 'Day', 'am': 'ቀን', 'fr': 'Jour', 'sw': 'Siku', 'ur': 'دن', 'tr': 'Gün', 'id': 'Hari', 'bn': 'দিন', 'ha': 'Rana', 'so': 'Maalin', 'fa': 'روز', 'ms': 'Hari'},
  'life_cycle_word': {'ar': 'الدورة', 'en': 'Cycle', 'am': 'ዑደት', 'fr': 'Cycle', 'sw': 'Mzunguko', 'ur': 'دور', 'tr': 'Döngü', 'id': 'Siklus', 'bn': 'চক্র', 'ha': 'Zagaye', 'so': 'Wareeg', 'fa': 'چرخه', 'ms': 'Kitaran'},
  'life_now': {'ar': 'الآن', 'en': 'Now', 'am': 'አሁን', 'fr': 'Maintenant', 'sw': 'Sasa', 'ur': 'اب', 'tr': 'Şimdi', 'id': 'Sekarang', 'bn': 'এখন', 'ha': 'Yanzu', 'so': 'Hadda', 'fa': 'اکنون', 'ms': 'Sekarang'},
  'life_get_ready': {'ar': 'استعدّ للفترة القادمة', 'en': 'Get ready for the next block', 'am': 'ለቀጣዩ ክፍለ ጊዜ ተዘጋጅ', 'fr': 'Préparez-vous au prochain créneau', 'sw': 'Jiandae kwa kipindi kijacho', 'ur': 'اگلے وقفے کے لیے تیار ہو جائیں', 'tr': 'Sonraki bölüme hazırlan', 'id': 'Bersiap untuk blok berikutnya', 'bn': 'পরবর্তী ব্লকের জন্য প্রস্তুত হোন', 'ha': 'Ka shirya don lokaci na gaba', 'so': 'U diyaar garow qaybta xigta', 'fa': 'برای بازهٔ بعدی آماده شو', 'ms': 'Bersedia untuk blok seterusnya'},
  'life_day_complete': {'ar': 'أكملت فترات اليوم — بارك الله فيك', 'en': 'Today’s blocks are done — well done', 'am': 'የዛሬ ክፍለ ጊዜያት ተጠናቀዋል — በጎ ሥራ', 'fr': 'Les créneaux du jour sont terminés — bravo', 'sw': 'Vipindi vya leo vimekamilika — hongera', 'ur': 'آج کے تمام وقفے مکمل — شاباش', 'tr': 'Bugünün bölümleri bitti — aferin', 'id': 'Blok hari ini selesai — kerja bagus', 'bn': 'আজকের সব ব্লক সম্পন্ন — সাবাশ', 'ha': 'An gama lokutan yau — madalla', 'so': 'Qaybaha maanta waa la dhammeeyay — aad baad u fiicantahay', 'fa': 'بازه‌های امروز تمام شد — آفرین', 'ms': 'Blok hari ini selesai — syabas'},
  'life_rest': {'ar': 'راحة', 'en': 'Rest', 'am': 'እረፍት', 'fr': 'Repos', 'sw': 'Pumziko', 'ur': 'آرام', 'tr': 'Dinlen', 'id': 'Istirahat', 'bn': 'বিশ্রাম', 'ha': 'Hutu', 'so': 'Nasasho', 'fa': 'استراحت', 'ms': 'Rehat'},
  'life_todays_blocks': {'ar': 'فترات اليوم', 'en': 'Today’s blocks', 'am': 'የዛሬ ክፍለ ጊዜያት', 'fr': 'Créneaux du jour', 'sw': 'Vipindi vya leo', 'ur': 'آج کے وقفے', 'tr': 'Bugünün bölümleri', 'id': 'Blok hari ini', 'bn': 'আজকের ব্লকসমূহ', 'ha': 'Lokutan yau', 'so': 'Qaybaha maanta', 'fa': 'بازه‌های امروز', 'ms': 'Blok hari ini'},
  'life_progress_title': {'ar': 'التقدّم', 'en': 'Progress', 'am': 'እድገት', 'fr': 'Progrès', 'sw': 'Maendeleo', 'ur': 'پیش رفت', 'tr': 'İlerleme', 'id': 'Kemajuan', 'bn': 'অগ্রগতি', 'ha': 'Ci gaba', 'so': 'Horumar', 'fa': 'پیشرفت', 'ms': 'Kemajuan'},
  'life_heatmap_title': {'ar': 'كل يوم منذ البداية', 'en': 'Every day since the start', 'am': 'ከጅምሩ ጀምሮ በየቀኑ', 'fr': 'Chaque jour depuis le début', 'sw': 'Kila siku tangu mwanzo', 'ur': 'آغاز سے ہر دن', 'tr': 'Başlangıçtan bu yana her gün', 'id': 'Setiap hari sejak awal', 'bn': 'শুরু থেকে প্রতিদিন', 'ha': 'Kowace rana tun farko', 'so': 'Maalin kasta tan iyo bilowga', 'fa': 'هر روز از آغاز', 'ms': 'Setiap hari sejak mula'},
  'life_momentum_title': {'ar': 'زخم المحاور (آخر 7 أيام)', 'en': 'Pillar momentum (last 7 days)', 'am': 'የምሰሶ ፍጥነት (ያለፉት 7 ቀናት)', 'fr': 'Élan des piliers (7 derniers jours)', 'sw': 'Kasi ya nguzo (siku 7 zilizopita)', 'ur': 'ستونوں کی رفتار (پچھلے 7 دن)', 'tr': 'Sütun ivmesi (son 7 gün)', 'id': 'Momentum pilar (7 hari terakhir)', 'bn': 'স্তম্ভের গতি (গত ৭ দিন)', 'ha': 'Ƙarfin ginshiƙai (kwanaki 7 da suka gabata)', 'so': 'Xawaaraha tiirarka (7-dii maalmood ee la soo dhaafay)', 'fa': 'شتاب ستون‌ها (۷ روز اخیر)', 'ms': 'Momentum tiang (7 hari lepas)'},
  'life_win_today': {'ar': 'اليوم', 'en': 'Today', 'am': 'ዛሬ', 'fr': 'Aujourd’hui', 'sw': 'Leo', 'ur': 'آج', 'tr': 'Bugün', 'id': 'Hari ini', 'bn': 'আজ', 'ha': 'Yau', 'so': 'Maanta', 'fa': 'امروز', 'ms': 'Hari ini'},
  'life_win_7': {'ar': 'آخر 7', 'en': 'Last 7', 'am': 'የመጨረሻ 7', 'fr': '7 derniers', 'sw': '7 zilizopita', 'ur': 'پچھلے 7', 'tr': 'Son 7', 'id': '7 terakhir', 'bn': 'গত ৭', 'ha': '7 na ƙarshe', 'so': '7-dii u dambeeyay', 'fa': '۷ روز اخیر', 'ms': '7 terakhir'},
  'life_win_30': {'ar': 'آخر 30', 'en': 'Last 30', 'am': 'የመጨረሻ 30', 'fr': '30 derniers', 'sw': '30 zilizopita', 'ur': 'پچھلے 30', 'tr': 'Son 30', 'id': '30 terakhir', 'bn': 'গত ৩০', 'ha': '30 na ƙarshe', 'so': '30-kii u dambeeyay', 'fa': '۳۰ روز اخیر', 'ms': '30 terakhir'},
  'life_win_all': {'ar': 'منذ البدء', 'en': 'Since start', 'am': 'ከጅምሩ ጀምሮ', 'fr': 'Depuis le début', 'sw': 'Tangu mwanzo', 'ur': 'آغاز سے', 'tr': 'Baştan beri', 'id': 'Sejak awal', 'bn': 'শুরু থেকে', 'ha': 'Tun farko', 'so': 'Tan iyo bilowga', 'fa': 'از آغاز', 'ms': 'Sejak mula'},
  'life_streak_days': {'ar': 'يومًا متتابعًا', 'en': 'days in a row', 'am': 'ተከታታይ ቀናት', 'fr': 'jours d’affilée', 'sw': 'siku mfululizo', 'ur': 'مسلسل دن', 'tr': 'gün üst üste', 'id': 'hari berturut-turut', 'bn': 'পরপর দিন', 'ha': 'kwanaki a jere', 'so': 'maalmo isku xigta', 'fa': 'روز پیاپی', 'ms': 'hari berturut-turut'},
  'life_streak_grace': {'ar': 'يوم سماح واحد كل أسبوع — خطأ واحد لا يُصفّرها', 'en': 'one grace day per week — a single miss won’t reset it', 'am': 'በሳምንት አንድ የይቅርታ ቀን — አንድ ስህተት ዜሮ አያደርገውም', 'fr': 'un jour de grâce par semaine — un seul oubli ne remet pas à zéro', 'sw': 'siku moja ya neema kwa wiki — kukosa mara moja hakuifuti', 'ur': 'ہفتے میں ایک رعایتی دن — ایک غلطی اسے صفر نہیں کرتی', 'tr': 'haftada bir tolerans günü — tek bir kaçırma sıfırlamaz', 'id': 'satu hari kelonggaran per pekan — satu kali lewat tidak mengulang dari nol', 'bn': 'সপ্তাহে একটি ছাড়ের দিন — একবার মিস করলে শূন্য হবে না', 'ha': 'rana ɗaya ta jinƙai kowane mako — kuskure ɗaya ba zai sake shi zuwa sifili ba', 'so': 'hal maalin oo cafis ah toddobaadkii — hal seeg kuma dhigo eber', 'fa': 'یک روز ارفاق در هفته — یک بار جا انداختن صفرش نمی‌کند', 'ms': 'satu hari kelonggaran seminggu — satu kali terlepas tidak set semula'},
  'life_slipping': {'ar': '⚠ يتراجع', 'en': '⚠ slipping', 'am': '⚠ እየቀነሰ', 'fr': '⚠ en baisse', 'sw': '⚠ inashuka', 'ur': '⚠ گر رہا ہے', 'tr': '⚠ geriliyor', 'id': '⚠ menurun', 'bn': '⚠ পিছিয়ে পড়ছে', 'ha': '⚠ yana raguwa', 'so': '⚠ hoos u dhac', 'fa': '⚠ در حال افت', 'ms': '⚠ merosot'},
  // ---- Life Engine notifications (docs/LIFE_ENGINE.md, L4)
  'life_notif_channel_desc': {'ar': 'تذكيرات فترات مُحرّك الحياة والموجز الصباحي ومحاسبة الليل', 'en': 'Life Engine block reminders, the morning brief, and the nightly review', 'am': 'የሕይወት ሞተር ክፍለ ጊዜ ማስታወሻዎች፣ የጠዋት ማጠቃለያና የሌሊት ግምገማ', 'fr': 'Rappels des créneaux du Moteur de vie, le point du matin et le bilan du soir', 'sw': 'Vikumbusho vya vipindi vya Injini ya maisha, muhtasari wa asubuhi, na tathmini ya usiku', 'ur': 'لائف انجن کے وقفوں کی یاد دہانیاں، صبح کا خلاصہ، اور رات کا محاسبہ', 'tr': 'Hayat motoru bölüm hatırlatıcıları, sabah özeti ve gece muhasebesi', 'id': 'Pengingat blok Mesin kehidupan, ringkasan pagi, dan muhasabah malam', 'bn': 'লাইফ ইঞ্জিনের ব্লক রিমাইন্ডার, সকালের সারসংক্ষেপ ও রাতের হিসাব', 'ha': 'Tunatarwar lokutan Injin rayuwa, taƙaitawar safe, da lissafin dare', 'so': 'Xasuusinta qaybaha Mishiinka nolosha, soo koobista subaxda, iyo xisaabinta habeenkii', 'fa': 'یادآوری بازه‌های موتور زندگی، خلاصهٔ صبح و محاسبهٔ شب', 'ms': 'Peringatan blok Enjin kehidupan, ringkasan pagi, dan muhasabah malam'},
  'life_notif_morning_title': {'ar': '🌅 يوم جديد في مُحرّك الحياة', 'en': '🌅 A new day in the Life Engine', 'am': '🌅 በሕይወት ሞተር ውስጥ አዲስ ቀን', 'fr': '🌅 Un nouveau jour dans le Moteur de vie', 'sw': '🌅 Siku mpya katika Injini ya maisha', 'ur': '🌅 لائف انجن میں ایک نیا دن', 'tr': '🌅 Hayat motorunda yeni bir gün', 'id': '🌅 Hari baru di Mesin kehidupan', 'bn': '🌅 লাইফ ইঞ্জিনে নতুন এক দিন', 'ha': '🌅 Sabuwar rana a Injin rayuwa', 'so': '🌅 Maalin cusub oo Mishiinka nolosha ah', 'fa': '🌅 روزی نو در موتور زندگی', 'ms': '🌅 Hari baharu dalam Enjin kehidupan'},
  'life_notif_morning_body': {'ar': 'خطّتك بانتظارك — افتح التطبيق وابدأ أول فترة بنيّة صادقة.', 'en': 'Your plan is waiting — open the app and start the first block with sincere intent.', 'am': 'እቅድህ እየጠበቀህ ነው — መተግበሪያውን ክፈትና የመጀመሪያውን ክፍለ ጊዜ በቅን ልቦና ጀምር።', 'fr': 'Votre plan vous attend — ouvrez l’application et commencez le premier créneau avec une intention sincère.', 'sw': 'Mpango wako unakusubiri — fungua programu na uanze kipindi cha kwanza kwa nia safi.', 'ur': 'آپ کا منصوبہ منتظر ہے — ایپ کھولیں اور پہلا وقفہ سچی نیت سے شروع کریں۔', 'tr': 'Planın seni bekliyor — uygulamayı aç ve ilk bölüme samimi bir niyetle başla.', 'id': 'Rencanamu menanti — buka aplikasi dan mulai blok pertama dengan niat yang tulus.', 'bn': 'আপনার পরিকল্পনা অপেক্ষা করছে — অ্যাপ খুলুন এবং সৎ নিয়তে প্রথম ব্লক শুরু করুন।', 'ha': 'Shirin ka na jira — buɗe manhajar ka fara lokaci na farko da niyya ta gaskiya.', 'so': 'Qorshahaagu wuu ku sugayaa — fur abka oo bilow qaybta koowaad niyad daacad ah.', 'fa': 'برنامه‌ات منتظر توست — برنامه را باز کن و اولین بازه را با نیّتی صادق آغاز کن.', 'ms': 'Pelan anda menanti — buka apl dan mulakan blok pertama dengan niat yang ikhlas.'},
  'life_notif_nightly_title': {'ar': '🌙 حاسب نفسك', 'en': '🌙 Hold yourself to account', 'am': '🌙 ራስህን ተጠያቂ አድርግ', 'fr': '🌙 Fais ton bilan', 'sw': '🌙 Jihesabu mwenyewe', 'ur': '🌙 اپنا محاسبہ کریں', 'tr': '🌙 Kendini muhasebe et', 'id': '🌙 Muhasabah dirimu', 'bn': '🌙 নিজের হিসাব নিন', 'ha': '🌙 Yi wa kanka lissafi', 'so': '🌙 Is xisaabi', 'fa': '🌙 خودت را محاسبه کن', 'ms': '🌙 Muhasabah diri'},
  'life_notif_nightly_empty': {'ar': 'لم تُسجّل أي فترة اليوم. افتح مُحرّك الحياة الآن وأغلق يومك بصدق.', 'en': 'You logged no blocks today. Open the Life Engine now and close your day honestly.', 'am': 'ዛሬ ምንም ክፍለ ጊዜ አልመዘገብክም። አሁን የሕይወት ሞተርን ክፈትና ቀንህን በታማኝነት ዝጋ።', 'fr': 'Vous n’avez enregistré aucun créneau aujourd’hui. Ouvrez le Moteur de vie et clôturez votre journée honnêtement.', 'sw': 'Hujaandika kipindi chochote leo. Fungua Injini ya maisha sasa na ufunge siku yako kwa uaminifu.', 'ur': 'آج آپ نے کوئی وقفہ درج نہیں کیا۔ ابھی لائف انجن کھولیں اور اپنا دن سچائی سے مکمل کریں۔', 'tr': 'Bugün hiç bölüm kaydetmedin. Şimdi Hayat motorunu aç ve gününü dürüstçe kapat.', 'id': 'Kamu belum mencatat blok apa pun hari ini. Buka Mesin kehidupan sekarang dan tutup harimu dengan jujur.', 'bn': 'আজ আপনি কোনো ব্লক লেখেননি। এখনই লাইফ ইঞ্জিন খুলুন এবং সততার সাথে দিন শেষ করুন।', 'ha': 'Yau ba ka rubuta wani lokaci ba. Buɗe Injin rayuwa yanzu ka rufe ranarka da gaskiya.', 'so': 'Maanta qayb ma aadan diiwaan gelin. Hadda fur Mishiinka nolosha oo si daacad ah u soo gabagabee maalintaada.', 'fa': 'امروز هیچ بازه‌ای ثبت نکردی. همین حالا موتور زندگی را باز کن و روزت را صادقانه ببند.', 'ms': 'Anda tidak mencatat sebarang blok hari ini. Buka Enjin kehidupan sekarang dan tutup hari anda dengan jujur.'},
  'life_notif_nightly_done': {'ar': 'أنجزت {done}/{total} اليوم. اكتب ملاحظتك وهدف الغد.', 'en': 'You completed {done}/{total} today. Write your note and tomorrow’s goal.', 'am': 'ዛሬ {done}/{total} አጠናቀቅክ። ማስታወሻህንና የነገ ግብህን ጻፍ።', 'fr': 'Vous avez terminé {done}/{total} aujourd’hui. Notez votre remarque et l’objectif de demain.', 'sw': 'Umekamilisha {done}/{total} leo. Andika dokezo lako na lengo la kesho.', 'ur': 'آج آپ نے {done}/{total} مکمل کیے۔ اپنی یادداشت اور کل کا ہدف لکھیں۔', 'tr': 'Bugün {done}/{total} tamamladın. Notunu ve yarının hedefini yaz.', 'id': 'Kamu menyelesaikan {done}/{total} hari ini. Tulis catatan dan targetmu untuk besok.', 'bn': 'আজ আপনি {done}/{total} সম্পন্ন করেছেন। আপনার নোট এবং আগামীকালের লক্ষ্য লিখুন।', 'ha': 'Yau ka kammala {done}/{total}. Rubuta bayaninka da burin gobe.', 'so': 'Maanta waxaad dhammaystirtay {done}/{total}. Qor qoraalkaaga iyo yoolka berrito.', 'fa': 'امروز {done}/{total} را کامل کردی. یادداشت و هدف فردایت را بنویس.', 'ms': 'Anda menyelesaikan {done}/{total} hari ini. Tulis catatan dan matlamat esok anda.'},
  // ---- Life Engine L5 — weekly review + day note + cycle rollover (docs/LIFE_ENGINE.md)
  'life_note_title': {'ar': 'ملاحظة اليوم وهدف الغد', 'en': 'Today’s note & tomorrow’s goal', 'am': 'የዛሬ ማስታወሻና የነገ ግብ', 'fr': 'Note du jour & objectif de demain', 'sw': 'Dokezo la leo na lengo la kesho', 'ur': 'آج کی یادداشت اور کل کا ہدف', 'tr': 'Bugünün notu ve yarının hedefi', 'id': 'Catatan hari ini & target besok', 'bn': 'আজকের নোট ও আগামীকালের লক্ষ্য', 'ha': 'Bayanin yau da burin gobe', 'so': 'Qoraalka maanta iyo yoolka berri', 'fa': 'یادداشت امروز و هدف فردا', 'ms': 'Catatan hari ini & matlamat esok'},
  'life_note_sub': {'ar': 'دقيقة تأمّل تختم يومك', 'en': 'A minute of reflection to close your day', 'am': 'ቀንህን የሚዘጋ የአንድ ደቂቃ ማሰላሰል', 'fr': 'Une minute de réflexion pour clore la journée', 'sw': 'Dakika moja ya tafakari kufunga siku yako', 'ur': 'دن مکمل کرنے کے لیے ایک منٹ کا غور و فکر', 'tr': 'Gününü kapatan bir dakikalık tefekkür', 'id': 'Semenit refleksi untuk menutup harimu', 'bn': 'দিন শেষ করতে এক মিনিটের চিন্তন', 'ha': 'Minti ɗaya na tunani don rufe ranarka', 'so': 'Daqiiqad milicsi ah oo maalintaada soo gabagabaynaysa', 'fa': 'یک دقیقه تأمل برای پایان روزت', 'ms': 'Seminit renungan untuk menutup hari anda'},
  'life_note_day_label': {'ar': 'كيف كان يومك؟', 'en': 'How was your day?', 'am': 'ቀንህ እንዴት ነበር?', 'fr': 'Comment s’est passée ta journée ?', 'sw': 'Siku yako ilikuwaje?', 'ur': 'آپ کا دن کیسا رہا؟', 'tr': 'Günün nasıldı?', 'id': 'Bagaimana harimu?', 'bn': 'আপনার দিন কেমন কাটল?', 'ha': 'Yaya ranarka ta kasance?', 'so': 'Sidee maalintaadu ahayd?', 'fa': 'روزت چطور بود؟', 'ms': 'Bagaimana hari anda?'},
  'life_note_day_hint': {'ar': 'ما الذي سار جيدًا؟ وما الذي أعاقك؟', 'en': 'What went well? What held you back?', 'am': 'ምን ጥሩ ሆነ? ምን ገታህ?', 'fr': 'Qu’est-ce qui a bien marché ? Qu’est-ce qui t’a freiné ?', 'sw': 'Nini kilikwenda vizuri? Nini kilikuzuia?', 'ur': 'کیا اچھا رہا؟ کس چیز نے روکا؟', 'tr': 'Ne iyi gitti? Seni ne engelledi?', 'id': 'Apa yang berjalan baik? Apa yang menghambatmu?', 'bn': 'কী ভালো হলো? কী আপনাকে আটকাল?', 'ha': 'Me ya yi kyau? Me ya hana ka?', 'so': 'Maxaa si fiican u socday? Maxaa ku hor istaagay?', 'fa': 'چه چیزی خوب پیش رفت؟ چه چیزی مانعت شد؟', 'ms': 'Apa yang berjalan lancar? Apa yang menghalang anda?'},
  'life_note_goal_label': {'ar': 'هدف الغد', 'en': 'Tomorrow’s goal', 'am': 'የነገ ግብ', 'fr': 'Objectif de demain', 'sw': 'Lengo la kesho', 'ur': 'کل کا ہدف', 'tr': 'Yarının hedefi', 'id': 'Target besok', 'bn': 'আগামীকালের লক্ষ্য', 'ha': 'Burin gobe', 'so': 'Yoolka berri', 'fa': 'هدف فردا', 'ms': 'Matlamat esok'},
  'life_note_goal_hint': {'ar': 'أهمّ شيء واحد تبدأ به غدًا', 'en': 'The one most important thing to start with tomorrow', 'am': 'ነገ የምትጀምርበት አንድ በጣም አስፈላጊ ነገር', 'fr': 'La chose la plus importante par laquelle commencer demain', 'sw': 'Jambo moja muhimu zaidi la kuanza nalo kesho', 'ur': 'کل جس ایک اہم ترین کام سے آغاز کرنا ہے', 'tr': 'Yarın başlanacak en önemli tek şey', 'id': 'Satu hal terpenting untuk dimulai besok', 'bn': 'আগামীকাল যে একটি সবচেয়ে গুরুত্বপূর্ণ কাজ দিয়ে শুরু করবেন', 'ha': 'Abu ɗaya mafi muhimmanci da za a fara da shi gobe', 'so': 'Hal shay oo ugu muhiimsan oo berri lagu bilaabo', 'fa': 'مهم‌ترین کاری که فردا با آن شروع می‌کنی', 'ms': 'Satu perkara terpenting untuk dimulakan esok'},
  'life_note_mood_label': {'ar': 'مزاجك', 'en': 'Your mood', 'am': 'ስሜትህ', 'fr': 'Ton humeur', 'sw': 'Hisia zako', 'ur': 'آپ کا مزاج', 'tr': 'Ruh halin', 'id': 'Suasana hatimu', 'bn': 'আপনার মেজাজ', 'ha': 'Yanayin ranka', 'so': 'Niyadaada', 'fa': 'حال و هوایت', 'ms': 'Mood anda'},
  'life_note_save': {'ar': 'حفظ', 'en': 'Save', 'am': 'አስቀምጥ', 'fr': 'Enregistrer', 'sw': 'Hifadhi', 'ur': 'محفوظ کریں', 'tr': 'Kaydet', 'id': 'Simpan', 'bn': 'সংরক্ষণ', 'ha': 'Ajiye', 'so': 'Kaydi', 'fa': 'ذخیره', 'ms': 'Simpan'},
  'life_note_open': {'ar': 'اكتب ملاحظة اليوم', 'en': 'Write today’s note', 'am': 'የዛሬን ማስታወሻ ጻፍ', 'fr': 'Écrire la note du jour', 'sw': 'Andika dokezo la leo', 'ur': 'آج کی یادداشت لکھیں', 'tr': 'Bugünün notunu yaz', 'id': 'Tulis catatan hari ini', 'bn': 'আজকের নোট লিখুন', 'ha': 'Rubuta bayanin yau', 'so': 'Qor qoraalka maanta', 'fa': 'یادداشت امروز را بنویس', 'ms': 'Tulis catatan hari ini'},
  'life_week_title': {'ar': 'ملخّص الأسبوع', 'en': 'Weekly summary', 'am': 'የሳምንቱ ማጠቃለያ', 'fr': 'Bilan de la semaine', 'sw': 'Muhtasari wa wiki', 'ur': 'ہفتے کا خلاصہ', 'tr': 'Haftalık özet', 'id': 'Ringkasan pekan', 'bn': 'সাপ্তাহিক সারসংক্ষেপ', 'ha': 'Taƙaitawar mako', 'so': 'Soo koobista toddobaadka', 'fa': 'خلاصهٔ هفته', 'ms': 'Ringkasan mingguan'},
  'life_week_completion': {'ar': 'إنجاز الأسبوع', 'en': 'This week’s completion', 'am': 'የዚህ ሳምንት ማጠናቀቅ', 'fr': 'Réalisation de la semaine', 'sw': 'Ukamilishaji wa wiki hii', 'ur': 'اس ہفتے کی تکمیل', 'tr': 'Bu haftanın tamamlanması', 'id': 'Penyelesaian pekan ini', 'bn': 'এই সপ্তাহের সম্পন্নতা', 'ha': 'Cikar wannan mako', 'so': 'Dhammaystirka toddobaadkan', 'fa': 'تکمیل این هفته', 'ms': 'Penyiapan minggu ini'},
  'life_week_vs_prev': {'ar': 'مقارنةً بالأسبوع السابق', 'en': 'vs. the previous week', 'am': 'ካለፈው ሳምንት ጋር ሲነጻጸር', 'fr': 'par rapport à la semaine précédente', 'sw': 'ikilinganishwa na wiki iliyopita', 'ur': 'پچھلے ہفتے کے مقابلے میں', 'tr': 'önceki haftaya kıyasla', 'id': 'dibanding pekan sebelumnya', 'bn': 'গত সপ্তাহের তুলনায়', 'ha': 'idan aka kwatanta da makon da ya gabata', 'so': 'marka la barbardhigo toddobaadkii hore', 'fa': 'در مقایسه با هفتهٔ گذشته', 'ms': 'berbanding minggu sebelumnya'},
  'life_week_strongest': {'ar': 'الأقوى', 'en': 'Strongest', 'am': 'በጣም ጠንካራው', 'fr': 'Le plus fort', 'sw': 'Imara zaidi', 'ur': 'سب سے مضبوط', 'tr': 'En güçlü', 'id': 'Terkuat', 'bn': 'সবচেয়ে শক্তিশালী', 'ha': 'Mafi ƙarfi', 'so': 'Kan ugu xoogga badan', 'fa': 'قوی‌ترین', 'ms': 'Terkuat'},
  'life_week_attention': {'ar': 'يحتاج انتباهًا', 'en': 'Needs attention', 'am': 'ትኩረት ይፈልጋል', 'fr': 'À surveiller', 'sw': 'Inahitaji uangalifu', 'ur': 'توجہ درکار', 'tr': 'Dikkat gerektiriyor', 'id': 'Perlu perhatian', 'bn': 'মনোযোগ প্রয়োজন', 'ha': 'Yana buƙatar kulawa', 'so': 'Wuxuu u baahan yahay feejignaan', 'fa': 'نیازمند توجه', 'ms': 'Perlu perhatian'},
  'life_week_notes': {'ar': 'ملاحظات الأسبوع', 'en': 'This week’s notes', 'am': 'የዚህ ሳምንት ማስታወሻዎች', 'fr': 'Notes de la semaine', 'sw': 'Dokezo za wiki hii', 'ur': 'اس ہفتے کی یادداشتیں', 'tr': 'Bu haftanın notları', 'id': 'Catatan pekan ini', 'bn': 'এই সপ্তাহের নোট', 'ha': 'Bayanan wannan mako', 'so': 'Qoraallada toddobaadkan', 'fa': 'یادداشت‌های این هفته', 'ms': 'Catatan minggu ini'},
  'life_week_no_notes': {'ar': 'لا ملاحظات هذا الأسبوع بعد', 'en': 'No notes this week yet', 'am': 'በዚህ ሳምንት እስካሁን ማስታወሻ የለም', 'fr': 'Aucune note cette semaine pour l’instant', 'sw': 'Bado hakuna dokezo wiki hii', 'ur': 'اس ہفتے ابھی کوئی یادداشت نہیں', 'tr': 'Bu hafta henüz not yok', 'id': 'Belum ada catatan pekan ini', 'bn': 'এই সপ্তাহে এখনও কোনো নোট নেই', 'ha': 'Babu bayani a wannan mako tukuna', 'so': 'Weli qoraal toddobaadkan ma jiro', 'fa': 'هنوز یادداشتی برای این هفته نیست', 'ms': 'Belum ada catatan minggu ini'},
  'life_cycle_title': {'ar': 'مراجعة الدورة', 'en': 'Cycle review', 'am': 'የዑደት ግምገማ', 'fr': 'Bilan du cycle', 'sw': 'Mapitio ya mzunguko', 'ur': 'دور کا جائزہ', 'tr': 'Döngü değerlendirmesi', 'id': 'Tinjauan siklus', 'bn': 'চক্র পর্যালোচনা', 'ha': 'Bitar zagaye', 'so': 'Dib u eegista wareegga', 'fa': 'مرور چرخه', 'ms': 'Semakan kitaran'},
  'life_cycle_done': {'ar': 'أكملت الدورة', 'en': 'You completed cycle', 'am': 'ዑደቱን አጠናቀቅክ', 'fr': 'Vous avez terminé le cycle', 'sw': 'Umekamilisha mzunguko', 'ur': 'آپ نے دور مکمل کیا', 'tr': 'Döngüyü tamamladın', 'id': 'Kamu menyelesaikan siklus', 'bn': 'আপনি চক্র সম্পন্ন করেছেন', 'ha': 'Ka kammala zagaye', 'so': 'Waxaad dhammaystirtay wareegga', 'fa': 'چرخه را کامل کردی', 'ms': 'Anda menyelesaikan kitaran'},
  'life_cycle_days_word': {'ar': 'يومًا', 'en': 'days', 'am': 'ቀናት', 'fr': 'jours', 'sw': 'siku', 'ur': 'دن', 'tr': 'gün', 'id': 'hari', 'bn': 'দিন', 'ha': 'kwanaki', 'so': 'maalmood', 'fa': 'روز', 'ms': 'hari'},
  'life_cycle_avg': {'ar': 'متوسط الإنجاز', 'en': 'Avg. completion', 'am': 'አማካይ ማጠናቀቅ', 'fr': 'Réalisation moyenne', 'sw': 'Wastani wa ukamilishaji', 'ur': 'اوسط تکمیل', 'tr': 'Ort. tamamlama', 'id': 'Rata-rata penyelesaian', 'bn': 'গড় সম্পন্নতা', 'ha': 'Matsakaicin cikawa', 'so': 'Celceliska dhammaystirka', 'fa': 'میانگین تکمیل', 'ms': 'Purata penyiapan'},
  'life_cycle_blocks': {'ar': 'فترة أُنجزت', 'en': 'blocks done', 'am': 'የተጠናቀቁ ክፍለ ጊዜያት', 'fr': 'créneaux réalisés', 'sw': 'vipindi vilivyokamilika', 'ur': 'مکمل وقفے', 'tr': 'tamamlanan bölüm', 'id': 'blok selesai', 'bn': 'সম্পন্ন ব্লক', 'ha': 'lokutan da aka gama', 'so': 'qaybo la dhammeeyay', 'fa': 'بازه‌های انجام‌شده', 'ms': 'blok selesai'},
  'life_cycle_top_pillars': {'ar': 'أكثر المحاور إنجازًا', 'en': 'Most completed pillars', 'am': 'በጣም የተጠናቀቁ ምሰሶዎች', 'fr': 'Piliers les plus réalisés', 'sw': 'Nguzo zilizokamilishwa zaidi', 'ur': 'سب سے زیادہ مکمل ستون', 'tr': 'En çok tamamlanan sütunlar', 'id': 'Pilar paling banyak diselesaikan', 'bn': 'সর্বাধিক সম্পন্ন স্তম্ভ', 'ha': 'Ginshiƙan da aka fi kammalawa', 'so': 'Tiirarka ugu badan ee la dhammeeyay', 'fa': 'ستون‌های بیش‌ترین تکمیل', 'ms': 'Tiang paling banyak disiapkan'},
  'life_cycle_message': {'ar': 'الدورة نقطة تطوّر، لا نهاية. تأمّل ما مضى، وعدّل محاورك وفتراتك إن لزم، واحمل سلسلتك إلى الدورة القادمة. الإبداع مستمرّ.', 'en': 'A cycle is a turning point, not an end. Look back, adjust your pillars and blocks if needed, and carry your streak into the next cycle. Keep creating.', 'am': 'ዑደት መዞሪያ ነጥብ ነው፣ መጨረሻ አይደለም። ያለፈውን ተመልከት፣ አስፈላጊ ከሆነ ምሰሶዎችህንና ክፍለ ጊዜያትህን አስተካክል፣ ተከታታይነትህን ወደ ቀጣዩ ዑደት ውሰድ። መፍጠርን ቀጥል።', 'fr': 'Un cycle est un tournant, pas une fin. Regarde en arrière, ajuste tes piliers et créneaux si besoin, et porte ta série dans le cycle suivant. Continue de créer.', 'sw': 'Mzunguko ni kigeuzo, si mwisho. Tazama nyuma, rekebisha nguzo na vipindi vyako ikihitajika, na peleka mfululizo wako kwenye mzunguko ujao. Endelea kuunda.', 'ur': 'دور ایک موڑ ہے، انجام نہیں۔ پیچھے دیکھیں، ضرورت ہو تو اپنے ستون اور وقفے درست کریں، اور اپنی سلسلہ اگلے دور میں لے جائیں۔ تخلیق جاری رکھیں۔', 'tr': 'Bir döngü bir dönüm noktasıdır, son değil. Geriye bak, gerekirse sütunlarını ve bölümlerini ayarla ve serini bir sonraki döngüye taşı. Üretmeye devam et.', 'id': 'Siklus adalah titik balik, bukan akhir. Tengok ke belakang, sesuaikan pilar dan blokmu bila perlu, dan bawa rentetanmu ke siklus berikutnya. Teruslah berkarya.', 'bn': 'একটি চক্র একটি মোড়, শেষ নয়। পেছনে তাকান, প্রয়োজনে আপনার স্তম্ভ ও ব্লক সমন্বয় করুন, এবং আপনার ধারা পরবর্তী চক্রে নিয়ে যান। সৃষ্টি চালিয়ে যান।', 'ha': 'Zagaye wuri ne na juyi, ba ƙarshe ba. Duba baya, daidaita ginshiƙanka da lokutanka idan ya cancanta, ka ɗauki jerinka zuwa zagaye na gaba. Ka ci gaba da ƙirƙira.', 'so': 'Wareeg waa meel wareeg, ma aha dhammaad. Dib u fiiri, hagaaji tiirarkaaga iyo qaybahaaga haddii loo baahdo, oo u qaad taxanahaaga wareegga xiga. Sii wad hal-abuurka.', 'fa': 'چرخه یک نقطهٔ عطف است، نه پایان. به گذشته نگاه کن، در صورت نیاز ستون‌ها و بازه‌هایت را تنظیم کن، و زنجیره‌ات را به چرخهٔ بعد ببر. آفرینش را ادامه بده.', 'ms': 'Kitaran ialah titik peralihan, bukan pengakhiran. Lihat semula, laraskan tiang dan blok anda jika perlu, dan bawa rentetan anda ke kitaran seterusnya. Teruskan mencipta.'},
  'life_cycle_reflect_label': {'ar': 'تأمّل الدورة', 'en': 'Cycle reflection', 'am': 'የዑደት ማሰላሰል', 'fr': 'Réflexion sur le cycle', 'sw': 'Tafakari ya mzunguko', 'ur': 'دور پر غور', 'tr': 'Döngü üzerine düşünce', 'id': 'Refleksi siklus', 'bn': 'চক্র নিয়ে চিন্তন', 'ha': 'Tunani kan zagaye', 'so': 'Milicsiga wareegga', 'fa': 'تأمل چرخه', 'ms': 'Renungan kitaran'},
  'life_cycle_reflect_hint': {'ar': 'أهمّ درس من هذه الـ90 يومًا، وما ستغيّره', 'en': 'The biggest lesson from these 90 days, and what you’ll change', 'am': 'ከእነዚህ 90 ቀናት ትልቁ ትምህርት፣ እና የምትቀይረው', 'fr': 'La plus grande leçon de ces 90 jours, et ce que tu changeras', 'sw': 'Somo kubwa zaidi kutoka siku hizi 90, na utakachobadilisha', 'ur': 'ان 90 دنوں کا سب سے بڑا سبق، اور آپ کیا بدلیں گے', 'tr': 'Bu 90 günün en büyük dersi ve neyi değiştireceğin', 'id': 'Pelajaran terbesar dari 90 hari ini, dan apa yang akan kamu ubah', 'bn': 'এই ৯০ দিনের সবচেয়ে বড় শিক্ষা, এবং আপনি কী পরিবর্তন করবেন', 'ha': 'Babban darasi daga waɗannan kwanaki 90, da abin da za ka canza', 'so': 'Casharka ugu weyn ee 90-kan maalmood, iyo waxa aad bedeli doonto', 'fa': 'بزرگ‌ترین درس این ۹۰ روز، و آنچه تغییر خواهی داد', 'ms': 'Pengajaran terbesar daripada 90 hari ini, dan apa yang anda akan ubah'},
  'life_cycle_start_next': {'ar': 'ابدأ الدورة', 'en': 'Start cycle', 'am': 'ዑደት ጀምር', 'fr': 'Commencer le cycle', 'sw': 'Anza mzunguko', 'ur': 'دور شروع کریں', 'tr': 'Döngüyü başlat', 'id': 'Mulai siklus', 'bn': 'চক্র শুরু করুন', 'ha': 'Fara zagaye', 'so': 'Bilow wareegga', 'fa': 'شروع چرخه', 'ms': 'Mula kitaran'},
  'life_edit_plan': {'ar': 'تعديل الخطة', 'en': 'Edit plan', 'am': 'እቅድ አርትዕ', 'fr': 'Modifier le plan', 'sw': 'Hariri mpango', 'ur': 'منصوبہ ترمیم کریں', 'tr': 'Planı düzenle', 'id': 'Edit rencana', 'bn': 'পরিকল্পনা সম্পাদনা', 'ha': 'Gyara shirin', 'so': 'Wax ka beddel qorshaha', 'fa': 'ویرایش برنامه', 'ms': 'Sunting pelan'},
  'life_tab_pillars': {'ar': 'المحاور', 'en': 'Pillars', 'am': 'ምሰሶዎች', 'fr': 'Piliers', 'sw': 'Nguzo', 'ur': 'ستون', 'tr': 'Sütunlar', 'id': 'Pilar', 'bn': 'স্তম্ভ', 'ha': 'Ginshiƙai', 'so': 'Tiirar', 'fa': 'ستون‌ها', 'ms': 'Tiang'},
  'life_tab_slots': {'ar': 'الفترات', 'en': 'Blocks', 'am': 'ክፍለ ጊዜያት', 'fr': 'Créneaux', 'sw': 'Vipindi', 'ur': 'وقفے', 'tr': 'Bölümler', 'id': 'Blok', 'bn': 'ব্লক', 'ha': 'Lokuta', 'so': 'Qaybaha', 'fa': 'بازه‌ها', 'ms': 'Blok'},
  'life_add': {'ar': 'إضافة', 'en': 'Add', 'am': 'አክል', 'fr': 'Ajouter', 'sw': 'Ongeza', 'ur': 'شامل کریں', 'tr': 'Ekle', 'id': 'Tambah', 'bn': 'যোগ', 'ha': 'Ƙara', 'so': 'Ku dar', 'fa': 'افزودن', 'ms': 'Tambah'},
  'life_no_pillars': {'ar': 'لا محاور بعد — أضِف واحدًا.', 'en': 'No pillars yet — add one.', 'am': 'ገና ምሰሶ የለም — አንድ አክል።', 'fr': 'Aucun pilier — ajoutez-en un.', 'sw': 'Hakuna nguzo bado — ongeza moja.', 'ur': 'ابھی کوئی ستون نہیں — ایک شامل کریں۔', 'tr': 'Henüz sütun yok — bir tane ekleyin.', 'id': 'Belum ada pilar — tambahkan satu.', 'bn': 'এখনও কোনো স্তম্ভ নেই — একটি যোগ করুন।', 'ha': 'Babu ginshiƙai tukuna — ƙara ɗaya.', 'so': 'Weli ma jiro tiir — ku dar mid.', 'fa': 'هنوز ستونی نیست — یکی اضافه کنید.', 'ms': 'Belum ada tiang — tambah satu.'},
  'life_no_slots': {'ar': 'لا فترات بعد — أضِف واحدة.', 'en': 'No blocks yet — add one.', 'am': 'ገና ክፍለ ጊዜ የለም — አንድ አክል።', 'fr': 'Aucun créneau — ajoutez-en un.', 'sw': 'Hakuna vipindi bado — ongeza kimoja.', 'ur': 'ابھی کوئی وقفہ نہیں — ایک شامل کریں۔', 'tr': 'Henüz bölüm yok — bir tane ekleyin.', 'id': 'Belum ada blok — tambahkan satu.', 'bn': 'এখনও কোনো ব্লক নেই — একটি যোগ করুন।', 'ha': 'Babu lokuta tukuna — ƙara ɗaya.', 'so': 'Weli ma jiro qayb — ku dar mid.', 'fa': 'هنوز بازه‌ای نیست — یکی اضافه کنید.', 'ms': 'Belum ada blok — tambah satu.'},
  'life_untitled': {'ar': 'بلا اسم', 'en': 'Untitled', 'am': 'ርዕስ የለም', 'fr': 'Sans titre', 'sw': 'Bila jina', 'ur': 'بے عنوان', 'tr': 'Adsız', 'id': 'Tanpa judul', 'bn': 'শিরোনামহীন', 'ha': 'Ba suna', 'so': 'Cinwaan la’aan', 'fa': 'بی‌عنوان', 'ms': 'Tanpa tajuk'},
  'life_no_pillar': {'ar': 'بلا محور', 'en': 'No pillar', 'am': 'ምሰሶ የለም', 'fr': 'Aucun pilier', 'sw': 'Bila nguzo', 'ur': 'کوئی ستون نہیں', 'tr': 'Sütun yok', 'id': 'Tanpa pilar', 'bn': 'স্তম্ভ নেই', 'ha': 'Babu ginshiƙi', 'so': 'Tiir ma leh', 'fa': 'بدون ستون', 'ms': 'Tiada tiang'},
  'life_archive': {'ar': 'أرشفة', 'en': 'Archive', 'am': 'አርኪቭ', 'fr': 'Archiver', 'sw': 'Weka kwenye kumbukumbu', 'ur': 'آرکائیو', 'tr': 'Arşivle', 'id': 'Arsipkan', 'bn': 'সংরক্ষণাগার', 'ha': 'Adana ajiya', 'so': 'Kaydi', 'fa': 'بایگانی', 'ms': 'Arkib'},
  'life_restore': {'ar': 'استعادة', 'en': 'Restore', 'am': 'መልስ', 'fr': 'Restaurer', 'sw': 'Rejesha', 'ur': 'بحال کریں', 'tr': 'Geri yükle', 'id': 'Pulihkan', 'bn': 'পুনরুদ্ধার', 'ha': 'Maido', 'so': 'Soo celi', 'fa': 'بازگردانی', 'ms': 'Pulih'},
  'life_show_archived': {'ar': 'إظهار المؤرشفة', 'en': 'Show archived', 'am': 'የተከማቹ አሳይ', 'fr': 'Afficher les archivés', 'sw': 'Onyesha zilizohifadhiwa', 'ur': 'آرکائیو شدہ دکھائیں', 'tr': 'Arşivlenenleri göster', 'id': 'Tampilkan yang diarsipkan', 'bn': 'সংরক্ষিত দেখান', 'ha': 'Nuna waɗanda aka adana', 'so': 'Muuji kuwa la kaydiyay', 'fa': 'نمایش بایگانی‌شده‌ها', 'ms': 'Tunjuk yang diarkib'},
  'life_hide_archived': {'ar': 'إخفاء المؤرشفة', 'en': 'Hide archived', 'am': 'የተከማቹ ደብቅ', 'fr': 'Masquer les archivés', 'sw': 'Ficha zilizohifadhiwa', 'ur': 'آرکائیو شدہ چھپائیں', 'tr': 'Arşivlenenleri gizle', 'id': 'Sembunyikan yang diarsipkan', 'bn': 'সংরক্ষিত লুকান', 'ha': 'Ɓoye waɗanda aka adana', 'so': 'Qari kuwa la kaydiyay', 'fa': 'پنهان کردن بایگانی‌شده‌ها', 'ms': 'Sembunyi yang diarkib'},
  'life_reset_plan': {'ar': 'استعادة الخطة الأصلية', 'en': 'Restore original plan', 'am': 'የመጀመሪያውን እቅድ መልስ', 'fr': 'Restaurer le plan d’origine', 'sw': 'Rejesha mpango asilia', 'ur': 'اصل منصوبہ بحال کریں', 'tr': 'Özgün planı geri yükle', 'id': 'Pulihkan rencana asli', 'bn': 'মূল পরিকল্পনা পুনরুদ্ধার', 'ha': 'Maido shirin asali', 'so': 'Soo celi qorshihii asalka', 'fa': 'بازگردانی برنامهٔ اصلی', 'ms': 'Pulih pelan asal'},
  'life_reset_plan_confirm': {'ar': 'سيُستبدل كل المحاور والفترات بالخطة الأصلية (7 محاور و23 فترة). إنجازك السابق يبقى محفوظًا.', 'en': 'All pillars and blocks will be replaced with the original plan (7 pillars, 23 blocks). Your past progress is kept.', 'am': 'ሁሉም ምሰሶዎችና ክፍለ ጊዜያት በመጀመሪያው እቅድ ይተካሉ (7 ምሰሶ፣ 23 ክፍለ ጊዜ)። ያለፈው እድገትህ ይቀመጣል።', 'fr': 'Tous les piliers et créneaux seront remplacés par le plan d’origine (7 piliers, 23 créneaux). Votre progression passée est conservée.', 'sw': 'Nguzo na vipindi vyote vitabadilishwa na mpango asilia (nguzo 7, vipindi 23). Maendeleo yako ya awali yanahifadhiwa.', 'ur': 'تمام ستون اور وقفے اصل منصوبے سے بدل دیے جائیں گے (7 ستون، 23 وقفے)۔ آپ کی پچھلی پیش رفت محفوظ رہے گی۔', 'tr': 'Tüm sütunlar ve bölümler özgün planla değiştirilecek (7 sütun, 23 bölüm). Geçmiş ilerlemeniz korunur.', 'id': 'Semua pilar dan blok akan diganti dengan rencana asli (7 pilar, 23 blok). Progres lampau Anda tetap tersimpan.', 'bn': 'সব স্তম্ভ ও ব্লক মূল পরিকল্পনা দিয়ে প্রতিস্থাপিত হবে (৭ স্তম্ভ, ২৩ ব্লক)। আপনার আগের অগ্রগতি রক্ষিত থাকবে।', 'ha': 'Duk ginshiƙai da lokuta za a maye su da shirin asali (ginshiƙai 7, lokuta 23). Ci gaban ka na baya yana nan.', 'so': 'Dhammaan tiirarka iyo qaybaha waxaa lagu beddeli doonaa qorshihii asalka (7 tiir, 23 qayb). Horumarkaagii hore waa la hayaa.', 'fa': 'همهٔ ستون‌ها و بازه‌ها با برنامهٔ اصلی جایگزین می‌شوند (۷ ستون، ۲۳ بازه). پیشرفت گذشتهٔ شما حفظ می‌شود.', 'ms': 'Semua tiang dan blok akan diganti dengan pelan asal (7 tiang, 23 blok). Kemajuan lampau anda dikekalkan.'},
  'life_reset_plan_do': {'ar': 'استعادة', 'en': 'Restore', 'am': 'መልስ', 'fr': 'Restaurer', 'sw': 'Rejesha', 'ur': 'بحال کریں', 'tr': 'Geri yükle', 'id': 'Pulihkan', 'bn': 'পুনরুদ্ধার', 'ha': 'Maido', 'so': 'Soo celi', 'fa': 'بازگردانی', 'ms': 'Pulih'},
  'life_cadence_daily': {'ar': 'يومي', 'en': 'Daily', 'am': 'ዕለታዊ', 'fr': 'Quotidien', 'sw': 'Kila siku', 'ur': 'روزانہ', 'tr': 'Günlük', 'id': 'Harian', 'bn': 'দৈনিক', 'ha': 'Kullum', 'so': 'Maalinle', 'fa': 'روزانه', 'ms': 'Harian'},
  'life_cadence_weekly': {'ar': 'أسبوعي', 'en': 'Weekly', 'am': 'ሳምንታዊ', 'fr': 'Hebdomadaire', 'sw': 'Kila wiki', 'ur': 'ہفتہ وار', 'tr': 'Haftalık', 'id': 'Mingguan', 'bn': 'সাপ্তাহিক', 'ha': 'Mako-mako', 'so': 'Toddobaadle', 'fa': 'هفتگی', 'ms': 'Mingguan'},
  'life_add_pillar': {'ar': 'محور جديد', 'en': 'New pillar', 'am': 'አዲስ ምሰሶ', 'fr': 'Nouveau pilier', 'sw': 'Nguzo mpya', 'ur': 'نیا ستون', 'tr': 'Yeni sütun', 'id': 'Pilar baru', 'bn': 'নতুন স্তম্ভ', 'ha': 'Sabon ginshiƙi', 'so': 'Tiir cusub', 'fa': 'ستون جدید', 'ms': 'Tiang baharu'},
  'life_edit_pillar': {'ar': 'تعديل المحور', 'en': 'Edit pillar', 'am': 'ምሰሶ አርትዕ', 'fr': 'Modifier le pilier', 'sw': 'Hariri nguzo', 'ur': 'ستون ترمیم کریں', 'tr': 'Sütunu düzenle', 'id': 'Edit pilar', 'bn': 'স্তম্ভ সম্পাদনা', 'ha': 'Gyara ginshiƙi', 'so': 'Wax ka beddel tiirka', 'fa': 'ویرایش ستون', 'ms': 'Sunting tiang'},
  'life_field_name': {'ar': 'الاسم', 'en': 'Name', 'am': 'ስም', 'fr': 'Nom', 'sw': 'Jina', 'ur': 'نام', 'tr': 'Ad', 'id': 'Nama', 'bn': 'নাম', 'ha': 'Suna', 'so': 'Magaca', 'fa': 'نام', 'ms': 'Nama'},
  'life_field_emoji': {'ar': 'رمز', 'en': 'Emoji', 'am': 'ኢሞጂ', 'fr': 'Émoji', 'sw': 'Emoji', 'ur': 'ایموجی', 'tr': 'Emoji', 'id': 'Emoji', 'bn': 'ইমোজি', 'ha': 'Emoji', 'so': 'Emoji', 'fa': 'ایموجی', 'ms': 'Emoji'},
  'life_field_target': {'ar': 'الهدف', 'en': 'Target', 'am': 'ዒላማ', 'fr': 'Objectif', 'sw': 'Lengo', 'ur': 'ہدف', 'tr': 'Hedef', 'id': 'Target', 'bn': 'লক্ষ্য', 'ha': 'Manufa', 'so': 'Bartilmaameed', 'fa': 'هدف', 'ms': 'Sasaran'},
  'life_field_target_hint': {'ar': 'مثل: يومي · 4 فيديو/أسبوع', 'en': 'e.g. daily · 4 videos/week', 'am': 'ለምሳሌ፡ ዕለታዊ · 4 ቪዲዮ/ሳምንት', 'fr': 'ex. quotidien · 4 vidéos/sem.', 'sw': 'mf. kila siku · video 4/wiki', 'ur': 'مثلاً: روزانہ · 4 ویڈیو/ہفتہ', 'tr': 'örn. günlük · 4 video/hafta', 'id': 'mis. harian · 4 video/pekan', 'bn': 'যেমন: দৈনিক · ৪ ভিডিও/সপ্তাহ', 'ha': 'misali: kullum · bidiyo 4/mako', 'so': 'tusaale: maalinle · 4 muuqaal/toddobaad', 'fa': 'مثلاً: روزانه · ۴ ویدیو/هفته', 'ms': 'cth. harian · 4 video/minggu'},
  'life_field_cadence': {'ar': 'الإيقاع', 'en': 'Cadence', 'am': 'ምት', 'fr': 'Rythme', 'sw': 'Mdundo', 'ur': 'تعدد', 'tr': 'Ritim', 'id': 'Irama', 'bn': 'ছন্দ', 'ha': 'Tsari', 'so': 'Xawaaraha', 'fa': 'آهنگ', 'ms': 'Irama'},
  'life_field_weekly_target': {'ar': 'الهدف الأسبوعي', 'en': 'Weekly target', 'am': 'ሳምንታዊ ዒላማ', 'fr': 'Objectif hebdo', 'sw': 'Lengo la wiki', 'ur': 'ہفتہ وار ہدف', 'tr': 'Haftalık hedef', 'id': 'Target mingguan', 'bn': 'সাপ্তাহিক লক্ষ্য', 'ha': 'Manufar mako', 'so': 'Bartilmaameedka toddobaadka', 'fa': 'هدف هفتگی', 'ms': 'Sasaran mingguan'},
  'life_field_color': {'ar': 'اللون', 'en': 'Color', 'am': 'ቀለም', 'fr': 'Couleur', 'sw': 'Rangi', 'ur': 'رنگ', 'tr': 'Renk', 'id': 'Warna', 'bn': 'রঙ', 'ha': 'Launi', 'so': 'Midabka', 'fa': 'رنگ', 'ms': 'Warna'},
  'life_add_slot': {'ar': 'فترة جديدة', 'en': 'New block', 'am': 'አዲስ ክፍለ ጊዜ', 'fr': 'Nouveau créneau', 'sw': 'Kipindi kipya', 'ur': 'نیا وقفہ', 'tr': 'Yeni bölüm', 'id': 'Blok baru', 'bn': 'নতুন ব্লক', 'ha': 'Sabon lokaci', 'so': 'Qayb cusub', 'fa': 'بازهٔ جدید', 'ms': 'Blok baharu'},
  'life_add_block_inline': {'ar': 'أضِف فترة', 'en': 'Add a block', 'am': 'ክፍለ ጊዜ አክል', 'fr': 'Ajouter un créneau', 'sw': 'Ongeza kipindi', 'ur': 'وقفہ شامل کریں', 'tr': 'Bölüm ekle', 'id': 'Tambah blok', 'bn': 'ব্লক যোগ করুন', 'ha': 'Ƙara lokaci', 'so': 'Ku dar qayb', 'fa': 'افزودن بازه', 'ms': 'Tambah blok'},
  'life_edit_slot': {'ar': 'تعديل الفترة', 'en': 'Edit block', 'am': 'ክፍለ ጊዜ አርትዕ', 'fr': 'Modifier le créneau', 'sw': 'Hariri kipindi', 'ur': 'وقفہ ترمیم کریں', 'tr': 'Bölümü düzenle', 'id': 'Edit blok', 'bn': 'ব্লক সম্পাদনা', 'ha': 'Gyara lokaci', 'so': 'Wax ka beddel qaybta', 'fa': 'ویرایش بازه', 'ms': 'Sunting blok'},
  'life_field_start': {'ar': 'من', 'en': 'From', 'am': 'ከ', 'fr': 'De', 'sw': 'Kuanzia', 'ur': 'سے', 'tr': 'Başlangıç', 'id': 'Dari', 'bn': 'থেকে', 'ha': 'Daga', 'so': 'Laga', 'fa': 'از', 'ms': 'Dari'},
  'life_field_end': {'ar': 'إلى', 'en': 'To', 'am': 'እስከ', 'fr': 'À', 'sw': 'Hadi', 'ur': 'تک', 'tr': 'Bitiş', 'id': 'Sampai', 'bn': 'পর্যন্ত', 'ha': 'Zuwa', 'so': 'Ilaa', 'fa': 'تا', 'ms': 'Ke'},
  'life_field_activity': {'ar': 'النشاط', 'en': 'Activity', 'am': 'እንቅስቃሴ', 'fr': 'Activité', 'sw': 'Shughuli', 'ur': 'سرگرمی', 'tr': 'Etkinlik', 'id': 'Aktivitas', 'bn': 'কার্যকলাপ', 'ha': 'Aiki', 'so': 'Dhaqdhaqaaqa', 'fa': 'فعالیت', 'ms': 'Aktiviti'},
  'life_field_pillar': {'ar': 'المحور', 'en': 'Pillar', 'am': 'ምሰሶ', 'fr': 'Pilier', 'sw': 'Nguzo', 'ur': 'ستون', 'tr': 'Sütun', 'id': 'Pilar', 'bn': 'স্তম্ভ', 'ha': 'Ginshiƙi', 'so': 'Tiirka', 'fa': 'ستون', 'ms': 'Tiang'},
  'life_field_category': {'ar': 'التصنيف', 'en': 'Category', 'am': 'ምድብ', 'fr': 'Catégorie', 'sw': 'Kategoria', 'ur': 'زمرہ', 'tr': 'Kategori', 'id': 'Kategori', 'bn': 'বিভাগ', 'ha': 'Rukuni', 'so': 'Qaybta', 'fa': 'دسته', 'ms': 'Kategori'},
  'life_field_category_hint': {'ar': 'مثل: روحي · صحة · تطوير', 'en': 'e.g. spiritual · health · growth', 'am': 'ለምሳሌ፡ መንፈሳዊ · ጤና · እድገት', 'fr': 'ex. spirituel · santé · progrès', 'sw': 'mf. kiroho · afya · ukuaji', 'ur': 'مثلاً: روحانی · صحت · نمو', 'tr': 'örn. ruhsal · sağlık · gelişim', 'id': 'mis. spiritual · kesehatan · pertumbuhan', 'bn': 'যেমন: আধ্যাত্মিক · স্বাস্থ্য · বিকাশ', 'ha': 'misali: na ruhi · lafiya · ci gaba', 'so': 'tusaale: ruuxi · caafimaad · koritaan', 'fa': 'مثلاً: معنوی · سلامت · رشد', 'ms': 'cth. rohani · kesihatan · pertumbuhan'},
  'life_tab_tasks': {'ar': 'المهام', 'en': 'Tasks', 'am': 'ተግባራት', 'fr': 'Tâches', 'sw': 'Kazi', 'ur': 'ٹاسک', 'tr': 'Görevler', 'id': 'Tugas', 'bn': 'কাজ', 'ha': 'Ayyuka', 'so': 'Hawlaha', 'fa': 'وظایف', 'ms': 'Tugas'},
  'life_tasks_section': {'ar': 'المهام', 'en': 'Tasks', 'am': 'ተግባራት', 'fr': 'Tâches', 'sw': 'Kazi', 'ur': 'ٹاسک', 'tr': 'Görevler', 'id': 'Tugas', 'bn': 'কাজ', 'ha': 'Ayyuka', 'so': 'Hawlaha', 'fa': 'وظایف', 'ms': 'Tugas'},
  'life_mit_title': {'ar': 'أهمّ 3 لليوم', 'en': 'Today’s top 3', 'am': 'የዛሬ ከፍተኛ 3', 'fr': 'Top 3 du jour', 'sw': '3 muhimu za leo', 'ur': 'آج کے اہم 3', 'tr': 'Bugünün ilk 3’ü', 'id': '3 utama hari ini', 'bn': 'আজকের শীর্ষ ৩', 'ha': 'Manyan 3 na yau', 'so': '3-da ugu muhiimsan maanta', 'fa': '۳ اولویت امروز', 'ms': '3 utama hari ini'},
  'life_mit_hint': {'ar': 'أضِف أولويّة…', 'en': 'Add a priority…', 'am': 'ቅድሚያ ጨምር…', 'fr': 'Ajouter une priorité…', 'sw': 'Ongeza kipaumbele…', 'ur': 'ترجیح شامل کریں…', 'tr': 'Öncelik ekle…', 'id': 'Tambah prioritas…', 'bn': 'অগ্রাধিকার যোগ করুন…', 'ha': 'Ƙara fifiko…', 'so': 'Ku dar mudnaan…', 'fa': 'یک اولویت اضافه کنید…', 'ms': 'Tambah keutamaan…'},
  'life_no_tasks': {'ar': 'لا مهام بعد — أضِف واحدة.', 'en': 'No tasks yet — add one.', 'am': 'ገና ተግባር የለም — አንድ አክል።', 'fr': 'Aucune tâche — ajoutez-en une.', 'sw': 'Hakuna kazi bado — ongeza moja.', 'ur': 'ابھی کوئی ٹاسک نہیں — ایک شامل کریں۔', 'tr': 'Henüz görev yok — bir tane ekleyin.', 'id': 'Belum ada tugas — tambahkan satu.', 'bn': 'এখনও কোনো কাজ নেই — একটি যোগ করুন।', 'ha': 'Babu ayyuka tukuna — ƙara ɗaya.', 'so': 'Weli ma jiro hawl — ku dar mid.', 'fa': 'هنوز وظیفه‌ای نیست — یکی اضافه کنید.', 'ms': 'Belum ada tugas — tambah satu.'},
  'life_add_task': {'ar': 'مهمة جديدة', 'en': 'New task', 'am': 'አዲስ ተግባር', 'fr': 'Nouvelle tâche', 'sw': 'Kazi mpya', 'ur': 'نیا ٹاسک', 'tr': 'Yeni görev', 'id': 'Tugas baru', 'bn': 'নতুন কাজ', 'ha': 'Sabon aiki', 'so': 'Hawl cusub', 'fa': 'وظیفهٔ جدید', 'ms': 'Tugas baharu'},
  'life_edit_task': {'ar': 'تعديل المهمة', 'en': 'Edit task', 'am': 'ተግባር አርትዕ', 'fr': 'Modifier la tâche', 'sw': 'Hariri kazi', 'ur': 'ٹاسک ترمیم کریں', 'tr': 'Görevi düzenle', 'id': 'Edit tugas', 'bn': 'কাজ সম্পাদনা', 'ha': 'Gyara aiki', 'so': 'Wax ka beddel hawsha', 'fa': 'ویرایش وظیفه', 'ms': 'Sunting tugas'},
  'life_field_task_title': {'ar': 'المهمة', 'en': 'Task', 'am': 'ተግባር', 'fr': 'Tâche', 'sw': 'Kazi', 'ur': 'ٹاسک', 'tr': 'Görev', 'id': 'Tugas', 'bn': 'কাজ', 'ha': 'Aiki', 'so': 'Hawsha', 'fa': 'وظیفه', 'ms': 'Tugas'},
  'life_field_task_kind': {'ar': 'النوع', 'en': 'Type', 'am': 'ዓይነት', 'fr': 'Type', 'sw': 'Aina', 'ur': 'قسم', 'tr': 'Tür', 'id': 'Jenis', 'bn': 'ধরন', 'ha': 'Nau’i', 'so': 'Nooca', 'fa': 'نوع', 'ms': 'Jenis'},
  'life_task_milestone': {'ar': 'معلَم', 'en': 'Milestone', 'am': 'ምዕራፍ', 'fr': 'Jalon', 'sw': 'Hatua', 'ur': 'سنگ میل', 'tr': 'Kilometre taşı', 'id': 'Tonggak', 'bn': 'মাইলফলক', 'ha': 'Matakin ci gaba', 'so': 'Marinduub', 'fa': 'نقطهٔ عطف', 'ms': 'Pencapaian'},
  'life_field_qty_target': {'ar': 'هدف رقمي', 'en': 'Numeric target', 'am': 'ቁጥራዊ ዒላማ', 'fr': 'Objectif chiffré', 'sw': 'Lengo la idadi', 'ur': 'عددی ہدف', 'tr': 'Sayısal hedef', 'id': 'Target angka', 'bn': 'সংখ্যাগত লক্ষ্য', 'ha': 'Manufar lamba', 'so': 'Bartilmaameed tiro', 'fa': 'هدف عددی', 'ms': 'Sasaran angka'},
  'life_qty_off': {'ar': 'بلا', 'en': 'Off', 'am': 'የለም', 'fr': 'Aucun', 'sw': 'Hakuna', 'ur': 'نہیں', 'tr': 'Kapalı', 'id': 'Nonaktif', 'bn': 'নেই', 'ha': 'Babu', 'so': 'Ma jiro', 'fa': 'خاموش', 'ms': 'Tiada'},
  'life_field_qty_unit': {'ar': 'الوحدة', 'en': 'Unit', 'am': 'አሃድ', 'fr': 'Unité', 'sw': 'Kipimo', 'ur': 'اکائی', 'tr': 'Birim', 'id': 'Satuan', 'bn': 'একক', 'ha': 'Naúni', 'so': 'Cutub', 'fa': 'واحد', 'ms': 'Unit'},
  'life_field_qty_unit_hint': {'ar': 'صفحة · دقيقة · فيديو', 'en': 'page · minute · video', 'am': 'ገጽ · ደቂቃ · ቪዲዮ', 'fr': 'page · minute · vidéo', 'sw': 'ukurasa · dakika · video', 'ur': 'صفحہ · منٹ · ویڈیو', 'tr': 'sayfa · dakika · video', 'id': 'halaman · menit · video', 'bn': 'পৃষ্ঠা · মিনিট · ভিডিও', 'ha': 'shafi · minti · bidiyo', 'so': 'bog · daqiiqad · muuqaal', 'fa': 'صفحه · دقیقه · ویدیو', 'ms': 'halaman · minit · video'},
  // ---- Study benefits map (79-sa-E)
  'study_map_title': {
    'ar': 'خريطة الفوائد', 'en': 'Benefits map', 'am': 'የጥቅሞች ካርታ', 'fr': "Carte des bénéfices", 'sw': 'Ramani ya faida',
    'ur': 'فوائد کا نقشہ', 'tr': 'Faydalar haritası', 'id': 'Peta faedah', 'bn': 'উপকারিতার মানচিত্র', 'ha': "Taswirar fa'idodi",
    'so': 'Khariidadda faaʼiidooyinka', 'fa': 'نقشه فواید', 'ms': 'Peta faedah',
  },
  'study_map_empty': {
    'ar': 'لا فوائد بعد', 'en': 'No benefits yet', 'am': 'እስካሁን ጥቅም የለም', 'fr': "Aucun bénéfice pour l'instant", 'sw': 'Bado hakuna faida',
    'ur': 'ابھی کوئی فائدہ نہیں', 'tr': 'Henüz fayda yok', 'id': 'Belum ada faedah', 'bn': 'এখনও কোনো উপকারিতা নেই', 'ha': "Babu fa'ida tukuna",
    'so': "Weli faaʼiido ma jirto", 'fa': 'هنوز فایده‌ای نیست', 'ms': 'Belum ada faedah',
  },
  'study_map_total': {
    'ar': 'الإجمالي', 'en': 'Total', 'am': 'ጠቅላላ', 'fr': 'Total', 'sw': 'Jumla',
    'ur': 'کل', 'tr': 'Toplam', 'id': 'Total', 'bn': 'মোট', 'ha': "Jimla",
    'so': 'Wadarta', 'fa': 'مجموع', 'ms': 'Jumlah',
  },
  'study_map_with_note': {
    'ar': 'مع ملاحظة', 'en': 'With a note', 'am': 'ከማስታወሻ ጋር', 'fr': "Avec une note", 'sw': 'Zenye dokezo',
    'ur': 'نوٹ کے ساتھ', 'tr': 'Notlu', 'id': 'Dengan catatan', 'bn': 'নোট সহ', 'ha': "Mai bayanin kula",
    'so': 'Leh qoraal', 'fa': 'دارای یادداشت', 'ms': 'Dengan nota',
  },
  'study_map_orphans': {
    'ar': 'تغيّر موضعها', 'en': 'Position lost', 'am': 'ቦታቸው ጠፍቷል', 'fr': "Position perdue", 'sw': 'Nafasi imepotea',
    'ur': 'مقام کھو گیا', 'tr': 'Konumu kayıp', 'id': 'Posisi hilang', 'bn': 'অবস্থান হারিয়ে গেছে', 'ha': "Wurin ya ɓace",
    'so': 'Booska waa la waayay', 'fa': 'موقعیت گم شد', 'ms': 'Kedudukan hilang',
  },
  'study_map_by_color': {
    'ar': 'حسب اللون', 'en': 'By colour', 'am': 'በቀለም', 'fr': 'Par couleur', 'sw': 'Kwa rangi',
    'ur': 'رنگ کے لحاظ سے', 'tr': 'Renge göre', 'id': 'Menurut warna', 'bn': 'রঙ অনুসারে', 'ha': "Bisa launi",
    'so': 'Midabka', 'fa': 'بر اساس رنگ', 'ms': 'Mengikut warna',
  },
  'study_map_by_category': {
    'ar': 'حسب التصنيف', 'en': 'By category', 'am': 'በምድብ', 'fr': 'Par catégorie', 'sw': 'Kwa kategoria',
    'ur': 'زمرے کے لحاظ سے', 'tr': 'Kategoriye göre', 'id': 'Menurut kategori', 'bn': 'বিভাগ অনুসারে', 'ha': "Bisa rukuni",
    'so': 'Qaybta', 'fa': 'بر اساس دسته', 'ms': 'Mengikut kategori',
  },
  'study_map_by_book': {
    'ar': 'حسب الكتاب', 'en': 'By book', 'am': 'በመጽሐፍ', 'fr': 'Par livre', 'sw': 'Kwa kitabu',
    'ur': 'کتاب کے لحاظ سے', 'tr': 'Kitaba göre', 'id': 'Menurut kitab', 'bn': 'কিতাব অনুসারে', 'ha': "Bisa littafi",
    'so': 'Kitaabka', 'fa': 'بر اساس کتاب', 'ms': 'Mengikut kitab',
  },
  'study_map_by_author': {
    'ar': 'حسب المؤلف', 'en': 'By author', 'am': 'በደራሲ', 'fr': 'Par auteur', 'sw': 'Kwa mwandishi',
    'ur': 'مصنف کے لحاظ سے', 'tr': 'Yazara göre', 'id': 'Menurut penulis', 'bn': 'লেখক অনুসারে', 'ha': "Bisa marubuci",
    'so': 'Qoraaga', 'fa': 'بر اساس مؤلف', 'ms': 'Mengikut pengarang',
  },
  'study_map_export_action': {
    'ar': 'تصدير', 'en': 'Export', 'am': 'ላክ', 'fr': 'Exporter', 'sw': 'Hamisha',
    'ur': 'برآمد', 'tr': 'Dışa aktar', 'id': 'Ekspor', 'bn': 'রপ্তানি', 'ha': "Fitarwa",
    'so': 'Dhoofi', 'fa': 'برون‌بری', 'ms': 'Eksport',
  },
  'study_map_export_subject': {
    'ar': 'فوائدي من المكتبة التراثية', 'en': 'My benefits from the Turath library', 'am': 'ከቱራስ ቤተ-መጻሕፍት ያገኘኋቸው ጥቅሞች', 'fr': "Mes bénéfices de la bibliothèque Turath", 'sw': 'Faida zangu kutoka maktaba ya Turath',
    'ur': 'مکتبۂ تراث سے میرے فوائد', 'tr': 'Turath kütüphanesinden faydalarım', 'id': 'Faedah saya dari perpustakaan Turath', 'bn': 'তুরাস লাইব্রেরি থেকে আমার উপকারিতা', 'ha': "Fa'idodina daga ɗakin karatu na Turath",
    'so': 'Faaʼiidooyinkayga maktabadda Turath', 'fa': 'فواید من از کتابخانه تراث', 'ms': 'Faedah saya dari perpustakaan Turath',
  },
  'study_map_nothing_to_export': {
    'ar': 'لا شيء للتصدير بعد', 'en': 'Nothing to export yet', 'am': 'ለማላክ ምንም የለም', 'fr': "Rien à exporter pour l'instant", 'sw': 'Hakuna cha kuhamisha bado',
    'ur': 'ابھی برآمد کرنے کے لیے کچھ نہیں', 'tr': 'Henüz dışa aktarılacak bir şey yok', 'id': 'Belum ada yang bisa diekspor', 'bn': 'এখনও রপ্তানি করার কিছু নেই', 'ha': "Babu abin da za a fitar tukuna",
    'so': 'Weli waxba lama dhoofin karo', 'fa': 'هنوز چیزی برای برون‌بری نیست', 'ms': 'Belum ada apa-apa untuk dieksport',
  },
  'turath_reanchor_action': {
    'ar': 'أعد ربطها', 'en': 'Re-anchor', 'am': 'እንደገና አያይዝ', 'fr': "Ré-ancrer", 'sw': 'Fungasha tena',
    'ur': 'دوبارہ جوڑیں', 'tr': 'Yeniden bağla', 'id': 'Tautkan ulang', 'bn': 'পুনরায় সংযুক্ত করুন', 'ha': "Sāke haɗawa",
    'so': 'Dib u xidh', 'fa': 'اتصال دوباره', 'ms': 'Pautan semula',
  },
  'turath_notebook_title': {
    'ar': 'دفتر الفوائد', 'en': 'Study notebook', 'am': 'የጥናት ማስታወሻ', 'fr': "Carnet d'étude", 'sw': 'Daftari la masomo',
    'ur': 'مطالعہ نوٹ بک', 'tr': 'Çalışma defteri', 'id': 'Buku catatan belajar', 'bn': 'অধ্যয়ন নোটবুক', 'ha': "Littafin rubutun karatu",
    'so': 'Buugga faa\'iidooyinka', 'fa': 'دفترچه مطالعه', 'ms': 'Buku nota kajian',
  },
  'turath_notebook_subtitle': {
    'ar': 'كل ما ظللته ودوّنته', 'en': 'Everything you highlighted and noted', 'am': 'ያደመቁትና የመዘገቡት ሁሉ', 'fr': 'Tout ce que vous avez surligné et noté', 'sw': 'Yote uliyoyaangazia na kuandika',
    'ur': 'سب کچھ جو آپ نے نمایاں اور نوٹ کیا', 'tr': 'Vurguladığınız ve not ettiğiniz her şey', 'id': 'Semua yang Anda sorot dan catat', 'bn': 'আপনি যা কিছু হাইলাইট ও নোট করেছেন', 'ha': "Duk abin da ka haskaka ka kuma rubuta",
    'so': 'Wax kasta oo aad muujisay oo aad qortay', 'fa': 'هر چه هایلایت و یادداشت کرده‌اید', 'ms': 'Semua yang anda serlahkan dan catat',
  },
  'turath_notebook_search_hint': {
    'ar': 'ابحث في فوائدك وملاحظاتك...', 'en': 'Search your notes...', 'am': 'ማስታወሻዎችዎን ይፈልጉ...', 'fr': 'Rechercher dans vos notes...', 'sw': 'Tafuta dokezo zako...',
    'ur': 'اپنے نوٹس میں تلاش کریں...', 'tr': 'Notlarınızda arayın...', 'id': 'Cari catatan Anda...', 'bn': 'আপনার নোট খুঁজুন...', 'ha': 'Bincika bayananka...',
    'so': 'Ka raadi qoraaladaada...', 'fa': 'در یادداشت‌های خود جست‌وجو کنید...', 'ms': 'Cari nota anda...',
  },
  'turath_notebook_empty': {
    'ar': 'لا فوائد بعد — ظلّل نصًّا في أي كتاب لتبدأ', 'en': 'Nothing yet — highlight text in any book to start',
    'am': 'እስካሁን ምንም የለም — ለመጀመር በማንኛውም መጽሐፍ ጽሑፍ ያድምቁ', 'fr': "Rien pour l'instant — surlignez du texte dans un livre pour commencer",
    'sw': 'Bado hakuna — angazia maandishi katika kitabu chochote kuanza', 'ur': 'ابھی کچھ نہیں — شروع کرنے کے لیے کسی کتاب میں متن نمایاں کریں',
    'tr': 'Henüz bir şey yok — başlamak için herhangi bir kitapta metni vurgulayın', 'id': 'Belum ada — sorot teks di buku mana pun untuk memulai',
    'bn': 'এখনও কিছু নেই — শুরু করতে যেকোনো বইয়ে টেক্সট হাইলাইট করুন', 'ha': 'Babu kome tukuna — haskaka rubutu a kowane littafi don farawa',
    'so': 'Weli waxba ma jiraan — muuji qoraal buug kasta si aad u bilowdo', 'fa': 'هنوز چیزی نیست — برای شروع متنی را در هر کتابی هایلایت کنید',
    'ms': 'Belum ada apa-apa — serlahkan teks dalam mana-mana buku untuk bermula',
  },
  'turath_page_short': {
    'ar': 'ص', 'en': 'p.', 'am': 'ገጽ', 'fr': 'p.', 'sw': 'uk.',
    'ur': 'ص', 'tr': 's.', 'id': 'hlm.', 'bn': 'পৃ.', 'ha': 'sh.',
    'so': 'b.', 'fa': 'ص', 'ms': 'ms.',
  },
  'turath_annotation_orphan': {
    'ar': 'تغيّر موضعها', 'en': 'position changed', 'am': 'ቦታው ተቀይሯል', 'fr': 'position modifiée', 'sw': 'nafasi imebadilika',
    'ur': 'مقام بدل گیا', 'tr': 'konumu değişti', 'id': 'posisi berubah', 'bn': 'অবস্থান পরিবর্তিত', 'ha': 'wurin ya canza',
    'so': 'booskeedu wuu isbeddelay', 'fa': 'موقعیت تغییر کرد', 'ms': 'kedudukan berubah',
  },
  'turath_my_notes_in_book': {
    'ar': 'فوائدي في هذا الكتاب', 'en': 'My notes in this book', 'am': 'በዚህ መጽሐፍ ውስጥ ማስታወሻዎቼ', 'fr': 'Mes notes dans ce livre', 'sw': 'Dokezo zangu katika kitabu hiki',
    'ur': 'اس کتاب میں میرے نوٹس', 'tr': 'Bu kitaptaki notlarım', 'id': 'Catatan saya di buku ini', 'bn': 'এই বইয়ে আমার নোট', 'ha': 'Bayanaina a wannan littafi',
    'so': 'Qoraaladayda buuggan', 'fa': 'یادداشت‌های من در این کتاب', 'ms': 'Nota saya dalam buku ini',
  },
  'turath_annotation_no_note': {
    'ar': 'لا توجد ملاحظة بعد', 'en': 'No note yet', 'am': 'እስካሁን ማስታወሻ የለም', 'fr': 'Pas encore de note', 'sw': 'Hakuna dokezo bado',
    'ur': 'ابھی کوئی نوٹ نہیں', 'tr': 'Henüz not yok', 'id': 'Belum ada catatan', 'bn': 'এখনও কোনো নোট নেই', 'ha': 'Babu bayanin kula tukuna',
    'so': 'Weli qoraal ma jiro', 'fa': 'هنوز یادداشتی نیست', 'ms': 'Tiada nota lagi',
  },
  'turath_annotation_change_color': {
    'ar': 'تغيير اللون', 'en': 'Change colour', 'am': 'ቀለም ቀይር', 'fr': 'Changer la couleur', 'sw': 'Badilisha rangi',
    'ur': 'رنگ بدلیں', 'tr': 'Rengi değiştir', 'id': 'Ubah warna', 'bn': 'রঙ পরিবর্তন করুন', 'ha': 'Canza launi',
    'so': 'Beddel midabka', 'fa': 'تغییر رنگ', 'ms': 'Tukar warna',
  },
  'turath_annotation_edit_note': {
    'ar': 'تعديل الملاحظة', 'en': 'Edit note', 'am': 'ማስታወሻ አርትዕ', 'fr': 'Modifier la note', 'sw': 'Hariri dokezo',
    'ur': 'نوٹ میں ترمیم کریں', 'tr': 'Notu düzenle', 'id': 'Edit catatan', 'bn': 'নোট সম্পাদনা করুন', 'ha': 'Gyara bayanin kula',
    'so': 'Wax ka beddel qoraalka', 'fa': 'ویرایش یادداشت', 'ms': 'Sunting nota',
  },
  'turath_annotation_delete': {
    'ar': 'حذف التظليل', 'en': 'Delete highlight', 'am': 'ማድመቅ ሰርዝ', 'fr': 'Supprimer le surlignage', 'sw': 'Futa mstari',
    'ur': 'ہائی لائٹ حذف کریں', 'tr': 'Vurguyu sil', 'id': 'Hapus sorotan', 'bn': 'হাইলাইট মুছুন', 'ha': 'Share haske',
    'so': 'Tirtir muujinta', 'fa': 'حذف هایلایت', 'ms': 'Padam serlahan',
  },
  'turath_annotation_type_benefit': {
    'ar': 'فائدة', 'en': 'Benefit', 'am': 'ጥቅም', 'fr': 'Bénéfice', 'sw': 'Faida',
    'ur': 'فائدہ', 'tr': 'Fayda', 'id': 'Manfaat', 'bn': 'উপকার', 'ha': 'Amfani',
    'so': 'Faa\'iido', 'fa': 'فایده', 'ms': 'Manfaat',
  },
  'turath_annotation_type_explain': {
    'ar': 'شرح', 'en': 'Explanation', 'am': 'ማብራሪያ', 'fr': 'Explication', 'sw': 'Ufafanuzi',
    'ur': 'وضاحت', 'tr': 'Açıklama', 'id': 'Penjelasan', 'bn': 'ব্যাখ্যা', 'ha': 'Bayani',
    'so': 'Sharraxaad', 'fa': 'شرح', 'ms': 'Penjelasan',
  },
  'turath_annotation_type_memorize': {
    'ar': 'للحفظ والمراجعة', 'en': 'To memorise / review', 'am': 'ለማስታወስ / ለክለሳ', 'fr': 'À mémoriser / réviser', 'sw': 'Kukariri / kupitia',
    'ur': 'حفظ اور دہرائی کے لیے', 'tr': 'Ezber / tekrar için', 'id': 'Untuk dihafal / diulang', 'bn': 'মুখস্থ / পুনরালোচনার জন্য', 'ha': 'Don haddacewa / bita',
    'so': 'Xafid / dib-u-eegis', 'fa': 'برای حفظ / مرور', 'ms': 'Untuk hafalan / ulang kaji',
  },
  'turath_annotation_type_important': {
    'ar': 'مهم جدًا', 'en': 'Very important', 'am': 'በጣም አስፈላጊ', 'fr': 'Très important', 'sw': 'Muhimu sana',
    'ur': 'بہت اہم', 'tr': 'Çok önemli', 'id': 'Sangat penting', 'bn': 'অত্যন্ত গুরুত্বপূর্ণ', 'ha': 'Mai matuƙar muhimmanci',
    'so': 'Muhiim aad ah', 'fa': 'بسیار مهم', 'ms': 'Sangat penting',
  },
  'turath_annotation_type_question': {
    'ar': 'سؤال / إشكال', 'en': 'Question / issue', 'am': 'ጥያቄ / ችግር', 'fr': 'Question / problème', 'sw': 'Swali / tatizo',
    'ur': 'سوال / اشکال', 'tr': 'Soru / sorun', 'id': 'Pertanyaan / masalah', 'bn': 'প্রশ্ন / সমস্যা', 'ha': 'Tambaya / matsala',
    'so': 'Su\'aal / dhibaato', 'fa': 'پرسش / اشکال', 'ms': 'Soalan / isu',
  },
  'turath_annotation_type_correction': {
    'ar': 'استدراك', 'en': 'Correction', 'am': 'እርማት', 'fr': 'Rectification', 'sw': 'Marekebisho',
    'ur': 'استدراک', 'tr': 'Düzeltme', 'id': 'Koreksi', 'bn': 'সংশোধন', 'ha': 'Gyara',
    'so': 'Saxid', 'fa': 'استدراک', 'ms': 'Pembetulan',
  },
  'copy_action': {
    'ar': 'نسخ', 'en': 'Copy', 'am': 'ቅዳ', 'fr': 'Copier', 'sw': 'Nakili',
    'ur': 'کاپی کریں', 'tr': 'Kopyala', 'id': 'Salin', 'bn': 'কপি করুন', 'ha': 'Kwafi',
    'so': 'Koobi', 'fa': 'کپی', 'ms': 'Salin',
  },
  'delete_action': {
    'ar': 'حذف', 'en': 'Delete', 'am': 'ሰርዝ', 'fr': 'Supprimer', 'sw': 'Futa',
    'ur': 'حذف کریں', 'tr': 'Sil', 'id': 'Hapus', 'bn': 'মুছে ফেলুন', 'ha': 'Share',
    'so': 'Tirtir', 'fa': 'حذف', 'ms': 'Padam',
  },
  'save_action': {
    'ar': 'حفظ', 'en': 'Save', 'am': 'አስቀምጥ', 'fr': 'Enregistrer', 'sw': 'Hifadhi',
    'ur': 'محفوظ کریں', 'tr': 'Kaydet', 'id': 'Simpan', 'bn': 'সংরক্ষণ করুন', 'ha': 'Ajiye',
    'so': 'Kaydi', 'fa': 'ذخیره', 'ms': 'Simpan',
  },
  'load_failed_prefix': {
    'ar': 'تعذّر التحميل', 'en': 'Failed to load', 'am': 'መጫን አልተቻለም', 'fr': 'Échec du chargement', 'sw': 'Imeshindwa kupakia',
    'ur': 'لوڈ کرنا ناکام ہوا', 'tr': 'Yükleme başarısız', 'id': 'Gagal memuat', 'bn': 'লোড ব্যর্থ হয়েছে', 'ha': 'An kasa loda',
    'so': 'Waa la waayay soo rarid', 'fa': 'بارگذاری ناموفق بود', 'ms': 'Gagal memuatkan',
  },
  'hide_action': {
    'ar': 'إخفاء', 'en': 'Hide', 'am': 'ደብቅ', 'fr': 'Masquer', 'sw': 'Ficha',
    'ur': 'چھپائیں', 'tr': 'Gizle', 'id': 'Sembunyikan', 'bn': 'লুকান', 'ha': 'Ɓoye',
    'so': 'Qari', 'fa': 'پنهان کردن', 'ms': 'Sembunyikan',
  },
  'hide_from_my_list': {
    'ar': 'إخفاء عن قائمتي', 'en': 'Hide from my list', 'am': 'ከዝርዝሬ ደብቅ', 'fr': 'Masquer de ma liste', 'sw': 'Ficha kutoka orodha yangu',
    'ur': 'میری فہرست سے چھپائیں', 'tr': 'Listemden gizle', 'id': 'Sembunyikan dari daftar saya', 'bn': 'আমার তালিকা থেকে লুকান', 'ha': 'Ɓoye daga jerina',
    'so': 'Ka qari liistadayda', 'fa': 'پنهان از لیست من', 'ms': 'Sembunyikan dari senarai saya',
  },
  'hidden_books_count': {
    'ar': 'كتب مخفية', 'en': 'hidden books', 'am': 'የተደበቁ መጻሕፍት', 'fr': 'livres masqués', 'sw': 'vitabu vilivyofichwa',
    'ur': 'چھپی ہوئی کتابیں', 'tr': 'gizli kitap', 'id': 'buku tersembunyi', 'bn': 'লুকানো বই', 'ha': 'littattafan ɓoye',
    'so': 'buugag qarsoon', 'fa': 'کتاب‌های پنهان', 'ms': 'buku tersembunyi',
  },
  'more_content_from_admin': {
    'ar': 'محتوى آخر من المشرف', 'en': 'More content from the admin', 'am': 'ከአስተዳዳሪው ተጨማሪ ይዘት', 'fr': "Plus de contenu de l'administrateur", 'sw': 'Maudhui zaidi kutoka kwa msimamizi',
    'ur': 'ایڈمن کی طرف سے مزید مواد', 'tr': 'Yöneticiden diğer içerikler', 'id': 'Konten lain dari admin', 'bn': 'অ্যাডমিনের কাছ থেকে আরও বিষয়বস্তু', 'ha': 'Ƙarin abun ciki daga mai kula',
    'so': 'Waxyaabo dheeraad ah oo ka yimid maamulaha', 'fa': 'محتوای دیگر از مدیر', 'ms': 'Kandungan lain daripada pentadbir',
  },
  'selected_book_label': {
    'ar': 'الكتاب المحدَّد', 'en': 'Selected Book', 'am': 'የተመረጠው መጽሐፍ', 'fr': 'Livre sélectionné', 'sw': 'Kitabu Kilichochaguliwa',
    'ur': 'منتخب کتاب', 'tr': 'Seçilen Kitap', 'id': 'Buku Terpilih', 'bn': 'নির্বাচিত বই', 'ha': 'Littafin da Aka Zaɓa',
    'so': 'Buugga la Doortay', 'fa': 'کتاب انتخاب‌شده', 'ms': 'Buku Dipilih',
  },
  'downloading_ellipsis': {
    'ar': 'جارٍ التحميل...', 'en': 'Downloading...', 'am': 'በማውረድ ላይ...', 'fr': 'Téléchargement...', 'sw': 'Inapakua...',
    'ur': 'ڈاؤن لوڈ ہو رہا ہے...', 'tr': 'İndiriliyor...', 'id': 'Mengunduh...', 'bn': 'ডাউনলোড হচ্ছে...', 'ha': 'Ana Saukarwa...',
    'so': 'Waa la soo dejinayaa...', 'fa': 'در حال دانلود...', 'ms': 'Memuat turun...',
  },
  'open_this_book': {
    'ar': 'فتح هذا الكتاب', 'en': 'Open This Book', 'am': 'ይህን መጽሐፍ ክፈት', 'fr': 'Ouvrir ce livre', 'sw': 'Fungua Kitabu Hiki',
    'ur': 'یہ کتاب کھولیں', 'tr': 'Bu Kitabı Aç', 'id': 'Buka Buku Ini', 'bn': 'এই বইটি খুলুন', 'ha': 'Buɗe Wannan Littafi',
    'so': 'Fur Buuggan', 'fa': 'باز کردن این کتاب', 'ms': 'Buka Buku Ini',
  },
  'reading_percent_label': {
    'ar': 'نسبة القراءة (تقديرية)', 'en': 'Reading Progress (estimated)', 'am': 'የንባብ ደረጃ (ግምታዊ)', 'fr': 'Progression de lecture (estimée)', 'sw': 'Kiwango cha Kusoma (makadirio)',
    'ur': 'مطالعے کی شرح (تخمینی)', 'tr': 'Okuma Oranı (tahmini)', 'id': 'Persentase Bacaan (perkiraan)', 'bn': 'পড়ার হার (আনুমানিক)', 'ha': 'Adadin Karatu (kimantawa)',
    'so': 'Boqolkiiba Akhriska (qiyaas)', 'fa': 'درصد مطالعه (تخمینی)', 'ms': 'Peratus Bacaan (anggaran)',
  },
  'reading_percent_desc': {
    'ar': 'استخدم هذا فقط إن كنت تقرأ نسخة ورقية — عند القراءة داخل التطبيق يُحفظ موضعك تلقائياً بالصفحة.', 'en': "Only use this if you're reading a paper copy — reading inside the app saves your page position automatically.", 'am': 'ይህን የምትጠቀመው የወረቀት ቅጂ እያነበብህ ከሆነ ብቻ ነው — በመተግበሪያው ውስጥ ስታነብ ገጽህ ራሱ በራሱ ይቀመጣል።', 'fr': "Utilisez ceci uniquement si vous lisez une copie papier — la lecture dans l'application enregistre automatiquement votre position.", 'sw': 'Tumia hii tu ikiwa unasoma nakala ya karatasi — kusoma ndani ya programu huhifadhi nafasi yako kiotomatiki.',
    'ur': 'یہ صرف اس صورت میں استعمال کریں اگر آپ کاغذی کاپی پڑھ رہے ہیں — ایپ کے اندر پڑھنے پر آپ کی جگہ خودکار محفوظ ہو جاتی ہے۔', 'tr': 'Bunu yalnızca kağıt bir kopya okuyorsanız kullanın — uygulama içinde okumak konumunuzu otomatik kaydeder.', 'id': 'Gunakan ini hanya jika Anda membaca salinan kertas — membaca di dalam aplikasi menyimpan posisi Anda secara otomatis.', 'bn': 'এটি শুধু তখনই ব্যবহার করুন যদি আপনি কাগজের কপি পড়ছেন — অ্যাপের ভেতরে পড়লে আপনার অবস্থান স্বয়ংক্রিয়ভাবে সংরক্ষিত হয়।', 'ha': 'Yi amfani da wannan kawai idan kana karanta kwafin takarda — karatu a cikin manhaja yana ajiye matsayinka ta atomatik.',
    'so': 'Tan u isticmaal kaliya haddii aad akhrinayso nuqul warqad ah — akhrinta gudaha barnaamijka ayaa si toos ah u kaydisa booskaaga.', 'fa': 'فقط زمانی از این استفاده کن که نسخه کاغذی می‌خوانی — خواندن داخل برنامه موقعیتت را به‌طور خودکار ذخیره می‌کند.', 'ms': 'Gunakan ini hanya jika anda membaca salinan kertas — membaca dalam aplikasi menyimpan kedudukan anda secara automatik.',
  },
  'book_quiz_label': {
    'ar': 'اختبار هذا الكتاب', 'en': "This Book's Quiz", 'am': 'የዚህ መጽሐፍ ፈተና', 'fr': 'Quiz de ce livre', 'sw': 'Jaribio la Kitabu Hiki',
    'ur': 'اس کتاب کا امتحان', 'tr': 'Bu Kitabın Testi', 'id': 'Kuis Buku Ini', 'bn': 'এই বইয়ের কুইজ', 'ha': 'Jarrabawar Wannan Littafi',
    'so': 'Imtixaanka Buuggan', 'fa': 'آزمون این کتاب', 'ms': 'Kuiz Buku Ini',
  },
  'your_score_label': {
    'ar': 'نتيجتك', 'en': 'Your Score', 'am': 'ውጤትህ', 'fr': 'Votre score', 'sw': 'Alama Yako',
    'ur': 'آپ کا نتیجہ', 'tr': 'Puanınız', 'id': 'Skor Anda', 'bn': 'আপনার স্কোর', 'ha': 'Sakamakonka',
    'so': 'Natiijadaada', 'fa': 'نمره تو', 'ms': 'Markah Anda',
  },
  'quiz_not_taken_yet': {
    'ar': 'لم يتم إجراء الاختبار بعد', 'en': 'Quiz not taken yet', 'am': 'ፈተናው እስካሁን አልተወሰደም', 'fr': "Le quiz n'a pas encore été passé", 'sw': 'Jaribio bado halijafanywa',
    'ur': 'ابھی تک امتحان نہیں دیا گیا', 'tr': 'Test henüz yapılmadı', 'id': 'Kuis belum dikerjakan', 'bn': 'এখনও কুইজ দেওয়া হয়নি', 'ha': 'Ba a yi jarrabawar tukuna ba',
    'so': 'Imtixaanka wali lama qaadan', 'fa': 'آزمون هنوز انجام نشده', 'ms': 'Kuiz belum diambil',
  },
  'no_quiz_yet': {
    'ar': 'لا يوجد اختبار بعد', 'en': 'No quiz yet', 'am': 'እስካሁን ፈተና የለም', 'fr': "Pas encore de quiz", 'sw': 'Bado hakuna jaribio',
    'ur': 'ابھی تک کوئی امتحان نہیں', 'tr': 'Henüz test yok', 'id': 'Belum ada kuis', 'bn': 'এখনও কোনো কুইজ নেই', 'ha': 'Babu jarrabawa tukuna',
    'so': 'Wali imtixaan ma jiro', 'fa': 'هنوز آزمونی نیست', 'ms': 'Belum ada kuiz',
  },
  'start_quiz': {
    'ar': 'بدء الاختبار', 'en': 'Start Quiz', 'am': 'ፈተና ጀምር', 'fr': 'Commencer le quiz', 'sw': 'Anza Jaribio',
    'ur': 'امتحان شروع کریں', 'tr': 'Teste Başla', 'id': 'Mulai Kuis', 'bn': 'কুইজ শুরু করুন', 'ha': 'Fara Jarrabawa',
    'so': 'Bilow Imtixaanka', 'fa': 'شروع آزمون', 'ms': 'Mula Kuiz',
  },
  'font_size_label': {
    'ar': 'حجم الخط في التطبيق', 'en': 'App Font Size', 'am': 'የመተግበሪያ ፊደል መጠን', 'fr': "Taille de police de l'application", 'sw': 'Ukubwa wa Herufi wa Programu',
    'ur': 'ایپ کے فونٹ کا سائز', 'tr': 'Uygulama Yazı Boyutu', 'id': 'Ukuran Font Aplikasi', 'bn': 'অ্যাপ ফন্ট সাইজ', 'ha': 'Girman Rubutun Manhaja',
    'so': 'Cabbirka Farta Barnaamijka', 'fa': 'اندازه فونت برنامه', 'ms': 'Saiz Fon Aplikasi',
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
  // 2026-08-17: رحلتي's SMART setup wizard — one of the first screens a
  // new student ever sees, found with zero translation coverage during
  // Ismail's "why doesn't everything change" audit. Static copy only
  // (questions, labels, button); the live pace-calculation sentences with
  // interpolated numbers stay a follow-up — a real, scoped increment, not
  // an attempt at the whole 500-string problem in one pass.
  'journey_start_title': {
    'ar': 'ابدأ رحلتك', 'en': 'Start Your Journey', 'am': 'ጉዞህን ጀምር', 'fr': 'Commencez votre parcours', 'sw': 'Anza Safari Yako',
    'ur': 'اپنا سفر شروع کریں', 'tr': 'Yolculuğuna Başla', 'id': 'Mulai Perjalanan Anda', 'bn': 'আপনার যাত্রা শুরু করুন', 'ha': 'Fara Tafiyarka',
    'so': 'Bilow Safarkaaga', 'fa': 'سفر خود را آغاز کنید', 'ms': 'Mulakan Perjalanan Anda',
  },
  'journey_start_subtitle': {
    'ar': 'حدّد هدفك ومستواك الحالي، وسنحسب لك وتيرة يومية مناسبة — وستتكيّف هذه الوتيرة تلقائيًا مع أدائك الفعلي لاحقًا، لا تبقى رقمًا ثابتًا.',
    'en': "Set your goal and current level, and we'll calculate a suitable daily pace — it will adapt automatically to your real progress later, not stay a fixed number.",
    'am': 'ግብህንና የአሁኑን ደረጃህን ይግለጹ፣ ተስማሚ የዕለት ፍጥነት እናሰላለን — ይህ ፍጥነት ከእውነተኛ አፈጻጸምህ ጋር በራስ-ሰር ይላመዳል።',
    'fr': 'Définissez votre objectif et votre niveau actuel, nous calculerons un rythme quotidien adapté — il s\'ajustera automatiquement à vos progrès réels.',
    'sw': 'Weka lengo lako na kiwango chako cha sasa, tutakuhesabia kasi inayofaa ya kila siku — kasi hii itajirekebisha kiotomatiki na utendaji wako halisi.',
    'ur': 'اپنا ہدف اور موجودہ سطح طے کریں، ہم آپ کے لیے مناسب روزانہ رفتار کا حساب لگائیں گے — یہ رفتار بعد میں آپ کی حقیقی کارکردگی کے ساتھ خودکار طور پر ڈھل جائے گی۔',
    'tr': 'Hedefinizi ve mevcut seviyenizi belirleyin, size uygun günlük hızı hesaplayacağız — bu hız daha sonra gerçek performansınıza otomatik olarak uyum sağlayacak.',
    'id': 'Tentukan target dan level Anda saat ini, kami akan menghitung kecepatan harian yang sesuai — kecepatan ini akan menyesuaikan otomatis dengan kemajuan nyata Anda.',
    'bn': 'আপনার লক্ষ্য ও বর্তমান স্তর নির্ধারণ করুন, আমরা আপনার জন্য উপযুক্ত দৈনিক গতি হিসাব করব — এই গতি পরে আপনার প্রকৃত অগ্রগতির সাথে স্বয়ংক্রিয়ভাবে খাপ খাইয়ে নেবে।',
    'ha': 'Ƙayyade manufarka da matakinka na yanzu, za mu lissafa maka saurin yau da kullum da ya dace — wannan saurin zai daidaita kansa da ainihin ci gabanka.',
    'so': 'Qeex hadafkaaga iyo heerkaaga hadda, waxaan kuu xisaabin doonaa xawaare maalinle ku habboon — xawaaraan wuxuu si toos ah ula qabsan doonaa horumarkaaga dhabta ah.',
    'fa': 'هدف و سطح فعلی خود را مشخص کنید، ما سرعت روزانه مناسبی برای شما محاسبه می‌کنیم — این سرعت بعداً به‌طور خودکار با عملکرد واقعی شما تطبیق می‌یابد.',
    'ms': 'Tetapkan matlamat dan tahap semasa anda, kami akan mengira kadar harian yang sesuai — kadar ini akan menyesuaikan secara automatik dengan kemajuan sebenar anda.',
  },
  'journey_years_question': {
    'ar': 'في كم سنة تريد ختم حفظ القرآن؟', 'en': 'In how many years do you want to complete memorizing the Quran?',
    'am': 'ቁርኣንን በስንት ዓመት ውስጥ መሸምደድ ትፈልጋለህ?', 'fr': 'En combien d\'années souhaitez-vous terminer la mémorisation du Coran ?',
    'sw': 'Unataka kumaliza kuhifadhi Qur\'an kwa miaka mingapi?', 'ur': 'آپ کتنے سالوں میں قرآن حفظ مکمل کرنا چاہتے ہیں؟',
    'tr': 'Kur\'an\'ı kaç yılda ezberlemeyi tamamlamak istiyorsunuz?', 'id': 'Dalam berapa tahun Anda ingin menyelesaikan hafalan Al-Qur\'an?',
    'bn': 'আপনি কত বছরে কুরআন মুখস্থ শেষ করতে চান?', 'ha': 'A cikin shekaru nawa kake son kammala haddar Alkur\'ani?',
    'so': 'Immisa sano ayaad rabtaa inaad ku dhammaystirto xifdiga Qur\'aanka?', 'fa': 'در چند سال می‌خواهید حفظ قرآن را تکمیل کنید؟',
    'ms': 'Dalam berapa tahun anda ingin menamatkan hafazan Al-Quran?',
  },
  'journey_level_question': {
    'ar': 'ما مستواك الحالي؟', 'en': 'What is your current level?', 'am': 'የአሁኑ ደረጃህ ምንድን ነው?', 'fr': 'Quel est votre niveau actuel ?',
    'sw': 'Kiwango chako cha sasa ni kipi?', 'ur': 'آپ کی موجودہ سطح کیا ہے؟', 'tr': 'Mevcut seviyeniz nedir?',
    'id': 'Apa level Anda saat ini?', 'bn': 'আপনার বর্তমান স্তর কী?', 'ha': 'Menene matakinka na yanzu?',
    'so': 'Waa maxay heerkaaga hadda?', 'fa': 'سطح فعلی شما چیست؟', 'ms': 'Apakah tahap semasa anda?',
  },
  'level_beginner': {
    'ar': 'مبتدئ', 'en': 'Beginner', 'am': 'ጀማሪ', 'fr': 'Débutant', 'sw': 'Mwanzo', 'ur': 'ابتدائی',
    'tr': 'Başlangıç', 'id': 'Pemula', 'bn': 'শিক্ষানবিশ', 'ha': 'Mafari', 'so': 'Bilow', 'fa': 'مبتدی', 'ms': 'Permulaan',
  },
  'level_intermediate': {
    'ar': 'متوسط', 'en': 'Intermediate', 'am': 'መካከለኛ', 'fr': 'Intermédiaire', 'sw': 'Kati', 'ur': 'درمیانہ',
    'tr': 'Orta', 'id': 'Menengah', 'bn': 'মধ্যম', 'ha': 'Matsakaici', 'so': 'Dhexdhexaad', 'fa': 'متوسط', 'ms': 'Pertengahan',
  },
  'level_advanced': {
    'ar': 'متقدم', 'en': 'Advanced', 'am': 'ከፍተኛ', 'fr': 'Avancé', 'sw': 'Juu', 'ur': 'اعلیٰ',
    'tr': 'İleri', 'id': 'Lanjutan', 'bn': 'উন্নত', 'ha': 'Matakin Sama', 'so': 'Sare', 'fa': 'پیشرفته', 'ms': 'Lanjutan',
  },
  'journey_commitment_label': {
    'ar': 'التزام شخصي (اختياري)', 'en': 'Personal Commitment (Optional)', 'am': 'የግል ቁርጠኝነት (አማራጭ)', 'fr': 'Engagement personnel (facultatif)',
    'sw': 'Ahadi Binafsi (Hiari)', 'ur': 'ذاتی عزم (اختیاری)', 'tr': 'Kişisel Taahhüt (İsteğe Bağlı)', 'id': 'Komitmen Pribadi (Opsional)',
    'bn': 'ব্যক্তিগত অঙ্গীকার (ঐচ্ছিক)', 'ha': 'Alkawari na Kai (Na Zaɓi)', 'so': 'Ballanqaad Shakhsi ah (Ikhtiyaari)',
    'fa': 'تعهد شخصی (اختیاری)', 'ms': 'Komitmen Peribadi (Pilihan)',
  },
  'journey_commitment_desc': {
    'ar': 'تذكير تكتبه لنفسك يظهر لك عند العودة بعد انقطاع — أنت من يقرر وينفّذ، لا التطبيق.',
    'en': "A reminder you write for yourself, shown when you return after a break — you decide and act, not the app.",
    'am': 'ለራስህ የምትጽፈው ማስታወሻ፣ ከተቋረጠ በኋላ ስትመለስ ይታይሃል — የምትወስነውና የምትፈጽመው አንተ ነህ፣ መተግበሪያው አይደለም።',
    'fr': 'Un rappel que vous écrivez pour vous-même, affiché à votre retour après une pause — c\'est vous qui décidez et agissez, pas l\'application.',
    'sw': 'Ukumbusho unaojiandikia mwenyewe, unaoonekana unaporudi baada ya mapumziko — wewe ndiye unayeamua na kutenda, si programu.',
    'ur': 'ایک یاد دہانی جو آپ اپنے لیے لکھتے ہیں، وقفے کے بعد واپسی پر دکھائی جاتی ہے — فیصلہ اور عمل آپ کا ہے، ایپ کا نہیں۔',
    'tr': 'Kendiniz için yazdığınız bir hatırlatma, bir aradan sonra döndüğünüzde gösterilir — karar veren ve uygulayan sizsiniz, uygulama değil.',
    'id': 'Pengingat yang Anda tulis untuk diri sendiri, ditampilkan saat Anda kembali setelah jeda — Andalah yang memutuskan dan bertindak, bukan aplikasi.',
    'bn': 'নিজের জন্য লেখা একটি অনুস্মারক, বিরতির পর ফিরে এলে দেখানো হয় — সিদ্ধান্ত ও কাজ আপনার, অ্যাপের নয়।',
    'ha': 'Tunatarwa da kake rubuta wa kanka, ana nuna ta lokacin da ka dawo bayan tsayawa — kai ne ke yanke shawara da aikatawa, ba manhajar ba.',
    'so': 'Xasuusin aad naftaada u qorto, oo lagu muujiyo markaad ku soo laabato ka dib kala go\' — adiga ayaa go\'aansada oo fulinaya, ma aha app-ka.',
    'fa': 'یادآوری‌ای که برای خودتان می‌نویسید و پس از بازگشت از یک وقفه نمایش داده می‌شود — تصمیم و عمل با شماست، نه برنامه.',
    'ms': 'Peringatan yang anda tulis untuk diri sendiri, dipaparkan apabila anda kembali selepas jeda — andalah yang memutuskan dan bertindak, bukan aplikasi.',
  },
  'journey_commitment_placeholder': {
    'ar': 'مثال: لو فوّت 3 أيام متتالية، سأتصدق بكذا', 'en': 'Example: If I miss 3 days in a row, I will give this much in charity',
    'am': 'ምሳሌ፦ 3 ተከታታይ ቀናት ካመለጠኝ፣ ይህን ያህል ምጽዋት እሰጣለሁ', 'fr': 'Exemple : Si je manque 3 jours d\'affilée, je ferai cette aumône',
    'sw': 'Mfano: Nikikosa siku 3 mfululizo, nitatoa sadaka hii', 'ur': 'مثال: اگر میں مسلسل 3 دن چھوڑ دوں تو اتنی صدقہ دوں گا',
    'tr': 'Örnek: 3 gün üst üste kaçırırsam, şu kadar sadaka vereceğim', 'id': 'Contoh: Jika saya melewatkan 3 hari berturut-turut, saya akan bersedekah sekian',
    'bn': 'উদাহরণ: টানা ৩ দিন বাদ দিলে, আমি এতটা সদকা দেব', 'ha': 'Misali: Idan na rasa kwana 3 a jere, zan bayar da sadaka gwargwadon haka',
    'so': 'Tusaale: Haddii aan 3 maalmood isku xigxiga seego, waxaan bixin doonaa sadaqad intaas le\'eg',
    'fa': 'مثال: اگر ۳ روز پیاپی را از دست بدهم، این مقدار صدقه می‌دهم', 'ms': 'Contoh: Jika saya terlepas 3 hari berturut-turut, saya akan bersedekah sekian',
  },
  'years_label': {
    'ar': 'سنة', 'en': 'years', 'am': 'ዓመታት', 'fr': 'ans', 'sw': 'miaka', 'ur': 'سال',
    'tr': 'yıl', 'id': 'tahun', 'bn': 'বছর', 'ha': 'shekaru', 'so': 'sano', 'fa': 'سال', 'ms': 'tahun',
  },
  'journey_start_button': {
    'ar': 'ابدأ رحلتي', 'en': 'Start My Journey', 'am': 'ጉዞዬን ጀምር', 'fr': 'Commencer mon parcours', 'sw': 'Anza Safari Yangu',
    'ur': 'میرا سفر شروع کریں', 'tr': 'Yolculuğuma Başla', 'id': 'Mulai Perjalanan Saya', 'bn': 'আমার যাত্রা শুরু করুন', 'ha': 'Fara Tafiyata',
    'so': 'Bilow Safarkayga', 'fa': 'سفرم را آغاز کن', 'ms': 'Mulakan Perjalanan Saya',
  },
  // 2026-08-18: chat screen chrome for محادثة الرفيق (QURAN_COMPANION_ROADMAP.md
  // §4.36) — only 'ar'/'en' content exists inside the engine itself so far,
  // but the screen's own chrome (title, input hint, send button) follows
  // the same 13-language basics coverage as the rest of the app's UI.
  'companion_chat_title': {
    'ar': 'الرفيق', 'en': 'Companion', 'am': 'ጓደኛ', 'fr': 'Compagnon', 'sw': 'Rafiki',
    'ur': 'رفیق', 'tr': 'Arkadaş', 'id': 'Sahabat', 'bn': 'সঙ্গী', 'ha': 'Aboki',
    'so': 'Saaxiib', 'fa': 'همراه', 'ms': 'Rakan',
  },
  'companion_chat_home_tagline': {
    'ar': 'اسأل رفيقك عن تقدمك', 'en': 'Ask your companion about your progress',
    'am': 'ስለ እድገትህ ጓደኛህን ጠይቅ', 'fr': 'Demandez à votre compagnon vos progrès',
    'sw': 'Muulize rafiki yako kuhusu maendeleo yako',
    'ur': 'اپنے رفیق سے اپنی پیش رفت کے بارے میں پوچھیں', 'tr': 'Arkadaşına ilerlemeni sor',
    'id': 'Tanyakan progresmu ke sahabatmu', 'bn': 'আপনার সঙ্গীকে আপনার অগ্রগতি সম্পর্কে জিজ্ঞাসা করুন',
    'ha': 'Tambayi abokinka game da ci gabanka', 'so': 'Weydii saaxiibkaa horumarkaaga',
    'fa': 'از همراهت درباره پیشرفتت بپرس', 'ms': 'Tanya rakan anda tentang kemajuan anda',
  },
  'companion_chat_hint': {
    'ar': 'اكتب رسالتك...', 'en': 'Type a message...', 'am': 'መልእክትዎን ይጻፉ...', 'fr': 'Écrivez un message...', 'sw': 'Andika ujumbe...',
    'ur': 'اپنا پیغام لکھیں...', 'tr': 'Mesajınızı yazın...', 'id': 'Ketik pesan...', 'bn': 'আপনার বার্তা লিখুন...', 'ha': 'Rubuta saƙo...',
    'so': 'Qor fariintaada...', 'fa': 'پیام خود را بنویسید...', 'ms': 'Taip mesej...',
  },
  'companion_chat_send': {
    'ar': 'إرسال', 'en': 'Send', 'am': 'ላክ', 'fr': 'Envoyer', 'sw': 'Tuma',
    'ur': 'بھیجیں', 'tr': 'Gönder', 'id': 'Kirim', 'bn': 'পাঠান', 'ha': 'Aika',
    'so': 'Dir', 'fa': 'ارسال', 'ms': 'Hantar',
  },
  'companion_start_now': {
    'ar': 'ابدأ الآن', 'en': 'Start Now', 'am': 'አሁን ጀምር', 'fr': 'Commencer maintenant', 'sw': 'Anza Sasa',
    'ur': 'ابھی شروع کریں', 'tr': 'Şimdi Başla', 'id': 'Mulai Sekarang', 'bn': 'এখনই শুরু করুন', 'ha': 'Fara Yanzu',
    'so': 'Hadda Bilow', 'fa': 'اکنون شروع کن', 'ms': 'Mula Sekarang',
  },
  'companion_chat_with_him': {
    'ar': 'تحدث مع الرفيق', 'en': 'Chat with Companion', 'am': 'ከጓደኛ ጋር ይወያዩ', 'fr': 'Discuter avec le compagnon', 'sw': 'Ongea na Rafiki',
    'ur': 'رفیق سے بات کریں', 'tr': 'Arkadaşla Sohbet Et', 'id': 'Ngobrol dengan Sahabat', 'bn': 'সঙ্গীর সাথে কথা বলুন', 'ha': 'Yi Hira da Aboki',
    'so': 'La Hadal Saaxiibka', 'fa': 'با همراه گفتگو کن', 'ms': 'Berbual dengan Rakan',
  },
  'qibla_title': {
    'ar': 'القبلة', 'en': 'Qibla', 'am': 'ቂብላ', 'fr': 'Qibla', 'sw': 'Kibla',
    'ur': 'قبلہ', 'tr': 'Kıble', 'id': 'Kiblat', 'bn': 'কিবলা', 'ha': 'Kibla',
    'so': 'Kibla', 'fa': 'قبله', 'ms': 'Kiblat',
  },
  'qibla_tab_compass': {
    'ar': 'البوصلة', 'en': 'Compass', 'am': 'ኮምፓስ', 'fr': 'Boussole', 'sw': 'Dira',
    'ur': 'قطب نما', 'tr': 'Pusula', 'id': 'Kompas', 'bn': 'কম্পাস', 'ha': 'Kamfas',
    'so': 'Kamfas', 'fa': 'قطب‌نما', 'ms': 'Kompas',
  },
  'qibla_tab_map': {
    'ar': 'المرئية', 'en': 'Map', 'am': 'ካርታ', 'fr': 'Carte', 'sw': 'Ramani',
    'ur': 'نقشہ', 'tr': 'Harita', 'id': 'Peta', 'bn': 'মানচিত্র', 'ha': 'Taswira',
    'so': 'Khariidad', 'fa': 'نقشه', 'ms': 'Peta',
  },
  'qibla_tab_ar': {
    'ar': 'الواقع المعزز', 'en': 'Augmented Reality', 'am': 'የተጨመረ እውነታ', 'fr': 'Réalité augmentée', 'sw': 'Uhalisia Ulioboreshwa',
    'ur': 'اگمینٹڈ رئیلٹی', 'tr': 'Artırılmış Gerçeklik', 'id': 'Realitas Tertambah', 'bn': 'অগমেন্টেড রিয়েলিটি', 'ha': 'Gaskiyar Da Aka Ƙara',
    'so': 'Xaqiiqada La Xoojiyay', 'fa': 'واقعیت افزوده', 'ms': 'Realiti Ditambah',
  },
  'qibla_tab_sun': {
    'ar': 'الشمس', 'en': 'Sun', 'am': 'ፀሐይ', 'fr': 'Soleil', 'sw': 'Jua',
    'ur': 'سورج', 'tr': 'Güneş', 'id': 'Matahari', 'bn': 'সূর্য', 'ha': 'Rana',
    'so': 'Qorax', 'fa': 'خورشید', 'ms': 'Matahari',
  },
  'qibla_ar_rug_help_tooltip': {
    'ar': 'ما معنى السجادة في الواقع المعزز؟', 'en': 'What does the rug in AR mean?', 'am': 'በAR ውስጥ ያለው ምንጣፍ ምን ማለት ነው?', 'fr': 'Que signifie le tapis en RA ?', 'sw': 'Zulia katika AR lina maana gani?',
    'ur': 'اے آر میں قالین کا کیا مطلب ہے؟', 'tr': 'AR\'daki halı ne anlama geliyor?', 'id': 'Apa arti sajadah di AR?', 'bn': 'AR-এ গালিচার অর্থ কী?', 'ha': 'Menene ma\'anar kafet a AR?',
    'so': 'Waa maxay macnaha roogga AR?', 'fa': 'فرش در AR به چه معناست؟', 'ms': 'Apakah maksud permaidani dalam AR?',
  },
  'qibla_ar_rug_help_title': {
    'ar': 'السجادة في الواقع المعزز', 'en': 'The Rug in Augmented Reality', 'am': 'ምንጣፉ በተጨመረ እውነታ', 'fr': 'Le tapis en réalité augmentée', 'sw': 'Zulia katika Uhalisia Ulioboreshwa',
    'ur': 'اے آر میں قالین', 'tr': 'Artırılmış Gerçeklikte Halı', 'id': 'Sajadah di Realitas Tertambah', 'bn': 'AR-এ গালিচা', 'ha': 'Kafet a Gaskiyar Da Aka Ƙara',
    'so': 'Rooga Xaqiiqada La Xoojiyay', 'fa': 'فرش در واقعیت افزوده', 'ms': 'Permaidani dalam Realiti Ditambah',
  },
  'qibla_ar_rug_help_body': {
    'ar': 'الشكل الظاهر أسفل الشاشة يمثّل سجادة الصلاة — تدور تلقائيًا لتشير إلى نفس اتجاه الكعبة الذي تحدده الأيقونة العلوية، لتساعدك على معرفة أين تفرش سجادتك فعليًا.',
    'en': 'The shape at the bottom of the screen represents a prayer rug — it rotates automatically to face the same Kaaba direction the icon above points to, helping you know where to actually lay your rug.',
    'am': 'ከስክሪኑ ግርጌ ያለው ቅርጽ የጸሎት ምንጣፍን ይወክላል — ከላይ ያለው አዶ ወደሚያመለክተው ተመሳሳይ የካዕባ አቅጣጫ በራስ-ሰር ይሽከረከራል፣ ምንጣፍዎን በትክክል የት እንደሚያነጥፉ ለማወቅ ይረዳዎታል።',
    'fr': 'La forme en bas de l\'écran représente un tapis de prière — elle pivote automatiquement pour indiquer la même direction de la Kaaba que l\'icône ci-dessus, vous aidant à savoir où poser réellement votre tapis.',
    'sw': 'Umbo lililo chini ya skrini linawakilisha zulia la sala — linazunguka kiotomatiki kuelekea mwelekeo uleule wa Kaaba unaoonyeshwa na aikoni iliyo juu, likikusaidia kujua wapi hasa pa kutandika zulia lako.',
    'ur': 'اسکرین کے نیچے موجود شکل نماز کے قالین کی نمائندگی کرتی ہے — یہ خودکار طور پر اسی کعبہ کی سمت کی طرف گھومتی ہے جو اوپر والا آئیکن ظاہر کرتا ہے، تاکہ آپ کو معلوم ہو کہ اپنا قالین اصل میں کہاں بچھانا ہے۔',
    'tr': 'Ekranın altındaki şekil bir seccadeyi temsil eder — yukarıdaki simgenin işaret ettiği aynı Kâbe yönüne otomatik olarak döner, böylece seccadenizi gerçekte nereye sereceğinizi bilmenize yardımcı olur.',
    'id': 'Bentuk di bagian bawah layar mewakili sajadah — berputar otomatis mengarah ke arah Ka\'bah yang sama seperti ditunjukkan ikon di atas, membantu Anda mengetahui di mana sebenarnya menggelar sajadah.',
    'bn': 'স্ক্রিনের নিচের আকৃতিটি জায়নামাজ প্রতিনিধিত্ব করে — এটি স্বয়ংক্রিয়ভাবে ঘোরে একই কাবার দিকে যা উপরের আইকনটি নির্দেশ করে, আপনাকে জানতে সাহায্য করে যে আসলে কোথায় আপনার জায়নামাজ বিছাতে হবে।',
    'ha': 'Siffar da ke ƙasan allon tana wakiltar kafet na sallah — tana juyawa ta atomatik zuwa wannan hanyar Ka\'aba wanda alamar da ke sama ke nunawa, tana taimaka maka sanin inda za ka shimfiɗa kafet ɗinka a zahiri.',
    'so': 'Qaabka ku yaal hoosta shaashadda wuxuu matalayaa roogga salaadda — si toos ah ayuu ugu wareegaa jihada Kacbada ee ay tilmaamayso astaanta sare, taasoo kaa caawinaysa inaad ogaato meesha aad dhab ahaan u gogoshid roogaaga.',
    'fa': 'شکل پایین صفحه نمایانگر سجاده است — به‌طور خودکار به همان جهت کعبه‌ای می‌چرخد که آیکون بالا نشان می‌دهد و به شما کمک می‌کند بدانید سجاده خود را واقعاً کجا پهن کنید.',
    'ms': 'Bentuk di bahagian bawah skrin mewakili sejadah — ia berputar secara automatik menghadap arah Kaabah yang sama seperti yang ditunjukkan ikon di atas, membantu anda mengetahui di mana sebenarnya untuk membentangkan sejadah anda.',
  },
  'qibla_ar_rug_help_dismiss': {
    'ar': 'فهمت', 'en': 'Got it', 'am': 'ገባኝ', 'fr': 'Compris', 'sw': 'Nimeelewa',
    'ur': 'سمجھ گیا', 'tr': 'Anladım', 'id': 'Mengerti', 'bn': 'বুঝেছি', 'ha': 'Na Gane',
    'so': 'Waan Fahmay', 'fa': 'فهمیدم', 'ms': 'Faham',
  },
  // 2026-08-22: onboarding_screen.dart, first-launch tutorial — flagged by
  // Ismail's "everything must change with the language" audit as still
  // 100% hardcoded Arabic.
  'onboarding_skip': {
    'ar': 'تخطي', 'en': 'Skip', 'am': 'ዝለል', 'fr': 'Passer', 'sw': 'Ruka',
    'ur': 'نظرانداز کریں', 'tr': 'Geç', 'id': 'Lewati', 'bn': 'বাদ দিন', 'ha': 'Tsallake',
    'so': 'Ka Bood', 'fa': 'رد کردن', 'ms': 'Langkau',
  },
  // KHATM_SYSTEM_AND_STYLE_REFERENCE.md §1.3 — the first-launch language
  // picker's own title (a new page 0 in the existing onboarding PageView).
  'onboarding_language_title': {
    'ar': 'اختر لغتك', 'en': 'Choose your language', 'am': 'ቋንቋዎን ይምረጡ', 'fr': 'Choisissez votre langue', 'sw': 'Chagua lugha yako',
    'ur': 'اپنی زبان منتخب کریں', 'tr': 'Dilinizi seçin', 'id': 'Pilih bahasa Anda', 'bn': 'আপনার ভাষা বেছে নিন', 'ha': 'Zaɓi harshenka',
    'so': 'Dooro luqaddaada', 'fa': 'زبان خود را انتخاب کنید', 'ms': 'Pilih bahasa anda',
  },
  'onboarding_next': {
    'ar': 'التالي', 'en': 'Next', 'am': 'ቀጣይ', 'fr': 'Suivant', 'sw': 'Ifuatayo',
    'ur': 'اگلا', 'tr': 'İleri', 'id': 'Selanjutnya', 'bn': 'পরবর্তী', 'ha': 'Na Gaba',
    'so': 'Xiga', 'fa': 'بعدی', 'ms': 'Seterusnya',
  },
  'onboarding_start_now': {
    'ar': 'ابدأ الآن', 'en': 'Start Now', 'am': 'አሁን ጀምር', 'fr': 'Commencer maintenant', 'sw': 'Anza Sasa',
    'ur': 'ابھی شروع کریں', 'tr': 'Şimdi Başla', 'id': 'Mulai Sekarang', 'bn': 'এখনই শুরু করুন', 'ha': 'Fara Yanzu',
    'so': 'Bilow Hadda', 'fa': 'اکنون شروع کن', 'ms': 'Mula Sekarang',
  },
  'onboarding_close': {
    'ar': 'إغلاق', 'en': 'Close', 'am': 'ዝጋ', 'fr': 'Fermer', 'sw': 'Funga',
    'ur': 'بند کریں', 'tr': 'Kapat', 'id': 'Tutup', 'bn': 'বন্ধ করুন', 'ha': 'Rufe',
    'so': 'Xir', 'fa': 'بستن', 'ms': 'Tutup',
  },
  'onboarding_slide1_title': {
    'ar': 'مرحباً بك في طالب العلم 👋', 'en': 'Welcome to Talib al-Ilm 👋', 'am': 'እንኳን ወደ ጣሊብ አል-ዒልም በደህና መጡ 👋', 'fr': 'Bienvenue dans Talib al-Ilm 👋', 'sw': 'Karibu Talib al-Ilm 👋',
    'ur': 'طالب العلم میں خوش آمدید 👋', 'tr': 'Talib al-Ilm\'e Hoş Geldiniz 👋', 'id': 'Selamat Datang di Talib al-Ilm 👋', 'bn': 'তালিবুল ইলম-এ স্বাগতম 👋', 'ha': 'Barka da Zuwa Talib al-Ilm 👋',
    'so': 'Ku Soo Dhowow Talib al-Ilm 👋', 'fa': 'به طالب العلم خوش آمدید 👋', 'ms': 'Selamat Datang ke Talib al-Ilm 👋',
  },
  'onboarding_slide1_body': {
    'ar': 'رفيقك في حفظ القرآن وفهمه وتطبيقه — مع الحديث والعقيدة والأذكار والتجويد وأكثر، كل ذلك بلا إنترنت ولا إعلانات.',
    'en': 'Your companion for memorizing, understanding, and living the Qur\'an — with hadith, aqeedah, adhkar, tajweed, and more, all fully offline and ad-free.',
    'am': 'ቁርኣንን ለማጥናት፣ ለመረዳት እና በተግባር ላዋሉ አጋርዎ — ከሐዲስ፣ ዐቂዳ፣ አዝካር እና ተጅዊድ ጋር፣ ሁሉም ያለ ኢንተርኔት እና ያለ ማስታወቂያ።',
    'fr': 'Votre compagnon pour mémoriser, comprendre et vivre le Coran — avec le hadith, l\'aqida, les adhkar, le tajwid et plus encore, entièrement hors ligne et sans publicité.',
    'sw': 'Rafiki yako wa kuhifadhi, kuelewa, na kutekeleza Qur\'an — pamoja na hadithi, aqidah, adhkar, tajwid na zaidi, yote bila mtandao na bila matangazo.',
    'ur': 'قرآن کو حفظ کرنے، سمجھنے اور اس پر عمل کرنے میں آپ کا ساتھی — حدیث، عقیدہ، اذکار، تجوید اور مزید کے ساتھ، یہ سب بغیر انٹرنیٹ اور بغیر اشتہارات کے۔',
    'tr': 'Kur\'an\'ı ezberleme, anlama ve yaşama yolunda arkadaşınız — hadis, akide, ezkâr, tecvid ve daha fazlasıyla, tamamen çevrimdışı ve reklamsız.',
    'id': 'Sahabat Anda dalam menghafal, memahami, dan mengamalkan Al-Qur\'an — dengan hadits, akidah, adzkar, tajwid, dan lainnya, semuanya offline penuh dan tanpa iklan.',
    'bn': 'কুরআন হিফজ, বোঝা ও জীবনে প্রয়োগ করার সঙ্গী — হাদিস, আকিদা, আজকার, তাজবিদ ও আরও অনেক কিছু নিয়ে, সবকিছু সম্পূর্ণ অফলাইনে এবং বিজ্ঞাপনমুক্ত।',
    'ha': 'Abokinka wajen haddace, fahimta, da aiwatar da Alkur\'ani — tare da hadisi, akida, azkari, tajwidi da ƙari, duk babu intanet kuma babu talla.',
    'so': 'Saaxiibkaaga xifdhinta, fahamka, iyo dhaqan-galinta Qur\'aanka — oo wata xadiiska, caqiidada, adkaarka, tajwiidka iyo wax badan, dhammaantoodna aan lahayn internet ama xayaysiisyo.',
    'fa': 'همراه شما در حفظ، فهم و عمل به قرآن — همراه با حدیث، عقیده، اذکار، تجوید و بیشتر، همگی به‌طور کامل آفلاین و بدون تبلیغات.',
    'ms': 'Sahabat anda dalam menghafal, memahami, dan mengamalkan Al-Quran — bersama hadis, akidah, zikir, tajwid dan banyak lagi, semuanya luar talian sepenuhnya dan bebas iklan.',
  },
  'onboarding_slide2_title': {
    'ar': 'حفظ القرآن ومراجعته', 'en': 'Memorizing & Reviewing the Qur\'an', 'am': 'ቁርኣንን ማጥናት እና መከለስ', 'fr': 'Mémoriser et réviser le Coran', 'sw': 'Kuhifadhi na Kupitia Qur\'an',
    'ur': 'قرآن حفظ کرنا اور دہرانا', 'tr': 'Kur\'an\'ı Ezberleme ve Tekrar', 'id': 'Menghafal & Mengulang Al-Qur\'an', 'bn': 'কুরআন হিফজ ও পুনরাবৃত্তি', 'ha': 'Haddace da Sake Nazarin Alkur\'ani',
    'so': 'Xifdhinta iyo Dib-u-eegista Qur\'aanka', 'fa': 'حفظ و مرور قرآن', 'ms': 'Menghafal & Mengulangkaji Al-Quran',
  },
  'onboarding_slide2_body': {
    'ar': 'اقرأ المصحف صفحة بصفحة برسم عثماني حقيقي، احفظ بوتيرتك الخاصة، وراجع بمحرك مراجعة ذكي (6 محطات) يذكّرك بالوقت الأمثل لكل صفحة قبل أن تُنسى.',
    'en': 'Read the Mushaf page by page in authentic Uthmani script, memorize at your own pace, and review with a smart 6-stage review engine that reminds you of the ideal time for each page before it\'s forgotten.',
    'am': 'ሙስሐፉን ገጽ በገጽ በእውነተኛ ዑስማኒ ጽሑፍ ያንብቡ፣ በራስዎ ፍጥነት ያጥኑ፣ እና ገጹ ከመረሳቱ በፊት ትክክለኛውን ጊዜ የሚያስታውስዎ ብልህ የ6-ደረጃ መከለሻ ሞተር ይጠቀሙ።',
    'fr': 'Lisez le Moushaf page par page en véritable écriture othmanie, mémorisez à votre rythme, et révisez avec un moteur de révision intelligent à 6 étapes qui vous rappelle le moment idéal pour chaque page avant qu\'elle ne soit oubliée.',
    'sw': 'Soma Msahafu ukurasa kwa ukurasa kwa maandishi halisi ya Kiuthmani, hifadhi kwa kasi yako mwenyewe, na pitia kwa injini ya kupitia yenye hatua 6 zenye akili inayokukumbusha wakati bora wa kila ukurasa kabla haujasahaulika.',
    'ur': 'مصحف کو صفحہ بہ صفحہ اصل عثمانی رسم الخط میں پڑھیں، اپنی رفتار سے حفظ کریں، اور 6 مراحل پر مشتمل ذہین دہرانے کے انجن سے دہرائیں جو بھولنے سے پہلے ہر صفحے کے بہترین وقت کی یاد دہانی کراتا ہے۔',
    'tr': 'Mushaf\'ı sayfa sayfa gerçek Osmanlı hattıyla okuyun, kendi hızınızda ezberleyin ve her sayfa unutulmadan önce ideal tekrar zamanını hatırlatan akıllı 6 aşamalı tekrar motoruyla tekrar edin.',
    'id': 'Baca Mushaf halaman demi halaman dengan rasm Utsmani yang otentik, hafalkan sesuai kecepatan Anda sendiri, dan ulangi dengan mesin pengulangan cerdas 6 tahap yang mengingatkan Anda waktu ideal untuk setiap halaman sebelum terlupakan.',
    'bn': 'আসল উসমানি রসমে মুসহাফ পাতায় পাতায় পড়ুন, নিজের গতিতে হিফজ করুন, এবং ৬-ধাপের বুদ্ধিমান পুনরাবৃত্তি ইঞ্জিন দিয়ে দোহরান, যা প্রতিটি পাতা ভুলে যাওয়ার আগে সঠিক সময় স্মরণ করিয়ে দেয়।',
    'ha': 'Karanta Mushafi shafi-shafi da rubutun Usmani na gaskiya, ka haddace da saurin da ya dace da kai, kuma ka sake nazari da injin sake-nazari mai matakai 6 mai basira wanda ke tunatar da kai lokacin da ya dace na kowane shafi kafin a manta shi.',
    'so': 'Akhri Mushafka bog-bog ah oo qoraal Cusmaani ah oo dhab ah, xifdhi si u dhaqso ah oo kuu gaar ah, oo dib-u-eeg matoor dib-u-eegis xikmad leh oo 6 marxaladood ah oo kuu xasuusiya waqtiga ku habboon bog kasta ka hor inta aan la illoobin.',
    'fa': 'مصحف را صفحه به صفحه با رسم‌الخط اصیل عثمانی بخوانید، با سرعت خودتان حفظ کنید و با موتور مرور هوشمند ۶ مرحله‌ای که زمان ایده‌آل هر صفحه را پیش از فراموشی به شما یادآوری می‌کند، مرور کنید.',
    'ms': 'Baca Mushaf halaman demi halaman dengan rasm Uthmani yang tulen, hafal mengikut kelajuan anda sendiri, dan ulangkaji dengan enjin ulangkaji pintar 6 peringkat yang mengingatkan anda masa terbaik untuk setiap halaman sebelum ia dilupakan.',
  },
  'onboarding_slide3_title': {
    'ar': 'رحلتك ومدرّب الحفظ', 'en': 'Your Journey & Memorization Coach', 'am': 'ጉዞዎ እና የማጥናት አሰልጣኝ', 'fr': 'Votre parcours et votre coach de mémorisation', 'sw': 'Safari Yako na Kocha wa Kuhifadhi',
    'ur': 'آپ کا سفر اور حفظ کوچ', 'tr': 'Yolculuğunuz ve Ezber Koçu', 'id': 'Perjalanan Anda & Pelatih Hafalan', 'bn': 'আপনার যাত্রা ও হিফজ কোচ', 'ha': 'Tafiyarka da Kocin Haddacewa',
    'so': 'Safarkaaga iyo Tababarahaaga Xifdhinta', 'fa': 'مسیر شما و مربی حفظ', 'ms': 'Perjalanan Anda & Jurulatih Hafazan',
  },
  'onboarding_slide3_body': {
    'ar': 'من "رحلتي" حدّد هدف ختمك وتابع وتيرتك المتكيفة يومًا بيوم — بالموعد أو متأخر أو متقدم — بلا ضغط ولا معاقبة عند الانقطاع.',
    'en': 'From "My Journey" set your completion goal and track your pace day by day — on schedule, behind, or ahead — with no pressure and no penalty when you miss a day.',
    'am': 'ከ"ጉዞዬ" የማጠናቀቂያ ግብዎን ያዘጋጁ እና ፍጥነትዎን ቀን በቀን ይከታተሉ — በጊዜ፣ ዘግይቶ፣ ወይም ቀድሞ — ያለ ጫና እና ያለ ቅጣት ቀን ሲያመልጥዎ።',
    'fr': 'Dans "Mon parcours", fixez votre objectif de complétion et suivez votre rythme jour après jour — à l\'heure, en retard, ou en avance — sans pression et sans pénalité si vous manquez un jour.',
    'sw': 'Kutoka "Safari Yangu" weka lengo lako la kukamilisha na fuatilia kasi yako siku kwa siku — kwa wakati, umechelewa, au umetangulia — bila shinikizo na bila adhabu unapokosa siku.',
    'ur': '"میرا سفر" میں اپنا تکمیل کا ہدف مقرر کریں اور روز بروز اپنی رفتار دیکھیں — وقت پر، پیچھے، یا آگے — بغیر کسی دباؤ اور بغیر کسی سزا کے جب کوئی دن چھوٹ جائے۔',
    'tr': '"Yolculuğum"dan hatim hedefinizi belirleyin ve gün gün hızınızı takip edin — zamanında, geride veya önde — bir günü kaçırdığınızda baskı ya da ceza olmadan.',
    'id': 'Dari "Perjalananku" tetapkan target khatam Anda dan pantau kecepatan Anda hari demi hari — sesuai jadwal, tertinggal, atau lebih cepat — tanpa tekanan dan tanpa hukuman saat melewatkan satu hari.',
    'bn': '"আমার যাত্রা" থেকে আপনার খতম লক্ষ্য নির্ধারণ করুন এবং দিনে দিনে আপনার গতি অনুসরণ করুন — নির্ধারিত সময়ে, পিছিয়ে, বা এগিয়ে — কোনো চাপ ছাড়া এবং একদিন বাদ পড়লে কোনো শাস্তি ছাড়াই।',
    'ha': 'Daga "Tafiyata" ka saita burin kammala karatun ka, ka kuma bibiyi saurin ka kullum — kana kan lokaci, a baya, ko a gaba — babu matsin lamba kuma babu hukunci idan ka rasa yini.',
    'so': 'Ka "Safarkayga" dooro yoolkaaga dhammaystirka oo la soco xawaaraaga maalin walba — waqtiga saxda ah, dib maray, ama hore u socda — cadaadis la\'aan iyo ciqaab la\'aan haddii aad maalin ka maqnaato.',
    'fa': 'از "سفر من" هدف ختم خود را تعیین کنید و روند خود را روز به روز دنبال کنید — طبق برنامه، عقب‌مانده یا جلوتر — بدون فشار و بدون جریمه در صورت جا ماندن یک روز.',
    'ms': 'Daripada "Perjalanan Saya" tetapkan sasaran khatam anda dan jejaki kadar anda hari demi hari — mengikut jadual, ketinggalan, atau lebih awal — tanpa tekanan dan tanpa hukuman apabila anda terlepas satu hari.',
  },
  'onboarding_slide4_title': {
    'ar': 'أبعد من القرآن', 'en': 'Beyond the Qur\'an', 'am': 'ከቁርኣን ባሻገር', 'fr': 'Au-delà du Coran', 'sw': 'Zaidi ya Qur\'an',
    'ur': 'قرآن سے آگے', 'tr': 'Kur\'an\'ın Ötesinde', 'id': 'Lebih dari Al-Qur\'an', 'bn': 'কুরআনের বাইরেও', 'ha': 'Bayan Alkur\'ani',
    'so': 'Waxa ka Baxsan Qur\'aanka', 'fa': 'فراتر از قرآن', 'ms': 'Melangkaui Al-Quran',
  },
  'onboarding_slide4_body': {
    'ar': 'الأربعون النووية، العقيدة الواسطية، أحكام التجويد، حصن المسلم للأذكار، ودروس تطبيقية — كل علم له مكانه ومراجعته الخاصة.',
    'en': 'The 40 Hadith of an-Nawawi, al-Aqeedah al-Wasitiyyah, tajweed rules, Hisn al-Muslim for adhkar, and practical lessons — each subject with its own place and its own review track.',
    'am': 'የነወዊ 40 ሐዲሶች፣ ዐቂዳ ዋሲጢያ፣ የተጅዊድ ሕጎች፣ ለአዝካር ሂስን አል-ሙስሊም፣ እና ተግባራዊ ትምህርቶች — እያንዳንዱ ትምህርት የራሱ ቦታ እና የራሱ መከለሻ አለው።',
    'fr': 'Les 40 hadiths d\'an-Nawawi, al-Aqida al-Wasitiyya, les règles du tajwid, Hisn al-Muslim pour les adhkar, et des leçons pratiques — chaque matière a sa propre place et son propre suivi de révision.',
    'sw': 'Hadithi 40 za an-Nawawi, al-Aqidah al-Wasitiyyah, kanuni za tajwid, Hisn al-Muslim kwa adhkar, na masomo ya vitendo — kila somo lina nafasi yake na njia yake ya kupitia.',
    'ur': 'امام نووی کی چالیس احادیث، عقیدہ واسطیہ، تجوید کے احکام، اذکار کے لیے حصن المسلم، اور عملی اسباق — ہر علم کی اپنی جگہ اور اپنا دہرانے کا نظام ہے۔',
    'tr': 'Nevevi\'nin 40 hadisi, el-Akidetü\'l-Vasıtiyye, tecvid kuralları, ezkâr için Hısnü\'l-Müslim ve pratik dersler — her ilmin kendi yeri ve kendi tekrar sistemi var.',
    'id': '40 Hadits Nawawi, Aqidah Wasitiyah, hukum tajwid, Hisnul Muslim untuk adzkar, dan pelajaran praktis — setiap ilmu memiliki tempat dan jalur pengulangannya sendiri.',
    'bn': 'নববীর ৪০ হাদিস, আকিদাতুল ওয়াসিতিয়্যাহ, তাজবিদের বিধান, আজকারের জন্য হিসনুল মুসলিম, এবং ব্যবহারিক পাঠ — প্রতিটি বিষয়ের নিজস্ব স্থান ও নিজস্ব পুনরাবৃত্তি ব্যবস্থা রয়েছে।',
    'ha': 'Hadisai 40 na Nawawi, Aqeedah al-Wasitiyyah, ka\'idojin tajwidi, Hisn al-Muslim na azkari, da darussan aiki — kowane ilimi yana da wurinsa da tsarin sake-nazarinsa na musamman.',
    'so': 'Afartankii Xadiith ee Imaam Nawawi, Caqiidada Waasidiyada, xeerarka Tajwiidka, Hisnul-Muslim ee adkaarka, iyo casharrada wax ku ool ah — cilmi kastaa wuxuu leeyahay meel iyo hab dib-u-eegis oo isaga u gaar ah.',
    'fa': 'چهل حدیث نووی، عقیده واسطیه، احکام تجوید، حصن المسلم برای اذکار، و درس‌های کاربردی — هر علمی جایگاه و مسیر مرور خاص خود را دارد.',
    'ms': '40 Hadis an-Nawawi, Aqidah al-Wasitiyyah, hukum tajwid, Hisnul Muslim untuk zikir, dan pelajaran praktikal — setiap ilmu mempunyai tempat dan laluan ulangkajinya sendiri.',
  },
  'onboarding_slide5_title': {
    'ar': 'جلسة اليوم ورفيقك', 'en': 'Today\'s Session & Your Companion', 'am': 'የዛሬው ክፍለ ጊዜ እና አጋርዎ', 'fr': 'La séance du jour et votre compagnon', 'sw': 'Kipindi cha Leo na Rafiki Yako',
    'ur': 'آج کا سیشن اور آپ کا ساتھی', 'tr': 'Bugünkü Oturum ve Arkadaşınız', 'id': 'Sesi Hari Ini & Sahabat Anda', 'bn': 'আজকের সেশন ও আপনার সঙ্গী', 'ha': 'Zaman Yau da Abokinka',
    'so': 'Fadhiga Maanta iyo Saaxiibkaaga', 'fa': 'جلسه امروز و همراه شما', 'ms': 'Sesi Hari Ini & Sahabat Anda',
  },
  'onboarding_slide5_body': {
    'ar': 'ابدأ "جلسة اليوم" لخطة موجّهة بالوقت المتاح لديك، ورفيق طالب العلم معك يشجعك ويذكّرك — كل هذا يعمل بالكامل دون اتصال بالإنترنت.',
    'en': 'Start "Today\'s Session" for a plan guided by the time you have available, with your Talib al-Ilm companion by your side to encourage and remind you — all of it working fully offline.',
    'am': '"የዛሬው ክፍለ ጊዜ" ይጀምሩ ላሉት ጊዜ በተመራ እቅድ፣ እና ጣሊብ አል-ዒልም አጋርዎ ከጎንዎ ያበረታታዎታል እና ያስታውስዎታል — ይህ ሁሉ ያለ ኢንተርኔት ሙሉ በሙሉ ይሰራል።',
    'fr': 'Lancez la "Séance du jour" pour un plan guidé selon le temps dont vous disposez, avec votre compagnon Talib al-Ilm à vos côtés pour vous encourager et vous rappeler — le tout fonctionnant entièrement hors ligne.',
    'sw': 'Anza "Kipindi cha Leo" kwa mpango unaoongozwa na muda ulio nao, akiwa na rafiki yako wa Talib al-Ilm karibu yako kukutia moyo na kukukumbusha — yote yakifanya kazi bila mtandao kabisa.',
    'ur': '"آج کا سیشن" شروع کریں تاکہ آپ کے دستیاب وقت کے مطابق رہنمائی ملے، اور طالب العلم کا ساتھی آپ کے ساتھ حوصلہ افزائی اور یاد دہانی کرائے — یہ سب کچھ مکمل طور پر بغیر انٹرنیٹ کے کام کرتا ہے۔',
    'tr': 'Elinizdeki zamana göre yönlendirilen bir plan için "Bugünkü Oturum"u başlatın; Talib al-Ilm arkadaşınız yanınızda sizi teşvik eder ve hatırlatır — tüm bunlar tamamen çevrimdışı çalışır.',
    'id': 'Mulai "Sesi Hari Ini" untuk rencana yang disesuaikan dengan waktu yang Anda miliki, dengan sahabat Talib al-Ilm di sisi Anda untuk menyemangati dan mengingatkan — semuanya berjalan sepenuhnya offline.',
    'bn': 'আপনার হাতে থাকা সময় অনুযায়ী পরিচালিত পরিকল্পনার জন্য "আজকের সেশন" শুরু করুন, এবং আপনার তালিবুল ইলম সঙ্গী পাশে থেকে উৎসাহ দেয় ও মনে করিয়ে দেয় — এসব কিছুই সম্পূর্ণ অফলাইনে কাজ করে।',
    'ha': 'Fara "Zaman Yau" don shirin da aka jagoranta bisa lokacin da kake da shi, tare da abokinka na Talib al-Ilm a gefenka don ƙarfafa ka da tunatar da kai — duk wannan yana aiki gaba ɗaya ba tare da intanet ba.',
    'so': 'Bilow "Fadhiga Maanta" si aad u hesho qorshe ku salaysan waqtiga aad haysato, adigoo wata saaxiibkaaga Talib al-Ilm oo ku dhiirigelinaya oo ku xasuusinaya — dhammaan kuwan waxay si buuxda u shaqeeyaan iyaga oo aan lahayn internet.',
    'fa': '"جلسه امروز" را برای برنامه‌ای متناسب با زمان در دسترستان شروع کنید، در حالی که همراه طالب العلم شما را تشویق و یادآوری می‌کند — همه اینها کاملاً به‌صورت آفلاین کار می‌کند.',
    'ms': 'Mulakan "Sesi Hari Ini" untuk pelan yang dipandu mengikut masa yang anda ada, dengan sahabat Talib al-Ilm di sisi anda untuk memberi semangat dan mengingatkan — semuanya berfungsi sepenuhnya luar talian.',
  },
  // 2026-08-22: activities_screen.dart + add_activity_screen.dart — the
  // "الأنشطة" tab and its add/edit form, found still 100% hardcoded Arabic
  // during the app-wide UI-chrome translation sweep. AppBar title reuses
  // 'nav_activities' as the prefix before the interpolated month label
  // (same pattern already used by goals_screen.dart with 'nav_goals').
  'no_activities_yet': {
    'ar': 'لا توجد أنشطة مسجلة هذا الشهر بعد', 'en': 'No activities recorded this month yet', 'am': 'እስካሁን በዚህ ወር የተመዘገበ እንቅስቃሴ የለም', 'fr': "Aucune activité enregistrée ce mois-ci pour l'instant", 'sw': 'Bado hakuna shughuli zilizorekodiwa mwezi huu',
    'ur': 'اس مہینے ابھی تک کوئی سرگرمی درج نہیں ہوئی', 'tr': 'Bu ay henüz kaydedilmiş etkinlik yok', 'id': 'Belum ada aktivitas yang tercatat bulan ini', 'bn': 'এই মাসে এখনও কোনো কার্যক্রম রেকর্ড করা হয়নি', 'ha': 'Babu ayyukan da aka rubuta a wannan watan tukuna',
    'so': 'Wali hawlo lagu diiwaan geliyay bishan lama helin', 'fa': 'هنوز فعالیتی برای این ماه ثبت نشده است', 'ms': 'Belum ada aktiviti direkodkan bulan ini',
  },
  'beneficiaries_label': {
    'ar': 'مستفيدون', 'en': 'Beneficiaries', 'am': 'ተጠቃሚዎች', 'fr': 'Bénéficiaires', 'sw': 'Wanufaika',
    'ur': 'مستفیدین', 'tr': 'Yararlananlar', 'id': 'Penerima Manfaat', 'bn': 'সুবিধাভোগী', 'ha': 'Masu Amfana',
    'so': "Faa'iidaystayaasha", 'fa': 'بهره‌مندان', 'ms': 'Penerima Manfaat',
  },
  'add_activity_title': {
    'ar': 'إضافة نشاط', 'en': 'Add Activity', 'am': 'እንቅስቃሴ ጨምር', 'fr': 'Ajouter une activité', 'sw': 'Ongeza Shughuli',
    'ur': 'سرگرمی شامل کریں', 'tr': 'Etkinlik Ekle', 'id': 'Tambah Aktivitas', 'bn': 'কার্যক্রম যোগ করুন', 'ha': 'Ƙara Aiki',
    'so': 'Ku dar Hawl', 'fa': 'افزودن فعالیت', 'ms': 'Tambah Aktiviti',
  },
  'edit_activity_title': {
    'ar': 'تعديل نشاط', 'en': 'Edit Activity', 'am': 'እንቅስቃሴ አርትዕ', 'fr': "Modifier l'activité", 'sw': 'Hariri Shughuli',
    'ur': 'سرگرمی میں ترمیم کریں', 'tr': 'Etkinliği Düzenle', 'id': 'Ubah Aktivitas', 'bn': 'কার্যক্রম সম্পাদনা করুন', 'ha': 'Gyara Aiki',
    'so': 'Wax ka Beddel Hawsha', 'fa': 'ویرایش فعالیت', 'ms': 'Edit Aktiviti',
  },
  'title_desc_required': {
    'ar': 'يرجى إدخال العنوان/الوصف', 'en': 'Please enter the title/description', 'am': 'እባክዎ ርዕስ/መግለጫ ያስገቡ', 'fr': 'Veuillez saisir le titre/la description', 'sw': 'Tafadhali weka kichwa/maelezo',
    'ur': 'براہ کرم عنوان/تفصیل درج کریں', 'tr': 'Lütfen başlık/açıklama girin', 'id': 'Silakan masukkan judul/deskripsi', 'bn': 'অনুগ্রহ করে শিরোনাম/বিবরণ লিখুন', 'ha': 'Da fatan za a shigar da take/bayani',
    'so': 'Fadlan geli cinwaanka/sharaxaadda', 'fa': 'لطفاً عنوان/توضیحات را وارد کنید', 'ms': 'Sila masukkan tajuk/penerangan',
  },
  'delete_activity_title': {
    'ar': 'حذف النشاط', 'en': 'Delete Activity', 'am': 'እንቅስቃሴ ሰርዝ', 'fr': "Supprimer l'activité", 'sw': 'Futa Shughuli',
    'ur': 'سرگرمی حذف کریں', 'tr': 'Etkinliği Sil', 'id': 'Hapus Aktivitas', 'bn': 'কার্যক্রম মুছুন', 'ha': 'Share Aiki',
    'so': 'Tirtir Hawsha', 'fa': 'حذف فعالیت', 'ms': 'Padam Aktiviti',
  },
  'delete_activity_confirm': {
    'ar': 'هل تريد حذف هذا النشاط؟', 'en': 'Do you want to delete this activity?', 'am': 'ይህን እንቅስቃሴ መሰረዝ ይፈልጋሉ?', 'fr': 'Voulez-vous supprimer cette activité ?', 'sw': 'Je, unataka kufuta shughuli hii?',
    'ur': 'کیا آپ یہ سرگرمی حذف کرنا چاہتے ہیں؟', 'tr': 'Bu etkinliği silmek istiyor musunuz?', 'id': 'Apakah Anda ingin menghapus aktivitas ini?', 'bn': 'আপনি কি এই কার্যক্রমটি মুছতে চান?', 'ha': 'Kana son share wannan aikin?',
    'so': 'Ma rabtaa inaad tirtirto hawshan?', 'fa': 'آیا می‌خواهید این فعالیت را حذف کنید؟', 'ms': 'Adakah anda ingin memadam aktiviti ini?',
  },
  'delete': {
    'ar': 'حذف', 'en': 'Delete', 'am': 'ሰርዝ', 'fr': 'Supprimer', 'sw': 'Futa',
    'ur': 'حذف کریں', 'tr': 'Sil', 'id': 'Hapus', 'bn': 'মুছুন', 'ha': 'Share',
    'so': 'Tirtir', 'fa': 'حذف', 'ms': 'Padam',
  },
  'activity_type_label': {
    'ar': 'نوع النشاط', 'en': 'Activity Type', 'am': 'የእንቅስቃሴ ዓይነት', 'fr': "Type d'activité", 'sw': 'Aina ya Shughuli',
    'ur': 'سرگرمی کی قسم', 'tr': 'Etkinlik Türü', 'id': 'Jenis Aktivitas', 'bn': 'কার্যক্রমের ধরন', 'ha': "Nau'in Aiki",
    'so': 'Nooca Hawsha', 'fa': 'نوع فعالیت', 'ms': 'Jenis Aktiviti',
  },
  'hijri_date_label_prefix': {
    'ar': 'التاريخ الهجري', 'en': 'Hijri Date', 'am': 'የሂጅሪ ቀን', 'fr': 'Date hégirienne', 'sw': 'Tarehe ya Hijri',
    'ur': 'ہجری تاریخ', 'tr': 'Hicri Tarih', 'id': 'Tanggal Hijriah', 'bn': 'হিজরি তারিখ', 'ha': 'Kwanan Hijira',
    'so': 'Taariikhda Hijriga', 'fa': 'تاریخ هجری', 'ms': 'Tarikh Hijrah',
  },
  'date_picker_subtitle': {
    'ar': 'اضغط لاختيار تاريخ آخر (يظهر التقويم الميلادي للاختيار فقط)', 'en': 'Tap to choose another date (the Gregorian calendar is shown for selection only)', 'am': 'ሌላ ቀን ለመምረጥ ተጫን (ጎርጎርያን ካላንደር ለምርጫ ብቻ ይታያል)', 'fr': "Appuyez pour choisir une autre date (le calendrier grégorien s'affiche uniquement pour la sélection)", 'sw': 'Bonyeza kuchagua tarehe nyingine (kalenda ya Kigregori inaonyeshwa kwa uchaguzi tu)',
    'ur': 'دوسری تاریخ چننے کے لیے دبائیں (عیسوی کیلنڈر صرف انتخاب کے لیے دکھایا جاتا ہے)', 'tr': 'Başka bir tarih seçmek için dokunun (Miladi takvim yalnızca seçim için gösterilir)', 'id': 'Ketuk untuk memilih tanggal lain (kalender Masehi hanya ditampilkan untuk pemilihan)', 'bn': 'অন্য তারিখ বেছে নিতে চাপুন (গ্রেগরিয়ান ক্যালেন্ডার শুধুমাত্র নির্বাচনের জন্য দেখানো হয়)', 'ha': 'Danna don zaɓar wata rana (ana nuna kalandar Miladiyya don zaɓi kawai)',
    'so': 'Taabo si aad u doorato taariikh kale (kalandarka Miilaadiga waxaa loo muujiyaa doorasho kaliya)', 'fa': 'برای انتخاب تاریخ دیگر ضربه بزنید (تقویم میلادی فقط برای انتخاب نمایش داده می‌شود)', 'ms': 'Ketik untuk memilih tarikh lain (kalendar Masihi dipaparkan untuk pemilihan sahaja)',
  },
  'name_details_label': {
    'ar': 'اسم/تفاصيل', 'en': 'Name/Details', 'am': 'ስም/ዝርዝሮች', 'fr': 'Nom/Détails', 'sw': 'Jina/Maelezo',
    'ur': 'نام/تفصیلات', 'tr': 'İsim/Detaylar', 'id': 'Nama/Detail', 'bn': 'নাম/বিবরণ', 'ha': 'Suna/Bayani',
    'so': 'Magaca/Faahfaahin', 'fa': 'نام/جزئیات', 'ms': 'Nama/Butiran',
  },
  'title_desc_label': {
    'ar': 'العنوان / الوصف', 'en': 'Title / Description', 'am': 'ርዕስ / መግለጫ', 'fr': 'Titre / Description', 'sw': 'Kichwa / Maelezo',
    'ur': 'عنوان / تفصیل', 'tr': 'Başlık / Açıklama', 'id': 'Judul / Deskripsi', 'bn': 'শিরোনাম / বিবরণ', 'ha': 'Take / Bayani',
    'so': 'Cinwaanka / Sharaxaadda', 'fa': 'عنوان / توضیحات', 'ms': 'Tajuk / Penerangan',
  },
  'beneficiaries_count_label': {
    'ar': 'عدد المستفيدين (تقريبي)', 'en': 'Number of Beneficiaries (approx.)', 'am': 'የተጠቃሚዎች ብዛት (ግምት)', 'fr': 'Nombre de bénéficiaires (approximatif)', 'sw': 'Idadi ya Wanufaika (takriban)',
    'ur': 'مستفیدین کی تعداد (تخمینی)', 'tr': 'Yararlanan Sayısı (yaklaşık)', 'id': 'Jumlah Penerima Manfaat (perkiraan)', 'bn': 'সুবিধাভোগীর সংখ্যা (আনুমানিক)', 'ha': 'Adadin Masu Amfana (kimanin)',
    'so': "Tirada Faa'iidaystayaasha (qiyaas)", 'fa': 'تعداد بهره‌مندان (تقریبی)', 'ms': 'Bilangan Penerima Manfaat (anggaran)',
  },
  'notes_optional_label': {
    'ar': 'ملاحظات (اختياري)', 'en': 'Notes (optional)', 'am': 'ማስታወሻዎች (አማራጭ)', 'fr': 'Remarques (facultatif)', 'sw': 'Maelezo (si lazima)',
    'ur': 'نوٹس (اختیاری)', 'tr': 'Notlar (isteğe bağlı)', 'id': 'Catatan (opsional)', 'bn': 'নোট (ঐচ্ছিক)', 'ha': 'Bayanai (na zaɓi)',
    'so': 'Fiiro gaar ah (ikhtiyaari)', 'fa': 'یادداشت‌ها (اختیاری)', 'ms': 'Nota (pilihan)',
  },
  'save_changes_action': {
    'ar': 'حفظ التعديلات', 'en': 'Save Changes', 'am': 'ለውጦችን አስቀምጥ', 'fr': 'Enregistrer les modifications', 'sw': 'Hifadhi Mabadiliko',
    'ur': 'تبدیلیاں محفوظ کریں', 'tr': 'Değişiklikleri Kaydet', 'id': 'Simpan Perubahan', 'bn': 'পরিবর্তন সংরক্ষণ করুন', 'ha': 'Ajiye Canje-canje',
    'so': 'Kaydi Isbeddelada', 'fa': 'ذخیره تغییرات', 'ms': 'Simpan Perubahan',
  },
  // 2026-08-22: add_task_screen.dart + daily_tasks_screen.dart — the daily
  // tasks list, its add/edit form, and the completion-checklist dialog,
  // found still 100% hardcoded Arabic during the same sweep.
  'task_title_required': {
    'ar': 'يرجى إدخال عنوان المهمة', 'en': 'Please enter the task title', 'am': 'እባክዎ የተግባር ርዕስ ያስገቡ', 'fr': 'Veuillez saisir le titre de la tâche', 'sw': 'Tafadhali weka kichwa cha kazi',
    'ur': 'براہ کرم ٹاسک کا عنوان درج کریں', 'tr': 'Lütfen görev başlığını girin', 'id': 'Silakan masukkan judul tugas', 'bn': 'অনুগ্রহ করে কাজের শিরোনাম লিখুন', 'ha': 'Da fatan za a shigar da take na aiki',
    'so': 'Fadlan geli cinwaanka hawsha', 'fa': 'لطفاً عنوان وظیفه را وارد کنید', 'ms': 'Sila masukkan tajuk tugasan',
  },
  'delete_task_title': {
    'ar': 'حذف المهمة', 'en': 'Delete Task', 'am': 'ተግባር ሰርዝ', 'fr': 'Supprimer la tâche', 'sw': 'Futa Kazi',
    'ur': 'ٹاسک حذف کریں', 'tr': 'Görevi Sil', 'id': 'Hapus Tugas', 'bn': 'কাজ মুছুন', 'ha': 'Share Aiki',
    'so': 'Tirtir Hawsha', 'fa': 'حذف وظیفه', 'ms': 'Padam Tugasan',
  },
  'delete_task_confirm': {
    'ar': 'هل تريد حذف هذه المهمة؟', 'en': 'Do you want to delete this task?', 'am': 'ይህን ተግባር መሰረዝ ይፈልጋሉ?', 'fr': 'Voulez-vous supprimer cette tâche ?', 'sw': 'Je, unataka kufuta kazi hii?',
    'ur': 'کیا آپ یہ ٹاسک حذف کرنا چاہتے ہیں؟', 'tr': 'Bu görevi silmek istiyor musunuz?', 'id': 'Apakah Anda ingin menghapus tugas ini?', 'bn': 'আপনি কি এই কাজটি মুছতে চান?', 'ha': 'Kana son share wannan aikin?',
    'so': 'Ma rabtaa inaad tirtirto hawshan?', 'fa': 'آیا می‌خواهید این وظیفه را حذف کنید؟', 'ms': 'Adakah anda ingin memadam tugasan ini?',
  },
  'edit_task_title': {
    'ar': 'تعديل مهمة', 'en': 'Edit Task', 'am': 'ተግባር አርትዕ', 'fr': 'Modifier la tâche', 'sw': 'Hariri Kazi',
    'ur': 'ٹاسک میں ترمیم کریں', 'tr': 'Görevi Düzenle', 'id': 'Ubah Tugas', 'bn': 'কাজ সম্পাদনা করুন', 'ha': 'Gyara Aiki',
    'so': 'Wax ka Beddel Hawsha', 'fa': 'ویرایش وظیفه', 'ms': 'Edit Tugasan',
  },
  'new_task_title': {
    'ar': 'مهمة جديدة', 'en': 'New Task', 'am': 'አዲስ ተግባር', 'fr': 'Nouvelle tâche', 'sw': 'Kazi Mpya',
    'ur': 'نیا ٹاسک', 'tr': 'Yeni Görev', 'id': 'Tugas Baru', 'bn': 'নতুন কাজ', 'ha': 'Sabon Aiki',
    'so': 'Hawl Cusub', 'fa': 'وظیفه جدید', 'ms': 'Tugasan Baharu',
  },
  'task_title_label': {
    'ar': 'عنوان المهمة', 'en': 'Task Title', 'am': 'የተግባር ርዕስ', 'fr': 'Titre de la tâche', 'sw': 'Kichwa cha Kazi',
    'ur': 'ٹاسک کا عنوان', 'tr': 'Görev Başlığı', 'id': 'Judul Tugas', 'bn': 'কাজের শিরোনাম', 'ha': 'Take na Aiki',
    'so': 'Cinwaanka Hawsha', 'fa': 'عنوان وظیفه', 'ms': 'Tajuk Tugasan',
  },
  'no_time_set': {
    'ar': 'بدون وقت محدد', 'en': 'No time set', 'am': 'የተወሰነ ሰዓት የለም', 'fr': 'Aucune heure définie', 'sw': 'Hakuna wakati uliowekwa',
    'ur': 'کوئی وقت مقرر نہیں', 'tr': 'Belirlenmiş saat yok', 'id': 'Tidak ada waktu yang ditentukan', 'bn': 'কোনো সময় নির্ধারণ করা হয়নি', 'ha': 'Babu lokacin da aka saita',
    'so': 'Waqti la\'aan', 'fa': 'زمانی تعیین نشده', 'ms': 'Tiada masa ditetapkan',
  },
  'time_label_prefix': {
    'ar': 'الوقت', 'en': 'Time', 'am': 'ሰዓት', 'fr': 'Heure', 'sw': 'Wakati',
    'ur': 'وقت', 'tr': 'Saat', 'id': 'Waktu', 'bn': 'সময়', 'ha': 'Lokaci',
    'so': 'Waqtiga', 'fa': 'زمان', 'ms': 'Masa',
  },
  'reminder_notification_title': {
    'ar': 'تذكير عبر إشعار', 'en': 'Notification Reminder', 'am': 'በማሳወቂያ ማስታወሻ', 'fr': 'Rappel par notification', 'sw': 'Ukumbusho kwa Arifa',
    'ur': 'اطلاع کے ذریعے یاد دہانی', 'tr': 'Bildirimle Hatırlatma', 'id': 'Pengingat melalui Notifikasi', 'bn': 'বিজ্ঞপ্তির মাধ্যমে অনুস্মারক', 'ha': 'Tunatarwa ta Sanarwa',
    'so': 'Xasuusin Ogeysiis ah', 'fa': 'یادآوری از طریق اعلان', 'ms': 'Peringatan melalui Notifikasi',
  },
  'reminder_notification_subtitle': {
    'ar': 'يصلك إشعار في هذا الوقت لهذه المهمة', 'en': "You'll get a notification at this time for this task", 'am': 'በዚህ ሰዓት ለዚህ ተግባር ማሳወቂያ ይደርስዎታል', 'fr': 'Vous recevrez une notification à cette heure pour cette tâche', 'sw': 'Utapata arifa wakati huu kwa kazi hii',
    'ur': 'اس وقت پر آپ کو اس ٹاسک کے لیے اطلاع ملے گی', 'tr': 'Bu görev için bu saatte bir bildirim alacaksınız', 'id': 'Anda akan menerima notifikasi pada waktu ini untuk tugas ini', 'bn': 'এই সময়ে এই কাজের জন্য আপনি একটি বিজ্ঞপ্তি পাবেন', 'ha': 'Za ka sami sanarwa a wannan lokacin domin wannan aikin',
    'so': 'Waqtigan waxaad heli doontaa ogeysiis hawshan la xiriira', 'fa': 'در این زمان برای این وظیفه اعلانی دریافت خواهید کرد', 'ms': 'Anda akan menerima notifikasi pada masa ini untuk tugasan ini',
  },
  'completion_checklist_title': {
    'ar': 'قائمة التحقق عند الإكمال (اختياري)', 'en': 'Completion Checklist (optional)', 'am': 'የማጠናቀቂያ ማረጋገጫ ዝርዝር (አማራጭ)', 'fr': "Liste de vérification à l'achèvement (facultatif)", 'sw': 'Orodha ya Ukaguzi ya Kukamilisha (si lazima)',
    'ur': 'تکمیل کے وقت چیک لسٹ (اختیاری)', 'tr': 'Tamamlama Kontrol Listesi (isteğe bağlı)', 'id': 'Daftar Periksa Penyelesaian (opsional)', 'bn': 'সমাপ্তি চেকলিস্ট (ঐচ্ছিক)', 'ha': 'Jerin Duba na Kammalawa (na zaɓi)',
    'so': 'Liiska Hubinta Dhamaystirka (ikhtiyaari)', 'fa': 'چک‌لیست تکمیل (اختیاری)', 'ms': 'Senarai Semak Penyelesaian (pilihan)',
  },
  'completion_checklist_desc': {
    'ar': 'تظهر لك هذه النقاط لمراجعتها عند وضع علامة "مكتملة" على المهمة.', 'en': 'These points appear for you to review when you mark the task "completed."', 'am': 'ተግባሩን "የተጠናቀቀ" ብለው ሲያመልክቱ እነዚህ ነጥቦች ለክለሳ ይታያሉ።', 'fr': 'Ces points s\'affichent pour être vérifiés lorsque vous marquez la tâche comme "terminée".', 'sw': 'Vipengele hivi vinaonekana kwa ajili ya kukagua unapoweka alama "imekamilika" kwenye kazi.',
    'ur': 'جب آپ ٹاسک کو "مکمل" کا نشان لگاتے ہیں تو یہ نکات جائزے کے لیے ظاہر ہوتے ہیں۔', 'tr': 'Görevi "tamamlandı" olarak işaretlediğinizde bu maddeler gözden geçirmeniz için görünür.', 'id': 'Poin-poin ini muncul untuk Anda tinjau saat menandai tugas sebagai "selesai".', 'bn': 'কাজটিকে "সম্পন্ন" চিহ্নিত করার সময় এই পয়েন্টগুলো পর্যালোচনার জন্য দেখানো হয়।', 'ha': 'Waɗannan abubuwa suna bayyana don ka duba lokacin da ka sanya alamar "an kammala" akan aikin.',
    'so': 'Dhibcahan waxay kuu soo baxaan si aad u dib-u-eegto marka aad calaamadeyso hawsha "la dhammeeyay."', 'fa': 'این نکات هنگام علامت‌گذاری وظیفه به‌عنوان "تکمیل‌شده" برای بازبینی نمایش داده می‌شوند.', 'ms': 'Perkara-perkara ini dipaparkan untuk semakan anda apabila anda menandakan tugasan sebagai "selesai".',
  },
  'checklist_item_hint': {
    'ar': 'تأكد من...', 'en': 'Make sure to...', 'am': 'ያረጋግጡ...', 'fr': 'Assurez-vous de...', 'sw': 'Hakikisha...',
    'ur': 'یقینی بنائیں کہ...', 'tr': 'Şundan emin olun...', 'id': 'Pastikan untuk...', 'bn': 'নিশ্চিত করুন যে...', 'ha': 'Ka tabbatar...',
    'so': 'Hubi in...', 'fa': 'مطمئن شوید که...', 'ms': 'Pastikan...',
  },
  'add_checklist_point': {
    'ar': 'إضافة نقطة تحقق', 'en': 'Add Checklist Item', 'am': 'የማረጋገጫ ነጥብ ጨምር', 'fr': 'Ajouter un point de vérification', 'sw': 'Ongeza Kipengele cha Ukaguzi',
    'ur': 'چیک لسٹ آئٹم شامل کریں', 'tr': 'Kontrol Listesi Maddesi Ekle', 'id': 'Tambah Item Periksa', 'bn': 'চেকলিস্ট আইটেম যোগ করুন', 'ha': 'Ƙara Abin Dubawa',
    'so': 'Ku dar Qodob Hubin', 'fa': 'افزودن مورد چک‌لیست', 'ms': 'Tambah Item Semakan',
  },
  'add_task_action': {
    'ar': 'إضافة المهمة', 'en': 'Add Task', 'am': 'ተግባር ጨምር', 'fr': 'Ajouter la tâche', 'sw': 'Ongeza Kazi',
    'ur': 'ٹاسک شامل کریں', 'tr': 'Görev Ekle', 'id': 'Tambah Tugas', 'bn': 'কাজ যোগ করুন', 'ha': 'Ƙara Aiki',
    'so': 'Ku dar Hawsha', 'fa': 'افزودن وظیفه', 'ms': 'Tambah Tugasan',
  },
  'tasks_title': {
    'ar': 'المهام', 'en': 'Tasks', 'am': 'ተግባራት', 'fr': 'Tâches', 'sw': 'Kazi',
    'ur': 'کام', 'tr': 'Görevler', 'id': 'Tugas', 'bn': 'কাজসমূহ', 'ha': 'Ayyuka',
    'so': 'Hawlaha', 'fa': 'وظایف', 'ms': 'Tugasan',
  },
  'no_tasks_yet': {
    'ar': 'لا توجد مهام بعد — اضغط + لإضافة مهمة', 'en': 'No tasks yet — tap + to add one', 'am': 'እስካሁን ተግባራት የሉም — + ተጫን አንድ ለመጨመር', 'fr': 'Aucune tâche pour le moment — appuyez sur + pour en ajouter une', 'sw': 'Bado hakuna kazi — bonyeza + kuongeza',
    'ur': 'ابھی تک کوئی ٹاسک نہیں — شامل کرنے کے لیے + دبائیں', 'tr': 'Henüz görev yok — eklemek için + dokun', 'id': 'Belum ada tugas — ketuk + untuk menambahkan', 'bn': 'এখনও কোনো কাজ নেই — যোগ করতে + চাপুন', 'ha': 'Babu ayyuka tukuna — danna + don ƙarawa',
    'so': 'Wali hawlo ma jiraan — taabo + si aad u darto mid', 'fa': 'هنوز وظیفه‌ای نیست — برای افزودن + را بزنید', 'ms': 'Belum ada tugasan — ketik + untuk menambah',
  },
  'today_label': {
    'ar': 'اليوم', 'en': 'Today', 'am': 'ዛሬ', 'fr': "Aujourd'hui", 'sw': 'Leo',
    'ur': 'آج', 'tr': 'Bugün', 'id': 'Hari Ini', 'bn': 'আজ', 'ha': 'Yau',
    'so': 'Maanta', 'fa': 'امروز', 'ms': 'Hari Ini',
  },
  'upcoming_label': {
    'ar': 'القادمة', 'en': 'Upcoming', 'am': 'የሚመጡ', 'fr': 'À venir', 'sw': 'Zijazo',
    'ur': 'آنے والے', 'tr': 'Yaklaşan', 'id': 'Mendatang', 'bn': 'আসন্ন', 'ha': 'Masu Zuwa',
    'so': 'Kuwa Soo Socda', 'fa': 'پیش رو', 'ms': 'Akan Datang',
  },
  'review_checklist_before_complete': {
    'ar': 'راجع النقاط التالية قبل إكمال المهمة:', 'en': 'Review the following points before completing the task:', 'am': 'ተግባሩን ከማጠናቀቅዎ በፊት የሚከተሉትን ነጥቦች ይከልሱ፦', 'fr': 'Vérifiez les points suivants avant de terminer la tâche :', 'sw': 'Kagua vipengele vifuatavyo kabla ya kukamilisha kazi:',
    'ur': 'ٹاسک مکمل کرنے سے پہلے درج ذیل نکات کا جائزہ لیں:', 'tr': 'Görevi tamamlamadan önce aşağıdaki maddeleri gözden geçirin:', 'id': 'Tinjau poin-poin berikut sebelum menyelesaikan tugas:', 'bn': 'কাজটি সম্পন্ন করার আগে নিম্নলিখিত পয়েন্টগুলো পর্যালোচনা করুন:', 'ha': 'Duba waɗannan abubuwa kafin ka kammala aikin:',
    'so': 'Dib u eeg dhibcahan hoos ku qoran ka hor inta aadan hawsha dhammaystirin:', 'fa': 'پیش از تکمیل وظیفه، نکات زیر را بررسی کنید:', 'ms': 'Semak perkara berikut sebelum menyelesaikan tugasan:',
  },
  'mark_task_complete': {
    'ar': 'تم — إكمال المهمة', 'en': 'Done — Complete Task', 'am': 'ተጠናቅቋል — ተግባርን ጨርስ', 'fr': 'Terminé — Achever la tâche', 'sw': 'Imekamilika — Kamilisha Kazi',
    'ur': 'ہو گیا — ٹاسک مکمل کریں', 'tr': 'Tamam — Görevi Tamamla', 'id': 'Selesai — Selesaikan Tugas', 'bn': 'সম্পন্ন — কাজ সম্পন্ন করুন', 'ha': 'An Gama — Kammala Aiki',
    'so': 'Waa la Dhammeeyay — Dhammayso Hawsha', 'fa': 'انجام شد — تکمیل وظیفه', 'ms': 'Selesai — Lengkapkan Tugasan',
  },
  'checklist_points_suffix': {
    'ar': 'نقطة تحقق', 'en': 'checkpoints', 'am': 'የማረጋገጫ ነጥቦች', 'fr': 'points de vérification', 'sw': 'vipengele vya ukaguzi',
    'ur': 'چیک پوائنٹس', 'tr': 'kontrol maddesi', 'id': 'item periksa', 'bn': 'চেকপয়েন্ট', 'ha': 'wuraren dubawa',
    'so': 'dhibco hubin', 'fa': 'مورد بررسی', 'ms': 'item semakan',
  },
  'activities_title_word': {
    'ar': 'أنشطة', 'en': 'Activities', 'am': 'እንቅስቃሴዎች', 'fr': 'Activités', 'sw': 'Shughuli',
    'ur': 'سرگرمیاں', 'tr': 'Etkinlikler', 'id': 'Aktivitas', 'bn': 'কার্যক্রম', 'ha': 'Ayyuka',
    'so': 'Hawlaha', 'fa': 'فعالیت‌ها', 'ms': 'Aktiviti',
  },
  // 2026-08-22: notification_settings_screen.dart — adhkar/prayer/quiet-hours
  // settings, found still 100% hardcoded Arabic during the sweep.
  'notif_cat_morning_title': {
    'ar': 'أذكار الصباح', 'en': 'Morning Adhkar', 'am': 'የጠዋት አዝካር', 'fr': 'Adhkar du matin', 'sw': 'Adhkar za Asubuhi',
    'ur': 'صبح کے اذکار', 'tr': 'Sabah Ezkârı', 'id': 'Dzikir Pagi', 'bn': 'সকালের আজকার', 'ha': 'Azkarin Safiya',
    'so': 'Adkaarka Aroorka', 'fa': 'اذکار صبح', 'ms': 'Zikir Pagi',
  },
  'notif_cat_morning_hint': {
    'ar': 'الافتراضي: وقت الفجر الفعلي', 'en': 'Default: actual Fajr time', 'am': 'ነባሪ፦ ትክክለኛው የፈጅር ሰዓት', 'fr': 'Par défaut : heure réelle de Fajr', 'sw': 'Chaguo-msingi: wakati halisi wa Fajr',
    'ur': 'ڈیفالٹ: فجر کا اصل وقت', 'tr': 'Varsayılan: gerçek Fecir vakti', 'id': 'Default: waktu Subuh sebenarnya', 'bn': 'ডিফল্ট: প্রকৃত ফজরের সময়', 'ha': 'Tsoho: ainihin lokacin Asuba',
    'so': 'Caadiga: waqtiga dhabta ah ee Subax', 'fa': 'پیش‌فرض: زمان واقعی فجر', 'ms': 'Lalai: waktu Subuh sebenar',
  },
  'notif_cat_evening_title': {
    'ar': 'أذكار المساء', 'en': 'Evening Adhkar', 'am': 'የማታ አዝካር', 'fr': 'Adhkar du soir', 'sw': 'Adhkar za Jioni',
    'ur': 'شام کے اذکار', 'tr': 'Akşam Ezkârı', 'id': 'Dzikir Petang', 'bn': 'সন্ধ্যার আজকার', 'ha': 'Azkarin Yamma',
    'so': 'Adkaarka Galabnimo', 'fa': 'اذکار عصر', 'ms': 'Zikir Petang',
  },
  'notif_cat_evening_hint': {
    'ar': 'الافتراضي: وقت العصر الفعلي', 'en': 'Default: actual Asr time', 'am': 'ነባሪ፦ ትክክለኛው የዐስር ሰዓት', 'fr': "Par défaut : heure réelle d'Asr", 'sw': 'Chaguo-msingi: wakati halisi wa Asr',
    'ur': 'ڈیفالٹ: عصر کا اصل وقت', 'tr': 'Varsayılan: gerçek İkindi vakti', 'id': 'Default: waktu Asar sebenarnya', 'bn': 'ডিফল্ট: প্রকৃত আসরের সময়', 'ha': 'Tsoho: ainihin lokacin La\'asar',
    'so': 'Caadiga: waqtiga dhabta ah ee Casar', 'fa': 'پیش‌فرض: زمان واقعی عصر', 'ms': 'Lalai: waktu Asar sebenar',
  },
  'notif_cat_sleep_title': {
    'ar': 'أذكار النوم', 'en': 'Sleep Adhkar', 'am': 'የመኝታ አዝካር', 'fr': 'Adhkar du coucher', 'sw': 'Adhkar za Kulala',
    'ur': 'سونے کے اذکار', 'tr': 'Uyku Ezkârı', 'id': 'Dzikir Sebelum Tidur', 'bn': 'ঘুমের আজকার', 'ha': 'Azkarin Barci',
    'so': 'Adkaarka Hurdada', 'fa': 'اذکار خواب', 'ms': 'Zikir Sebelum Tidur',
  },
  'notif_cat_sleep_hint': {
    'ar': 'الافتراضي: وقت العشاء الفعلي', 'en': 'Default: actual Isha time', 'am': 'ነባሪ፦ ትክክለኛው የዒሻ ሰዓት', 'fr': "Par défaut : heure réelle d'Isha", 'sw': 'Chaguo-msingi: wakati halisi wa Isha',
    'ur': 'ڈیفالٹ: عشاء کا اصل وقت', 'tr': 'Varsayılan: gerçek Yatsı vakti', 'id': 'Default: waktu Isya sebenarnya', 'bn': 'ডিফল্ট: প্রকৃত এশার সময়', 'ha': 'Tsoho: ainihin lokacin Isha\'i',
    'so': 'Caadiga: waqtiga dhabta ah ee Cishaha', 'fa': 'پیش‌فرض: زمان واقعی عشاء', 'ms': 'Lalai: waktu Isyak sebenar',
  },
  'dhikr_generic_fallback': {
    'ar': 'ذكر', 'en': 'Dhikr', 'am': 'ዚክር', 'fr': 'Dhikr', 'sw': 'Dhikr',
    'ur': 'ذکر', 'tr': 'Zikir', 'id': 'Dzikir', 'bn': 'জিকির', 'ha': 'Zikiri',
    'so': 'Dhikr', 'fa': 'ذکر', 'ms': 'Zikir',
  },
  'choose_dhikr_title': {
    'ar': 'اختر الذكر', 'en': 'Choose the Dhikr', 'am': 'ዚክር ይምረጡ', 'fr': 'Choisissez le dhikr', 'sw': 'Chagua Dhikr',
    'ur': 'ذکر منتخب کریں', 'tr': 'Zikri Seçin', 'id': 'Pilih Dzikir', 'bn': 'জিকির নির্বাচন করুন', 'ha': 'Zaɓi Zikiri',
    'so': 'Dooro Dhikrka', 'fa': 'ذکر را انتخاب کنید', 'ms': 'Pilih Zikir',
  },
  'notifications_title': {
    'ar': 'الإشعارات', 'en': 'Notifications', 'am': 'ማሳወቂያዎች', 'fr': 'Notifications', 'sw': 'Arifa',
    'ur': 'اطلاعات', 'tr': 'Bildirimler', 'id': 'Notifikasi', 'bn': 'বিজ্ঞপ্তি', 'ha': 'Sanarwa',
    'so': 'Ogeysiisyada', 'fa': 'اعلان‌ها', 'ms': 'Notifikasi',
  },
  'notification_diagnostics_tooltip': {
    'ar': 'تشخيص الإشعارات', 'en': 'Notification Diagnostics', 'am': 'የማሳወቂያ ምርመራ', 'fr': 'Diagnostic des notifications', 'sw': 'Uchunguzi wa Arifa',
    'ur': 'اطلاعات کی تشخیص', 'tr': 'Bildirim Tanılama', 'id': 'Diagnostik Notifikasi', 'bn': 'বিজ্ঞপ্তি নির্ণয়', 'ha': 'Binciken Sanarwa',
    'so': 'Baaritaanka Ogeysiisyada', 'fa': 'عیب‌یابی اعلان‌ها', 'ms': 'Diagnostik Notifikasi',
  },
  'prayer_notification_title': {
    'ar': 'تنبيه أوقات الصلاة', 'en': 'Prayer Time Alerts', 'am': 'የጸሎት ሰዓት ማንቂያ', 'fr': 'Alertes des heures de prière', 'sw': 'Arifa za Nyakati za Sala',
    'ur': 'نماز کے اوقات کی الرٹ', 'tr': 'Namaz Vakti Uyarısı', 'id': 'Peringatan Waktu Salat', 'bn': 'নামাজের সময়ের সতর্কতা', 'ha': 'Faɗakarwar Lokutan Sallah',
    'so': 'Digniinta Waqtiyada Salaadda', 'fa': 'هشدار اوقات نماز', 'ms': 'Amaran Waktu Solat',
  },
  'prayer_notification_subtitle': {
    'ar': 'الأوقات الخمسة، محسوبة من موقعك الفعلي', 'en': 'All five times, calculated from your actual location', 'am': 'ሁሉም አምስት ሰዓቶች፣ ከትክክለኛ አካባቢዎ የተሰሉ', 'fr': 'Les cinq heures, calculées à partir de votre position réelle', 'sw': 'Nyakati zote tano, zilizohesabiwa kutoka eneo lako halisi',
    'ur': 'تمام پانچ اوقات، آپ کے اصل مقام سے حساب شدہ', 'tr': 'Beş vaktin tümü, gerçek konumunuzdan hesaplanır', 'id': 'Kelima waktu, dihitung dari lokasi Anda yang sebenarnya', 'bn': 'পাঁচটি সময়ই আপনার প্রকৃত অবস্থান থেকে হিসাব করা', 'ha': 'Dukkan lokuta biyar, an ƙididdige su daga ainihin wurin da kake',
    'so': 'Shantaba waqtiyada, waxaa lagu xisaabiyay meesha aad dhab ahaan joogto', 'fa': 'هر پنج وقت، بر اساس موقعیت واقعی شما محاسبه شده', 'ms': 'Kelima-lima waktu, dikira daripada lokasi sebenar anda',
  },
  'adhan_sound_title': {
    'ar': 'صوت الأذان', 'en': 'Adhan Sound', 'am': 'የአዛን ድምፅ', 'fr': "Son de l'adhan", 'sw': 'Sauti ya Adhana',
    'ur': 'اذان کی آواز', 'tr': 'Ezan Sesi', 'id': 'Suara Adzan', 'bn': 'আজানের শব্দ', 'ha': 'Sautin Kiran Salla',
    'so': 'Codka Azaanka', 'fa': 'صدای اذان', 'ms': 'Bunyi Azan',
  },
  'adhan_sound_subtitle': {
    'ar': 'تسجيل أذان حر الحقوق (CC0)، يعمل بلا اتصال إنترنت', 'en': 'A royalty-free (CC0) adhan recording, works fully offline', 'am': 'ነፃ የቅጂ መብት (CC0) የአዛን ቅጂ፣ ያለ ኢንተርኔት ይሰራል', 'fr': "Un enregistrement d'adhan libre de droits (CC0), fonctionne hors ligne", 'sw': 'Rekodi ya adhana isiyo na hakimiliki (CC0), inafanya kazi bila mtandao',
    'ur': 'رائلٹی فری (CC0) اذان ریکارڈنگ، بغیر انٹرنیٹ کے کام کرتی ہے', 'tr': 'Telifsiz (CC0) ezan kaydı, tamamen çevrimdışı çalışır', 'id': 'Rekaman adzan bebas royalti (CC0), berfungsi sepenuhnya offline', 'bn': 'রয়্যালটি-মুক্ত (CC0) আজান রেকর্ডিং, সম্পূর্ণ অফলাইনে কাজ করে', 'ha': 'Rikodin kiran salla marar biyan haƙƙi (CC0), yana aiki gaba ɗaya ba tare da intanet ba',
    'so': 'Duuban azaan xor u ah xuquuqda (CC0), wuxuu si buuxda u shaqeeyaa isaga oo aan lahayn internet', 'fa': 'ضبط اذان بدون حق امتیاز (CC0)، به‌طور کامل آفلاین کار می‌کند', 'ms': 'Rakaman azan bebas royalti (CC0), berfungsi sepenuhnya luar talian',
  },
  'stop_action': {
    'ar': 'إيقاف', 'en': 'Stop', 'am': 'አቁም', 'fr': 'Arrêter', 'sw': 'Simamisha',
    'ur': 'روکیں', 'tr': 'Durdur', 'id': 'Hentikan', 'bn': 'বন্ধ করুন', 'ha': 'Tsaya',
    'so': 'Jooji', 'fa': 'توقف', 'ms': 'Berhenti',
  },
  'test_adhan_sound_action': {
    'ar': 'تجربة صوت الأذان', 'en': 'Preview Adhan Sound', 'am': 'የአዛን ድምፅ ይሞክሩ', 'fr': "Aperçu du son de l'adhan", 'sw': 'Jaribu Sauti ya Adhana',
    'ur': 'اذان کی آواز آزمائیں', 'tr': 'Ezan Sesini Dinle', 'id': 'Pratinjau Suara Adzan', 'bn': 'আজানের শব্দ শুনুন', 'ha': 'Gwada Sautin Kiran Salla',
    'so': 'Tijaabi Codka Azaanka', 'fa': 'پیش‌نمایش صدای اذان', 'ms': 'Pratonton Bunyi Azan',
  },
  'quiet_hours_title': {
    'ar': 'ساعات الهدوء', 'en': 'Quiet Hours', 'am': 'የፀጥታ ሰዓቶች', 'fr': 'Heures silencieuses', 'sw': 'Saa za Kimya',
    'ur': 'خاموشی کے اوقات', 'tr': 'Sessiz Saatler', 'id': 'Jam Tenang', 'bn': 'নীরব সময়', 'ha': 'Sa\'o\'in Shiru',
    'so': 'Saacadaha Aamusnaanta', 'fa': 'ساعات سکوت', 'ms': 'Waktu Senyap',
  },
  'quiet_hours_subtitle': {
    'ar': 'لا يُجدوَل أي تذكير قابل للتحريك داخل هذه الفترة', 'en': 'No movable reminder will be scheduled within this window', 'am': 'ሊንቀሳቀስ የሚችል ማንኛውም ማስታወሻ በዚህ ጊዜ ውስጥ አይታቀድም', 'fr': 'Aucun rappel déplaçable ne sera programmé pendant cette période', 'sw': 'Hakuna ukumbusho unaoweza kuhamishwa utakaopangwa ndani ya kipindi hiki',
    'ur': 'اس مدت کے دوران کوئی بھی قابلِ منتقلی یاد دہانی شیڈول نہیں کی جائے گی', 'tr': 'Bu süre içinde taşınabilir bir hatırlatma zamanlanmaz', 'id': 'Tidak ada pengingat yang dapat dipindahkan akan dijadwalkan dalam periode ini', 'bn': 'এই সময়ের মধ্যে কোনো স্থানান্তরযোগ্য অনুস্মারক নির্ধারণ করা হবে না', 'ha': 'Babu wata tunatarwa mai iya matsawa da za a tsara a cikin wannan lokacin',
    'so': 'Wax xasuusin la dhaqaajin karo lama jadwali doono muddadan gudaheeda', 'fa': 'در این بازه زمانی هیچ یادآوری قابل‌جابجایی برنامه‌ریزی نخواهد شد', 'ms': 'Tiada peringatan boleh alih akan dijadualkan dalam tempoh ini',
  },
  'from_hour_prefix': {
    'ar': 'من الساعة', 'en': 'From', 'am': 'ከሰዓት', 'fr': 'De', 'sw': 'Kutoka saa',
    'ur': 'سے', 'tr': "Saat", 'id': 'Dari pukul', 'bn': 'থেকে', 'ha': 'Daga karfe',
    'so': 'Laga bilaabo saacadda', 'fa': 'از ساعت', 'ms': 'Dari pukul',
  },
  'to_hour_prefix': {
    'ar': 'إلى', 'en': 'to', 'am': 'እስከ', 'fr': 'à', 'sw': 'hadi saa',
    'ur': 'تک', 'tr': "-", 'id': 'sampai pukul', 'bn': 'পর্যন্ত', 'ha': 'zuwa karfe',
    'so': 'ilaa saacadda', 'fa': 'تا ساعت', 'ms': 'hingga pukul',
  },
  'adhkar_notifications_section_title': {
    'ar': 'إشعارات الأذكار', 'en': 'Adhkar Notifications', 'am': 'የአዝካር ማሳወቂያዎች', 'fr': 'Notifications des adhkar', 'sw': 'Arifa za Adhkar',
    'ur': 'اذکار کی اطلاعات', 'tr': 'Ezkâr Bildirimleri', 'id': 'Notifikasi Dzikir', 'bn': 'আজকার বিজ্ঞপ্তি', 'ha': 'Sanarwar Azkari',
    'so': 'Ogeysiisyada Adkaarka', 'fa': 'اعلان‌های اذکار', 'ms': 'Notifikasi Zikir',
  },
  'auto_label': {
    'ar': 'تلقائي', 'en': 'Automatic', 'am': 'ራስ-ሰር', 'fr': 'Automatique', 'sw': 'Kiotomatiki',
    'ur': 'خودکار', 'tr': 'Otomatik', 'id': 'Otomatis', 'bn': 'স্বয়ংক্রিয়', 'ha': 'Atomatik',
    'so': 'Toos ah', 'fa': 'خودکار', 'ms': 'Automatik',
  },
  'set_time_manually_label': {
    'ar': 'تحديد وقت يدويًا', 'en': 'Set Time Manually', 'am': 'ሰዓት በእጅ ያዘጋጁ', 'fr': 'Définir l\'heure manuellement', 'sw': 'Weka Muda Mwenyewe',
    'ur': 'دستی طور پر وقت مقرر کریں', 'tr': 'Manuel Saat Belirle', 'id': 'Atur Waktu Manual', 'bn': 'নিজে সময় নির্ধারণ করুন', 'ha': 'Saita Lokaci da Hannu',
    'so': 'Gacanta ku qeex Waqtiga', 'fa': 'تنظیم دستی زمان', 'ms': 'Tetapkan Masa Secara Manual',
  },
  'hour_at_label': {
    'ar': 'الساعة', 'en': 'At', 'am': 'በሰዓት', 'fr': 'À', 'sw': 'Saa',
    'ur': 'وقت', 'tr': 'Saat', 'id': 'Pukul', 'bn': 'সময়', 'ha': 'Da karfe',
    'so': 'Saacadda', 'fa': 'ساعت', 'ms': 'Pukul',
  },
  'custom_time_label': {
    'ar': 'وقت مخصّص', 'en': 'Custom Time', 'am': 'ብጁ ሰዓት', 'fr': 'Heure personnalisée', 'sw': 'Muda Maalum',
    'ur': 'اپنی مرضی کا وقت', 'tr': 'Özel Saat', 'id': 'Waktu Khusus', 'bn': 'কাস্টম সময়', 'ha': 'Lokaci na Musamman',
    'so': 'Waqti Gaar ah', 'fa': 'زمان سفارشی', 'ms': 'Masa Tersuai',
  },
  'custom_adhkar_section_title': {
    'ar': 'أذكار مخصّصة', 'en': 'Custom Adhkar', 'am': 'ብጁ አዝካር', 'fr': 'Adhkar personnalisés', 'sw': 'Adhkar Maalum',
    'ur': 'حسبِ ضرورت اذکار', 'tr': 'Özel Ezkâr', 'id': 'Dzikir Kustom', 'bn': 'কাস্টম আজকার', 'ha': 'Azkari na Musamman',
    'so': 'Adkaar Gaar ah', 'fa': 'اذکار سفارشی', 'ms': 'Zikir Tersuai',
  },
  'custom_adhkar_section_subtitle': {
    'ar': 'أضف تذكيرًا لأي ذكر آخر تختاره بنفسك', 'en': 'Add a reminder for any other dhikr you choose yourself', 'am': 'እርስዎ ራስዎ ለሚመርጡት ማንኛውም ሌላ ዚክር ማስታወሻ ይጨምሩ', 'fr': 'Ajoutez un rappel pour tout autre dhikr de votre choix', 'sw': 'Ongeza ukumbusho kwa dhikr nyingine yoyote unayochagua mwenyewe',
    'ur': 'اپنی پسند کے کسی بھی دوسرے ذکر کے لیے یاد دہانی شامل کریں', 'tr': 'Kendinizin seçtiği başka herhangi bir zikir için hatırlatma ekleyin', 'id': 'Tambahkan pengingat untuk dzikir lain pilihan Anda sendiri', 'bn': 'আপনার পছন্দমতো অন্য যেকোনো জিকিরের জন্য একটি অনুস্মারক যোগ করুন', 'ha': 'Ƙara tunatarwa don duk wani zikiri da kai da kanka ka zaɓa',
    'so': 'Ku dar xasuusin dhikr kasta oo kale oo aad adigu doorato', 'fa': 'برای هر ذکر دیگری که خودتان انتخاب می‌کنید یادآوری اضافه کنید', 'ms': 'Tambah peringatan untuk mana-mana zikir lain pilihan anda sendiri',
  },
  'add_dhikr_reminder_action': {
    'ar': 'أضف ذكرًا', 'en': 'Add a Dhikr', 'am': 'ዚክር ጨምር', 'fr': 'Ajouter un dhikr', 'sw': 'Ongeza Dhikr',
    'ur': 'ذکر شامل کریں', 'tr': 'Zikir Ekle', 'id': 'Tambah Dzikir', 'bn': 'জিকির যোগ করুন', 'ha': 'Ƙara Zikiri',
    'so': 'Ku dar Dhikr', 'fa': 'افزودن ذکر', 'ms': 'Tambah Zikir',
  },
  // 2026-08-22: notification_diagnostics_screen.dart — the self-check
  // screen behind the diagnostics tooltip above.
  'notification_diagnostics_title': {
    'ar': 'تشخيص الإشعارات', 'en': 'Notification Diagnostics', 'am': 'የማሳወቂያ ምርመራ', 'fr': 'Diagnostic des notifications', 'sw': 'Uchunguzi wa Arifa',
    'ur': 'اطلاعات کی تشخیص', 'tr': 'Bildirim Tanılama', 'id': 'Diagnostik Notifikasi', 'bn': 'বিজ্ঞপ্তি নির্ণয়', 'ha': 'Binciken Sanarwa',
    'so': 'Baaritaanka Ogeysiisyada', 'fa': 'عیب‌یابی اعلان‌ها', 'ms': 'Diagnostik Notifikasi',
  },
  'notification_permission_title': {
    'ar': 'إذن الإشعارات', 'en': 'Notification Permission', 'am': 'የማሳወቂያ ፈቃድ', 'fr': 'Autorisation de notifications', 'sw': 'Ruhusa ya Arifa',
    'ur': 'اطلاعات کی اجازت', 'tr': 'Bildirim İzni', 'id': 'Izin Notifikasi', 'bn': 'বিজ্ঞপ্তির অনুমতি', 'ha': 'Izinin Sanarwa',
    'so': 'Idanka Ogeysiisyada', 'fa': 'مجوز اعلان‌ها', 'ms': 'Kebenaran Notifikasi',
  },
  'permission_granted_label': {
    'ar': 'ممنوح', 'en': 'Granted', 'am': 'ተፈቅዷል', 'fr': 'Accordée', 'sw': 'Imeruhusiwa',
    'ur': 'دی گئی', 'tr': 'Verildi', 'id': 'Diberikan', 'bn': 'অনুমোদিত', 'ha': 'An Bayar',
    'so': 'La Ogolaaday', 'fa': 'داده شده', 'ms': 'Diberikan',
  },
  'notification_permission_denied_text': {
    'ar': 'غير ممنوح — لن تصل أي إشعارات حتى تُفعّله من إعدادات النظام', 'en': "Not granted — you won't receive any notifications until you enable it in system settings", 'am': 'አልተፈቀደም — ከስርዓት ቅንብሮች እስኪያነቁት ድረስ ምንም ማሳወቂያ አይደርስዎትም', 'fr': "Non accordée — vous ne recevrez aucune notification tant que vous ne l'activez pas dans les paramètres système", 'sw': 'Haijaruhusiwa — hutapokea arifa yoyote hadi uiwashe kwenye mipangilio ya mfumo',
    'ur': 'دی نہیں گئی — سسٹم سیٹنگز سے فعال کیے بغیر آپ کو کوئی اطلاع نہیں ملے گی', 'tr': 'Verilmedi — sistem ayarlarından etkinleştirmedikçe hiçbir bildirim almazsınız', 'id': 'Tidak diberikan — Anda tidak akan menerima notifikasi apa pun hingga mengaktifkannya di pengaturan sistem', 'bn': 'অনুমোদিত নয় — সিস্টেম সেটিংস থেকে সক্রিয় না করা পর্যন্ত আপনি কোনো বিজ্ঞপ্তি পাবেন না', 'ha': 'Ba a bayar ba — ba za ka sami wata sanarwa ba sai ka kunna ta daga saitunan tsarin',
    'so': 'Lama ogolaan — ma heli doontid ogeysiis illaa aad ka daaraysid dejinta nidaamka', 'fa': 'اعطا نشده — تا زمانی که آن را از تنظیمات سیستم فعال نکنید هیچ اعلانی دریافت نخواهید کرد', 'ms': 'Tidak diberikan — anda tidak akan menerima sebarang notifikasi sehingga anda mendayakannya dalam tetapan sistem',
  },
  'exact_alarm_scheduling_title': {
    'ar': 'الجدولة الدقيقة (لتنبيه الصلاة)', 'en': 'Exact Scheduling (for prayer alerts)', 'am': 'ትክክለኛ መርሐግብር (ለጸሎት ማንቂያ)', 'fr': 'Planification précise (pour les alertes de prière)', 'sw': 'Upangaji Sahihi (kwa arifa za sala)',
    'ur': 'درست شیڈولنگ (نماز کی الرٹ کے لیے)', 'tr': 'Kesin Zamanlama (namaz uyarıları için)', 'id': 'Penjadwalan Tepat (untuk peringatan salat)', 'bn': 'নির্ভুল সময়সূচি (নামাজের সতর্কতার জন্য)', 'ha': 'Tsara Ainihin Lokaci (don faɗakarwar sallah)',
    'so': 'Jadwalka Saxda ah (digniinta salaadda)', 'fa': 'زمان‌بندی دقیق (برای هشدار نماز)', 'ms': 'Penjadualan Tepat (untuk amaran solat)',
  },
  'exact_alarm_granted_text': {
    'ar': 'ممنوحة — تنبيه الصلاة يصل في وقته بدقة', 'en': 'Granted — prayer alerts arrive exactly on time', 'am': 'ተፈቅዷል — የጸሎት ማንቂያ በትክክለኛው ሰዓት ይደርሳል', 'fr': "Accordée — les alertes de prière arrivent exactement à l'heure", 'sw': 'Imeruhusiwa — arifa za sala zinafika kwa wakati kamili',
    'ur': 'دی گئی — نماز کی الرٹ عین وقت پر پہنچتی ہے', 'tr': 'Verildi — namaz uyarıları tam zamanında gelir', 'id': 'Diberikan — peringatan salat tiba tepat waktu', 'bn': 'অনুমোদিত — নামাজের সতর্কতা সঠিক সময়ে পৌঁছায়', 'ha': 'An Bayar — faɗakarwar sallah tana isowa daidai lokaci',
    'so': 'La Ogolaaday — digniinta salaadda waxay timaadaa waqtigeeda saxda ah', 'fa': 'داده شده — هشدار نماز دقیقاً به‌موقع می‌رسد', 'ms': 'Diberikan — amaran solat tiba tepat pada masanya',
  },
  'exact_alarm_denied_text': {
    'ar': 'غير ممنوحة — تنبيه الصلاة قد يتأخر بضع دقائق بسبب توفير البطارية', 'en': 'Not granted — prayer alerts may be delayed a few minutes due to battery optimization', 'am': 'አልተፈቀደም — በባትሪ ቁጠባ ምክንያት የጸሎት ማንቂያ ጥቂት ደቂቃዎች ሊዘገይ ይችላል', 'fr': "Non accordée — les alertes de prière peuvent être retardées de quelques minutes en raison de l'économie de batterie", 'sw': 'Haijaruhusiwa — arifa za sala zinaweza kuchelewa dakika chache kwa sababu ya kuhifadhi betri',
    'ur': 'دی نہیں گئی — بیٹری کی بچت کی وجہ سے نماز کی الرٹ چند منٹ تاخیر کا شکار ہو سکتی ہے', 'tr': 'Verilmedi — pil tasarrufu nedeniyle namaz uyarıları birkaç dakika gecikebilir', 'id': 'Tidak diberikan — peringatan salat mungkin tertunda beberapa menit karena optimisasi baterai', 'bn': 'অনুমোদিত নয় — ব্যাটারি সাশ্রয়ের কারণে নামাজের সতর্কতা কয়েক মিনিট বিলম্বিত হতে পারে', 'ha': "Ba a bayar ba — faɗakarwar sallah na iya jinkirta 'yan mintuna saboda tattalin baturi",
    'so': 'Lama ogolaan — digniinta salaadda waxay dib u dhici kartaa dhowr daqiiqo sababtoo ah keydinta batteriga', 'fa': 'داده نشده — هشدار نماز ممکن است به دلیل بهینه‌سازی باتری چند دقیقه به تأخیر بیفتد', 'ms': 'Tidak diberikan — amaran solat mungkin lewat beberapa minit disebabkan pengoptimuman bateri',
  },
  'location_label': {
    'ar': 'الموقع', 'en': 'Location', 'am': 'አካባቢ', 'fr': 'Emplacement', 'sw': 'Mahali',
    'ur': 'مقام', 'tr': 'Konum', 'id': 'Lokasi', 'bn': 'অবস্থান', 'ha': 'Wuri',
    'so': 'Goobta', 'fa': 'موقعیت', 'ms': 'Lokasi',
  },
  'no_location_available_text': {
    'ar': 'لا يوجد موقع متاح — تُحسب أوقات الصلاة والأذكار بالساعات الافتراضية الثابتة', 'en': 'No location available — prayer and adhkar times are calculated using fixed default hours', 'am': 'ምንም አካባቢ የለም — የጸሎት እና የአዝካር ሰዓቶች በቋሚ ነባሪ ሰዓቶች ይሰላሉ', 'fr': "Aucun emplacement disponible — les heures de prière et d'adhkar sont calculées avec des heures par défaut fixes", 'sw': 'Hakuna mahali panapopatikana — nyakati za sala na adhkar zinahesabiwa kwa saa chaguo-msingi zisizobadilika',
    'ur': 'کوئی مقام دستیاب نہیں — نماز اور اذکار کے اوقات مقررہ ڈیفالٹ اوقات سے شمار کیے جاتے ہیں', 'tr': 'Konum yok — namaz ve ezkâr vakitleri sabit varsayılan saatlerle hesaplanır', 'id': 'Tidak ada lokasi yang tersedia — waktu salat dan dzikir dihitung menggunakan jam default tetap', 'bn': 'কোনো অবস্থান উপলব্ধ নেই — নামাজ ও আজকারের সময় নির্ধারিত ডিফল্ট ঘণ্টা দিয়ে হিসাব করা হয়', 'ha': "Babu wurin da ake da shi — ana ƙididdige lokutan sallah da azkari da tsayayyun sa'o'in tsoho",
    'so': 'Goob lama helin — waqtiyada salaadda iyo adkaarka waxaa lagu xisaabiyaa saacado caadi ah oo go\'an', 'fa': 'موقعیتی در دسترس نیست — زمان‌های نماز و اذکار با ساعات پیش‌فرض ثابت محاسبه می‌شوند', 'ms': 'Tiada lokasi tersedia — waktu solat dan zikir dikira menggunakan waktu lalai tetap',
  },
  'manual_location_text': {
    'ar': 'موقع مُدخَل يدويًا', 'en': 'Manually entered location', 'am': 'በእጅ የገባ አካባቢ', 'fr': 'Emplacement saisi manuellement', 'sw': 'Mahali palipowekwa mwenyewe',
    'ur': 'دستی طور پر درج کردہ مقام', 'tr': 'Manuel girilen konum', 'id': 'Lokasi yang dimasukkan secara manual', 'bn': 'ম্যানুয়ালি প্রবেশ করানো অবস্থান', 'ha': 'Wurin da aka shigar da hannu',
    'so': 'Goob gacanta lagu galiyay', 'fa': 'موقعیت وارد شده به‌صورت دستی', 'ms': 'Lokasi dimasukkan secara manual',
  },
  'real_gps_location_text': {
    'ar': 'موقع GPS حقيقي', 'en': 'Real GPS location', 'am': 'እውነተኛ የGPS አካባቢ', 'fr': 'Emplacement GPS réel', 'sw': 'Mahali halisi pa GPS',
    'ur': 'اصل جی پی ایس مقام', 'tr': 'Gerçek GPS konumu', 'id': 'Lokasi GPS asli', 'bn': 'প্রকৃত জিপিএস অবস্থান', 'ha': 'Ainihin Wurin GPS',
    'so': 'Goobta GPS-ka Dhabta ah', 'fa': 'موقعیت واقعی GPS', 'ms': 'Lokasi GPS sebenar',
  },
  'accuracy_meters_suffix': {
    'ar': 'دقة ~', 'en': 'accuracy ~', 'am': 'ትክክለኛነት ~', 'fr': 'précision ~', 'sw': 'usahihi ~',
    'ur': 'درستگی ~', 'tr': 'doğruluk ~', 'id': 'akurasi ~', 'bn': 'নির্ভুলতা ~', 'ha': 'daidaito ~',
    'so': 'saxnaanta ~', 'fa': 'دقت ~', 'ms': 'ketepatan ~',
  },
  'meters_unit_short': {
    'ar': 'م', 'en': 'm', 'am': 'ሜ', 'fr': 'm', 'sw': 'm',
    'ur': 'میٹر', 'tr': 'm', 'id': 'm', 'bn': 'মি', 'ha': 'm',
    'so': 'm', 'fa': 'متر', 'ms': 'm',
  },
  'from_cache_text': {
    'ar': 'من ذاكرة التخزين المؤقت', 'en': 'from cache', 'am': 'ከመሸጎጫ', 'fr': 'depuis le cache', 'sw': 'kutoka kwenye hifadhi ya muda',
    'ur': 'کیشے سے', 'tr': 'önbellekten', 'id': 'dari cache', 'bn': 'ক্যাশ থেকে', 'ha': 'daga ma\'ajiya',
    'so': 'kaydka ku meel gaadhka ah', 'fa': 'از حافظه موقت', 'ms': 'daripada cache',
  },
  'scheduled_notifications_count_title': {
    'ar': 'الإشعارات المجدولة الآن', 'en': 'Currently Scheduled Notifications', 'am': 'አሁን የተያዙ ማሳወቂያዎች', 'fr': 'Notifications actuellement programmées', 'sw': 'Arifa Zilizopangwa Sasa',
    'ur': 'اس وقت شیڈول شدہ اطلاعات', 'tr': 'Şu Anda Zamanlanmış Bildirimler', 'id': 'Notifikasi yang Dijadwalkan Saat Ini', 'bn': 'বর্তমানে নির্ধারিত বিজ্ঞপ্তি', 'ha': 'Sanarwar da Aka Tsara Yanzu',
    'so': 'Ogeysiisyada Hadda Jadwalka Lagu Qabtay', 'fa': 'اعلان‌های زمان‌بندی‌شده کنونی', 'ms': 'Notifikasi Dijadualkan Sekarang',
  },
  'no_scheduled_notifications_text': {
    'ar': 'لا توجد إشعارات مجدولة حاليًا', 'en': 'No notifications are currently scheduled', 'am': 'በአሁኑ ጊዜ የተያዘ ማሳወቂያ የለም', 'fr': "Aucune notification n'est actuellement programmée", 'sw': 'Hakuna arifa zilizopangwa kwa sasa',
    'ur': 'اس وقت کوئی اطلاع شیڈول نہیں ہے', 'tr': 'Şu anda zamanlanmış bir bildirim yok', 'id': 'Tidak ada notifikasi yang dijadwalkan saat ini', 'bn': 'বর্তমানে কোনো বিজ্ঞপ্তি নির্ধারিত নেই', 'ha': 'Babu sanarwar da aka tsara a yanzu',
    'so': 'Hadda ma jiraan ogeysiisyo la jadwalay', 'fa': 'در حال حاضر هیچ اعلانی زمان‌بندی نشده است', 'ms': 'Tiada notifikasi dijadualkan pada masa ini',
  },
  // 2026-08-22: support_screen.dart — contact form + FAQ, reached from
  // Profile. The Telegram message text sent TO admins (Ismail's own
  // inbox) stays Arabic — that's an internal notification, not UI shown
  // to the student, so it's out of scope for this sweep.
  'support_title': {
    'ar': 'الدعم والأسئلة الشائعة', 'en': 'Support & FAQ', 'am': 'ድጋፍ እና ተደጋጋሚ ጥያቄዎች', 'fr': 'Assistance et FAQ', 'sw': 'Msaada na Maswali Yanayoulizwa Mara kwa Mara',
    'ur': 'مدد اور اکثر پوچھے گئے سوالات', 'tr': 'Destek ve SSS', 'id': 'Dukungan & FAQ', 'bn': 'সহায়তা ও প্রশ্নোত্তর', 'ha': 'Taimako da Tambayoyi',
    'so': 'Taageero iyo Su\'aalaha Badanaa La Isweydiiyo', 'fa': 'پشتیبانی و پرسش‌های متداول', 'ms': 'Sokongan & Soalan Lazim',
  },
  'support_intro_title': {
    'ar': 'هذا التطبيق وقفٌ لوجه الله تعالى', 'en': 'This app is a waqf, for the sake of Allah', 'am': 'ይህ መተግበሪያ ለአላህ ስም የተሰጠ ውቅፍ ነው', 'fr': "Cette application est un waqf, pour l'amour d'Allah", 'sw': 'Programu hii ni waqfu, kwa ajili ya Allah',
    'ur': 'یہ ایپ اللہ کی رضا کے لیے وقف ہے', 'tr': 'Bu uygulama Allah rızası için bir vakıftır', 'id': 'Aplikasi ini adalah wakaf, karena Allah semata', 'bn': 'এই অ্যাপটি আল্লাহর সন্তুষ্টির জন্য একটি ওয়াকফ', 'ha': 'Wannan manhajar wakafi ce, don Allah kaɗai',
    'so': 'Barnaamijkan waa waqaf, Ilaahay aawadiis', 'fa': 'این برنامه وقفی است، برای رضای خداوند', 'ms': 'Aplikasi ini adalah wakaf, kerana Allah semata-mata',
  },
  'support_intro_body': {
    'ar': 'أُعدّ بلا مقابل احتساباً للأجر. إن واجهتك مشكلة، أو لديك اقتراح لتطويره، أو أي استفسار، يسعدنا تواصلك — ستصل رسالتك مباشرة إلى المشرفين على التطبيق.',
    'en': "Built without charge, seeking reward from Allah alone. If you run into a problem, have a suggestion, or any question, we'd love to hear from you — your message goes directly to the app's maintainers.",
    'am': 'ያለ ምንም ክፍያ፣ ከአላህ ብቻ ምንዳን በመፈለግ የተዘጋጀ ነው። ችግር ካጋጠመዎት፣ ለማሻሻል ሐሳብ ካለዎት፣ ወይም ማንኛውም ጥያቄ ካለዎት፣ እንድንሰማ ደስ ይለናል — መልእክትዎ በቀጥታ ለመተግበሪያው አስተዳዳሪዎች ይደርሳል።',
    'fr': "Créée gratuitement, en recherchant uniquement la récompense d'Allah. Si vous rencontrez un problème, avez une suggestion, ou une question, nous serions ravis de vous entendre — votre message parvient directement aux responsables de l'application.",
    'sw': 'Imetengenezwa bila malipo, tukitafuta malipo kutoka kwa Allah pekee. Ukikutana na tatizo, una pendekezo, au swali lolote, tungependa kusikia kutoka kwako — ujumbe wako unafika moja kwa moja kwa wasimamizi wa programu.',
    'ur': 'یہ بلا معاوضہ، صرف اللہ سے اجر کی امید میں تیار کی گئی ہے۔ اگر آپ کو کوئی مسئلہ درپیش ہو، کوئی تجویز ہو، یا کوئی سوال ہو، تو ہمیں آپ سے سن کر خوشی ہوگی — آپ کا پیغام براہ راست ایپ کے منتظمین تک پہنچتا ہے۔',
    'tr': 'Yalnızca Allah rızası gözetilerek ücretsiz olarak hazırlanmıştır. Bir sorunla karşılaşırsanız, bir öneriniz varsa veya herhangi bir sorunuz olursa, sizden haber almaktan memnuniyet duyarız — mesajınız doğrudan uygulama yöneticilerine ulaşır.',
    'id': 'Dibuat tanpa biaya, semata mengharap pahala dari Allah. Jika Anda mengalami masalah, memiliki saran, atau pertanyaan apa pun, kami senang mendengar dari Anda — pesan Anda akan langsung sampai ke pengelola aplikasi.',
    'bn': 'বিনামূল্যে তৈরি, শুধুমাত্র আল্লাহর কাছে সওয়াবের আশায়। যদি আপনি কোনো সমস্যার সম্মুখীন হন, কোনো পরামর্শ থাকে, বা কোনো প্রশ্ন থাকে, আমরা আপনার কাছ থেকে শুনতে চাই — আপনার বার্তা সরাসরি অ্যাপের পরিচালকদের কাছে পৌঁছাবে।',
    'ha': 'An gina shi ba tare da biya ba, ana neman lada daga Allah kaɗai. Idan ka fuskanci matsala, kana da shawara, ko wata tambaya, muna son jin daga gare ka — saƙonka yana isa kai tsaye ga masu kula da manhajar.',
    'so': 'Waxaa la sameeyay iyada oo aan lacag lahayn, iyadoo laga doonayo ajir Ilaahay oo keliya. Haddii aad la kulanto dhibaato, aad haysato talo, ama su\'aal kasta, waxaan jeclaan lahayn inaan kaa maqalno — fariintaadu waxay si toos ah ugu gaari doontaa maamulayaasha app-ka.',
    'fa': 'بدون هیچ هزینه‌ای ساخته شده، تنها با امید پاداش از سوی خداوند. اگر با مشکلی مواجه شدید، پیشنهادی داشتید، یا سؤالی داشتید، خوشحال می‌شویم از شما بشنویم — پیام شما مستقیماً به مدیران برنامه می‌رسد.',
    'ms': 'Dibina tanpa bayaran, semata-mata mengharap ganjaran daripada Allah. Jika anda menghadapi masalah, mempunyai cadangan, atau sebarang soalan, kami ingin mendengar daripada anda — mesej anda akan terus sampai kepada penyelenggara aplikasi.',
  },
  'contact_us_header': {
    'ar': 'تواصل معنا', 'en': 'Contact Us', 'am': 'ያግኙን', 'fr': 'Contactez-nous', 'sw': 'Wasiliana Nasi',
    'ur': 'ہم سے رابطہ کریں', 'tr': 'Bize Ulaşın', 'id': 'Hubungi Kami', 'bn': 'আমাদের সাথে যোগাযোগ করুন', 'ha': 'Tuntube Mu',
    'so': 'Nala Soo Xiriir', 'fa': 'با ما تماس بگیرید', 'ms': 'Hubungi Kami',
  },
  'support_message_hint': {
    'ar': 'اكتب رسالتك هنا: مشكلة، اقتراح، أو أي استفسار...', 'en': 'Write your message here: a problem, a suggestion, or any question...', 'am': 'መልእክትዎን እዚህ ይጻፉ፦ ችግር፣ ሐሳብ፣ ወይም ማንኛውም ጥያቄ...', 'fr': 'Écrivez votre message ici : un problème, une suggestion, ou une question...', 'sw': 'Andika ujumbe wako hapa: tatizo, pendekezo, au swali lolote...',
    'ur': 'یہاں اپنا پیغام لکھیں: مسئلہ، تجویز، یا کوئی سوال...', 'tr': 'Mesajınızı buraya yazın: bir sorun, bir öneri veya herhangi bir soru...', 'id': 'Tulis pesan Anda di sini: masalah, saran, atau pertanyaan apa pun...', 'bn': 'আপনার বার্তা এখানে লিখুন: সমস্যা, পরামর্শ, বা কোনো প্রশ্ন...', 'ha': 'Rubuta saƙonka a nan: matsala, shawara, ko wata tambaya...',
    'so': 'Halkan ku qor fariintaada: dhibaato, talo, ama su\'aal kasta...', 'fa': 'پیام خود را اینجا بنویسید: مشکل، پیشنهاد، یا هر سؤالی...', 'ms': 'Tulis mesej anda di sini: masalah, cadangan, atau sebarang soalan...',
  },
  'send_action': {
    'ar': 'إرسال', 'en': 'Send', 'am': 'ላክ', 'fr': 'Envoyer', 'sw': 'Tuma',
    'ur': 'بھیجیں', 'tr': 'Gönder', 'id': 'Kirim', 'bn': 'পাঠান', 'ha': 'Aika',
    'so': 'Dir', 'fa': 'ارسال', 'ms': 'Hantar',
  },
  'sending_in_progress': {
    'ar': 'جارٍ الإرسال...', 'en': 'Sending...', 'am': 'እየላከ ነው...', 'fr': 'Envoi en cours...', 'sw': 'Inatuma...',
    'ur': 'بھیجا جا رہا ہے...', 'tr': 'Gönderiliyor...', 'id': 'Mengirim...', 'bn': 'পাঠানো হচ্ছে...', 'ha': 'Ana Aikawa...',
    'so': 'Waa la diraayaa...', 'fa': 'در حال ارسال...', 'ms': 'Menghantar...',
  },
  'support_send_success': {
    'ar': 'تم إرسال رسالتك، جزاك الله خيراً', 'en': 'Your message was sent, may Allah reward you well', 'am': 'መልእክትዎ ተልኳል፣ አላህ በደግነት ይክፈልዎ', 'fr': "Votre message a été envoyé, qu'Allah vous récompense", 'sw': 'Ujumbe wako umetumwa, Allah akulipe kheri',
    'ur': 'آپ کا پیغام بھیج دیا گیا، اللہ آپ کو بہترین جزا دے', 'tr': 'Mesajınız gönderildi, Allah sizi hayırla mükafatlandırsın', 'id': 'Pesan Anda telah terkirim, semoga Allah membalas Anda dengan kebaikan', 'bn': 'আপনার বার্তা পাঠানো হয়েছে, আল্লাহ আপনাকে উত্তম প্রতিদান দিন', 'ha': 'An aika saƙonka, Allah Ya saka maka da alkhairi',
    'so': 'Fariintaadii waa la diray, Ilaahay khayr ha kaa siiyo', 'fa': 'پیام شما ارسال شد، خداوند به شما پاداش نیک دهد', 'ms': 'Mesej anda telah dihantar, semoga Allah membalas kebaikan anda',
  },
  'support_send_failure': {
    'ar': 'تعذر الإرسال — تأكد من الاتصال بالإنترنت وحاول مرة أخرى', 'en': "Couldn't send — check your internet connection and try again", 'am': 'መላክ አልተቻለም — የኢንተርኔት ግንኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ', 'fr': "Échec de l'envoi — vérifiez votre connexion internet et réessayez", 'sw': 'Imeshindikana kutuma — hakikisha muunganisho wa mtandao na ujaribu tena',
    'ur': 'بھیجا نہیں جا سکا — اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں', 'tr': 'Gönderilemedi — internet bağlantınızı kontrol edip tekrar deneyin', 'id': 'Gagal mengirim — periksa koneksi internet Anda dan coba lagi', 'bn': 'পাঠানো যায়নি — আপনার ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন', 'ha': 'An kasa aikawa — duba haɗin intanet ɗinka ka sake gwadawa',
    'so': 'Lama dirin — hubi xiriirkaaga internetka oo mar kale isku day', 'fa': 'ارسال ناموفق بود — اتصال اینترنت خود را بررسی کرده و دوباره تلاش کنید', 'ms': 'Gagal menghantar — semak sambungan internet anda dan cuba lagi',
  },
  'faq_header': {
    'ar': 'الأسئلة الشائعة', 'en': 'Frequently Asked Questions', 'am': 'ተደጋጋሚ ጥያቄዎች', 'fr': 'Questions fréquentes', 'sw': 'Maswali Yanayoulizwa Mara kwa Mara',
    'ur': 'اکثر پوچھے گئے سوالات', 'tr': 'Sık Sorulan Sorular', 'id': 'Pertanyaan yang Sering Diajukan', 'bn': 'প্রায়শই জিজ্ঞাসিত প্রশ্ন', 'ha': 'Tambayoyin da Ake Yawan Yi',
    'so': 'Su\'aalaha Badanaa La Isweydiiyo', 'fa': 'پرسش‌های متداول', 'ms': 'Soalan Lazim',
  },
  'no_faq_yet_text': {
    'ar': 'لا توجد أسئلة شائعة بعد.', 'en': 'No FAQ entries yet.', 'am': 'እስካሁን ተደጋጋሚ ጥያቄዎች የሉም።', 'fr': "Aucune question fréquente pour l'instant.", 'sw': 'Bado hakuna maswali yanayoulizwa mara kwa mara.',
    'ur': 'ابھی تک کوئی عمومی سوال موجود نہیں۔', 'tr': 'Henüz sık sorulan soru yok.', 'id': 'Belum ada pertanyaan yang sering diajukan.', 'bn': 'এখনও কোনো প্রশ্নোত্তর নেই।', 'ha': 'Babu tambayoyin da ake yawan yi tukuna.',
    'so': 'Wali ma jiraan su\'aalo badanaa la isweydiiyo.', 'fa': 'هنوز پرسش متداولی وجود ندارد.', 'ms': 'Belum ada soalan lazim.',
  },
  // 2026-08-22: shared prayer-name keys — used by prayer_times_screen.dart,
  // salah_tracker_screen.dart, salah_assessment_screen.dart,
  // worship_coach_screen.dart, and daily_companion_card.dart, which each
  // hardcoded their own copy of these five/six names independently.
  'prayer_fajr': {
    'ar': 'الفجر', 'en': 'Fajr', 'am': 'ፈጅር', 'fr': 'Fajr', 'sw': 'Alfajiri',
    'ur': 'فجر', 'tr': 'İmsak', 'id': 'Subuh', 'bn': 'ফজর', 'ha': 'Asuba',
    'so': 'Subax', 'fa': 'فجر', 'ms': 'Subuh',
  },
  'prayer_sunrise': {
    'ar': 'الشروق', 'en': 'Sunrise', 'am': 'ፀሐይ መውጫ', 'fr': 'Lever du soleil', 'sw': 'Macheo',
    'ur': 'طلوعِ آفتاب', 'tr': 'Güneş Doğuşu', 'id': 'Terbit Matahari', 'bn': 'সূর্যোদয়', 'ha': 'Fitowar Rana',
    'so': 'Qorrax Ka Soo Baxa', 'fa': 'طلوع آفتاب', 'ms': 'Matahari Terbit',
  },
  'prayer_dhuhr': {
    'ar': 'الظهر', 'en': 'Dhuhr', 'am': 'ዙህር', 'fr': 'Dhuhr', 'sw': 'Adhuhuri',
    'ur': 'ظہر', 'tr': 'Öğle', 'id': 'Zuhur', 'bn': 'জোহর', 'ha': 'Azahar',
    'so': 'Duhur', 'fa': 'ظهر', 'ms': 'Zohor',
  },
  'prayer_asr': {
    'ar': 'العصر', 'en': 'Asr', 'am': 'ዐስር', 'fr': 'Asr', 'sw': 'Alasiri',
    'ur': 'عصر', 'tr': 'İkindi', 'id': 'Asar', 'bn': 'আসর', 'ha': "La'asar",
    'so': 'Casar', 'fa': 'عصر', 'ms': 'Asar',
  },
  'prayer_maghrib': {
    'ar': 'المغرب', 'en': 'Maghrib', 'am': 'መግሪብ', 'fr': 'Maghrib', 'sw': 'Magharibi',
    'ur': 'مغرب', 'tr': 'Akşam', 'id': 'Maghrib', 'bn': 'মাগরিব', 'ha': 'Magariba',
    'so': 'Maghrib', 'fa': 'مغرب', 'ms': 'Maghrib',
  },
  'prayer_isha': {
    'ar': 'العشاء', 'en': 'Isha', 'am': 'ዒሻ', 'fr': 'Isha', 'sw': 'Isha',
    'ur': 'عشاء', 'tr': 'Yatsı', 'id': 'Isya', 'bn': 'এশা', 'ha': "Isha'i",
    'so': 'Cisha', 'fa': 'عشاء', 'ms': 'Isyak',
  },
  'next_prayer_suffix': {
    'ar': 'القادم', 'en': 'Upcoming', 'am': 'የሚቀጥለው', 'fr': 'à venir', 'sw': 'Ijayo',
    'ur': 'اگلی', 'tr': 'Sıradaki', 'id': 'Berikutnya', 'bn': 'পরবর্তী', 'ha': 'Mai Zuwa',
    'so': 'Xigta', 'fa': 'بعدی', 'ms': 'Seterusnya',
  },
  'next_prayer_generic': {
    'ar': 'الصلاة القادمة', 'en': 'Next Prayer', 'am': 'የሚቀጥለው ጸሎት', 'fr': 'Prochaine prière', 'sw': 'Sala Ijayo',
    'ur': 'اگلی نماز', 'tr': 'Sıradaki Namaz', 'id': 'Salat Berikutnya', 'bn': 'পরবর্তী নামাজ', 'ha': 'Sallar Mai Zuwa',
    'so': 'Salaadda Xigta', 'fa': 'نماز بعدی', 'ms': 'Solat Seterusnya',
  },
  // 2026-08-22: weekday names — used by salah_assessment_screen.dart.
  'weekday_sunday': {
    'ar': 'الأحد', 'en': 'Sunday', 'am': 'እሁድ', 'fr': 'Dimanche', 'sw': 'Jumapili',
    'ur': 'اتوار', 'tr': 'Pazar', 'id': 'Minggu', 'bn': 'রবিবার', 'ha': 'Lahadi',
    'so': 'Axad', 'fa': 'یکشنبه', 'ms': 'Ahad',
  },
  'weekday_monday': {
    'ar': 'الاثنين', 'en': 'Monday', 'am': 'ሰኞ', 'fr': 'Lundi', 'sw': 'Jumatatu',
    'ur': 'پیر', 'tr': 'Pazartesi', 'id': 'Senin', 'bn': 'সোমবার', 'ha': 'Litinin',
    'so': 'Isniin', 'fa': 'دوشنبه', 'ms': 'Isnin',
  },
  'weekday_tuesday': {
    'ar': 'الثلاثاء', 'en': 'Tuesday', 'am': 'ማክሰኞ', 'fr': 'Mardi', 'sw': 'Jumanne',
    'ur': 'منگل', 'tr': 'Salı', 'id': 'Selasa', 'bn': 'মঙ্গলবার', 'ha': 'Talata',
    'so': 'Talaado', 'fa': 'سه‌شنبه', 'ms': 'Selasa',
  },
  'weekday_wednesday': {
    'ar': 'الأربعاء', 'en': 'Wednesday', 'am': 'ረቡዕ', 'fr': 'Mercredi', 'sw': 'Jumatano',
    'ur': 'بدھ', 'tr': 'Çarşamba', 'id': 'Rabu', 'bn': 'বুধবার', 'ha': 'Laraba',
    'so': 'Arbaco', 'fa': 'چهارشنبه', 'ms': 'Rabu',
  },
  'weekday_thursday': {
    'ar': 'الخميس', 'en': 'Thursday', 'am': 'ሐሙስ', 'fr': 'Jeudi', 'sw': 'Alhamisi',
    'ur': 'جمعرات', 'tr': 'Perşembe', 'id': 'Kamis', 'bn': 'বৃহস্পতিবার', 'ha': 'Alhamis',
    'so': 'Khamiis', 'fa': 'پنجشنبه', 'ms': 'Khamis',
  },
  'weekday_friday': {
    'ar': 'الجمعة', 'en': 'Friday', 'am': 'ዓርብ', 'fr': 'Vendredi', 'sw': 'Ijumaa',
    'ur': 'جمعہ', 'tr': 'Cuma', 'id': 'Jumat', 'bn': 'শুক্রবার', 'ha': "Jumma'a",
    'so': 'Jimce', 'fa': 'جمعه', 'ms': 'Jumaat',
  },
  'weekday_saturday': {
    'ar': 'السبت', 'en': 'Saturday', 'am': 'ቅዳሜ', 'fr': 'Samedi', 'sw': 'Jumamosi',
    'ur': 'ہفتہ', 'tr': 'Cumartesi', 'id': 'Sabtu', 'bn': 'শনিবার', 'ha': 'Asabar',
    'so': 'Sabti', 'fa': 'شنبه', 'ms': 'Sabtu',
  },
  // 2026-08-22: prayer_times_screen.dart.
  'calc_method_tooltip': {
    'ar': 'طريقة الحساب', 'en': 'Calculation Method', 'am': 'የስሌት ዘዴ', 'fr': 'Méthode de calcul', 'sw': 'Njia ya Hesabu',
    'ur': 'حساب کا طریقہ', 'tr': 'Hesaplama Yöntemi', 'id': 'Metode Perhitungan', 'bn': 'গণনার পদ্ধতি', 'ha': 'Hanyar Lissafi',
    'so': 'Habka Xisaabinta', 'fa': 'روش محاسبه', 'ms': 'Kaedah Pengiraan',
  },
  'calculating_prayer_times_message': {
    'ar': 'جاري حساب مواقيت الصلاة لموقعك...', 'en': 'Calculating prayer times for your location...', 'am': 'ለአካባቢዎ የጸሎት ሰዓቶችን በማስላት ላይ...', 'fr': 'Calcul des heures de prière pour votre position...', 'sw': 'Inahesabu nyakati za sala kwa eneo lako...',
    'ur': 'آپ کے مقام کے لیے نماز کے اوقات کا حساب لگایا جا رہا ہے...', 'tr': 'Konumunuz için namaz vakitleri hesaplanıyor...', 'id': 'Menghitung waktu salat untuk lokasi Anda...', 'bn': 'আপনার অবস্থানের জন্য নামাজের সময় গণনা করা হচ্ছে...', 'ha': 'Ana lissafin lokutan sallah don wurinka...',
    'so': 'Waxaa la xisaabinayaa waqtiyada salaadda ee goobtaada...', 'fa': 'در حال محاسبه اوقات نماز برای موقعیت شما...', 'ms': 'Mengira waktu solat untuk lokasi anda...',
  },
  'manual_location_used_banner': {
    'ar': 'يُستخدم موقع مُدخَل يدويًا', 'en': 'Using a manually entered location', 'am': 'በእጅ የገባ አካባቢ ጥቅም ላይ ውሏል', 'fr': 'Utilisation d\'un emplacement saisi manuellement', 'sw': 'Inatumia mahali palipowekwa mwenyewe',
    'ur': 'دستی طور پر درج کردہ مقام استعمال ہو رہا ہے', 'tr': 'Manuel girilen konum kullanılıyor', 'id': 'Menggunakan lokasi yang dimasukkan secara manual', 'bn': 'ম্যানুয়ালি প্রবেশ করানো অবস্থান ব্যবহৃত হচ্ছে', 'ha': 'Ana amfani da wurin da aka shigar da hannu',
    'so': 'Waxaa la isticmaalayaa goob gacanta lagu geliyay', 'fa': 'از موقعیت وارد شده به‌صورت دستی استفاده می‌شود', 'ms': 'Menggunakan lokasi dimasukkan secara manual',
  },
  'enter_location_manually_title': {
    'ar': 'أدخل موقعك يدويًا', 'en': 'Enter Your Location Manually', 'am': 'አካባቢዎን በእጅ ያስገቡ', 'fr': 'Saisissez votre emplacement manuellement', 'sw': 'Weka Mahali Pako Mwenyewe',
    'ur': 'اپنا مقام دستی طور پر درج کریں', 'tr': 'Konumunuzu Manuel Girin', 'id': 'Masukkan Lokasi Anda Secara Manual', 'bn': 'নিজে আপনার অবস্থান লিখুন', 'ha': 'Shigar da Wurinka da Hannu',
    'so': 'Gacanta ku geli Goobtaada', 'fa': 'موقعیت خود را به‌صورت دستی وارد کنید', 'ms': 'Masukkan Lokasi Anda Secara Manual',
  },
  'enter_location_manually_subtitle': {
    'ar': 'يُستخدم فقط إذا تعذّر الوصول لموقعك عبر GPS', 'en': "Only used if your GPS location can't be reached", 'am': 'የGPS አካባቢዎ ላይ መድረስ ካልተቻለ ብቻ ጥቅም ላይ ይውላል', 'fr': "Utilisé uniquement si votre position GPS ne peut pas être atteinte", 'sw': 'Inatumika tu ikiwa mahali pako pa GPS hapawezi kufikiwa',
    'ur': 'صرف اس وقت استعمال ہوتا ہے جب آپ کے GPS مقام تک رسائی ممکن نہ ہو', 'tr': 'Yalnızca GPS konumunuza ulaşılamadığında kullanılır', 'id': 'Hanya digunakan jika lokasi GPS Anda tidak dapat dijangkau', 'bn': 'শুধুমাত্র তখনই ব্যবহৃত হয় যখন আপনার জিপিএস অবস্থান পাওয়া যায় না', 'ha': 'Ana amfani da shi ne kawai idan ba a iya samun wurin GPS ɗinka ba',
    'so': 'Waxaa loo isticmaalaa kaliya haddii aan la gaarin karin goobtaada GPS-ka', 'fa': 'فقط در صورتی استفاده می‌شود که به موقعیت GPS شما دسترسی نباشد', 'ms': 'Hanya digunakan jika lokasi GPS anda tidak dapat dicapai',
  },
  'latitude_field_label': {
    'ar': 'خط العرض (Latitude)', 'en': 'Latitude', 'am': 'ኬክሮስ (Latitude)', 'fr': 'Latitude', 'sw': 'Latitudo',
    'ur': 'عرض البلد (Latitude)', 'tr': 'Enlem (Latitude)', 'id': 'Lintang (Latitude)', 'bn': 'অক্ষাংশ (Latitude)', 'ha': 'Latitude',
    'so': 'Latitude', 'fa': 'عرض جغرافیایی (Latitude)', 'ms': 'Latitud',
  },
  'longitude_field_label': {
    'ar': 'خط الطول (Longitude)', 'en': 'Longitude', 'am': 'ኬንትሮስ (Longitude)', 'fr': 'Longitude', 'sw': 'Longitudo',
    'ur': 'طول البلد (Longitude)', 'tr': 'Boylam (Longitude)', 'id': 'Bujur (Longitude)', 'bn': 'দ্রাঘিমাংশ (Longitude)', 'ha': 'Longitude',
    'so': 'Longitude', 'fa': 'طول جغرافیایی (Longitude)', 'ms': 'Longitud',
  },
  'save_location_action': {
    'ar': 'حفظ الموقع', 'en': 'Save Location', 'am': 'አካባቢ አስቀምጥ', 'fr': "Enregistrer l'emplacement", 'sw': 'Hifadhi Mahali',
    'ur': 'مقام محفوظ کریں', 'tr': 'Konumu Kaydet', 'id': 'Simpan Lokasi', 'bn': 'অবস্থান সংরক্ষণ করুন', 'ha': 'Ajiye Wuri',
    'so': 'Kaydi Goobta', 'fa': 'ذخیره موقعیت', 'ms': 'Simpan Lokasi',
  },
  'calc_method_label_prefix': {
    'ar': 'طريقة الحساب', 'en': 'Calculation method', 'am': 'የስሌት ዘዴ', 'fr': 'Méthode de calcul', 'sw': 'Njia ya hesabu',
    'ur': 'حساب کا طریقہ', 'tr': 'Hesaplama yöntemi', 'id': 'Metode perhitungan', 'bn': 'গণনার পদ্ধতি', 'ha': 'Hanyar lissafi',
    'so': 'Habka xisaabinta', 'fa': 'روش محاسبه', 'ms': 'Kaedah pengiraan',
  },
  'asr_madhab_label_prefix': {
    'ar': 'مذهب العصر', 'en': "Asr school (madhab)", 'am': 'የዐስር መድሀብ', 'fr': "École (madhhab) de l'Asr", 'sw': 'Madhehebu ya Alasiri',
    'ur': 'عصر کا مذہب', 'tr': 'İkindi Mezhebi', 'id': 'Mazhab Asar', 'bn': 'আসরের মাজহাব', 'ha': "Madhabin La'asar",
    'so': 'Madhabka Casarka', 'fa': 'مذهب عصر', 'ms': 'Mazhab Asar',
  },
  'hanafi_label': {
    'ar': 'حنفي', 'en': 'Hanafi', 'am': 'ሐነፊ', 'fr': 'Hanafite', 'sw': 'Hanafi',
    'ur': 'حنفی', 'tr': 'Hanefi', 'id': 'Hanafi', 'bn': 'হানাফি', 'ha': 'Hanafi',
    'so': 'Xanafi', 'fa': 'حنفی', 'ms': 'Hanafi',
  },
  'jumhoor_madhab_label': {
    'ar': 'الجمهور (شافعي/مالكي/حنبلي)', 'en': 'Majority (Shafi\'i/Maliki/Hanbali)', 'am': 'አብላጫው (ሻፊዒ/ማሊኪ/ሐንበሊ)', 'fr': 'Majorité (chaféite/malikite/hanbalite)', 'sw': 'Wengi (Shafi\'i/Maliki/Hanbali)',
    'ur': 'جمہور (شافعی/مالکی/حنبلی)', 'tr': 'Çoğunluk (Şafii/Maliki/Hanbeli)', 'id': 'Mayoritas (Syafi\'i/Maliki/Hanbali)', 'bn': 'অধিকাংশ (শাফেয়ি/মালেকি/হাম্বলি)', 'ha': "Rinjaye (Shafi'i/Maliki/Hanbali)",
    'so': 'Aqlabiyada (Shaafici/Maaliki/Xanbali)', 'fa': 'اکثریت (شافعی/مالکی/حنبلی)', 'ms': 'Majoriti (Syafi\'i/Maliki/Hanbali)',
  },
  'calc_method_sheet_title': {
    'ar': 'طريقة حساب أوقات الصلاة', 'en': 'Prayer Time Calculation Method', 'am': 'የጸሎት ሰዓት ስሌት ዘዴ', 'fr': 'Méthode de calcul des heures de prière', 'sw': 'Njia ya Kuhesabu Nyakati za Sala',
    'ur': 'نماز کے اوقات کے حساب کا طریقہ', 'tr': 'Namaz Vakti Hesaplama Yöntemi', 'id': 'Metode Perhitungan Waktu Salat', 'bn': 'নামাজের সময় গণনার পদ্ধতি', 'ha': 'Hanyar Lissafin Lokutan Sallah',
    'so': 'Habka Xisaabinta Waqtiyada Salaadda', 'fa': 'روش محاسبه اوقات نماز', 'ms': 'Kaedah Pengiraan Waktu Solat',
  },
  'asr_madhab_sheet_title': {
    'ar': 'مذهب حساب العصر', 'en': 'Asr Calculation School', 'am': 'የዐስር ስሌት መድሀብ', 'fr': "École de calcul de l'Asr", 'sw': 'Madhehebu ya Kuhesabu Alasiri',
    'ur': 'عصر کے حساب کا مذہب', 'tr': 'İkindi Hesaplama Mezhebi', 'id': 'Mazhab Perhitungan Asar', 'bn': 'আসর গণনার মাজহাব', 'ha': "Madhabin Lissafin La'asar",
    'so': 'Madhabka Xisaabinta Casarka', 'fa': 'مذهب محاسبه عصر', 'ms': 'Mazhab Pengiraan Asar',
  },
  'high_latitude_rule_title': {
    'ar': 'قاعدة خطوط العرض العالية', 'en': 'High Latitude Rule', 'am': 'የከፍተኛ ኬክሮስ ደንብ', 'fr': 'Règle des hautes latitudes', 'sw': 'Kanuni ya Latitudo za Juu',
    'ur': 'اونچے عرض البلد کا قاعدہ', 'tr': 'Yüksek Enlem Kuralı', 'id': 'Aturan Lintang Tinggi', 'bn': 'উচ্চ অক্ষাংশের নিয়ম', 'ha': 'Ka\'idar Latitude Mai Girma',
    'so': 'Xeerka Latitude-ka Sare', 'fa': 'قاعده عرض جغرافیایی بالا', 'ms': 'Peraturan Latitud Tinggi',
  },
  'high_latitude_rule_desc': {
    'ar': 'يظهر تأثيرها فقط في المناطق البعيدة عن خط الاستواء (فوق ٤٨° تقريبًا) حيث لا يُظلم الشفق كفاية لحساب الفجر/العشاء عاديًا',
    'en': "Only affects regions far from the equator (above roughly 48°), where twilight never gets dark enough for a normal Fajr/Isha calculation",
    'am': 'ተጽዕኖው የሚታየው ከምድር ወገብ ራቅ ካሉ አካባቢዎች (ከ48° በላይ ግምት) ብቻ ነው፣ እዚያ ንጋት ለተለመደው የፈጅር/ዒሻ ስሌት በቂ ጨለማ ስለማይሆን',
    'fr': "N'affecte que les régions éloignées de l'équateur (au-delà d'environ 48°), où le crépuscule ne devient jamais assez sombre pour un calcul normal du Fajr/Isha",
    'sw': 'Inaathiri tu maeneo yaliyo mbali na ikweta (zaidi ya nyuzi 48 hivi), ambapo giza la jioni halifiki kiwango cha kutosha kwa hesabu ya kawaida ya Fajr/Isha',
    'ur': 'اس کا اثر صرف خطِ استوا سے دور علاقوں پر ہوتا ہے (تقریباً ٤٨° سے اوپر) جہاں شفق عام فجر/عشاء کے حساب کے لیے کافی تاریک نہیں ہوتی',
    'tr': 'Yalnızca ekvatordan uzak bölgeleri etkiler (yaklaşık 48°\'nin üzerinde), burada alacakaranlık normal Fecir/Yatsı hesabı için yeterince kararmaz',
    'id': 'Hanya memengaruhi wilayah yang jauh dari khatulistiwa (di atas sekitar 48°), di mana senja tidak pernah cukup gelap untuk perhitungan Subuh/Isya normal',
    'bn': 'শুধুমাত্র নিরক্ষরেখা থেকে দূরবর্তী অঞ্চলে (প্রায় ৪৮° এর উপরে) প্রভাব ফেলে, যেখানে গোধূলি স্বাভাবিক ফজর/এশার হিসাবের জন্য যথেষ্ট অন্ধকার হয় না',
    'ha': 'Yana shafan yankunan da suke nesa da equator ne kawai (sama da kusan digiri 48), inda duhun magariba ba ya taɓa zama isasshe don lissafin Asuba/Isha\'i na yau da kullun',
    'so': 'Waxay saameyn ku yeelataa kaliya deegaanada ka fog dhulbaraha (in ka badan 48° qiyaastii), halkaas oo mugdiga fiidkii aanu marnaba u madoobaan xisaabinta caadiga ah ee Subax/Cisha',
    'fa': 'فقط بر مناطق دور از خط استوا (بالای تقریباً ۴۸ درجه) تأثیر می‌گذارد، جایی که گرگ‌ومیش هرگز به اندازه کافی برای محاسبه عادی فجر/عشاء تاریک نمی‌شود',
    'ms': 'Hanya menjejaskan kawasan yang jauh dari khatulistiwa (melebihi kira-kira 48°), di mana syafak tidak pernah cukup gelap untuk pengiraan Subuh/Isyak biasa',
  },
  'edit_location_manually_action': {
    'ar': 'تعديل الموقع يدويًا', 'en': 'Edit Location Manually', 'am': 'አካባቢን በእጅ አርትዕ', 'fr': "Modifier l'emplacement manuellement", 'sw': 'Hariri Mahali Mwenyewe',
    'ur': 'مقام دستی طور پر تبدیل کریں', 'tr': 'Konumu Manuel Düzenle', 'id': 'Ubah Lokasi Secara Manual', 'bn': 'ম্যানুয়ালি অবস্থান সম্পাদনা করুন', 'ha': 'Gyara Wuri da Hannu',
    'so': 'Gacanta ku wax ka beddel Goobta', 'fa': 'ویرایش دستی موقعیت', 'ms': 'Edit Lokasi Secara Manual',
  },
  'no_location_title': {
    'ar': 'لم نتمكن من تحديد موقعك', 'en': "We couldn't determine your location", 'am': 'አካባቢዎን መወሰን አልቻልንም', 'fr': "Nous n'avons pas pu déterminer votre emplacement", 'sw': 'Hatukuweza kubaini mahali pako',
    'ur': 'ہم آپ کا مقام معلوم نہیں کر سکے', 'tr': 'Konumunuzu belirleyemedik', 'id': 'Kami tidak dapat menentukan lokasi Anda', 'bn': 'আমরা আপনার অবস্থান নির্ধারণ করতে পারিনি', 'ha': 'Ba mu iya tantance wurinka ba',
    'so': 'Ma aanan awoodin inaan go\'aamino goobtaada', 'fa': 'نتوانستیم موقعیت شما را تعیین کنیم', 'ms': 'Kami tidak dapat menentukan lokasi anda',
  },
  'no_location_desc': {
    'ar': 'تحتاج أوقات الصلاة والقبلة إلى موقعك — فعّل خدمة الموقع أو أدخله يدويًا', 'en': 'Prayer times and Qibla need your location — enable location services or enter it manually', 'am': 'የጸሎት ሰዓቶች እና ቂብላ አካባቢዎን ይፈልጋሉ — የአካባቢ አገልግሎትን ያንቁ ወይም በእጅ ያስገቡት', 'fr': 'Les heures de prière et la Qibla ont besoin de votre position — activez les services de localisation ou saisissez-la manuellement', 'sw': 'Nyakati za sala na Kibla vinahitaji mahali pako — washa huduma za mahali au uweke mwenyewe',
    'ur': 'نماز کے اوقات اور قبلہ کو آپ کے مقام کی ضرورت ہے — لوکیشن سروسز فعال کریں یا دستی طور پر درج کریں', 'tr': 'Namaz vakitleri ve Kıble konumunuza ihtiyaç duyar — konum hizmetlerini etkinleştirin veya manuel girin', 'id': 'Waktu salat dan Kiblat memerlukan lokasi Anda — aktifkan layanan lokasi atau masukkan secara manual', 'bn': 'নামাজের সময় ও কিবলার জন্য আপনার অবস্থান প্রয়োজন — লোকেশন সেবা চালু করুন বা নিজে লিখুন', 'ha': 'Lokutan sallah da Alkibla suna buƙatar wurinka — kunna sabis na wuri ko ka shigar da shi da hannu',
    'so': 'Waqtiyada salaadda iyo Qiblada waxay u baahan yihiin goobtaada — daar adeegga goobta ama gacanta ku geli', 'fa': 'اوقات نماز و قبله به موقعیت شما نیاز دارند — سرویس مکان را فعال کنید یا آن را به‌صورت دستی وارد کنید', 'ms': 'Waktu solat dan Kiblat memerlukan lokasi anda — dayakan perkhidmatan lokasi atau masukkan secara manual',
  },
  'enter_location_manually_action': {
    'ar': 'إدخال الموقع يدويًا', 'en': 'Enter Location Manually', 'am': 'አካባቢን በእጅ ያስገቡ', 'fr': "Saisir l'emplacement manuellement", 'sw': 'Weka Mahali Mwenyewe',
    'ur': 'مقام دستی طور پر درج کریں', 'tr': 'Konumu Manuel Gir', 'id': 'Masukkan Lokasi Secara Manual', 'bn': 'ম্যানুয়ালি অবস্থান লিখুন', 'ha': 'Shigar da Wuri da Hannu',
    'so': 'Gacanta ku geli Goobta', 'fa': 'وارد کردن دستی موقعیت', 'ms': 'Masukkan Lokasi Secara Manual',
  },
  'hlr_auto_label': {
    'ar': 'تلقائي (موصى به)', 'en': 'Automatic (recommended)', 'am': 'ራስ-ሰር (የሚመከር)', 'fr': 'Automatique (recommandé)', 'sw': 'Kiotomatiki (kinachopendekezwa)',
    'ur': 'خودکار (تجویز کردہ)', 'tr': 'Otomatik (önerilen)', 'id': 'Otomatis (disarankan)', 'bn': 'স্বয়ংক্রিয় (প্রস্তাবিত)', 'ha': 'Atomatik (ana bada shawarar)',
    'so': 'Toos ah (lagula talinayo)', 'fa': 'خودکار (توصیه‌شده)', 'ms': 'Automatik (disyorkan)',
  },
  'hlr_middle_of_night_label': {
    'ar': 'منتصف الليل', 'en': 'Middle of the Night', 'am': 'የሌሊት እኩሌታ', 'fr': 'Milieu de la nuit', 'sw': 'Katikati ya Usiku',
    'ur': 'نصف شب', 'tr': 'Gecenin Ortası', 'id': 'Tengah Malam', 'bn': 'মধ্যরাত', 'ha': 'Tsakiyar Dare',
    'so': 'Bar-habeenka', 'fa': 'نیمه شب', 'ms': 'Pertengahan Malam',
  },
  'hlr_seventh_of_night_label': {
    'ar': 'سُبع الليل', 'en': 'One-Seventh of the Night', 'am': 'የሌሊት ሰባተኛ', 'fr': 'Un septième de la nuit', 'sw': 'Sehemu ya Saba ya Usiku',
    'ur': 'رات کا ساتواں حصہ', 'tr': 'Gecenin Yedide Biri', 'id': 'Sepertujuh Malam', 'bn': 'রাতের এক-সপ্তমাংশ', 'ha': 'Kashi Bakwai na Dare',
    'so': 'Toddobaad-Habeenka', 'fa': 'یک‌هفتم شب', 'ms': 'Satu Pertujuh Malam',
  },
  'hlr_twilight_angle_label': {
    'ar': 'زاوية الشفق', 'en': 'Twilight Angle', 'am': 'የንጋት ማዕዘን', 'fr': 'Angle crépusculaire', 'sw': 'Pembe ya Gizagiza',
    'ur': 'شفق کا زاویہ', 'tr': 'Alacakaranlık Açısı', 'id': 'Sudut Senja', 'bn': 'গোধূলি কোণ', 'ha': 'Kusurwar Magariba',
    'so': 'Xagasha Fiidka', 'fa': 'زاویه گرگ‌ومیش', 'ms': 'Sudut Syafak',
  },
  'method_muslim_world_league': {
    'ar': 'رابطة العالم الإسلامي', 'en': 'Muslim World League', 'am': 'የሙስሊም ዓለም ሊግ', 'fr': 'Ligue islamique mondiale', 'sw': 'Umoja wa Dunia wa Kiislamu',
    'ur': 'رابطہ عالم اسلامی', 'tr': 'Müslüman Dünya Birliği', 'id': 'Liga Muslim Dunia', 'bn': 'মুসলিম বিশ্ব লীগ', 'ha': "Kungiyar Musulmi ta Duniya",
    'so': 'Ururka Muslimiinta Adduunka', 'fa': 'رابطه جهان اسلام', 'ms': 'Liga Muslim Sedunia',
  },
  'method_egyptian': {
    'ar': 'الهيئة المصرية العامة للمساحة', 'en': 'Egyptian General Authority of Survey', 'am': 'የግብጽ አጠቃላይ ጥናት ባለስልጣን', 'fr': 'Autorité générale égyptienne de topographie', 'sw': 'Mamlaka Kuu ya Upimaji ya Misri',
    'ur': 'مصری جنرل اتھارٹی آف سروے', 'tr': 'Mısır Genel Anket Otoritesi', 'id': 'Otoritas Survei Umum Mesir', 'bn': 'মিশরীয় সাধারণ জরিপ কর্তৃপক্ষ', 'ha': 'Hukumar Bincike ta Masar',
    'so': 'Hay\'adda Sahanka Guud ee Masar', 'fa': 'سازمان کل نقشه‌برداری مصر', 'ms': 'Pihak Berkuasa Ukur Am Mesir',
  },
  'method_karachi': {
    'ar': 'جامعة العلوم الإسلامية، كراتشي', 'en': 'University of Islamic Sciences, Karachi', 'am': 'የእስልምና ሳይንስ ዩኒቨርስቲ፣ ካራቺ', 'fr': 'Université des sciences islamiques, Karachi', 'sw': 'Chuo Kikuu cha Elimu ya Kiislamu, Karachi',
    'ur': 'جامعہ علوم اسلامیہ، کراچی', 'tr': 'İslami Bilimler Üniversitesi, Karaçi', 'id': 'Universitas Ilmu Islam, Karachi', 'bn': 'ইসলামিক বিজ্ঞান বিশ্ববিদ্যালয়, করাচি', 'ha': 'Jami\'ar Kimiyyar Musulunci, Karachi',
    'so': 'Jaamacadda Sayniska Islaamiga, Karachi', 'fa': 'دانشگاه علوم اسلامی، کراچی', 'ms': 'Universiti Sains Islam, Karachi',
  },
  'method_umm_al_qura': {
    'ar': 'أم القرى، مكة المكرمة', 'en': 'Umm al-Qura, Makkah', 'am': 'ኡም አል-ቁራ፣ መካ', 'fr': 'Umm al-Qura, La Mecque', 'sw': 'Umm al-Qura, Makka',
    'ur': 'ام القریٰ، مکہ مکرمہ', 'tr': 'Ümmü\'l-Kura, Mekke', 'id': 'Umm al-Qura, Makkah', 'bn': 'উম্মুল কুরা, মক্কা', 'ha': "Ummul Qura, Makka",
    'so': 'Umm al-Qura, Makka', 'fa': 'ام‌القری، مکه', 'ms': 'Umm al-Qura, Makkah',
  },
  'method_dubai': {
    'ar': 'دبي', 'en': 'Dubai', 'am': 'ዱባይ', 'fr': 'Dubaï', 'sw': 'Dubai',
    'ur': 'دبئی', 'tr': 'Dubai', 'id': 'Dubai', 'bn': 'দুবাই', 'ha': 'Dubai',
    'so': 'Dubay', 'fa': 'دبی', 'ms': 'Dubai',
  },
  'method_qatar': {
    'ar': 'قطر', 'en': 'Qatar', 'am': 'ኳታር', 'fr': 'Qatar', 'sw': 'Qatar',
    'ur': 'قطر', 'tr': 'Katar', 'id': 'Qatar', 'bn': 'কাতার', 'ha': 'Qatar',
    'so': 'Qadar', 'fa': 'قطر', 'ms': 'Qatar',
  },
  'method_kuwait': {
    'ar': 'الكويت', 'en': 'Kuwait', 'am': 'ኩዌት', 'fr': 'Koweït', 'sw': 'Kuwait',
    'ur': 'کویت', 'tr': 'Kuveyt', 'id': 'Kuwait', 'bn': 'কুয়েত', 'ha': 'Kuwait',
    'so': 'Kuwayt', 'fa': 'کویت', 'ms': 'Kuwait',
  },
  'method_moonsighting_committee': {
    'ar': 'لجنة رؤية الهلال', 'en': 'Moonsighting Committee', 'am': 'የጨረቃ ምልከታ ኮሚቴ', 'fr': 'Comité d\'observation de la lune', 'sw': 'Kamati ya Kuona Mwezi',
    'ur': 'کمیٹی برائے رؤیتِ ہلال', 'tr': 'Hilal Görme Komitesi', 'id': 'Komite Rukyatul Hilal', 'bn': 'চাঁদ দেখা কমিটি', 'ha': 'Kwamitin Ganin Wata',
    'so': 'Guddiga Arag Bisha', 'fa': 'کمیته رؤیت هلال', 'ms': 'Jawatankuasa Cerapan Bulan',
  },
  'method_singapore': {
    'ar': 'سنغافورة', 'en': 'Singapore', 'am': 'ሲንጋፖር', 'fr': 'Singapour', 'sw': 'Singapore',
    'ur': 'سنگاپور', 'tr': 'Singapur', 'id': 'Singapura', 'bn': 'সিঙ্গাপুর', 'ha': 'Singapore',
    'so': 'Singaboor', 'fa': 'سنگاپور', 'ms': 'Singapura',
  },
  'method_turkiye': {
    'ar': 'تركيا (ديانت)', 'en': 'Turkey (Diyanet)', 'am': 'ቱርክ (ዲያነት)', 'fr': 'Turquie (Diyanet)', 'sw': 'Uturuki (Diyanet)',
    'ur': 'ترکی (دیانت)', 'tr': 'Türkiye (Diyanet)', 'id': 'Turki (Diyanet)', 'bn': 'তুরস্ক (দিয়ানেত)', 'ha': 'Turkiyya (Diyanet)',
    'so': 'Turkiga (Diyanet)', 'fa': 'ترکیه (دیانت)', 'ms': 'Turki (Diyanet)',
  },
  'method_tehran': {
    'ar': 'طهران', 'en': 'Tehran', 'am': 'ቴህራን', 'fr': 'Téhéran', 'sw': 'Tehran',
    'ur': 'تہران', 'tr': 'Tahran', 'id': 'Teheran', 'bn': 'তেহরান', 'ha': 'Tehran',
    'so': 'Tehraan', 'fa': 'تهران', 'ms': 'Tehran',
  },
  'method_north_america': {
    'ar': 'أمريكا الشمالية (ISNA)', 'en': 'North America (ISNA)', 'am': 'ሰሜን አሜሪካ (ISNA)', 'fr': 'Amérique du Nord (ISNA)', 'sw': 'Amerika Kaskazini (ISNA)',
    'ur': 'شمالی امریکہ (ISNA)', 'tr': 'Kuzey Amerika (ISNA)', 'id': 'Amerika Utara (ISNA)', 'bn': 'উত্তর আমেরিকা (ISNA)', 'ha': 'Arewacin Amurka (ISNA)',
    'so': 'Waqooyiga Ameerika (ISNA)', 'fa': 'آمریکای شمالی (ISNA)', 'ms': 'Amerika Utara (ISNA)',
  },
  'method_morocco': {
    'ar': 'المغرب', 'en': 'Morocco', 'am': 'ሞሮኮ', 'fr': 'Maroc', 'sw': 'Moroko',
    'ur': 'مراکش', 'tr': 'Fas', 'id': 'Maroko', 'bn': 'মরক্কো', 'ha': 'Maroko',
    'so': 'Marooko', 'fa': 'مراکش', 'ms': 'Maghribi',
  },
  'am_period_short': {
    'ar': 'ص', 'en': 'AM', 'am': 'ጠዋት', 'fr': 'AM', 'sw': 'AM',
    'ur': 'صبح', 'tr': 'ÖÖ', 'id': 'AM', 'bn': 'AM', 'ha': 'AM',
    'so': 'AM', 'fa': 'ق.ظ', 'ms': 'AM',
  },
  'pm_period_short': {
    'ar': 'م', 'en': 'PM', 'am': 'ከሰዓት', 'fr': 'PM', 'sw': 'PM',
    'ur': 'شام', 'tr': 'ÖS', 'id': 'PM', 'bn': 'PM', 'ha': 'PM',
    'so': 'PM', 'fa': 'ب.ظ', 'ms': 'PM',
  },
  // 2026-08-22: salah_tracker_screen.dart.
  'salah_tracker_title': {
    'ar': 'إقامة الصلاة', 'en': 'Establishing Prayer', 'am': 'ጸሎትን ማቋቋም', 'fr': 'Accomplir la prière', 'sw': 'Kusimamisha Sala',
    'ur': 'اقامتِ نماز', 'tr': 'Namazı İkame Etmek', 'id': 'Mendirikan Salat', 'bn': 'নামাজ কায়েম করা', 'ha': 'Tsayar da Sallah',
    'so': 'Salaadda Taagidda', 'fa': 'اقامه نماز', 'ms': 'Mendirikan Solat',
  },
  'weekly_assessment_tooltip': {
    'ar': 'تقييمي الأسبوعي', 'en': 'My Weekly Assessment', 'am': 'የሳምንታዊ ግምገማዬ', 'fr': 'Mon évaluation hebdomadaire', 'sw': 'Tathmini Yangu ya Wiki',
    'ur': 'میرا ہفتہ وار جائزہ', 'tr': 'Haftalık Değerlendirmem', 'id': 'Penilaian Mingguan Saya', 'bn': 'আমার সাপ্তাহিক মূল্যায়ন', 'ha': 'Kimanta Makona',
    'so': 'Qiimeyntayda Toddobaadlaha ah', 'fa': 'ارزیابی هفتگی من', 'ms': 'Penilaian Mingguan Saya',
  },
  'loading_salah_log': {
    'ar': 'جاري تحميل سجل صلاتك...', 'en': 'Loading your prayer log...', 'am': 'የጸሎት መዝገብዎን በመጫን ላይ...', 'fr': 'Chargement de votre journal de prière...', 'sw': 'Inapakia rekodi yako ya sala...',
    'ur': 'آپ کا نماز کا ریکارڈ لوڈ ہو رہا ہے...', 'tr': 'Namaz kaydınız yükleniyor...', 'id': 'Memuat catatan salat Anda...', 'bn': 'আপনার নামাজের রেকর্ড লোড হচ্ছে...', 'ha': 'Ana lodin tarihin sallar ka...',
    'so': 'Waxaa la soo rarayaa diiwaanka salaaddaada...', 'fa': 'در حال بارگذاری سابقه نماز شما...', 'ms': 'Memuatkan log solat anda...',
  },
  'todays_prayers_header': {
    'ar': 'صلواتي اليوم', 'en': "Today's Prayers", 'am': 'የዛሬ ጸሎቶቼ', 'fr': "Mes prières d'aujourd'hui", 'sw': 'Sala Zangu za Leo',
    'ur': 'میری آج کی نمازیں', 'tr': 'Bugünkü Namazlarım', 'id': 'Salat Saya Hari Ini', 'bn': 'আজকের আমার নামাজ', 'ha': 'Sallolina na Yau',
    'so': 'Salaadahayga Maanta', 'fa': 'نمازهای امروز من', 'ms': 'Solat Saya Hari Ini',
  },
  'log_honestly_subtitle': {
    'ar': 'سجّل بصدق — هذا لك أنت، لا حكم عليك من أحد', 'en': "Record honestly — this is for you alone, no one is judging", 'am': 'በእውነት ይመዝግቡ — ይህ ለእርስዎ ብቻ ነው፣ ማንም አይፈርድብዎትም', 'fr': 'Enregistrez honnêtement — ceci est pour vous seul, personne ne juge', 'sw': 'Rekodi kwa uaminifu — hii ni kwa ajili yako pekee, hakuna anayehukumu',
    'ur': 'ایمانداری سے درج کریں — یہ صرف آپ کے لیے ہے، کوئی آپ کو نہیں جانچ رہا', 'tr': 'Dürüstçe kaydedin — bu yalnızca sizin için, kimse yargılamıyor', 'id': 'Catat dengan jujur — ini hanya untuk Anda sendiri, tidak ada yang menghakimi', 'bn': 'সততার সাথে রেকর্ড করুন — এটি শুধু আপনার জন্য, কেউ বিচার করছে না', 'ha': 'Ka rubuta da gaskiya — wannan naka ne kaɗai, babu wanda zai yi maka hukunci',
    'so': 'Si daacad ah u diiwaan geli — tan waa kuu adiga oo keliya, cid ku xukumaysa ma jirto', 'fa': 'صادقانه ثبت کنید — این فقط برای شماست، هیچ‌کس شما را قضاوت نمی‌کند', 'ms': 'Rekod dengan jujur — ini untuk anda sahaja, tiada siapa menghakimi',
  },
  'prayer_status_question_suffix': {
    'ar': 'هل صليت؟', 'en': 'Did you pray?', 'am': 'ጸልየዋል?', 'fr': 'Avez-vous prié ?', 'sw': 'Je, umesali?',
    'ur': 'کیا آپ نے نماز پڑھی؟', 'tr': 'Namaz kıldın mı?', 'id': 'Apakah Anda sudah salat?', 'bn': 'আপনি কি নামাজ পড়েছেন?', 'ha': 'Ka yi sallah?',
    'so': 'Ma salaaday?', 'fa': 'آیا نماز خواندید؟', 'ms': 'Adakah anda telah solat?',
  },
  'prayed_on_time_status': {
    'ar': 'صليتها في وقتها', 'en': 'Prayed on time', 'am': 'በሰዓቱ ጸልያለሁ', 'fr': "Priée à l'heure", 'sw': 'Nimesali kwa wakati',
    'ur': 'وقت پر پڑھی', 'tr': 'Vaktinde kıldım', 'id': 'Salat tepat waktu', 'bn': 'সময়মতো পড়েছি', 'ha': 'Na yi ta a kan lokaci',
    'so': 'Waqtigeeda ayaan ku tukaday', 'fa': 'به‌موقع خواندم', 'ms': 'Solat tepat masa',
  },
  'prayed_jamaah_status': {
    'ar': 'صليتها جماعة', 'en': 'Prayed in congregation', 'am': 'በጀመዓ ጸልያለሁ', 'fr': 'Priée en congrégation', 'sw': 'Nimesali kwa jamaa',
    'ur': 'باجماعت پڑھی', 'tr': 'Cemaatle kıldım', 'id': 'Salat berjamaah', 'bn': 'জামাতে পড়েছি', 'ha': 'Na yi ta jama\'a',
    'so': 'Jamaaco ayaan ku tukaday', 'fa': 'با جماعت خواندم', 'ms': 'Solat berjemaah',
  },
  'prayed_late_status': {
    'ar': 'صليتها متأخرًا', 'en': 'Prayed late', 'am': 'ዘግይቼ ጸልያለሁ', 'fr': 'Priée en retard', 'sw': 'Nimesali kwa kuchelewa',
    'ur': 'دیر سے پڑھی', 'tr': 'Geç kıldım', 'id': 'Salat terlambat', 'bn': 'দেরিতে পড়েছি', 'ha': 'Na yi ta a makare',
    'so': 'Aan daahay ayaan ku tukaday', 'fa': 'با تأخیر خواندم', 'ms': 'Solat lewat',
  },
  'prayer_missed_status': {
    'ar': 'لم أصلها', 'en': "Didn't pray it", 'am': 'አልጸለይኩም', 'fr': "Non priée", 'sw': 'Sijasali',
    'ur': 'نہیں پڑھی', 'tr': 'Kılmadım', 'id': 'Belum salat', 'bn': 'পড়িনি', 'ha': 'Ban yi ba',
    'so': 'Ma tukan', 'fa': 'نخواندم', 'ms': 'Belum solat',
  },
  'not_recorded_yet_label': {
    'ar': 'لم يُسجَّل بعد', 'en': 'Not recorded yet', 'am': 'እስካሁን አልተመዘገበም', 'fr': 'Pas encore enregistré', 'sw': 'Bado haijarekodiwa',
    'ur': 'ابھی تک درج نہیں ہوا', 'tr': 'Henüz kaydedilmedi', 'id': 'Belum tercatat', 'bn': 'এখনও রেকর্ড করা হয়নি', 'ha': 'Ba a rubuta ba tukuna',
    'so': 'Wali lama diiwaan gelin', 'fa': 'هنوز ثبت نشده', 'ms': 'Belum direkodkan',
  },
  'salah_library_action': {
    'ar': 'مكتبة إقامة الصلاة', 'en': 'Prayer Library', 'am': 'የጸሎት ቤተ መጻሕፍት', 'fr': 'Bibliothèque de la prière', 'sw': 'Maktaba ya Sala',
    'ur': 'نماز کی لائبریری', 'tr': 'Namaz Kütüphanesi', 'id': 'Perpustakaan Salat', 'bn': 'নামাজ গ্রন্থাগার', 'ha': 'Laburaren Sallah',
    'so': 'Maktabadda Salaadda', 'fa': 'کتابخانه نماز', 'ms': 'Perpustakaan Solat',
  },
  'salah_stories_action': {
    'ar': 'قصص الأولين في الصلاة', 'en': 'Stories of the Early Muslims on Prayer', 'am': 'የቀደምት ሙስሊሞች የጸሎት ታሪኮች', 'fr': 'Récits des premiers musulmans sur la prière', 'sw': 'Hadithi za Waislamu wa Kwanza kuhusu Sala',
    'ur': 'نماز میں سلف کے قصے', 'tr': 'İlk Müslümanların Namaz Hakkındaki Kıssaları', 'id': 'Kisah Para Salaf tentang Salat', 'bn': 'নামাজ নিয়ে পূর্বসূরিদের কাহিনী', 'ha': 'Labaran Magabata Kan Sallah',
    'so': 'Sheekooyinka Salafka ku Saabsan Salaadda', 'fa': 'داستان‌های سلف درباره نماز', 'ms': 'Kisah Salaf tentang Solat',
  },
  'salah_resources_action': {
    'ar': 'مصادر موصى بها', 'en': 'Recommended Resources', 'am': 'የሚመከሩ ምንጮች', 'fr': 'Ressources recommandées', 'sw': 'Vyanzo Vinavyopendekezwa',
    'ur': 'تجویز کردہ ذرائع', 'tr': 'Önerilen Kaynaklar', 'id': 'Sumber yang Direkomendasikan', 'bn': 'প্রস্তাবিত উৎস', 'ha': 'Abubuwan da Ake Bada Shawara',
    'so': 'Ilaha Lagula Talinayo', 'fa': 'منابع پیشنهادی', 'ms': 'Sumber Disyorkan',
  },
  'todays_mission_label': {
    'ar': 'مهمة اليوم', 'en': "Today's Mission", 'am': 'የዛሬ ተልእኮ', 'fr': "Mission du jour", 'sw': 'Dhamira ya Leo',
    'ur': 'آج کا مشن', 'tr': 'Bugünkü Görev', 'id': 'Misi Hari Ini', 'bn': 'আজকের মিশন', 'ha': 'Manufar Yau',
    'so': 'Hawsha Maanta', 'fa': 'مأموریت امروز', 'ms': 'Misi Hari Ini',
  },
  'view_full_library_action': {
    'ar': 'عرض المكتبة كاملة', 'en': 'View Full Library', 'am': 'ሙሉ ቤተ መጻሕፍትን ይመልከቱ', 'fr': 'Voir la bibliothèque complète', 'sw': 'Ona Maktaba Kamili',
    'ur': 'مکمل لائبریری دیکھیں', 'tr': 'Tüm Kütüphaneyi Görüntüle', 'id': 'Lihat Perpustakaan Lengkap', 'bn': 'সম্পূর্ণ গ্রন্থাগার দেখুন', 'ha': 'Duba Cikakken Laburare',
    'so': 'Fiiri Maktabadda Oo Dhan', 'fa': 'مشاهده کتابخانه کامل', 'ms': 'Lihat Perpustakaan Penuh',
  },
  // 2026-08-22: salah_assessment_screen.dart.
  'dim_muhafazah': {
    'ar': 'المحافظة على الصلوات', 'en': 'Maintaining the Prayers', 'am': 'ጸሎቶችን መጠበቅ', 'fr': 'Assiduité aux prières', 'sw': 'Kudumisha Sala',
    'ur': 'نمازوں کی پابندی', 'tr': 'Namazlara Devam', 'id': 'Menjaga Salat', 'bn': 'নামাজ বজায় রাখা', 'ha': 'Kiyaye Sallolin',
    'so': 'Ilaalinta Salaadaha', 'fa': 'محافظت بر نمازها', 'ms': 'Menjaga Solat',
  },
  'dim_on_time': {
    'ar': 'الصلاة في الوقت', 'en': 'Praying on Time', 'am': 'በሰዓቱ መጸለይ', 'fr': "Prier à l'heure", 'sw': 'Kusali kwa Wakati',
    'ur': 'وقت پر نماز', 'tr': 'Vaktinde Namaz', 'id': 'Salat Tepat Waktu', 'bn': 'সময়মতো নামাজ', 'ha': 'Sallah a Kan Lokaci',
    'so': 'Salaadda Waqtigeeda', 'fa': 'نماز به‌موقع', 'ms': 'Solat Tepat Masa',
  },
  'dim_jamaah': {
    'ar': 'الجماعة', 'en': 'Congregation', 'am': 'ጀመዓ', 'fr': 'La congrégation', 'sw': 'Jamaa',
    'ur': 'باجماعت', 'tr': 'Cemaat', 'id': 'Berjamaah', 'bn': 'জামাত', 'ha': "Jama'a",
    'so': 'Jamaaco', 'fa': 'جماعت', 'ms': 'Berjemaah',
  },
  'dim_khushu': {
    'ar': 'الخشوع', 'en': 'Khushu (Humility)', 'am': 'ኹሹዕ (ትህትና)', 'fr': 'Khoushou (humilité)', 'sw': 'Unyenyekevu (Khushu)',
    'ur': 'خشوع', 'tr': 'Huşu', 'id': 'Khusyuk', 'bn': 'খুশু (একাগ্রতা)', 'ha': "Kaskantar da kai (Khushu'i)",
    'so': 'Khushuuc', 'fa': 'خشوع', 'ms': 'Khusyuk',
  },
  'dim_rawatib': {
    'ar': 'السنن الرواتب', 'en': 'The Regular Sunnah Prayers', 'am': 'መደበኛ ሱናዎች', 'fr': 'Les sunnas régulières', 'sw': 'Sunna za Kawaida',
    'ur': 'سنن راتبہ', 'tr': 'Nafile Namazlar (Revatib)', 'id': 'Sunnah Rawatib', 'bn': 'সুন্নাতে রাওয়াতিব', 'ha': "Sunnonin Yau da Kullum",
    'so': 'Sunnooyinka Joogtada ah', 'fa': 'سنت‌های رواتب', 'ms': 'Sunat Rawatib',
  },
  'dim_adhkar': {
    'ar': 'أذكار الصلاة', 'en': 'Prayer Adhkar', 'am': 'የጸሎት አዝካር', 'fr': 'Les adhkar de la prière', 'sw': 'Adhkar za Sala',
    'ur': 'نماز کے اذکار', 'tr': 'Namaz Ezkârı', 'id': 'Dzikir Salat', 'bn': 'নামাজের আজকার', 'ha': 'Azkarin Sallah',
    'so': 'Adkaarka Salaadda', 'fa': 'اذکار نماز', 'ms': 'Zikir Solat',
  },
  'dim_understanding': {
    'ar': 'فهم ما تقرأ', 'en': 'Understanding What You Recite', 'am': 'የሚያነቡትን መረዳት', 'fr': 'Comprendre ce que vous récitez', 'sw': 'Kuelewa Unayosoma',
    'ur': 'جو پڑھتے ہیں اسے سمجھنا', 'tr': 'Okuduğunu Anlamak', 'id': 'Memahami yang Dibaca', 'bn': 'যা পড়ছেন তা বোঝা', 'ha': 'Fahimtar Abin da Kake Karantawa',
    'so': 'Fahamka Waxa Aad Akhrinayso', 'fa': 'فهم آنچه می‌خوانید', 'ms': 'Memahami Apa yang Dibaca',
  },
  'weekly_progress_prefix': {
    'ar': 'صليت', 'en': 'You prayed', 'am': 'ጸልየዋል', 'fr': 'Vous avez prié', 'sw': 'Umesali',
    'ur': 'آپ نے پڑھی', 'tr': 'Kıldınız', 'id': 'Anda salat', 'bn': 'আপনি পড়েছেন', 'ha': 'Ka yi',
    'so': 'Waad tukatay', 'fa': 'خواندید', 'ms': 'Anda telah solat',
  },
  'weekly_progress_middle': {
    'ar': 'من', 'en': 'of', 'am': 'ከ', 'fr': 'sur', 'sw': 'kati ya',
    'ur': 'میں سے', 'tr': '/', 'id': 'dari', 'bn': 'এর মধ্যে', 'ha': 'daga cikin',
    'so': 'oo ka mid ah', 'fa': 'از', 'ms': 'daripada',
  },
  'weekly_progress_suffix': {
    'ar': 'صلاة هذا الأسبوع (في وقتها أو جماعة)', 'en': 'prayers this week (on time or in congregation)', 'am': 'ጸሎቶች በዚህ ሳምንት (በሰዓቱ ወይም በጀመዓ)', 'fr': 'prières cette semaine (à l\'heure ou en congrégation)', 'sw': 'sala wiki hii (kwa wakati au kwa jamaa)',
    'ur': 'نمازیں اس ہفتے (وقت پر یا باجماعت)', 'tr': 'namazı bu hafta (vaktinde veya cemaatle)', 'id': 'salat minggu ini (tepat waktu atau berjamaah)', 'bn': 'নামাজ এই সপ্তাহে (সময়মতো বা জামাতে)', 'ha': "sallah a wannan makon (a kan lokaci ko jama'a)",
    'so': 'salaad usbuucan (waqtigeeda ama jamaaco)', 'fa': 'نماز در این هفته (به‌موقع یا با جماعت)', 'ms': 'solat minggu ini (tepat masa atau berjemaah)',
  },
  'week_in_detail_header': {
    'ar': 'أسبوعك بالتفصيل', 'en': 'Your Week in Detail', 'am': 'ሳምንትዎ በዝርዝር', 'fr': 'Votre semaine en détail', 'sw': 'Wiki Yako kwa Undani',
    'ur': 'آپ کا ہفتہ تفصیل سے', 'tr': 'Haftanız Ayrıntılı', 'id': 'Minggu Anda Secara Detail', 'bn': 'আপনার সপ্তাহ বিস্তারিত', 'ha': 'Makonka Dalla-dalla',
    'so': 'Usbuucaaga Faahfaahsan', 'fa': 'هفته شما به‌تفصیل', 'ms': 'Minggu Anda Secara Terperinci',
  },
  'rate_yourself_honestly_subtitle': {
    'ar': 'قيّم نفسك بصدق — لا أحد سيراها سواك', 'en': "Rate yourself honestly — no one will see this but you", 'am': 'ራስዎን በእውነት ይገምግሙ — ከእርስዎ በቀር ማንም አያየውም', 'fr': "Évaluez-vous honnêtement — personne d'autre que vous ne le verra", 'sw': 'Jipime kwa uaminifu — hakuna atakayeona hii isipokuwa wewe',
    'ur': 'خود کو ایمانداری سے پرکھیں — یہ آپ کے سوا کوئی نہیں دیکھے گا', 'tr': 'Kendinizi dürüstçe değerlendirin — bunu sizden başka kimse görmeyecek', 'id': 'Nilai diri Anda dengan jujur — tidak ada yang akan melihatnya selain Anda', 'bn': 'নিজেকে সততার সাথে মূল্যায়ন করুন — আপনি ছাড়া কেউ এটি দেখবে না', 'ha': 'Ka tantance kanka da gaskiya — babu wanda zai gan shi sai kai',
    'so': 'Si daacad ah isu qiimee — ma jiro cid arki doonta tan adiga mooyee', 'fa': 'خودتان را صادقانه ارزیابی کنید — جز شما کسی این را نمی‌بیند', 'ms': 'Nilai diri anda dengan jujur — tiada siapa akan melihat ini selain anda',
  },
  // 2026-08-22: worship_coach_screen.dart.
  'worship_coach_title': {
    'ar': 'مدرب العبادة', 'en': 'Worship Coach', 'am': 'የአምልኮ አሰልጣኝ', 'fr': "Coach d'adoration", 'sw': 'Kocha wa Ibada',
    'ur': 'عبادت کوچ', 'tr': 'İbadet Koçu', 'id': 'Pelatih Ibadah', 'bn': 'ইবাদত কোচ', 'ha': 'Kocin Ibada',
    'so': 'Tababaraha Cibaadada', 'fa': 'مربی عبادت', 'ms': 'Jurulatih Ibadah',
  },
  'analyzing_consistency_message': {
    'ar': 'جاري تحليل انتظامك لتحديد مهمتك...', 'en': 'Analyzing your consistency to determine your task...', 'am': 'ተግባርዎን ለመወሰን ወጥነትዎን በመተንተን ላይ...', 'fr': 'Analyse de votre régularité pour déterminer votre tâche...', 'sw': 'Inachambua uthabiti wako kubaini kazi yako...',
    'ur': 'آپ کا کام طے کرنے کے لیے آپ کی مستقل مزاجی کا تجزیہ کیا جا رہا ہے...', 'tr': 'Göreviniz belirlenmek için sürekliliğiniz analiz ediliyor...', 'id': 'Menganalisis konsistensi Anda untuk menentukan tugas Anda...', 'bn': 'আপনার কাজ নির্ধারণ করতে আপনার ধারাবাহিকতা বিশ্লেষণ করা হচ্ছে...', 'ha': 'Ana nazarin daidaiton ka don tantance aikinka...',
    'so': 'Waxaa la falanqeynayaa joogtaynta si loo go\'aamiyo hawshaada...', 'fa': 'در حال تحلیل ثبات شما برای تعیین وظیفه‌تان...', 'ms': 'Menganalisis konsistensi anda untuk menentukan tugas anda...',
  },
  'how_we_determine_task_header': {
    'ar': 'كيف نحدد مهمتك؟', 'en': 'How do we determine your task?', 'am': 'ተግባርዎን እንዴት እንወስናለን?', 'fr': 'Comment déterminons-nous votre tâche ?', 'sw': 'Tunabainije kazi yako?',
    'ur': 'ہم آپ کا کام کیسے طے کرتے ہیں؟', 'tr': 'Göreviniz nasıl belirleniyor?', 'id': 'Bagaimana kami menentukan tugas Anda?', 'bn': 'আমরা আপনার কাজ কীভাবে নির্ধারণ করি?', 'ha': 'Ta yaya muke tantance aikinka?',
    'so': 'Sideen u go\'aaminaa hawshaada?', 'fa': 'چگونه وظیفه شما را تعیین می‌کنیم؟', 'ms': 'Bagaimana kami menentukan tugas anda?',
  },
  'coach_rule_explanation': {
    'ar': 'قاعدة بسيطة وواضحة، بلا ذكاء اصطناعي: نحسب مدى انتظامك في آخر 7 أيام لكل مجال، ونركّز على أول مجال أقل من 70% — الصلاة أولًا، ثم القرآن، ثم الأذكار. إن كانت الثلاثة مستقرة، نقترح المرحلة التالية بدل إزعاجك بما هو متقن أصلًا.',
    'en': "A simple, transparent rule, no AI involved: we calculate your consistency over the last 7 days for each area, and focus on the first area under 70% — prayer first, then Qur'an, then adhkar. If all three are stable, we suggest the next stage instead of bothering you about something already solid.",
    'am': 'ቀላል እና ግልጽ ደንብ፣ ያለ ሰው ሠራሽ አስተውሎት፦ ላለፉት 7 ቀናት ለእያንዳንዱ ዘርፍ ወጥነትዎን እናሰላለን፣ እና ከ70% በታች ባለው መጀመሪያ ዘርፍ ላይ እናተኩራለን — መጀመሪያ ጸሎት፣ ከዚያ ቁርኣን፣ ከዚያ አዝካር። ሦስቱም የተረጋጉ ከሆኑ፣ ቀድሞውኑ የተካኑበትን በማወክ ፈንታ ቀጣዩን ደረጃ እንጠቁማለን።',
    'fr': "Une règle simple et transparente, sans IA : nous calculons votre régularité sur les 7 derniers jours pour chaque domaine, et nous nous concentrons sur le premier domaine sous 70 % — la prière d'abord, puis le Coran, puis les adhkar. Si les trois sont stables, nous suggérons l'étape suivante plutôt que de vous déranger avec ce qui est déjà solide.",
    'sw': 'Kanuni rahisi na wazi, bila AI: tunahesabu uthabiti wako wa siku 7 zilizopita kwa kila eneo, na kuzingatia eneo la kwanza lililo chini ya 70% — sala kwanza, kisha Qur\'an, kisha adhkar. Ikiwa yote matatu ni thabiti, tunapendekeza hatua inayofuata badala ya kukusumbua na kitu ambacho tayari kimeimarika.',
    'ur': 'ایک آسان اور واضح اصول، بغیر مصنوعی ذہانت کے: ہم ہر شعبے کے لیے پچھلے 7 دنوں کی آپ کی مستقل مزاجی کا حساب لگاتے ہیں، اور 70% سے کم پہلے شعبے پر توجہ دیتے ہیں — پہلے نماز، پھر قرآن، پھر اذکار۔ اگر تینوں مستحکم ہوں، تو ہم آپ کو پہلے سے مضبوط چیز سے پریشان کرنے کے بجائے اگلا مرحلہ تجویز کرتے ہیں۔',
    'tr': "Basit ve şeffaf bir kural, yapay zeka yok: her alan için son 7 gündeki sürekliliğinizi hesaplıyoruz ve %70'in altındaki ilk alana odaklanıyoruz — önce namaz, sonra Kur'an, sonra ezkâr. Üçü de istikrarlıysa, zaten sağlam olan bir şeyle sizi rahatsız etmek yerine bir sonraki aşamayı öneriyoruz.",
    'id': 'Aturan sederhana dan transparan, tanpa AI: kami menghitung konsistensi Anda selama 7 hari terakhir untuk setiap bidang, dan fokus pada bidang pertama di bawah 70% — salat dulu, lalu Al-Qur\'an, lalu dzikir. Jika ketiganya stabil, kami menyarankan tahap berikutnya alih-alih mengganggu Anda dengan sesuatu yang sudah kuat.',
    'bn': 'একটি সহজ ও স্বচ্ছ নিয়ম, কোনো এআই ছাড়াই: আমরা প্রতিটি ক্ষেত্রের জন্য গত ৭ দিনের ধারাবাহিকতা গণনা করি এবং ৭০%-এর নিচে থাকা প্রথম ক্ষেত্রে মনোযোগ দিই — প্রথমে নামাজ, তারপর কুরআন, তারপর আজকার। তিনটিই স্থিতিশীল হলে, ইতিমধ্যে মজবুত কিছু নিয়ে আপনাকে বিরক্ত না করে পরবর্তী ধাপ প্রস্তাব করি।',
    'ha': "Ka'ida mai sauƙi kuma bayyananna, ba tare da AI ba: muna lissafin daidaitonka na kwanaki 7 da suka gabata don kowane fanni, muna mai da hankali kan fannin farko da ya kai ƙasa da 70% — sallah tukuna, sannan Alkur'ani, sannan azkari. Idan dukkan ukun sun tabbata, muna ba da shawarar matakin gaba maimakon dama'ka da abin da ya riga ya kwanta.",
    'so': 'Xeer fudud oo cad, oo aan lahayn AI: waxaan xisaabinaa joogtaynta 7-dii maalmood ee ugu dambeeyay qayb kasta, oo waxaan diirada saarnaa qaybta ugu horreysa ee ka hooseysa 70% — salaadda marka hore, ka dib Qur\'aanka, ka dibna adkaarka. Haddii saddexdaba ay xasilloon yihiin, waxaan soo jeedinaa marxaladda xigta halkii aan kugu dhib gelin wax mar hore adkaaday.',
    'fa': 'قاعده‌ای ساده و شفاف، بدون هوش مصنوعی: ثبات شما را در ۷ روز گذشته برای هر حوزه محاسبه می‌کنیم و روی اولین حوزه‌ای که زیر ۷۰٪ است تمرکز می‌کنیم — ابتدا نماز، سپس قرآن، سپس اذکار. اگر هر سه پایدار باشند، به‌جای مزاحم شدن با چیزی که از قبل مستحکم است، مرحله بعدی را پیشنهاد می‌دهیم.',
    'ms': "Peraturan mudah dan telus, tanpa AI: kami mengira konsistensi anda dalam 7 hari lepas bagi setiap bidang, dan memberi tumpuan kepada bidang pertama di bawah 70% — solat dahulu, kemudian Al-Quran, kemudian zikir. Jika ketiga-tiganya stabil, kami mencadangkan peringkat seterusnya dan bukannya mengganggu anda dengan sesuatu yang sudah kukuh.",
  },
  'consistency_prayer_label': {
    'ar': 'الصلاة', 'en': 'Prayer', 'am': 'ጸሎት', 'fr': 'La prière', 'sw': 'Sala',
    'ur': 'نماز', 'tr': 'Namaz', 'id': 'Salat', 'bn': 'নামাজ', 'ha': 'Sallah',
    'so': 'Salaadda', 'fa': 'نماز', 'ms': 'Solat',
  },
  'consistency_quran_label': {
    'ar': 'القرآن', 'en': "Qur'an", 'am': 'ቁርኣን', 'fr': 'Le Coran', 'sw': 'Qur\'an',
    'ur': 'قرآن', 'tr': "Kur'an", 'id': 'Al-Qur\'an', 'bn': 'কুরআন', 'ha': "Alkur'ani",
    'so': "Qur'aanka", 'fa': 'قرآن', 'ms': 'Al-Quran',
  },
  'consistency_dhikr_label': {
    'ar': 'الأذكار', 'en': 'Adhkar', 'am': 'አዝካር', 'fr': 'Les adhkar', 'sw': 'Adhkar',
    'ur': 'اذکار', 'tr': 'Ezkâr', 'id': 'Dzikir', 'bn': 'আজকার', 'ha': 'Azkari',
    'so': 'Adkaarka', 'fa': 'اذکار', 'ms': 'Zikir',
  },
  'manzil_weekly_portion_title': {
    'ar': 'منزل — حصتك الأسبوعية', 'en': 'Manzil — Your Weekly Portion', 'am': 'መንዚል — ሳምንታዊ ድርሻዎ', 'fr': 'Manzil — Votre part hebdomadaire', 'sw': 'Manzil — Sehemu Yako ya Wiki',
    'ur': 'منزل — آپ کا ہفتہ وار حصہ', 'tr': 'Menzil — Haftalık Payınız', 'id': 'Manzil — Porsi Mingguan Anda', 'bn': 'মানজিল — আপনার সাপ্তাহিক অংশ', 'ha': 'Manzil — Rabonka na Mako',
    'so': 'Manzil — Qaybtaada Toddobaadlaha ah', 'fa': 'منزل — سهم هفتگی شما', 'ms': 'Manzil — Bahagian Mingguan Anda',
  },
  'manzil_weekly_portion_prefix': {
    'ar': 'لتغطية كل محفوظك الراسخ مرة كل أسبوع، راجع نحو', 'en': "To cover all your solid memorization once a week, review around", 'am': 'ጠንካራውን ሁሉንም ጥናትዎን በሳምንት አንድ ጊዜ ለመሸፈን፣ በግምት ይከልሱ', 'fr': "Pour couvrir toute votre mémorisation solide une fois par semaine, révisez environ", 'sw': 'Ili kufunika hifadhi yako yote thabiti mara moja kwa wiki, pitia karibu',
    'ur': 'اپنے تمام مضبوط حفظ کو ہفتے میں ایک بار مکمل کرنے کے لیے، تقریباً دہرائیں', 'tr': "Sağlam ezberinizin tamamını haftada bir kez kapsamak için yaklaşık şunu tekrar edin:", 'id': 'Untuk mencakup semua hafalan Anda yang kuat sekali seminggu, ulangi sekitar', 'bn': 'আপনার সমস্ত মজবুত হিফজ সপ্তাহে একবার আবৃত্তি করতে, প্রায় দোহরান',
    'ha': "Don rufe duk haddace naka mai ƙarfi sau ɗaya a mako, sake dubi kusan", 'so': 'Si aad u dabooshid dhammaan xifdhintaada adkaatay hal mar toddobaadkii, dib-u-eeg qiyaastii', 'fa': 'برای پوشش کامل حفظیات محکم شما یک‌بار در هفته، حدود این مقدار مرور کنید:', 'ms': 'Untuk meliputi semua hafalan kukuh anda sekali seminggu, ulangkaji kira-kira',
  },
  'manzil_weekly_portion_suffix': {
    'ar': 'صفحة يوميًا', 'en': 'pages daily', 'am': 'ገጾች በየቀኑ', 'fr': 'pages par jour', 'sw': 'kurasa kila siku',
    'ur': 'صفحات روزانہ', 'tr': 'sayfa günlük', 'id': 'halaman setiap hari', 'bn': 'পাতা প্রতিদিন', 'ha': 'shafuka kullum',
    'so': 'bog maalin kasta', 'fa': 'صفحه در روز', 'ms': 'halaman setiap hari',
  },
  'weak_spots_header': {
    'ar': 'نقاط تحتاج تركيزًا إضافيًا', 'en': 'Spots That Need Extra Focus', 'am': 'ተጨማሪ ትኩረት የሚያስፈልጋቸው ነጥቦች', 'fr': "Points qui nécessitent plus d'attention", 'sw': 'Sehemu Zinazohitaji Umakini Zaidi',
    'ur': 'اضافی توجہ کی ضرورت والے نکات', 'tr': 'Ekstra Odak Gerektiren Noktalar', 'id': 'Titik yang Butuh Fokus Ekstra', 'bn': 'অতিরিক্ত মনোযোগ প্রয়োজন এমন পয়েন্ট', 'ha': 'Wuraren da Ke Buƙatar Ƙarin Kulawa',
    'so': 'Dhibcaha U Baahan Diirada Dheeraadka ah', 'fa': 'نقاطی که نیاز به تمرکز بیشتر دارند', 'ms': 'Titik Memerlukan Fokus Tambahan',
  },
  'weak_spots_subtitle': {
    'ar': 'الصفحات التي تكرر فيها "يحتاج مراجعة" مؤخرًا — آخر 30 يومًا', 'en': 'Pages recently marked "needs review" repeatedly — last 30 days', 'am': '"ክለሳ ይፈልጋል" ተብለው በተደጋጋሚ የተመዘገቡ ገጾች — ያለፉት 30 ቀናት', 'fr': 'Pages récemment marquées "à réviser" de manière répétée — 30 derniers jours', 'sw': 'Kurasa zilizowekwa alama "inahitaji kupitiwa" mara kwa mara hivi karibuni — siku 30 zilizopita',
    'ur': 'وہ صفحات جن پر حال ہی میں بار بار "دہرانے کی ضرورت" کا نشان لگا — پچھلے 30 دن', 'tr': 'Son zamanlarda tekrar tekrar "gözden geçirilmeli" olarak işaretlenen sayfalar — son 30 gün', 'id': 'Halaman yang baru-baru ini berulang kali ditandai "perlu diulang" — 30 hari terakhir', 'bn': 'সম্প্রতি বারবার "পুনরাবৃত্তি প্রয়োজন" চিহ্নিত পাতা — গত ৩০ দিন', 'ha': 'Shafukan da aka sanya alamar "yana buƙatar sake nazari" akai-akai kwanan nan — kwanaki 30 na ƙarshe',
    'so': 'Bogagga dhawaan si isdaba joog ah loo calaamadeeyay "u baahan dib-u-eegis" — 30kii maalmood ee ugu dambeeyay', 'fa': 'صفحاتی که اخیراً به‌طور مکرر "نیاز به مرور" علامت‌گذاری شده‌اند — ۳۰ روز گذشته', 'ms': 'Halaman yang baru-baru ini kerap ditanda "perlu ulangkaji" — 30 hari lepas',
  },
  'page_word_prefix': {
    'ar': 'صفحة', 'en': 'Page', 'am': 'ገጽ', 'fr': 'Page', 'sw': 'Ukurasa',
    'ur': 'صفحہ', 'tr': 'Sayfa', 'id': 'Halaman', 'bn': 'পাতা', 'ha': 'Shafi',
    'so': 'Bogga', 'fa': 'صفحه', 'ms': 'Halaman',
  },
  'from_surah_prefix': {
    'ar': 'من سورة', 'en': 'from Surah', 'am': 'ከሱራ', 'fr': 'de la sourate', 'sw': 'kutoka Sura',
    'ur': 'سورۃ سے', 'tr': "Suresinden", 'id': 'dari Surah', 'bn': 'সূরা থেকে', 'ha': 'daga Suratu',
    'so': 'Suuradda', 'fa': 'از سوره', 'ms': 'daripada Surah',
  },
  'times_count_suffix': {
    'ar': 'مرات', 'en': 'times', 'am': 'ጊዜ', 'fr': 'fois', 'sw': 'mara',
    'ur': 'بار', 'tr': 'kez', 'id': 'kali', 'bn': 'বার', 'ha': 'sau',
    'so': 'jeer', 'fa': 'بار', 'ms': 'kali',
  },
  'additional_tasks_soon_title': {
    'ar': 'أعمال إضافية — قريبًا', 'en': 'Additional Acts — Coming Soon', 'am': 'ተጨማሪ ተግባራት — በቅርቡ', 'fr': 'Actes supplémentaires — bientôt', 'sw': 'Matendo Zaidi — Hivi Karibuni',
    'ur': 'اضافی اعمال — جلد آ رہا ہے', 'tr': 'Ek Ameller — Yakında', 'id': 'Amalan Tambahan — Segera Hadir', 'bn': 'অতিরিক্ত আমল — শীঘ্রই আসছে', 'ha': 'Ƙarin Ayyuka — Nan Ba Da Jimawa Ba',
    'so': 'Camallo Dheeraad ah — Dhawaan', 'fa': 'اعمال بیشتر — به‌زودی', 'ms': 'Amalan Tambahan — Akan Datang',
  },
  'additional_tasks_soon_body': {
    'ar': 'قيام الليل والوتر والصدقة وصيام التطوع لم تُضَف بعد لأنها تحتاج تتبعًا جديدًا لم يُبنَ في التطبيق حتى الآن — ستُضاف تدريجيًا بعد استقرار الصلاة والقرآن والأذكار، بنفس مبدأ عدم البدء بكل شيء دفعة واحدة.',
    'en': "Qiyam al-Layl, Witr, charity, and voluntary fasting haven't been added yet because they need new tracking not yet built into the app — they'll be added gradually once prayer, Qur'an, and adhkar are stable, following the same principle of not starting everything at once.",
    'am': 'የሌሊት ጸሎት፣ ውትር፣ ምጽዋት እና በፈቃደኝነት ጾም እስካሁን አልታከሉም ምክንያቱም እስካሁን በመተግበሪያው ውስጥ ያልተገነባ አዲስ ክትትል ስለሚያስፈልጋቸው — ጸሎት፣ ቁርኣን እና አዝካር ከተረጋጉ በኋላ ቀስ በቀስ ይታከላሉ፣ ሁሉንም በአንድ ጊዜ ካለመጀመር ጋር ተመሳሳይ መርህ በመከተል።',
    'fr': "Qiyam al-Layl, le Witr, l'aumône et le jeûne volontaire n'ont pas encore été ajoutés car ils nécessitent un nouveau suivi non encore intégré à l'application — ils seront ajoutés progressivement une fois la prière, le Coran et les adhkar stabilisés, selon le même principe de ne pas tout commencer à la fois.",
    'sw': 'Qiyam al-Layl, Witr, sadaka, na saumu ya hiari havijaongezwa bado kwa sababu vinahitaji ufuatiliaji mpya ambao haujajengwa katika programu hadi sasa — vitaongezwa hatua kwa hatua baada ya sala, Qur\'an, na adhkar kuwa thabiti, kufuata kanuni ile ile ya kutoanza kila kitu mara moja.',
    'ur': 'قیام اللیل، وتر، صدقہ اور نفلی روزے ابھی شامل نہیں کیے گئے کیونکہ انہیں نئی ٹریکنگ کی ضرورت ہے جو ابھی تک ایپ میں نہیں بنائی گئی — نماز، قرآن اور اذکار مستحکم ہونے کے بعد بتدریج شامل کیے جائیں گے، اسی اصول پر عمل کرتے ہوئے کہ سب کچھ ایک ساتھ شروع نہ کیا جائے۔',
    'tr': "Kıyamu'l-Leyl, Vitir, sadaka ve nafile oruç henüz eklenmedi çünkü uygulamada henüz oluşturulmamış yeni bir takip gerektiriyorlar — namaz, Kur'an ve ezkâr istikrar kazandıktan sonra, her şeyi bir anda başlatmama ilkesiyle kademeli olarak eklenecekler.",
    'id': 'Qiyamul Lail, Witir, sedekah, dan puasa sunnah belum ditambahkan karena memerlukan pelacakan baru yang belum dibangun di aplikasi — akan ditambahkan secara bertahap setelah salat, Al-Qur\'an, dan dzikir stabil, mengikuti prinsip yang sama untuk tidak memulai semuanya sekaligus.',
    'bn': 'কিয়ামুল লাইল, বিতর, সদকা এবং নফল রোজা এখনও যোগ করা হয়নি কারণ এগুলোর জন্য নতুন ট্র্যাকিং দরকার যা এখনও অ্যাপে তৈরি হয়নি — নামাজ, কুরআন ও আজকার স্থিতিশীল হওয়ার পর ধীরে ধীরে যোগ করা হবে, একসাথে সবকিছু শুরু না করার একই নীতি অনুসরণ করে।',
    'ha': "Qiyam al-Layl, Witr, sadaka, da azumin nafila ba a ƙara su ba tukuna domin suna buƙatar sabon bibiya wanda ba a gina shi a cikin manhajar ba tukuna — za a ƙara su kaɗan-kaɗan bayan sallah, Alkur'ani, da azkari sun tabbata, bin ka'idar rashin fara komai lokaci guda.",
    'so': 'Qiyaamul-Layl, Witrka, sadaqada, iyo soonka ikhtiyaarka ah wali lama darin sababtoo ah waxay u baahan yihiin la socod cusub oo aan weli lagu dhisin app-ka — waxaa lagu dari doonaa si tartiib ah marka salaadda, Qur\'aanka, iyo adkaarku ay xasillaan, iyadoo la raacayo mabda\'a isku mid ah ee aan wax walba mar keliya la bilaabin.',
    'fa': 'قیام‌اللیل، وتر، صدقه و روزه مستحب هنوز اضافه نشده‌اند زیرا نیاز به پیگیری جدیدی دارند که هنوز در برنامه ساخته نشده — پس از تثبیت نماز، قرآن و اذکار، به‌تدریج اضافه خواهند شد، با همان اصل عدم شروع همه‌چیز به‌یکباره.',
    'ms': 'Qiyamullail, Witir, sedekah, dan puasa sunat belum ditambah kerana ia memerlukan penjejakan baharu yang belum dibina dalam aplikasi — ia akan ditambah secara beransur-ansur selepas solat, Al-Quran, dan zikir stabil, mengikut prinsip yang sama iaitu tidak memulakan semuanya sekali gus.',
  },
  'last_7_days_label': {
    'ar': 'آخر 7 أيام', 'en': 'Last 7 Days', 'am': 'ያለፉት 7 ቀናት', 'fr': '7 derniers jours', 'sw': 'Siku 7 Zilizopita',
    'ur': 'گزشتہ 7 دن', 'tr': 'Son 7 Gün', 'id': '7 Hari Terakhir', 'bn': 'গত ৭ দিন', 'ha': 'Kwanaki 7 na Ƙarshe',
    'so': '7-dii Maalmood ee Ugu Dambeeyay', 'fa': '۷ روز گذشته', 'ms': '7 Hari Lepas',
  },
  'focus_now_badge_label': {
    'ar': 'التركيز الآن', 'en': 'Focus Now', 'am': 'አሁን ትኩረት', 'fr': 'Focus actuel', 'sw': 'Lengo Sasa',
    'ur': 'ابھی توجہ', 'tr': 'Şimdi Odak', 'id': 'Fokus Sekarang', 'bn': 'এখনকার মনোযোগ', 'ha': 'Kulawa Yanzu',
    'so': 'Diiradda Hadda', 'fa': 'تمرکز اکنون', 'ms': 'Fokus Sekarang',
  },
  // 2026-08-22: daily_companion_card.dart — home-screen hero card.
  'after_prayer_suffix': {
    'ar': 'بعد', 'en': 'in', 'am': 'በኋላ', 'fr': 'dans', 'sw': 'baada ya',
    'ur': 'میں', 'tr': 'sonra', 'id': 'dalam', 'bn': 'পরে', 'ha': 'bayan',
    'so': 'kaddib', 'fa': 'تا', 'ms': 'dalam',
  },
  'qibla_word_label': {
    'ar': 'القبلة', 'en': 'Qibla', 'am': 'ቂብላ', 'fr': 'Qibla', 'sw': 'Kibla',
    'ur': 'قبلہ', 'tr': 'Kıble', 'id': 'Kiblat', 'bn': 'কিবলা', 'ha': 'Alkibla',
    'so': 'Qiblada', 'fa': 'قبله', 'ms': 'Kiblat',
  },
  // 2026-08-22: tasbih_screen.dart. The dhikr phrases themselves
  // (سبحان الله etc.) stay Arabic — deep Islamic content, out of scope.
  'tasbih_title': {
    'ar': 'التسبيح', 'en': 'Tasbih Counter', 'am': 'ተስቢሕ ቆጣሪ', 'fr': 'Compteur de Tasbih', 'sw': 'Kihesabu Tasbihi',
    'ur': 'تسبیح شمار', 'tr': 'Tesbih Sayacı', 'id': 'Penghitung Tasbih', 'bn': 'তসবিহ কাউন্টার', 'ha': 'Kirga Tasbihi',
    'so': 'Tirinta Tasbiixda', 'fa': 'شمارشگر تسبیح', 'ms': 'Kira Tasbih',
  },
  'reset_today_tooltip': {
    'ar': 'إعادة ضبط اليوم', 'en': "Reset Today's Count", 'am': 'የዛሬውን ዳግም አስጀምር', 'fr': "Réinitialiser aujourd'hui", 'sw': 'Weka Upya Leo',
    'ur': 'آج کا شمار دوبارہ ترتیب دیں', 'tr': 'Bugünü Sıfırla', 'id': 'Atur Ulang Hari Ini', 'bn': 'আজকের গণনা রিসেট করুন', 'ha': 'Sake Farawa Yau',
    'so': 'Dib u deji Maanta', 'fa': 'بازنشانی امروز', 'ms': 'Set Semula Hari Ini',
  },
  'add_custom_dhikr_title': {
    'ar': 'إضافة ذكر مخصص', 'en': 'Add a Custom Dhikr', 'am': 'ብጁ ዚክር ጨምር', 'fr': 'Ajouter un dhikr personnalisé', 'sw': 'Ongeza Dhikr Maalum',
    'ur': 'حسبِ ضرورت ذکر شامل کریں', 'tr': 'Özel Zikir Ekle', 'id': 'Tambah Dzikir Kustom', 'bn': 'কাস্টম জিকির যোগ করুন', 'ha': 'Ƙara Zikiri na Musamman',
    'so': 'Ku dar Dhikr Gaar ah', 'fa': 'افزودن ذکر سفارشی', 'ms': 'Tambah Zikir Tersuai',
  },
  'write_dhikr_or_dua_hint': {
    'ar': 'اكتب الذكر أو الدعاء', 'en': 'Write the dhikr or dua', 'am': 'ዚክሩን ወይም ዱዓውን ይጻፉ', 'fr': 'Écrivez le dhikr ou le doua', 'sw': 'Andika dhikr au dua',
    'ur': 'ذکر یا دعا لکھیں', 'tr': 'Zikri veya duayı yazın', 'id': 'Tulis dzikir atau doa', 'bn': 'জিকির বা দোয়া লিখুন', 'ha': 'Rubuta zikiri ko addu\'a',
    'so': 'Qor dhikrka ama duco', 'fa': 'ذکر یا دعا را بنویسید', 'ms': 'Tulis zikir atau doa',
  },
  'delete_custom_dhikr_title': {
    'ar': 'حذف هذا الذكر المخصص؟', 'en': 'Delete this custom dhikr?', 'am': 'ይህን ብጁ ዚክር ይሰርዙ?', 'fr': 'Supprimer ce dhikr personnalisé ?', 'sw': 'Futa dhikr hii maalum?',
    'ur': 'کیا یہ حسبِ ضرورت ذکر حذف کریں؟', 'tr': 'Bu özel zikri sil?', 'id': 'Hapus dzikir kustom ini?', 'bn': 'এই কাস্টম জিকিরটি মুছবেন?', 'ha': 'Share wannan zikirin na musamman?',
    'so': 'Ma tirtirtaa dhikrkan gaarka ah?', 'fa': 'این ذکر سفارشی حذف شود؟', 'ms': 'Padam zikir tersuai ini?',
  },
  'undo_action': {
    'ar': 'تراجع', 'en': 'Undo', 'am': 'ተመለስ', 'fr': 'Annuler', 'sw': 'Tengua',
    'ur': 'واپس لیں', 'tr': 'Geri Al', 'id': 'Batalkan', 'bn': 'পূর্বাবস্থায় ফিরুন', 'ha': 'Soke',
    'so': 'Dib u celi', 'fa': 'واگرد', 'ms': 'Buat Asal',
  },
  'custom_dhikr_chip_label': {
    'ar': 'ذكر مخصص', 'en': 'Custom Dhikr', 'am': 'ብጁ ዚክር', 'fr': 'Dhikr personnalisé', 'sw': 'Dhikr Maalum',
    'ur': 'حسبِ ضرورت ذکر', 'tr': 'Özel Zikir', 'id': 'Dzikir Kustom', 'bn': 'কাস্টম জিকির', 'ha': 'Zikiri na Musamman',
    'so': 'Dhikr Gaar ah', 'fa': 'ذکر سفارشی', 'ms': 'Zikir Tersuai',
  },
  'target_label_prefix': {
    'ar': 'الهدف: ', 'en': 'Target: ', 'am': 'ግብ፦ ', 'fr': 'Objectif : ', 'sw': 'Lengo: ',
    'ur': 'ہدف: ', 'tr': 'Hedef: ', 'id': 'Target: ', 'bn': 'লক্ষ্য: ', 'ha': 'Manufa: ',
    'so': 'Yoolka: ', 'fa': 'هدف: ', 'ms': 'Sasaran: ',
  },
  'of_target_prefix': {
    'ar': 'من', 'en': 'of', 'am': 'ከ', 'fr': 'sur', 'sw': 'kati ya',
    'ur': 'میں سے', 'tr': '/', 'id': 'dari', 'bn': 'এর মধ্যে', 'ha': 'daga cikin',
    'so': 'oo ka mid ah', 'fa': 'از', 'ms': 'daripada',
  },
  'tasbih_target_complete_message': {
    'ar': 'أتممت الهدف — بارك الله فيك ✨', 'en': "You completed the target — may Allah bless you ✨", 'am': 'ግቡን አጠናቀዋል — አላህ ይባርክዎ ✨', 'fr': "Vous avez atteint l'objectif — qu'Allah vous bénisse ✨", 'sw': 'Umefikia lengo — Allah akubariki ✨',
    'ur': 'آپ نے ہدف مکمل کر لیا — اللہ آپ کو برکت دے ✨', 'tr': 'Hedefi tamamladınız — Allah sizi mübarek kılsın ✨', 'id': 'Anda mencapai target — semoga Allah memberkati Anda ✨', 'bn': 'আপনি লক্ষ্য পূরণ করেছেন — আল্লাহ আপনাকে বরকত দিন ✨', 'ha': 'Ka kammala manufar — Allah Ya albarkace ka ✨',
    'so': 'Waad gaadhay yoolka — Ilaahay ha ku barakeeyo ✨', 'fa': 'به هدف رسیدید — خداوند شما را برکت دهد ✨', 'ms': 'Anda mencapai sasaran — semoga Allah memberkati anda ✨',
  },
  'tap_anywhere_to_tasbih_message': {
    'ar': 'اضغط في أي مكان لتسبّح', 'en': 'Tap anywhere to count', 'am': 'ለመቁጠር የትም ይንኩ', 'fr': "Appuyez n'importe où pour compter", 'sw': 'Gusa mahali popote kuhesabu',
    'ur': 'شمار کرنے کے لیے کہیں بھی دبائیں', 'tr': 'Saymak için herhangi bir yere dokunun', 'id': 'Ketuk di mana saja untuk menghitung', 'bn': 'গণনা করতে যেকোনো জায়গায় চাপুন', 'ha': 'Danna ko\'ina don ƙidayawa',
    'so': 'Taabo meel kasta si aad u tirisid', 'fa': 'برای شمارش هر جا را لمس کنید', 'ms': 'Ketik di mana-mana untuk mengira',
  },
  // 2026-08-22: review_screen.dart.
  'review_title': {
    'ar': 'المراجعة', 'en': 'Review', 'am': 'ክለሳ', 'fr': 'Révision', 'sw': 'Kupitia',
    'ur': 'دہرائی', 'tr': 'Tekrar', 'id': 'Ulangan', 'bn': 'পুনরাবৃত্তি', 'ha': 'Sake Nazari',
    'so': 'Dib-u-eegis', 'fa': 'مرور', 'ms': 'Ulangkaji',
  },
  'completed_all_reviews_message': {
    'ar': 'أحسنت — أنجزت كل مراجعات اليوم', 'en': "Well done — you've completed all of today's reviews", 'am': 'መልካም — የዛሬውን ክለሳ ሁሉ አጠናቀዋል', 'fr': "Bien joué — vous avez terminé toutes les révisions d'aujourd'hui", 'sw': 'Hongera — umekamilisha marudio yote ya leo',
    'ur': 'شاباش — آپ نے آج کی تمام دہرائیاں مکمل کر لیں', 'tr': 'Aferin — bugünkü tüm tekrarları tamamladınız', 'id': 'Bagus — Anda telah menyelesaikan semua ulangan hari ini', 'bn': 'সাবাশ — আপনি আজকের সব পুনরাবৃত্তি সম্পন্ন করেছেন', 'ha': 'Madalla — ka kammala dukkan sake-nazarin yau',
    'so': 'Waad ku mahadsan tahay — waad dhammaysay dhammaan dib-u-eegistii maanta', 'fa': 'آفرین — همه مرورهای امروز را کامل کردید', 'ms': 'Syabas — anda telah melengkapkan semua ulangkaji hari ini',
  },
  'no_reviews_due_message': {
    'ar': 'لا توجد مراجعات مستحقة اليوم', 'en': 'No reviews due today', 'am': 'ዛሬ የሚገባ ክለሳ የለም', 'fr': "Aucune révision due aujourd'hui", 'sw': 'Hakuna marudio yanayohitajika leo',
    'ur': 'آج کوئی دہرائی واجب نہیں', 'tr': 'Bugün için tekrar yok', 'id': 'Tidak ada ulangan yang jatuh tempo hari ini', 'bn': 'আজ কোনো পুনরাবৃত্তি বাকি নেই', 'ha': 'Babu sake-nazarin da ake bukata yau',
    'so': 'Maanta dib-u-eegis lagama baahna', 'fa': 'امروز مروری لازم نیست', 'ms': 'Tiada ulangkaji perlu dilakukan hari ini',
  },
  'reward_reminder_prefix': {
    'ar': 'قلت لنفسك:', 'en': 'You told yourself:', 'am': 'ለራስዎ ተናግረው ነበር፦', 'fr': 'Vous vous êtes dit :', 'sw': 'Ulijiambia:',
    'ur': 'آپ نے خود سے کہا تھا:', 'tr': 'Kendinize demiştiniz:', 'id': 'Anda berkata pada diri sendiri:', 'bn': 'আপনি নিজেকে বলেছিলেন:', 'ha': 'Ka gaya wa kanka:',
    'so': 'Waxaad naftaada u sheegtay:', 'fa': 'به خودتان گفتید:', 'ms': 'Anda telah berkata kepada diri sendiri:',
  },
  'reward_reminder_suffix': {
    'ar': '— اذهب ونفّذها 🎉', 'en': "— go do it 🎉", 'am': '— ሂደው ያድርጉት 🎉', 'fr': "— allez-y et faites-le 🎉", 'sw': '— nenda ukafanye 🎉',
    'ur': '— جائیں اور اسے پورا کریں 🎉', 'tr': '— hadi git ve yap 🎉', 'id': '— pergilah dan lakukan 🎉', 'bn': '— যান এবং তা করুন 🎉', 'ha': '— je ka aikata shi 🎉',
    'so': '— tag oo samee 🎉', 'fa': '— برو و انجامش بده 🎉', 'ms': '— pergi dan lakukannya 🎉',
  },
  'remaining_count_prefix': {
    'ar': 'باقي', 'en': 'Remaining:', 'am': 'ቀሪ', 'fr': 'Restant :', 'sw': 'Zilizobaki:',
    'ur': 'باقی', 'tr': 'Kalan:', 'id': 'Sisa:', 'bn': 'বাকি', 'ha': 'Sauran:',
    'so': 'Ku hadhay:', 'fa': 'باقی‌مانده:', 'ms': 'Baki:',
  },
  'ayah_word_label': {
    'ar': 'آية', 'en': 'ayah', 'am': 'አንቀጽ', 'fr': 'verset', 'sw': 'aya',
    'ur': 'آیت', 'tr': 'ayet', 'id': 'ayat', 'bn': 'আয়াত', 'ha': 'aya',
    'so': 'aayad', 'fa': 'آیه', 'ms': 'ayat',
  },
  'to_surah_prefix': {
    'ar': 'إلى سورة', 'en': 'to Surah', 'am': 'እስከ ሱራ', 'fr': "à la sourate", 'sw': 'hadi Sura',
    'ur': 'سورۃ تک', 'tr': "Suresine kadar", 'id': 'hingga Surah', 'bn': 'সূরা পর্যন্ত', 'ha': 'zuwa Suratu',
    'so': 'ilaa Suuradda', 'fa': 'تا سوره', 'ms': 'hingga Surah',
  },
  'rate_your_review_prompt': {
    'ar': 'قيّم مراجعتك:', 'en': 'Rate your review:', 'am': 'ክለሳዎን ይገምግሙ፦', 'fr': 'Évaluez votre révision :', 'sw': 'Kadiria marudio yako:',
    'ur': 'اپنی دہرائی کی درجہ بندی کریں:', 'tr': 'Tekrarınızı değerlendirin:', 'id': 'Nilai ulangan Anda:', 'bn': 'আপনার পুনরাবৃত্তি মূল্যায়ন করুন:', 'ha': 'Kimanta sake-nazarinka:',
    'so': 'Qiimee dib-u-eegistaada:', 'fa': 'مرور خود را ارزیابی کنید:', 'ms': 'Nilai ulangkaji anda:',
  },
  'rating_needs_review': {
    'ar': 'يحتاج مراجعة', 'en': 'Needs Review', 'am': 'ክለሳ ያስፈልገዋል', 'fr': 'Nécessite une révision', 'sw': 'Inahitaji Kupitiwa',
    'ur': 'دہرائی درکار', 'tr': 'Tekrar Gerekli', 'id': 'Perlu Diulang', 'bn': 'পুনরাবৃত্তি প্রয়োজন', 'ha': 'Yana Buƙatar Sake Nazari',
    'so': 'U Baahan Dib-u-eegis', 'fa': 'نیاز به مرور', 'ms': 'Perlu Ulangkaji',
  },
  'rating_good': {
    'ar': 'جيد', 'en': 'Good', 'am': 'ጥሩ', 'fr': 'Bien', 'sw': 'Vizuri',
    'ur': 'اچھا', 'tr': 'İyi', 'id': 'Baik', 'bn': 'ভালো', 'ha': 'Da Kyau',
    'so': 'Wanaagsan', 'fa': 'خوب', 'ms': 'Baik',
  },
  'rating_excellent': {
    'ar': 'ممتاز', 'en': 'Excellent', 'am': 'እጅግ በጣም ጥሩ', 'fr': 'Excellent', 'sw': 'Bora Sana',
    'ur': 'بہترین', 'tr': 'Mükemmel', 'id': 'Sangat Baik', 'bn': 'চমৎকার', 'ha': 'Mafi Kyau',
    'so': 'Aad U Fiican', 'fa': 'عالی', 'ms': 'Cemerlang',
  },
  'review_mistake_note_title': {
    'ar': 'أي خطأ بالذات؟ (اختياري)', 'en': 'Which mistake exactly? (optional)', 'am': 'የትኛው ስህተት በተለይ? (አማራጭ)', 'fr': 'Quelle erreur exactement ? (facultatif)', 'sw': 'Kosa lipi hasa? (si lazima)',
    'ur': 'بالکل کون سی غلطی؟ (اختیاری)', 'tr': 'Tam olarak hangi hata? (isteğe bağlı)', 'id': 'Kesalahan yang mana tepatnya? (opsional)', 'bn': 'ঠিক কোন ভুলটি? (ঐচ্ছিক)', 'ha': 'Wanne kuskure daidai? (na zaɓi)',
    'so': 'Khaladkee sax ah? (ikhtiyaari)', 'fa': 'دقیقاً کدام اشتباه؟ (اختیاری)', 'ms': 'Kesilapan yang mana tepatnya? (pilihan)',
  },
  'review_mistake_note_hint': {
    'ar': 'مثلًا: تعثرت بآية ٥', 'en': 'e.g. I stumbled on ayah 5', 'am': 'ለምሳሌ፦ በአንቀጽ 5 ተደናቀፍኩ', 'fr': "par exemple : j'ai buté sur le verset 5", 'sw': 'k.m.: nilikwazwa aya ya 5',
    'ur': 'مثلاً: میں آیت ٥ پر اٹک گیا', 'tr': 'örneğin: 5. ayette takıldım', 'id': 'misalnya: saya tersendat di ayat 5', 'bn': 'যেমন: আয়াত ৫-এ আটকে গেছি', 'ha': "misali: na tuntuɓe a aya 5",
    'so': 'tusaale ahaan: waxaan ku turunturooday aayadda 5aad', 'fa': 'مثلاً: در آیه ۵ گیر کردم', 'ms': 'contohnya: saya tersekat pada ayat 5',
  },
  'record_action': {
    'ar': 'تسجيل', 'en': 'Record', 'am': 'መዝግብ', 'fr': 'Enregistrer', 'sw': 'Rekodi',
    'ur': 'ریکارڈ کریں', 'tr': 'Kaydet', 'id': 'Catat', 'bn': 'রেকর্ড করুন', 'ha': 'Rubuta',
    'so': 'Diiwaan geli', 'fa': 'ثبت', 'ms': 'Rekod',
  },
  'sabaq_label': {
    'ar': 'سبق', 'en': 'Sabaq', 'am': 'ሰበቅ', 'fr': 'Sabaq', 'sw': 'Sabaq',
    'ur': 'سبق', 'tr': 'Sebak', 'id': 'Sabaq', 'bn': 'সবক', 'ha': 'Sabaƙ',
    'so': 'Sabaq', 'fa': 'سبق', 'ms': 'Sabaq',
  },
  'sabqi_label': {
    'ar': 'سبقي', 'en': 'Sabqi', 'am': 'ሰበቂ', 'fr': 'Sabqi', 'sw': 'Sabqi',
    'ur': 'سبقی', 'tr': 'Sebki', 'id': 'Sabqi', 'bn': 'সবকি', 'ha': 'Sabƙi',
    'so': 'Sabqi', 'fa': 'سبقی', 'ms': 'Sabqi',
  },
  'manzil_label': {
    'ar': 'منزل', 'en': 'Manzil', 'am': 'መንዚል', 'fr': 'Manzil', 'sw': 'Manzil',
    'ur': 'منزل', 'tr': 'Menzil', 'id': 'Manzil', 'bn': 'মানজিল', 'ha': 'Manzil',
    'so': 'Manzil', 'fa': 'منزل', 'ms': 'Manzil',
  },
  // 2026-08-22: command_center_screen.dart.
  'command_center_title': {
    'ar': 'لوحة القيادة', 'en': 'Command Center', 'am': 'የመቆጣጠሪያ ሰሌዳ', 'fr': 'Centre de commande', 'sw': 'Kituo cha Amri',
    'ur': 'کمانڈ سینٹر', 'tr': 'Komuta Merkezi', 'id': 'Pusat Kendali', 'bn': 'কমান্ড সেন্টার', 'ha': 'Cibiyar Umarni',
    'so': 'Xarunta Amarka', 'fa': 'مرکز فرماندهی', 'ms': 'Pusat Arahan',
  },
  'calculating_dashboard_message': {
    'ar': 'جاري حساب لوحتك...', 'en': 'Calculating your dashboard...', 'am': 'ሰሌዳዎን በማስላት ላይ...', 'fr': 'Calcul de votre tableau de bord...', 'sw': 'Inahesabu dashibodi yako...',
    'ur': 'آپ کا ڈیش بورڈ شمار کیا جا رہا ہے...', 'tr': 'Panonuz hesaplanıyor...', 'id': 'Menghitung dasbor Anda...', 'bn': 'আপনার ড্যাশবোর্ড গণনা করা হচ্ছে...', 'ha': 'Ana lissafin dashboard ɗinka...',
    'so': 'Waxaa la xisaabinayaa dashboard-kaaga...', 'fa': 'در حال محاسبه داشبورد شما...', 'ms': 'Mengira papan pemuka anda...',
  },
  'todays_plan_smart_title': {
    'ar': 'خطتك اليوم محسوبة بذكاء', 'en': "Today's Plan, Calculated Smartly", 'am': 'የዛሬው እቅድዎ በብልህነት የተሰላ ነው', 'fr': "Votre plan du jour, calculé intelligemment", 'sw': 'Mpango Wako wa Leo, Umehesabiwa kwa Akili',
    'ur': 'آج کا آپ کا منصوبہ ذہانت سے شمار کیا گیا', 'tr': 'Bugünkü Planınız Akıllıca Hesaplandı', 'id': 'Rencana Hari Ini, Dihitung Secara Cerdas', 'bn': 'আজকের পরিকল্পনা বুদ্ধিমত্তার সাথে গণনা করা হয়েছে', 'ha': 'Tsarin Yau, An Lissafta Shi Da Basira',
    'so': 'Qorshahaaga Maanta, Si Xikmad Leh Loo Xisaabiyay', 'fa': 'برنامه امروز شما، هوشمندانه محاسبه شده', 'ms': 'Rancangan Hari Ini, Dikira Secara Bijak',
  },
  'if_you_allocate_prefix': {
    'ar': 'لو خصصت', 'en': 'If you set aside', 'am': 'ቢመድቡ', 'fr': 'Si vous consacriez', 'sw': 'Ukitenga',
    'ur': 'اگر آپ مختص کریں', 'tr': 'Ayırırsanız', 'id': 'Jika Anda menyisihkan', 'bn': 'আপনি যদি বরাদ্দ করেন', 'ha': 'Idan ka ware',
    'so': 'Haddii aad qoondayso', 'fa': 'اگر اختصاص دهید', 'ms': 'Jika anda memperuntukkan',
  },
  'trial_allocation_suffix': {
    'ar': 'دقيقة اليوم — توزيع تجريبي، لا يُلزمك بشيء', 'en': "minutes today — a trial split, it doesn't commit you to anything", 'am': 'ደቂቃ ዛሬ — የሙከራ ክፍፍል፣ ምንም አያስገድድዎትም', 'fr': "minutes aujourd'hui — une répartition d'essai, qui ne vous engage à rien", 'sw': 'dakika leo — mgao wa majaribio, hauhitaji chochote kwako',
    'ur': 'منٹ آج — ایک آزمائشی تقسیم، جو آپ کو کسی چیز کا پابند نہیں کرتی', 'tr': 'dakika bugün — deneme dağılımı, sizi hiçbir şeye bağlamaz', 'id': 'menit hari ini — pembagian percobaan, tidak mengikat Anda pada apa pun', 'bn': 'মিনিট আজ — একটি ট্রায়াল বণ্টন, যা আপনাকে কিছুতে বাধ্য করে না', 'ha': "minti a yau — rabon gwaji ne, ba ya daure ka da komai",
    'so': 'daqiiqo maanta — qaybin tijaabo ah, kuma qasbayo wax', 'fa': 'دقیقه امروز — یک تقسیم آزمایشی، شما را به چیزی متعهد نمی‌کند', 'ms': 'minit hari ini — pembahagian percubaan, tidak mengikat anda kepada apa-apa',
  },
  'minutes_short_unit': {
    'ar': 'د', 'en': 'min', 'am': 'ደ', 'fr': 'min', 'sw': 'dak',
    'ur': 'من', 'tr': 'dk', 'id': 'mnt', 'bn': 'মিনিট', 'ha': 'min',
    'so': 'daq', 'fa': 'دق', 'ms': 'min',
  },
  'quick_review_note_prefix': {
    'ar': 'زادت مراجعة سريعة لأن لديك', 'en': 'Quick review increased because you have', 'am': 'ፈጣን ክለሳ ጨምሯል ምክንያቱም አለዎት', 'fr': 'La révision rapide a augmenté car vous avez', 'sw': 'Marudio ya haraka yameongezeka kwa sababu una',
    'ur': 'فوری دہرائی بڑھ گئی کیونکہ آپ کے پاس ہے', 'tr': 'Hızlı tekrar arttı çünkü', 'id': 'Ulangan cepat meningkat karena Anda memiliki', 'bn': 'দ্রুত পুনরাবৃত্তি বেড়েছে কারণ আপনার আছে', 'ha': 'Sake-nazari mai sauri ya karu domin kana da',
    'so': 'Dib-u-eegis degdeg ah ayaa kordhay sababtoo ah waxaad haysataa', 'fa': 'مرور سریع افزایش یافت زیرا شما دارید', 'ms': 'Ulangkaji pantas meningkat kerana anda mempunyai',
  },
  'quick_review_note_middle': {
    'ar': 'صفحة قرآن و', 'en': "Qur'an pages and", 'am': 'የቁርኣን ገጾች እና', 'fr': 'pages du Coran et', 'sw': 'kurasa za Qur\'an na',
    'ur': 'قرآن کے صفحات اور', 'tr': "Kur'an sayfası ve", 'id': 'halaman Al-Qur\'an dan', 'bn': 'কুরআনের পাতা এবং', 'ha': "shafukan Alkur'ani da",
    'so': "bogag Qur'aan ah iyo", 'fa': 'صفحه قرآن و', 'ms': 'halaman Al-Quran dan',
  },
  'quick_review_note_suffix': {
    'ar': 'مراجعة معرفية مستحقة اليوم', 'en': 'knowledge reviews due today', 'am': 'ዛሬ የሚገባ የእውቀት ክለሳ', 'fr': "révisions de connaissances dues aujourd'hui", 'sw': 'marudio ya maarifa yanayohitajika leo',
    'ur': 'علمی دہرائیاں آج واجب', 'tr': 'bugün için bilgi tekrarı', 'id': 'ulangan pengetahuan jatuh tempo hari ini', 'bn': 'জ্ঞানভিত্তিক পুনরাবৃত্তি আজ বাকি', 'ha': 'sake-nazarin ilimi da ake bukata yau',
    'so': 'dib-u-eegis aqoon ah oo maanta la sugayo', 'fa': 'مرور دانش که امروز موعد آن است', 'ms': 'ulangkaji pengetahuan perlu dilakukan hari ini',
  },
  'forecast_card_title': {
    'ar': 'توقّع ختمك', 'en': 'Your Completion Forecast', 'am': 'የማጠናቀቂያ ትንበያዎ', 'fr': "Prévision de votre achèvement", 'sw': 'Utabiri wa Kukamilisha Kwako',
    'ur': 'آپ کی تکمیل کی پیشین گوئی', 'tr': 'Tamamlama Tahmininiz', 'id': 'Perkiraan Penyelesaian Anda', 'bn': 'আপনার সমাপ্তির পূর্বাভাস', 'ha': 'Hasashen Kammalawarka',
    'so': 'Saadaasha Dhammaystirkaaga', 'fa': 'پیش‌بینی ختم شما', 'ms': 'Ramalan Penyempurnaan Anda',
  },
  'forecast_insufficient_data_text': {
    'ar': 'بيانات غير كافية بعد لتوقّع موثوق — يحتاج الأمر أيامًا أكثر من الحفظ الفعلي المسجَّل حتى نستطيع بناء توقّع مبني على تاريخك الحقيقي، لا رقم مختلَق.',
    'en': "Not enough data yet for a reliable forecast — it takes more days of actually-recorded memorization before we can build a forecast based on your real history, not a made-up number.",
    'am': 'ለታማኝ ትንበያ በቂ መረጃ የለም — በእውነተኛ ታሪክዎ ላይ የተመሰረተ ትንበያ ልንገነባ እስክንችል ድረስ ተጨማሪ ቀናት ትክክለኛ የተመዘገበ ጥናት ይፈልጋል፣ የተፈጠረ ቁጥር አይደለም።',
    'fr': "Pas encore assez de données pour une prévision fiable — il faut davantage de jours de mémorisation réellement enregistrée avant de pouvoir construire une prévision basée sur votre véritable historique, pas un chiffre inventé.",
    'sw': 'Bado hakuna data ya kutosha kwa utabiri wa kuaminika — inahitaji siku zaidi za kuhifadhi zilizorekodiwa halisi kabla hatujaweza kujenga utabiri unaotegemea historia yako halisi, si nambari iliyobuniwa.',
    'ur': 'قابلِ اعتماد پیشین گوئی کے لیے ابھی کافی ڈیٹا نہیں ہے — اس میں مزید دنوں کی اصل درج شدہ حفظ کی ضرورت ہے تاکہ ہم آپ کی حقیقی تاریخ پر مبنی پیشین گوئی بنا سکیں، نہ کہ گھڑا ہوا نمبر۔',
    'tr': "Güvenilir bir tahmin için henüz yeterli veri yok — gerçek geçmişinize dayalı bir tahmin oluşturabilmemiz için uydurma bir sayı değil, daha fazla gün gerçekten kaydedilmiş ezber gerekiyor.",
    'id': 'Data belum cukup untuk perkiraan yang andal — dibutuhkan lebih banyak hari hafalan yang benar-benar tercatat sebelum kami dapat membangun perkiraan berdasarkan riwayat asli Anda, bukan angka rekaan.',
    'bn': 'নির্ভরযোগ্য পূর্বাভাসের জন্য এখনও পর্যাপ্ত তথ্য নেই — আপনার প্রকৃত ইতিহাসের ভিত্তিতে পূর্বাভাস তৈরি করতে আরও বেশি দিনের প্রকৃতভাবে রেকর্ড করা হিফজ প্রয়োজন, বানানো সংখ্যা নয়।',
    'ha': "Babu isasshen bayanai tukuna don hasashe abin dogaro — yana buƙatar ƙarin kwanaki na haddace da aka rubuta na gaskiya kafin mu iya gina hasashe bisa tarihinka na gaskiya, ba lambar da aka ƙirƙira ba.",
    'so': 'Wali xog kuma filna saadaal la isku halayn karo — waxay u baahan tahay maalmo dheeraad ah oo xifdhin dhab ah oo la diiwaan geliyay ka hor inta aanan dhisin saadaal ku salaysan taariikhdaada dhabta ah, ee aan ahayn tiro la been abuurtay.',
    'fa': 'هنوز داده کافی برای پیش‌بینی قابل اعتماد وجود ندارد — نیاز به روزهای بیشتری از حفظ واقعاً ثبت‌شده است تا بتوانیم پیش‌بینی‌ای بر اساس سابقه واقعی شما بسازیم، نه یک عدد ساختگی.',
    'ms': 'Data belum mencukupi untuk ramalan yang boleh dipercayai — ia memerlukan lebih banyak hari hafalan yang benar-benar direkodkan sebelum kami dapat membina ramalan berdasarkan sejarah sebenar anda, bukan nombor rekaan.',
  },
  'forecast_best_case_label': {
    'ar': 'أفضل حالة', 'en': 'Best Case', 'am': 'ምርጥ ሁኔታ', 'fr': 'Meilleur cas', 'sw': 'Hali Bora Zaidi',
    'ur': 'بہترین صورت', 'tr': 'En İyi Durum', 'id': 'Skenario Terbaik', 'bn': 'সেরা পরিস্থিতি', 'ha': 'Mafi Kyawun Yanayi',
    'so': 'Xaaladda Ugu Wanaagsan', 'fa': 'بهترین حالت', 'ms': 'Senario Terbaik',
  },
  'forecast_expected_label': {
    'ar': 'المتوقَّع', 'en': 'Expected', 'am': 'የሚጠበቀው', 'fr': 'Attendu', 'sw': 'Inayotarajiwa',
    'ur': 'متوقع', 'tr': 'Beklenen', 'id': 'Diperkirakan', 'bn': 'প্রত্যাশিত', 'ha': 'Ake Sa Ran',
    'so': 'La Filayo', 'fa': 'مورد انتظار', 'ms': 'Dijangka',
  },
  'forecast_worst_case_label': {
    'ar': 'أسوأ حالة', 'en': 'Worst Case', 'am': 'መጥፎ ሁኔታ', 'fr': 'Pire cas', 'sw': 'Hali Mbaya Zaidi',
    'ur': 'بدترین صورت', 'tr': 'En Kötü Durum', 'id': 'Skenario Terburuk', 'bn': 'সবচেয়ে খারাপ পরিস্থিতি', 'ha': 'Mafi Munin Yanayi',
    'so': 'Xaaladda Ugu Xun', 'fa': 'بدترین حالت', 'ms': 'Senario Terburuk',
  },
  'forecast_basis_note': {
    'ar': 'مبني على محاكاة لأيام حفظك الحقيقية المسجَّلة فعليًا، لا افتراضًا نظريًا.', 'en': "Based on a simulation of your actually-recorded memorization days, not a theoretical assumption.", 'am': 'በትክክል በተመዘገቡ የጥናት ቀናትዎ ማስመሰያ ላይ የተመሰረተ ነው፣ የንድፈ ሐሳብ ግምት አይደለም።', 'fr': "Basé sur une simulation de vos jours de mémorisation réellement enregistrés, pas une hypothèse théorique.", 'sw': 'Kimejengwa juu ya uigaji wa siku zako halisi za kuhifadhi zilizorekodiwa, si dhana ya kinadharia.',
    'ur': 'یہ آپ کے حقیقی طور پر درج شدہ حفظ کے دنوں کی نقالی پر مبنی ہے، نظریاتی مفروضے پر نہیں۔', 'tr': "Teorik bir varsayım değil, gerçekten kaydedilmiş ezber günlerinizin simülasyonuna dayanır.", 'id': 'Berdasarkan simulasi hari-hari hafalan Anda yang benar-benar tercatat, bukan asumsi teoretis.', 'bn': 'এটি আপনার প্রকৃতভাবে রেকর্ড করা হিফজের দিনগুলোর সিমুলেশনের ওপর ভিত্তি করে তৈরি, তাত্ত্বিক অনুমান নয়।', 'ha': "An gina shi bisa kwaikwayon ainihin kwanakin haddacewarka da aka rubuta, ba zato na ka'ida ba.",
    'so': 'Waxaa lagu dhisay tayaya-simulaysiga maalmaha dhabta ah ee xifdhintaada la diiwaan geliyay, ma aha mala-awaal fikrad ah.', 'fa': 'بر اساس شبیه‌سازی روزهای واقعی حفظ ثبت‌شده شما است، نه یک فرض نظری.', 'ms': 'Berdasarkan simulasi hari hafalan sebenar anda yang direkodkan, bukan andaian teori.',
  },
  'biggest_factor_prefix': {
    'ar': 'أكبر عامل يمكن تحسينه:', 'en': 'Biggest factor you could improve:', 'am': 'ሊያሻሽሉት የሚችሉት ትልቁ ምክንያት፦', 'fr': 'Le plus grand facteur que vous pourriez améliorer :', 'sw': 'Sababu kubwa unayoweza kuboresha:',
    'ur': 'سب سے بڑا عنصر جسے آپ بہتر بنا سکتے ہیں:', 'tr': 'İyileştirebileceğiniz en büyük faktör:', 'id': 'Faktor terbesar yang bisa Anda tingkatkan:', 'bn': 'সবচেয়ে বড় বিষয় যা আপনি উন্নত করতে পারেন:', 'ha': 'Babban abin da za ka iya inganta:',
    'so': 'Arrinta ugu weyn ee aad hagaajin karto:', 'fa': 'بزرگ‌ترین عاملی که می‌توانید بهبود دهید:', 'ms': 'Faktor terbesar yang boleh anda perbaiki:',
  },
  'sensitivity_impact_prefix': {
    'ar': 'قد يقرّب ختمك ~', 'en': 'Could bring your completion closer by ~', 'am': 'ማጠናቀቅዎን በ~ ሊያቀርበው ይችላል', 'fr': 'Pourrait rapprocher votre achèvement de ~', 'sw': 'Inaweza kuleta ukamilishaji wako karibu kwa ~',
    'ur': 'آپ کی تکمیل کو ~ سے قریب لا سکتا ہے', 'tr': 'Tamamlanmanızı ~ kadar yaklaştırabilir', 'id': 'Bisa mendekatkan penyelesaian Anda sekitar ~', 'bn': 'আপনার সমাপ্তিকে ~ কাছে আনতে পারে', 'ha': 'Zai iya kawo kammalawarka kusa da ~',
    'so': 'Wuxuu dhammaystirkaaga u soo dhoweyn karaa ~', 'fa': 'ممکن است ختم شما را حدود ~ نزدیک‌تر کند', 'ms': 'Boleh mendekatkan penyempurnaan anda sekitar ~',
  },
  'sensitivity_impact_suffix': {
    'ar': 'يومًا لو تحسّن هذا العامل تحديدًا', 'en': 'days if specifically this factor improved', 'am': 'ቀናት ይህ ምክንያት በተለይ ቢሻሻል', 'fr': 'jours si spécifiquement ce facteur s\'améliorait', 'sw': 'siku ikiwa sababu hii mahususi ingeboreshwa',
    'ur': 'دن اگر خاص طور پر یہ عنصر بہتر ہو جائے', 'tr': 'gün, özellikle bu faktör iyileşirse', 'id': 'hari jika faktor ini secara khusus membaik', 'bn': 'দিন যদি বিশেষভাবে এই বিষয়টি উন্নত হয়', 'ha': 'kwanaki idan wannan abin musamman ya inganta',
    'so': 'maalin haddii arrintan gaar ahaan hagaagto', 'fa': 'روز اگر دقیقاً همین عامل بهبود یابد', 'ms': 'hari jika faktor ini khususnya bertambah baik',
  },
  'day_word_label': {
    'ar': 'يوم', 'en': 'day(s)', 'am': 'ቀን', 'fr': 'jour(s)', 'sw': 'siku',
    'ur': 'دن', 'tr': 'gün', 'id': 'hari', 'bn': 'দিন', 'ha': 'kwanaki',
    'so': 'maalin', 'fa': 'روز', 'ms': 'hari',
  },
  'quran_mastery_label': {
    'ar': 'إتقان القرآن', 'en': "Qur'an Mastery", 'am': 'የቁርኣን ብቃት', 'fr': 'Maîtrise du Coran', 'sw': 'Umahiri wa Qur\'an',
    'ur': 'قرآن پر مہارت', 'tr': "Kur'an Hakimiyeti", 'id': 'Penguasaan Al-Qur\'an', 'bn': 'কুরআন দক্ষতা', 'ha': "Kwarewar Alkur'ani",
    'so': "Xirfadaha Qur'aanka", 'fa': 'تسلط بر قرآن', 'ms': 'Penguasaan Al-Quran',
  },
  'adhkar_streak_label': {
    'ar': 'استمرارية الأذكار', 'en': 'Adhkar Streak', 'am': 'የአዝካር ተከታታይነት', 'fr': 'Régularité des adhkar', 'sw': 'Mfululizo wa Adhkar',
    'ur': 'اذکار کا تسلسل', 'tr': 'Ezkâr Serisi', 'id': 'Rentetan Dzikir', 'bn': 'আজকার ধারাবাহিকতা', 'ha': 'Jerin Azkari',
    'so': 'Isku-xigxiga Adkaarka', 'fa': 'استمرار اذکار', 'ms': 'Rentetan Zikir',
  },
  'due_knowledge_reviews_label': {
    'ar': 'مراجعات معرفية مستحقة', 'en': 'Knowledge Reviews Due', 'am': 'የሚገባ የእውቀት ክለሳ', 'fr': 'Révisions de connaissances dues', 'sw': 'Marudio ya Maarifa Yanayohitajika',
    'ur': 'واجب علمی دہرائیاں', 'tr': 'Bekleyen Bilgi Tekrarları', 'id': 'Ulangan Pengetahuan Jatuh Tempo', 'bn': 'বাকি জ্ঞানভিত্তিক পুনরাবৃত্তি', 'ha': 'Sake-nazarin Ilimi da Ake Bukata',
    'so': 'Dib-u-eegis Aqoon ah oo Sugaya', 'fa': 'مرور دانش سررسیده', 'ms': 'Ulangkaji Pengetahuan Perlu Dilakukan',
  },
  // 2026-08-22: daily_session_screen.dart — the 6 session-step cards.
  'daily_session_title': {
    'ar': 'جلسة اليوم', 'en': "Today's Session", 'am': 'የዛሬው ክፍለ ጊዜ', 'fr': "Séance du jour", 'sw': 'Kipindi cha Leo',
    'ur': 'آج کا سیشن', 'tr': 'Bugünkü Oturum', 'id': 'Sesi Hari Ini', 'bn': 'আজকের সেশন', 'ha': 'Zaman Yau',
    'so': 'Fadhiga Maanta', 'fa': 'جلسه امروز', 'ms': 'Sesi Hari Ini',
  },
  'guided_session_by_time_action': {
    'ar': 'جلسة موجّهة بالوقت', 'en': 'Time-Guided Session', 'am': 'በጊዜ የተመራ ክፍለ ጊዜ', 'fr': 'Séance guidée par le temps', 'sw': 'Kipindi Kinachoongozwa na Muda',
    'ur': 'وقت کے مطابق رہنمائی شدہ سیشن', 'tr': 'Zamana Göre Yönlendirilen Oturum', 'id': 'Sesi Dipandu Waktu', 'bn': 'সময়-নির্দেশিত সেশন', 'ha': 'Zaman da Aka Jagoranta bisa Lokaci',
    'so': 'Fadhi Waqti ku Hagaya', 'fa': 'جلسه هدایت‌شده با زمان', 'ms': 'Sesi Dipandu Masa',
  },
  'session_all_done_message': {
    'ar': 'أحسنت 🌱 أنجزت جلسة اليوم', 'en': "Well done 🌱 you've completed today's session", 'am': 'መልካም 🌱 የዛሬውን ክፍለ ጊዜ አጠናቀዋል', 'fr': "Bien joué 🌱 vous avez terminé la séance du jour", 'sw': 'Hongera 🌱 umekamilisha kipindi cha leo',
    'ur': 'شاباش 🌱 آپ نے آج کا سیشن مکمل کر لیا', 'tr': 'Aferin 🌱 bugünkü oturumu tamamladınız', 'id': 'Bagus 🌱 Anda telah menyelesaikan sesi hari ini', 'bn': 'সাবাশ 🌱 আপনি আজকের সেশন সম্পন্ন করেছেন', 'ha': 'Madalla 🌱 ka kammala zaman yau',
    'so': 'Waad ku mahadsan tahay 🌱 waad dhammaysay fadhiga maanta', 'fa': 'آفرین 🌱 جلسه امروز را کامل کردید', 'ms': 'Syabas 🌱 anda telah melengkapkan sesi hari ini',
  },
  'step_reading_title': {
    'ar': 'قراءة', 'en': 'Reading', 'am': 'ንባብ', 'fr': 'Lecture', 'sw': 'Kusoma',
    'ur': 'تلاوت', 'tr': 'Okuma', 'id': 'Membaca', 'bn': 'পাঠ', 'ha': 'Karatu',
    'so': 'Akhriska', 'fa': 'خواندن', 'ms': 'Membaca',
  },
  'step_reading_subtitle': {
    'ar': 'اقرأ ولو صفحة واحدة اليوم', 'en': 'Read even just one page today', 'am': 'ዛሬ አንድ ገጽ እንኳ ያንብቡ', 'fr': "Lisez ne serait-ce qu'une page aujourd'hui", 'sw': 'Soma hata ukurasa mmoja leo',
    'ur': 'آج کم از کم ایک صفحہ پڑھیں', 'tr': 'Bugün en az bir sayfa okuyun', 'id': 'Baca setidaknya satu halaman hari ini', 'bn': 'আজ অন্তত একটি পাতা পড়ুন', 'ha': 'Karanta ko da shafi ɗaya a yau',
    'so': 'Akhri ugu yaraan hal bog maanta', 'fa': 'حداقل یک صفحه امروز بخوانید', 'ms': 'Baca sekurang-kurangnya satu halaman hari ini',
  },
  'step_reading_action': {
    'ar': 'أنجزتها', 'en': 'Done', 'am': 'ጨርሻለሁ', 'fr': 'Fait', 'sw': 'Nimekamilisha',
    'ur': 'مکمل کر لیا', 'tr': 'Tamamladım', 'id': 'Selesai', 'bn': 'সম্পন্ন করেছি', 'ha': 'Na Gama',
    'so': 'Waan Dhammeeyay', 'fa': 'انجام دادم', 'ms': 'Selesai',
  },
  'step_new_memo_title': {
    'ar': 'الحفظ الجديد', 'en': 'New Memorization', 'am': 'አዲስ ጥናት', 'fr': 'Nouvelle mémorisation', 'sw': 'Hifadhi Mpya',
    'ur': 'نیا حفظ', 'tr': 'Yeni Ezber', 'id': 'Hafalan Baru', 'bn': 'নতুন হিফজ', 'ha': 'Sabon Haddacewa',
    'so': 'Xifdhinta Cusub', 'fa': 'حفظ جدید', 'ms': 'Hafalan Baharu',
  },
  'step_new_memo_subtitle': {
    'ar': 'احفظ صفحة جديدة أو راجع ما تصفّحته', 'en': 'Memorize a new page or review what you browsed', 'am': 'አዲስ ገጽ ያጥኑ ወይም ያሰሱትን ይከልሱ', 'fr': 'Mémorisez une nouvelle page ou révisez ce que vous avez parcouru', 'sw': 'Hifadhi ukurasa mpya au pitia uliochunguza',
    'ur': 'نیا صفحہ حفظ کریں یا جو دیکھا اسے دہرائیں', 'tr': 'Yeni bir sayfa ezberleyin veya göz attığınızı tekrar edin', 'id': 'Hafalkan halaman baru atau ulangi yang Anda jelajahi', 'bn': 'নতুন পাতা হিফজ করুন বা যা দেখেছেন তা পুনরাবৃত্তি করুন', 'ha': 'Haddace sabon shafi ko sake nazarin abin da ka duba',
    'so': 'Xifdhi bog cusub ama dib-u-eeg waxa aad daalacatay', 'fa': 'صفحه جدیدی حفظ کنید یا آنچه مرور کردید را بازبینی کنید', 'ms': 'Hafal halaman baharu atau ulangkaji apa yang anda semak imbas',
  },
  'step_new_memo_action': {
    'ar': 'تصفّح القرآن', 'en': 'Browse the Qur\'an', 'am': 'ቁርኣንን ያስሱ', 'fr': 'Parcourir le Coran', 'sw': 'Vinjari Qur\'an',
    'ur': 'قرآن دیکھیں', 'tr': "Kur'an'a Göz At", 'id': 'Jelajahi Al-Qur\'an', 'bn': 'কুরআন দেখুন', 'ha': "Bincika Alkur'ani",
    'so': "Daalac Qur'aanka", 'fa': 'مرور قرآن', 'ms': 'Semak Imbas Al-Quran',
  },
  'step_review_subtitle': {
    'ar': 'راجع ما استحق المراجعة اليوم', 'en': "Review what's due today", 'am': 'ዛሬ የሚገባውን ይከልሱ', 'fr': "Révisez ce qui est dû aujourd'hui", 'sw': 'Pitia yaliyostahili leo',
    'ur': 'آج جو دہرانا واجب ہے اسے دہرائیں', 'tr': 'Bugün için gereken tekrarı yapın', 'id': 'Ulangi apa yang jatuh tempo hari ini', 'bn': 'আজ যা বাকি তা পুনরাবৃত্তি করুন', 'ha': 'Sake nazarin abin da ake bukata yau',
    'so': 'Dib-u-eeg waxa maanta la sugayo', 'fa': 'آنچه امروز موعدش رسیده مرور کنید', 'ms': 'Ulangkaji apa yang perlu dilakukan hari ini',
  },
  'step_review_action': {
    'ar': 'ابدأ المراجعة', 'en': 'Start Review', 'am': 'ክለሳ ጀምር', 'fr': 'Commencer la révision', 'sw': 'Anza Kupitia',
    'ur': 'دہرائی شروع کریں', 'tr': 'Tekrara Başla', 'id': 'Mulai Ulangan', 'bn': 'পুনরাবৃত্তি শুরু করুন', 'ha': 'Fara Sake Nazari',
    'so': 'Bilow Dib-u-eegista', 'fa': 'شروع مرور', 'ms': 'Mula Ulangkaji',
  },
  'step_understanding_title': {
    'ar': 'الفهم', 'en': 'Understanding', 'am': 'ግንዛቤ', 'fr': 'Compréhension', 'sw': 'Uelewa',
    'ur': 'فہم', 'tr': 'Anlama', 'id': 'Pemahaman', 'bn': 'বোঝাপড়া', 'ha': 'Fahimta',
    'so': 'Faham', 'fa': 'فهم', 'ms': 'Kefahaman',
  },
  'step_understanding_subtitle': {
    'ar': 'تفسير ما حفظته', 'en': "Tafsir of what you memorized", 'am': 'ያጠኑትን ትርጓሜ', 'fr': 'Tafsir de ce que vous avez mémorisé', 'sw': 'Tafsiri ya ulichohifadhi',
    'ur': 'جو حفظ کیا اس کی تفسیر', 'tr': 'Ezberlediğinizin tefsiri', 'id': 'Tafsir dari yang Anda hafalkan', 'bn': 'যা হিফজ করেছেন তার তাফসীর', 'ha': "Tafsirin abin da ka haddace",
    'so': 'Tafsiirka waxa aad xifdhisay', 'fa': 'تفسیر آنچه حفظ کردید', 'ms': 'Tafsir bagi apa yang anda hafal',
  },
  'step_understanding_action': {
    'ar': 'ابدأ الفهم', 'en': 'Start Understanding', 'am': 'ግንዛቤ ጀምር', 'fr': 'Commencer la compréhension', 'sw': 'Anza Kuelewa',
    'ur': 'فہم شروع کریں', 'tr': 'Anlamaya Başla', 'id': 'Mulai Memahami', 'bn': 'বোঝা শুরু করুন', 'ha': 'Fara Fahimta',
    'so': 'Bilow Fahamka', 'fa': 'شروع فهم', 'ms': 'Mula Memahami',
  },
  'step_application_title': {
    'ar': 'التطبيق 🌱', 'en': 'Application 🌱', 'am': 'ተግባራዊነት 🌱', 'fr': 'Mise en pratique 🌱', 'sw': 'Utekelezaji 🌱',
    'ur': 'اطلاق 🌱', 'tr': 'Uygulama 🌱', 'id': 'Penerapan 🌱', 'bn': 'প্রয়োগ 🌱', 'ha': 'Aiwatarwa 🌱',
    'so': 'Dhaqan-galinta 🌱', 'fa': 'کاربرد 🌱', 'ms': 'Amalan 🌱',
  },
  'step_application_subtitle': {
    'ar': 'درس تطبيقي من محفوظك', 'en': 'A practical lesson from what you memorized', 'am': 'ካጠኑት ተግባራዊ ትምህርት', 'fr': 'Une leçon pratique de ce que vous avez mémorisé', 'sw': 'Somo la vitendo kutoka ulichohifadhi',
    'ur': 'آپ کے حفظ سے ایک عملی سبق', 'tr': 'Ezberinizden pratik bir ders', 'id': 'Pelajaran praktis dari yang Anda hafalkan', 'bn': 'আপনার হিফজ থেকে একটি ব্যবহারিক পাঠ', 'ha': "Darasi na aiki daga abin da ka haddace",
    'so': 'Cashar wax ku ool ah oo ka socda xifdhintaada', 'fa': 'درسی کاربردی از حفظیات شما', 'ms': 'Pelajaran praktikal daripada hafalan anda',
  },
  'step_application_action': {
    'ar': 'درس اليوم', 'en': "Today's Lesson", 'am': 'የዛሬ ትምህርት', 'fr': 'Leçon du jour', 'sw': 'Somo la Leo',
    'ur': 'آج کا سبق', 'tr': 'Bugünkü Ders', 'id': 'Pelajaran Hari Ini', 'bn': 'আজকের পাঠ', 'ha': 'Darasin Yau',
    'so': 'Casharka Maanta', 'fa': 'درس امروز', 'ms': 'Pelajaran Hari Ini',
  },
  'step_quiz_title': {
    'ar': 'اختبر نفسك', 'en': 'Test Yourself', 'am': 'ራስዎን ይፈትሹ', 'fr': 'Testez-vous', 'sw': 'Jijaribu',
    'ur': 'خود کو آزمائیں', 'tr': 'Kendinizi Test Edin', 'id': 'Uji Diri Anda', 'bn': 'নিজেকে পরীক্ষা করুন', 'ha': 'Gwada Kanka',
    'so': 'Isku Tijaabi', 'fa': 'خودت را بیازما', 'ms': 'Uji Diri Anda',
  },
  'step_quiz_subtitle': {
    'ar': 'ما الآية التالية؟', 'en': "What's the next ayah?", 'am': 'ቀጣዩ አንቀጽ ምንድን ነው?', 'fr': 'Quel est le verset suivant ?', 'sw': 'Aya ijayo ni ipi?',
    'ur': 'اگلی آیت کیا ہے؟', 'tr': 'Bir sonraki ayet nedir?', 'id': 'Apa ayat selanjutnya?', 'bn': 'পরবর্তী আয়াত কী?', 'ha': 'Wace aya ce ta gaba?',
    'so': 'Waa maxay aayadda xigta?', 'fa': 'آیه بعدی چیست؟', 'ms': 'Apakah ayat seterusnya?',
  },
  'step_quiz_action': {
    'ar': 'ابدأ', 'en': 'Start', 'am': 'ጀምር', 'fr': 'Commencer', 'sw': 'Anza',
    'ur': 'شروع کریں', 'tr': 'Başla', 'id': 'Mulai', 'bn': 'শুরু করুন', 'ha': 'Fara',
    'so': 'Bilow', 'fa': 'شروع', 'ms': 'Mula',
  },
  // 2026-08-22: completion_goals_screen.dart. Specific book/curriculum
  // titles (Zad al-Ma'ad, Madarij, al-Wasitiyyah, al-Arbain) stay Arabic —
  // proper nouns naming actual classical texts, not UI chrome.
  'completion_goals_title': {
    'ar': 'خطط ختمي', 'en': 'My Completion Plans', 'am': 'የማጠናቀቂያ እቅዶቼ', 'fr': "Mes plans d'achèvement", 'sw': 'Mipango Yangu ya Kukamilisha',
    'ur': 'میرے تکمیل کے منصوبے', 'tr': 'Tamamlama Planlarım', 'id': 'Rencana Khatam Saya', 'bn': 'আমার সমাপ্তি পরিকল্পনা', 'ha': 'Tsare-tsaren Kammalawata',
    'so': 'Qorshayaashayda Dhammaystirka', 'fa': 'برنامه‌های ختم من', 'ms': 'Rancangan Khatam Saya',
  },
  'goal_quran_reading_label': {
    'ar': 'ختمة قراءة القرآن', 'en': "Qur'an Reading Khatma", 'am': 'የቁርኣን ንባብ ኻትማ', 'fr': 'Khatma de lecture du Coran', 'sw': 'Khatma ya Kusoma Qur\'an',
    'ur': 'قرآن پڑھنے کا ختم', 'tr': "Kur'an Okuma Hatmi", 'id': 'Khatam Membaca Al-Qur\'an', 'bn': 'কুরআন পাঠ খতম', 'ha': "Khatmul Karatun Alkur'ani",
    'so': "Khatmiga Akhriska Qur'aanka", 'fa': 'ختم قرائت قرآن', 'ms': 'Khatam Membaca Al-Quran',
  },
  'goal_quran_memorization_label': {
    'ar': 'ختم حفظ القرآن', 'en': "Qur'an Memorization Khatma", 'am': 'የቁርኣን ጥናት ኻትማ', 'fr': 'Khatma de mémorisation du Coran', 'sw': 'Khatma ya Kuhifadhi Qur\'an',
    'ur': 'قرآن حفظ کا ختم', 'tr': "Kur'an Ezber Hatmi", 'id': 'Khatam Hafalan Al-Qur\'an', 'bn': 'কুরআন হিফজ খতম', 'ha': "Khatmul Haddace Alkur'ani",
    'so': "Khatmiga Xifdhinta Qur'aanka", 'fa': 'ختم حفظ قرآن', 'ms': 'Khatam Hafalan Al-Quran',
  },
  'from_my_library_prefix': {
    'ar': 'من مكتبتي:', 'en': 'From my library:', 'am': 'ከቤተ መጻሕፍቴ፦', 'fr': 'De ma bibliothèque :', 'sw': 'Kutoka maktaba yangu:',
    'ur': 'میری لائبریری سے:', 'tr': 'Kütüphanemden:', 'id': 'Dari perpustakaan saya:', 'bn': 'আমার গ্রন্থাগার থেকে:', 'ha': 'Daga laburare na:',
    'so': 'Maktabadayda:', 'fa': 'از کتابخانه من:', 'ms': 'Dari perpustakaan saya:',
  },
  'add_library_book_hint': {
    'ar': 'لإضافة كتاب من مكتبتك: افتحه مرة واحدة من "مكتبتي" أولًا حتى يُعرف عدد صفحاته', 'en': 'To add a book from your library: open it once from "My Library" first so its page count is known', 'am': 'ከቤተ መጻሕፍትዎ መጽሐፍ ለመጨመር፦ የገጽ ብዛቱ እንዲታወቅ መጀመሪያ ከ"ቤተ መጻሕፍቴ" አንድ ጊዜ ይክፈቱት', 'fr': 'Pour ajouter un livre de votre bibliothèque : ouvrez-le une fois depuis "Ma bibliothèque" pour que son nombre de pages soit connu', 'sw': 'Kuongeza kitabu kutoka maktaba yako: kifungue mara moja kutoka "Maktaba Yangu" kwanza ili idadi ya kurasa zake ijulikane',
    'ur': 'اپنی لائبریری سے کتاب شامل کرنے کے لیے: پہلے اسے "میری لائبریری" سے ایک بار کھولیں تاکہ اس کے صفحات کی تعداد معلوم ہو جائے', 'tr': 'Kütüphanenizden bir kitap eklemek için: sayfa sayısının bilinmesi için önce "Kütüphanem"den bir kez açın', 'id': 'Untuk menambahkan buku dari perpustakaan Anda: buka sekali dari "Perpustakaan Saya" dulu agar jumlah halamannya diketahui', 'bn': 'আপনার গ্রন্থাগার থেকে একটি বই যোগ করতে: প্রথমে "আমার গ্রন্থাগার" থেকে একবার খুলুন যাতে এর পাতার সংখ্যা জানা যায়', 'ha': 'Don ƙara littafi daga laburarenka: fara buɗe shi sau ɗaya daga "Laburare Na" don a san adadin shafukansa',
    'so': 'Si aad buug uga darto maktabaddaada: marka hore hal mar ka fur "Maktabadayda" si loo ogaado tirada bogagiisa', 'fa': 'برای افزودن کتابی از کتابخانه‌تان: ابتدا یک‌بار آن را از "کتابخانه من" باز کنید تا تعداد صفحاتش مشخص شود', 'ms': 'Untuk menambah buku daripada perpustakaan anda: buka sekali daripada "Perpustakaan Saya" dahulu supaya bilangan halamannya diketahui',
  },
  'target_date_prefix': {
    'ar': 'الموعد المستهدف:', 'en': 'Target date:', 'am': 'ዒላማ ቀን፦', 'fr': 'Date cible :', 'sw': 'Tarehe lengwa:',
    'ur': 'ہدف کی تاریخ:', 'tr': 'Hedef tarih:', 'id': 'Tanggal target:', 'bn': 'লক্ষ্য তারিখ:', 'ha': 'Ranar Manufa:',
    'so': 'Taariikhda Bartilmaameedka:', 'fa': 'تاریخ هدف:', 'ms': 'Tarikh sasaran:',
  },
  'create_plan_action': {
    'ar': 'إنشاء الخطة', 'en': 'Create Plan', 'am': 'እቅድ ፍጠር', 'fr': 'Créer le plan', 'sw': 'Unda Mpango',
    'ur': 'منصوبہ بنائیں', 'tr': 'Plan Oluştur', 'id': 'Buat Rencana', 'bn': 'পরিকল্পনা তৈরি করুন', 'ha': 'Ƙirƙiri Tsari',
    'so': 'Samee Qorshaha', 'fa': 'ایجاد برنامه', 'ms': 'Cipta Rancangan',
  },
  'new_completion_plan_title': {
    'ar': 'خطة ختم جديدة', 'en': 'New Completion Plan', 'am': 'አዲስ የማጠናቀቂያ እቅድ', 'fr': "Nouveau plan d'achèvement", 'sw': 'Mpango Mpya wa Kukamilisha',
    'ur': 'نیا تکمیل کا منصوبہ', 'tr': 'Yeni Tamamlama Planı', 'id': 'Rencana Khatam Baru', 'bn': 'নতুন সমাপ্তি পরিকল্পনা', 'ha': 'Sabon Tsarin Kammalawa',
    'so': 'Qorshe Dhammaystir Cusub', 'fa': 'برنامه ختم جدید', 'ms': 'Rancangan Khatam Baharu',
  },
  // §2.3 grain 3.1 — the free-text name field's own label.
  'khatm_name_field_label': {
    'ar': 'اسم الختمة', 'en': 'Plan name', 'am': 'የእቅድ ስም', 'fr': 'Nom du plan', 'sw': 'Jina la mpango',
    'ur': 'منصوبے کا نام', 'tr': 'Plan adı', 'id': 'Nama rencana', 'bn': 'পরিকল্পনার নাম', 'ha': 'Sunan tsari',
    'so': 'Magaca qorshaha', 'fa': 'نام برنامه', 'ms': 'Nama rancangan',
  },
  // §2.3 grain 3.1 — the name field's suggested default, composed with
  // today's date: "$khatm_default_name_prefix - <date>".
  'khatm_default_name_prefix': {
    'ar': 'ختمتي', 'en': 'My Khatm', 'am': 'ኸተሜ', 'fr': 'Mon khatm', 'sw': 'Khatm Yangu',
    'ur': 'میرا ختم', 'tr': 'Hatmim', 'id': 'Khatam Saya', 'bn': 'আমার খতম', 'ha': 'Kammalawata',
    'so': 'Khatmkayga', 'fa': 'ختم من', 'ms': 'Khatam Saya',
  },
  // §2.3 field 5, grain "duration stepper" — replaces the raw calendar
  // target-date picker with a day-count label.
  'khatm_duration_field_label': {
    'ar': 'المدة (الأيام)', 'en': 'Duration (days)', 'am': 'ቆይታ (ቀናት)', 'fr': 'Durée (jours)', 'sw': 'Muda (siku)',
    'ur': 'مدت (دن)', 'tr': 'Süre (gün)', 'id': 'Durasi (hari)', 'bn': 'সময়কাল (দিন)', 'ha': 'Tsawon lokaci (kwanaki)',
    'so': 'Muddada (maalmo)', 'fa': 'مدت (روز)', 'ms': 'Tempoh (hari)',
  },
  // §2.3 field 4 — the juz-to-juz RangeSlider's label, quran_reading/
  // quran_memorization only.
  'khatm_range_field_label': {
    'ar': 'نطاق الختمة', 'en': 'Plan range', 'am': 'የእቅድ ወሰን', 'fr': 'Plage du plan', 'sw': 'Wigo wa mpango',
    'ur': 'منصوبے کی حد', 'tr': 'Plan aralığı', 'id': 'Rentang rencana', 'bn': 'পরিকল্পনার পরিসীমা', 'ha': 'Iyakar tsari',
    'so': 'Xudduudka qorshaha', 'fa': 'محدوده برنامه', 'ms': 'Julat rancangan',
  },
  // §2.3 field 3 — the "تحزيب الصحابة" convenience-fill toggle's own label
  // (the ⓘ dialog body itself stays Arabic-only, see `_kTahzeebInfoText`).
  'khatm_tahzeeb_toggle_label': {
    'ar': 'تحزيب الصحابة', 'en': "The Companions' Seven-Day Division", 'am': 'የባልደረቦች ሰባት ቀን ክፍፍል', 'fr': 'Division des Compagnons en sept jours', 'sw': 'Mgawanyo wa Masahaba wa siku saba',
    'ur': 'صحابہ کی سات روزہ تقسیم', 'tr': 'Sahabenin Yedi Günlük Bölümü', 'id': 'Pembagian Tujuh Hari Sahabat', 'bn': 'সাহাবীদের সাত দিনের বিভাজন', 'ha': 'Rabon Sahabbai na kwanaki bakwai',
    'so': 'Qaybinta Toddobaadka ee Saxaabada', 'fa': 'تقسیم هفت‌روزه صحابه', 'ms': 'Pembahagian Tujuh Hari Sahabat',
  },
  'khatm_tahzeeb_info_tooltip': {
    'ar': 'عن تحزيب الصحابة', 'en': "About the Companions' division", 'am': 'ስለ ባልደረቦች ክፍፍል', 'fr': 'À propos de cette division', 'sw': 'Kuhusu mgawanyo huu', 'ur': 'اس تقسیم کے بارے میں', 'tr': 'Bu bölüm hakkında', 'id': 'Tentang pembagian ini', 'bn': 'এই বিভাজন সম্পর্কে', 'ha': 'Game da wannan raba', 'so': 'Ku saabsan qaybintan', 'fa': 'درباره این تقسیم', 'ms': 'Tentang pembahagian ini',
  },
  // §2.3 item 4, "متبقي اليوم" — the goal card's manual page-entry field
  // label. Auto-filled with the mushaf reader's current page when opened
  // from its "الختمات" sheet; blank (typed manually) elsewhere.
  'khatm_record_position_label': {
    'ar': 'سجّل موضعك', 'en': 'Record your position', 'am': 'ቦታዎን ይመዝግቡ', 'fr': 'Enregistrez votre position', 'sw': 'Rekodi nafasi yako',
    'ur': 'اپنی پوزیشن درج کریں', 'tr': 'Konumunuzu kaydedin', 'id': 'Catat posisi Anda', 'bn': 'আপনার অবস্থান রেকর্ড করুন', 'ha': 'Rubuta matsayinka',
    'so': 'Diiwaan geli booskaaga', 'fa': 'موقعیت خود را ثبت کنید', 'ms': 'Rekodkan kedudukan anda',
  },
  'khatm_remaining_today_prefix': {
    'ar': 'متبقي اليوم:', 'en': 'Remaining today:', 'am': 'ዛሬ የቀረው:', 'fr': "Restant aujourd'hui :", 'sw': 'Iliyobaki leo:',
    'ur': 'آج باقی:', 'tr': 'Bugün kalan:', 'id': 'Sisa hari ini:', 'bn': 'আজ বাকি:', 'ha': 'Ragowar yau:',
    'so': 'Maanta ku hadhay:', 'fa': 'باقی‌مانده امروز:', 'ms': 'Baki hari ini:',
  },
  'khatm_completed_today_label': {
    'ar': 'أتممت ورد اليوم ✓', 'en': "Today's portion complete ✓", 'am': 'የዛሬው ድርሻ ተጠናቅቋል ✓', 'fr': "Portion du jour terminée ✓", 'sw': 'Sehemu ya leo imekamilika ✓',
    'ur': 'آج کا حصہ مکمل ✓', 'tr': 'Bugünkü bölüm tamamlandı ✓', 'id': 'Bagian hari ini selesai ✓', 'bn': 'আজকের অংশ সম্পন্ন ✓', 'ha': 'An kammala rabon yau ✓',
    'so': 'Qaybta maanta way dhammaatay ✓', 'fa': 'سهم امروز کامل شد ✓', 'ms': 'Bahagian hari ini selesai ✓',
  },
  // §2.5 — the collapsible 7-werd boundary list's own header/labels.
  'khatm_werd_list_title': {
    // 2026-09-18: was a static "(٧)" — §2.5 is no longer fixed at 7 werds
    // (it now equals the plan's real day count), so the count is appended
    // live in code instead of baked into this string.
    'ar': 'قائمة الأوراد', 'en': 'Portions list', 'am': 'የክፍሎች ዝርዝር', 'fr': 'Liste des portions', 'sw': 'Orodha ya sehemu',
    'ur': 'اوراد کی فہرست', 'tr': 'Bölüm listesi', 'id': 'Daftar bagian', 'bn': 'অংশের তালিকা', 'ha': 'Jerin sassa',
    'so': 'Liiska qaybaha', 'fa': 'فهرست اوراد', 'ms': 'Senarai bahagian',
  },
  'khatm_werd_label': {
    'ar': 'الورد', 'en': 'Portion', 'am': 'ክፍል', 'fr': 'Portion', 'sw': 'Sehemu',
    'ur': 'ورد', 'tr': 'Bölüm', 'id': 'Bagian', 'bn': 'অংশ', 'ha': 'Sashi',
    'so': 'Qayb', 'fa': 'ورد', 'ms': 'Bahagian',
  },
  'khatm_werd_range_to_label': {
    'ar': 'إلى', 'en': 'to', 'am': 'እስከ', 'fr': 'à', 'sw': 'hadi',
    'ur': 'تک', 'tr': 'ile', 'id': 'sampai', 'bn': 'পর্যন্ত', 'ha': 'zuwa',
    'so': 'ilaa', 'fa': 'تا', 'ms': 'hingga',
  },
  // §2.3 field 8 — the wizard's own reminder toggle + time-picker labels.
  'khatm_reminder_toggle_label': {
    'ar': 'وقت التذكير', 'en': 'Reminder time', 'am': 'የማስታወሻ ሰዓት', 'fr': 'Heure du rappel', 'sw': 'Muda wa kikumbusho',
    'ur': 'یاد دہانی کا وقت', 'tr': 'Hatırlatma saati', 'id': 'Waktu pengingat', 'bn': 'রিমাইন্ডার সময়', 'ha': 'Lokacin tunatarwa',
    'so': 'Waqtiga xasuusinta', 'fa': 'زمان یادآوری', 'ms': 'Masa peringatan',
  },
  'khatm_reminder_time_label': {
    'ar': 'الوقت', 'en': 'Time', 'am': 'ሰዓት', 'fr': 'Heure', 'sw': 'Muda',
    'ur': 'وقت', 'tr': 'Saat', 'id': 'Waktu', 'bn': 'সময়', 'ha': 'Lokaci',
    'so': 'Waqtiga', 'fa': 'زمان', 'ms': 'Masa',
  },
  // §2.6 — the goal-identity edit (✎) mini-dialog's title (colour + name +
  // reminder only; range/duration are fixed after creation per the spec).
  'khatm_edit_plan_title': {
    'ar': 'تعديل الختمة', 'en': 'Edit plan', 'am': 'እቅድ አርትዕ', 'fr': 'Modifier le plan', 'sw': 'Hariri mpango',
    'ur': 'منصوبہ میں ترمیم', 'tr': 'Planı düzenle', 'id': 'Edit rencana', 'bn': 'পরিকল্পনা সম্পাদনা', 'ha': 'Gyara tsari',
    'so': 'Wax ka beddel qorshaha', 'fa': 'ویرایش برنامه', 'ms': 'Edit rancangan',
  },
  // §2.3 field 9 — the pre-save confirmation dialog's own strings.
  // §2.3 field 7أ — the "توزيع الورد على الصلوات" session editor.
  'khatm_session_distribution_toggle_label': {
    'ar': 'توزيع الورد على الصلوات', 'en': 'Split across prayer sessions', 'am': 'በጸሎት ክፍለ ጊዜዎች ይከፋፍሉ', 'fr': 'Répartir sur les prières', 'sw': 'Gawanya kwa nyakati za sala',
    'ur': 'نمازوں کے اوقات پر تقسیم کریں', 'tr': 'Namaz vakitlerine böl', 'id': 'Bagi ke sesi salat', 'bn': 'নামাজের সময় অনুযায়ী ভাগ করুন', 'ha': 'Rarraba a kan lokutan sallah',
    'so': 'U qaybi salaadaha', 'fa': 'تقسیم بر اساس اوقات نماز', 'ms': 'Bahagikan mengikut waktu solat',
  },
  'khatm_new_session_default_label': {
    'ar': 'جلسة جديدة', 'en': 'New session', 'am': 'አዲስ ክፍለ ጊዜ', 'fr': 'Nouvelle séance', 'sw': 'Kipindi kipya',
    'ur': 'نیا سیشن', 'tr': 'Yeni oturum', 'id': 'Sesi baru', 'bn': 'নতুন সেশন', 'ha': 'Sabon zama',
    'so': 'Fadhi cusub', 'fa': 'جلسه جدید', 'ms': 'Sesi baharu',
  },
  'khatm_session_pattern_prompt': {
    'ar': 'اختر نمط توزيع الورد على الصلوات:', 'en': 'Choose a session pattern:', 'am': 'የክፍለ ጊዜ ስርዓት ይምረጡ:', 'fr': 'Choisissez un modèle de répartition :', 'sw': 'Chagua mfumo wa vipindi:',
    'ur': 'سیشن پیٹرن منتخب کریں:', 'tr': 'Bir oturum düzeni seçin:', 'id': 'Pilih pola sesi:', 'bn': 'সেশন প্যাটার্ন বেছে নিন:', 'ha': 'Zaɓi tsarin zama:',
    'so': 'Dooro nooca fadhiyada:', 'fa': 'الگوی جلسات را انتخاب کنید:', 'ms': 'Pilih corak sesi:',
  },
  'khatm_pattern_equal_title': {
    'ar': 'متساوٍ تقريبًا', 'en': 'Roughly equal', 'am': 'ግምት ውስጥ እኩል', 'fr': 'Presque égal', 'sw': 'Sawa kiasi',
    'ur': 'تقریباً برابر', 'tr': 'Yaklaşık eşit', 'id': 'Kira-kira sama', 'bn': 'প্রায় সমান', 'ha': 'Kusan daidai',
    'so': 'Ku dhawaad siman', 'fa': 'تقریباً برابر', 'ms': 'Lebih kurang sama',
  },
  'khatm_pattern_focused_title': {
    'ar': 'مُركَّز', 'en': 'Focused', 'am': 'ያተኮረ', 'fr': 'Concentré', 'sw': 'Makini',
    'ur': 'مرکوز', 'tr': 'Odaklı', 'id': 'Terfokus', 'bn': 'কেন্দ্রীভূত', 'ha': 'Mai da hankali',
    'so': 'Diirad saaran', 'fa': 'متمرکز', 'ms': 'Tertumpu',
  },
  'khatm_add_session_action': {
    'ar': 'أضف جلسة', 'en': 'Add session', 'am': 'ክፍለ ጊዜ ጨምር', 'fr': 'Ajouter une séance', 'sw': 'Ongeza kipindi',
    'ur': 'سیشن شامل کریں', 'tr': 'Oturum ekle', 'id': 'Tambah sesi', 'bn': 'সেশন যোগ করুন', 'ha': 'Ƙara zama',
    'so': 'Ku dar fadhi', 'fa': 'افزودن جلسه', 'ms': 'Tambah sesi',
  },
  // §2.5's own "add" label — kept distinct from khatm_add_session_action
  // (§2.3.7أ) since "جلسة"/session and "ورد"/werd are different concepts
  // on the same live card and must never read the same in the UI.
  'khatm_add_werd_action': {
    'ar': 'أضف وردًا', 'en': 'Add portion', 'am': 'ክፍል ጨምር', 'fr': 'Ajouter une portion', 'sw': 'Ongeza sehemu',
    'ur': 'حصہ شامل کریں', 'tr': 'Bölüm ekle', 'id': 'Tambah bagian', 'bn': 'অংশ যোগ করুন', 'ha': 'Ƙara sashe',
    'so': 'Ku dar qayb', 'fa': 'افزودن بخش', 'ms': 'Tambah bahagian',
  },
  'khatm_reset_sessions_action': {
    'ar': 'إعادة الضبط الافتراضي', 'en': 'Reset to default', 'am': 'ወደ ነባሪ መልስ', 'fr': 'Réinitialiser', 'sw': 'Rejesha chaguo-msingi',
    'ur': 'ڈیفالٹ پر بحال کریں', 'tr': 'Varsayılana sıfırla', 'id': 'Kembalikan ke default', 'bn': 'ডিফল্টে পুনরায় সেট করুন', 'ha': 'Mayar da tsoho',
    'so': 'Dib ugu celi caadiga', 'fa': 'بازنشانی پیش‌فرض', 'ms': 'Set semula lalai',
  },
  'khatm_distributed_label': {
    'ar': 'الموزَّع', 'en': 'Distributed', 'am': 'የተከፋፈለ', 'fr': 'Réparti', 'sw': 'Imegawanywa',
    'ur': 'تقسیم شدہ', 'tr': 'Dağıtılan', 'id': 'Terdistribusi', 'bn': 'বিতরণ করা হয়েছে', 'ha': 'An rarraba',
    'so': 'La qaybiyay', 'fa': 'تقسیم‌شده', 'ms': 'Diagihkan',
  },
  'khatm_of_label': {
    'ar': 'من', 'en': 'of', 'am': 'ከ', 'fr': 'sur', 'sw': 'ya',
    'ur': 'میں سے', 'tr': '/', 'id': 'dari', 'bn': 'এর মধ্যে', 'ha': 'daga',
    'so': 'ee', 'fa': 'از', 'ms': 'daripada',
  },
  'khatm_edit_session_title': {
    'ar': 'تعديل الجلسة', 'en': 'Edit session', 'am': 'ክፍለ ጊዜ አርትዕ', 'fr': 'Modifier la séance', 'sw': 'Hariri kipindi',
    'ur': 'سیشن میں ترمیم', 'tr': 'Oturumu düzenle', 'id': 'Edit sesi', 'bn': 'সেশন সম্পাদনা', 'ha': 'Gyara zama',
    'so': 'Wax ka beddel fadhiga', 'fa': 'ویرایش جلسه', 'ms': 'Edit sesi',
  },
  'khatm_session_label_field': {
    'ar': 'اسم الجلسة', 'en': 'Session name', 'am': 'የክፍለ ጊዜ ስም', 'fr': 'Nom de la séance', 'sw': 'Jina la kipindi',
    'ur': 'سیشن کا نام', 'tr': 'Oturum adı', 'id': 'Nama sesi', 'bn': 'সেশনের নাম', 'ha': 'Sunan zama',
    'so': 'Magaca fadhiga', 'fa': 'نام جلسه', 'ms': 'Nama sesi',
  },
  // §2.5's own edit-sheet title/field-label — kept distinct from the
  // §2.3.7أ session versions above for the same reason as
  // khatm_add_werd_action (a "ورد" is not a "جلسة").
  'khatm_edit_werd_title': {
    'ar': 'تعديل الورد', 'en': 'Edit portion', 'am': 'ክፍል አርትዕ', 'fr': 'Modifier la portion', 'sw': 'Hariri sehemu',
    'ur': 'حصے میں ترمیم', 'tr': 'Bölümü düzenle', 'id': 'Edit bagian', 'bn': 'অংশ সম্পাদনা', 'ha': 'Gyara sashe',
    'so': 'Wax ka beddel qaybta', 'fa': 'ویرایش بخش', 'ms': 'Edit bahagian',
  },
  'khatm_werd_label_field': {
    'ar': 'اسم الورد', 'en': 'Portion name', 'am': 'የክፍል ስም', 'fr': 'Nom de la portion', 'sw': 'Jina la sehemu',
    'ur': 'حصے کا نام', 'tr': 'Bölüm adı', 'id': 'Nama bagian', 'bn': 'অংশের নাম', 'ha': 'Sunan sashe',
    'so': 'Magaca qaybta', 'fa': 'نام بخش', 'ms': 'Nama bahagian',
  },
  'khatm_anchor_prayer_option': {
    'ar': 'مرتبط بصلاة', 'en': 'Prayer-linked', 'am': 'ከጸሎት ጋር የተያያዘ', 'fr': 'Lié à une prière', 'sw': 'Imeunganishwa na sala',
    'ur': 'نماز سے منسلک', 'tr': 'Namaza bağlı', 'id': 'Terkait salat', 'bn': 'নামাজের সাথে যুক্ত', 'ha': 'An haɗa da sallah',
    'so': 'Ku xiran salaadda', 'fa': 'مرتبط با نماز', 'ms': 'Berkaitan solat',
  },
  'khatm_anchor_fixed_option': {
    'ar': 'وقت مخصّص', 'en': 'Fixed time', 'am': 'የተወሰነ ሰዓት', 'fr': 'Heure fixe', 'sw': 'Muda maalum',
    'ur': 'مخصوص وقت', 'tr': 'Sabit saat', 'id': 'Waktu tetap', 'bn': 'নির্দিষ্ট সময়', 'ha': 'Lokaci na musamman',
    'so': 'Waqti go\'an', 'fa': 'زمان مشخص', 'ms': 'Masa tetap',
  },
  'khatm_offset_label': {
    'ar': 'الإزاحة', 'en': 'Offset', 'am': 'መፈናቀል', 'fr': 'Décalage', 'sw': 'Mtengano',
    'ur': 'آفسیٹ', 'tr': 'Kaydırma', 'id': 'Selisih waktu', 'bn': 'অফসেট', 'ha': 'Bambanci',
    'so': 'Duruf', 'fa': 'انحراف زمانی', 'ms': 'Ofset',
  },
  'khatm_session_units_label': {
    'ar': 'عدد الصفحات', 'en': 'Page count', 'am': 'የገጾች ብዛት', 'fr': 'Nombre de pages', 'sw': 'Idadi ya kurasa',
    'ur': 'صفحات کی تعداد', 'tr': 'Sayfa sayısı', 'id': 'Jumlah halaman', 'bn': 'পৃষ্ঠার সংখ্যা', 'ha': 'Yawan shafuka',
    'so': 'Tirada boggagga', 'fa': 'تعداد صفحات', 'ms': 'Bilangan halaman',
  },
  'minute_short_label': {
    'ar': 'د', 'en': 'min', 'am': 'ደቂቃ', 'fr': 'min', 'sw': 'dak',
    'ur': 'منٹ', 'tr': 'dk', 'id': 'mnt', 'bn': 'মিনিট', 'ha': 'min',
    'so': 'daq', 'fa': 'دقیقه', 'ms': 'min',
  },
  'khatm_confirm_dialog_title': {
    'ar': 'تأكيد إنشاء الختمة', 'en': 'Confirm plan', 'am': 'እቅድ ያረጋግጡ', 'fr': 'Confirmer le plan', 'sw': 'Thibitisha mpango',
    'ur': 'منصوبے کی تصدیق کریں', 'tr': 'Planı onayla', 'id': 'Konfirmasi rencana', 'bn': 'পরিকল্পনা নিশ্চিত করুন', 'ha': 'Tabbatar da tsari',
    'so': 'Xaqiiji qorshaha', 'fa': 'تأیید برنامه', 'ms': 'Sahkan rancangan',
  },
  'khatm_confirm_question': {
    'ar': 'هل أنت متأكد من إنشاء هذه الختمة؟', 'en': 'Create this plan?', 'am': 'ይህ እቅድ ይፈጠር?', 'fr': 'Créer ce plan ?', 'sw': 'Unda mpango huu?',
    'ur': 'کیا یہ منصوبہ بنایا جائے؟', 'tr': 'Bu plan oluşturulsun mu?', 'id': 'Buat rencana ini?', 'bn': 'এই পরিকল্পনা তৈরি করবেন?', 'ha': 'Ƙirƙiri wannan tsari?',
    'so': 'Ma abuurtaa qorshahan?', 'fa': 'این برنامه ساخته شود؟', 'ms': 'Cipta rancangan ini?',
  },
  'khatm_confirm_start_label': {
    'ar': 'البداية', 'en': 'Start', 'am': 'መጀመሪያ', 'fr': 'Début', 'sw': 'Mwanzo',
    'ur': 'آغاز', 'tr': 'Başlangıç', 'id': 'Mulai', 'bn': 'শুরু', 'ha': 'Farawa',
    'so': 'Bilowga', 'fa': 'شروع', 'ms': 'Mula',
  },
  'khatm_confirm_end_label': {
    'ar': 'النهاية (المتوقَّعة)', 'en': 'End (expected)', 'am': 'መጨረሻ (የሚጠበቅ)', 'fr': 'Fin (prévue)', 'sw': 'Mwisho (unaotarajiwa)',
    'ur': 'اختتام (متوقع)', 'tr': 'Bitiş (tahmini)', 'id': 'Selesai (perkiraan)', 'bn': 'শেষ (প্রত্যাশিত)', 'ha': 'Ƙarshe (ana tsammani)',
    'so': 'Dhammaad (la filayo)', 'fa': 'پایان (تخمینی)', 'ms': 'Tamat (dijangka)',
  },
  'khatm_confirm_daily_label': {
    'ar': 'المعدّل اليومي', 'en': 'Daily rate', 'am': 'ዕለታዊ መጠን', 'fr': 'Rythme quotidien', 'sw': 'Kiwango cha kila siku',
    'ur': 'روزانہ کی شرح', 'tr': 'Günlük oran', 'id': 'Tingkat harian', 'bn': 'দৈনিক হার', 'ha': 'Adadin yau da kullum',
    'so': 'Heerka maalinlaha ah', 'fa': 'نرخ روزانه', 'ms': 'Kadar harian',
  },
  'reminder_off_label': {
    'ar': 'متوقف', 'en': 'Off', 'am': 'ጠፍቷል', 'fr': 'Désactivé', 'sw': 'Imezimwa',
    'ur': 'بند', 'tr': 'Kapalı', 'id': 'Nonaktif', 'bn': 'বন্ধ', 'ha': 'A kashe',
    'so': 'Damban', 'fa': 'خاموش', 'ms': 'Mati',
  },
  'delete_plan_title': {
    'ar': 'مسح الخطة؟', 'en': 'Delete this plan?', 'am': 'እቅዱን ይሰርዙ?', 'fr': 'Supprimer ce plan ?', 'sw': 'Futa mpango huu?',
    'ur': 'کیا یہ منصوبہ حذف کریں؟', 'tr': 'Bu plan silinsin mi?', 'id': 'Hapus rencana ini?', 'bn': 'এই পরিকল্পনা মুছবেন?', 'ha': 'Share wannan tsari?',
    'so': 'Ma tirtirtaa qorshahan?', 'fa': 'این برنامه حذف شود؟', 'ms': 'Padam rancangan ini?',
  },
  'delete_plan_confirm_prefix': {
    'ar': 'سيُمسح', 'en': 'This will delete', 'am': 'ይህ ይሰርዛል', 'fr': 'Ceci supprimera', 'sw': 'Hii itafuta',
    'ur': 'یہ حذف کر دے گا', 'tr': 'Bu silecek:', 'id': 'Ini akan menghapus', 'bn': 'এটি মুছে ফেলবে', 'ha': 'Wannan zai share',
    'so': 'Tan waxay tirtiri doontaa', 'fa': 'این کار حذف می‌کند', 'ms': 'Ini akan memadam',
  },
  'delete_plan_confirm_suffix': {
    'ar': 'ولن تُذكَّر بها بعد الآن. تقدّمك المُسجَّل لن يتأثر — يمكنك إنشاء خطة جديدة في أي وقت.', 'en': "and you won't be reminded of it anymore. Your recorded progress won't be affected — you can create a new plan anytime.", 'am': 'እና ከእንግዲህ አይታወሱም። የተመዘገበ እድገትዎ አይነካም — በማንኛውም ጊዜ አዲስ እቅድ መፍጠር ይችላሉ።', 'fr': "et vous ne recevrez plus de rappels à ce sujet. Votre progression enregistrée ne sera pas affectée — vous pouvez créer un nouveau plan à tout moment.", 'sw': 'na hutakumbushwa tena kuihusu. Maendeleo yako yaliyorekodiwa hayataathiriwa — unaweza kuunda mpango mpya wakati wowote.',
    'ur': 'اور اب آپ کو اس کی یاد نہیں دلائی جائے گی۔ آپ کی درج شدہ پیشرفت متاثر نہیں ہوگی — آپ کسی بھی وقت نیا منصوبہ بنا سکتے ہیں۔', 'tr': 've artık bu konuda hatırlatılmayacaksınız. Kayıtlı ilerlemeniz etkilenmeyecek — istediğiniz zaman yeni bir plan oluşturabilirsiniz.', 'id': 'dan Anda tidak akan diingatkan lagi tentangnya. Kemajuan tercatat Anda tidak akan terpengaruh — Anda dapat membuat rencana baru kapan saja.', 'bn': 'এবং আপনাকে আর এর কথা মনে করিয়ে দেওয়া হবে না। আপনার রেকর্ড করা অগ্রগতি প্রভাবিত হবে না — আপনি যেকোনো সময় নতুন পরিকল্পনা তৈরি করতে পারেন।', 'ha': 'kuma ba za a ƙara tunatar da kai da shi ba. Ci gaban ka da aka rubuta ba zai shafa ba — za ka iya ƙirƙirar sabon tsari a kowane lokaci.',
    'so': 'mana ku xasuusin doono mar dambe. Horumarkaaga la diiwaan geliyay ma saameyn doono — waqti kasta waxaad samayn kartaa qorshe cusub.', 'fa': 'و دیگر به شما یادآوری نخواهد شد. پیشرفت ثبت‌شده شما تحت تأثیر قرار نمی‌گیرد — می‌توانید هر زمان برنامه جدیدی ایجاد کنید.', 'ms': 'dan anda tidak akan diingatkan lagi mengenainya. Kemajuan direkodkan anda tidak akan terjejas — anda boleh mencipta rancangan baharu pada bila-bila masa.',
  },
  'no_active_plans_message': {
    'ar': 'لا توجد خطط نشطة — أنشئ خطة جديدة بالزر أسفل الشاشة', 'en': 'No active plans — create a new one with the button below', 'am': 'ንቁ እቅድ የለም — ከታች ባለው ቁልፍ አዲስ እቅድ ይፍጠሩ', 'fr': "Aucun plan actif — créez-en un nouveau avec le bouton ci-dessous", 'sw': 'Hakuna mipango hai — unda mpya kwa kitufe kilicho chini',
    'ur': 'کوئی فعال منصوبہ نہیں — نیچے دیے گئے بٹن سے نیا بنائیں', 'tr': 'Aktif plan yok — aşağıdaki düğmeyle yeni bir tane oluşturun', 'id': 'Tidak ada rencana aktif — buat yang baru dengan tombol di bawah', 'bn': 'কোনো সক্রিয় পরিকল্পনা নেই — নিচের বোতাম দিয়ে নতুন তৈরি করুন', 'ha': 'Babu tsare-tsare masu aiki — ƙirƙiri sabo da maɓallin ƙasa',
    'so': 'Ma jiraan qorshayaal firfircoon — mid cusub ku samee badhanka hoose', 'fa': 'هیچ برنامه فعالی نیست — با دکمه پایین یکی جدید بسازید', 'ms': 'Tiada rancangan aktif — cipta yang baharu dengan butang di bawah',
  },
  'ahead_of_plan_badge': {
    'ar': 'متقدم عن الخطة 🌱', 'en': 'Ahead of plan 🌱', 'am': 'ከእቅድ ቀድሞ 🌱', 'fr': "En avance sur le plan 🌱", 'sw': 'Umetangulia mpango 🌱',
    'ur': 'منصوبے سے آگے 🌱', 'tr': 'Plandan önde 🌱', 'id': 'Lebih cepat dari rencana 🌱', 'bn': 'পরিকল্পনার চেয়ে এগিয়ে 🌱', 'ha': 'Gaba da Tsari 🌱',
    'so': 'Ka Horreeya Qorshaha 🌱', 'fa': 'جلوتر از برنامه 🌱', 'ms': 'Mendahului rancangan 🌱',
  },
  'on_track_badge': {
    'ar': 'بالضبط حسب الخطة', 'en': 'Exactly on track', 'am': 'በትክክል በእቅዱ መሠረት', 'fr': "Exactement selon le plan", 'sw': 'Sawasawa na mpango',
    'ur': 'بالکل منصوبے کے مطابق', 'tr': 'Tam olarak plana göre', 'id': 'Persis sesuai rencana', 'bn': 'ঠিক পরিকল্পনা অনুযায়ী', 'ha': 'Daidai da Tsari',
    'so': 'Si Sax ah U Socda Qorshaha', 'fa': 'دقیقاً طبق برنامه', 'ms': 'Tepat mengikut rancangan',
  },
  'behind_plan_badge': {
    'ar': 'متأخر قليلًا عن الخطة', 'en': 'A bit behind plan', 'am': 'ከእቅድ ትንሽ ወደኋላ', 'fr': "Un peu en retard sur le plan", 'sw': 'Umechelewa kidogo kwenye mpango',
    'ur': 'منصوبے سے تھوڑا پیچھے', 'tr': 'Plandan biraz geride', 'id': 'Sedikit tertinggal dari rencana', 'bn': 'পরিকল্পনার চেয়ে সামান্য পিছিয়ে', 'ha': 'Kadan a Baya da Tsari',
    'so': 'Wax Yar Ka Dib Maray Qorshaha', 'fa': 'کمی عقب‌تر از برنامه', 'ms': 'Sedikit ketinggalan daripada rancangan',
  },
  'days_left_rate_message_prefix': {
    'ar': 'باقي', 'en': 'Remaining:', 'am': 'ቀሪ', 'fr': 'Restant :', 'sw': 'Zilizobaki:',
    'ur': 'باقی', 'tr': 'Kalan:', 'id': 'Sisa:', 'bn': 'বাকি', 'ha': 'Sauran:',
    'so': 'Ku hadhay:', 'fa': 'باقی‌مانده:', 'ms': 'Baki:',
  },
  'days_left_rate_message_suffix': {
    'ar': 'بمعدل', 'en': 'at a rate of', 'am': 'በመጠን', 'fr': 'à un rythme de', 'sw': 'kwa kiwango cha',
    'ur': 'بمعدل', 'tr': 'oranında', 'id': 'dengan laju', 'bn': 'হারে', 'ha': 'a kan adadin',
    'so': 'heerka', 'fa': 'با نرخ', 'ms': 'pada kadar',
  },
  'daily_to_finish_on_time_suffix': {
    'ar': 'يوميًا لإتمامها بالموعد', 'en': 'daily to finish on time', 'am': 'በየቀኑ በጊዜው ለማጠናቀቅ', 'fr': "par jour pour terminer à temps", 'sw': 'kila siku ili kumaliza kwa wakati',
    'ur': 'روزانہ وقت پر مکمل کرنے کے لیے', 'tr': 'zamanında bitirmek için günlük', 'id': 'setiap hari untuk selesai tepat waktu', 'bn': 'প্রতিদিন সময়মতো শেষ করতে', 'ha': 'kullum don kammalawa a kan lokaci',
    'so': 'maalin kasta si loogu dhammeeyo waqtiga', 'fa': 'روزانه برای اتمام به‌موقع', 'ms': 'setiap hari untuk selesai tepat masa',
  },
  'target_date_passed_message': {
    'ar': 'انتهى الموعد المستهدف', 'en': 'Target date has passed', 'am': 'ዒላማ ቀኑ አልፏል', 'fr': 'La date cible est passée', 'sw': 'Tarehe lengwa imepita',
    'ur': 'ہدف کی تاریخ گزر چکی ہے', 'tr': 'Hedef tarih geçti', 'id': 'Tanggal target telah berlalu', 'bn': 'লক্ষ্য তারিখ পার হয়ে গেছে', 'ha': 'Ranar Manufa Ta Wuce',
    'so': 'Taariikhda Bartilmaameedku Way Dhaafeen', 'fa': 'تاریخ هدف گذشته است', 'ms': 'Tarikh sasaran telah berlalu',
  },
  'reschedule_plan_action': {
    'ar': 'أعِد جدولة الخطة', 'en': 'Reschedule Plan', 'am': 'እቅድ እንደገና ያስይዙ', 'fr': 'Replanifier le plan', 'sw': 'Panga Upya Mpango',
    'ur': 'منصوبہ دوبارہ ترتیب دیں', 'tr': 'Planı Yeniden Zamanla', 'id': 'Jadwalkan Ulang Rencana', 'bn': 'পরিকল্পনা পুনঃনির্ধারণ করুন', 'ha': 'Sake Tsara Tsari',
    'so': 'Dib u Jadwali Qorshaha', 'fa': 'زمان‌بندی مجدد برنامه', 'ms': 'Jadual Semula Rancangan',
  },
  'delete_plan_action': {
    'ar': 'مسح الخطة', 'en': 'Delete Plan', 'am': 'እቅድ ሰርዝ', 'fr': 'Supprimer le plan', 'sw': 'Futa Mpango',
    'ur': 'منصوبہ حذف کریں', 'tr': 'Planı Sil', 'id': 'Hapus Rencana', 'bn': 'পরিকল্পনা মুছুন', 'ha': 'Share Tsari',
    'so': 'Tirtir Qorshaha', 'fa': 'حذف برنامه', 'ms': 'Padam Rancangan',
  },
  'deleted_library_book_label': {
    'ar': 'كتاب محذوف من مكتبتي', 'en': 'A book deleted from my library', 'am': 'ከቤተ መጻሕፍቴ የተሰረዘ መጽሐፍ', 'fr': 'Un livre supprimé de ma bibliothèque', 'sw': 'Kitabu kilichofutwa kutoka maktaba yangu',
    'ur': 'میری لائبریری سے حذف شدہ کتاب', 'tr': 'Kütüphanemden silinen bir kitap', 'id': 'Buku yang dihapus dari perpustakaan saya', 'bn': 'আমার গ্রন্থাগার থেকে মোছা একটি বই', 'ha': 'Littafi da aka share daga laburare na',
    'so': 'Buug laga tirtiray maktabadayda', 'fa': 'کتابی که از کتابخانه من حذف شده', 'ms': 'Buku dipadam daripada perpustakaan saya',
  },
  // 2026-08-22: shared subject-area labels (placement_repository.dart) +
  // mission_screen.dart. quran/adhkar reuse consistency_quran_label /
  // consistency_dhikr_label already added for worship_coach_screen.dart.
  'subject_hadith_label': {
    'ar': 'الحديث', 'en': 'Hadith', 'am': 'ሐዲስ', 'fr': 'Le hadith', 'sw': 'Hadithi',
    'ur': 'حدیث', 'tr': 'Hadis', 'id': 'Hadits', 'bn': 'হাদিস', 'ha': 'Hadisi',
    'so': 'Xadiiska', 'fa': 'حدیث', 'ms': 'Hadis',
  },
  'subject_aqeedah_label': {
    'ar': 'العقيدة', 'en': 'Aqeedah', 'am': 'ዐቂዳ', 'fr': "L'aqida", 'sw': 'Aqidah',
    'ur': 'عقیدہ', 'tr': 'Akide', 'id': 'Akidah', 'bn': 'আকিদা', 'ha': 'Akida',
    'so': 'Caqiidada', 'fa': 'عقیده', 'ms': 'Akidah',
  },
  'subject_arabic_label': {
    'ar': 'العربية', 'en': 'Arabic', 'am': 'ዐረብኛ', 'fr': 'Arabe', 'sw': 'Kiarabu',
    'ur': 'عربی', 'tr': 'Arapça', 'id': 'Bahasa Arab', 'bn': 'আরবি', 'ha': 'Larabci',
    'so': 'Carabi', 'fa': 'عربی', 'ms': 'Bahasa Arab',
  },
  'subject_tajweed_label': {
    'ar': 'التجويد', 'en': 'Tajweed', 'am': 'ተጅዊድ', 'fr': 'Le tajwid', 'sw': 'Tajwid',
    'ur': 'تجوید', 'tr': 'Tecvid', 'id': 'Tajwid', 'bn': 'তাজবিদ', 'ha': 'Tajwidi',
    'so': 'Tajwiidka', 'fa': 'تجوید', 'ms': 'Tajwid',
  },
  'mission_title': {
    'ar': 'رسالتي', 'en': 'My Mission', 'am': 'ተልእኮዬ', 'fr': 'Ma mission', 'sw': 'Dhamira Yangu',
    'ur': 'میرا مشن', 'tr': 'Görevim', 'id': 'Misi Saya', 'bn': 'আমার মিশন', 'ha': 'Manufata',
    'so': 'Hawshayda', 'fa': 'مأموریت من', 'ms': 'Misi Saya',
  },
  'level_beginner_label': {
    'ar': 'مبتدئ', 'en': 'Beginner', 'am': 'ጀማሪ', 'fr': 'Débutant', 'sw': 'Mwanzo',
    'ur': 'ابتدائی', 'tr': 'Başlangıç', 'id': 'Pemula', 'bn': 'শিক্ষানবিশ', 'ha': 'Mai Farawa',
    'so': 'Bilowga', 'fa': 'مبتدی', 'ms': 'Permulaan',
  },
  'level_intermediate_label': {
    'ar': 'متوسط', 'en': 'Intermediate', 'am': 'መካከለኛ', 'fr': 'Intermédiaire', 'sw': 'Wastani',
    'ur': 'درمیانہ', 'tr': 'Orta', 'id': 'Menengah', 'bn': 'মধ্যম', 'ha': 'Matsakaici',
    'so': 'Dhexdhexaad', 'fa': 'متوسط', 'ms': 'Pertengahan',
  },
  'level_advanced_label': {
    'ar': 'متقدم', 'en': 'Advanced', 'am': 'ከፍተኛ', 'fr': 'Avancé', 'sw': 'Juu',
    'ur': 'اعلی درجہ', 'tr': 'İleri', 'id': 'Mahir', 'bn': 'উন্নত', 'ha': 'Mafi Gaba',
    'so': 'Sare', 'fa': 'پیشرفته', 'ms': 'Mahir',
  },
  'previous_step_action': {
    'ar': 'السابق', 'en': 'Previous', 'am': 'የቀድሞው', 'fr': 'Précédent', 'sw': 'Iliyotangulia',
    'ur': 'پچھلا', 'tr': 'Önceki', 'id': 'Sebelumnya', 'bn': 'পূর্ববর্তী', 'ha': 'Na Baya',
    'so': 'Kii Hore', 'fa': 'قبلی', 'ms': 'Sebelumnya',
  },
  'next_step_action': {
    'ar': 'التالي', 'en': 'Next', 'am': 'ቀጣይ', 'fr': 'Suivant', 'sw': 'Ifuatayo',
    'ur': 'اگلا', 'tr': 'İleri', 'id': 'Selanjutnya', 'bn': 'পরবর্তী', 'ha': 'Na Gaba',
    'so': 'Xiga', 'fa': 'بعدی', 'ms': 'Seterusnya',
  },
  'show_my_map_action': {
    'ar': 'أظهر خريطتي', 'en': 'Show My Map', 'am': 'ካርታዬን አሳይ', 'fr': 'Afficher ma carte', 'sw': 'Onyesha Ramani Yangu',
    'ur': 'میرا نقشہ دکھائیں', 'tr': 'Haritamı Göster', 'id': 'Tampilkan Peta Saya', 'bn': 'আমার মানচিত্র দেখান', 'ha': 'Nuna Taswirata',
    'so': 'Tus Khariidaddayda', 'fa': 'نقشه من را نشان بده', 'ms': 'Tunjukkan Peta Saya',
  },
  'mission_interest_step_title': {
    'ar': 'ماذا تحب أن تتعلم أكثر؟', 'en': 'What do you enjoy learning most?', 'am': 'በጣም ማጥናት የሚወዱት ምንድን ነው?', 'fr': "Qu'aimez-vous apprendre le plus ?", 'sw': 'Ni nini unachopenda kujifunza zaidi?',
    'ur': 'آپ سب سے زیادہ کیا سیکھنا پسند کرتے ہیں؟', 'tr': 'En çok neyi öğrenmeyi seviyorsunuz?', 'id': 'Apa yang paling Anda sukai untuk dipelajari?', 'bn': 'আপনি সবচেয়ে বেশি কী শিখতে ভালোবাসেন?', 'ha': 'Wane abu ka fi so ka koya?',
    'so': 'Muxuu yahay waxa aad ugu jeceshahay inaad barato?', 'fa': 'بیشتر از همه علاقه‌مند به یادگیری چه چیزی هستید؟', 'ms': 'Apakah yang paling anda gemari untuk dipelajari?',
  },
  'mission_rating_step_title': {
    'ar': 'قيّم نفسك في كل مجال (تصريح ذاتي فقط)', 'en': 'Rate yourself in each area (self-reported only)', 'am': 'በእያንዳንዱ ዘርፍ ራስዎን ይገምግሙ (እራስ-ሪፖርት ብቻ)', 'fr': 'Évaluez-vous dans chaque domaine (auto-déclaration uniquement)', 'sw': 'Jipime katika kila eneo (ni taarifa binafsi tu)',
    'ur': 'ہر شعبے میں خود کو پرکھیں (صرف خود بیانی)', 'tr': 'Her alanda kendinizi değerlendirin (yalnızca kendi beyanınız)', 'id': 'Nilai diri Anda di setiap bidang (hanya laporan mandiri)', 'bn': 'প্রতিটি ক্ষেত্রে নিজেকে মূল্যায়ন করুন (শুধুমাত্র স্ব-প্রতিবেদন)', 'ha': 'Kimanta kanka a kowane fanni (bayani na kanka kawai)',
    'so': 'Isqiimee qayb kasta (waa oo qudha sheegasho naftaada)', 'fa': 'در هر حوزه خودتان را ارزیابی کنید (فقط گزارش شخصی)', 'ms': 'Nilai diri anda dalam setiap bidang (laporan sendiri sahaja)',
  },
  'mission_minutes_step_title': {
    'ar': 'كم دقيقة تستطيع التعلّم يوميًا؟', 'en': 'How many minutes can you learn daily?', 'am': 'በየቀኑ ስንት ደቂቃ ማጥናት ይችላሉ?', 'fr': 'Combien de minutes pouvez-vous apprendre par jour ?', 'sw': 'Unaweza kujifunza dakika ngapi kila siku?',
    'ur': 'آپ روزانہ کتنے منٹ سیکھ سکتے ہیں؟', 'tr': 'Günde kaç dakika öğrenebilirsiniz?', 'id': 'Berapa menit Anda bisa belajar setiap hari?', 'bn': 'আপনি প্রতিদিন কত মিনিট শিখতে পারেন?', 'ha': 'Minti nawa za ka iya koyo kullum?',
    'so': 'Immisa daqiiqo ayaad barasho maalin kasta awoodaa?', 'fa': 'روزانه چند دقیقه می‌توانید یاد بگیرید؟', 'ms': 'Berapa minit anda boleh belajar setiap hari?',
  },
  'mission_minutes_unit_suffix': {
    'ar': 'دقيقة', 'en': 'min', 'am': 'ደቂቃ', 'fr': 'min', 'sw': 'dakika',
    'ur': 'منٹ', 'tr': 'dk', 'id': 'menit', 'bn': 'মিনিট', 'ha': 'minti',
    'so': 'daqiiqo', 'fa': 'دقیقه', 'ms': 'minit',
  },
  'mission_goal_step_title': {
    'ar': 'ما هدفك خلال سنة؟ (اختياري)', 'en': 'What is your goal within a year? (optional)', 'am': 'በአንድ ዓመት ውስጥ ግብዎ ምንድን ነው? (አማራጭ)', 'fr': "Quel est votre objectif dans un an ? (facultatif)", 'sw': 'Lengo lako ndani ya mwaka mmoja ni nini? (si lazima)',
    'ur': 'ایک سال میں آپ کا ہدف کیا ہے؟ (اختیاری)', 'tr': 'Bir yıl içindeki hedefiniz nedir? (isteğe bağlı)', 'id': 'Apa tujuan Anda dalam satu tahun? (opsional)', 'bn': 'এক বছরের মধ্যে আপনার লক্ষ্য কী? (ঐচ্ছিক)', 'ha': 'Menene manufarka a cikin shekara guda? (na zaɓi)',
    'so': 'Waa maxay yoolkaaga sanad gudahiisa? (ikhtiyaari)', 'fa': 'هدف شما در یک سال چیست؟ (اختیاری)', 'ms': 'Apakah matlamat anda dalam setahun? (pilihan)',
  },
  'mission_goal_hint': {
    'ar': 'مثال: أحفظ 5 أجزاء وأتقن الواسطية', 'en': "Example: memorize 5 juz' and master al-Wasitiyyah", 'am': 'ምሳሌ፦ 5 ጁዝእ አጥናት እና ዋሲጢያን ተካን', 'fr': "Exemple : mémoriser 5 juz' et maîtriser al-Wasitiyya", 'sw': 'Mfano: kuhifadhi juzuu 5 na kubobea al-Wasitiyyah',
    'ur': 'مثال: 5 پارے حفظ کروں اور واسطیہ میں مہارت حاصل کروں', 'tr': "Örnek: 5 cüz ezberlemek ve el-Vasıtiyye'de ustalaşmak", 'id': "Contoh: menghafal 5 juz dan menguasai al-Wasitiyyah", 'bn': 'উদাহরণ: ৫ পারা হিফজ করা এবং ওয়াসিতিয়্যাহ আয়ত্ত করা', 'ha': "Misali: haddace juzu'i 5 da kware a al-Wasitiyyah",
    'so': "Tusaale: xifdhi 5 juz' oo aqoon fiican u yeelo al-Wasitiyyah", 'fa': 'مثال: حفظ ۵ جزء و تسلط بر واسطیه', 'ms': 'Contoh: menghafal 5 juzuk dan menguasai al-Wasitiyyah',
  },
  'mission_one_year_goal_label': {
    'ar': '🎯 هدفك خلال سنة', 'en': '🎯 Your goal within a year', 'am': '🎯 በአንድ ዓመት ውስጥ ግብዎ', 'fr': '🎯 Votre objectif dans un an', 'sw': '🎯 Lengo lako ndani ya mwaka',
    'ur': '🎯 ایک سال میں آپ کا ہدف', 'tr': '🎯 Bir yıl içindeki hedefiniz', 'id': '🎯 Tujuan Anda dalam satu tahun', 'bn': '🎯 এক বছরের মধ্যে আপনার লক্ষ্য', 'ha': '🎯 Manufarka a cikin shekara',
    'so': '🎯 Yoolkaaga sanad gudahiisa', 'fa': '🎯 هدف شما در یک سال', 'ms': '🎯 Matlamat anda dalam setahun',
  },
  'strongest_area_label': {
    'ar': 'أقوى مجال', 'en': 'Strongest Area', 'am': 'ጠንካራ ዘርፍ', 'fr': 'Domaine le plus fort', 'sw': 'Eneo Imara Zaidi',
    'ur': 'مضبوط ترین شعبہ', 'tr': 'En Güçlü Alan', 'id': 'Bidang Terkuat', 'bn': 'সবচেয়ে শক্তিশালী ক্ষেত্র', 'ha': 'Fanni Mafi Ƙarfi',
    'so': 'Qaybta Ugu Xoogga Badan', 'fa': 'قوی‌ترین حوزه', 'ms': 'Bidang Terkuat',
  },
  'weakest_area_label': {
    'ar': 'أضعف مجال', 'en': 'Weakest Area', 'am': 'ደካማ ዘርፍ', 'fr': 'Domaine le plus faible', 'sw': 'Eneo Dhaifu Zaidi',
    'ur': 'کمزور ترین شعبہ', 'tr': 'En Zayıf Alan', 'id': 'Bidang Terlemah', 'bn': 'দুর্বলতম ক্ষেত্র', 'ha': 'Fanni Mafi Rauni',
    'so': 'Qaybta Ugu Daciifsan', 'fa': 'ضعیف‌ترین حوزه', 'ms': 'Bidang Terlemah',
  },
  'average_label': {
    'ar': 'المتوسط', 'en': 'Average', 'am': 'አማካይ', 'fr': 'Moyenne', 'sw': 'Wastani',
    'ur': 'اوسط', 'tr': 'Ortalama', 'id': 'Rata-rata', 'bn': 'গড়', 'ha': 'Matsakaici',
    'so': 'Celceliska', 'fa': 'میانگین', 'ms': 'Purata',
  },
  'your_map_header': {
    'ar': 'خريطتك', 'en': 'Your Map', 'am': 'ካርታዎ', 'fr': 'Votre carte', 'sw': 'Ramani Yako',
    'ur': 'آپ کا نقشہ', 'tr': 'Haritanız', 'id': 'Peta Anda', 'bn': 'আপনার মানচিত্র', 'ha': 'Taswirarka',
    'so': 'Khariiddaada', 'fa': 'نقشه شما', 'ms': 'Peta Anda',
  },
  'biggest_opportunity_prefix': {
    'ar': 'أكبر فرصة لتحسينك الآن:', 'en': 'Your biggest opportunity to improve right now:', 'am': 'አሁን ለማሻሻል ትልቁ ዕድልዎ፦', 'fr': "Votre plus grande opportunité d'amélioration maintenant :", 'sw': 'Fursa yako kubwa ya kuboresha sasa:',
    'ur': 'ابھی بہتری کا سب سے بڑا موقع:', 'tr': 'Şu anda gelişmek için en büyük fırsatınız:', 'id': 'Peluang terbesar Anda untuk berkembang sekarang:', 'bn': 'এখন উন্নতির জন্য আপনার সবচেয়ে বড় সুযোগ:', 'ha': 'Babbar dama don ingantawa yanzu:',
    'so': 'Fursaddaada ugu weyn ee horumarinta hadda:', 'fa': 'بزرگ‌ترین فرصت شما برای بهبود اکنون:', 'ms': 'Peluang terbesar anda untuk berkembang sekarang:',
  },
  'start_here_action': {
    'ar': 'ابدأ من هنا', 'en': 'Start Here', 'am': 'ከዚህ ይጀምሩ', 'fr': 'Commencez ici', 'sw': 'Anzia Hapa',
    'ur': 'یہاں سے شروع کریں', 'tr': 'Buradan Başla', 'id': 'Mulai Dari Sini', 'bn': 'এখান থেকে শুরু করুন', 'ha': 'Fara Daga Nan',
    'so': 'Halkan ka Bilow', 'fa': 'از اینجا شروع کن', 'ms': 'Mula Dari Sini',
  },
  'suggested_level_prefix': {
    'ar': 'المستوى المقترح:', 'en': 'Suggested level:', 'am': 'የተጠቆመ ደረጃ፦', 'fr': 'Niveau suggéré :', 'sw': 'Kiwango Kinachopendekezwa:',
    'ur': 'تجویز کردہ سطح:', 'tr': 'Önerilen Seviye:', 'id': 'Tingkat yang Disarankan:', 'bn': 'প্রস্তাবিত স্তর:', 'ha': 'Matsayin da Aka Bada Shawara:',
    'so': 'Heerka la Soo Jeediyay:', 'fa': 'سطح پیشنهادی:', 'ms': 'Tahap Dicadangkan:',
  },
  'use_it_suffix_question': {
    'ar': '— استخدمه؟', 'en': '— use it?', 'am': '— ይጠቀሙበት?', 'fr': "— l'utiliser ?", 'sw': '— tumia?',
    'ur': '— اسے استعمال کریں؟', 'tr': '— kullanılsın mı?', 'id': '— gunakan?', 'bn': '— ব্যবহার করবেন?', 'ha': '— a yi amfani da shi?',
    'so': '— isticmaal?', 'fa': '— استفاده شود؟', 'ms': '— guna?',
  },
  'use_it_action': {
    'ar': 'استخدمه', 'en': 'Use It', 'am': 'ይጠቀሙበት', 'fr': 'Utiliser', 'sw': 'Tumia',
    'ur': 'استعمال کریں', 'tr': 'Kullan', 'id': 'Gunakan', 'bn': 'ব্যবহার করুন', 'ha': 'Yi Amfani',
    'so': 'Isticmaal', 'fa': 'استفاده کن', 'ms': 'Guna',
  },
  'reassess_action': {
    'ar': 'أعد التقييم', 'en': 'Reassess', 'am': 'እንደገና ይገምግሙ', 'fr': 'Réévaluer', 'sw': 'Pima Tena',
    'ur': 'دوبارہ جانچیں', 'tr': 'Yeniden Değerlendir', 'id': 'Nilai Ulang', 'bn': 'পুনর্মূল্যায়ন করুন', 'ha': 'Sake Kimantawa',
    'so': 'Dib u Qiimee', 'fa': 'ارزیابی مجدد', 'ms': 'Nilai Semula',
  },
  // 2026-08-22: reading_stats_screen.dart.
  'reading_stats_title': {
    'ar': 'إحصائياتي في القراءة', 'en': 'My Reading Stats', 'am': 'የንባብ ስታትስቲክሶቼ', 'fr': 'Mes statistiques de lecture', 'sw': 'Takwimu Zangu za Kusoma',
    'ur': 'میرے مطالعے کے اعداد و شمار', 'tr': 'Okuma İstatistiklerim', 'id': 'Statistik Membaca Saya', 'bn': 'আমার পড়ার পরিসংখ্যান', 'ha': 'Kididdigar Karatuna',
    'so': 'Tirakoobkayga Akhriska', 'fa': 'آمار مطالعه من', 'ms': 'Statistik Bacaan Saya',
  },
  'books_opened_label': {
    'ar': 'كتاب فُتح', 'en': 'Books Opened', 'am': 'የተከፈቱ መጻሕፍት', 'fr': 'Livres ouverts', 'sw': 'Vitabu Vilivyofunguliwa',
    'ur': 'کھولی گئی کتابیں', 'tr': 'Açılan Kitap', 'id': 'Buku Dibuka', 'bn': 'খোলা বই', 'ha': 'Littattafan da Aka Buɗe',
    'so': 'Buugag La Furay', 'fa': 'کتاب باز شده', 'ms': 'Buku Dibuka',
  },
  'books_finished_label': {
    'ar': 'كتاب أُنهي', 'en': 'Books Finished', 'am': 'የተጠናቀቁ መጻሕፍት', 'fr': 'Livres terminés', 'sw': 'Vitabu Vilivyokamilika',
    'ur': 'مکمل کی گئی کتابیں', 'tr': 'Tamamlanan Kitap', 'id': 'Buku Selesai', 'bn': 'শেষ করা বই', 'ha': 'Littattafan da Aka Gama',
    'so': 'Buugag Dhammaystiran', 'fa': 'کتاب تمام‌شده', 'ms': 'Buku Selesai',
  },
  'pages_read_label': {
    'ar': 'صفحة قُرئت', 'en': 'Pages Read', 'am': 'የተነበቡ ገጾች', 'fr': 'Pages lues', 'sw': 'Kurasa Zilizosomwa',
    'ur': 'پڑھے گئے صفحات', 'tr': 'Okunan Sayfa', 'id': 'Halaman Dibaca', 'bn': 'পড়া পাতা', 'ha': 'Shafukan da Aka Karanta',
    'so': 'Bogag La Akhriyay', 'fa': 'صفحه خوانده‌شده', 'ms': 'Halaman Dibaca',
  },
  'quiz_passed_label': {
    'ar': 'اختبار ناجح', 'en': 'Quizzes Passed', 'am': 'ያለፉ ፈተናዎች', 'fr': 'Quiz réussis', 'sw': 'Majaribio Yaliyopita',
    'ur': 'کامیاب کوئز', 'tr': 'Geçilen Sınav', 'id': 'Kuis Lulus', 'bn': 'পাস করা কুইজ', 'ha': 'Jarrabawar da Aka Ci',
    'so': 'Imtixaannada La Gudbay', 'fa': 'آزمون قبول‌شده', 'ms': 'Kuiz Lulus',
  },
  'average_quiz_results_label': {
    'ar': 'متوسط نتائج الاختبارات', 'en': 'Average Quiz Score', 'am': 'አማካይ የፈተና ውጤት', 'fr': 'Score moyen aux quiz', 'sw': 'Wastani wa Matokeo ya Majaribio',
    'ur': 'اوسط کوئز نتیجہ', 'tr': 'Ortalama Sınav Sonucu', 'id': 'Rata-rata Nilai Kuis', 'bn': 'গড় কুইজ ফলাফল', 'ha': 'Matsakaicin Sakamakon Jarrabawa',
    'so': 'Celceliska Natiijooyinka Imtixaanka', 'fa': 'میانگین نتایج آزمون', 'ms': 'Purata Keputusan Kuiz',
  },
  'reading_stats_empty_message': {
    'ar': 'ابدأ بقراءة أي كتاب من "الكتاب" أو "مكتبتي" لترى إحصائياتك هنا.', 'en': 'Start reading any book from "Library" or "My Library" to see your stats here.', 'am': 'ስታትስቲክሶችዎን እዚህ ለማየት ከ"ቤተ መጻሕፍት" ወይም "ቤተ መጻሕፍቴ" ማንኛውንም መጽሐፍ ማንበብ ይጀምሩ።', 'fr': 'Commencez à lire un livre depuis "Bibliothèque" ou "Ma bibliothèque" pour voir vos statistiques ici.', 'sw': 'Anza kusoma kitabu chochote kutoka "Maktaba" au "Maktaba Yangu" ili kuona takwimu zako hapa.',
    'ur': 'یہاں اپنے اعداد و شمار دیکھنے کے لیے "کتب خانہ" یا "میری لائبریری" سے کوئی کتاب پڑھنا شروع کریں۔', 'tr': "İstatistiklerinizi burada görmek için \"Kütüphane\" veya \"Kütüphanem\"den herhangi bir kitap okumaya başlayın.", 'id': 'Mulailah membaca buku apa pun dari "Perpustakaan" atau "Perpustakaan Saya" untuk melihat statistik Anda di sini.', 'bn': 'এখানে আপনার পরিসংখ্যান দেখতে "লাইব্রেরি" বা "আমার লাইব্রেরি" থেকে যেকোনো বই পড়া শুরু করুন।', 'ha': 'Fara karanta duk wani littafi daga "Laburare" ko "Laburare Na" don ganin kididdigarka a nan.',
    'so': 'Ka bilow akhrinta buug kasta oo ka mid ah "Maktabadda" ama "Maktabadayda" si aad halkan uga aragto tirakoobkaaga.', 'fa': 'برای دیدن آمار خود در اینجا، خواندن هر کتابی را از "کتابخانه" یا "کتابخانه من" شروع کنید.', 'ms': 'Mula membaca mana-mana buku daripada "Perpustakaan" atau "Perpustakaan Saya" untuk melihat statistik anda di sini.',
  },
  // 2026-08-22: personal_accountability_screen.dart.
  'personal_accountability_title': {
    'ar': 'التزامي الشخصي', 'en': 'My Personal Commitment', 'am': 'የግል ቁርጠኝነቴ', 'fr': 'Mon engagement personnel', 'sw': 'Ahadi Yangu Binafsi',
    'ur': 'میری ذاتی وابستگی', 'tr': 'Kişisel Taahhüdüm', 'id': 'Komitmen Pribadi Saya', 'bn': 'আমার ব্যক্তিগত অঙ্গীকার', 'ha': 'Alkawarina na Kaina',
    'so': 'Ballan-qaadkayga Shakhsiga ah', 'fa': 'تعهد شخصی من', 'ms': 'Komitmen Peribadi Saya',
  },
  'personal_accountability_intro': {
    'ar': 'هذا التزام بينك وبين نفسك فقط. التطبيق يذكّرك بما كتبته هنا عند إنجازك أو تقصيرك — ولا ينفّذ شيئًا نيابة عنك بأي حال.', 'en': "This is a commitment only between you and yourself. The app just reminds you of what you wrote here when you succeed or fall short — it never carries out anything on your behalf.", 'am': 'ይህ ከራስዎ ጋር ብቻ ያለ ቁርጠኝነት ነው። መተግበሪያው ስኬትዎ ወይም ውድቀትዎ ጊዜ እዚህ የጻፉትን ያስታውስዎታል — በምንም መልኩ ስለ እርስዎ ምንም አያከናውንም።', 'fr': "Ceci est un engagement uniquement entre vous et vous-même. L'application ne fait que vous rappeler ce que vous avez écrit ici lorsque vous réussissez ou échouez — elle n'exécute jamais rien en votre nom.", 'sw': 'Hii ni ahadi kati yako na wewe mwenyewe tu. Programu inakukumbusha tu ulichoandika hapa unapofanikiwa au kukosea — haifanyi chochote kwa niaba yako kamwe.',
    'ur': 'یہ صرف آپ کے اور آپ کے درمیان ایک وابستگی ہے۔ ایپ آپ کو صرف اس بات کی یاد دلاتی ہے جو آپ نے یہاں لکھی جب آپ کامیاب ہوں یا کمی کریں — یہ آپ کی جانب سے کبھی کچھ نہیں کرتی۔', 'tr': "Bu yalnızca sizinle sizin aranızdaki bir taahhüttür. Uygulama, başarılı olduğunuzda veya eksik kaldığınızda burada yazdıklarınızı size hatırlatır — sizin adınıza asla hiçbir şey yapmaz.", 'id': 'Ini adalah komitmen hanya antara Anda dan diri Anda sendiri. Aplikasi hanya mengingatkan Anda tentang apa yang Anda tulis di sini saat Anda berhasil atau gagal — tidak pernah melakukan apa pun atas nama Anda.', 'bn': 'এটি শুধুমাত্র আপনার এবং আপনার নিজের মধ্যে একটি অঙ্গীকার। অ্যাপটি শুধু আপনাকে মনে করিয়ে দেয় আপনি এখানে যা লিখেছেন যখন আপনি সফল হন বা ঘাটতি করেন — এটি কখনো আপনার পক্ষে কিছু করে না।', 'ha': "Wannan alkawari ne tsakaninka da kanka kawai. Manhajar tana tunatar da kai abin da ka rubuta a nan lokacin da ka yi nasara ko ka gaza — ba ta taɓa yin komai a madadinka ba.",
    'so': 'Tani waa ballan-qaad adiga iyo naftaada oo kaliya ka dhexeeya. App-ku wuxuu kuu xasuusiyaa waxa aad halkan qortay marka aad guulaysato ama aad ka gaabsatid — mar walba kuguma sameeyo wax adiga aawadaa.', 'fa': 'این تعهدی فقط بین شما و خودتان است. برنامه فقط آنچه اینجا نوشته‌اید را هنگام موفقیت یا کوتاهی به شما یادآوری می‌کند — هرگز چیزی از طرف شما انجام نمی‌دهد.', 'ms': 'Ini adalah komitmen hanya antara anda dan diri anda sendiri. Aplikasi hanya mengingatkan anda tentang apa yang anda tulis di sini apabila anda berjaya atau tidak — ia tidak pernah melakukan apa-apa bagi pihak anda.',
  },
  'my_reward_header': {
    'ar': 'مكافأتي', 'en': 'My Reward', 'am': 'ሽልማቴ', 'fr': 'Ma récompense', 'sw': 'Zawadi Yangu',
    'ur': 'میرا انعام', 'tr': 'Ödülüm', 'id': 'Hadiah Saya', 'bn': 'আমার পুরস্কার', 'ha': 'Ladana',
    'so': 'Abaal-marintayda', 'fa': 'پاداش من', 'ms': 'Ganjaran Saya',
  },
  'reward_subtitle': {
    'ar': 'شيء تكافئ به نفسك عند إنجاز مهمة أو استلام شهادة', 'en': 'Something you reward yourself with when completing a task or earning a certificate', 'am': 'ተግባር ሲያጠናቅቁ ወይም የምስክር ወረቀት ሲቀበሉ ራስዎን የሚሸልሙበት ነገር', 'fr': 'Quelque chose dont vous vous récompensez en accomplissant une tâche ou en obtenant un certificat', 'sw': 'Kitu unachojituza nacho unapokamilisha kazi au kupata cheti',
    'ur': 'کوئی چیز جس سے آپ کسی کام کی تکمیل یا سرٹیفکیٹ ملنے پر خود کو نوازتے ہیں', 'tr': 'Bir görevi tamamladığınızda veya sertifika aldığınızda kendinizi ödüllendireceğiniz bir şey', 'id': 'Sesuatu yang Anda hadiahkan pada diri sendiri saat menyelesaikan tugas atau mendapatkan sertifikat', 'bn': 'কোনো কাজ শেষ করলে বা সনদ পেলে নিজেকে যা দিয়ে পুরস্কৃত করেন', 'ha': "Wani abu da kake ba wa kanka lada da shi lokacin da ka kammala aiki ko ka sami takardar shaida",
    'so': 'Wax aad naftaada ku abaal marto marka aad dhammayso hawl ama aad hesho shahaado', 'fa': 'چیزی که هنگام تکمیل یک کار یا دریافت گواهی به خودتان پاداش می‌دهید', 'ms': 'Sesuatu yang anda ganjari diri sendiri apabila menyelesaikan tugasan atau mendapat sijil',
  },
  'enable_reward_reminder_action': {
    'ar': 'فعّل التذكير بالمكافأة', 'en': 'Enable Reward Reminder', 'am': 'የሽልማት ማስታወሻ አንቁ', 'fr': 'Activer le rappel de récompense', 'sw': 'Washa Ukumbusho wa Zawadi',
    'ur': 'انعام کی یاد دہانی فعال کریں', 'tr': 'Ödül Hatırlatmasını Etkinleştir', 'id': 'Aktifkan Pengingat Hadiah', 'bn': 'পুরস্কার অনুস্মারক চালু করুন', 'ha': 'Kunna Tunatarwar Lada',
    'so': 'Daar Xasuusinta Abaal-marinta', 'fa': 'فعال‌سازی یادآوری پاداش', 'ms': 'Dayakan Peringatan Ganjaran',
  },
  'reward_hint_example': {
    'ar': 'مثلًا: سأشتري كتابًا أحبه', 'en': "e.g.: I'll buy a book I love", 'am': 'ለምሳሌ፦ የምወደው መጽሐፍ እገዛለሁ', 'fr': "par exemple : j'achèterai un livre que j'aime", 'sw': 'k.m.: nitanunua kitabu ninachopenda',
    'ur': 'مثلاً: میں اپنی پسندیدہ کتاب خریدوں گا', 'tr': 'örneğin: sevdiğim bir kitap satın alacağım', 'id': 'misalnya: saya akan membeli buku yang saya suka', 'bn': 'যেমন: আমি আমার পছন্দের একটি বই কিনব', 'ha': "misali: zan sayi littafin da nake so",
    'so': 'tusaale ahaan: waxaan iibsan doonaa buug aan jeclahay', 'fa': 'مثلاً: کتابی که دوست دارم می‌خرم', 'ms': 'contohnya: saya akan membeli buku yang saya suka',
  },
  'if_i_fall_short_header': {
    'ar': 'إن قصّرت', 'en': 'If I Fall Short', 'am': 'ካልተሳካልኝ', 'fr': "Si je n'y arrive pas", 'sw': 'Ikiwa Nitakosea',
    'ur': 'اگر میں کمی کروں', 'tr': 'Eksik Kalırsam', 'id': 'Jika Saya Gagal', 'bn': 'যদি আমি কম করি', 'ha': 'Idan Na Gaza',
    'so': 'Haddii Aan Ka Gaabsado', 'fa': 'اگر کوتاهی کنم', 'ms': 'Jika Saya Tidak Berjaya',
  },
  'if_i_fall_short_subtitle': {
    'ar': 'قرارك بالكامل — لا يوجد صح أو خطأ هنا', 'en': "Entirely your choice — there's no right or wrong here", 'am': 'ሙሉ በሙሉ የእርስዎ ውሳኔ — እዚህ ትክክል ወይም ስህተት የለም', 'fr': "Entièrement votre choix — il n'y a ni bien ni mal ici", 'sw': 'Ni uamuzi wako kabisa — hakuna sahihi au makosa hapa',
    'ur': 'مکمل طور پر آپ کا فیصلہ — یہاں کوئی صحیح یا غلط نہیں', 'tr': 'Tamamen sizin kararınız — burada doğru ya da yanlış yok', 'id': 'Sepenuhnya keputusan Anda — tidak ada benar atau salah di sini', 'bn': 'সম্পূর্ণ আপনার সিদ্ধান্ত — এখানে সঠিক বা ভুল নেই', 'ha': 'Shawararka ce gaba ɗaya — babu daidai ko kuskure a nan',
    'so': 'Waa go\'aankaaga oo dhan — halkan ma jiro sax ama qalad', 'fa': 'تصمیم کاملاً با شماست — اینجا درست یا غلطی وجود ندارد', 'ms': 'Sepenuhnya keputusan anda — tiada betul atau salah di sini',
  },
  'no_punishment_option_title': {
    'ar': 'بدون عقاب — أعتمد على نفسي فقط', 'en': "No punishment — I rely on myself alone", 'am': 'ያለ ቅጣት — በራሴ ብቻ እተማመናለሁ', 'fr': "Sans punition — je compte uniquement sur moi-même", 'sw': 'Bila adhabu — natumaini nafsi yangu tu',
    'ur': 'بغیر سزا کے — میں صرف اپنے آپ پر انحصار کرتا ہوں', 'tr': "Cezasız — sadece kendime güveniyorum", 'id': 'Tanpa hukuman — saya hanya mengandalkan diri sendiri', 'bn': 'কোনো শাস্তি ছাড়া — শুধু নিজের উপর নির্ভর করি', 'ha': "Ba tare da hukunci ba — na dogara ga kaina kaɗai",
    'so': 'Ciqaab la\'aan — waxaan ku tiirsanahay naftayda oo keliya', 'fa': 'بدون تنبیه — فقط به خودم تکیه می‌کنم', 'ms': 'Tanpa hukuman — saya bergantung pada diri sendiri sahaja',
  },
  'no_punishment_option_subtitle': {
    'ar': 'خيار صحي تمامًا؛ الالتزام الذاتي وحده كافٍ لكثير من الناس', 'en': 'A perfectly healthy choice; self-commitment alone is enough for many people', 'am': 'ፍጹም ጤናማ ምርጫ ነው፤ ራስን ማክበር ብቻ ለብዙ ሰዎች በቂ ነው', 'fr': 'Un choix parfaitement sain ; l\'engagement personnel seul suffit pour beaucoup de gens', 'sw': 'Ni chaguo lenye afya kabisa; ahadi binafsi pekee inatosha kwa watu wengi',
    'ur': 'بالکل صحت مند انتخاب؛ خود وابستگی اکیلی بہت سے لوگوں کے لیے کافی ہے', 'tr': "Tamamen sağlıklı bir seçim; birçok insan için yalnızca kendine bağlılık yeterlidir", 'id': 'Pilihan yang sepenuhnya sehat; komitmen diri saja sudah cukup bagi banyak orang', 'bn': 'সম্পূর্ণ স্বাস্থ্যকর একটি পছন্দ; শুধু স্ব-অঙ্গীকারই অনেকের জন্য যথেষ্ট', 'ha': "Zaɓi mai kyau sosai; alkawarin kai kaɗai ya isa ga mutane da yawa",
    'so': 'Waa doorasho caafimaad qaba oo dhammaystiran; ballan-qaadka naftaada oo kaliya ayaa ku filan dad badan', 'fa': 'انتخابی کاملاً سالم؛ تعهد شخصی به‌تنهایی برای بسیاری از افراد کافی است', 'ms': 'Pilihan yang sangat sihat; komitmen diri sahaja mencukupi bagi ramai orang',
  },
  'set_own_commitment_option': {
    'ar': 'أضع لنفسي التزامًا عند التقصير', 'en': "I'll set a commitment for myself if I fall short", 'am': 'ካልተሳካልኝ ለራሴ ቁርጠኝነት አስቀምጣለሁ', 'fr': "Je me fixerai un engagement en cas d'échec", 'sw': 'Nitajiwekea ahadi ninapokosea',
    'ur': 'کمی کرنے پر میں اپنے لیے ایک وابستگی مقرر کروں گا', 'tr': "Eksik kalırsam kendime bir taahhüt belirlerim", 'id': 'Saya akan menetapkan komitmen untuk diri sendiri jika gagal', 'bn': 'ঘাটতি হলে আমি নিজের জন্য একটি অঙ্গীকার রাখব', 'ha': "Zan sanya wa kaina alkawari idan na gaza",
    'so': 'Waxaan naftayda u dejin doonaa ballan-qaad haddii aan ka gaabsado', 'fa': 'اگر کوتاهی کنم برای خودم تعهدی می‌گذارم', 'ms': 'Saya akan menetapkan komitmen untuk diri sendiri jika tidak berjaya',
  },
  'punishment_hint_example': {
    'ar': 'مثلًا: سأتصدق بمبلغ معيّن', 'en': "e.g.: I'll give a certain amount in charity", 'am': 'ለምሳሌ፦ የተወሰነ መጠን ምጽዋት እሰጣለሁ', 'fr': 'par exemple : je ferai un don caritatif', 'sw': 'k.m.: nitatoa sadaka kiasi fulani',
    'ur': 'مثلاً: میں ایک مخصوص رقم صدقہ کروں گا', 'tr': 'örneğin: belirli bir miktar sadaka vereceğim', 'id': 'misalnya: saya akan bersedekah dengan jumlah tertentu', 'bn': 'যেমন: আমি একটি নির্দিষ্ট পরিমাণ সদকা দেব', 'ha': "misali: zan bayar da sadaka kuɗi na musamman",
    'so': 'tusaale ahaan: waxaan bixin doonaa sadaqad qadar go\'an ah', 'fa': 'مثلاً: مبلغ مشخصی صدقه می‌دهم', 'ms': 'contohnya: saya akan bersedekah dengan jumlah tertentu',
  },
  'saved_message': {
    'ar': 'تم الحفظ', 'en': 'Saved', 'am': 'ተቀምጧል', 'fr': 'Enregistré', 'sw': 'Imehifadhiwa',
    'ur': 'محفوظ ہو گیا', 'tr': 'Kaydedildi', 'id': 'Tersimpan', 'bn': 'সংরক্ষিত হয়েছে', 'ha': 'An Ajiye',
    'so': 'Waa la Kaydiyay', 'fa': 'ذخیره شد', 'ms': 'Disimpan',
  },
  // 2026-08-22: wird_screen.dart. Template titles/descriptions/item labels
  // come from wird_templates.dart (scholar-named content), out of scope.
  'wird_title': {
    'ar': 'ورد اليوم', 'en': "Today's Wird", 'am': 'የዛሬው ውርድ', 'fr': 'Wird du jour', 'sw': 'Wird ya Leo',
    'ur': 'آج کا ورد', 'tr': 'Bugünkü Vird', 'id': 'Wirid Hari Ini', 'bn': 'আজকের ওয়াজিফা', 'ha': 'Wirdin Yau',
    'so': 'Wirdka Maanta', 'fa': 'ورد امروز', 'ms': 'Wirid Hari Ini',
  },
  'choose_wird_label': {
    'ar': 'اختر وردك', 'en': 'Choose Your Wird', 'am': 'ውርድዎን ይምረጡ', 'fr': 'Choisissez votre wird', 'sw': 'Chagua Wird Yako',
    'ur': 'اپنا ورد منتخب کریں', 'tr': 'Virdinizi Seçin', 'id': 'Pilih Wirid Anda', 'bn': 'আপনার ওয়াজিফা নির্বাচন করুন', 'ha': 'Zaɓi Wirdinka',
    'so': 'Dooro Wirdkaaga', 'fa': 'ورد خود را انتخاب کنید', 'ms': 'Pilih Wirid Anda',
  },
  // 2026-08-22: companion_chat_screen.dart's two dev-tool tooltips.
  'companion_debug_tooltip': {
    'ar': 'تشخيص', 'en': 'Debug', 'am': 'ማረም', 'fr': 'Diagnostic', 'sw': 'Uchunguzi',
    'ur': 'تشخیص', 'tr': 'Tanılama', 'id': 'Diagnostik', 'bn': 'নির্ণয়', 'ha': 'Bincike',
    'so': 'Baaritaan', 'fa': 'عیب‌یابی', 'ms': 'Diagnostik',
  },
  'app_self_test_tooltip': {
    'ar': 'اختبار شامل للتطبيق', 'en': 'Full App Self-Test', 'am': 'ሙሉ የመተግበሪያ ራስ-ምርመራ', 'fr': "Auto-test complet de l'application", 'sw': 'Jaribio Kamili la Programu',
    'ur': 'مکمل ایپ سیلف ٹیسٹ', 'tr': 'Kapsamlı Uygulama Kendi Kendini Testi', 'id': 'Uji Mandiri Aplikasi Lengkap', 'bn': 'অ্যাপের সম্পূর্ণ স্ব-পরীক্ষা', 'ha': 'Cikakken Gwajin Kai na Manhajar',
    'so': 'Tijaabinta Buuxda ee App-ka', 'fa': 'خودآزمایی کامل برنامه', 'ms': 'Ujian Diri Aplikasi Penuh',
  },
  // 2026-08-22: celebration_overlay.dart.
  'celebration_progress_message': {
    'ar': 'أحسنت 🌱 تقدّمت خطوة أخرى في رحلتك', 'en': "Well done 🌱 you've taken another step on your journey", 'am': 'መልካም 🌱 በጉዞዎ ሌላ እርምጃ ወስደዋል', 'fr': "Bien joué 🌱 vous avez fait un pas de plus dans votre parcours", 'sw': 'Hongera 🌱 umepiga hatua nyingine katika safari yako',
    'ur': 'شاباش 🌱 آپ نے اپنے سفر میں ایک اور قدم بڑھایا', 'tr': 'Aferin 🌱 yolculuğunuzda bir adım daha attınız', 'id': 'Bagus 🌱 Anda telah mengambil langkah lain dalam perjalanan Anda', 'bn': 'সাবাশ 🌱 আপনি আপনার যাত্রায় আরেকটি পদক্ষেপ নিয়েছেন', 'ha': 'Madalla 🌱 ka ɗauki wani mataki a tafiyarka',
    'so': 'Waad ku mahadsan tahay 🌱 waxaad qaadday tallaabo kale oo safarkaaga ah', 'fa': 'آفرین 🌱 قدم دیگری در مسیرتان برداشتید', 'ms': 'Syabas 🌱 anda telah mengambil satu lagi langkah dalam perjalanan anda',
  },
  'preparing_share_message': {
    'ar': 'جارٍ التجهيز...', 'en': 'Preparing...', 'am': 'በማዘጋጀት ላይ...', 'fr': 'Préparation en cours...', 'sw': 'Inaandaa...',
    'ur': 'تیار کیا جا رہا ہے...', 'tr': 'Hazırlanıyor...', 'id': 'Menyiapkan...', 'bn': 'প্রস্তুত করা হচ্ছে...', 'ha': 'Ana Shirye-shirye...',
    'so': 'Waa la diyaarinayaa...', 'fa': 'در حال آماده‌سازی...', 'ms': 'Menyediakan...',
  },
  'share_certificate_action': {
    'ar': 'مشاركة الشهادة', 'en': 'Share Certificate', 'am': 'የምስክር ወረቀት ያጋሩ', 'fr': 'Partager le certificat', 'sw': 'Shiriki Cheti',
    'ur': 'سرٹیفکیٹ شیئر کریں', 'tr': 'Sertifikayı Paylaş', 'id': 'Bagikan Sertifikat', 'bn': 'সনদ শেয়ার করুন', 'ha': 'Raba Takardar Shaida',
    'so': 'La Wadaag Shahaadada', 'fa': 'اشتراک‌گذاری گواهی', 'ms': 'Kongsi Sijil',
  },
  // 2026-08-22: certificate_card.dart — the shareable certificate image.
  'certificate_of_appreciation_title': {
    'ar': 'شهادة تقدير', 'en': 'Certificate of Appreciation', 'am': 'የአድናቆት ምስክር ወረቀት', 'fr': "Certificat d'appréciation", 'sw': 'Cheti cha Shukrani',
    'ur': 'اعزازی سند', 'tr': 'Takdir Belgesi', 'id': 'Sertifikat Penghargaan', 'bn': 'প্রশংসাপত্র', 'ha': 'Takardar Godiya',
    'so': 'Shahaadada Sharaftiin', 'fa': 'گواهی تقدیر', 'ms': 'Sijil Penghargaan',
  },
  'certificate_awarded_to_label': {
    'ar': 'تُمنح هذه الشهادة إلى', 'en': 'This certificate is awarded to', 'am': 'ይህ የምስክር ወረቀት ለ ተሰጥቷል', 'fr': 'Ce certificat est décerné à', 'sw': 'Cheti hiki kimetunukiwa',
    'ur': 'یہ سند اس کے نام کی گئی', 'tr': 'Bu belge şu kişiye verilmiştir:', 'id': 'Sertifikat ini diberikan kepada', 'bn': 'এই সনদ প্রদান করা হয়েছে', 'ha': 'An bai wa wannan takardar shaida',
    'so': 'Shahaadadan waxaa la siiyay', 'fa': 'این گواهی به این شخص اهدا می‌شود', 'ms': 'Sijil ini dianugerahkan kepada',
  },
  'signature_label': {
    'ar': 'التوقيع', 'en': 'Signature', 'am': 'ፊርማ', 'fr': 'Signature', 'sw': 'Sahihi',
    'ur': 'دستخط', 'tr': 'İmza', 'id': 'Tanda Tangan', 'bn': 'স্বাক্ষর', 'ha': 'Sa Hannu',
    'so': 'Saxeexa', 'fa': 'امضا', 'ms': 'Tandatangan',
  },
  'app_signature_name': {
    'ar': 'تطبيق طالب العلم', 'en': 'Talib al-Ilm App', 'am': 'የጣሊብ አል-ዒልም መተግበሪያ', 'fr': "Application Talib al-Ilm", 'sw': 'Programu ya Talib al-Ilm',
    'ur': 'طالب العلم ایپ', 'tr': "Talib al-Ilm Uygulaması", 'id': 'Aplikasi Talib al-Ilm', 'bn': 'তালিবুল ইলম অ্যাপ', 'ha': 'Manhajar Talib al-Ilm',
    'so': 'Barnaamijka Talib al-Ilm', 'fa': 'برنامه طالب العلم', 'ms': 'Aplikasi Talib al-Ilm',
  },
  'date_label': {
    'ar': 'التاريخ', 'en': 'Date', 'am': 'ቀን', 'fr': 'Date', 'sw': 'Tarehe',
    'ur': 'تاریخ', 'tr': 'Tarih', 'id': 'Tanggal', 'bn': 'তারিখ', 'ha': 'Kwanan Wata',
    'so': 'Taariikhda', 'fa': 'تاریخ', 'ms': 'Tarikh',
  },
  // 2026-08-22: companion_card.dart caption. message.title/body come from
  // companion_engine.dart's rule catalog (Arabic-only content), out of
  // scope for this sweep.
  'companion_caption_prefix': {
    'ar': 'رفيق طالب العلم', 'en': "Talib al-Ilm's Companion", 'am': 'የጣሊብ አል-ዒልም ጓደኛ', 'fr': 'Le compagnon de Talib al-Ilm', 'sw': 'Rafiki wa Talib al-Ilm',
    'ur': 'طالب العلم کا ساتھی', 'tr': "Talib al-Ilm'in Arkadaşı", 'id': 'Sahabat Talib al-Ilm', 'bn': 'তালিবুল ইলমের সঙ্গী', 'ha': 'Abokin Talib al-Ilm',
    'so': 'Saaxiibka Talib al-Ilm', 'fa': 'همراه طالب العلم', 'ms': 'Sahabat Talib al-Ilm',
  },
  // 2026-08-22: time_accountability_dashboard.dart + worship_coach_card.dart.
  'time_accountability_title': {
    'ar': 'محاسبة الوقت', 'en': 'Time Accountability', 'am': 'የጊዜ ተጠያቂነት', 'fr': 'Redevabilité du temps', 'sw': 'Uwajibikaji wa Muda',
    'ur': 'وقت کی جوابدہی', 'tr': 'Zaman Hesabı', 'id': 'Akuntabilitas Waktu', 'bn': 'সময়ের জবাবদিহিতা', 'ha': 'Lissafin Lokaci',
    'so': 'Xisaabinta Waqtiga', 'fa': 'محاسبه وقت', 'ms': 'Akauntabiliti Masa',
  },
  'week_label': {
    'ar': 'الأسبوع', 'en': 'Week', 'am': 'ሳምንት', 'fr': 'Semaine', 'sw': 'Wiki',
    'ur': 'ہفتہ', 'tr': 'Hafta', 'id': 'Minggu', 'bn': 'সপ্তাহ', 'ha': 'Mako',
    'so': 'Toddobaad', 'fa': 'هفته', 'ms': 'Minggu',
  },
  'month_label': {
    'ar': 'الشهر', 'en': 'Month', 'am': 'ወር', 'fr': 'Mois', 'sw': 'Mwezi',
    'ur': 'مہینہ', 'tr': 'Ay', 'id': 'Bulan', 'bn': 'মাস', 'ha': 'Wata',
    'so': 'Bil', 'fa': 'ماه', 'ms': 'Bulan',
  },
  'year_label': {
    'ar': 'السنة', 'en': 'Year', 'am': 'ዓመት', 'fr': 'Année', 'sw': 'Mwaka',
    'ur': 'سال', 'tr': 'Yıl', 'id': 'Tahun', 'bn': 'বছর', 'ha': 'Shekara',
    'so': 'Sanad', 'fa': 'سال', 'ms': 'Tahun',
  },
  'hour_short_unit': {
    'ar': 'س', 'en': 'h', 'am': 'ሰ', 'fr': 'h', 'sw': 's',
    'ur': 'گھ', 'tr': 's', 'id': 'j', 'bn': 'ঘ', 'ha': 'a',
    'so': 's', 'fa': 'س', 'ms': 'j',
  },
  'day_short_unit': {
    'ar': 'ي', 'en': 'd', 'am': 'ቀ', 'fr': 'j', 'sw': 's',
    'ur': 'د', 'tr': 'g', 'id': 'h', 'bn': 'দি', 'ha': 'r',
    'so': 'm', 'fa': 'ر', 'ms': 'h',
  },
  'not_recorded_yet_feminine': {
    'ar': 'لم تُسجَّل بعد', 'en': 'Not recorded yet', 'am': 'እስካሁን አልተመዘገበም', 'fr': 'Pas encore enregistré', 'sw': 'Bado haijarekodiwa',
    'ur': 'ابھی تک درج نہیں ہوا', 'tr': 'Henüz kaydedilmedi', 'id': 'Belum tercatat', 'bn': 'এখনও রেকর্ড করা হয়নি', 'ha': 'Ba a rubuta ba tukuna',
    'so': 'Wali lama diiwaan gelin', 'fa': 'هنوز ثبت نشده', 'ms': 'Belum direkodkan',
  },
  // 2026-08-22: knowledge_review_screen.dart. Book/source proper nouns
  // (al-Arbain al-Nawawiyyah, al-Wasitiyyah, Hisn al-Muslim) stay Arabic.
  'knowledge_review_title': {
    'ar': 'مراجعتك اليوم', 'en': "Today's Review", 'am': 'የዛሬ ክለሳዎ', 'fr': 'Votre révision du jour', 'sw': 'Marudio Yako ya Leo',
    'ur': 'آج کی آپ کی دہرائی', 'tr': 'Bugünkü Tekrarınız', 'id': 'Ulangan Anda Hari Ini', 'bn': 'আজকের আপনার পুনরাবৃত্তি', 'ha': 'Sake Nazarinka na Yau',
    'so': 'Dib-u-eegistaada Maanta', 'fa': 'مرور امروز شما', 'ms': 'Ulangkaji Anda Hari Ini',
  },
  'assembling_review_message': {
    'ar': 'جاري تجميع مراجعتك...', 'en': 'Assembling your review...', 'am': 'ክለሳዎን በማዘጋጀት ላይ...', 'fr': 'Préparation de votre révision...', 'sw': 'Inakusanya marudio yako...',
    'ur': 'آپ کی دہرائی جمع کی جا رہی ہے...', 'tr': 'Tekrarınız hazırlanıyor...', 'id': 'Menyusun ulangan Anda...', 'bn': 'আপনার পুনরাবৃত্তি একত্র করা হচ্ছে...', 'ha': 'Ana tara sake-nazarinka...',
    'so': 'Waxaa la ururinayaa dib-u-eegistaada...', 'fa': 'در حال آماده‌سازی مرور شما...', 'ms': 'Menyusun ulangkaji anda...',
  },
  'nothing_to_review_message': {
    'ar': 'لا شيء يستحق المراجعة الآن — أحسنت', 'en': "Nothing due for review right now — well done", 'am': 'አሁን የሚገባ ክለሳ የለም — መልካም', 'fr': "Rien à réviser pour le moment — bien joué", 'sw': 'Hakuna kinachohitaji kupitiwa sasa — hongera',
    'ur': 'ابھی کچھ بھی دہرانے کے لائق نہیں — شاباش', 'tr': 'Şu anda tekrar edilecek bir şey yok — aferin', 'id': 'Tidak ada yang perlu diulang sekarang — bagus', 'bn': 'এখন পুনরাবৃত্তির কিছু নেই — সাবাশ', 'ha': "Babu wani abu da ake bukatar sake-nazari yanzu — madalla",
    'so': 'Hadda wax dib-u-eegis ku habboon ma jiraan — waad ku mahadsan tahay', 'fa': 'الان چیزی برای مرور نیست — آفرین', 'ms': 'Tiada apa-apa perlu diulangkaji sekarang — syabas',
  },
  'hadith_section_title': {
    'ar': 'الحديث — الأربعين النووية', 'en': 'Hadith — al-Arbain al-Nawawiyyah', 'am': 'ሐዲስ — አል-አርበዒን አን-ነወዊያ', 'fr': "Le hadith — al-Arbain al-Nawawiyya", 'sw': 'Hadithi — al-Arbain al-Nawawiyyah',
    'ur': 'حدیث — اربعین نوویہ', 'tr': "Hadis — el-Erbaîn en-Neveviyye", 'id': 'Hadits — al-Arbain al-Nawawiyyah', 'bn': 'হাদিস — আরবাঈন নববী', 'ha': "Hadisi — al-Arbain al-Nawawiyyah",
    'so': "Xadiiska — al-Arbain al-Nawawiyyah", 'fa': 'حدیث — اربعین نوویه', 'ms': 'Hadis — al-Arbain al-Nawawiyyah',
  },
  'aqeedah_section_title': {
    'ar': 'العقيدة — الواسطية', 'en': 'Aqeedah — al-Wasitiyyah', 'am': 'ዐቂዳ — አል-ዋሲጢያ', 'fr': "L'aqida — al-Wasitiyya", 'sw': 'Aqidah — al-Wasitiyyah',
    'ur': 'عقیدہ — واسطیہ', 'tr': "Akide — el-Vasıtıyye", 'id': 'Akidah — al-Wasitiyyah', 'bn': 'আকিদা — ওয়াসিতিয়্যাহ', 'ha': "Akida — al-Wasitiyyah",
    'so': 'Caqiidada — al-Wasitiyyah', 'fa': 'عقیده — واسطیه', 'ms': 'Akidah — al-Wasitiyyah',
  },
  'adhkar_section_title': {
    'ar': 'الأذكار — حصن المسلم', 'en': 'Adhkar — Hisn al-Muslim', 'am': 'አዝካር — ሂስን አል-ሙስሊም', 'fr': "Les adhkar — Hisn al-Muslim", 'sw': 'Adhkar — Hisn al-Muslim',
    'ur': 'اذکار — حصن المسلم', 'tr': "Ezkâr — Hısnü'l-Müslim", 'id': 'Dzikir — Hisnul Muslim', 'bn': 'আজকার — হিসনুল মুসলিম', 'ha': "Azkari — Hisn al-Muslim",
    'so': 'Adkaarka — Hisn al-Muslim', 'fa': 'اذکار — حصن المسلم', 'ms': 'Zikir — Hisnul Muslim',
  },
  'and_conjunction_prefix': {
    'ar': 'و', 'en': 'and ', 'am': 'እና ', 'fr': 'et ', 'sw': 'na ',
    'ur': 'اور ', 'tr': 've ', 'id': 'dan ', 'bn': 'এবং ', 'ha': 'da ',
    'so': 'iyo ', 'fa': 'و ', 'ms': 'dan ',
  },
  'others_more_suffix': {
    'ar': 'غيرها', 'en': 'more', 'am': 'ተጨማሪ', 'fr': 'de plus', 'sw': 'zaidi',
    'ur': 'مزید', 'tr': 'daha', 'id': 'lainnya', 'bn': 'আরও', 'ha': 'ƙari',
    'so': 'kale', 'fa': 'مورد دیگر', 'ms': 'lagi',
  },
  // 2026-08-22: curriculum_map_screen.dart. Level/item titles+details come
  // from curriculum_levels.dart / curriculum_repository.dart (content).
  'curriculum_map_title': {
    'ar': 'خريطتي التعليمية', 'en': 'My Learning Map', 'am': 'የትምህርት ካርታዬ', 'fr': "Ma carte d'apprentissage", 'sw': 'Ramani Yangu ya Kujifunza',
    'ur': 'میرا تعلیمی نقشہ', 'tr': 'Öğrenme Haritam', 'id': 'Peta Belajar Saya', 'bn': 'আমার শেখার মানচিত্র', 'ha': 'Taswirar Karatuna',
    'so': 'Khariiddayda Waxbarashada', 'fa': 'نقشه یادگیری من', 'ms': 'Peta Pembelajaran Saya',
  },
  'content_coming_soon_message': {
    'ar': 'هذا المحتوى قيد التحضير', 'en': 'This content is being prepared', 'am': 'ይህ ይዘት በዝግጅት ላይ ነው', 'fr': 'Ce contenu est en préparation', 'sw': 'Maudhui haya yanaandaliwa',
    'ur': 'یہ مواد تیار کیا جا رہا ہے', 'tr': 'Bu içerik hazırlanıyor', 'id': 'Konten ini sedang disiapkan', 'bn': 'এই বিষয়বস্তু প্রস্তুত করা হচ্ছে', 'ha': 'Ana shirya wannan abun ciki',
    'so': 'Nuxurkan waa la diyaarinayaa', 'fa': 'این محتوا در حال آماده‌سازی است', 'ms': 'Kandungan ini sedang disediakan',
  },
  'your_path_header': {
    'ar': 'مسارك: من الصفر إلى التعمّق', 'en': 'Your Path: From Zero to Deep Mastery', 'am': 'መንገድዎ፦ ከዜሮ ወደ ጥልቅ ብቃት', 'fr': "Votre parcours : du débutant à l'approfondissement", 'sw': 'Njia Yako: Kutoka Sifuri Hadi Kubobea',
    'ur': 'آپ کا راستہ: صفر سے گہرائی تک', 'tr': 'Yolunuz: Sıfırdan Derinlemesine', 'id': 'Jalur Anda: Dari Nol hingga Mendalam', 'bn': 'আপনার পথ: শূন্য থেকে গভীরতা পর্যন্ত', 'ha': 'Hanyarka: Daga Sifili zuwa Zurfin Ilimi',
    'so': 'Waddadaada: Eber ilaa Aqoon Dheer', 'fa': 'مسیر شما: از صفر تا تسلط عمیق', 'ms': 'Laluan Anda: Dari Sifar hingga Penguasaan Mendalam',
  },
  'stations_completed_suffix': {
    'ar': 'محطة مكتملة', 'en': 'stations completed', 'am': 'ጣቢያዎች ተጠናቅቀዋል', 'fr': 'étapes terminées', 'sw': 'vituo vimekamilika',
    'ur': 'مراحل مکمل', 'tr': 'durak tamamlandı', 'id': 'stasiun selesai', 'bn': 'ধাপ সম্পন্ন', 'ha': 'tashoshi sun cika',
    'so': 'saldhig oo dhammaystiran', 'fa': 'ایستگاه تکمیل‌شده', 'ms': 'stesen selesai',
  },
  'no_lock_recommendation': {
    'ar': 'توصية لا قفل — افتح ما تشاء بأي ترتيب', 'en': "A recommendation, not a lock — open whatever you like, in any order", 'am': 'ምክር እንጂ ቁልፍ አይደለም — የፈለጉትን በማንኛውም ቅደም ተከተል ይክፈቱ', 'fr': "Une recommandation, pas un verrou — ouvrez ce que vous voulez, dans n'importe quel ordre", 'sw': 'Ni pendekezo, si kufuli — fungua chochote unachotaka, kwa mpangilio wowote',
    'ur': 'یہ سفارش ہے، تالا نہیں — کسی بھی ترتیب میں جو چاہیں کھولیں', 'tr': 'Bir öneridir, kilit değil — istediğiniz sırayla istediğinizi açın', 'id': 'Ini rekomendasi, bukan kunci — buka apa pun yang Anda inginkan, dalam urutan apa pun', 'bn': 'এটি একটি সুপারিশ, তালা নয় — যেকোনো ক্রমে যা ইচ্ছা খুলুন', 'ha': "Shawara ce, ba kulle ba — buɗe abin da kake so, cikin kowane tsari",
    'so': 'Waa talo, ma aha xidhid — fur wixii aad doonayso, dartiib kasta', 'fa': 'این یک توصیه است، نه قفل — به هر ترتیبی که می‌خواهید باز کنید', 'ms': 'Ini cadangan, bukan kunci — buka apa sahaja yang anda mahu, dalam sebarang susunan',
  },
  'tag_completed_label': {
    'ar': 'أُنجز', 'en': 'Done', 'am': 'ተጠናቋል', 'fr': 'Terminé', 'sw': 'Imekamilika',
    'ur': 'مکمل', 'tr': 'Tamamlandı', 'id': 'Selesai', 'bn': 'সম্পন্ন', 'ha': 'An Gama',
    'so': 'La Dhammeeyay', 'fa': 'انجام شد', 'ms': 'Selesai',
  },
  'tag_coming_soon_label': {
    'ar': 'قريبًا', 'en': 'Soon', 'am': 'በቅርቡ', 'fr': 'Bientôt', 'sw': 'Hivi Karibuni',
    'ur': 'جلد', 'tr': 'Yakında', 'id': 'Segera', 'bn': 'শীঘ্রই', 'ha': 'Nan Ba Da Jimawa Ba',
    'so': 'Dhawaan', 'fa': 'به‌زودی', 'ms': 'Akan Datang',
  },
  'tag_continue_now_label': {
    'ar': 'تابع الآن', 'en': 'Continue Now', 'am': 'አሁን ይቀጥሉ', 'fr': 'Continuer maintenant', 'sw': 'Endelea Sasa',
    'ur': 'ابھی جاری رکھیں', 'tr': 'Şimdi Devam Et', 'id': 'Lanjutkan Sekarang', 'bn': 'এখন চালিয়ে যান', 'ha': 'Ci Gaba Yanzu',
    'so': 'Sii Wad Hadda', 'fa': 'اکنون ادامه دهید', 'ms': 'Teruskan Sekarang',
  },
  'tag_open_label': {
    'ar': 'افتح', 'en': 'Open', 'am': 'ክፈት', 'fr': 'Ouvrir', 'sw': 'Fungua',
    'ur': 'کھولیں', 'tr': 'Aç', 'id': 'Buka', 'bn': 'খুলুন', 'ha': 'Buɗe',
    'so': 'Fur', 'fa': 'باز کن', 'ms': 'Buka',
  },
  'you_are_here_badge': {
    'ar': 'أنت هنا', 'en': 'You Are Here', 'am': 'እርስዎ እዚህ ነዎት', 'fr': 'Vous êtes ici', 'sw': 'Uko Hapa',
    'ur': 'آپ یہاں ہیں', 'tr': 'Buradasınız', 'id': 'Anda di Sini', 'bn': 'আপনি এখানে আছেন', 'ha': 'Kana Nan',
    'so': 'Halkan Ayaad Joogtaa', 'fa': 'شما اینجا هستید', 'ms': 'Anda Di Sini',
  },
  // 2026-08-22: audio_library_screen.dart. Series titles/author/category
  // come from audio_series_seed.dart (curated content), out of scope.
  'audio_library_title': {
    'ar': 'كتب صوتية من اليوتيوب', 'en': 'Audiobooks from YouTube', 'am': 'ከዩቲዩብ የድምጽ መጻሕፍት', 'fr': 'Livres audio depuis YouTube', 'sw': 'Vitabu vya Sauti kutoka YouTube',
    'ur': 'یوٹیوب سے آڈیو بکس', 'tr': "YouTube'dan Sesli Kitaplar", 'id': 'Buku Audio dari YouTube', 'bn': 'ইউটিউব থেকে অডিওবুক', 'ha': 'Littattafan Murya daga YouTube',
    'so': 'Buugaagta Codka ee YouTube', 'fa': 'کتاب‌های صوتی از یوتیوب', 'ms': 'Buku Audio dari YouTube',
  },
  'add_series_tooltip': {
    'ar': 'أضف سلسلة', 'en': 'Add a Series', 'am': 'ተከታታይ ጨምር', 'fr': 'Ajouter une série', 'sw': 'Ongeza Mfululizo',
    'ur': 'سلسلہ شامل کریں', 'tr': 'Seri Ekle', 'id': 'Tambah Seri', 'bn': 'সিরিজ যোগ করুন', 'ha': 'Ƙara Jerin',
    'so': 'Ku dar Taxane', 'fa': 'افزودن مجموعه', 'ms': 'Tambah Siri',
  },
  'add_audio_series_title': {
    'ar': 'أضف سلسلة صوتية', 'en': 'Add an Audio Series', 'am': 'የድምጽ ተከታታይ ጨምር', 'fr': 'Ajouter une série audio', 'sw': 'Ongeza Mfululizo wa Sauti',
    'ur': 'آڈیو سلسلہ شامل کریں', 'tr': 'Sesli Seri Ekle', 'id': 'Tambah Seri Audio', 'bn': 'অডিও সিরিজ যোগ করুন', 'ha': 'Ƙara Jerin Murya',
    'so': 'Ku dar Taxane Cod ah', 'fa': 'افزودن مجموعه صوتی', 'ms': 'Tambah Siri Audio',
  },
  'series_or_lesson_name_label': {
    'ar': 'اسم السلسلة أو الدرس', 'en': 'Series or Lesson Name', 'am': 'የተከታታይ ወይም ትምህርት ስም', 'fr': 'Nom de la série ou de la leçon', 'sw': 'Jina la Mfululizo au Somo',
    'ur': 'سلسلہ یا سبق کا نام', 'tr': 'Seri veya Ders Adı', 'id': 'Nama Seri atau Pelajaran', 'bn': 'সিরিজ বা পাঠের নাম', 'ha': 'Sunan Jerin ko Darasi',
    'so': 'Magaca Taxanaha ama Casharka', 'fa': 'نام مجموعه یا درس', 'ms': 'Nama Siri atau Pelajaran',
  },
  'youtube_link_label': {
    'ar': 'رابط يوتيوب (فيديو أو قائمة تشغيل)', 'en': 'YouTube Link (video or playlist)', 'am': 'የዩቲዩብ አገናኝ (ቪዲዮ ወይም ማጫወቻ ዝርዝር)', 'fr': 'Lien YouTube (vidéo ou playlist)', 'sw': 'Kiungo cha YouTube (video au orodha ya kucheza)',
    'ur': 'یوٹیوب لنک (ویڈیو یا پلے لسٹ)', 'tr': 'YouTube Bağlantısı (video veya oynatma listesi)', 'id': 'Tautan YouTube (video atau playlist)', 'bn': 'ইউটিউব লিঙ্ক (ভিডিও বা প্লেলিস্ট)', 'ha': 'Hanyar YouTube (bidiyo ko jerin kunnawa)',
    'so': 'Xiriirka YouTube (fiidiyow ama liiska ciyaarista)', 'fa': 'لینک یوتیوب (ویدیو یا پلی‌لیست)', 'ms': 'Pautan YouTube (video atau senarai main)',
  },
  'youtube_no_download_disclaimer': {
    'ar': 'يُشغَّل عبر مشغّل يوتيوب الرسمي داخل التطبيق — لا يُحمَّل أي شيء على جهازك', 'en': "Played via YouTube's official player inside the app — nothing is downloaded to your device", 'am': 'በመተግበሪያው ውስጥ ባለው ኦፊሴላዊ የዩቲዩብ አጫዋች ይጫወታል — ምንም ነገር ወደ መሳሪያዎ አይወርድም', 'fr': "Lu via le lecteur officiel de YouTube dans l'application — rien n'est téléchargé sur votre appareil", 'sw': 'Inachezwa kupitia kicheza sauti rasmi cha YouTube ndani ya programu — hakuna kinachopakuliwa kwenye kifaa chako',
    'ur': 'ایپ کے اندر یوٹیوب کے آفیشل پلیئر کے ذریعے چلایا جاتا ہے — آپ کے آلے پر کچھ بھی ڈاؤن لوڈ نہیں ہوتا', 'tr': "Uygulama içindeki resmi YouTube oynatıcısı ile çalınır — cihazınıza hiçbir şey indirilmez", 'id': 'Diputar melalui pemutar resmi YouTube di dalam aplikasi — tidak ada yang diunduh ke perangkat Anda', 'bn': 'অ্যাপের ভেতরে ইউটিউবের অফিসিয়াল প্লেয়ারের মাধ্যমে চালানো হয় — আপনার ডিভাইসে কিছুই ডাউনলোড হয় না', 'ha': "Ana kunna shi ta hanyar mai kunnawa na hukuma na YouTube a cikin manhajar — babu wani abu da ake sauke wa na'urarka",
    'so': 'Waxaa lagu ciyaaraa cayaartoyga rasmiga ah ee YouTube ee ku jira app-ka — waxba lagama soo dejinayo qalabkaaga', 'fa': 'از طریق پخش‌کننده رسمی یوتیوب در برنامه پخش می‌شود — چیزی روی دستگاه شما دانلود نمی‌شود', 'ms': 'Dimainkan melalui pemain rasmi YouTube dalam aplikasi — tiada apa-apa dimuat turun ke peranti anda',
  },
  'series_validation_error': {
    'ar': 'تأكد من إدخال الاسم ورابط يوتيوب صحيح', 'en': 'Make sure you entered a name and a valid YouTube link', 'am': 'ስም እና ትክክለኛ የዩቲዩብ አገናኝ ማስገባትዎን ያረጋግጡ', 'fr': "Assurez-vous d'avoir saisi un nom et un lien YouTube valide", 'sw': 'Hakikisha umeweka jina na kiungo sahihi cha YouTube',
    'ur': 'یقینی بنائیں کہ آپ نے نام اور درست یوٹیوب لنک درج کیا ہے', 'tr': "Bir ad ve geçerli bir YouTube bağlantısı girdiğinizden emin olun", 'id': 'Pastikan Anda memasukkan nama dan tautan YouTube yang valid', 'bn': 'নিশ্চিত করুন যে আপনি একটি নাম এবং সঠিক ইউটিউব লিঙ্ক লিখেছেন', 'ha': "Ka tabbatar ka shigar da suna da hanyar YouTube mai inganci",
    'so': 'Hubi inaad gelisay magac iyo xiriir YouTube oo sax ah', 'fa': 'مطمئن شوید نام و لینک یوتیوب معتبری وارد کرده‌اید', 'ms': 'Pastikan anda memasukkan nama dan pautan YouTube yang sah',
  },
  'delete_series_title': {
    'ar': 'حذف السلسلة', 'en': 'Delete Series', 'am': 'ተከታታይ ሰርዝ', 'fr': 'Supprimer la série', 'sw': 'Futa Mfululizo',
    'ur': 'سلسلہ حذف کریں', 'tr': 'Seriyi Sil', 'id': 'Hapus Seri', 'bn': 'সিরিজ মুছুন', 'ha': 'Share Jerin',
    'so': 'Tirtir Taxanaha', 'fa': 'حذف مجموعه', 'ms': 'Padam Siri',
  },
  'delete_series_confirm_prefix': {
    'ar': 'حذف', 'en': 'Delete', 'am': 'ሰርዝ', 'fr': 'Supprimer', 'sw': 'Futa',
    'ur': 'حذف کریں', 'tr': 'Sil', 'id': 'Hapus', 'bn': 'মুছুন', 'ha': 'Share',
    'so': 'Tirtir', 'fa': 'حذف', 'ms': 'Padam',
  },
  'delete_series_confirm_suffix': {
    'ar': '؟ هذا لا يحذف الفيديو من يوتيوب، فقط من قائمتك هنا.', 'en': "? This won't delete the video from YouTube, only from your list here.", 'am': '? ይህ ቪዲዮውን ከዩቲዩብ አይሰርዝም፣ ከዚህ ካለው ዝርዝርዎ ብቻ ነው።', 'fr': " ? Cela ne supprime pas la vidéo de YouTube, seulement de votre liste ici.", 'sw': '? Hii haifuti video kutoka YouTube, ni kutoka orodha yako hapa tu.',
    'ur': '؟ یہ ویڈیو کو یوٹیوب سے حذف نہیں کرے گا، صرف یہاں آپ کی فہرست سے۔', 'tr': "? Bu, videoyu YouTube'dan silmez, yalnızca buradaki listenizden siler.", 'id': '? Ini tidak menghapus video dari YouTube, hanya dari daftar Anda di sini.', 'bn': '? এটি ইউটিউব থেকে ভিডিও মুছবে না, শুধু এখানে আপনার তালিকা থেকে।', 'ha': "? Wannan ba ya share bidiyon daga YouTube, sai daga jerinka a nan kawai.",
    'so': '? Tani kama tirtirto fiidiyowga YouTube, waxay ka tirtirtaa kaliya liiskaaga halkan.', 'fa': '؟ این ویدیو را از یوتیوب حذف نمی‌کند، فقط از فهرست شما در اینجا حذف می‌شود.', 'ms': '? Ini tidak memadam video daripada YouTube, hanya daripada senarai anda di sini.',
  },
  'audio_stream_disclaimer': {
    'ar': 'تُبَث هذه المقاطع مباشرة من يوتيوب عبر مشغّله الرسمي — لا يُحمَّل أو يُعاد استضافة أي صوت داخل التطبيق، ويحتاج التشغيل اتصالًا بالإنترنت.', 'en': "These clips stream directly from YouTube via its official player — no audio is downloaded or rehosted inside the app, and playback needs an internet connection.", 'am': 'እነዚህ ክሊፖች በኦፊሴላዊ አጫዋቹ በኩል በቀጥታ ከዩቲዩብ ይተላለፋሉ — በመተግበሪያው ውስጥ ምንም ድምጽ አይወርድም ወይም እንደገና አይስተናገድም፣ መልሶ ማጫወት የኢንተርኔት ግንኙነት ይፈልጋል።', 'fr': "Ces extraits sont diffusés directement depuis YouTube via son lecteur officiel — aucun audio n'est téléchargé ou réhébergé dans l'application, et la lecture nécessite une connexion internet.", 'sw': 'Klipu hizi zinatiririka moja kwa moja kutoka YouTube kupitia kicheza chake rasmi — hakuna sauti inayopakuliwa au kuhifadhiwa upya ndani ya programu, na uchezaji unahitaji muunganisho wa mtandao.',
    'ur': 'یہ کلپس براہ راست یوٹیوب کے آفیشل پلیئر کے ذریعے سٹریم ہوتے ہیں — ایپ کے اندر کوئی آڈیو ڈاؤن لوڈ یا دوبارہ ہوسٹ نہیں ہوتی، اور چلانے کے لیے انٹرنیٹ کنکشن درکار ہے۔', 'tr': "Bu klipler resmi oynatıcısı aracılığıyla doğrudan YouTube'dan akışa alınır — uygulama içinde hiçbir ses indirilmez veya yeniden barındırılmaz ve oynatma için internet bağlantısı gerekir.", 'id': 'Klip ini di-streaming langsung dari YouTube melalui pemutar resminya — tidak ada audio yang diunduh atau di-hosting ulang di dalam aplikasi, dan pemutaran memerlukan koneksi internet.', 'bn': 'এই ক্লিপগুলো সরাসরি ইউটিউবের অফিসিয়াল প্লেয়ারের মাধ্যমে স্ট্রিম হয় — অ্যাপের ভেতরে কোনো অডিও ডাউনলোড বা পুনরায় হোস্ট করা হয় না, এবং প্লেব্যাকের জন্য ইন্টারনেট সংযোগ প্রয়োজন।', 'ha': "Waɗannan gutsuttsura ana yin streaming kai tsaye daga YouTube ta hanyar mai kunnawa na hukuma — babu wani sauti da ake saukewa ko sake watsawa a cikin manhajar, kuma kunnawa yana buƙatar haɗin intanet.",
    'so': 'Jajabkan waxaa laga sii daayaa si toos ah YouTube iyada oo la adeegsanayo cayaartoygeeda rasmiga ah — cod lagama soo dejiyo ama dib looma martigelin app-ka gudihiisa, ciyaarintuna waxay u baahan tahay xiriir internet ah.', 'fa': 'این کلیپ‌ها مستقیماً از یوتیوب از طریق پخش‌کننده رسمی آن پخش می‌شوند — هیچ صدایی در برنامه دانلود یا بازمیزبانی نمی‌شود و پخش نیاز به اتصال اینترنت دارد.', 'ms': 'Klip ini distrim terus daripada YouTube melalui pemain rasminya — tiada audio dimuat turun atau dihoskan semula dalam aplikasi, dan main balik memerlukan sambungan internet.',
  },
  'my_own_series_header': {
    'ar': 'سلاسلي الخاصة', 'en': 'My Own Series', 'am': 'የራሴ ተከታታዮች', 'fr': 'Mes propres séries', 'sw': 'Mifululizo Yangu Mwenyewe',
    'ur': 'میرے اپنے سلسلے', 'tr': 'Kendi Serilerim', 'id': 'Seri Saya Sendiri', 'bn': 'আমার নিজস্ব সিরিজ', 'ha': 'Jerina na Kaina',
    'so': 'Taxanahayga Gaarka ah', 'fa': 'مجموعه‌های خودم', 'ms': 'Siri Saya Sendiri',
  },
  'playlist_subtitle_label': {
    'ar': 'قائمة تشغيل', 'en': 'Playlist', 'am': 'ማጫወቻ ዝርዝር', 'fr': 'Playlist', 'sw': 'Orodha ya Kucheza',
    'ur': 'پلے لسٹ', 'tr': 'Oynatma Listesi', 'id': 'Playlist', 'bn': 'প্লেলিস্ট', 'ha': 'Jerin Kunnawa',
    'so': 'Liiska Ciyaarista', 'fa': 'پلی‌لیست', 'ms': 'Senarai Main',
  },
  'single_video_subtitle_label': {
    'ar': 'فيديو واحد', 'en': 'Single Video', 'am': 'ነጠላ ቪዲዮ', 'fr': 'Vidéo unique', 'sw': 'Video Moja',
    'ur': 'ایک ویڈیو', 'tr': 'Tek Video', 'id': 'Video Tunggal', 'bn': 'একটি ভিডিও', 'ha': 'Bidiyo Ɗaya',
    'so': 'Fiidiyow Kaliya', 'fa': 'یک ویدیو', 'ms': 'Video Tunggal',
  },
  // 2026-08-22: audio_player_screen.dart.
  'episode_word_label': {
    'ar': 'الحلقة', 'en': 'Episode', 'am': 'ክፍል', 'fr': 'Épisode', 'sw': 'Kipindi',
    'ur': 'قسط', 'tr': 'Bölüm', 'id': 'Episode', 'bn': 'পর্ব', 'ha': 'Kashi',
    'so': 'Qeybta', 'fa': 'قسمت', 'ms': 'Episod',
  },
  'resumed_from_saved_message': {
    'ar': 'استؤنف من حيث توقفت آخر مرة', 'en': 'Resumed from where you last stopped', 'am': 'ካቆሙበት ተቀጠለ', 'fr': "Repris là où vous vous étiez arrêté", 'sw': 'Imeendelezwa kutoka ulipoishia mara ya mwisho',
    'ur': 'وہاں سے جاری جہاں آپ نے آخری بار روکا تھا', 'tr': "Son bıraktığınız yerden devam edildi", 'id': 'Dilanjutkan dari terakhir Anda berhenti', 'bn': 'আপনি সর্বশেষ যেখানে থেমেছিলেন সেখান থেকে চালু হয়েছে', 'ha': "An ci gaba daga inda ka tsaya a karo na ƙarshe",
    'so': 'Waxaa laga sii watay meeshii aad markii ugu dambeysay ka joogsatay', 'fa': 'از جایی که آخرین بار متوقف شدید ادامه یافت', 'ms': 'Diteruskan dari tempat anda berhenti kali terakhir',
  },
  'previous_episode_action': {
    'ar': 'السابقة', 'en': 'Previous', 'am': 'የቀድሞው', 'fr': 'Précédent', 'sw': 'Iliyotangulia',
    'ur': 'پچھلی', 'tr': 'Önceki', 'id': 'Sebelumnya', 'bn': 'পূর্ববর্তী', 'ha': 'Na Baya',
    'so': 'Tii Hore', 'fa': 'قبلی', 'ms': 'Sebelumnya',
  },
  'next_episode_action': {
    'ar': 'التالية', 'en': 'Next', 'am': 'ቀጣይ', 'fr': 'Suivant', 'sw': 'Ifuatayo',
    'ur': 'اگلی', 'tr': 'Sonraki', 'id': 'Selanjutnya', 'bn': 'পরবর্তী', 'ha': 'Na Gaba',
    'so': 'Tii Xigta', 'fa': 'بعدی', 'ms': 'Seterusnya',
  },
  'open_episode_in_youtube_action': {
    'ar': 'افتح هذه الحلقة في يوتيوب', 'en': 'Open This Episode in YouTube', 'am': 'ይህን ክፍል በዩቲዩብ ይክፈቱ', 'fr': "Ouvrir cet épisode dans YouTube", 'sw': 'Fungua Kipindi Hiki katika YouTube',
    'ur': 'یہ قسط یوٹیوب میں کھولیں', 'tr': "Bu Bölümü YouTube'da Aç", 'id': 'Buka Episode Ini di YouTube', 'bn': 'এই পর্বটি ইউটিউবে খুলুন', 'ha': "Buɗe Wannan Kashi a YouTube",
    'so': 'Ku Fur Qeybtan YouTube', 'fa': 'باز کردن این قسمت در یوتیوب', 'ms': 'Buka Episod Ini di YouTube',
  },
  'from_beginning_action': {
    'ar': 'من البداية', 'en': 'From the Beginning', 'am': 'ከመጀመሪያ', 'fr': 'Depuis le début', 'sw': 'Kutoka Mwanzo',
    'ur': 'شروع سے', 'tr': 'Baştan', 'id': 'Dari Awal', 'bn': 'শুরু থেকে', 'ha': 'Daga Farko',
    'so': 'Bilowga', 'fa': 'از ابتدا', 'ms': 'Dari Permulaan',
  },
  'open_full_playlist_action': {
    'ar': 'افتح القائمة كاملة في يوتيوب', 'en': 'Open Full Playlist in YouTube', 'am': 'ሙሉ ማጫወቻ ዝርዝርን በዩቲዩብ ይክፈቱ', 'fr': "Ouvrir la playlist complète dans YouTube", 'sw': 'Fungua Orodha Kamili katika YouTube',
    'ur': 'مکمل پلے لسٹ یوٹیوب میں کھولیں', 'tr': "Tam Oynatma Listesini YouTube'da Aç", 'id': 'Buka Playlist Lengkap di YouTube', 'bn': 'সম্পূর্ণ প্লেলিস্ট ইউটিউবে খুলুন', 'ha': "Buɗe Cikakken Jerin Kunnawa a YouTube",
    'so': 'Ku Fur Liiska Oo Dhan YouTube', 'fa': 'باز کردن پلی‌لیست کامل در یوتیوب', 'ms': 'Buka Senarai Main Penuh di YouTube',
  },
  'episodes_header': {
    'ar': 'الحلقات', 'en': 'Episodes', 'am': 'ክፍሎች', 'fr': 'Épisodes', 'sw': 'Vipindi',
    'ur': 'اقساط', 'tr': 'Bölümler', 'id': 'Episode', 'bn': 'পর্বসমূহ', 'ha': 'Kashe-kashe',
    'so': 'Qeybaha', 'fa': 'قسمت‌ها', 'ms': 'Episod-episod',
  },
  'reflection_notebook_header': {
    'ar': 'دفتر الفوائد', 'en': 'Reflections Notebook', 'am': 'የማስታወሻ ደብተር', 'fr': 'Carnet de réflexions', 'sw': 'Daftari la Mafunzo',
    'ur': 'فوائد کی نوٹ بک', 'tr': 'Notlar Defteri', 'id': 'Buku Catatan Manfaat', 'bn': 'শিক্ষার নোটবই', 'ha': "Littafin Fa'idodi",
    'so': 'Buugga Faa\'iidooyinka', 'fa': 'دفترچه دستاوردها', 'ms': 'Buku Nota Manfaat',
  },
  'reflection_notebook_subtitle': {
    'ar': 'اكتب ملخصًا أو فائدة استفدتها من هذه الحلقة — لنفسك، لا أحد غيرك سيراها', 'en': "Write a summary or benefit you took from this episode — for yourself, no one else will see it", 'am': 'ከዚህ ክፍል ያገኙትን ማጠቃለያ ወይም ጥቅም ይጻፉ — ለራስዎ ብቻ፣ ከእርስዎ በቀር ማንም አያየውም', 'fr': "Écrivez un résumé ou un bénéfice tiré de cet épisode — pour vous-même, personne d'autre ne le verra", 'sw': 'Andika muhtasari au faida uliyopata kutoka kipindi hiki — kwa ajili yako, hakuna mwingine atakayeona',
    'ur': 'اس قسط سے حاصل کردہ خلاصہ یا فائدہ لکھیں — اپنے لیے، آپ کے سوا کوئی نہیں دیکھے گا', 'tr': "Bu bölümden aldığınız özeti veya faydayı yazın — kendiniz için, sizden başka kimse görmeyecek", 'id': 'Tulis ringkasan atau manfaat yang Anda ambil dari episode ini — untuk diri Anda sendiri, tidak ada yang lain akan melihatnya', 'bn': 'এই পর্ব থেকে পাওয়া সারাংশ বা উপকারিতা লিখুন — নিজের জন্য, আপনি ছাড়া কেউ এটি দেখবে না', 'ha': "Rubuta taƙaitawa ko fa'idar da ka samu daga wannan kashi — don kanka, babu wanda zai gan shi sai kai",
    'so': 'Qor soo koobid ama faa\'iido aad ka heshay qeybtan — naftaada, ma jiro cid kale oo arki doonta', 'fa': 'خلاصه یا فایده‌ای که از این قسمت گرفتید بنویسید — برای خودتان، هیچ‌کس دیگری آن را نمی‌بیند', 'ms': 'Tulis ringkasan atau manfaat yang anda perolehi daripada episod ini — untuk diri sendiri, tiada siapa lain akan melihatnya',
  },
  'reflection_note_hint': {
    'ar': 'اكتب ما استفدته هنا...', 'en': 'Write what you benefited from here...', 'am': 'ያገኙትን ጥቅም እዚህ ይጻፉ...', 'fr': 'Écrivez ici ce dont vous avez profité...', 'sw': 'Andika hapa ulichofaidika...',
    'ur': 'یہاں لکھیں کہ آپ نے کیا فائدہ حاصل کیا...', 'tr': 'Buraya edindiğiniz faydayı yazın...', 'id': 'Tulis di sini apa yang Anda dapatkan...', 'bn': 'আপনি যা উপকার পেয়েছেন তা এখানে লিখুন...', 'ha': "Rubuta abin da ka amfana a nan...",
    'so': 'Halkan ku qor waxa aad ka faa\'iidaysatay...', 'fa': 'آنچه از آن بهره بردید اینجا بنویسید...', 'ms': 'Tulis di sini apa yang anda perolehi...',
  },
  'resume_point_hint_full': {
    'ar': 'أين توقفت؟ (رابط أو الوقت) — احتياطًا إن تعطّل الفيديو', 'en': "Where did you stop? (link or time) — just in case the video breaks", 'am': 'የት ደረሱ? (አገናኝ ወይም ሰዓት) — ቪዲዮ ችግር ቢፈጠር ለጥንቃቄ', 'fr': "Où vous êtes-vous arrêté ? (lien ou heure) — au cas où la vidéo se casserait", 'sw': 'Uliishia wapi? (kiungo au wakati) — ikiwa video itaharibika',
    'ur': 'آپ کہاں رکے؟ (لنک یا وقت) — احتیاطاً اگر ویڈیو خراب ہو جائے', 'tr': "Nerede kaldınız? (bağlantı veya zaman) — video bozulursa diye", 'id': 'Di mana Anda berhenti? (tautan atau waktu) — jaga-jaga jika video rusak', 'bn': 'আপনি কোথায় থেমেছেন? (লিঙ্ক বা সময়) — ভিডিও নষ্ট হলে সতর্কতাস্বরূপ', 'ha': "Ina ka tsaya? (hanya ko lokaci) — idan bidiyon ya lalace",
    'so': 'Xagee ka joogsatay? (xiriir ama waqti) — taxaddar ahaan haddii fiidiyowga jabo', 'fa': 'کجا متوقف شدید؟ (لینک یا زمان) — احتیاطاً اگر ویدیو خراب شود', 'ms': 'Di mana anda berhenti? (pautan atau masa) — sekiranya video rosak',
  },
  'save_note_action': {
    'ar': 'حفظ الملاحظة', 'en': 'Save Note', 'am': 'ማስታወሻ አስቀምጥ', 'fr': 'Enregistrer la note', 'sw': 'Hifadhi Ujumbe',
    'ur': 'نوٹ محفوظ کریں', 'tr': 'Notu Kaydet', 'id': 'Simpan Catatan', 'bn': 'নোট সংরক্ষণ করুন', 'ha': 'Ajiye Bayanin',
    'so': 'Kaydi Faallada', 'fa': 'ذخیره یادداشت', 'ms': 'Simpan Nota',
  },
  'note_saved_message': {
    'ar': 'تم حفظ ملاحظتك', 'en': 'Your note was saved', 'am': 'ማስታወሻዎ ተቀምጧል', 'fr': 'Votre note a été enregistrée', 'sw': 'Ujumbe wako umehifadhiwa',
    'ur': 'آپ کا نوٹ محفوظ ہو گیا', 'tr': 'Notunuz kaydedildi', 'id': 'Catatan Anda telah disimpan', 'bn': 'আপনার নোট সংরক্ষিত হয়েছে', 'ha': 'An Ajiye Bayaninka',
    'so': 'Faalladaadii waa la kaydiyay', 'fa': 'یادداشت شما ذخیره شد', 'ms': 'Nota anda telah disimpan',
  },
  'your_notes_on_episode_header': {
    'ar': 'ملاحظاتك على هذه الحلقة', 'en': 'Your Notes on This Episode', 'am': 'በዚህ ክፍል ላይ ያሉ ማስታወሻዎችዎ', 'fr': 'Vos notes sur cet épisode', 'sw': 'Ujumbe Wako kwa Kipindi Hiki',
    'ur': 'اس قسط پر آپ کے نوٹس', 'tr': 'Bu Bölümdeki Notlarınız', 'id': 'Catatan Anda tentang Episode Ini', 'bn': 'এই পর্বে আপনার নোট', 'ha': "Bayaninka Kan Wannan Kashi",
    'so': 'Faalladaada Qeybtan', 'fa': 'یادداشت‌های شما درباره این قسمت', 'ms': 'Nota Anda tentang Episod Ini',
  },
  'stopped_at_prefix': {
    'ar': 'توقفت عند:', 'en': 'Stopped at:', 'am': 'ያቆሙት፦', 'fr': 'Arrêté à :', 'sw': 'Umeishia:',
    'ur': 'رک گئے:', 'tr': 'Kaldığınız yer:', 'id': 'Berhenti di:', 'bn': 'থেমেছেন:', 'ha': 'Ka Tsaya:',
    'so': 'Ku Joogsaday:', 'fa': 'متوقف شده در:', 'ms': 'Berhenti di:',
  },
  'edit_note_title': {
    'ar': 'تعديل الملاحظة', 'en': 'Edit Note', 'am': 'ማስታወሻ አርትዕ', 'fr': 'Modifier la note', 'sw': 'Hariri Ujumbe',
    'ur': 'نوٹ میں ترمیم کریں', 'tr': 'Notu Düzenle', 'id': 'Ubah Catatan', 'bn': 'নোট সম্পাদনা করুন', 'ha': 'Gyara Bayanin',
    'so': 'Wax ka beddel Faallada', 'fa': 'ویرایش یادداشت', 'ms': 'Edit Nota',
  },
  'resume_point_label_short': {
    'ar': 'أين توقفت؟ (رابط أو الوقت)', 'en': 'Where did you stop? (link or time)', 'am': 'የት ደረሱ? (አገናኝ ወይም ሰዓት)', 'fr': 'Où vous êtes-vous arrêté ? (lien ou heure)', 'sw': 'Uliishia wapi? (kiungo au wakati)',
    'ur': 'آپ کہاں رکے؟ (لنک یا وقت)', 'tr': 'Nerede kaldınız? (bağlantı veya zaman)', 'id': 'Di mana Anda berhenti? (tautan atau waktu)', 'bn': 'আপনি কোথায় থেমেছেন? (লিঙ্ক বা সময়)', 'ha': "Ina ka tsaya? (hanya ko lokaci)",
    'so': 'Xagee ka joogsatay? (xiriir ama waqti)', 'fa': 'کجا متوقف شدید؟ (لینک یا زمان)', 'ms': 'Di mana anda berhenti? (pautan atau masa)',
  },
  'delete_note_title': {
    'ar': 'مسح الملاحظة؟', 'en': 'Delete this note?', 'am': 'ማስታወሻውን ይሰርዙ?', 'fr': 'Supprimer cette note ?', 'sw': 'Futa ujumbe huu?',
    'ur': 'کیا یہ نوٹ حذف کریں؟', 'tr': 'Bu not silinsin mi?', 'id': 'Hapus catatan ini?', 'bn': 'এই নোটটি মুছবেন?', 'ha': 'Share wannan bayanin?',
    'so': 'Ma tirtirtaa faalladan?', 'fa': 'این یادداشت حذف شود؟', 'ms': 'Padam nota ini?',
  },
  'cannot_undo_message': {
    'ar': 'لا يمكن التراجع عن هذا.', 'en': "This can't be undone.", 'am': 'ይህ ሊቀለበስ አይችልም።', 'fr': 'Cette action est irréversible.', 'sw': 'Hii haiwezi kutenguliwa.',
    'ur': 'اسے واپس نہیں لیا جا سکتا۔', 'tr': 'Bu geri alınamaz.', 'id': 'Ini tidak dapat dibatalkan.', 'bn': 'এটি পূর্বাবস্থায় ফেরানো যাবে না।', 'ha': 'Ba za a iya soke wannan ba.',
    'so': 'Tan lama celin karo.', 'fa': 'این عمل قابل بازگشت نیست.', 'ms': 'Ini tidak boleh dibuat asal.',
  },
  'reflection_prompt_1': {
    'ar': 'ما الفكرة التي لفتت انتباهك في هذا المقطع؟', 'en': 'What idea caught your attention in this clip?', 'am': 'በዚህ ክሊፕ ውስጥ ትኩረትዎን የሳበው ሐሳብ ምንድን ነው?', 'fr': "Quelle idée a attiré votre attention dans cet extrait ?", 'sw': 'Wazo lipi lilikuvutia katika klipu hii?',
    'ur': 'اس کلپ میں کس خیال نے آپ کی توجہ حاصل کی؟', 'tr': "Bu klipte hangi fikir dikkatinizi çekti?", 'id': 'Ide apa yang menarik perhatian Anda dalam klip ini?', 'bn': 'এই ক্লিপে কোন ধারণা আপনার নজর কাড়ল?', 'ha': "Wace fikira ce ta jawo hankalinka a wannan gutsuren?",
    'so': 'Fikirradee ayaa dareenkaaga soo jiitay jajabkan?', 'fa': 'چه ایده‌ای در این کلیپ توجه شما را جلب کرد؟', 'ms': 'Idea apakah yang menarik perhatian anda dalam klip ini?',
  },
  'reflection_prompt_2': {
    'ar': 'كيف يمكن أن تطبّق هذا في حياتك اليوم؟', 'en': 'How could you apply this in your life today?', 'am': 'ይህንን በዛሬው ህይወትዎ እንዴት ተግባራዊ ማድረግ ይችላሉ?', 'fr': "Comment pourriez-vous appliquer cela dans votre vie aujourd'hui ?", 'sw': 'Unawezaje kutekeleza hili katika maisha yako leo?',
    'ur': 'آپ آج اسے اپنی زندگی میں کیسے لاگو کر سکتے ہیں؟', 'tr': "Bunu bugün hayatınıza nasıl uygulayabilirsiniz?", 'id': 'Bagaimana Anda bisa menerapkan ini dalam hidup Anda hari ini?', 'bn': 'আজ আপনার জীবনে এটি কীভাবে প্রয়োগ করতে পারেন?', 'ha': "Ta yaya za ka aiwatar da wannan a rayuwarka yau?",
    'so': 'Sideed ku dhaqan gelin kartaa tan noloshaada maanta?', 'fa': 'چگونه می‌توانید امروز این را در زندگی خود به کار ببرید؟', 'ms': 'Bagaimana anda boleh mengamalkan ini dalam hidup anda hari ini?',
  },
  'reflection_prompt_3': {
    'ar': 'ما سؤال بقي عندك تريد البحث عنه لاحقًا؟', 'en': "What question do you still want to look up later?", 'am': 'በኋላ ለመፈለግ የሚፈልጉት ጥያቄ ምንድን ነው?', 'fr': "Quelle question voulez-vous encore approfondir plus tard ?", 'sw': 'Ni swali gani bado unataka kutafuta baadaye?',
    'ur': 'کون سا سوال باقی رہ گیا جسے آپ بعد میں تلاش کرنا چاہتے ہیں؟', 'tr': "Daha sonra araştırmak istediğiniz hangi soru kaldı?", 'id': 'Pertanyaan apa yang masih ingin Anda cari tahu nanti?', 'bn': 'পরে খুঁজে দেখতে চান এমন কোন প্রশ্ন রয়ে গেছে?', 'ha': "Wace tambaya ce ta rage wadda kake son bincika daga baya?",
    'so': 'Su\'aal kee ayaa kaa hadhay oo aad rabto inaad baadho goor dambe?', 'fa': 'چه سؤالی برایتان باقی مانده که بعداً می‌خواهید جستجو کنید؟', 'ms': 'Soalan apakah yang masih anda mahu cari kemudian?',
  },
  'reflection_prompt_4': {
    'ar': 'ما عبارة أو موقف أثّر فيك؟', 'en': 'What phrase or moment affected you?', 'am': 'የነካዎት ሐረግ ወይም ሁኔታ ምንድን ነው?', 'fr': "Quelle phrase ou quel moment vous a marqué ?", 'sw': 'Ni maneno au wakati gani ulikugusa?',
    'ur': 'کون سا جملہ یا لمحہ آپ کو متاثر کر گیا؟', 'tr': "Sizi hangi ifade ya da an etkiledi?", 'id': 'Frasa atau momen apa yang memengaruhi Anda?', 'bn': 'কোন বাক্য বা মুহূর্ত আপনাকে প্রভাবিত করেছিল?', 'ha': "Wace jimla ko lokaci ne ya shafe ka?",
    'so': 'Weerkee ama xaaladdee ayaa ku saameysay?', 'fa': 'چه عبارت یا لحظه‌ای بر شما تأثیر گذاشت؟', 'ms': 'Frasa atau detik apakah yang menyentuh anda?',
  },
  // 2026-08-22: personal_library_screen.dart. Book titles are user data,
  // not translated.
  'personal_library_title': {
    'ar': 'مكتبتي', 'en': 'My Library', 'am': 'ቤተ መጻሕፍቴ', 'fr': 'Ma bibliothèque', 'sw': 'Maktaba Yangu',
    'ur': 'میری لائبریری', 'tr': 'Kütüphanem', 'id': 'Perpustakaan Saya', 'bn': 'আমার গ্রন্থাগার', 'ha': 'Laburare Na',
    'so': 'Maktabadayda', 'fa': 'کتابخانه من', 'ms': 'Perpustakaan Saya',
  },
  'new_category_title': {
    'ar': 'قسم جديد', 'en': 'New Category', 'am': 'አዲስ ክፍል', 'fr': 'Nouvelle catégorie', 'sw': 'Jamii Mpya',
    'ur': 'نیا زمرہ', 'tr': 'Yeni Kategori', 'id': 'Kategori Baru', 'bn': 'নতুন বিভাগ', 'ha': 'Sabon Fanni',
    'so': 'Qaybo Cusub', 'fa': 'دسته جدید', 'ms': 'Kategori Baharu',
  },
  'category_name_hint_example': {
    'ar': 'مثال: الفقه', 'en': 'e.g.: Fiqh', 'am': 'ለምሳሌ፦ ፊቅህ', 'fr': 'par exemple : le fiqh', 'sw': 'k.m.: Fiqhi',
    'ur': 'مثلاً: فقہ', 'tr': 'örneğin: Fıkıh', 'id': 'misalnya: Fiqih', 'bn': 'যেমন: ফিকহ', 'ha': 'misali: Fikihu',
    'so': 'tusaale ahaan: Fiqhiga', 'fa': 'مثلاً: فقه', 'ms': 'contohnya: Fiqh',
  },
  'rename_category_title': {
    'ar': 'إعادة تسمية القسم', 'en': 'Rename Category', 'am': 'ክፍልን እንደገና ይሰይሙ', 'fr': 'Renommer la catégorie', 'sw': 'Badilisha Jina la Jamii',
    'ur': 'زمرے کا نام تبدیل کریں', 'tr': 'Kategoriyi Yeniden Adlandır', 'id': 'Ubah Nama Kategori', 'bn': 'বিভাগের নাম পরিবর্তন করুন', 'ha': 'Sake Suna Fanni',
    'so': 'Dib u Magacaw Qaybta', 'fa': 'تغییر نام دسته', 'ms': 'Namakan Semula Kategori',
  },
  'delete_category_title': {
    'ar': 'حذف القسم', 'en': 'Delete Category', 'am': 'ክፍል ሰርዝ', 'fr': 'Supprimer la catégorie', 'sw': 'Futa Jamii',
    'ur': 'زمرہ حذف کریں', 'tr': 'Kategoriyi Sil', 'id': 'Hapus Kategori', 'bn': 'বিভাগ মুছুন', 'ha': 'Share Fanni',
    'so': 'Tirtir Qaybta', 'fa': 'حذف دسته', 'ms': 'Padam Kategori',
  },
  'delete_category_confirm_prefix': {
    'ar': 'سيتم حذف قسم', 'en': 'This will delete the category', 'am': 'ክፍል ይሰረዛል', 'fr': 'Ceci supprimera la catégorie', 'sw': 'Hii itafuta jamii',
    'ur': 'یہ زمرہ حذف کر دے گا', 'tr': 'Bu kategori silinecek:', 'id': 'Ini akan menghapus kategori', 'bn': 'এটি বিভাগ মুছে ফেলবে', 'ha': 'Wannan zai share fannin',
    'so': 'Tan waxay tirtiri doontaa qaybta', 'fa': 'این کار دسته را حذف می‌کند', 'ms': 'Ini akan memadam kategori',
  },
  'delete_category_confirm_suffix': {
    'ar': 'فقط — الكتب بداخله ستبقى محفوظة ضمن "بدون قسم".', 'en': 'only — the books inside it will remain saved under "Uncategorized".', 'am': 'ብቻ — በውስጡ ያሉት መጻሕፍት በ"ያለ ክፍል" ውስጥ ተቀምጠው ይቆያሉ።', 'fr': 'uniquement — les livres qu\'elle contient resteront enregistrés sous "Sans catégorie".', 'sw': 'tu — vitabu vilivyomo vitabaki vimehifadhiwa chini ya "Bila Jamii".',
    'ur': 'صرف — اس کے اندر موجود کتابیں "بغیر زمرہ" میں محفوظ رہیں گی۔', 'tr': 'sadece — içindeki kitaplar "Kategorisiz" altında saklı kalacak.', 'id': 'saja — buku-buku di dalamnya akan tetap tersimpan di bawah "Tanpa Kategori".', 'bn': 'শুধু — এর ভেতরের বইগুলো "বিভাগহীন"-এর অধীনে সংরক্ষিত থাকবে।', 'ha': "kawai — littattafan da ke ciki za su ci gaba da ajiye a ƙarƙashin \"Ba Tare da Fanni Ba\".",
    'so': 'kaliya — buugagta gudaha ku jira waxay ku sii jiri doonaan "Qaybla\'aan".', 'fa': 'فقط — کتاب‌های داخل آن زیر "بدون دسته" ذخیره باقی می‌مانند.', 'ms': 'sahaja — buku di dalamnya akan kekal disimpan di bawah "Tiada Kategori".',
  },
  'uncategorized_label': {
    'ar': 'بدون قسم', 'en': 'Uncategorized', 'am': 'ያለ ክፍል', 'fr': 'Sans catégorie', 'sw': 'Bila Jamii',
    'ur': 'بغیر زمرہ', 'tr': 'Kategorisiz', 'id': 'Tanpa Kategori', 'bn': 'বিভাগহীন', 'ha': 'Ba Tare da Fanni Ba',
    'so': "Qaybla'aan", 'fa': 'بدون دسته', 'ms': 'Tiada Kategori',
  },
  'generic_category_fallback_name': {
    'ar': 'قسم', 'en': 'Category', 'am': 'ክፍል', 'fr': 'Catégorie', 'sw': 'Jamii',
    'ur': 'زمرہ', 'tr': 'Kategori', 'id': 'Kategori', 'bn': 'বিভাগ', 'ha': 'Fanni',
    'so': 'Qaybta', 'fa': 'دسته', 'ms': 'Kategori',
  },
  'add_book_failed_prefix': {
    'ar': 'تعذر إضافة الكتاب:', 'en': 'Could not add the book:', 'am': 'መጽሐፉን ማከል አልተቻለም፦', 'fr': "Impossible d'ajouter le livre :", 'sw': 'Imeshindikana kuongeza kitabu:',
    'ur': 'کتاب شامل نہیں کی جا سکی:', 'tr': 'Kitap eklenemedi:', 'id': 'Tidak dapat menambahkan buku:', 'bn': 'বই যোগ করা যায়নি:', 'ha': "An kasa ƙara littafin:",
    'so': 'Lama darsan buugga:', 'fa': 'افزودن کتاب ممکن نشد:', 'ms': 'Tidak dapat menambah buku:',
  },
  'delete_book_title': {
    'ar': 'حذف الكتاب', 'en': 'Delete Book', 'am': 'መጽሐፍ ሰርዝ', 'fr': 'Supprimer le livre', 'sw': 'Futa Kitabu',
    'ur': 'کتاب حذف کریں', 'tr': 'Kitabı Sil', 'id': 'Hapus Buku', 'bn': 'বই মুছুন', 'ha': 'Share Littafi',
    'so': 'Tirtir Buugga', 'fa': 'حذف کتاب', 'ms': 'Padam Buku',
  },
  'delete_book_confirm_prefix': {
    'ar': 'هل تريد حذف', 'en': 'Do you want to delete', 'am': 'መሰረዝ ይፈልጋሉ', 'fr': 'Voulez-vous supprimer', 'sw': 'Je, unataka kufuta',
    'ur': 'کیا آپ حذف کرنا چاہتے ہیں', 'tr': 'Silmek istiyor musunuz:', 'id': 'Apakah Anda ingin menghapus', 'bn': 'আপনি কি মুছে ফেলতে চান', 'ha': "Kana son share",
    'so': 'Ma doonaysaa inaad tirtirto', 'fa': 'آیا می‌خواهید حذف کنید', 'ms': 'Adakah anda ingin memadam',
  },
  'delete_book_confirm_suffix': {
    'ar': 'من مكتبتك؟', 'en': 'from your library?', 'am': 'ከቤተ መጻሕፍትዎ?', 'fr': 'de votre bibliothèque ?', 'sw': 'kutoka maktaba yako?',
    'ur': 'اپنی لائبریری سے؟', 'tr': 'kütüphanenizden?', 'id': 'dari perpustakaan Anda?', 'bn': 'আপনার লাইব্রেরি থেকে?', 'ha': 'daga laburarenka?',
    'so': 'maktabaddaada?', 'fa': 'از کتابخانه‌تان؟', 'ms': 'daripada perpustakaan anda?',
  },
  'copy_book_list_tooltip': {
    'ar': 'نسخ قائمة الكتب (نسخة احتياطية)', 'en': 'Copy Book List (backup)', 'am': 'የመጻሕፍት ዝርዝርን ይቅዱ (ምትኬ)', 'fr': 'Copier la liste des livres (sauvegarde)', 'sw': 'Nakili Orodha ya Vitabu (nakala rudufu)',
    'ur': 'کتابوں کی فہرست کاپی کریں (بیک اپ)', 'tr': 'Kitap Listesini Kopyala (yedek)', 'id': 'Salin Daftar Buku (cadangan)', 'bn': 'বইয়ের তালিকা কপি করুন (ব্যাকআপ)', 'ha': "Kwafi Jerin Littattafai (madadin)",
    'so': 'Koobi Liiska Buugagta (kaydin)', 'fa': 'کپی فهرست کتاب‌ها (پشتیبان)', 'ms': 'Salin Senarai Buku (sandaran)',
  },
  'book_list_copied_message': {
    'ar': 'تم نسخ قائمة الكتب — يمكنك لصقها في تلجرام أو الملاحظات كنسخة احتياطية.', 'en': "The book list was copied — you can paste it in Telegram or Notes as a backup.", 'am': 'የመጻሕፍት ዝርዝሩ ተቀድቷል — እንደ ምትኬ በቴሌግራም ወይም ማስታወሻዎች ውስጥ መለጠፍ ይችላሉ።', 'fr': "La liste des livres a été copiée — vous pouvez la coller dans Telegram ou dans les Notes comme sauvegarde.", 'sw': 'Orodha ya vitabu imenakiliwa — unaweza kubandika katika Telegram au Vidokezo kama nakala rudufu.',
    'ur': 'کتابوں کی فہرست کاپی ہو گئی — آپ اسے ٹیلیگرام یا نوٹس میں بیک اپ کے طور پر پیسٹ کر سکتے ہیں۔', 'tr': "Kitap listesi kopyalandı — yedek olarak Telegram'a veya Notlar'a yapıştırabilirsiniz.", 'id': 'Daftar buku telah disalin — Anda dapat menempelkannya di Telegram atau Catatan sebagai cadangan.', 'bn': 'বইয়ের তালিকা কপি হয়েছে — আপনি এটি টেলিগ্রাম বা নোটে ব্যাকআপ হিসেবে পেস্ট করতে পারেন।', 'ha': "An kwafi jerin littattafai — za ka iya manna shi a Telegram ko Bayanai a matsayin madadin.",
    'so': 'Liiska buugagta waa la koobiyay — waxaad ku dhejin kartaa Telegram ama Fiiro gaar ah si kaydin ah.', 'fa': 'فهرست کتاب‌ها کپی شد — می‌توانید آن را در تلگرام یا یادداشت‌ها به‌عنوان پشتیبان جای‌گذاری کنید.', 'ms': 'Senarai buku telah disalin — anda boleh menampalnya dalam Telegram atau Nota sebagai sandaran.',
  },
  'library_export_header': {
    'ar': 'مكتبتي', 'en': 'My Library', 'am': 'ቤተ መጻሕፍቴ', 'fr': 'Ma bibliothèque', 'sw': 'Maktaba Yangu',
    'ur': 'میری لائبریری', 'tr': 'Kütüphanem', 'id': 'Perpustakaan Saya', 'bn': 'আমার গ্রন্থাগার', 'ha': 'Laburare Na',
    'so': 'Maktabadayda', 'fa': 'کتابخانه من', 'ms': 'Perpustakaan Saya',
  },
  'empty_library_note': {
    'ar': '(المكتبة فارغة)', 'en': '(The library is empty)', 'am': '(ቤተ መጻሕፍት ባዶ ነው)', 'fr': '(La bibliothèque est vide)', 'sw': '(Maktaba ni tupu)',
    'ur': '(لائبریری خالی ہے)', 'tr': '(Kütüphane boş)', 'id': '(Perpustakaan kosong)', 'bn': '(গ্রন্থাগার খালি)', 'ha': "(Laburaren babu kowa)",
    'so': '(Maktabaddu waa madhan tahay)', 'fa': '(کتابخانه خالی است)', 'ms': '(Perpustakaan kosong)',
  },
  'search_all_books_hint': {
    'ar': 'ابحث في كل كتبك...', 'en': 'Search all your books...', 'am': 'ሁሉንም መጻሕፍትዎን ይፈልጉ...', 'fr': 'Rechercher dans tous vos livres...', 'sw': 'Tafuta vitabu vyako vyote...',
    'ur': 'اپنی تمام کتابوں میں تلاش کریں...', 'tr': 'Tüm kitaplarınızda arayın...', 'id': 'Cari di semua buku Anda...', 'bn': 'আপনার সব বইয়ে অনুসন্ধান করুন...', 'ha': "Bincika duk littattafanka...",
    'so': 'Ka raadi dhammaan buugagaaga...', 'fa': 'در همه کتاب‌های خود جستجو کنید...', 'ms': 'Cari dalam semua buku anda...',
  },
  'organize_books_hint': {
    'ar': 'رتّب كتبك في أقسام (مثل: الفقه، العقيدة، السيرة) لتجدها بسهولة لاحقاً.', 'en': 'Organize your books into categories (e.g. Fiqh, Aqeedah, Seerah) to find them easily later.', 'am': 'በኋላ በቀላሉ ለማግኘት መጻሕፍትዎን በክፍሎች ያደራጁ (ለምሳሌ፦ ፊቅህ፣ ዐቂዳ፣ ሲራ)።', 'fr': 'Organisez vos livres en catégories (par ex. fiqh, aqida, sira) pour les retrouver facilement plus tard.', 'sw': 'Panga vitabu vyako katika jamii (mfano: Fiqhi, Aqidah, Sira) ili kuvipata kwa urahisi baadaye.',
    'ur': 'اپنی کتابوں کو زمروں میں ترتیب دیں (مثلاً: فقہ، عقیدہ، سیرت) تاکہ بعد میں آسانی سے تلاش کر سکیں۔', 'tr': "Kitaplarınızı daha sonra kolayca bulmak için kategorilere ayırın (örn: Fıkıh, Akide, Siyer).", 'id': 'Atur buku Anda ke dalam kategori (misalnya: Fiqih, Akidah, Sirah) agar mudah ditemukan nanti.', 'bn': 'পরে সহজে খুঁজে পেতে আপনার বইগুলো বিভাগে সাজান (যেমন: ফিকহ, আকিদা, সিরাত)।', 'ha': "Tsara littattafanka a cikin fannoni (misali: Fikihu, Akida, Sira) don ka same su cikin sauƙi daga baya.",
    'so': 'Buugagaaga ku qaybi qaybo (tusaale ahaan: Fiqhiga, Caqiidada, Siirada) si aad si fudud ugu heshid mustaqbalka.', 'fa': 'کتاب‌های خود را در دسته‌ها سازماندهی کنید (مثلاً: فقه، عقیده، سیره) تا بعداً به‌راحتی پیدایشان کنید.', 'ms': 'Susun buku anda kepada kategori (contohnya: Fiqh, Akidah, Sirah) untuk memudahkan anda mencarinya kemudian.',
  },
  'book_count_suffix': {
    'ar': 'كتاب', 'en': 'books', 'am': 'መጻሕፍት', 'fr': 'livres', 'sw': 'vitabu',
    'ur': 'کتابیں', 'tr': 'kitap', 'id': 'buku', 'bn': 'বই', 'ha': 'littattafai',
    'so': 'buugag', 'fa': 'کتاب', 'ms': 'buku',
  },
  'rename_action_label': {
    'ar': 'إعادة تسمية', 'en': 'Rename', 'am': 'እንደገና ይሰይሙ', 'fr': 'Renommer', 'sw': 'Badilisha Jina',
    'ur': 'نام تبدیل کریں', 'tr': 'Yeniden Adlandır', 'id': 'Ubah Nama', 'bn': 'নাম পরিবর্তন করুন', 'ha': 'Sake Suna',
    'so': 'Dib u Magacaw', 'fa': 'تغییر نام', 'ms': 'Namakan Semula',
  },
  'no_search_results_message': {
    'ar': 'لا توجد نتائج.', 'en': 'No results.', 'am': 'ውጤት የለም።', 'fr': 'Aucun résultat.', 'sw': 'Hakuna matokeo.',
    'ur': 'کوئی نتیجہ نہیں۔', 'tr': 'Sonuç yok.', 'id': 'Tidak ada hasil.', 'bn': 'কোনো ফলাফল নেই।', 'ha': "Babu sakamako.",
    'so': 'Natiijo ma jirto.', 'fa': 'نتیجه‌ای یافت نشد.', 'ms': 'Tiada keputusan.',
  },
  'adding_in_progress_message': {
    'ar': 'جارٍ الإضافة...', 'en': 'Adding...', 'am': 'በመጨመር ላይ...', 'fr': 'Ajout en cours...', 'sw': 'Inaongeza...',
    'ur': 'شامل کیا جا رہا ہے...', 'tr': 'Ekleniyor...', 'id': 'Menambahkan...', 'bn': 'যোগ করা হচ্ছে...', 'ha': "Ana Ƙarawa...",
    'so': 'Waa la darayaa...', 'fa': 'در حال افزودن...', 'ms': 'Menambah...',
  },
  'add_book_action': {
    'ar': 'إضافة كتاب', 'en': 'Add a Book', 'am': 'መጽሐፍ ጨምር', 'fr': 'Ajouter un livre', 'sw': 'Ongeza Kitabu',
    'ur': 'کتاب شامل کریں', 'tr': 'Kitap Ekle', 'id': 'Tambah Buku', 'bn': 'বই যোগ করুন', 'ha': 'Ƙara Littafi',
    'so': 'Ku dar Buug', 'fa': 'افزودن کتاب', 'ms': 'Tambah Buku',
  },
  'no_books_here_yet_prefix': {
    'ar': 'لا توجد كتب هنا بعد.', 'en': 'No books here yet.', 'am': 'እስካሁን እዚህ መጻሕፍት የሉም።', 'fr': "Aucun livre ici pour l'instant.", 'sw': 'Bado hakuna vitabu hapa.',
    'ur': 'ابھی تک یہاں کوئی کتاب نہیں۔', 'tr': 'Burada henüz kitap yok.', 'id': 'Belum ada buku di sini.', 'bn': 'এখনও এখানে কোনো বই নেই।', 'ha': "Babu littattafai a nan tukuna.",
    'so': 'Wali buugag halkan kuma jiraan.', 'fa': 'هنوز کتابی اینجا نیست.', 'ms': 'Belum ada buku di sini.',
  },
  'no_books_here_yet_suffix': {
    'ar': 'اضغط "إضافة كتاب" لاختيار PDF من جهازك.', 'en': 'Tap "Add a Book" to choose a PDF from your device.', 'am': 'ከመሳሪያዎ PDF ለመምረጥ "መጽሐፍ ጨምር" ይንኩ።', 'fr': 'Appuyez sur « Ajouter un livre » pour choisir un PDF depuis votre appareil.', 'sw': 'Bonyeza "Ongeza Kitabu" kuchagua PDF kutoka kifaa chako.',
    'ur': 'اپنے آلے سے PDF منتخب کرنے کے لیے "کتاب شامل کریں" دبائیں۔', 'tr': "Cihazınızdan bir PDF seçmek için \"Kitap Ekle\"ye dokunun.", 'id': 'Ketuk "Tambah Buku" untuk memilih PDF dari perangkat Anda.', 'bn': 'আপনার ডিভাইস থেকে একটি PDF বেছে নিতে "বই যোগ করুন" চাপুন।', 'ha': "Danna \"Ƙara Littafi\" don zaɓar PDF daga na'urarka.",
    'so': 'Taabo "Ku dar Buug" si aad uga dooratid PDF qalabkaaga.', 'fa': 'برای انتخاب یک PDF از دستگاه خود، "افزودن کتاب" را بزنید.', 'ms': 'Ketik "Tambah Buku" untuk memilih PDF daripada peranti anda.',
  },
  // 2026-08-22: ayah_study_screen.dart — Phase 72 ("دراسة الآية").
  'study_page_ayat_action': {
    'ar': 'تفاسير آيات هذه الصفحة', 'en': 'Study This Page\'s Ayat', 'am': 'የዚህ ገጽ አንቀጾች ጥናት', 'fr': 'Étudier les versets de cette page', 'sw': 'Chunguza Aya za Ukurasa Huu',
    'ur': 'اس صفحہ کی آیات کا مطالعہ', 'tr': 'Bu Sayfanın Ayetlerini İncele', 'id': 'Pelajari Ayat Halaman Ini', 'bn': 'এই পৃষ্ঠার আয়াতগুলি অধ্যয়ন করুন', 'ha': 'Nazarin Ayoyin Wannan Shafi',
    'so': 'Daraasadda Aayadaha Boggan', 'fa': 'مطالعه آیات این صفحه', 'ms': 'Kaji Ayat Halaman Ini',
  },
  'ayah_label': {
    'ar': 'آية', 'en': 'Ayah', 'am': 'አንቀጽ', 'fr': 'Verset', 'sw': 'Aya',
    'ur': 'آیت', 'tr': 'Ayet', 'id': 'Ayat', 'bn': 'আয়াত', 'ha': 'Aya',
    'so': 'Aayad', 'fa': 'آیه', 'ms': 'Ayat',
  },
  'ayah_study_title': {
    'ar': 'دراسة الآية', 'en': 'Ayah Study', 'am': 'የአንቀጽ ጥናት', 'fr': 'Étude du verset', 'sw': 'Uchunguzi wa Aya',
    'ur': 'آیت کا مطالعہ', 'tr': 'Ayet İncelemesi', 'id': 'Studi Ayat', 'bn': 'আয়াত অধ্যয়ন', 'ha': 'Nazarin Aya',
    'so': 'Daraasadda Aayadda', 'fa': 'مطالعه آیه', 'ms': 'Kajian Ayat',
  },
  'translate_action': {
    'ar': 'الترجمة', 'en': 'Translation', 'am': 'ትርጉም', 'fr': 'Traduction', 'sw': 'Tafsiri',
    'ur': 'ترجمہ', 'tr': 'Çeviri', 'id': 'Terjemahan', 'bn': 'অনুবাদ', 'ha': 'Fassara',
    'so': 'Turjumaad', 'fa': 'ترجمه', 'ms': 'Terjemahan',
  },
  'listen_ayah_action': {
    'ar': 'الاستماع للآية', 'en': 'Listen to Ayah', 'am': 'አንቀጹን ማዳመጥ', 'fr': 'Écouter le verset', 'sw': 'Sikiliza Aya',
    'ur': 'آیت سنیں', 'tr': 'Ayeti Dinle', 'id': 'Dengarkan Ayat', 'bn': 'আয়াত শুনুন', 'ha': 'Saurari Aya',
    'so': 'Dhagayso Aayadda', 'fa': 'شنیدن آیه', 'ms': 'Dengar Ayat',
  },
  'remove_from_favorites_action': {
    'ar': 'إزالة من المفضلة', 'en': 'Remove from Favorites', 'am': 'ከምወዳቸው አስወግድ', 'fr': 'Retirer des favoris', 'sw': 'Ondoa kwenye Vipendwa',
    'ur': 'پسندیدہ سے ہٹائیں', 'tr': 'Favorilerden Kaldır', 'id': 'Hapus dari Favorit', 'bn': 'প্রিয় থেকে সরান', 'ha': 'Cire daga Abubuwan So',
    'so': 'Ka saar Kuwa La Jecelyahay', 'fa': 'حذف از موارد دلخواه', 'ms': 'Buang dari Kegemaran',
  },
  'add_to_favorites_action': {
    'ar': 'أضف للمفضلة', 'en': 'Add to Favorites', 'am': 'ወደ ተወዳጆች ጨምር', 'fr': 'Ajouter aux favoris', 'sw': 'Ongeza kwenye Vipendwa',
    'ur': 'پسندیدہ میں شامل کریں', 'tr': 'Favorilere Ekle', 'id': 'Tambah ke Favorit', 'bn': 'প্রিয়তে যোগ করুন', 'ha': 'Ƙara zuwa Abubuwan So',
    'so': 'Ku dar Kuwa La Jecelyahay', 'fa': 'افزودن به موارد دلخواه', 'ms': 'Tambah ke Kegemaran',
  },
  'share_action': {
    'ar': 'نشر', 'en': 'Share', 'am': 'አጋራ', 'fr': 'Partager', 'sw': 'Shiriki',
    'ur': 'شیئر کریں', 'tr': 'Paylaş', 'id': 'Bagikan', 'bn': 'শেয়ার করুন', 'ha': 'Raba',
    'so': 'La wadaag', 'fa': 'اشتراک‌گذاری', 'ms': 'Kongsi',
  },
  'pick_translation_language_title': {
    'ar': 'اختر لغة الترجمة', 'en': 'Choose Translation Language', 'am': 'የትርጉም ቋንቋ ይምረጡ', 'fr': 'Choisir la langue de traduction', 'sw': 'Chagua Lugha ya Tafsiri',
    'ur': 'ترجمے کی زبان منتخب کریں', 'tr': 'Çeviri Dili Seçin', 'id': 'Pilih Bahasa Terjemahan', 'bn': 'অনুবাদের ভাষা নির্বাচন করুন', 'ha': 'Zaɓi Harshen Fassara',
    'so': 'Dooro Luqadda Turjumaadda', 'fa': 'انتخاب زبان ترجمه', 'ms': 'Pilih Bahasa Terjemahan',
  },
  'no_translation_available_for_ayah': {
    'ar': 'لا توجد ترجمة متاحة لهذه الآية', 'en': 'No translation available for this ayah', 'am': 'ለዚህ አንቀጽ ትርጉም የለም', 'fr': 'Aucune traduction disponible pour ce verset', 'sw': 'Hakuna tafsiri kwa aya hii',
    'ur': 'اس آیت کے لیے کوئی ترجمہ دستیاب نہیں', 'tr': 'Bu ayet için çeviri yok', 'id': 'Tidak ada terjemahan untuk ayat ini', 'bn': 'এই আয়াতের জন্য কোনো অনুবাদ নেই', 'ha': 'Babu fassara don wannan aya',
    'so': 'Turjumaad uma jirto aayaddan', 'fa': 'ترجمه‌ای برای این آیه موجود نیست', 'ms': 'Tiada terjemahan untuk ayat ini',
  },
  'font_size_tooltip': {
    'ar': 'حجم الخط', 'en': 'Font Size', 'am': 'የቅርጸ-ቁምፊ መጠን', 'fr': 'Taille de police', 'sw': 'Ukubwa wa Fonti',
    'ur': 'فونٹ کا سائز', 'tr': 'Yazı Boyutu', 'id': 'Ukuran Font', 'bn': 'ফন্টের আকার', 'ha': 'Girman Rubutu',
    'so': 'Cabbirka Farta', 'fa': 'اندازه قلم', 'ms': 'Saiz Fon',
  },
  'sepia_mode_tooltip': {
    'ar': 'الوضع الورقي', 'en': 'Sepia Mode', 'am': 'የወረቀት ገጽታ', 'fr': 'Mode sépia', 'sw': 'Hali ya Karatasi',
    'ur': 'سیپیا موڈ', 'tr': 'Sepya Modu', 'id': 'Mode Sepia', 'bn': 'সেপিয়া মোড', 'ha': 'Yanayin Sepia',
    'so': 'Habka Warqadda', 'fa': 'حالت سپیا', 'ms': 'Mod Sepia',
  },
  'recitation_practice_title': {
    'ar': 'تسميع', 'en': 'Recitation Practice', 'am': 'ንባብ ልምምድ', 'fr': 'Pratique de récitation', 'sw': 'Mazoezi ya Kusoma',
    'ur': 'تسمیع', 'tr': 'Tilavet Pratiği', 'id': 'Latihan Bacaan', 'bn': 'তিলাওয়াত অনুশীলন', 'ha': 'Atisayen Karatu',
    'so': 'Ku-celcelinta Akhrinta', 'fa': 'تمرین تلاوت', 'ms': 'Latihan Bacaan',
  },
  'recitation_start_action': {
    'ar': 'ابدأ التسميع', 'en': 'Start Reciting', 'am': 'ንባብ ጀምር', 'fr': 'Commencer la récitation', 'sw': 'Anza Kusoma',
    'ur': 'تلاوت شروع کریں', 'tr': 'Okumaya Başla', 'id': 'Mulai Membaca', 'bn': 'তিলাওয়াত শুরু করুন', 'ha': 'Fara Karatu',
    'so': 'Bilow Akhrinta', 'fa': 'شروع تلاوت', 'ms': 'Mula Membaca',
  },
  'recitation_stop_action': {
    'ar': 'إيقاف', 'en': 'Stop', 'am': 'አቁም', 'fr': 'Arrêter', 'sw': 'Simama',
    'ur': 'روکیں', 'tr': 'Durdur', 'id': 'Berhenti', 'bn': 'থামুন', 'ha': 'Tsaya',
    'so': 'Jooji', 'fa': 'توقف', 'ms': 'Berhenti',
  },
  'recitation_listening_status': {
    'ar': 'أستمع...', 'en': 'Listening...', 'am': 'በማዳመጥ ላይ...', 'fr': 'Écoute en cours...', 'sw': 'Ninasikiliza...',
    'ur': 'سن رہا ہوں...', 'tr': 'Dinleniyor...', 'id': 'Mendengarkan...', 'bn': 'শুনছি...', 'ha': 'Ana saurare...',
    'so': 'Waan dhagaysanayaa...', 'fa': 'در حال شنیدن...', 'ms': 'Mendengar...',
  },
  'recitation_score_label': {
    'ar': 'النتيجة', 'en': 'Score', 'am': 'ውጤት', 'fr': 'Score', 'sw': 'Alama',
    'ur': 'نتیجہ', 'tr': 'Puan', 'id': 'Skor', 'bn': 'স্কোর', 'ha': 'Sakamako',
    'so': 'Natiijada', 'fa': 'امتیاز', 'ms': 'Skor',
  },
  'recitation_heard_label': {
    'ar': 'سمعت:', 'en': 'Heard:', 'am': 'የተሰማ:', 'fr': 'Entendu :', 'sw': 'Imesikika:',
    'ur': 'سنا:', 'tr': 'Duyulan:', 'id': 'Terdengar:', 'bn': 'শুনেছি:', 'ha': 'An ji:',
    'so': 'La maqlay:', 'fa': 'شنیده شد:', 'ms': 'Didengar:',
  },
  'recitation_network_error': {
    'ar': 'تعذر الاتصال بخدمة التعرف الصوتي، تحقق من الإنترنت', 'en': 'Could not reach the speech recognition service, check your internet connection',
    'am': 'የድምጽ ማወቂያ አገልግሎት ላይ መድረስ አልተቻለም፣ የበይነመረብ ግንኙነትዎን ያረጋግጡ', 'fr': "Impossible de joindre le service de reconnaissance vocale, vérifiez votre connexion internet",
    'sw': 'Imeshindwa kufikia huduma ya utambuzi wa sauti, angalia muunganisho wako wa intaneti', 'ur': 'اسپیچ ریکگنیشن سروس تک رسائی نہیں ہو سکی، انٹرنیٹ کنکشن چیک کریں',
    'tr': 'Konuşma tanıma hizmetine ulaşılamadı, internet bağlantınızı kontrol edin', 'id': 'Tidak dapat menjangkau layanan pengenalan suara, periksa koneksi internet Anda',
    'bn': 'স্পিচ রিকগনিশন সার্ভিসে পৌঁছানো যায়নি, ইন্টারনেট সংযোগ পরীক্ষা করুন', 'ha': 'An kasa isa ga sabis na gane murya, duba haɗin intanet ɗinka',
    'so': 'Lama gaarin adeegga aqoonsiga hadalka, hubi xiriirka internetka', 'fa': 'دسترسی به سرویس تشخیص گفتار ممکن نشد، اتصال اینترنت را بررسی کنید',
    'ms': 'Tidak dapat menghubungi perkhidmatan pengecaman suara, semak sambungan internet anda',
  },
  'recitation_generic_error': {
    'ar': 'حدث خطأ في التعرف الصوتي، حاول مجددًا', 'en': 'A speech recognition error occurred, try again', 'am': 'የድምጽ ማወቂያ ስህተት ተከስቷል፣ እንደገና ይሞክሩ',
    'fr': "Une erreur de reconnaissance vocale s'est produite, réessayez", 'sw': 'Hitilafu ya utambuzi wa sauti imetokea, jaribu tena', 'ur': 'اسپیچ ریکگنیشن میں خرابی ہوئی، دوبارہ کوشش کریں',
    'tr': 'Bir konuşma tanıma hatası oluştu, tekrar deneyin', 'id': 'Terjadi kesalahan pengenalan suara, coba lagi', 'bn': 'একটি স্পিচ রিকগনিশন ত্রুটি ঘটেছে, আবার চেষ্টা করুন',
    'ha': 'An sami kuskuren gane murya, sake gwadawa', 'so': 'Khalad ayaa dhacay aqoonsiga hadalka, isku day mar kale', 'fa': 'خطایی در تشخیص گفتار رخ داد، دوباره امتحان کنید',
    'ms': 'Ralat pengecaman suara berlaku, cuba lagi',
  },
  'recitation_no_arabic_locale': {
    'ar': 'لا تتوفر لغة عربية للتعرف الصوتي على هذا الجهاز', 'en': 'No Arabic speech recognition available on this device',
    'am': 'በዚህ መሣሪያ ላይ የአረብኛ ንግግር ማወቂያ የለም', 'fr': "Aucune reconnaissance vocale arabe disponible sur cet appareil",
    'sw': 'Hakuna utambuzi wa sauti wa Kiarabu kwenye kifaa hiki', 'ur': 'اس ڈیوائس پر عربی اسپیچ ریکگنیشن دستیاب نہیں',
    'tr': 'Bu cihazda Arapça konuşma tanıma mevcut değil', 'id': 'Pengenalan suara Arab tidak tersedia di perangkat ini',
    'bn': 'এই ডিভাইসে আরবি ভাষা শনাক্তকরণ উপলব্ধ নেই', 'ha': 'Babu gane muryar Larabci a wannan na\'urar',
    'so': 'Aqoonsiga hadalka Carabiga lagama heli karo qalabkan', 'fa': 'تشخیص گفتار عربی روی این دستگاه در دسترس نیست',
    'ms': 'Pengecaman suara Arab tidak tersedia pada peranti ini',
  },
  'recitation_mic_permission_denied': {
    'ar': 'يحتاج التطبيق إذن الميكروفون لهذه الميزة', 'en': 'The app needs microphone permission for this feature',
    'am': 'ይህ ባህሪ የማይክሮፎን ፈቃድ ያስፈልገዋል', 'fr': "L'application a besoin de l'autorisation du microphone pour cette fonctionnalité",
    'sw': 'Programu inahitaji ruhusa ya maikrofoni kwa kipengele hiki', 'ur': 'اس فیچر کے لیے مائیکروفون کی اجازت درکار ہے',
    'tr': 'Bu özellik için mikrofon izni gerekiyor', 'id': 'Aplikasi memerlukan izin mikrofon untuk fitur ini',
    'bn': 'এই বৈশিষ্ট্যের জন্য অ্যাপের মাইক্রোফোন অনুমতি প্রয়োজন', 'ha': 'Ana bukatar izinin makirufo don wannan fasalin',
    'so': 'Barnaamijku wuxuu u baahan yahay ogolaanshaha makarafoonka sifadan', 'fa': 'برنامه برای این ویژگی به مجوز میکروفون نیاز دارد',
    'ms': 'Aplikasi memerlukan kebenaran mikrofon untuk ciri ini',
  },
  'recitation_mode_listen': {
    'ar': 'استماع', 'en': 'Listen', 'am': 'ማዳመጥ', 'fr': 'Écouter', 'sw': 'Sikiliza',
    'ur': 'سنیں', 'tr': 'Dinle', 'id': 'Dengar', 'bn': 'শুনুন', 'ha': 'Saurara',
    'so': 'Dhagayso', 'fa': 'گوش دادن', 'ms': 'Dengar',
  },
  'recitation_mode_recite': {
    'ar': 'تسميع', 'en': 'Recite', 'am': 'ንባብ', 'fr': 'Réciter', 'sw': 'Soma',
    'ur': 'تلاوت', 'tr': 'Oku', 'id': 'Baca', 'bn': 'তিলাওয়াত', 'ha': 'Karatu',
    'so': 'Akhri', 'fa': 'تلاوت', 'ms': 'Baca',
  },
  'recitation_mode_test': {
    'ar': 'اختبار', 'en': 'Test', 'am': 'ፈተና', 'fr': 'Test', 'sw': 'Jaribio',
    'ur': 'ٹیسٹ', 'tr': 'Test', 'id': 'Uji', 'bn': 'পরীক্ষা', 'ha': 'Gwaji',
    'so': 'Imtixaan', 'fa': 'آزمون', 'ms': 'Ujian',
  },
  'recitation_hidden_ayah_hint': {
    'ar': 'الآية مخفية — اقرأها من حفظك ثم اضغط ابدأ التسميع', 'en': 'The ayah is hidden — recite it from memory, then press Start',
    'am': 'አንቀጹ ተደብቋል — ከቃላችሁ አንብቡት ከዚያ ጀምር ተጫኑ', 'fr': "Le verset est masqué — récitez-le de mémoire puis appuyez sur Démarrer",
    'sw': 'Aya imefichwa — isome kwa kumbukumbu kisha bonyeza Anza', 'ur': 'آیت پوشیدہ ہے — اسے حفظ سے پڑھیں پھر شروع کریں دبائیں',
    'tr': 'Ayet gizli — ezberden okuyun sonra Başlat\'a basın', 'id': 'Ayat disembunyikan — bacalah dari hafalan lalu tekan Mulai',
    'bn': 'আয়াতটি লুকানো — মুখস্থ থেকে পড়ুন তারপর শুরু করুন চাপুন', 'ha': 'An ɓoye ayar — karanta daga hafizarka sannan danna Fara',
    'so': 'Aayadu waa qarsoon tahay — xasuusnaanta ka akhri kadibna riix Bilow', 'fa': 'آیه پنهان است — از حفظ بخوانید سپس شروع را بزنید',
    'ms': 'Ayat disembunyikan — bacalah dari hafazan kemudian tekan Mula',
  },
  'recitation_play_action': {
    'ar': 'استمع للقارئ', 'en': 'Play Reciter', 'am': 'አንባቢ አጫውት', 'fr': 'Écouter le récitateur', 'sw': 'Cheza Msomaji',
    'ur': 'قاری سنیں', 'tr': 'Okuyucuyu Dinle', 'id': 'Putar Qari', 'bn': 'ক্বারী শুনুন', 'ha': 'Kunna Mai Karatu',
    'so': 'Dhagayso Akhriyaha', 'fa': 'پخش قاری', 'ms': 'Main Qari',
  },
  'recitation_playing_status': {
    'ar': 'جارٍ التشغيل...', 'en': 'Playing...', 'am': 'በማጫወት ላይ...', 'fr': 'Lecture en cours...', 'sw': 'Inacheza...',
    'ur': 'چل رہا ہے...', 'tr': 'Çalıyor...', 'id': 'Memutar...', 'bn': 'বাজছে...', 'ha': 'Ana kunnawa...',
    'so': 'Waa la tarayaa...', 'fa': 'در حال پخش...', 'ms': 'Sedang Dimainkan...',
  },
  'recitation_mistakes_title': {
    'ar': 'سجل أخطاء التسميع', 'en': 'Recitation Mistake History', 'am': 'የንባብ ስህተት ታሪክ', 'fr': 'Historique des erreurs de récitation', 'sw': 'Historia ya Makosa ya Kusoma',
    'ur': 'تلاوت کی غلطیوں کی تاریخ', 'tr': 'Okuma Hatası Geçmişi', 'id': 'Riwayat Kesalahan Bacaan', 'bn': 'তিলাওয়াতের ভুলের ইতিহাস', 'ha': 'Tarihin Kurakuran Karatu',
    'so': 'Taariikhda Khaladaadka Akhrinta', 'fa': 'تاریخچه خطاهای تلاوت', 'ms': 'Sejarah Kesilapan Bacaan',
  },
  'recitation_mistakes_empty': {
    'ar': 'لا توجد أخطاء مسجلة بعد — ابدأ جلسة تسميع من صفحة القرآن', 'en': 'No mistakes recorded yet — start a recitation session from the Quran page',
    'am': 'እስካሁን ምንም ስህተት አልተመዘገበም — ከቁርአን ገጽ ንባብ ጀምር', 'fr': "Aucune erreur enregistrée pour l'instant — commencez une session de récitation depuis la page du Coran",
    'sw': 'Hakuna makosa yaliyorekodiwa bado — anza kipindi cha kusoma kutoka ukurasa wa Qur\'ani', 'ur': 'ابھی تک کوئی غلطی درج نہیں — قرآن کے صفحے سے تلاوت شروع کریں',
    'tr': 'Henüz kaydedilmiş hata yok — Kur\'an sayfasından bir okuma oturumu başlatın', 'id': 'Belum ada kesalahan yang tercatat — mulai sesi bacaan dari halaman Al-Quran',
    'bn': 'এখনও কোনো ভুল রেকর্ড করা হয়নি — কুরআনের পৃষ্ঠা থেকে তিলাওয়াত সেশন শুরু করুন', 'ha': 'Babu kurakurai da aka rubuta tukuna — fara zaman karatu daga shafin Alqur\'ani',
    'so': 'Wali lama duubin khaladaad — ka bilow fadhi akhris bogga Qur\'aanka', 'fa': 'هنوز خطایی ثبت نشده — یک جلسه تلاوت از صفحه قرآن شروع کنید',
    'ms': 'Tiada kesilapan direkodkan lagi — mulakan sesi bacaan dari halaman Al-Quran',
  },
  'all_label': {
    'ar': 'الكل', 'en': 'All', 'am': 'ሁሉም', 'fr': 'Tout', 'sw': 'Zote',
    'ur': 'تمام', 'tr': 'Tümü', 'id': 'Semua', 'bn': 'সব', 'ha': 'Duka',
    'so': 'Dhammaan', 'fa': 'همه', 'ms': 'Semua',
  },
  'previous_ayah_action': {
    'ar': 'الآية السابقة', 'en': 'Previous Ayah', 'am': 'ቀዳሚ አንቀጽ', 'fr': 'Verset précédent', 'sw': 'Aya Iliyotangulia',
    'ur': 'پچھلی آیت', 'tr': 'Önceki Ayet', 'id': 'Ayat Sebelumnya', 'bn': 'পূর্ববর্তী আয়াত', 'ha': 'Ayar da Ta Gabata',
    'so': 'Aayadda Hore', 'fa': 'آیه قبلی', 'ms': 'Ayat Sebelumnya',
  },
  'next_ayah_action': {
    'ar': 'الآية التالية', 'en': 'Next Ayah', 'am': 'ቀጣይ አንቀጽ', 'fr': 'Verset suivant', 'sw': 'Aya Ifuatayo',
    'ur': 'اگلی آیت', 'tr': 'Sonraki Ayet', 'id': 'Ayat Berikutnya', 'bn': 'পরবর্তী আয়াত', 'ha': 'Ayar da Ke Gaba',
    'so': 'Aayadda Xigta', 'fa': 'آیه بعدی', 'ms': 'Ayat Seterusnya',
  },
  'no_tafsir_sources_for_ayah': {
    'ar': 'لا توجد مصادر تفسير محفوظة لهذه الآية بعد', 'en': 'No tafsir sources stored for this ayah yet', 'am': 'ለዚህ አንቀጽ እስካሁን የተቀመጠ ትርጓሜ ምንጭ የለም', 'fr': "Aucune source de tafsir enregistrée pour ce verset pour l'instant", 'sw': 'Bado hakuna vyanzo vya tafsiri vilivyohifadhiwa kwa aya hii',
    'ur': 'ابھی تک اس آیت کے لیے کوئی تفسیر کا ذریعہ محفوظ نہیں ہے', 'tr': 'Bu ayet için henüz kayıtlı tefsir kaynağı yok', 'id': 'Belum ada sumber tafsir yang tersimpan untuk ayat ini', 'bn': 'এই আয়াতের জন্য এখনও কোনো তাফসীর উৎস সংরক্ষিত নেই', 'ha': 'Babu tushen tafsiri da aka adana wa wannan ayar tukuna',
    'so': 'Wali ilo tafsiir ah oo la kaydiyay ayaadan uma jiraan', 'fa': 'هنوز منبع تفسیری برای این آیه ذخیره نشده است', 'ms': 'Belum ada sumber tafsir disimpan untuk ayat ini',
  },
  'compare_tafsirs_action': {
    'ar': 'قارن التفاسير', 'en': 'Compare Tafsirs', 'am': 'ትርጓሜዎችን ያወዳድሩ', 'fr': 'Comparer les tafsirs', 'sw': 'Linganisha Tafsiri',
    'ur': 'تفاسیر کا موازنہ کریں', 'tr': 'Tefsirleri Karşılaştır', 'id': 'Bandingkan Tafsir', 'bn': 'তাফসীর তুলনা করুন', 'ha': 'Kwatanta Tafsirori',
    'so': 'Isbarbardhig Tafsiirrada', 'fa': 'مقایسه تفاسیر', 'ms': 'Bandingkan Tafsir',
  },
  'all_sources_action': {
    'ar': 'كل المصادر', 'en': 'All Sources', 'am': 'ሁሉም ምንጮች', 'fr': 'Toutes les sources', 'sw': 'Vyanzo Vyote',
    'ur': 'تمام ذرائع', 'tr': 'Tüm Kaynaklar', 'id': 'Semua Sumber', 'bn': 'সব উৎস', 'ha': 'Dukkan Tushe',
    'so': 'Dhammaan Ilaha', 'fa': 'همه منابع', 'ms': 'Semua Sumber',
  },
  'no_tafsir_for_this_ayah': {
    'ar': 'لا يوجد تفسير محفوظ لهذه الآية من هذا المصدر', 'en': 'No tafsir stored for this ayah from this source', 'am': 'ከዚህ ምንጭ ለዚህ አንቀጽ የተቀመጠ ትርጓሜ የለም', 'fr': 'Aucun tafsir enregistré pour ce verset depuis cette source', 'sw': 'Hakuna tafsiri iliyohifadhiwa kwa aya hii kutoka chanzo hiki',
    'ur': 'اس ذریعے سے اس آیت کے لیے کوئی تفسیر محفوظ نہیں ہے', 'tr': 'Bu kaynaktan bu ayet için kayıtlı tefsir yok', 'id': 'Tidak ada tafsir tersimpan untuk ayat ini dari sumber ini', 'bn': 'এই উৎস থেকে এই আয়াতের জন্য কোনো তাফসীর সংরক্ষিত নেই', 'ha': 'Babu tafsirin da aka adana wa wannan ayar daga wannan tushen',
    'so': 'Ilahan tafsiir looma kaydin ayadan', 'fa': 'از این منبع تفسیری برای این آیه ذخیره نشده است', 'ms': 'Tiada tafsir disimpan untuk ayat ini daripada sumber ini',
  },
  // ---- TAFSIR_UNIFIED_ARCHITECTURE.md §5 — a real explanatory note from
  // the source, kept visually separate from the translation/tafsir text.
  'ql_footnote_section': {
    'ar': 'شرح توضيحي من المصدر', 'en': 'Explanatory note from the source', 'am': 'ከምንጩ የተገኘ ማብራሪያ', 'fr': 'Note explicative de la source', 'sw': 'Ufafanuzi kutoka chanzo',
    'ur': 'ماخذ سے وضاحتی نوٹ', 'tr': 'Kaynaktan açıklayıcı not', 'id': 'Catatan penjelasan dari sumber', 'bn': 'উৎস থেকে ব্যাখ্যামূলক নোট', 'ha': 'Bayani daga tushen',
    'so': 'Faah faahin ka timid isha', 'fa': 'یادداشت توضیحی از منبع', 'ms': 'Nota penjelasan daripada sumber',
  },
  'exit_compare_action': {
    'ar': 'إنهاء المقارنة', 'en': 'Exit Comparison', 'am': 'ንጽጽርን ዝጋ', 'fr': 'Quitter la comparaison', 'sw': 'Toka Kulinganisha',
    'ur': 'موازنہ ختم کریں', 'tr': 'Karşılaştırmadan Çık', 'id': 'Keluar dari Perbandingan', 'bn': 'তুলনা থেকে বের হন', 'ha': 'Fita Kwatancen',
    'so': 'Ka Bax Isbarbardhigga', 'fa': 'خروج از مقایسه', 'ms': 'Keluar Perbandingan',
  },
  'pick_two_to_four_sources': {
    'ar': 'اختر من ٢ إلى ٤ مصادر للمقارنة', 'en': 'Pick 2 to 4 sources to compare', 'am': 'ለማወዳደር ከ2 እስከ 4 ምንጮችን ይምረጡ', 'fr': 'Choisissez de 2 à 4 sources à comparer', 'sw': 'Chagua vyanzo 2 hadi 4 kulinganisha',
    'ur': 'موازنے کے لیے 2 سے 4 ذرائع منتخب کریں', 'tr': 'Karşılaştırmak için 2 ila 4 kaynak seçin', 'id': 'Pilih 2 hingga 4 sumber untuk dibandingkan', 'bn': 'তুলনা করতে ২ থেকে ৪টি উৎস বেছে নিন', 'ha': 'Zaɓi tushe 2 zuwa 4 don kwatantawa',
    'so': 'Dooro 2 ilaa 4 ilood si aad u isbarbardhigto', 'fa': 'برای مقایسه ۲ تا ۴ منبع انتخاب کنید', 'ms': 'Pilih 2 hingga 4 sumber untuk dibandingkan',
  },
  'mosques_title': {'ar': 'مساجدنا', 'en': 'Our mosques', 'am': 'መስጊዶቻችን', 'fr': 'Nos mosquées', 'sw': 'Misikiti yetu', 'ur': 'ہماری مساجد', 'tr': 'Camilerimiz', 'id': 'Masjid kami', 'bn': 'আমাদের মসজিদ', 'ha': 'Masallatanmu', 'so': 'Masaajidkeenna', 'fa': 'مساجد ما', 'ms': 'Masjid kami'},
  'mosques_search_hint': {'ar': 'ابحث عن مسجد بالاسم...', 'en': 'Search a mosque by name...', 'am': 'መስጊድ በስም ይፈልጉ...', 'fr': 'Rechercher une mosquée par nom...', 'sw': 'Tafuta msikiti kwa jina...', 'ur': 'نام سے مسجد تلاش کریں...', 'tr': 'İsimle cami ara...', 'id': 'Cari masjid berdasarkan nama...', 'bn': 'নাম দিয়ে মসজিদ খুঁজুন...', 'ha': 'Nemo masallaci da suna...', 'so': 'Ka raadi masjid magaca...', 'fa': 'مسجد را با نام جستجو کنید...', 'ms': 'Cari masjid mengikut nama...'},
  'mosques_all': {'ar': 'كل المساجد', 'en': 'All mosques', 'am': 'ሁሉም መስጊዶች', 'fr': 'Toutes les mosquées', 'sw': 'Misikiti yote', 'ur': 'تمام مساجد', 'tr': 'Tüm camiler', 'id': 'Semua masjid', 'bn': 'সব মসজিদ', 'ha': 'Dukkan masallatai', 'so': 'Dhammaan masaajidda', 'fa': 'همه مساجد', 'ms': 'Semua masjid'},
  'mosques_empty': {'ar': 'لا توجد مساجد بعد', 'en': 'No mosques yet', 'am': 'ገና መስጊዶች የሉም', 'fr': 'Aucune mosquée pour l’instant', 'sw': 'Bado hakuna misikiti', 'ur': 'ابھی کوئی مسجد نہیں', 'tr': 'Henüz cami yok', 'id': 'Belum ada masjid', 'bn': 'এখনও কোনো মসজিদ নেই', 'ha': 'Babu masallatai tukuna', 'so': 'Weli masaajid ma jiraan', 'fa': 'هنوز مسجدی نیست', 'ms': 'Belum ada masjid'},
  'mosque_my_mosque': {'ar': 'مسجدي', 'en': 'My mosque', 'am': 'የእኔ መስጊድ', 'fr': 'Ma mosquée', 'sw': 'Msikiti wangu', 'ur': 'میری مسجد', 'tr': 'Camim', 'id': 'Masjid saya', 'bn': 'আমার মসজিদ', 'ha': 'Masallacina', 'so': 'Masjidkayga', 'fa': 'مسجد من', 'ms': 'Masjid saya'},
  'mosque_set_mine': {'ar': 'اجعله مسجدي', 'en': 'Set as my mosque', 'am': 'እንደ የእኔ መስጊድ አድርግ', 'fr': 'Définir comme ma mosquée', 'sw': 'Weka kama msikiti wangu', 'ur': 'اسے میری مسجد بنائیں', 'tr': 'Camim olarak ayarla', 'id': 'Jadikan masjid saya', 'bn': 'আমার মসজিদ হিসেবে সেট করুন', 'ha': 'Sanya shi masallacina', 'so': 'Ka dhig masjidkayga', 'fa': 'به‌عنوان مسجد من تنظیم کن', 'ms': 'Tetapkan sebagai masjid saya'},
  'mosque_unset_mine': {'ar': 'إزالة من مسجدي', 'en': 'Unset my mosque', 'am': 'ከየእኔ መስጊድ አስወግድ', 'fr': 'Retirer de ma mosquée', 'sw': 'Ondoa kama msikiti wangu', 'ur': 'میری مسجد سے ہٹائیں', 'tr': 'Camimden kaldır', 'id': 'Batalkan masjid saya', 'bn': 'আমার মসজিদ থেকে সরান', 'ha': 'Cire daga masallacina', 'so': 'Ka saar masjidkayga', 'fa': 'از مسجد من حذف کن', 'ms': 'Nyahtetap masjid saya'},
  'mosque_verified': {'ar': 'مسجد موثّق', 'en': 'Verified', 'am': 'የተረጋገጠ መስጊድ', 'fr': 'Vérifiée', 'sw': 'Msikiti uliothibitishwa', 'ur': 'تصدیق شدہ مسجد', 'tr': 'Doğrulanmış', 'id': 'Terverifikasi', 'bn': 'যাচাইকৃত', 'ha': 'Tabbatacce', 'so': 'La xaqiijiyay', 'fa': 'تأییدشده', 'ms': 'Disahkan'},
  'mosque_directions': {'ar': 'الاتجاه', 'en': 'Directions', 'am': 'አቅጣጫ', 'fr': 'Itinéraire', 'sw': 'Maelekezo', 'ur': 'راستہ', 'tr': 'Yol tarifi', 'id': 'Rute', 'bn': 'পথনির্দেশ', 'ha': 'Hanya', 'so': 'Jihada', 'fa': 'مسیر', 'ms': 'Arah'},
  'mosque_contact': {'ar': 'تواصل', 'en': 'Contact', 'am': 'አግኝ', 'fr': 'Contact', 'sw': 'Wasiliana', 'ur': 'رابطہ', 'tr': 'İletişim', 'id': 'Kontak', 'bn': 'যোগাযোগ', 'ha': 'Tuntuɓa', 'so': 'La xiriir', 'fa': 'تماس', 'ms': 'Hubungi'},
  'mosque_services': {'ar': 'خدمات المسجد', 'en': 'Mosque services', 'am': 'የመስጊድ አገልግሎቶች', 'fr': 'Services de la mosquée', 'sw': 'Huduma za msikiti', 'ur': 'مسجد کی خدمات', 'tr': 'Cami hizmetleri', 'id': 'Layanan masjid', 'bn': 'মসজিদের সেবা', 'ha': 'Ayyukan masallaci', 'so': 'Adeegyada masjidka', 'fa': 'خدمات مسجد', 'ms': 'Perkhidmatan masjid'},
  'mosque_view_all': {'ar': 'عرض الكل', 'en': 'View all', 'am': 'ሁሉንም አሳይ', 'fr': 'Voir tout', 'sw': 'Ona zote', 'ur': 'سب دیکھیں', 'tr': 'Tümünü gör', 'id': 'Lihat semua', 'bn': 'সব দেখুন', 'ha': 'Duba duka', 'so': 'Eeg dhammaan', 'fa': 'مشاهده همه', 'ms': 'Lihat semua'},
  'mosque_section_empty': {'ar': 'لا يوجد محتوى في هذا القسم بعد', 'en': 'Nothing in this section yet', 'am': 'በዚህ ክፍል ገና ምንም የለም', 'fr': 'Rien dans cette section pour l’instant', 'sw': 'Bado hakuna kilicho hapa', 'ur': 'اس حصے میں ابھی کچھ نہیں', 'tr': 'Bu bölümde henüz bir şey yok', 'id': 'Belum ada apa pun di bagian ini', 'bn': 'এই বিভাগে এখনও কিছু নেই', 'ha': 'Babu kome a wannan sashe tukuna', 'so': 'Weli waxba kuma jiraan qaybtan', 'fa': 'هنوز چیزی در این بخش نیست', 'ms': 'Belum ada apa-apa dalam bahagian ini'},
  'mosque_content_missing': {'ar': 'العنصر غير متاح', 'en': 'Item not available', 'am': 'ንጥሉ አይገኝም', 'fr': 'Élément indisponible', 'sw': 'Kipengele hakipatikani', 'ur': 'آئٹم دستیاب نہیں', 'tr': 'Öğe mevcut değil', 'id': 'Item tidak tersedia', 'bn': 'আইটেমটি উপলব্ধ নয়', 'ha': 'Abu ba ya samuwa', 'so': 'Shayga lama helayo', 'fa': 'مورد در دسترس نیست', 'ms': 'Item tidak tersedia'},
  'mosque_play_audio': {'ar': 'تشغيل الصوت', 'en': 'Play audio', 'am': 'ድምፅ አጫውት', 'fr': 'Lire l’audio', 'sw': 'Cheza sauti', 'ur': 'آڈیو چلائیں', 'tr': 'Sesi oynat', 'id': 'Putar audio', 'bn': 'অডিও চালান', 'ha': 'Kunna sauti', 'so': 'Cod ka dhig', 'fa': 'پخش صدا', 'ms': 'Main audio'},
  'mosque_audio_soon': {'ar': 'التسجيل الصوتي غير مرفوع بعد', 'en': 'The recording isn’t uploaded yet', 'am': 'ቅጂው ገና አልተጫነም', 'fr': 'L’enregistrement n’est pas encore téléversé', 'sw': 'Rekodi haijapakiwa bado', 'ur': 'ریکارڈنگ ابھی اپ لوڈ نہیں ہوئی', 'tr': 'Kayıt henüz yüklenmedi', 'id': 'Rekaman belum diunggah', 'bn': 'রেকর্ডিং এখনও আপলোড হয়নি', 'ha': 'Ba a ɗora rikodin ba tukuna', 'so': 'Duubista weli lama soo gelin', 'fa': 'ضبط هنوز بارگذاری نشده', 'ms': 'Rakaman belum dimuat naik'},
  'mosque_open_attachment': {'ar': 'فتح المرفق', 'en': 'Open attachment', 'am': 'አባሪ ክፈት', 'fr': 'Ouvrir la pièce jointe', 'sw': 'Fungua kiambatisho', 'ur': 'منسلکہ کھولیں', 'tr': 'Eki aç', 'id': 'Buka lampiran', 'bn': 'সংযুক্তি খুলুন', 'ha': 'Buɗe abin haɗi', 'so': 'Fur lifaaqa', 'fa': 'باز کردن پیوست', 'ms': 'Buka lampiran'},
  'mosque_kind_lesson': {'ar': 'الدروس والمحاضرات', 'en': 'Lessons & lectures', 'am': 'ትምህርቶችና ንግግሮች', 'fr': 'Cours et conférences', 'sw': 'Masomo na mihadhara', 'ur': 'دروس و محاضرات', 'tr': 'Dersler ve konferanslar', 'id': 'Pelajaran & ceramah', 'bn': 'পাঠ ও বক্তৃতা', 'ha': 'Darussa da laccoci', 'so': 'Casharro & muxaadarooyin', 'fa': 'دروس و سخنرانی‌ها', 'ms': 'Pelajaran & kuliah'},
  'mosque_kind_khutbah': {'ar': 'خطبة الجمعة', 'en': 'Friday khutbah', 'am': 'የዓርብ ኹጥባ', 'fr': 'Sermon du vendredi', 'sw': 'Khutba ya Ijumaa', 'ur': 'خطبۂ جمعہ', 'tr': 'Cuma hutbesi', 'id': 'Khutbah Jumat', 'bn': 'জুমার খুতবা', 'ha': 'Huɗubar Juma’a', 'so': 'Khudbada Jimcaha', 'fa': 'خطبه جمعه', 'ms': 'Khutbah Jumaat'},
  'mosque_kind_announcement': {'ar': 'الإعلانات', 'en': 'Announcements', 'am': 'ማስታወቂያዎች', 'fr': 'Annonces', 'sw': 'Matangazo', 'ur': 'اعلانات', 'tr': 'Duyurular', 'id': 'Pengumuman', 'bn': 'ঘোষণা', 'ha': 'Sanarwa', 'so': 'Ogeysiisyo', 'fa': 'اطلاعیه‌ها', 'ms': 'Pengumuman'},
  'mosque_kind_recording': {'ar': 'التسجيلات الصوتية', 'en': 'Audio recordings', 'am': 'የድምፅ ቅጂዎች', 'fr': 'Enregistrements audio', 'sw': 'Rekodi za sauti', 'ur': 'آڈیو ریکارڈنگز', 'tr': 'Ses kayıtları', 'id': 'Rekaman audio', 'bn': 'অডিও রেকর্ডিং', 'ha': 'Rikodin sauti', 'so': 'Duubista codka', 'fa': 'ضبط‌های صوتی', 'ms': 'Rakaman audio'},
  'mosque_kind_library': {'ar': 'مكتبة المسجد', 'en': 'Mosque library', 'am': 'የመስጊድ ቤተ መጻሕፍት', 'fr': 'Bibliothèque de la mosquée', 'sw': 'Maktaba ya msikiti', 'ur': 'مسجد کی لائبریری', 'tr': 'Cami kütüphanesi', 'id': 'Perpustakaan masjid', 'bn': 'মসজিদ গ্রন্থাগার', 'ha': 'Ɗakin karatu na masallaci', 'so': 'Maktabadda masjidka', 'fa': 'کتابخانه مسجد', 'ms': 'Perpustakaan masjid'},
  'mosque_kind_need': {'ar': 'احتياجات المسجد', 'en': 'Mosque needs', 'am': 'የመስጊድ ፍላጎቶች', 'fr': 'Besoins de la mosquée', 'sw': 'Mahitaji ya msikiti', 'ur': 'مسجد کی ضروریات', 'tr': 'Cami ihtiyaçları', 'id': 'Kebutuhan masjid', 'bn': 'মসজিদের প্রয়োজন', 'ha': 'Bukatun masallaci', 'so': 'Baahiyaha masjidka', 'fa': 'نیازهای مسجد', 'ms': 'Keperluan masjid'},
  'mosque_kind_activity': {'ar': 'الأنشطة والفعاليات', 'en': 'Activities & events', 'am': 'እንቅስቃሴዎችና ዝግጅቶች', 'fr': 'Activités et événements', 'sw': 'Shughuli na matukio', 'ur': 'سرگرمیاں و تقریبات', 'tr': 'Etkinlikler', 'id': 'Aktivitas & acara', 'bn': 'কার্যক্রম ও অনুষ্ঠান', 'ha': 'Ayyuka da abubuwan da suka faru', 'so': 'Hawlaha & munaasabadaha', 'fa': 'فعالیت‌ها و رویدادها', 'ms': 'Aktiviti & acara'},
  // ---- «مساجدنا» — gallery, prayer times, distance, sync (5 improvements pass)
  'mosque_kind_gallery': {'ar': 'الصور', 'en': 'Photos', 'am': 'ፎቶዎች', 'fr': 'Photos', 'sw': 'Picha', 'ur': 'تصاویر', 'tr': 'Fotoğraflar', 'id': 'Foto', 'bn': 'ছবি', 'ha': 'Hotuna', 'so': 'Sawirro', 'fa': 'عکس‌ها', 'ms': 'Gambar'},
  'mosque_gallery_empty': {'ar': 'لا صور بعد', 'en': 'No photos yet', 'am': 'እስካሁን ፎቶ የለም', 'fr': 'Aucune photo pour l’instant', 'sw': 'Bado hakuna picha', 'ur': 'ابھی کوئی تصویر نہیں', 'tr': 'Henüz fotoğraf yok', 'id': 'Belum ada foto', 'bn': 'এখনও কোনো ছবি নেই', 'ha': 'Babu hotuna tukuna', 'so': 'Weli sawir ma jiro', 'fa': 'هنوز عکسی نیست', 'ms': 'Belum ada gambar'},
  'mosque_last_updated': {'ar': 'آخر تحديث', 'en': 'Last updated', 'am': 'መጨረሻ የተዘመነው', 'fr': 'Dernière mise à jour', 'sw': 'Ilisasishwa mara ya mwisho', 'ur': 'آخری تازہ کاری', 'tr': 'Son güncelleme', 'id': 'Terakhir diperbarui', 'bn': 'সর্বশেষ হালনাগাদ', 'ha': 'Sabuntawa ta ƙarshe', 'so': 'Cusboonaysiintii ugu dambeysay', 'fa': 'آخرین به‌روزرسانی', 'ms': 'Kemas kini terakhir'},
  'mosque_next_prayer': {'ar': 'الصلاة القادمة', 'en': 'Next prayer', 'am': 'ቀጣይ ሶላት', 'fr': 'Prochaine prière', 'sw': 'Sala ijayo', 'ur': 'اگلی نماز', 'tr': 'Sonraki namaz', 'id': 'Salat berikutnya', 'bn': 'পরবর্তী নামাজ', 'ha': 'Sallar gaba', 'so': 'Salaadda xigta', 'fa': 'نماز بعدی', 'ms': 'Solat seterusnya'},
  'mosque_prayer_note': {'ar': 'الأوقات محسوبة من موقع المسجد وقد تختلف عن جماعته بدقائق', 'en': 'Calculated from the mosque’s location — may differ from its jamā‘ah by a few minutes.', 'am': 'ከመስጊዱ አካባቢ የተሰላ — ከጀመዓው ጋር በደቂቃዎች ሊለያይ ይችላል።', 'fr': 'Calculé à partir de l’emplacement de la mosquée — peut différer de quelques minutes de sa jama’ah.', 'sw': 'Imehesabiwa kutoka eneo la msikiti — inaweza kutofautiana na jamaa yake kwa dakika chache.', 'ur': 'مسجد کے مقام سے حساب کیا گیا — جماعت کے وقت سے چند منٹ مختلف ہو سکتا ہے۔', 'tr': 'Caminin konumundan hesaplanmıştır — cemaatinden birkaç dakika farklı olabilir.', 'id': 'Dihitung dari lokasi masjid — bisa berbeda beberapa menit dari jamaahnya.', 'bn': 'মসজিদের অবস্থান থেকে হিসাব করা — জামাতের সময় থেকে কয়েক মিনিট ভিন্ন হতে পারে।', 'ha': 'An lissafa daga wurin masallaci — na iya bambanta da jama’a da ‘yan mintuna.', 'so': 'Waxaa laga xisaabiyay goobta masjidka — waxay ka duwanaan kartaa jamaacadiisa dhowr daqiiqo.', 'fa': 'از موقعیت مسجد محاسبه شده — ممکن است چند دقیقه با جماعتش تفاوت داشته باشد.', 'ms': 'Dikira daripada lokasi masjid — mungkin berbeza beberapa minit daripada jemaahnya.'},
  'mosque_offline_cache': {'ar': 'بلا اتصال — تُعرض نسخة محفوظة', 'en': 'Offline — showing a saved copy', 'am': 'ከመስመር ውጭ — የተቀመጠ ቅጂ እየታየ ነው', 'fr': 'Hors ligne — affichage d’une copie enregistrée', 'sw': 'Nje ya mtandao — inaonyesha nakala iliyohifadhiwa', 'ur': 'آف لائن — محفوظ شدہ کاپی دکھائی جا رہی ہے', 'tr': 'Çevrimdışı — kaydedilmiş bir kopya gösteriliyor', 'id': 'Luring — menampilkan salinan tersimpan', 'bn': 'অফলাইন — সংরক্ষিত কপি দেখানো হচ্ছে', 'ha': 'Ba kan layi ba — ana nuna kwafin da aka ajiye', 'so': 'Offline — waxaa la muujinayaa nuqul la kaydiyay', 'fa': 'آفلاین — نسخه ذخیره‌شده نمایش داده می‌شود', 'ms': 'Luar talian — memaparkan salinan yang disimpan'},
  'mosque_distance_prefix': {'ar': 'على بُعد', 'en': 'About', 'am': 'በግምት', 'fr': 'À environ', 'sw': 'Umbali wa', 'ur': 'تقریباً', 'tr': 'Yaklaşık', 'id': 'Sekitar', 'bn': 'প্রায়', 'ha': 'Kusan', 'so': 'Qiyaastii', 'fa': 'تقریباً', 'ms': 'Kira-kira'},
  'unit_metre': {'ar': 'م', 'en': 'm', 'am': 'ሜ', 'fr': 'm', 'sw': 'm', 'ur': 'میٹر', 'tr': 'm', 'id': 'm', 'bn': 'মি', 'ha': 'm', 'so': 'm', 'fa': 'متر', 'ms': 'm'},
  'unit_km': {'ar': 'كم', 'en': 'km', 'am': 'ኪሜ', 'fr': 'km', 'sw': 'km', 'ur': 'کلومیٹر', 'tr': 'km', 'id': 'km', 'bn': 'কিমি', 'ha': 'km', 'so': 'km', 'fa': 'کیلومتر', 'ms': 'km'},
  'mosque_open_page': {'ar': 'افتح صفحة المسجد', 'en': 'Open mosque page', 'am': 'የመስጊድ ገጽ ክፈት', 'fr': 'Ouvrir la page de la mosquée', 'sw': 'Fungua ukurasa wa msikiti', 'ur': 'مسجد کا صفحہ کھولیں', 'tr': 'Cami sayfasını aç', 'id': 'Buka halaman masjid', 'bn': 'মসজিদের পৃষ্ঠা খুলুন', 'ha': 'Buɗe shafin masallaci', 'so': 'Fur boggga masjidka', 'fa': 'باز کردن صفحه مسجد', 'ms': 'Buka halaman masjid'},
  'pause_action': {'ar': 'إيقاف مؤقت', 'en': 'Pause', 'am': 'ለአፍታ አቁም', 'fr': 'Pause', 'sw': 'Simamisha', 'ur': 'وقفہ', 'tr': 'Duraklat', 'id': 'Jeda', 'bn': 'বিরতি', 'ha': 'Dakata', 'so': 'Jooji', 'fa': 'مکث', 'ms': 'Jeda'},
  'reading_session_prompt': {'ar': 'كم دقيقة ستقرأ الآن؟', 'en': 'How many minutes will you read now?', 'am': 'አሁን ስንት ደቂቃ ታነባለህ?', 'fr': 'Combien de minutes vas-tu lire ?', 'sw': 'Utasoma dakika ngapi sasa?', 'ur': 'ابھی کتنے منٹ پڑھیں گے؟', 'tr': 'Şimdi kaç dakika okuyacaksın?', 'id': 'Berapa menit kamu akan membaca?', 'bn': 'এখন কত মিনিট পড়বে?', 'ha': 'Mintuna nawa za ka karanta yanzu?', 'so': 'Immisa daqiiqo ayaad hadda akhrinaysaa?', 'fa': 'اکنون چند دقیقه می‌خوانی؟', 'ms': 'Berapa minit anda akan membaca?'},
  'reading_session_done': {'ar': 'أتممت جلسة القراءة — أحسنت!', 'en': 'Reading session complete — well done!', 'am': 'የንባብ ክፍለ ጊዜ ተጠናቀቀ — ጎበዝ!', 'fr': 'Séance de lecture terminée — bravo !', 'sw': 'Kikao cha kusoma kimekamilika — hongera!', 'ur': 'مطالعے کا سیشن مکمل — شاباش!', 'tr': 'Okuma seansı tamam — aferin!', 'id': 'Sesi membaca selesai — bagus!', 'bn': 'পড়ার সেশন সম্পন্ন — সাবাশ!', 'ha': 'An gama zaman karatu — madalla!', 'so': 'Fadhiga akhriska waa dhammaaday — aad baad u fiicantahay!', 'fa': 'جلسه مطالعه کامل شد — آفرین!', 'ms': 'Sesi bacaan selesai — syabas!'},
  'tahfeez_audio_action': {'ar': 'التحفيظ الصوتي', 'en': 'Audio memorization', 'am': 'የድምፅ ማጥናት', 'fr': 'Mémorisation audio', 'sw': 'Kuhifadhi kwa sauti', 'ur': 'آڈیو حفظ', 'tr': 'Sesli ezber', 'id': 'Hafalan audio', 'bn': 'অডিও মুখস্থ', 'ha': 'Haddar sauti', 'so': 'Xafidhka codka', 'fa': 'حفظ صوتی', 'ms': 'Hafazan audio'},
  'recite_page_action': {'ar': 'تسميع الصفحة كاملة', 'en': 'Recite the whole page', 'am': 'ገጹን ሙሉ አንብብ', 'fr': 'Réciter toute la page', 'sw': 'Soma ukurasa mzima', 'ur': 'پورا صفحہ سنائیں', 'tr': 'Tüm sayfayı oku', 'id': 'Bacakan seluruh halaman', 'bn': 'পুরো পৃষ্ঠা তিলাওয়াত', 'ha': 'Karanta shafi duka', 'so': 'Akhri bogga oo dhan', 'fa': 'تلاوت کل صفحه', 'ms': 'Baca seluruh halaman'},

  // ---- AKHLAQ training system (P4) — al-Rifq slice UI
  'akhlaq_card_title': {'ar': 'تدريب الأخلاق', 'en': 'Character training', 'am': 'የስነምግባር ልምምድ', 'fr': 'Entraînement du caractère', 'sw': 'Mazoezi ya tabia', 'ur': 'اخلاق کی مشق', 'tr': 'Karakter eğitimi', 'id': 'Latihan akhlak', 'bn': 'চরিত্র প্রশিক্ষণ', 'ha': 'Horar da hali', 'so': 'Tababbarista dabeecadda', 'fa': 'تمرین اخلاق', 'ms': 'Latihan akhlak'},
  'akhlaq_card_tagline': {'ar': 'معرفة ← تدريب ← عادة', 'en': 'Knowledge → training → habit', 'am': 'እውቀት ← ልምምድ ← ልማድ', 'fr': 'Savoir → entraînement → habitude', 'sw': 'Elimu → mazoezi → tabia', 'ur': 'علم ← مشق ← عادت', 'tr': 'Bilgi → eğitim → alışkanlık', 'id': 'Ilmu → latihan → kebiasaan', 'bn': 'জ্ঞান → প্রশিক্ষণ → অভ্যাস', 'ha': 'Ilimi → horo → ɗabi’a', 'so': 'Aqoon → tababbar → caado', 'fa': 'دانش ← تمرین ← عادت', 'ms': 'Ilmu → latihan → kebiasaan'},
  'akhlaq_home_title': {'ar': 'تدريب الرِّفق', 'en': 'Training gentleness (al-Rifq)', 'am': 'የርኅራኄ ልምምድ', 'fr': 'Entraînement à la douceur (al-Rifq)', 'sw': 'Mazoezi ya upole (al-Rifq)', 'ur': 'نرمی کی مشق (الرِّفق)', 'tr': 'Yumuşaklık eğitimi (er-Rifk)', 'id': 'Latihan kelembutan (ar-Rifq)', 'bn': 'কোমলতার প্রশিক্ষণ (আর-রিফক)', 'ha': 'Horar da tausayi (al-Rifq)', 'so': 'Tababbarista naxariista (al-Rifq)', 'fa': 'تمرین نرمی (الرِّفق)', 'ms': 'Latihan kelembutan (ar-Rifq)'},
  'akhlaq_opposite': {'ar': 'ضدُّه', 'en': 'Opposite', 'am': 'ተቃራኒው', 'fr': 'Opposé', 'sw': 'Kinyume chake', 'ur': 'اِس کی ضد', 'tr': 'Zıddı', 'id': 'Lawannya', 'bn': 'বিপরীত', 'ha': 'Akasi', 'so': 'Liddiga', 'fa': 'متضاد', 'ms': 'Lawannya'},
  'akhlaq_today_plan': {'ar': 'تكليف اليوم', 'en': 'Today\'s practice', 'am': 'የዛሬ ተግባር', 'fr': 'Pratique du jour', 'sw': 'Zoezi la leo', 'ur': 'آج کی مشق', 'tr': 'Bugünün alıştırması', 'id': 'Latihan hari ini', 'bn': 'আজকের অনুশীলন', 'ha': 'Aikin yau', 'so': 'Layliga maanta', 'fa': 'تمرین امروز', 'ms': 'Latihan hari ini'},
  'akhlaq_track_k': {'ar': 'استرجاع', 'en': 'Recall', 'am': 'ማስታወስ', 'fr': 'Rappel', 'sw': 'Kumbuka', 'ur': 'یاد دہانی', 'tr': 'Hatırlama', 'id': 'Mengingat', 'bn': 'স্মরণ', 'ha': 'Tunawa', 'so': 'Xasuusin', 'fa': 'یادآوری', 'ms': 'Mengingat'},
  'akhlaq_track_s': {'ar': 'موقف جديد', 'en': 'New scenario', 'am': 'አዲስ ሁኔታ', 'fr': 'Nouvelle situation', 'sw': 'Hali mpya', 'ur': 'نیا منظر', 'tr': 'Yeni senaryo', 'id': 'Skenario baru', 'bn': 'নতুন পরিস্থিতি', 'ha': 'Sabon yanayi', 'so': 'Xaalad cusub', 'fa': 'موقعیت جدید', 'ms': 'Senario baharu'},
  'akhlaq_track_r': {'ar': 'مراجعة الأسبوع', 'en': 'Weekly review', 'am': 'ሳምንታዊ ግምገማ', 'fr': 'Bilan hebdomadaire', 'sw': 'Mapitio ya wiki', 'ur': 'ہفتہ وار جائزہ', 'tr': 'Haftalık gözden geçirme', 'id': 'Tinjauan mingguan', 'bn': 'সাপ্তাহিক পর্যালোচনা', 'ha': 'Bitar mako-mako', 'so': 'Dib u eegis toddobaadle', 'fa': 'مرور هفتگی', 'ms': 'Semakan mingguan'},
  'akhlaq_open_profile': {'ar': 'المؤشّر التدريبي', 'en': 'Training indicator', 'am': 'የልምምድ ጠቋሚ', 'fr': 'Indicateur d\'entraînement', 'sw': 'Kiashiria cha mazoezi', 'ur': 'تربیتی اشاریہ', 'tr': 'Eğitim göstergesi', 'id': 'Indikator latihan', 'bn': 'প্রশিক্ষণ নির্দেশক', 'ha': 'Alamar horo', 'so': 'Tilmaamaha tababbarka', 'fa': 'شاخص تمرین', 'ms': 'Penunjuk latihan'},
  'akhlaq_focus_week': {'ar': 'مهارة التركيز', 'en': 'Focus skill', 'am': 'የትኩረት ክህሎት', 'fr': 'Compétence ciblée', 'sw': 'Ujuzi wa kuzingatia', 'ur': 'توجہ کی مہارت', 'tr': 'Odak becerisi', 'id': 'Keterampilan fokus', 'bn': 'মনোযোগের দক্ষতা', 'ha': 'Ƙwarewar mai da hankali', 'so': 'Xirfadda diirradda', 'fa': 'مهارت تمرکز', 'ms': 'Kemahiran fokus'},
  'akhlaq_focus_hint': {'ar': 'اختر مهارةً تُركّز عليها هذه الأيّام', 'en': 'Pick one subskill to focus on these days', 'am': 'በእነዚህ ቀናት የምታተኩርበትን ንዑስ ክህሎት ምረጥ', 'fr': 'Choisis une sous-compétence à travailler ces jours-ci', 'sw': 'Chagua ujuzi mmoja wa kuzingatia siku hizi', 'ur': 'اِن دنوں جس مہارت پر توجہ دینی ہے وہ چنیں', 'tr': 'Bu günlerde odaklanacağın bir alt beceri seç', 'id': 'Pilih satu subketerampilan untuk difokuskan', 'bn': 'এই দিনগুলোতে একটি উপ-দক্ষতা বেছে নিন', 'ha': 'Zaɓi ƙaramar ƙwarewa da za ka mai da hankali a kai', 'so': 'Dooro xirfad hoosaad oo aad diiradda saarto', 'fa': 'یک زیرمهارت برای تمرکز این روزها انتخاب کن', 'ms': 'Pilih satu subkemahiran untuk difokuskan'},
  'akhlaq_no_plan': {'ar': 'لا مهامّ الآن — راجعْ لاحقًا', 'en': 'Nothing due now — check back later', 'am': 'አሁን ምንም የለም — ቆይተህ ተመልከት', 'fr': 'Rien à faire pour l\'instant — reviens plus tard', 'sw': 'Hakuna kazi sasa — angalia baadaye', 'ur': 'ابھی کچھ نہیں — بعد میں دیکھیں', 'tr': 'Şimdilik bir şey yok — sonra bak', 'id': 'Belum ada tugas — cek lagi nanti', 'bn': 'এখন কিছু নেই — পরে দেখুন', 'ha': 'Babu kome yanzu — dawo daga baya', 'so': 'Waxba ma jiraan hadda — mar dambe eeg', 'fa': 'اکنون چیزی نیست — بعداً بررسی کن', 'ms': 'Tiada tugasan kini — semak semula nanti'},
  'akhlaq_scenario_level': {'ar': 'موقف — مستوى', 'en': 'Scenario — level', 'am': 'ሁኔታ — ደረጃ', 'fr': 'Situation — niveau', 'sw': 'Hali — kiwango', 'ur': 'منظر — سطح', 'tr': 'Senaryo — seviye', 'id': 'Skenario — tingkat', 'bn': 'পরিস্থিতি — স্তর', 'ha': 'Yanayi — mataki', 'so': 'Xaalad — heer', 'fa': 'موقعیت — سطح', 'ms': 'Senario — tahap'},
  'akhlaq_level_note': {'ar': 'المستوى صعوبة الموقف، لا حكمًا على اختيارك', 'en': 'The level is the scenario\'s difficulty, not a judgement of your choice', 'am': 'ደረጃው የሁኔታው ክብደት ነው፣ የምርጫህ ፍርድ አይደለም', 'fr': 'Le niveau est la difficulté de la situation, pas un jugement de ton choix', 'sw': 'Kiwango ni ugumu wa hali, si hukumu ya chaguo lako', 'ur': 'سطح منظر کی دشواری ہے، آپ کے انتخاب پر فیصلہ نہیں', 'tr': 'Seviye senaryonun zorluğudur, seçiminizin yargısı değil', 'id': 'Tingkat adalah kesulitan skenario, bukan penilaian pilihanmu', 'bn': 'স্তর হলো পরিস্থিতির কঠিনতা, আপনার পছন্দের বিচার নয়', 'ha': 'Matakin shine wahalar yanayin, ba hukunci kan zaɓinka ba', 'so': 'Heerku waa adkaanta xaaladda, maaha xukun ku saabsan doorashadaada', 'fa': 'سطح، دشواری موقعیت است، نه قضاوتی درباره انتخاب تو', 'ms': 'Tahap ialah kesukaran senario, bukan penilaian pilihan anda'},
  'akhlaq_composite': {'ar': 'موقف مركّب', 'en': 'Composite scenario', 'am': 'ውሁድ ሁኔታ', 'fr': 'Situation composite', 'sw': 'Hali changamano', 'ur': 'مرکب منظر', 'tr': 'Bileşik senaryo', 'id': 'Skenario majemuk', 'bn': 'যৌগিক পরিস্থিতি', 'ha': 'Haɗaɗɗen yanayi', 'so': 'Xaalad isku dhafan', 'fa': 'موقعیت ترکیبی', 'ms': 'Senario kompaun'},
  'akhlaq_choose': {'ar': 'اختر استجابتك', 'en': 'Choose your response', 'am': 'ምላሽህን ምረጥ', 'fr': 'Choisis ta réponse', 'sw': 'Chagua jibu lako', 'ur': 'اپنا ردعمل چنیں', 'tr': 'Tepkini seç', 'id': 'Pilih responsmu', 'bn': 'আপনার প্রতিক্রিয়া বেছে নিন', 'ha': 'Zaɓi amsarka', 'so': 'Dooro jawaabkaaga', 'fa': 'پاسخ خود را انتخاب کن', 'ms': 'Pilih respons anda'},
  'akhlaq_verdict_aqrab': {'ar': 'الاستجابة الأقرب للرفق في هذا الموقف', 'en': 'The response closest to gentleness here', 'am': 'እዚህ ለርኅራኄ በጣም ቅርብ የሆነው ምላሽ', 'fr': 'La réponse la plus proche de la douceur ici', 'sw': 'Jibu lililo karibu zaidi na upole hapa', 'ur': 'اِس موقع پر نرمی کے سب سے قریب ردعمل', 'tr': 'Burada yumuşaklığa en yakın tepki', 'id': 'Respons yang paling dekat dengan kelembutan di sini', 'bn': 'এখানে কোমলতার সবচেয়ে কাছের প্রতিক্রিয়া', 'ha': 'Amsar da ta fi kusa da tausayi a nan', 'so': 'Jawaabta ugu dhow naxariista halkan', 'fa': 'نزدیک‌ترین پاسخ به نرمی در این موقعیت', 'ms': 'Respons paling hampir dengan kelembutan di sini'},
  'akhlaq_verdict_maqbul': {'ar': 'المضمون مقبول، والأسلوب يحتاج رفقًا', 'en': 'The substance is acceptable; the manner needs more gentleness', 'am': 'ይዘቱ ተቀባይነት አለው፤ አኳኋኑ ተጨማሪ ርኅራኄ ይፈልጋል', 'fr': 'Le fond est acceptable ; la manière demande plus de douceur', 'sw': 'Maudhui yanakubalika; namna inahitaji upole zaidi', 'ur': 'مواد قابل قبول ہے، انداز میں مزید نرمی چاہیے', 'tr': 'İçerik kabul edilebilir; üslup daha fazla yumuşaklık gerektiriyor', 'id': 'Substansinya dapat diterima; caranya perlu lebih lembut', 'bn': 'বিষয়বস্তু গ্রহণযোগ্য; ভঙ্গিতে আরও কোমলতা দরকার', 'ha': 'Abin da ke ciki yana karɓuwa; salon yana buƙatar ƙarin tausayi', 'so': 'Nuxurku waa la aqbali karaa; qaabku wuxuu u baahan yahay naxariis dheeraad ah', 'fa': 'محتوا قابل قبول است؛ شیوه به نرمی بیشتری نیاز دارد', 'ms': 'Isinya boleh diterima; caranya perlu lebih lembut'},
  'akhlaq_verdict_baid': {'ar': 'هذه الاستجابة بعيدة عن الرفق في هذا الموقف', 'en': 'This response is far from gentleness in this situation', 'am': 'ይህ ምላሽ በዚህ ሁኔታ ከርኅራኄ የራቀ ነው', 'fr': 'Cette réponse est loin de la douceur dans cette situation', 'sw': 'Jibu hili liko mbali na upole katika hali hii', 'ur': 'یہ ردعمل اِس صورتحال میں نرمی سے دور ہے', 'tr': 'Bu tepki bu durumda yumuşaklıktan uzak', 'id': 'Respons ini jauh dari kelembutan dalam situasi ini', 'bn': 'এই প্রতিক্রিয়া এই পরিস্থিতিতে কোমলতা থেকে দূরে', 'ha': 'Wannan amsar tana da nisa da tausayi a wannan yanayin', 'so': 'Jawaabtan waxay ka fog tahay naxariista xaaladdan', 'fa': 'این پاسخ در این موقعیت از نرمی دور است', 'ms': 'Respons ini jauh daripada kelembutan dalam keadaan ini'},
  'akhlaq_verdict_short_aqrab': {'ar': 'الأقرب', 'en': 'Closest', 'am': 'ቅርቡ', 'fr': 'Plus proche', 'sw': 'Karibu zaidi', 'ur': 'قریب ترین', 'tr': 'En yakın', 'id': 'Terdekat', 'bn': 'নিকটতম', 'ha': 'Mafi kusa', 'so': 'Ugu dhow', 'fa': 'نزدیک‌ترین', 'ms': 'Terdekat'},
  'akhlaq_verdict_short_maqbul': {'ar': 'مقبول', 'en': 'Acceptable', 'am': 'ተቀባይ', 'fr': 'Acceptable', 'sw': 'Inakubalika', 'ur': 'قابل قبول', 'tr': 'Kabul edilebilir', 'id': 'Bisa diterima', 'bn': 'গ্রহণযোগ্য', 'ha': 'Yana karɓuwa', 'so': 'La aqbali karo', 'fa': 'قابل قبول', 'ms': 'Boleh diterima'},
  'akhlaq_verdict_short_baid': {'ar': 'بعيد', 'en': 'Far', 'am': 'የራቀ', 'fr': 'Éloigné', 'sw': 'Mbali', 'ur': 'دور', 'tr': 'Uzak', 'id': 'Jauh', 'bn': 'দূরে', 'ha': 'Nisa', 'so': 'Fog', 'fa': 'دور', 'ms': 'Jauh'},
  'akhlaq_why': {'ar': 'لماذا', 'en': 'Why', 'am': 'ለምን', 'fr': 'Pourquoi', 'sw': 'Kwa nini', 'ur': 'کیوں', 'tr': 'Neden', 'id': 'Mengapa', 'bn': 'কেন', 'ha': 'Me ya sa', 'so': 'Waa maxay sababta', 'fa': 'چرا', 'ms': 'Mengapa'},
  'akhlaq_full_feedback': {'ar': 'تعليق', 'en': 'Feedback', 'am': 'አስተያየት', 'fr': 'Retour', 'sw': 'Maoni', 'ur': 'تبصرہ', 'tr': 'Geri bildirim', 'id': 'Umpan balik', 'bn': 'প্রতিক্রিয়া', 'ha': 'Ra\'ayi', 'so': 'Jawaab celin', 'fa': 'بازخورد', 'ms': 'Maklum balas'},
  'akhlaq_evidence': {'ar': 'الدليل', 'en': 'Evidence', 'am': 'ማስረጃ', 'fr': 'Preuve', 'sw': 'Ushahidi', 'ur': 'دلیل', 'tr': 'Delil', 'id': 'Dalil', 'bn': 'প্রমাণ', 'ha': 'Shaida', 'so': 'Cadeyn', 'fa': 'دلیل', 'ms': 'Dalil'},
  'akhlaq_grading': {'ar': 'الحكم', 'en': 'Grading', 'am': 'ደረጃ አሰጣጥ', 'fr': 'Authentification', 'sw': 'Daraja', 'ur': 'درجہ', 'tr': 'Derece', 'id': 'Penilaian', 'bn': 'শ্রেণিবিন্যাস', 'ha': 'Daraja', 'so': 'Darajada', 'fa': 'درجه‌بندی', 'ms': 'Penggredan'},
  'akhlaq_reflect': {'ar': 'للمحاسبة', 'en': 'For self-reckoning', 'am': 'ለራስ ሒሳብ', 'fr': 'Pour l\'introspection', 'sw': 'Kwa kujihasibu', 'ur': 'محاسبے کے لیے', 'tr': 'Nefis muhasebesi için', 'id': 'Untuk muhasabah diri', 'bn': 'আত্ম-হিসাবের জন্য', 'ha': 'Domin lissafin kai', 'so': 'Xisaabinta nafta', 'fa': 'برای محاسبه نفس', 'ms': 'Untuk muhasabah diri'},
  'akhlaq_probe': {'ar': 'سؤال للتأمّل', 'en': 'A question to ponder', 'am': 'የሚታሰብ ጥያቄ', 'fr': 'Une question à méditer', 'sw': 'Swali la kutafakari', 'ur': 'غور کرنے کا سوال', 'tr': 'Düşünülecek bir soru', 'id': 'Pertanyaan untuk direnungkan', 'bn': 'ভাবনার একটি প্রশ্ন', 'ha': 'Tambaya don yin tunani', 'so': 'Su\'aal lagu fekero', 'fa': 'پرسشی برای تأمل', 'ms': 'Soalan untuk direnung'},
  'akhlaq_another': {'ar': 'موقف آخر', 'en': 'Another scenario', 'am': 'ሌላ ሁኔታ', 'fr': 'Autre situation', 'sw': 'Hali nyingine', 'ur': 'ایک اور منظر', 'tr': 'Başka bir senaryo', 'id': 'Skenario lain', 'bn': 'আরেকটি পরিস্থিতি', 'ha': 'Wani yanayi', 'so': 'Xaalad kale', 'fa': 'موقعیت دیگر', 'ms': 'Senario lain'},
  'akhlaq_done': {'ar': 'تمّ', 'en': 'Done', 'am': 'ተከናውኗል', 'fr': 'Terminé', 'sw': 'Imekamilika', 'ur': 'ہو گیا', 'tr': 'Tamam', 'id': 'Selesai', 'bn': 'সম্পন্ন', 'ha': 'An gama', 'so': 'Waa la dhammeeyay', 'fa': 'انجام شد', 'ms': 'Selesai'},
  'akhlaq_source_hint': {'ar': 'الأصل العربي هو المعتمد؛ الترجمة للتقريب', 'en': 'The Arabic original is authoritative; the translation is for approximation', 'am': 'የዐረብኛው ዋና ነው፤ ትርጉሙ ለማቅረብ ነው', 'fr': 'L\'original arabe fait foi ; la traduction est indicative', 'sw': 'Asili ya Kiarabu ndiyo yenye mamlaka; tafsiri ni ya kukadiria', 'ur': 'عربی اصل معتبر ہے؛ ترجمہ تقریب کے لیے ہے', 'tr': 'Arapça asıl esastır; çeviri yaklaşıktır', 'id': 'Naskah asli Arab yang otoritatif; terjemahan hanya pendekatan', 'bn': 'আরবি মূলটিই প্রামাণিক; অনুবাদ কেবল আনুমানিক', 'ha': 'Asalin Larabci shine ingantacce; fassarar don kusanci ce', 'so': 'Qoraalka Carabiga ah ee asalka ah ayaa la tixgeliyaa; tarjumaadu waa u dhawaansho', 'fa': 'اصل عربی معتبر است؛ ترجمه برای تقریب است', 'ms': 'Teks asal Arab yang muktamad; terjemahan hanya penghampiran'},
  'akhlaq_profile_title': {'ar': 'المؤشّر التدريبي — الرِّفق', 'en': 'Training indicator — al-Rifq', 'am': 'የልምምድ ጠቋሚ — አል-ሪፍቅ', 'fr': 'Indicateur d\'entraînement — al-Rifq', 'sw': 'Kiashiria cha mazoezi — al-Rifq', 'ur': 'تربیتی اشاریہ — الرِّفق', 'tr': 'Eğitim göstergesi — er-Rifk', 'id': 'Indikator latihan — ar-Rifq', 'bn': 'প্রশিক্ষণ নির্দেশক — আর-রিফক', 'ha': 'Alamar horo — al-Rifq', 'so': 'Tilmaamaha tababbarka — al-Rifq', 'fa': 'شاخص تمرین — الرِّفق', 'ms': 'Penunjuk latihan — ar-Rifq'},
  'akhlaq_band_beginner': {'ar': 'لم يبدأ', 'en': 'Not started', 'am': 'አልተጀመረም', 'fr': 'Non commencé', 'sw': 'Haijaanza', 'ur': 'شروع نہیں ہوا', 'tr': 'Başlanmadı', 'id': 'Belum dimulai', 'bn': 'শুরু হয়নি', 'ha': 'Ba a fara ba', 'so': 'Lama bilaabin', 'fa': 'شروع‌نشده', 'ms': 'Belum bermula'},
  'akhlaq_band_practising': {'ar': 'تحت الممارسة', 'en': 'Practising', 'am': 'በመለማመድ ላይ', 'fr': 'En pratique', 'sw': 'Inafanyiwa mazoezi', 'ur': 'مشق جاری', 'tr': 'Alıştırma yapılıyor', 'id': 'Sedang berlatih', 'bn': 'অনুশীলনে', 'ha': 'Ana horo', 'so': 'Layli socda', 'fa': 'در حال تمرین', 'ms': 'Sedang berlatih'},
  'akhlaq_band_stable': {'ar': 'ثبات', 'en': 'Steady', 'am': 'የተረጋጋ', 'fr': 'Stable', 'sw': 'Thabiti', 'ur': 'استحکام', 'tr': 'Kararlı', 'id': 'Stabil', 'bn': 'স্থিতিশীল', 'ha': 'Tsayayye', 'so': 'Deggan', 'fa': 'پایدار', 'ms': 'Stabil'},
  'akhlaq_band_mastery': {'ar': 'تمكّن في التدريب', 'en': 'Trained well', 'am': 'በደንብ የተለማመደ', 'fr': 'Bien entraîné', 'sw': 'Amezoezwa vizuri', 'ur': 'تربیت میں مہارت', 'tr': 'İyi eğitilmiş', 'id': 'Terlatih baik', 'bn': 'ভালোভাবে প্রশিক্ষিত', 'ha': 'An horar da kyau', 'so': 'Si fiican loo tababbaray', 'fa': 'خوب تمرین‌شده', 'ms': 'Terlatih baik'},
  'akhlaq_band_review': {'ar': 'يحتاج مراجعة', 'en': 'Needs review', 'am': 'ግምገማ ይፈልጋል', 'fr': 'À revoir', 'sw': 'Inahitaji mapitio', 'ur': 'جائزے کی ضرورت', 'tr': 'Gözden geçirilmeli', 'id': 'Perlu ditinjau', 'bn': 'পর্যালোচনা প্রয়োজন', 'ha': 'Yana buƙatar bitar', 'so': 'U baahan dib u eegis', 'fa': 'نیازمند مرور', 'ms': 'Perlu semakan'},
  'akhlaq_aqrab_count': {'ar': 'في آخر {n} موقفًا لهذه المهارة، اخترت الاستجابة الأرفق {k} مرّة', 'en': 'In the last {n} scenarios for this subskill, you chose the gentler response {k} times', 'am': 'በዚህ ንዑስ ክህሎት ውስጥ ባለፉት {n} ሁኔታዎች፣ ይበልጥ ርኅሩኅ ምላሹን {k} ጊዜ መርጠሃል', 'fr': 'Sur les {n} dernières situations de cette sous-compétence, tu as choisi la réponse la plus douce {k} fois', 'sw': 'Katika hali {n} za mwisho za ujuzi huu, ulichagua jibu la upole zaidi mara {k}', 'ur': 'اِس مہارت کے آخری {n} مناظر میں، آپ نے نرم تر ردعمل {k} بار چنا', 'tr': 'Bu alt becerinin son {n} senaryosunda, daha yumuşak tepkiyi {k} kez seçtin', 'id': 'Dalam {n} skenario terakhir untuk subketerampilan ini, kamu memilih respons yang lebih lembut {k} kali', 'bn': 'এই উপ-দক্ষতার শেষ {n}টি পরিস্থিতিতে, আপনি {k} বার কোমলতর প্রতিক্রিয়া বেছেছেন', 'ha': 'A cikin yanayi {n} na ƙarshe na wannan ƙwarewa, ka zaɓi amsar da ta fi tausayi sau {k}', 'so': '{n}-tii xaaladood ee ugu dambeeyay ee xirfaddan, waxaad dooratay jawaabta naxariista badan {k} jeer', 'fa': 'در {n} موقعیت اخیر این زیرمهارت، پاسخ نرم‌تر را {k} بار انتخاب کردی', 'ms': 'Dalam {n} senario terakhir untuk subkemahiran ini, anda memilih respons lebih lembut sebanyak {k} kali'},
  'akhlaq_weak_dim': {'ar': 'أكثر بُعدٍ ظهر فيه ضعفٌ مؤخرًا', 'en': 'Dimension that showed weakness recently', 'am': 'በቅርቡ ድክመት ያሳየ ገጽታ', 'fr': 'Dimension qui a récemment montré une faiblesse', 'sw': 'Kipimo kilichoonyesha udhaifu hivi karibuni', 'ur': 'حال ہی میں کمزوری ظاہر کرنے والا پہلو', 'tr': 'Son zamanlarda zayıflık gösteren boyut', 'id': 'Dimensi yang baru-baru ini menunjukkan kelemahan', 'bn': 'সম্প্রতি দুর্বলতা দেখানো মাত্রা', 'ha': 'Fannin da ya nuna rauni kwanan nan', 'so': 'Cabbirka dhawaan daciifnimo muujiyay', 'fa': 'بُعدی که اخیراً ضعف نشان داده', 'ms': 'Dimensi yang menunjukkan kelemahan baru-baru ini'},
  'akhlaq_no_attempts': {'ar': 'لا تدريبات بعد', 'en': 'No practice yet', 'am': 'እስካሁን ልምምድ የለም', 'fr': 'Pas encore d\'entraînement', 'sw': 'Bado hakuna mazoezi', 'ur': 'ابھی کوئی مشق نہیں', 'tr': 'Henüz alıştırma yok', 'id': 'Belum ada latihan', 'bn': 'এখনও কোনো অনুশীলন নেই', 'ha': 'Babu horo tukuna', 'so': 'Weli layli ma jiro', 'fa': 'هنوز تمرینی نیست', 'ms': 'Belum ada latihan'},
  'akhlaq_disclaimer': {'ar': 'هذا مؤشّر تدريبي مبني على إجاباتك وتدريباتك داخل التطبيق، وليس حكمًا على أخلاقك ولا على صلاحك. حقيقة الخُلُق يعلمها الله.', 'en': 'This is a training indicator based on your answers and practice inside the app. It is not a judgement of your character or your righteousness. Allah alone knows the reality of one\'s character.', 'am': 'ይህ በመተግበሪያው ውስጥ ባሉ መልሶችህና ልምምዶችህ ላይ የተመሠረተ የልምምድ ጠቋሚ ነው። የባህርይህ ወይም የደግነትህ ፍርድ አይደለም። የባህርይ እውነታ አላህ ብቻ ያውቃል።', 'fr': 'Ceci est un indicateur d\'entraînement basé sur tes réponses et ta pratique dans l\'application. Ce n\'est pas un jugement de ton caractère ni de ta piété. Allah seul connaît la réalité du caractère.', 'sw': 'Hiki ni kiashiria cha mazoezi kinachotegemea majibu na mazoezi yako ndani ya programu. Si hukumu ya tabia yako wala uchamungu wako. Allah pekee ndiye ajuaye uhalisia wa tabia.', 'ur': 'یہ ایپ کے اندر آپ کے جوابات اور مشق پر مبنی ایک تربیتی اشاریہ ہے۔ یہ آپ کے اخلاق یا صلاح پر فیصلہ نہیں۔ خُلق کی حقیقت اللہ ہی جانتا ہے۔', 'tr': 'Bu, uygulama içindeki cevaplarınıza ve alıştırmalarınıza dayalı bir eğitim göstergesidir. Karakterinizin veya salihliğinizin bir yargısı değildir. Karakterin gerçeğini yalnızca Allah bilir.', 'id': 'Ini adalah indikator latihan berdasarkan jawaban dan latihanmu di dalam aplikasi. Ini bukan penilaian atas akhlak atau kesalehanmu. Hanya Allah yang mengetahui hakikat akhlak seseorang.', 'bn': 'এটি অ্যাপের ভেতরে আপনার উত্তর ও অনুশীলনের ভিত্তিতে একটি প্রশিক্ষণ নির্দেশক। এটি আপনার চরিত্র বা তাকওয়ার বিচার নয়। চরিত্রের প্রকৃত অবস্থা কেবল আল্লাহই জানেন।', 'ha': 'Wannan alama ce ta horo bisa amsoshinka da horonka a cikin manhajar. Ba hukunci ba ne kan halinka ko ƙwarai da gaskiyarka. Allah kaɗai ya san gaskiyar hali.', 'so': 'Kani waa tilmaame tababbar oo ku salaysan jawaabahaaga iyo layliyaddaada gudaha appka. Maaha xukun ku saabsan dabeecaddaada ama wanaaggaaga. Xaqiiqada dabeecadda Alle kaliya ayaa og.', 'fa': 'این یک شاخص تمرینی بر پایه پاسخ‌ها و تمرین‌های تو درون برنامه است. این قضاوتی درباره اخلاق یا صلاح تو نیست. حقیقت خُلق را تنها خدا می‌داند.', 'ms': 'Ini ialah penunjuk latihan berdasarkan jawapan dan latihan anda dalam aplikasi. Ia bukan penilaian terhadap akhlak atau kesalihan anda. Hanya Allah mengetahui hakikat akhlak seseorang.'},
  'akhlaq_dim_gentleness': {'ar': 'الرِّفق', 'en': 'Gentleness', 'am': 'ርኅራኄ', 'fr': 'Douceur', 'sw': 'Upole', 'ur': 'نرمی', 'tr': 'Yumuşaklık', 'id': 'Kelembutan', 'bn': 'কোমলতা', 'ha': 'Tausayi', 'so': 'Naxariis', 'fa': 'نرمی', 'ms': 'Kelembutan'},
  'akhlaq_dim_justice': {'ar': 'العدل', 'en': 'Justice', 'am': 'ፍትሕ', 'fr': 'Justice', 'sw': 'Haki', 'ur': 'انصاف', 'tr': 'Adalet', 'id': 'Keadilan', 'bn': 'ন্যায়বিচার', 'ha': 'Adalci', 'so': 'Caddaalad', 'fa': 'عدالت', 'ms': 'Keadilan'},
  'akhlaq_dim_truthfulness': {'ar': 'الصدق', 'en': 'Truthfulness', 'am': 'እውነተኝነት', 'fr': 'Véracité', 'sw': 'Ukweli', 'ur': 'سچائی', 'tr': 'Doğruluk', 'id': 'Kejujuran', 'bn': 'সত্যবাদিতা', 'ha': 'Gaskiya', 'so': 'Runta', 'fa': 'راستگویی', 'ms': 'Kejujuran'},
  'akhlaq_dim_self_control': {'ar': 'ضبط النفس', 'en': 'Self-control', 'am': 'ራስን መቆጣጠር', 'fr': 'Maîtrise de soi', 'sw': 'Kujidhibiti', 'ur': 'ضبط نفس', 'tr': 'Öz denetim', 'id': 'Pengendalian diri', 'bn': 'আত্মনিয়ন্ত্রণ', 'ha': 'Kamun kai', 'so': 'Is-xakameyn', 'fa': 'خویشتن‌داری', 'ms': 'Kawalan diri'},
  'akhlaq_dim_respect': {'ar': 'الاحترام', 'en': 'Respect', 'am': 'አክብሮት', 'fr': 'Respect', 'sw': 'Heshima', 'ur': 'احترام', 'tr': 'Saygı', 'id': 'Rasa hormat', 'bn': 'সম্মান', 'ha': 'Girmamawa', 'so': 'Ixtiraam', 'fa': 'احترام', 'ms': 'Hormat'},
  'akhlaq_dim_timing': {'ar': 'حُسن التوقيت', 'en': 'Good timing', 'am': 'ጥሩ ጊዜ አመራረጥ', 'fr': 'Bon moment', 'sw': 'Wakati mzuri', 'ur': 'درست وقت', 'tr': 'İyi zamanlama', 'id': 'Waktu yang tepat', 'bn': 'সঠিক সময়', 'ha': 'Kyakkyawan lokaci', 'so': 'Waqti wanaagsan', 'fa': 'زمان‌بندی خوب', 'ms': 'Pemasaan yang baik'},
  'akhlaq_dim_intention_awareness': {'ar': 'مراقبة الباعث', 'en': 'Awareness of one\'s motive', 'am': 'የፍላጎት ንቃት', 'fr': 'Conscience du motif', 'sw': 'Kutambua nia', 'ur': 'نیت کی نگرانی', 'tr': 'Niyet farkındalığı', 'id': 'Kesadaran akan niat', 'bn': 'উদ্দেশ্য সম্পর্কে সচেতনতা', 'ha': 'Sanin dalili', 'so': 'Ogaanshaha ujeeddada', 'fa': 'آگاهی از انگیزه', 'ms': 'Kesedaran tentang niat'},
  'akhlaq_dim_firmness_when_needed': {'ar': 'الحزم عند الحاجة', 'en': 'Firmness when needed', 'am': 'በሚያስፈልግበት ጊዜ ጽናት', 'fr': 'Fermeté au besoin', 'sw': 'Uthabiti inapohitajika', 'ur': 'ضرورت پر سختی', 'tr': 'Gerektiğinde kararlılık', 'id': 'Ketegasan saat diperlukan', 'bn': 'প্রয়োজনে দৃঢ়তা', 'ha': 'Ƙarfi lokacin da ake buƙata', 'so': 'Adkeysi marka loo baahdo', 'fa': 'قاطعیت در صورت نیاز', 'ms': 'Ketegasan bila perlu'},

  // ---- Tafsir/translation section headers (TAFSIR_UNIFIED_ARCHITECTURE, 2026-09-11)
  'ql_tafsir_section': {'ar': 'تفاسير', 'en': 'Tafsir (exegesis)', 'am': 'ተፍሲር (ማብራሪያ)', 'fr': 'Tafsir (exégèse)', 'sw': 'Tafsiri (ufafanuzi)', 'ur': 'تفاسیر (تشریح)', 'tr': 'Tefsir (yorum)', 'id': 'Tafsir (penjelasan)', 'bn': 'তাফসির (ব্যাখ্যা)', 'ha': 'Tafsiri (bayani)', 'so': 'Tafsiir (sharraxaad)', 'fa': 'تفسیر (شرح)', 'ms': 'Tafsir (penjelasan)'},
  'ql_translation_section': {'ar': 'ترجمات', 'en': 'Translations', 'am': 'ትርጉሞች', 'fr': 'Traductions', 'sw': 'Tafsiri za lugha', 'ur': 'تراجم', 'tr': 'Çeviriler', 'id': 'Terjemahan', 'bn': 'অনুবাদসমূহ', 'ha': 'Fassarori', 'so': 'Turjumaadaha', 'fa': 'ترجمه‌ها', 'ms': 'Terjemahan'},
};

/// Looks up [key] in the student's current language, falling back to
/// Arabic (the source language) if a translation is missing for that key.
String basicText(String key, String languageCode) {
  final entry = basicTranslations[key];
  if (entry == null) return key;
  return entry[languageCode] ?? entry['ar'] ?? key;
}
