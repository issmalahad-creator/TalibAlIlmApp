/**
 * طالب العلم — Telegram Content Relay (fresh script, own bot/sheet, no
 * relation to any other project). Serves the JSON contract already defined
 * in lib/models/book_content.dart (BookContentFeed) so the existing, never-
 * deployed BookContentService/ContentBadgeService/book_screen.dart in the
 * Flutter app can start working immediately once this is deployed and its
 * /exec URL is pasted into lib/config/app_config.dart's bookContentApiUrl.
 *
 * How it works:
 *  - Ismail sends messages to @talib_alilm_adhkar_bot in a PRIVATE chat
 *    (not the channel — private chats are the reliable path, confirmed by
 *    direct testing 2026-08-17).
 *  - A time-driven trigger (pollTelegram) runs every few minutes, reads new
 *    messages from the admin only, and logs them into this Sheet.
 *  - doGet() compiles the Sheet into the JSON feed the app expects.
 *
 * Admin message formats (send as text, or as a caption on an attached
 * document/photo):
 *   كتاب: <title>       + PDF attached  -> adds to books[] (never overwritten)
 *   بانر: <caption>      + photo attached -> replaces the current banner
 *   ملف: <title>         + any attached  -> adds to items[]
 *   سؤال: <q> جواب: <a>  (text only)     -> adds to faq[]
 *   <anything else>      (text only)     -> replaces the current announcement
 *
 * SETUP (see DEPLOY.md next to this file):
 *   1. Create a new Google Sheet, open Extensions > Apps Script, paste this file in as Code.gs.
 *   2. Project Settings > Script Properties: add BOT_TOKEN and ADMIN_ID.
 *   3. Run `setup` once (top toolbar, select function, Run).
 *   4. Triggers (clock icon) > Add Trigger > pollTelegram > Time-driven > every 5-10 minutes.
 *   5. Deploy > New deployment > Web app > Execute as "Me" > Who has access "Anyone".
 *   6. Copy the /exec URL into app_config.dart's bookContentApiUrl.
 */

const SHEET_NAME = 'content';
const PROP = PropertiesService.getScriptProperties();

function botToken_() {
  return PROP.getProperty('BOT_TOKEN');
}

function adminId_() {
  return PROP.getProperty('ADMIN_ID');
}

function sheet_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sh = ss.getSheetByName(SHEET_NAME);
  if (!sh) {
    sh = ss.insertSheet(SHEET_NAME);
    sh.appendRow(['id', 'type', 'title_or_caption', 'body_or_answer', 'file_id', 'date']);
  }
  return sh;
}

/** Run once manually after setting Script Properties. */
function setup() {
  sheet_();
  PROP.setProperty('UPDATE_OFFSET', '0');
}

/** Time-driven trigger target. Polls Telegram for new admin messages only. */
function pollTelegram() {
  const token = botToken_();
  const admin = adminId_();
  if (!token || !admin) throw new Error('Set BOT_TOKEN and ADMIN_ID in Script Properties first.');

  const offset = Number(PROP.getProperty('UPDATE_OFFSET') || '0');
  const resp = UrlFetchApp.fetch(
    'https://api.telegram.org/bot' + token + '/getUpdates?offset=' + offset + '&timeout=0'
  );
  const data = JSON.parse(resp.getContentText());
  if (!data.ok) return;

  let maxUpdateId = offset - 1;
  data.result.forEach(function (update) {
    maxUpdateId = Math.max(maxUpdateId, update.update_id);
    const msg = update.message;
    if (!msg || !msg.from || String(msg.from.id) !== String(admin)) return; // ignore anyone but the admin
    handleAdminMessage_(msg);
  });

  if (maxUpdateId >= offset) {
    PROP.setProperty('UPDATE_OFFSET', String(maxUpdateId + 1));
  }
}

function handleAdminMessage_(msg) {
  const sh = sheet_();
  const id = msg.date + '_' + msg.message_id;
  const date = new Date(msg.date * 1000).toISOString();
  const caption = (msg.caption || msg.text || '').trim();
  const fileId = msg.document ? msg.document.file_id : msg.photo ? msg.photo[msg.photo.length - 1].file_id : null;

  if (caption.indexOf('كتاب:') === 0 && fileId) {
    sh.appendRow([id, 'book', caption.replace('كتاب:', '').trim(), '', fileId, date]);
  } else if (caption.indexOf('بانر:') === 0 && fileId) {
    sh.appendRow([id, 'banner', caption.replace('بانر:', '').trim(), '', fileId, date]);
  } else if (caption.indexOf('ملف:') === 0 && fileId) {
    sh.appendRow([id, 'item', caption.replace('ملف:', '').trim(), '', fileId, date]);
  } else if (caption.indexOf('سؤال:') === 0) {
    const afterQ = caption.slice('سؤال:'.length);
    const jIdx = afterQ.indexOf('جواب:');
    const question = (jIdx === -1 ? afterQ : afterQ.slice(0, jIdx)).trim();
    const answer = jIdx === -1 ? '' : afterQ.slice(jIdx + 'جواب:'.length).trim();
    sh.appendRow([id, 'faq', question, answer, '', date]);
  } else if (caption) {
    sh.appendRow([id, 'announcement', caption, '', '', date]);
  }
}

function resolveFileUrl_(fileId, token) {
  if (!fileId) return '';
  const resp = UrlFetchApp.fetch('https://api.telegram.org/bot' + token + '/getFile?file_id=' + fileId);
  const filePath = JSON.parse(resp.getContentText()).result.file_path;
  return 'https://api.telegram.org/file/bot' + token + '/' + filePath;
}

/** Public read endpoint. Returns the JSON feed BookContentFeed.fromJson expects. */
function doGet(e) {
  const token = botToken_();
  const rows = sheet_().getDataRange().getValues();
  rows.shift(); // header row

  const books = [];
  const items = [];
  const history = [];
  const faq = [];
  let announcement = '';
  let banner = null;

  rows.forEach(function (row) {
    const rowId = row[0];
    const type = row[1];
    const titleOrCaption = row[2];
    const bodyOrAnswer = row[3];
    const fileId = row[4];
    const date = row[5];

    if (type === 'book') {
      books.unshift({ id: String(rowId), title: titleOrCaption, url: resolveFileUrl_(fileId, token), date: date, quiz: [] });
    } else if (type === 'item') {
      items.unshift({ type: 'document', title: titleOrCaption, url: resolveFileUrl_(fileId, token), date: date });
    } else if (type === 'banner') {
      const url = resolveFileUrl_(fileId, token);
      banner = { caption: titleOrCaption, url: url, date: date };
      history.unshift({ type: 'banner', text: titleOrCaption, url: url, date: date });
    } else if (type === 'announcement') {
      announcement = titleOrCaption;
      history.unshift({ type: 'announcement', text: titleOrCaption, url: '', date: date });
    } else if (type === 'faq') {
      faq.unshift({ question: titleOrCaption, answer: bodyOrAnswer, date: date });
    }
  });

  const feed = { announcement: announcement, banner: banner, books: books, items: items, history: history, faq: faq };
  return ContentService.createTextOutput(JSON.stringify(feed)).setMimeType(ContentService.MimeType.JSON);
}
