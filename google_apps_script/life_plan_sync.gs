/**
 * سكربت مزامنة "خطة الحياة الشاملة" — Ismail, 2026-08-25.
 *
 * ماذا يفعل هذا السكربت الآن (بدون أي حاجة لتطبيق طالب العلم بعد):
 *   1) كلما غيّرت أي خانة ☐/✓ (checkbox) في شيت "الجدول اليومي"، يعيد
 *      حساب نسبة الإنجاز الفعلية تلقائيًا ويكتبها في شيت "تتبع الإنجاز".
 *   2) يجهّز نقطتي اتصال (doGet / doPost) لاستخدامها لاحقًا من تطبيق
 *      طالب العلم مباشرة — القراءة الآن، الكتابة لاحقًا — دون أي تعديل
 *      إضافي على هذا الملف عند الوصول لتلك المرحلة (Phase 77.11 في TODO.md).
 *
 * التركيب (خطوات لمرة واحدة):
 *   1) افتح شيتك: Extensions -> Apps Script.
 *   2) احذف أي كود موجود في Code.gs والصق هذا الملف كاملاً بدلاً منه.
 *   3) عدّل CONFIG أسفل حسب أسماء الشيتات الحقيقية عندك (تحقق من التبويبات
 *      بالضبط — الأسماء حساسة لحالة الأحرف والمسافات).
 *   4) من أعلى يسار محرر Apps Script: Deploy -> New deployment -> Web app.
 *      Execute as: Me. Who has access: Anyone with the link.
 *   5) انسخ الرابط الذي يعطيك إياه (Web app URL) — هذا هو الرابط الذي
 *      سيستخدمه التطبيق لاحقًا في Phase 77.11.
 *   6) لتفعيل الحساب التلقائي عند كل تعديل: Triggers (⏰ من القائمة
 *      الجانبية) -> Add Trigger -> اختر onEditInstalled -> Event type:
 *      On edit -> Save.
 *
 * لا يحتاج هذا الملف أي توكن أو سيرفر خارجي حتى الآن — كله يعمل داخل
 * حساب Google الخاص بك فقط.
 */

// ============================================================
// CONFIG — عدّل هذا القسم فقط ليطابق شيتك الحقيقي بالضبط
// ============================================================
const CONFIG = {
  // اسم تبويب الجدول اليومي كما هو مكتوب بالضبط في أسفل الشيت
  DAILY_SCHEDULE_SHEET: 'الجدول اليومي',

  // اسم تبويب تتبع الإنجاز
  TRACKING_SHEET: 'تتبع الإنجاز',

  // الصف الذي تبدأ منه بيانات الجدول اليومي (بعد صف العناوين)
  DAILY_SCHEDULE_FIRST_DATA_ROW: 4,

  // أعمدة أيام الأسبوع في الجدول اليومي (D..J = الأحد..السبت، عدّل
  // حسب ترتيبك الفعلي إن اختلف)
  DAY_COLUMNS: { 'الأحد': 4, 'الاثنين': 5, 'الثلاثاء': 6, 'الأربعاء': 7, 'الخميس': 8, 'الجمعة': 9, 'السبت': 10 },

  // رمز سري بسيط — سيُستخدم لاحقًا عندما يتصل التطبيق بهذا السكربت
  // (Phase 77.11c) حتى لا يستطيع أي شخص آخر الكتابة في شيتك. غيّره
  // إلى أي نص تريده أنت فقط تعرفه.
  SHARED_SECRET: 'CHANGE_ME_TO_YOUR_OWN_SECRET',
};

// ============================================================
// 1) إعادة حساب نسبة الإنجاز اليومي تلقائيًا
// ============================================================

/** يُستدعى تلقائيًا من الـ Trigger عند أي تعديل في الشيت كله. */
function onEditInstalled(e) {
  try {
    const editedSheet = e.range.getSheet().getName();
    if (editedSheet !== CONFIG.DAILY_SCHEDULE_SHEET) return; // نهتم فقط بتعديلات الجدول اليومي
    recomputeTodayCompletion_();
  } catch (err) {
    Logger.log('onEditInstalled error: ' + err);
  }
}

