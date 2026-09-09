> ⚠️ **مطويّة.** أُعيد تعريف المشروع كـ«نظام تدريب» (2026-09-09). المرجع الحاكم الآن: `docs/akhlaq/README.md` + الوثائق الست. هذه الوثيقة للسياق فقط.

# منظومة الأخلاق والآداب — مخطّط البيانات (SQLite)

> يُترجم `AKHLAQ_KNOWLEDGE_MODEL` إلى جداول. يتبع نمط الترحيل القائم في
> `lib/db/database_helper.dart` (`if (oldVersion < N) await _createVNTables(db)`
> + استدعاء غير مشروط داخل `onCreate`). الإصدار الحالي للقاعدة **v60**؛
> منظومة الأخلاق تبدأ من **v61** فصاعدًا على دفعات (لا كل الجداول دفعة
> واحدة — كل مرحلة `AKHLAQ_ROADMAP` تأخذ رقمها).

القاعدة العامّة: **الأصول المبذورة** (`assets/akhlaq/*.json.gz`) صفّ واحد لكل
كيان كبير أو ملفّ لكل مجال، تُبذَر بـ`AkhlaqSync` (نمط `QuranCorpusSync`) عبر
علامة نسخة في `akhlaq_meta`. بيانات الطالب (`*_user`) لا تُبذَر أبدًا.

---

## 1. جداول المعرفة (مبذورة، للقراءة)

### v61 — العُقَد والخريطة

```sql
CREATE TABLE akhlaq_node (
  slug          TEXT PRIMARY KEY,          -- 'sidq', 'adab_istima', ...
  title_ar      TEXT NOT NULL,
  node_kind     TEXT NOT NULL,             -- domain|khuluq|adab|vice|daily|relation_ctx|prophetic
  domain        TEXT NOT NULL,             -- 'qalb'|'lisan'|'ghadab'|'taamul'|'talib_ilm'|'asnaf'|'yawmi'|'khilaf'|'dawah'|'tazkiyah'|'nabawi'
  content_class TEXT NOT NULL,             -- khuluq_shari|adab_thabit|adab_mustahabb|khuluq_amm|aadah_urf|ijtihad_khilaf
  summary_ar    TEXT NOT NULL,
  level_hint    INTEGER NOT NULL DEFAULT 0,
  sort          INTEGER NOT NULL DEFAULT 0,
  status        TEXT NOT NULL DEFAULT 'draft'  -- draft|reviewed|published
);

CREATE TABLE akhlaq_edge (
  from_slug   TEXT NOT NULL,
  edge_type   TEXT NOT NULL,               -- child_of|opposite_of|requires|strengthens|leads_to|prerequisite_for|related_to|evidence_shared
  to_slug     TEXT NOT NULL,
  note_ar     TEXT,
  source_ref  TEXT,                        -- إن كانت العلاقة نفسها منقولة
  PRIMARY KEY (from_slug, edge_type, to_slug)
);
CREATE INDEX idx_akhlaq_edge_to ON akhlaq_edge(to_slug);

CREATE TABLE akhlaq_xlink (                -- روابط خارج المنظومة
  from_slug   TEXT NOT NULL,
  target_kind TEXT NOT NULL,               -- ayah|hadith_item|turath|sira_event|lesson|life_pillar
  target_ref  TEXT NOT NULL,               -- '2:83' | 'evid:123' | 'book:137#p45' | ...
  note_ar     TEXT,
  PRIMARY KEY (from_slug, target_kind, target_ref)
);
```

### v62 — الأدلّة وسجلّ الطبعات

```sql
CREATE TABLE akhlaq_source_edition (
  edition_id   TEXT PRIMARY KEY,
  title        TEXT NOT NULL,
  author       TEXT,
  editor_tahqiq TEXT,
  publisher    TEXT,
  year         TEXT,
  notes        TEXT
);

CREATE TABLE akhlaq_evidence (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  node_slug      TEXT NOT NULL,
  evidence_type  TEXT NOT NULL,            -- quran|hadith_marfu|athar_sahabi|qawl_tabii|qawl_alim|qissa|hikmah_ghayr_thabita
  content_class  TEXT NOT NULL,
  text_ar        TEXT NOT NULL,
  explain_ar     TEXT,                     -- شرح ميسّر، منفصل عن النصّ
  source_kind    TEXT NOT NULL,            -- quran|hadith_book|athar_book|scholar_book|sira_book
  source_title   TEXT NOT NULL,
  source_edition TEXT,                     -- FK → akhlaq_source_edition.edition_id
  book_section   TEXT,
  locator        TEXT,                     -- رقم الحديث / مج+ص / سورة:آية
  narrator_top   TEXT,                     -- الصحابي (للمرفوع)
  grading        TEXT,                     -- sahih|hasan|daif|...|lam_yudras  (إلزامي للمرفوع)
  grading_authority TEXT,
  takhrij        TEXT,
  sharh_refs     TEXT,                     -- JSON array
  lessons        TEXT,                     -- JSON array of {text_ar, source?}
  status         TEXT NOT NULL DEFAULT 'draft',
  reviewed_by    TEXT,
  review_note    TEXT,
  added_at       INTEGER,
  updated_at     INTEGER
);
CREATE INDEX idx_akhlaq_evidence_node ON akhlaq_evidence(node_slug, status);
```

