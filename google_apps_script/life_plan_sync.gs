/**
 * سكربت مزامنة "خطة الحياة الشاملة" — Ismail، 2026-08-25.
 *
 * هذا الإصدار مبني على فحص حقيقي لشيتك (وليس تخمينًا): جلبت المحتوى
 * الفعلي لتبويبي "📅 الجدول اليومي" و"📊 تتبع الإنجاز" خلية بخلية عبر
 * رابط تصدير Google الرسمي، وتأكدت من:
 *   - عدد صفوف الجدول اليومي الحقيقي: 23 صفًا (من 05:00 إلى 22:00)، تبدأ
 *     من الصف 3 (وليس 4 كما في النسخة الأولى من هذا الملف — كان تخمينًا
 *     خاطئًا، صُحِّح الآن بعد الفحص الفعلي).
 *   - أعمدة الأيام: D=الأحد, E=الاثنين, F=الثلاثاء, G=الأربعاء, H=الخميس,
 *     I=الجمعة, J=السبت — هذا الجزء كان تخمينًا صحيحًا بالصدفة.
 *   - خانات التحديد ليست checkbox حقيقية في الأصل — كانت رمز نصي "☐"
 *     فقط. لو تُرك السكربت القديم كما هو (يبحث عن true/false) لَما عمل
 *     أبدًا. تم حل هذا: setupRealCheckboxes() يحوّلها لمرة واحدة إلى
 *     checkbox حقيقي (قابل للمس)، مع الحفاظ على "☐" للفارغ و"✅" للمنجز
 *     — نفس الرمزين المستخدمين في شيتك أصلاً.
 *   - "تتبع الإنجاز" مبني مسبقًا لـ90 يومًا حقيقيًا ("اليوم 1" .. "اليوم
 *     90")، مع صف "📊 ملخص الأسبوع" بدل يوم الجمعة كل أسبوع (لذلك رقم
 *     الصف لا يُحسب حسابيًا — يُبحث عنه بالنص كل مرة، وهذا مقصود وصحيح).
 *   - الأعمدة الثمانية في تتبع الإنجاز (قرآن، كتاب 1، كتاب 2، Python،
 *     ERP عميل، Microworkers، محتوى، توظيف) لا تُطابق صفوف الجدول
 *     اليومي بشكل تلقائي — طابقتها يدويًا بالمحتوى الفعلي لكل صف (انظر
 *     PILLAR_ROW_MAP أسفل، مع توضيح أي صف يمثل أي عمود ولماذا).
 *
 * ماذا يفعل السكربت الآن:
 *   1) عند تحديد أي خانة في "الجدول اليومي"، يحسب فورًا: نسبة إنجاز اليوم
 *      الكلية (من كل الـ23 خانة)، ونسبة إنجاز كل محور من المحاور الثمانية
 *      المتتبَّعة، ويكتب كل ذلك في صف "اليوم N" الصحيح داخل "تتبع الإنجاز"
 *      (يحسب N تلقائيًا من تاريخ البداية الذي تحدده أنت في CONFIG).
 *   2) يجهّز doGet/doPost لاستخدام تطبيق طالب العلم لاحقًا (Phase 77.11) —
 *      لا حاجة لأي تعديل إضافي هنا عند الوصول لتلك المرحلة.
 *
 * التركيب (مرة واحدة فقط):
 *   1) افتح شيتك: Extensions -> Apps Script.
 *   2) احذف أي كود موجود في Code.gs، الصق هذا الملف كاملاً بدلاً منه.
 *   3) في CONFIG أسفل: عدّل START_DATE ليكون تاريخ "اليوم 1" الحقيقي عندك
 *      (اليوم الذي تبدأ فيه التحدي فعليًا — لا تتركه فارغًا).
 *   4) من محرر Apps Script: اختر الدالة setupRealCheckboxes من القائمة
 *      المنسدلة أعلى الصفحة، ثم اضغط Run (▶). هذا يحوّل كل خانات "☐" في
 *      الشيتين إلى checkbox حقيقي — تعمل مرة واحدة فقط، لا تكررها.
 *   5) Deploy -> New deployment -> Web app. Execute as: Me. Who has
 *      access: Anyone with the link. انسخ الرابط — يُستخدم لاحقًا فقط.
 *   6) Triggers (⏰) -> Add Trigger -> onEditInstalled -> On edit -> Save.
 *
 * كل هذا يعمل داخل حساب Google الخاص بك فقط، بلا سيرفر وبلا توكن خارجي.
 */

