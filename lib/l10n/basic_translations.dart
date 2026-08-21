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
};

/// Looks up [key] in the student's current language, falling back to
/// Arabic (the source language) if a translation is missing for that key.
String basicText(String key, String languageCode) {
  final entry = basicTranslations[key];
  if (entry == null) return key;
  return entry[languageCode] ?? entry['ar'] ?? key;
}
