# 06-QURAN-MEMORIZATION-MODEL.md — نموذج البيانات، أسلوب الصفحات، وخوارزمية تحجيم السبق

**يكمل**: `00-MEMORY-SYSTEM-MASTER.md` §2 (VerseMemory) و§19 (تحجيم يحترم حدود السورة). **يدمج** ملف `40-MEMORY-DATA-MODEL.md` المذكور سابقًا في خارطة الملفات — لا داعي لملف منفصل، هذا هو نفسه (تحديث خارطة §18 في المستند الرئيسي مطلوب بعد هذا الملف).

---

## 1. أسلوب الصفحات: المرجع الثابت

**604 صفحة** — المصحف المدني (طبعة مجمع الملك فهد، 15 سطرًا/صفحة تقريبًا، الأولى والأخيرة مختلفتان قليلًا). هذا **لا يُعاد حسابه** — يُقرأ مباشرة من الأصول المُجمَّعة أصلًا في هذا المشروع:

```
assets/quran/quran-data.js  → 31 نقطة بداية جزء [سورة, آية] (QuranData.Juz) — المصدر المشحون فعليًا، مُدرَج في pubspec.yaml
quran_import_service.dart   → يُفسِّر هذه النقاط عند الاستيراد إلى عمودي quran_ayat.juz_number/page_number
quran_ayat (DB)              → النص نفسه (Tanzil Uthmani) + juz_number/page_number المُشتقَّين
```

**تصحيح (2026-09-16، بالتحقّق الفعلي من الوكيل المنفِّذ)**: `mushafs-1.json.gz` **ليس** مصدر الحقيقة كما ادُّعي سابقًا هنا — الملف موجود في جذر المشروع فقط، خارج `assets/`، غير مُدرَج في `pubspec.yaml`، ومُتجاهَل في `.gitignore` — تنزيل محلي عابر غير متاح وقت التشغيل إطلاقًا. **المصدر الفعلي المستخدَم حيًّا هو `assets/quran/quran-data.js`** كما هو موضَّح أعلاه.

**القاعدة**: أي حد صفحة/جزء يُستخدَم في هذا المحرك يُقرَأ من عمودي `quran_ayat.juz_number`/`page_number` (مُشتقَّين وقت الاستيراد من `quran-data.js`)، ولا يُعاد اشتقاقه بحساب يدوي (604÷30 حساب تقريبي للعرض فقط، لا للجدولة الفعلية — الحدود الحقيقية للأجزاء تتفاوت فعليًا: جزء 1 = 21 صفحة، جزء 15 = 20 صفحة، جزء 30 = 23 صفحة، مؤكَّد بالفحص المباشر — والاعتماد على المتوسط في الجدولة الفعلية خطأ).

### التسلسل الهرمي (من الأصل نفسه)

```
القرآن (604 صفحة)
 └─ 30 جزءًا
     └─ 60 حزبًا (2 لكل جزء)
         └─ 240 ربعًا (4 لكل حزب)
             └─ صفحات (≈2.5 صفحة/ربع بالمتوسط، حد حقيقي وليس ثابتًا)
                 └─ آيات (6236 آية إجمالًا)
```

---

## 2. جدول `verse_memory` (المخطط الفعلي)

```sql
CREATE TABLE verse_memory (
  ayah_id               INTEGER PRIMARY KEY REFERENCES quran_ayat(id),
  state                 TEXT NOT NULL DEFAULT 'new',
      -- 'new' | 'encoded' | 'initial_recall' | 'stable' | 'strong'
      -- | 'long_term' | 'maintenance' | 'failure' | 'reactivation'
      -- | 'repair' | 'decay' | 'weak'
  encoding_strength      REAL NOT NULL DEFAULT 0.0,   -- 0.0–1.0
  retrieval_strength      REAL NOT NULL DEFAULT 0.0,   -- S في معادلة §3 من 03-SPACING-ENGINE.md
  fluency_sec_per_word    REAL,
  last_accuracy           REAL,                         -- 0.0–1.0، آخر تسميع
  consecutive_successes   INTEGER NOT NULL DEFAULT 0,
  last_successful_recall  TEXT,                         -- ISO date
  last_failure            TEXT,
  next_review_at          TEXT,                         -- محسوب من §3، منفصل عن next_review_date الحالي للصفحة
  confusion_risk          REAL NOT NULL DEFAULT 0.0,     -- من محرك المتشابهات، §9 من MASTER (معلَّق حتى يتوفر مصدر)
  prev_verse_linked        INTEGER NOT NULL DEFAULT 0,    -- boolean
  next_verse_linked        INTEGER NOT NULL DEFAULT 0,
  memorization_order_index INTEGER,                     -- يُملأ عند أول تسميع، ثابت بعدها (لأساس manzil_bucket)
  created_at               TEXT NOT NULL,
  updated_at               TEXT NOT NULL
);

CREATE INDEX idx_verse_memory_next_review ON verse_memory(next_review_at);
CREATE INDEX idx_verse_memory_state ON verse_memory(state);
```

**إضافي بالكامل** — لا عمود في `quran_ayat`/`memorization_repository` الحالي يُعدَّل. يُفعَّل خلف صف واحد في جدول الإعدادات: `feature_flags(key='verse_memory_v1', enabled=0)`.

