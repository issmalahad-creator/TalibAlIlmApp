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
};

/// Looks up [key] in the student's current language, falling back to
/// Arabic (the source language) if a translation is missing for that key.
String basicText(String key, String languageCode) {
  final entry = basicTranslations[key];
  if (entry == null) return key;
  return entry[languageCode] ?? entry['ar'] ?? key;
}