> **قيد بناء (في `build_akhlaq_corpus.py`، لا في SQLite):** يُرفض بناء
> الأصل إذا كان `evidence_type='hadith_marfu'` و`grading` فارغ أو
> `= 'lam_yudras'` مع `status='published'`؛ أو `content_class='aadah_urf'`
> و`evidence_type ∈ {quran,hadith_marfu}`؛ أو `status='published'` بلا
> `reviewed_by`.

### v63 — المنهج والمواقف والتمارين

```sql
CREATE TABLE akhlaq_level (
  level      INTEGER PRIMARY KEY,          -- 0..12
  title_ar   TEXT NOT NULL,
  intro_ar   TEXT NOT NULL,
  outcome_ar TEXT NOT NULL
);

CREATE TABLE akhlaq_lesson (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  level       INTEGER NOT NULL,
  ord         INTEGER NOT NULL,
  title_ar    TEXT NOT NULL,
  body_ar     TEXT NOT NULL,
  objective_ar TEXT,
  node_refs   TEXT,                        -- JSON array of slugs
  est_minutes INTEGER NOT NULL DEFAULT 5,
  status      TEXT NOT NULL DEFAULT 'draft'
);
CREATE INDEX idx_akhlaq_lesson_level ON akhlaq_lesson(level, ord);

CREATE TABLE akhlaq_scenario (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  prompt_ar      TEXT NOT NULL,
  context_tags   TEXT,                     -- JSON array
  node_refs      TEXT,                     -- JSON array of slugs
  reflection_ar  TEXT,
  status         TEXT NOT NULL DEFAULT 'draft'
);

CREATE TABLE akhlaq_scenario_option (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id   INTEGER NOT NULL,
  ord           INTEGER NOT NULL,
  text_ar       TEXT NOT NULL,
  verdict       TEXT NOT NULL,             -- sahih|maqbul|khata
  why_ar        TEXT NOT NULL,
  evidence_refs TEXT                       -- JSON array of akhlaq_evidence.id
);
CREATE INDEX idx_akhlaq_scenopt ON akhlaq_scenario_option(scenario_id, ord);

CREATE TABLE akhlaq_practice (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  node_slug     TEXT NOT NULL,
  text_ar       TEXT NOT NULL,
  cadence       TEXT NOT NULL DEFAULT 'once',  -- once|daily|weekly
  reflect_ar    TEXT,
  status        TEXT NOT NULL DEFAULT 'draft'
);
```

### v64 — البحث (FTS)

```sql
-- fts5 على الأدلّة والدروس والعُقَد (نصّ مطبّع + خام)
CREATE VIRTUAL TABLE akhlaq_fts USING fts5(
  kind,            -- node|evidence|lesson
  ref_id,          -- slug أو id
  title,
  body_norm,       -- normalizeArabicForSearch(text)
  body_raw,        -- النصّ الأصلي للعرض
  node_slug,
  tokenize = 'unicode61 remove_diacritics 2'
);
```
(نفس فلسفة `text_normalized` في بحث القرآن؛ يُعاد استخدام `arabic_normalize.dart`.)

---

## 2. جداول بيانات الطالب (لا تُبذَر)

