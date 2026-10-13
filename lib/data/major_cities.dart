/// A short offline city list for when GPS gives nothing — picking a city is
/// friendlier than typing coordinates. City-centre coordinates (±0.05°,
/// well under a minute of prayer-time difference). Names: Arabic + English
/// (proper nouns, shown as-is in every UI language).
class MajorCity {
  final String ar;
  final String en;
  final String countryAr;
  final double lat;
  final double lng;
  const MajorCity(this.ar, this.en, this.countryAr, this.lat, this.lng);
}

const majorCities = <MajorCity>[
  // Ethiopia
  MajorCity('أديس أبابا', 'Addis Ababa', 'إثيوبيا', 9.03, 38.74),
  MajorCity('دير داوا', 'Dire Dawa', 'إثيوبيا', 9.59, 41.87),
  MajorCity('هرر', 'Harar', 'إثيوبيا', 9.31, 42.12),
  MajorCity('جِمّا', 'Jimma', 'إثيوبيا', 7.67, 36.83),
  MajorCity('ديسي', 'Dessie', 'إثيوبيا', 11.13, 39.63),
  MajorCity('بحر دار', 'Bahir Dar', 'إثيوبيا', 11.59, 37.39),
  MajorCity('مقلي', 'Mekelle', 'إثيوبيا', 13.50, 39.47),
  MajorCity('هواسا', 'Hawassa', 'إثيوبيا', 7.06, 38.48),
  MajorCity('أداما', 'Adama', 'إثيوبيا', 8.54, 39.27),
  // Arabia & the Gulf
  MajorCity('مكة المكرمة', 'Makkah', 'السعودية', 21.42, 39.83),
  MajorCity('المدينة المنورة', 'Madinah', 'السعودية', 24.47, 39.61),
  MajorCity('الرياض', 'Riyadh', 'السعودية', 24.71, 46.68),
  MajorCity('جدة', 'Jeddah', 'السعودية', 21.49, 39.19),
  MajorCity('دبي', 'Dubai', 'الإمارات', 25.20, 55.27),
  MajorCity('الدوحة', 'Doha', 'قطر', 25.29, 51.53),
  MajorCity('الكويت', 'Kuwait City', 'الكويت', 29.38, 47.99),
  MajorCity('مسقط', 'Muscat', 'عُمان', 23.59, 58.41),
  MajorCity('صنعاء', "Sana'a", 'اليمن', 15.37, 44.19),
  // Levant, Egypt, Sudan, Maghreb, Turkey
  MajorCity('عمّان', 'Amman', 'الأردن', 31.95, 35.93),
  MajorCity('القاهرة', 'Cairo', 'مصر', 30.04, 31.24),
  MajorCity('الخرطوم', 'Khartoum', 'السودان', 15.50, 32.56),
  MajorCity('الدار البيضاء', 'Casablanca', 'المغرب', 33.57, -7.59),
  MajorCity('الجزائر', 'Algiers', 'الجزائر', 36.75, 3.06),
  MajorCity('تونس', 'Tunis', 'تونس', 36.81, 10.18),
  MajorCity('إسطنبول', 'Istanbul', 'تركيا', 41.01, 28.98),
  // East & West Africa
  MajorCity('مقديشو', 'Mogadishu', 'الصومال', 2.05, 45.32),
  MajorCity('جيبوتي', 'Djibouti', 'جيبوتي', 11.59, 43.15),
  MajorCity('نيروبي', 'Nairobi', 'كينيا', -1.29, 36.82),
  MajorCity('دار السلام', 'Dar es Salaam', 'تنزانيا', -6.79, 39.21),
  MajorCity('كانو', 'Kano', 'نيجيريا', 12.00, 8.52),
  MajorCity('لاغوس', 'Lagos', 'نيجيريا', 6.52, 3.38),
  // South & Southeast Asia
  MajorCity('كراتشي', 'Karachi', 'باكستان', 24.86, 67.01),
  MajorCity('لاهور', 'Lahore', 'باكستان', 31.55, 74.34),
  MajorCity('دكا', 'Dhaka', 'بنغلاديش', 23.81, 90.41),
  MajorCity('جاكرتا', 'Jakarta', 'إندونيسيا', -6.21, 106.85),
  MajorCity('كوالالمبور', 'Kuala Lumpur', 'ماليزيا', 3.14, 101.69),
  // Europe & America
  MajorCity('لندن', 'London', 'بريطانيا', 51.51, -0.13),
  MajorCity('باريس', 'Paris', 'فرنسا', 48.86, 2.35),
  MajorCity('برلين', 'Berlin', 'ألمانيا', 52.52, 13.40),
  MajorCity('نيويورك', 'New York', 'أمريكا', 40.71, -74.01),
  MajorCity('تورونتو', 'Toronto', 'كندا', 43.65, -79.38),
];