### دالة تجميع: من الآية إلى الصفحة (القراءة التي تراها الشاشات الحالية)

```
page_status(page) =
    IF كل آيات الصفحة في state ∈ {stable, strong, long_term, maintenance} → "راسخة"
    ELSE IF أي آية في state ∈ {failure, decay, weak, repair, reactivation} → "تحتاج إصلاحًا"
    ELSE IF كل آيات الصفحة في state = 'new' → "لم تُبدأ"
    ELSE → "قيد الحفظ"
```

هذه الدالة هي **الوحيدة** التي تلمس شاشات الحفظ الحالية (`hifzCategory()`، شاشة المراجعة) — تُستدعى بدل القراءة المباشرة من عمود التاريخ القديم **فقط عند تفعيل `verse_memory_v1`**؛ التطبيق الحالي (`age_since_memorized`) يبقى المصدر الافتراضي حتى يثبت الجديد نفسه على بيانات تجريبية (Grain 1-2 في `TODO.md` المرفق).

---

## 3. خوارزمية تحجيم وحدة السبق (تحترم حدود السورة، من §19 في المستند الرئيسي)

المُدخَلات: `daily_rate` (صفحة/يوم، من الخطة المختارة عبر `JourneyPlanRepository`)، `current_position` (أول آية غير مبدوءة، حتمي بترتيب `memorization_order_mode`).

```
function next_sabaq_unit(current_position, daily_rate):
    surah = السورة التي تقع فيها current_position
    surah_remaining_pages = صفحات السورة المتبقية من current_position إلى نهايتها  (من mushafs-1.json.gz)

    IF surah_remaining_pages ≤ daily_rate × 1.3:        # سورة قصيرة أو قريبة من الانتهاء
        unit_end = نهاية السورة                          # يحاكي نمط "يوم = سورة" المُشاهَد في التطبيق المُراجَع
    ELSE IF surah_remaining_pages ≥ daily_rate × 4:      # سورة طويلة جدًا (كالبقرة/النساء)
        unit_end = أقرب حد ربع (rub') ≥ daily_rate ولا يتجاوزه بأكثر من 0.5 صفحة
    ELSE:
        unit_end = أقرب حد حزب (hizb) أو ربع، أيهما أقرب لـ daily_rate

    RETURN [current_position, unit_end]   # لا يقف أبدًا في منتصف آية
```

**لماذا هذا أفضل من تحجيم صفحة ثابتة**: يمنع قطع سورة قصيرة عبر يومين بلا داعٍ (كما يفعل أي جدول صفحات ثابت)، ويمنع أيضًا مشكلة عكسية (الانتظار لإنهاء سورة طويلة كالبقرة كوحدة واحدة، وهو غير عملي) عبر الرجوع لحدود الربع/الحزب القياسية للسور الطويلة.

### نقطة تفتيش صريحة بعد كل وحدة سورة

```
IF unit_end = نهاية سورة:
    اليوم التالي مباشرة = "يوم مراجعة" (لا سبق جديد)، يقفل فقط بعد نجاح تسميع كامل للسورة
    (يطابق نمط "راجع السورة" المُشاهَد، مُرقًّى إلى بوابة حقيقية بدل نص إرشادي فقط، انظر §8 من MASTER)
```

---

## 4. خطة الترحيل (Migration)

| المرحلة | ماذا يحدث | خطر على بيانات إسماعيل الحقيقية |
|---|---|---|
| 1. إنشاء الجدول | `verse_memory` فارغ، `feature_flags.verse_memory_v1=0` | صفر — جدول جديد فارغ فقط |
| 2. تعبئة أولية (backfill) | لكل صفحة "راسخة" فعلًا اليوم (بالمعيار القديم)، تُنشأ صفوف `verse_memory` لآياتها بحالة `stable` مبدئيًا؛ الصفحات الجارية تُعبَّأ بحالة `initial_recall` | صفر — قراءة فقط، كتابة في جدول جديد |
| 3. وضع الظل (shadow mode) | المحرك الجديد يحسب بالتوازي مع القديم، النتيجتان تُقارَنان في السجلات (logs) فقط، الشاشة تعرض القديم كما هو | صفر — لا تغيير في ما يراه المستخدم |
| 4. تفعيل اختياري | `feature_flags.verse_memory_v1=1` خلف شاشة إعدادات صريحة ("جرّب محرك الذاكرة الجديد") | منخفض — رجوع فوري بإيقاف العلم |
| 5. افتراضي للجميع | فقط بعد ما لا يقل عن أسبوعين تشغيل حي بلا انحراف ملحوظ بين النظامين على بيانات إسماعيل نفسه | — |

لا مرحلة هنا تُلغي أو تُعدِّل `next_review_date` الحالي بأثر رجعي — القديم يبقى المرجع الفعلي حتى المرحلة 5.

---

*مصدر البيانات الأساسي: الأصول المُجمَّعة أصلًا في هذا المشروع (`mushafs-1.json.gz`, `surahs.json.gz`, `quran_ayat`) — لا مصدر خارجي جديد.*