// ============================================================
// CONFIG — راجع فقط START_DATE و SHARED_SECRET، الباقي مطابق للشيت الحقيقي فعليًا
// ============================================================
const CONFIG = {
  DAILY_SCHEDULE_SHEET: '📅 الجدول اليومي',
  TRACKING_SHEET: '📊 تتبع الإنجاز',

  // مطابقة فعلية لشيتك — لا تغيّرها إلا إذا عدّلت بنية الجدول اليومي بنفسك
  DAILY_SCHEDULE_FIRST_ROW: 3,
  DAILY_SCHEDULE_LAST_ROW: 25,
  DAY_COLUMNS: { 'الأحد': 4, 'الاثنين': 5, 'الثلاثاء': 6, 'الأربعاء': 7, 'الخميس': 8, 'الجمعة': 9, 'السبت': 10 },

  // ⚠️ عدّل هذا التاريخ فقط — اليوم الذي يمثّل "اليوم 1" في شيت تتبع
  // الإنجاز. الصيغة: سنة-شهر-يوم. لم أفترض تاريخًا لأن هذا قرارك أنت.
  START_DATE: '2026-08-26',

  // أعمدة تتبع الإنجاز الثمانية بالترتيب الفعلي في شيتك (B..I)
  TRACKING_PILLAR_COLUMNS: ['قرآن', 'كتاب 1', 'كتاب 2', 'Python', 'ERP عميل', 'Microworkers', 'محتوى', 'توظيف'],

  CHECKED: '✅',
  UNCHECKED: '☐',

  SHARED_SECRET: 'CHANGE_ME_TO_YOUR_OWN_SECRET',
};

/**
 * أي صفوف من "الجدول اليومي" (رقم الصف الفعلي) تُحتسب لكل عمود من
 * الأعمدة الثمانية في "تتبع الإنجاز" — مبني على المحتوى الحقيقي لكل صف:
 *   4  = 05:30–06:30 حفظ القرآن          14 = 13:30–14:30 تفسير القرآن
 *   22 = 19:30–20:30 مراجعة ما حُفظ+اختبار   -> الثلاثة لعمود "قرآن"
 *   7  = 07:30–08:30 مقطع صوتي (كتاب)         -> عمود "كتاب 1"
 *   17 = 15:30–16:30 مقطع صوتي (كتاب ثاني)    -> عمود "كتاب 2"
 *   8  = 08:30–09:30 Python / برمجة           -> عمود "Python"
 *   9  = 09:30–10:30 ERP + متابعة عملاء
 *   18 = 16:30–17:30 مشروع ERP (تطوير)        -> عمود "ERP عميل"
 *   13 = 12:30–13:30 Microworkers (مهام)      -> عمود "Microworkers"
 *   11 = 11:00–12:00 إنتاج محتوى
 *   20 = 18:00–19:00 كتابة سكريبت/تحرير فيديو -> عمود "محتوى"
 *   15 = 14:30–15:00 طلبات وظائف + LinkedIn    -> عمود "توظيف"
 * ملاحظة: باقي الصفوف (فجر/رياضة/فطور/راحة/ظهر/عصر/مغرب/عشاء/تنظيم/نوم)
 * تدخل في نسبة اليوم الكلية لكنها ليست جزءًا من الأعمدة الثمانية —
 * هذا اختياري وليس خطأ، عدّله إن أردت محورًا لها لاحقًا.
 */
const PILLAR_ROW_MAP = {
  'قرآن': [4, 14, 22],
  'كتاب 1': [7],
  'كتاب 2': [17],
  'Python': [8],
  'ERP عميل': [9, 18],
  'Microworkers': [13],
  'محتوى': [11, 20],
  'توظيف': [15],
};

// ============================================================
// 0) إعداد لمرة واحدة — شغّلها يدويًا من محرر Apps Script قبل أي شيء آخر
// ============================================================

/** يحوّل كل خانات "☐" النصية في الشيتين إلى checkbox حقيقي قابل للمس. */
function setupRealCheckboxes() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const trackingSheet = ss.getSheetByName(CONFIG.TRACKING_SHEET);
  if (!scheduleSheet || !trackingSheet) {
    throw new Error('تحقق من CONFIG.DAILY_SCHEDULE_SHEET و CONFIG.TRACKING_SHEET — لم يُعثر على أحد التبويبين بهذا الاسم بالضبط.');
  }

  const numDailyRows = CONFIG.DAILY_SCHEDULE_LAST_ROW - CONFIG.DAILY_SCHEDULE_FIRST_ROW + 1;
  scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_ROW, 4, numDailyRows, 7) // D..J
    .insertCheckboxes(CONFIG.CHECKED, CONFIG.UNCHECKED);

  const lastTrackingRow = trackingSheet.getLastRow();
  if (lastTrackingRow >= 2) {
    trackingSheet.getRange(2, 2, lastTrackingRow - 1, CONFIG.TRACKING_PILLAR_COLUMNS.length) // B..I
      .insertCheckboxes(CONFIG.CHECKED, CONFIG.UNCHECKED);
  }

  SpreadsheetApp.getUi().alert('تم تحويل كل الخانات إلى checkbox حقيقي. لا تُشغّل هذه الدالة مرة أخرى.');
}

// ============================================================
// 1) إعادة حساب الإنجاز تلقائيًا عند كل تعديل
// ============================================================

function onEditInstalled(e) {
  try {
    if (e.range.getSheet().getName() !== CONFIG.DAILY_SCHEDULE_SHEET) return;
    recomputeTodayCompletion_();
  } catch (err) {
    Logger.log('onEditInstalled error: ' + err);
  }
}