```sql
CREATE TABLE akhlaq_progress_user (       -- تقدّم تعلّمي، لا حكم
  ref_kind    TEXT NOT NULL,              -- node|lesson|scenario|practice
  ref_id      TEXT NOT NULL,
  state       TEXT NOT NULL,              -- seen|studying|practiced|reviewed|internalised
  updated_at  INTEGER NOT NULL,
  PRIMARY KEY (ref_kind, ref_id)
);

CREATE TABLE akhlaq_focus_user (          -- «تركيز هذا الأسبوع»
  week_start  TEXT PRIMARY KEY,           -- YYYY-MM-DD
  node_slug   TEXT NOT NULL,
  note_ar     TEXT
);

CREATE TABLE akhlaq_notebook_user (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  kind        TEXT NOT NULL,              -- faida|iqtibas|mawqif_khata|mawqif_najah|khuluq_urid|khittat_islah|sual_li_nafsi|muhasabah_yawmi|muhasabah_usbuu
  node_slug   TEXT,
  evidence_id INTEGER,
  x_target    TEXT,                       -- 'ayah:2:83' | 'turath:137#p45'
  body_ar     TEXT NOT NULL,
  mood        INTEGER,                    -- 1..5 اختياري
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER
);
CREATE INDEX idx_akhlaq_nb_node ON akhlaq_notebook_user(node_slug);
CREATE INDEX idx_akhlaq_nb_kind ON akhlaq_notebook_user(kind, created_at);

CREATE TABLE akhlaq_scenario_answer_user (
  scenario_id INTEGER NOT NULL,
  chosen_opt  INTEGER,
  reflected   INTEGER NOT NULL DEFAULT 0,
  answered_at INTEGER NOT NULL,
  PRIMARY KEY (scenario_id)
);

CREATE TABLE akhlaq_meta (               -- علامات النسخ للبذر
  k TEXT PRIMARY KEY, v TEXT
);
```

> الاقتباس المربوط بموضع نصّ في كتاب (Turath) يُخزَّن عبر جداول التحشية
> القائمة (`turath_annotations` + `saveResolvedAnchor`)، ويُشار إليه من
> `akhlaq_notebook_user.x_target = 'turath:<book>#<anchor>'` — لا يُكرَّر
> محرّك تحشية.

---

## 3. البذر (`AkhlaqSync`)

- نمط `QuranCorpusSync`: يقرأ `assets/akhlaq/manifest.json` (sha256 + نسخة
  لكل ملفّ)، يقارن بـ`akhlaq_meta`، يبذر المتغيّر فقط في معاملة واحدة.
- ملفّات الأصول المقترحة: `nodes.json.gz` · `edges.json.gz` ·
  `xlinks.json.gz` · `evidence/<domain>.json.gz` (ملفّ لكل مجال) ·
  `levels.json.gz` · `lessons.json.gz` · `scenarios.json.gz` ·
  `practice.json.gz` · `source_editions.json.gz`.
- الـFTS يُعاد بناؤه بعد كل بذر متغيّر (`INSERT INTO akhlaq_fts SELECT …`).
- الحجم المتوقّع: أقلّ من ~3–6 MB مضغوطة في البداية (نصوص عربية).

---

## 4. الفهارس والأداء

- `akhlaq_evidence(node_slug, status)` · `akhlaq_edge(to_slug)` ·
  `akhlaq_lesson(level, ord)` · `akhlaq_fts` (بحث فوري).
- بطاقة العُقدة = 3–4 استعلامات مفهرسة؛ تُخزَّن مؤقتًا في الذاكرة (LRU صغير)
  مثل `QuranBookCache`.

---

## 5. التطبيع العربي والبحث

يُعاد استخدام `normalizeArabicForSearch` (`lib/utils/arabic_normalize.dart`)
لملء `body_norm`. تسامح الأخطاء المطبعية في `AKHLAQ_SEARCH §4`.

---

## 6. جاهزية المزامنة المستقبلية (Supabase)

كل جدول `*_user` يقبل لاحقًا `updated_at` (موجود) + `deleted_at` + `rev`
بلا كسر (أعمدة NULL عبر `ALTER TABLE ADD COLUMN`). جداول المعرفة تُرفَع
كـreference tables (قراءة عامّة). لا يُنفَّذ الآن.

---

## 7. الترحيل — تسلسل الإصدارات

| الإصدار | الجداول | يواكب مرحلة |
|---|---|---|
| v61 | `akhlaq_node`, `akhlaq_edge`, `akhlaq_xlink` | A1 |
| v62 | `akhlaq_source_edition`, `akhlaq_evidence` | A2 |
| v63 | `akhlaq_level`, `akhlaq_lesson`, `akhlaq_scenario(+option)`, `akhlaq_practice` | A4/A5 |
| v64 | `akhlaq_fts` | A7 |
| v65 | `akhlaq_*_user`, `akhlaq_meta` | A1 (بيانات الطالب تبدأ مبكرًا فارغة) |

> يجوز دمج v61+v65 معًا إذا بدأت واجهة التقدّم مع أول شاشة. القرار في
> `AKHLAQ_EXECUTION_PLAN`.
