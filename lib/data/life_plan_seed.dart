import '../models/life_plan.dart';

/// The seed of «مُحرّك الحياة» — read verbatim from Ismail's real Google
/// Sheet «🚀 خطة الحياة الشاملة» (tabs `🎯 الأهداف` + `📅 الجدول اليومي`),
/// 2026‑09‑04, via the `gviz` CSV endpoint. Editable in‑app afterwards;
/// this is only the first fill of `life_pillars` / `life_slots`.

const List<LifePillar> kLifePillars = [
  LifePillar(
      key: 'quran',
      label: '📖 القرآن الكريم',
      emoji: '📖',
      targetText: 'يومي',
      cadence: LifeCadence.daily,
      sort: 0),
  LifePillar(
      key: 'books',
      label: '📚 الكتب الـ5',
      emoji: '📚',
      targetText: 'مقطع/يوم',
      cadence: LifeCadence.daily,
      sort: 1),
  LifePillar(
      key: 'social',
      label: '🎬 السوشل ميديا',
      emoji: '🎬',
      targetText: '3–4 فيديو/أسبوع',
      cadence: LifeCadence.weekly,
      weeklyTarget: 4,
      sort: 2),
  LifePillar(
      key: 'coding',
      label: '💻 Python وبرمجة',
      emoji: '💻',
      targetText: 'ساعة/يوم',
      cadence: LifeCadence.daily,
      sort: 3),
  LifePillar(
      key: 'erp',
      label: '🏪 ERP العملاء',
      emoji: '🏪',
      targetText: '7 عملاء نشط',
      cadence: LifeCadence.weekly,
      weeklyTarget: 7,
      sort: 4),
  LifePillar(
      key: 'micro',
      label: '🌐 Microworkers',
      emoji: '🌐',
      targetText: '5 مهام/أسبوع',
      cadence: LifeCadence.weekly,
      weeklyTarget: 5,
      sort: 5),
  LifePillar(
      key: 'jobs',
      label: '💼 البحث عن عمل',
      emoji: '💼',
      targetText: '3 طلبات/أسبوع',
      cadence: LifeCadence.weekly,
      weeklyTarget: 3,
      sort: 6),
];

/// 23 time‑blocks. `pillarKey` links a block to one of the 7 tracked
/// pillars; blocks with `null` (روحي / صحة / حياة / تنظيم / نوم) count
/// toward the whole‑day percentage but not a pillar's.
const List<LifeSlot> kLifeSlots = [
  LifeSlot(slotNo: 1, startMin: 300, endMin: 330, activity: '🕌 فجر + دعاء + نية اليوم', mihwar: 'روحي', sort: 0),
  LifeSlot(slotNo: 2, startMin: 330, endMin: 390, activity: '📖 حفظ القرآن (ربع حزب)', mihwar: 'قرآن', pillarKey: 'quran', sort: 1),
  LifeSlot(slotNo: 3, startMin: 390, endMin: 420, activity: '🏃 رياضة خفيفة', mihwar: 'صحة', sort: 2),
  LifeSlot(slotNo: 4, startMin: 420, endMin: 450, activity: '🍳 فطور + راحة', mihwar: 'حياة', sort: 3),
  LifeSlot(slotNo: 5, startMin: 450, endMin: 510, activity: '📚 مقطع صوتي (كتاب)', mihwar: 'تعلم', pillarKey: 'books', sort: 4),
  LifeSlot(slotNo: 6, startMin: 510, endMin: 570, activity: '💻 Python / برمجة', mihwar: 'تطوير', pillarKey: 'coding', sort: 5),
  LifeSlot(slotNo: 7, startMin: 570, endMin: 630, activity: '🏪 ERP + متابعة عملاء', mihwar: 'عمل', pillarKey: 'erp', sort: 6),
  LifeSlot(slotNo: 8, startMin: 630, endMin: 660, activity: '☕ استراحة + مراجعة بريد', mihwar: 'تنظيم', sort: 7),
  LifeSlot(slotNo: 9, startMin: 660, endMin: 720, activity: '🎬 إنتاج محتوى (تصوير/مونتاج)', mihwar: 'محتوى', pillarKey: 'social', sort: 8),
  LifeSlot(slotNo: 10, startMin: 720, endMin: 750, activity: '🕌 ظهر + قيلولة 10 دق', mihwar: 'روحي', sort: 9),
  LifeSlot(slotNo: 11, startMin: 750, endMin: 810, activity: '🌐 Microworkers (مهام)', mihwar: 'دخل', pillarKey: 'micro', sort: 10),
  LifeSlot(slotNo: 12, startMin: 810, endMin: 870, activity: '📖 تفسير القرآن (ما حفظه)', mihwar: 'قرآن', pillarKey: 'quran', sort: 11),
  LifeSlot(slotNo: 13, startMin: 870, endMin: 900, activity: '💼 طلبات وظائف + LinkedIn', mihwar: 'توظيف', pillarKey: 'jobs', sort: 12),
  LifeSlot(slotNo: 14, startMin: 900, endMin: 930, activity: '🕌 عصر + مراجعة يومية', mihwar: 'روحي', sort: 13),
  LifeSlot(slotNo: 15, startMin: 930, endMin: 990, activity: '📚 مقطع صوتي (كتاب ثاني)', mihwar: 'تعلم', pillarKey: 'books', sort: 14),
  LifeSlot(slotNo: 16, startMin: 990, endMin: 1050, activity: '💻 مشروع ERP (تطوير)', mihwar: 'تطوير', pillarKey: 'erp', sort: 15),
  LifeSlot(slotNo: 17, startMin: 1050, endMin: 1080, activity: '🕌 مغرب + ذكر', mihwar: 'روحي', sort: 16),
  LifeSlot(slotNo: 18, startMin: 1080, endMin: 1140, activity: '🎬 كتابة سكريبت / تحرير فيديو', mihwar: 'محتوى', pillarKey: 'social', sort: 17),
  LifeSlot(slotNo: 19, startMin: 1140, endMin: 1170, activity: '🍽️ عشاء + راحة', mihwar: 'حياة', sort: 18),
  LifeSlot(slotNo: 20, startMin: 1170, endMin: 1230, activity: '📖 مراجعة ما حفظ + اختبار', mihwar: 'قرآن', pillarKey: 'quran', sort: 19),
  LifeSlot(slotNo: 21, startMin: 1230, endMin: 1260, activity: '🕌 عشاء + ورد مسائي', mihwar: 'روحي', sort: 20),
  LifeSlot(slotNo: 22, startMin: 1260, endMin: 1290, activity: '📝 تدوين الإنجازات اليومية', mihwar: 'تنظيم', sort: 21),
  LifeSlot(slotNo: 23, startMin: 1290, endMin: 1320, activity: '😴 تحضير اليوم التالي + نوم', mihwar: 'نوم', sort: 22),
];