/** يحسب نسبة الخانات المُنجزة (✓/TRUE) لليوم الحالي فقط، ويكتبها في شيت تتبع الإنجاز. */
function recomputeTodayCompletion_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const trackingSheet = ss.getSheetByName(CONFIG.TRACKING_SHEET);
  if (!scheduleSheet || !trackingSheet) {
    Logger.log('تحقق من أسماء الشيتات في CONFIG — لم يُعثر على أحدهما.');
    return;
  }

  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];
  if (!dayCol) return;

  const lastRow = scheduleSheet.getLastRow();
  const numRows = lastRow - CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW + 1;
  if (numRows <= 0) return;

  const range = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW, dayCol, numRows, 1);
  const values = range.getValues(); // [[true], [false], ...] لخانات checkbox

  let total = 0;
  let done = 0;
  values.forEach(function (row) {
    const v = row[0];
    if (v === true || v === false) { // خانة checkbox فعلية فقط، تجاهل الفارغة/النصية
      total++;
      if (v === true) done++;
    }
  });

  const percent = total > 0 ? Math.round((done / total) * 100) : 0;
  writeTodayPercent_(trackingSheet, percent, done, total);
}

/** يكتب/يحدّث صف اليوم في شيت تتبع الإنجاز (ينشئ صفًا جديدًا إن لم يوجد صف لتاريخ اليوم). */
function writeTodayPercent_(trackingSheet, percent, done, total) {
  const todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd');
  const data = trackingSheet.getDataRange().getValues();
  let targetRow = -1;
  for (let i = 1; i < data.length; i++) { // تخطَّ صف العناوين
    const cell = data[i][0];
    const cellStr = cell instanceof Date ? Utilities.formatDate(cell, Session.getScriptTimeZone(), 'yyyy-MM-dd') : String(cell);
    if (cellStr === todayStr) { targetRow = i + 1; break; }
  }
  if (targetRow === -1) {
    targetRow = trackingSheet.getLastRow() + 1;
    trackingSheet.getRange(targetRow, 1).setValue(new Date());
  }
  trackingSheet.getRange(targetRow, 2).setValue(done + ' / ' + total);
  trackingSheet.getRange(targetRow, 3).setValue(percent + '%');
}

function arabicDayName_(date) {
  const names = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  return names[date.getDay()];
}

// ============================================================
// 2) نقاط اتصال جاهزة لتطبيق طالب العلم (تُستخدم في Phase 77.11،
//    لا تحتاج أي تفعيل إضافي الآن — تعمل تلقائيًا بمجرد نشر Web App)
// ============================================================

/** GET: يعيد بيانات جدول اليوم كـ JSON — للقراءة من التطبيق لاحقًا. */
function doGet(e) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];
  const lastRow = scheduleSheet.getLastRow();
  const numRows = lastRow - CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW + 1;

  const titles = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW, 2, numRows, 1).getValues();
  const checks = scheduleSheet.getRange(CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW, dayCol, numRows, 1).getValues();

  const slots = [];
  for (let i = 0; i < numRows; i++) {
    slots.push({ row: CONFIG.DAILY_SCHEDULE_FIRST_DATA_ROW + i, title: titles[i][0], completed: checks[i][0] === true });
  }

  return ContentService.createTextOutput(JSON.stringify({ day: todayName, slots: slots })).setMimeType(ContentService.MimeType.JSON);
}

/** POST: يستقبل {secret, row, completed} من التطبيق ويحدّث الخانة المطابقة في الجدول اليومي. */
function doPost(e) {
  const body = JSON.parse(e.postData.contents);
  if (body.secret !== CONFIG.SHARED_SECRET) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: 'unauthorized' })).setMimeType(ContentService.MimeType.JSON);
  }

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName(CONFIG.DAILY_SCHEDULE_SHEET);
  const todayName = arabicDayName_(new Date());
  const dayCol = CONFIG.DAY_COLUMNS[todayName];

  scheduleSheet.getRange(body.row, dayCol).setValue(body.completed === true);
  recomputeTodayCompletion_();

  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON);
}