function recomputeTodayCompletion_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const trackingSheet = ss.getSheetByName(CONFIG.TRACKING_SHEET);
  if (!scheduleSheet || !trackingSheet) return;

  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];
  if (!dayCol) return;

  const numRows = CONFIG.DAILY_SCHEDULE_LAST_ROW - CONFIG.DAILY_SCHEDULE_FIRST_ROW + 1;
  const colValues = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_ROW, dayCol, numRows, 1).getValues();

  // خريطة: رقم الصف الفعلي -> هل مُنجز اليوم (بالمقارنة بالرمز الحقيقي ✅)
  const doneByRow = {};
  for (let i = 0; i < numRows; i++) {
    doneByRow[CONFIG.DAILY_SCHEDULE_FIRST_ROW + i] = colValues[i][0] === CONFIG.CHECKED;
  }

  const totalSlots = numRows;
  const doneSlots = Object.values(doneByRow).filter(Boolean).length;
  const overallPercent = totalSlots > 0 ? Math.round((doneSlots / totalSlots) * 100) : 0;

  const pillarStatus = {};
  CONFIG.TRACKING_PILLAR_COLUMNS.forEach(function (pillar) {
    const rows = PILLAR_ROW_MAP[pillar] || [];
    pillarStatus[pillar] = rows.length > 0 && rows.every(function (r) { return doneByRow[r] === true; });
  });

  writeTodayRow_(trackingSheet, overallPercent, doneSlots, totalSlots, pillarStatus);
}

/** يجد صف "اليوم N" الصحيح (N محسوب من CONFIG.START_DATE) ويكتب فيه النتائج. */
function writeTodayRow_(trackingSheet, percent, done, total, pillarStatus) {
  const dayNumber = computeDayNumber_();
  if (dayNumber < 1 || dayNumber > 90) return; // خارج نطاق الـ90 يومًا، لا شيء لفعله

  const label = 'اليوم ' + dayNumber;
  const data = trackingSheet.getDataRange().getValues();
  let targetRow = -1;
  for (let i = 1; i < data.length; i++) { // تخطَّ صف العناوين
    if (String(data[i][0]).trim() === label) { targetRow = i + 1; break; }
  }
  if (targetRow === -1) {
    Logger.log('لم يُعثر على صف "' + label + '" في تتبع الإنجاز — تحقق من CONFIG.START_DATE.');
    return;
  }

  CONFIG.TRACKING_PILLAR_COLUMNS.forEach(function (pillar, idx) {
    const col = 2 + idx; // B=2 هو أول عمود محور
    trackingSheet.getRange(targetRow, col).setValue(pillarStatus[pillar] ? CONFIG.CHECKED : CONFIG.UNCHECKED);
  });

  const statusText = percent >= 90 ? '🏆 ممتاز' : percent >= 70 ? '✅ جيد' : percent >= 40 ? '⚠️ متوسط' : '❌ ضعيف';
  trackingSheet.getRange(targetRow, 10).setValue(percent + '%'); // J = نسبة الإنجاز
  trackingSheet.getRange(targetRow, 11).setValue(statusText);   // K = الحالة
}

function computeDayNumber_() {
  const start = new Date(CONFIG.START_DATE + 'T00:00:00');
  const today = new Date();
  const startMidnight = new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const todayMidnight = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const diffDays = Math.round((todayMidnight - startMidnight) / (1000 * 60 * 60 * 24));
  return diffDays + 1; // اليوم الأول = اليوم 1
}

function arabicDayName_(date) {
  const names = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  return names[date.getDay()];
}

// ============================================================
// 2) نقاط اتصال لتطبيق طالب العلم لاحقًا (Phase 77.11) — لا تفعيل إضافي مطلوب الآن
// ============================================================

function doGet(e) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];
  const numRows = CONFIG.DAILY_SCHEDULE_LAST_ROW - CONFIG.DAILY_SCHEDULE_FIRST_ROW + 1;

  const titles = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_ROW, 2, numRows, 1).getValues();
  const times = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_ROW, 1, numRows, 1).getValues();
  const checks = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_ROW, dayCol, numRows, 1).getValues();

  const slots = [];
  for (let i = 0; i < numRows; i++) {
    slots.push({
      row: CONFIG.DAILY_SCHEDULE_FIRST_ROW + i,
      time: times[i][0],
      title: titles[i][0],
      completed: checks[i][0] === CONFIG.CHECKED,
    });
  }

  return ContentService.createTextOutput(JSON.stringify({ day: todayName, dayNumber: computeDayNumber_(), slots: slots })).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  const body = JSON.parse(e.postData.contents);
  if (body.secret !== CONFIG.SHARED_SECRET) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: 'unauthorized' })).setMimeType(ContentService.MimeType.JSON);
  }

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];

  scheduleSheet.getRange(body.row, dayCol).setValue(body.completed === true ? CONFIG.CHECKED : CONFIG.UNCHECKED);
  recomputeTodayCompletion_();

  return ContentService.createTextOutput(JSON.stringify({ ok: true, dayNumber: computeDayNumber_() })).setMimeType(ContentService.MimeType.JSON);
}
