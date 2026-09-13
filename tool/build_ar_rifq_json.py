# Assembles docs/akhlaq/alrifq/ar-rifq.json (the machine-readable content spec
# Not a runtime file. Regenerates docs/akhlaq/alrifq/ar-rifq.json from the AR-RIFQ_*.md content.
# for the الرفق vertical slice). Source of prose: docs/akhlaq/alrifq/AR-RIFQ_*.md
# Not a runtime file — a spec artifact + validation input + future seed.
import json, io

OUT = 'docs/akhlaq/alrifq/ar-rifq.json'

# ---- EVIDENCE ---------------------------------------------------------------
# source_status: source_confirmed = text reached from source + book/edition/
#   locator fixed + (marfu') takhrij/grading present IN the source.
#   source_located = source+book fixed, some metadata not yet pinned.
EV = [
 dict(id="EV-01", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح مسلم", author="مسلم بن الحجاج", edition="ت محمد فؤاد عبد الباقي — Turath 1727",
   chapter="كتاب البر والصلة والآداب — باب (٢٣) فضل الرفق", vol="4", page="2003–2004",
   hadith_id="٧٧ – (٢٥٩٣)", narrator="عائشة رضي الله عنها",
   text_ar="«يا عائشةُ! إنَّ اللهَ رفيقٌ يحبُّ الرفقَ، ويُعطي على الرفقِ ما لا يُعطي على العُنفِ، وما لا يُعطي على ما سواهُ».",
   authentication="أخرجه مسلم في صحيحه.", grader="مسلم (على شرطه)", grading="sahih",
   takhrij="مسلم ٢٥٩٣، كتاب البر والصلة، باب فضل الرفق.",
   source_status="source_confirmed", principle_refs=["P1"]),
 dict(id="EV-02", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح مسلم", author="مسلم بن الحجاج", edition="ت عبد الباقي — Turath 1727",
   chapter="كتاب البر والصلة والآداب — باب (٢٣) فضل الرفق", vol="4", page="2004",
   hadith_id="٧٨ – (٢٥٩٤)", narrator="عائشة رضي الله عنها (عن شريح بن هانئ)",
   text_ar="«إنَّ الرفقَ لا يكونُ في شيءٍ إلا زانَه، ولا يُنزَعُ من شيءٍ إلا شانَه».",
   authentication="أخرجه مسلم في صحيحه.", grader="مسلم", grading="sahih",
   takhrij="مسلم ٢٥٩٤. ورافدٌ بمعناه: سنن أبي داود ت الأرنؤوط (Turath 117359) كتاب الأدب باب (١١) في الرفق، ح ٤٨٠٨، ج7/186 — قصّة الناقة المُحرَّمة.",
   source_status="source_confirmed", principle_refs=["P2"]),
 dict(id="EV-03", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح مسلم", author="مسلم بن الحجاج", edition="ت عبد الباقي — Turath 1727",
   chapter="كتاب البر والصلة والآداب — باب (٢٣) فضل الرفق", vol="4", page="2003",
   hadith_id="٧٤ – (٢٥٩٢) (وبنحوه ٧٦)", narrator="جرير بن عبد الله رضي الله عنه",
   text_ar="«مَن يُحرَمِ الرفقَ يُحرَمِ الخيرَ».",
   authentication="أخرجه مسلم في صحيحه.", grader="مسلم", grading="sahih",
   takhrij="مسلم ٢٥٩٢.", source_status="source_confirmed", principle_refs=["P3"]),
 dict(id="EV-04", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح البخاري", author="محمد بن إسماعيل البخاري", edition="ت مصطفى ديب البغا — Turath 735",
   chapter="كتاب الأدب — باب (٨٠) قول النبيّ ﷺ: «يسِّروا ولا تُعسِّروا» (وأصله كتاب العلم ح ٦٩)",
   vol="5 (وموضع 1/38)", page="2269", hadith_id="٥٧٧٤ (وح ٦٩)", narrator="أنس بن مالك رضي الله عنه",
   text_ar="«يسِّروا ولا تُعسِّروا، وسكِّنوا ولا تُنفِّروا» — وفي رواية: «... وبشِّروا ولا تُنفِّروا».",
   authentication="متّفق عليه (البخاري؛ ومسلم في الجهاد والسير ١٧٣٤).", grader="البخاري ومسلم", grading="sahih",
   takhrij="البخاري ٥٧٧٤ و ٦٩؛ مسلم ١٧٣٤.", source_status="source_confirmed", principle_refs=["P4"]),
 dict(id="EV-05", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح مسلم", author="مسلم بن الحجاج", edition="ت عبد الباقي — Turath 1727",
   chapter="كتاب الجهاد والسِّيَر — باب (٣) في الأمر بالتيسير وترك التنفير", vol="3", page="1358",
   hadith_id="٦ – (١٧٣٢)", narrator="أبو موسى الأشعري رضي الله عنه",
   text_ar="كان رسولُ اللهِ ﷺ إذا بعثَ أحدًا من أصحابِه في بعضِ أمرِه قال: «بشِّروا ولا تُنفِّروا، ويسِّروا ولا تُعسِّروا».",
   authentication="أخرجه مسلم في صحيحه.", grader="مسلم", grading="sahih",
   takhrij="مسلم ١٧٣٢.", source_status="source_confirmed", principle_refs=["P4"]),
 dict(id="EV-06", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="الأدب المفرد للبخاري (بأحكام الألباني) — وأصله في الصحيحين", author="محمد بن إسماعيل البخاري",
   edition="بأحكام الألباني ت الزهيري — Turath 9647 (الأصل: البخاري ك الأدب؛ مسلم ك السلام)",
   chapter="باب (٢١٧) الرفق", vol="1", page="235", hadith_id="٤٦٢ (الصحيحة ٢٦٠٢)",
   narrator="عائشة رضي الله عنها",
   text_ar="دخلَ رهطٌ من اليهودِ على رسولِ اللهِ ﷺ فقالوا: السَّامُ عليكم. قالت عائشةُ: ففهِمتُها فقلتُ: عليكمُ السَّامُ واللعنةُ. فقال رسولُ اللهِ ﷺ: «مَهلًا يا عائشةُ، عليكِ بالرفقِ، وإيّاكِ والعُنفَ والفُحشَ». قالت: أوَلم تسمعْ ما قالوا؟ قال: «أوَلم تسمعي ما قلتُ؟ رددتُ عليهم، فيُستجابُ لي فيهم ولا يُستجابُ لهم فيَّ».",
   authentication="أصله متّفق عليه؛ وحكم الألباني على رواية الأدب المفرد: صحيح.",
   grader="البخاري ومسلم (الأصل) + الألباني (رواية الأدب المفرد)", grading="sahih",
   takhrij="البخاري ك الأدب، مسلم ك السلام؛ السلسلة الصحيحة ٢٦٠٢.",
   source_status="source_confirmed", principle_refs=["P5"]),
 dict(id="EV-07", source_type="hadith_marfu", source_tier=2, content_class="adab_thabit",
   book="الأدب المفرد للبخاري (بأحكام الألباني)", author="البخاري",
   edition="Turath 9647 (وأصله عند أبي داود، كتاب الحدود)", chapter="باب (٢١٧) الرفق",
   vol="1", page="237", hadith_id="٤٦٥ (الصحيحة ٦٣٨)", narrator="(كما في الطبعة)",
   text_ar="عن النبيّ ﷺ: «أقيلوا ذوي الهيئاتِ عثراتِهم».",
   authentication="حكم الألباني: صحيح (السلسلة الصحيحة ٦٣٨).", grader="الألباني", grading="sahih",
   takhrij="أبو داود ك الحدود؛ السلسلة الصحيحة ٦٣٨.",
   source_status="source_located", principle_refs=["P6"],
   note="نطاق «ذوي الهيئات» و«العثرات» (لا يشمل الحدود ولا حقًّا متعدّيًا) — الاستعمال هنا سلوكيّ ضيّق: هفوة أدبٍ عارضة."),
 dict(id="EV-08", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح مسلم", author="مسلم بن الحجاج", edition="ت عبد الباقي — Turath 1727",
   chapter="كتاب المساجد ومواضع الصلاة — باب (٧) تحريم الكلام في الصلاة", vol="1", page="381",
   hadith_id="٣٣ – (٥٣٧)", narrator="معاوية بن الحكم السُّلَمي رضي الله عنه",
   text_ar="(تكلّم في الصلاة جاهلًا بالنهي، فزجرَه القومُ بأبصارِهم) ... ثمّ قال: «فبأبي هو وأمّي، ما رأيتُ معلِّمًا قبلَه ولا بعدَه أحسنَ تعليمًا منه؛ فواللهِ ما كهَرني ولا ضرَبني ولا شتَمني».",
   authentication="أخرجه مسلم في صحيحه.", grader="مسلم", grading="sahih",
   takhrij="مسلم ٥٣٧.", source_status="source_confirmed", principle_refs=["P7"]),
 dict(id="EV-09", source_type="hadith_marfu", source_tier=2, content_class="khuluq_shari",
   book="صحيح البخاري", author="البخاري", edition="ت البغا — Turath 735 (وموضع آخر ح ٥٧٧٧)",
   chapter="كتاب الوضوء — باب صبّ الماء على البول في المسجد", vol="1", page="89",
   hadith_id="٢١٧", narrator="أبو هريرة رضي الله عنه",
   text_ar="قامَ أعرابيٌّ فبالَ في المسجدِ، فتناولَه الناسُ، فقال لهمُ النبيُّ ﷺ: «دَعوه، وهَريقوا على بولِه سَجْلًا من ماءٍ — أو ذَنوبًا من ماءٍ — فإنّما بُعِثتم ميسِّرين، ولم تُبعَثوا معسِّرين».",
   authentication="أخرجه البخاري في صحيحه.", grader="البخاري", grading="sahih",
   takhrij="البخاري ٢١٧ و ٥٧٧٧.", source_status="source_confirmed", principle_refs=["P8"]),
 dict(id="EV-10", source_type="qawl_alim", source_tier=4, content_class="khuluq_amm",
   book="جامع العلوم والحكم", author="ابن رجب الحنبلي", edition="ت شعيب الأرنؤوط وإبراهيم باجس — Turath 4268",
   chapter="شرح حديث «الدين النصيحة»", vol="2 (وموضع 1/225)", page="256", hadith_id="",
   narrator="",
   text_ar="قال ابنُ رجب: «وبكلِّ حالٍ يتعيَّنُ الرفقُ في الإنكارِ». ونقلَ عن سفيانَ الثوريِّ: «لا يأمرُ بالمعروفِ وينهى عنِ المنكرِ إلا من كان فيه خصالٌ ثلاثٌ: رفيقٌ بما يأمرُ رفيقٌ بما ينهى، عدلٌ بما يأمرُ عدلٌ بما ينهى، عالمٌ بما يأمرُ عالمٌ بما ينهى». ونقلَ عن الإمامِ أحمدَ: «الناسُ محتاجون إلى مُداراةٍ ...».",
   authentication="كلامُ مصنِّفٍ في كتابِه؛ يُنسَبُ إليه وإلى مَن نقلَ عنه.", grader="", grading="",
   takhrij="جامع العلوم والحكم، شرح حديث «الدين النصيحة».",
   source_status="source_confirmed", principle_refs=["P9"]),
 dict(id="EV-11", source_type="quran", source_tier=1, content_class="khuluq_shari",
   book="القرآن الكريم (والتبويب من: رياض الصالحين، باب الحلم والأناة والرفق)",
   author="النووي (التبويب)", edition="رياض الصالحين ط الرسالة الثاني — Turath 12014 — ج1/216",
   chapter="باب الحلم والأناة والرفق", vol="", page="", hadith_id="",
   narrator="",
   text_ar="﴿وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ وَاللَّهُ يُحِبُّ الْمُحْسِنِينَ﴾ [آل عمران: ١٣٤] · ﴿خُذِ الْعَفْوَ وَأْمُرْ بِالْعُرْفِ وَأَعْرِضْ عَنِ الْجَاهِلِينَ﴾ [الأعراف: ١٩٩] · ﴿ادْفَعْ بِالَّتِي هِيَ أَحْسَنُ فَإِذَا الَّذِي بَيْنَكَ وَبَيْنَهُ عَدَاوَةٌ كَأَنَّهُ وَلِيٌّ حَمِيمٌ﴾ [فصّلت: ٣٤]",
   authentication="كلامُ اللهِ؛ والتبويبُ اجتهادُ النوويِّ في كتابِه (يُنسَبُ إليه).",
   grader="", grading="",
   takhrij="الآيات: آل عمران ١٣٤، الأعراف ١٩٩، فصّلت ٣٤. الرسم وأرقام الآيات تُثبَّت من المصحف المحلّي عند التنفيذ.",
   source_status="source_located", principle_refs=[],
   note="ترجمة المعاني تُؤخَذ من إصدارٍ مُرخَّص فقط، وتُسمّى «ترجمة معاني الآية» — لا تُولَّد."),
]

# ---- PRINCIPLES (interpretation_by = منهج التطبيق التربوي) -----------------
P = [
 dict(id="P1", subskill="rifq_ibara", statement_ar="اللِّينُ طريقٌ لإيصالِ الحقِّ، لا بديلٌ عنه.", evidence=["EV-01"]),
 dict(id="P2", subskill="rifq_nabra", statement_ar="حين تشتدُّ لهجتُك يَنقُصُ أثرُ كلامِك ولو كان حقًّا.", evidence=["EV-02"]),
 dict(id="P3", subskill="rifq_istifzaz", statement_ar="التماسُ اللِّينِ مقصودٌ حتى حين يصعبُ الموقفُ.", evidence=["EV-03"]),
 dict(id="P4", subskill="rifq_taysir", statement_ar="ابدأْ بما يُقرِّبُ، وتجنَّبْ ما يُنفِّرُ، وتدرَّجْ.", evidence=["EV-04","EV-05"]),
 dict(id="P5", subskill="rifq_haqq", statement_ar="بيانُ الحقِّ يبقى؛ والرفقُ هو اختيارُ أخفِّ ردٍّ كافٍ، لا الفُحشَ ولا الإغضاءَ.", evidence=["EV-06"]),
 dict(id="P6", subskill="rifq_hafwa", statement_ar="الهفوةُ العابرةُ من أهلِ الفضلِ تُقالُ، ولا تُتتبَّعُ.", evidence=["EV-07"]),
 dict(id="P7", subskill="rifq_jahil", statement_ar="الجاهلُ يُعلَّمُ لا يُزجَرُ؛ ولا تثريبَ عليه في جهلِه.", evidence=["EV-08"]),
 dict(id="P8", subskill="rifq_la_taqta3", statement_ar="إذا كان زجرُك الآنَ يزيدُ الضررَ، فأمهِلْ، ثمّ أصلِحْ وعلِّمْ برفقٍ.", evidence=["EV-09"]),
 dict(id="P9", subskill="rifq_fahs", statement_ar="لا يُقدِمُ على الإنكارِ إلا من يجمعُ: الرفقَ في الطريقةِ، والعدلَ في الحكمِ، والعلمَ بالمسألةِ.", evidence=["EV-10"]),
]

SUBSKILLS = [
 ("rifq_ibara","اختيار أرفق عبارةٍ كافية لبيان الخطأ"),
 ("rifq_nabra","ضبط نبرة الصوت ولغة الجسد عند الإنكار"),
 ("rifq_tawqit","اختيار الوقت والمكان المناسبين للتصحيح (الخلوة إن أمكن)"),
 ("rifq_taysir","البدء بما يُقرّب قبل بيان الخطأ (تيسير لا تنفير)"),
 ("rifq_fahs","فحصٌ قبليّ: أعالِمٌ أنا؟ أعادلٌ حكمي؟ أرفيقةٌ طريقتي؟"),
 ("rifq_jahil","الرفق بالجاهل والسائل: تصحيحٌ بلا كَهْرٍ ولا تعنيف"),
 ("rifq_la_taqta3","عدم قطع الموقف بعنفٍ إذا زاد القطعُ الضرر؛ الإصلاح بعده"),
 ("rifq_istifzaz","تعمّد اللين عند الاستفزاز (الرفق اختيارٌ لا عجز)"),
 ("rifq_hazm","الجمع بين الحزم في المضمون واللين في الأسلوب"),
 ("rifq_naqd_qawl","فصل نقد القول عن ذمّ الشخص، مع بقاء أدب الإنكار"),
 ("rifq_nush","الرفق في النصيحة: نُصحٌ لا فضيحة"),
 ("rifq_mukarrir","الرفق مع من كرّر الخطأ: صبرٌ وتدرّجٌ بلا تعنيفٍ متصاعد"),
]

# behaviors: (id, subskill, text_ar, basis)  basis = EV-id OR "TARBAWI"
B = [
 ("B-01a","rifq_ibara","يصوغُ الملاحظةَ سؤالًا أو اقتراحًا قبل الحكم.","EV-01"),
 ("B-01b","rifq_ibara","يقتصرُ على القدرِ الكافي لبيانِ الخطأ، بلا زيادةِ تجريحٍ.","EV-02"),
 ("B-01c","rifq_ibara","يتجنّبُ ألفاظَ التصغيرِ والتوبيخِ («كيف لا تعرف»، «واضح جدًّا»).","EV-06"),
 ("B-01d","rifq_ibara","يذكرُ الصوابَ بعد بيانِ الخطأ، لا الخطأَ وحدَه.","TARBAWI"),
 ("B-02a","rifq_nabra","يخفضُ صوتَه حين يشتدُّ الموقفُ بدلَ رفعِه.","EV-02"),
 ("B-02b","rifq_nabra","لا يصاحبُ كلامَه إشارةُ استهزاءٍ أو زفرةُ ضيقٍ.","TARBAWI"),
 ("B-02c","rifq_nabra","يُمهِلُ ثانيةً قبل أن ينطقَ حين يحسُّ بارتفاعِ انفعالِه.","EV-03"),
 ("B-03a","rifq_tawqit","يؤخّرُ تصحيحَ الخطأ غيرِ العاجلِ إلى خلوةٍ بدلَ إعلانِه.","TARBAWI"),
 ("B-03b","rifq_tawqit","يصحّحُ فورًا فقط إذا كان تأخيرُه يُوقِعُ في ضررٍ أكبرَ.","EV-09"),
 ("B-03c","rifq_tawqit","لا يستدعي انتباهَ الحاضرين إلى خطأ فردٍ منهم بلا حاجةٍ.","EV-06"),
 ("B-04a","rifq_taysir","يفتحُ بذكرِ ما أصابَ فيه المخطئُ أو بكلمةٍ تُقرِّبُ.","EV-04"),
 ("B-04b","rifq_taysir","يتجنّبُ مدخلًا يُنفِّرُ («عندك أخطاء كثيرة...»).","EV-04"),
 ("B-04c","rifq_taysir","يتدرّجُ: الأهمُّ أولًا، لا كلَّ الملاحظاتِ دفعةً.","EV-05"),
 ("B-05a","rifq_fahs","يتوقّفُ قبل التصحيحِ ليتأكّدَ من المسألةِ إن لم يكن متيقّنًا.","EV-10"),
 ("B-05b","rifq_fahs","يميّزُ بين خطأٍ محقّقٍ ومسألةِ خلافٍ سائغٍ فلا يجعلُ المخالفَ «مخطئًا».","EV-10"),
 ("B-05c","rifq_fahs","لا يُنكِرُ إلا وهو يجمعُ: علمًا بالمسألةِ، وعدلًا في الحكمِ، ورفقًا في الطريقةِ.","EV-10"),
 ("B-06a","rifq_jahil","يجيبُ سؤالَ الجاهلِ البسيطَ بلا استنكارٍ ثمّ يبيّنُ.","EV-08"),
 ("B-06b","rifq_jahil","لا يزجُرُ السائلَ ولا يسخرُ من ضعفِ سؤالِه.","EV-08"),
 ("B-06c","rifq_jahil","يذكرُ الحكمَ/الصوابَ بعد أن يُطمئنَ السائلَ، لا قبلَه.","EV-08"),
 ("B-07a","rifq_la_taqta3","يكفُّ اندفاعَه لقطعِ الموقفِ حين يرى أنّ القطعَ الآنَ يوسّعُ الضررَ.","EV-09"),
 ("B-07b","rifq_la_taqta3","يعالجُ الأثرَ أولًا، ثمّ يعلّمُ صاحبَ الخطأ برفقٍ.","EV-09"),
 ("B-07c","rifq_la_taqta3","لا ينهالُ على المخطئِ بحضرةِ الناسِ لحظةَ الخطأ.","EV-09"),
 ("B-08a","rifq_istifzaz","يردُّ على الإساءةِ بأخفِّ ردٍّ كافٍ يحفظُ الحقَّ.","EV-06"),
 ("B-08b","rifq_istifzaz","لا يجاري الفُحشَ بفُحشٍ.","EV-06"),
 ("B-08c","rifq_istifzaz","يذكّرُ نفسَه أنّ قدرتَه على الشدّةِ قائمةٌ وأنّه يختارُ اللِّينَ.","EV-03"),
 ("B-09a","rifq_hazm","يقولُ «هذا خطأٌ» بوضوحٍ، وبعبارةٍ غيرِ جارحةٍ.","EV-06"),
 ("B-09b","rifq_hazm","لا يظنُّ أنّ خفضَ العبارةِ يعني التنازلَ عن المضمونِ.","TARBAWI"),
 ("B-09c","rifq_hazm","لا يظنُّ أنّ الغلظةَ في اللفظِ «حزمٌ».","TARBAWI"),
 ("B-10a","rifq_naqd_qawl","ينقدُ الفكرةَ/القولَ ولا ينتقلُ إلى وصفِ صاحبِها.","EV-06"),
 ("B-10b","rifq_naqd_qawl","يحفظُ للمخالفِ قدرَه وهو يبيّنُ خطأَه.","EV-10"),
 ("B-10c","rifq_naqd_qawl","لا يستطيلُ في عِرضِ المخطئِ بحجّةِ الغيرةِ على الحقِّ.","EV-06"),
 ("B-11a","rifq_nush","ينصحُ على انفرادٍ ما أمكنَ.","EV-10"),
 ("B-11b","rifq_nush","لا يُشهِرُ بالخطأ في مجلسٍ أو مكتوبٍ.","EV-06"),
 ("B-11c","rifq_nush","يختارُ من الألفاظِ ما يحفظُ الودَّ.","EV-10"),
 ("B-12a","rifq_mukarrir","يعيدُ البيانَ بأسلوبٍ آخرَ بدلَ رفعِ اللهجةِ في المرّةِ الثانيةِ.","EV-03"),
 ("B-12b","rifq_mukarrir","يفصلُ بين «تكرارِ الخطأ» و«استحقاقِ الغلظةِ».","EV-03"),
 ("B-12c","rifq_mukarrir","يسألُ نفسَه: هل كان بياني الأولُ واضحًا؟ قبل أن يلومَ المتكرِّرَ.","TARBAWI"),
]

# ---- SCENARIOS (compact — full prose in AR-RIFQ_SCENARIOS.md) --------------
def opt(o,t,dims,v,why,ev): return dict(ord=o, text_ar=t, dimensions=dims, verdict=v, why_ar=why, evidence=ev)
S = [
 dict(id="S-01", difficulty=1, setting="small_majlis", subskills=["rifq_ibara","rifq_taysir"],
   pressure=[], composite=False,
   stem_ar="في درسٍ، ذكرَ زميلٌ مسألةً فأخطأ فيها، وبينكما ودٌّ.",
   options=[
     opt("A","«كيف تقولُ هذا وأنت طالبُ علمٍ؟»",{"gentleness":-1,"respect":-1,"intention_awareness":-1},"baid","تجريحٌ وتصغيرٌ؛ أثرُ الحقِّ ينقصُ.",["EV-02","EV-06"]),
     opt("B","تسكتُ وتتركُه (لستَ في مزاجِ نقاشٍ).",{"truthfulness":-1,"firmness_when_needed":-1},"baid","كتمُ بيانٍ يسيرٍ بلا عذرٍ.",["EV-10"]),
     opt("C","«فائدةٌ: الصوابُ في هذه المسألةِ كذا، والدليلُ...» بهدوءٍ.",{"gentleness":1,"truthfulness":1,"timing":1},"aqrab","بيانٌ ليّنٌ كافٍ، يفصلُ الخطأَ عن الشخصِ.",["EV-01","EV-04"]),
     opt("D","تصحّحُه بحدّةٍ أمام الجميعِ «هذا غلطٌ، الصوابُ...».",{"truthfulness":1,"gentleness":-1,"respect":-1},"maqbul","المضمونُ صحيحٌ، لكنّ الأسلوبَ يشينُ ويُحرِجُ.",["EV-02"]),
   ],
   probe_ar="لو اخترتَ (A) أو (D) — أكان الباعثُ بيانَ الحقِّ أم ألّا تبدوَ أقلَّ منه؟",
   feedback_ar="الأقربُ (C): لفظٌ ليّنٌ + بيانٌ + دليلٌ، بلا تصغيرٍ. (D) صحيحٌ لكنّه يشينُ الموقفَ (EV-02). (A) تجريحٌ. (B) كتمانٌ.",
   reflection_ar="حين صحّحتَ لأحدٍ آخرَ مرّةٍ — هل بدأتَ بالفائدةِ أم بالتخطئةِ؟"),
 dict(id="S-02", difficulty=3, setting="small_majlis", subskills=["rifq_mukarrir","rifq_nabra"],
   pressure=["time_pressure"], composite=False,
   stem_ar="نبّهتَ طالبًا قبل أسبوعٍ إلى خطأٍ، واليومَ كرّرَه في مجلسٍ آخرَ.",
   options=[
     opt("A","«قلتُ لك مرّةً! لماذا لا تحفظُ؟» بضيقٍ.",{"self_control":-1,"gentleness":-1,"respect":-1},"baid","غلظةٌ متصاعدةٌ مع التكرارِ.",["EV-03"]),
     opt("B","تصحّحُ بهدوءٍ، وبأسلوبٍ مختلفٍ عن المرّةِ الأولى، وتسألُ نفسَك: هل كان بياني واضحًا؟",{"gentleness":1,"self_control":1,"intention_awareness":1},"aqrab","صبرٌ + تغييرُ الأسلوبِ + مراجعةُ الذاتِ.",["EV-03","EV-08"]),
     opt("C","تتجاهلُ، فالتكرارُ «مشكلتُه هو».",{"truthfulness":-1,"firmness_when_needed":-1},"baid","تركُ بيانٍ لازمٍ.",["EV-10"]),
     opt("D","تصحّحُ بلطفٍ، ثمّ تضيفُ تعليقًا ساخرًا خفيفًا «حتى لا تنساها».",{"gentleness":1,"respect":-1,"intention_awareness":-1},"maqbul","اللينُ مشوبٌ بلمزٍ يُضعِفُ أثرَه.",["EV-06"]),
   ],
   probe_ar="هل غضبتَ من تكرارِه، أم راجعتَ طريقتَك في التعليمِ؟",
   feedback_ar="الأقربُ (B). التكرارُ لا يُبيحُ الغلظةَ (يُقاس على EV-03)، وقد يكونُ الخللُ في وضوحِ بيانِك السابقِ [TARBAWI].",
   reflection_ar="هل غضبتَ من تكرارِه، أم راجعتَ تعليمَك؟"),
 dict(id="S-03", difficulty=2, setting="small_majlis", subskills=["rifq_jahil"],
   pressure=["in_public"], composite=False,
   stem_ar="رجلٌ حديثُ التزامٍ سألَ في مجلسٍ سؤالًا عدَّه بعضُ الحاضرين بديهيًّا، فابتسمَ بعضُهم.",
   options=[
     opt("A","«سؤالٌ في محلِّه؛ المسألةُ فيها تفصيلٌ...» ثمّ تبيّنُ.",{"gentleness":1,"respect":1,"truthfulness":1},"aqrab","ترحيبٌ + بيانٌ بلا انتهارٍ (EV-08).",["EV-08"]),
     opt("B","«هذا معروفٌ، اقرأْ كتابَ الطهارةِ أولًا».",{"gentleness":-1,"respect":-1},"baid","كَهْرٌ وإحالةٌ فيها تصغيرٌ.",["EV-08"]),
     opt("C","تجيبُ بجفافٍ ثمّ تنصرفُ.",{"truthfulness":1,"gentleness":-1,"timing":-1},"maqbul","مضمونٌ صحيحٌ، لكن بلا رفقٍ بالسائلِ.",["EV-08"]),
     opt("D","تضحكُ مجاملةً مع الحاضرين ثمّ تجيبُ.",{"respect":-1,"self_control":-1,"intention_awareness":-1},"baid","مشاركةٌ في إحراجِ السائلِ.",["EV-08"]),
   ],
   probe_ar="حين سُئلتَ سؤالًا سهلًا — هل أشعرتَ السائلَ بضعفِه؟",
   feedback_ar="الأقربُ (A): «ما كهَرني ولا ضرَبني ولا شتَمني» (EV-08) — يُرحَّبُ بالسؤالِ ثمّ يُبيَّنُ.",
   reflection_ar="حين سُئلتَ سؤالًا سهلًا آخرَ مرّةٍ — هل أشعرتَ السائلَ بضعفِه؟"),
 dict(id="S-04", difficulty=4, setting="online", subskills=["rifq_istifzaz","rifq_naqd_qawl"],
   pressure=["he_insults","in_public"], composite=False,
   stem_ar="قلتَ في تعليقٍ عبارةً، ففهِمَها أحدُهم على غيرِ مرادِك، وردَّ عليك بحدّةٍ أمام الناسِ.",
   options=[
     opt("A","«لو قرأتَ بتأنٍّ لفهمتَ؛ لكنّ التسرّعَ عادةٌ عندك».",{"gentleness":-1,"respect":-1},"baid","ردٌّ للنفسِ + انتقالٌ إلى الشخصِ.",["EV-06"]),
     opt("B","«أقصدُ كذا لقرينةِ كذا، لا ما فهمتَ. شكرًا على التنبيهِ».",{"gentleness":1,"self_control":1,"truthfulness":1},"aqrab","توضيحٌ للحقِّ بأخفِّ ردٍّ، بلا انجرارٍ (EV-06).",["EV-06","EV-03"]),
     opt("C","تحذفُ التعليقَ وتنسحبُ.",{"firmness_when_needed":-1,"truthfulness":-1},"maqbul","تسلَمُ من الشرِّ لكن تتركُ بيانًا ممكنًا بلا ضررٍ.",["EV-10"]),
     opt("D","«كلامُك سوءُ فهمٍ فاضحٌ» بلا توضيحٍ.",{"truthfulness":1,"gentleness":-1,"respect":-1},"baid","إثباتٌ للحقِّ بصيغةٍ مُذِلّةٍ.",["EV-02"]),
   ],
   probe_ar="أوّلُ ما تحرّكَ فيك: تصحيحُ الفهمِ، أم أنّه «تطاولَ عليك»؟",
   feedback_ar="الأقربُ (B): بيانُ المرادِ + كلمةُ شكرٍ تُنهي التوتّرَ — ردٌّ للحقِّ لا للنفسِ (EV-03، EV-06).",
   reflection_ar="حين استُفزِزتَ — هل رددتَ للحقِّ أم لنفسِك؟"),
 dict(id="S-05", difficulty=3, setting="small_majlis", subskills=["rifq_fahs","rifq_naqd_qawl"],
   pressure=["dislike_him"], composite=False,
   stem_ar="خالفَك زميلٌ في مسألةٍ فيها قولانِ معتبرانِ، وتمسّكَ بقولِه بأدبٍ.",
   options=[
     opt("A","«قولُك ضعيفٌ ومهجورٌ» وتقطعُ النقاشَ.",{"truthfulness":-1,"justice":-1,"gentleness":-1},"baid","تخطئةٌ في مسألةِ خلافٍ سائغٍ + قطعٌ فظٌّ.",["EV-10"]),
     opt("B","«المسألةُ فيها قولانِ؛ أرجّحُ كذا لدليلِ كذا، وقولُك له وجهٌ».",{"justice":1,"gentleness":1,"truthfulness":1},"aqrab","إنصافٌ + بيانُ الترجيحِ بلا تخطئةٍ للمخالفِ (EV-10).",["EV-10"]),
     opt("C","تجاملُه «كلامُك جميلٌ» وتتركُ بيانَ ما تراه راجحًا.",{"gentleness":1,"truthfulness":-1,"firmness_when_needed":-1},"baid","لينٌ يُضيّعُ بيانَ ما تعتقدُه الصوابَ.",["EV-10"]),
     opt("D","تصمتُ لأنّك لا تحبُّه ولا تريدُ مجاملتَه.",{"intention_awareness":-1,"justice":-1},"baid","الباعثُ شخصيٌّ لا علميٌّ.",["EV-10"]),
   ],
   probe_ar="هل كان موقفي من قولِه لأنّه خطأٌ، أم لأنّه هو؟",
   feedback_ar="الأقربُ (B): «عدلٌ بما ينهى» (EV-10)؛ مسألةُ الخلافِ لا يُجعَلُ أحدُ طرفيها «الخطأ».",
   reflection_ar="هل كان موقفي من قولِه لأنّه خطأٌ، أم لأنّه هو؟"),
 dict(id="S-06", difficulty=5, setting="public_majlis", subskills=["rifq_istifzaz","rifq_nabra"],
   pressure=["he_insults","in_public"], composite=False,
   stem_ar="في مجلسٍ عامٍّ، قال أحدُهم مُشيرًا إليك: «بعضُ من يتصدّرُ للتعليمِ لا يُحسِنُ قراءةَ سطرٍ».",
   options=[
     opt("A","«وأنتَ ما قرأتَ كتابًا كاملًا في حياتِك».",{"self_control":-1,"gentleness":-1,"truthfulness":-1},"baid","مجاراةُ الفُحشِ بفُحشٍ (ضدّ EV-06).",["EV-06"]),
     opt("B","«إن كان عندك ملاحظةٌ علميّةٌ محدّدةٌ فأنا أسمعُها» بهدوءٍ، ثمّ تُكمِلُ.",{"self_control":1,"gentleness":1,"firmness_when_needed":1},"aqrab","ضبطٌ + ردٌّ للحقِّ بلا انجرارٍ، ويحفظُ موضعَك.",["EV-06","EV-03"]),
     opt("C","تسكتُ وتُظهِرُ الضيقَ وتغادرُ المجلسَ.",{"self_control":0,"timing":-1},"maqbul","تسلَمُ من المشادّةِ، لكنّ الانسحابَ المُتبرِّمَ فيه أثرُ غضبٍ.",["EV-02"]),
     opt("D","«سامحك اللهُ» بنبرةٍ ساخرةٍ.",{"gentleness":-1,"intention_awareness":-1},"baid","صيغةُ عفوٍ ظاهرُها لينٌ وباطنُها لمزٌ.",["EV-06"]),
   ],
   probe_ar="حين رددتَ — هل كان ردّي للحقِّ أم لنفسي؟",
   feedback_ar="الأقربُ (B): «مَهلًا... عليكِ بالرفقِ وإيّاكِ والعُنفَ والفُحشَ» (EV-06). الرفقُ هنا اختيارٌ مع قدرتِك على الردِّ، لا عجزٌ.",
   reflection_ar="هل بقيَ أثرُ الاستفزازِ فيَّ بعد أن انتهى المجلسُ؟"),
 dict(id="S-07", difficulty=4, setting="small_majlis", subskills=["rifq_tawqit","rifq_nush"],
   pressure=["in_public"], composite=False,
   stem_ar="ألقى طالبٌ فائدةً أمام الحلقةِ ونسبَ قولًا إلى غيرِ قائلِه. الخطأُ لا يترتّبُ عليه ضررٌ عاجلٌ.",
   options=[
     opt("A","تقاطعُه فورًا «هذا ليس كذلك».",{"truthfulness":1,"timing":-1,"respect":-1},"maqbul","صحيحٌ، لكن العلنيّةَ الفوريّةَ تُحرِجُ بلا حاجةٍ.",["EV-06"]),
     opt("B","تدعُه يُكمِلُ، ثمّ على انفرادٍ: «فائدتُك نافعةٌ؛ والصوابُ في النسبةِ كذا».",{"gentleness":1,"timing":1,"respect":1},"aqrab","سترٌ + توقيتٌ يحفظُ ماءَ الوجهِ (EV-06، EV-09).",["EV-06","EV-09"]),
     opt("C","تكتبُ الخطأَ في مجموعةِ الحلقةِ العامّةِ لينتبهَ الجميعُ.",{"truthfulness":1,"gentleness":-1,"respect":-1},"baid","«نصيحةٌ» علنيّةٌ = فضيحةٌ.",["EV-06"]),
     opt("D","تتركُه بلا تنبيهٍ إطلاقًا.",{"truthfulness":-1,"firmness_when_needed":-1},"maqbul","السترُ حسنٌ، لكن تركَ التنبيهِ بالكلّيّةِ يُبقي الخطأَ.",["EV-10"]),
   ],
   probe_ar="هل كان يمكنُ أن أقولَها له على انفرادٍ؟",
   feedback_ar="الأقربُ (B): الجمعُ بين التنبيهِ (لئلا يبقى الخطأُ) والسترِ (اختيارِ الوقتِ والمكانِ).",
   reflection_ar="هل كان يمكنُ أن أقولَها له على انفرادٍ؟"),
 dict(id="S-08", difficulty=5, setting="private", subskills=["rifq_istifzaz","rifq_naqd_qawl","rifq_nush"],
   pressure=["your_reputation"], composite=False,
   stem_ar="نقلَ زميلٌ كلامًا لك بغيرِ معناه إلى شيخٍ، فبلغَك أنّ الشيخَ فهِمَ عنك خلافَ مرادِك.",
   options=[
     opt("A","تنشرُ توضيحًا عامًّا تُسمّي فيه الزميلَ وتصفُه بالتحريفِ.",{"truthfulness":1,"gentleness":-1,"respect":-1},"baid","إثباتُ حقٍّ بطريقةٍ تُسقِطُ الشخصَ وتُشهِّرُ.",["EV-06"]),
     opt("B","توضّحُ مرادَك للشيخِ مباشرةً، وتُعاتِبُ الزميلَ على انفرادٍ بلا تجريحٍ.",{"truthfulness":1,"gentleness":1,"timing":1},"aqrab","حفظُ الحقِّ + عتابٌ سرّيٌّ ليّنٌ (EV-10، EV-11 «ادفع بالتي هي أحسن»).",["EV-10","EV-11"]),
     opt("C","تسكتُ تمامًا حفاظًا على «الرفقِ».",{"truthfulness":-1,"firmness_when_needed":-1},"baid","ضعفٌ لا رفقٌ؛ يبقى فهمٌ خاطئٌ عنك.",["EV-06"]),
     opt("D","تقاطعُ الزميلَ وتُظهِرُ له الجفاءَ دون أن تخبرَه بالسببِ.",{"self_control":-1,"gentleness":-1,"justice":-1},"baid","عقوبةٌ بلا بيانٍ، وباعثُها الانتصارُ للنفسِ.",["EV-10"]),
   ],
   probe_ar="رغبتي الأولى: تصحيحُ الصورةِ عند الشيخِ، أم معاقبةُ الزميلِ؟",
   feedback_ar="الأقربُ (B): «ادفعْ بالتي هي أحسنُ» (EV-11) — تُصلِحُ الفهمَ وتُعاتِبُ سرًّا. السكوتُ هنا ضعفٌ لا رفقٌ.",
   reflection_ar="رغبتي الأولى: تصحيحُ الصورةِ، أم معاقبةُ الزميلِ؟"),
 dict(id="S-09", difficulty=6, setting="public_majlis", subskills=["rifq_nabra","rifq_hazm"],
   pressure=["yr_certain","time_pressure","in_public"], composite=False,
   stem_ar="بقيَ خمسُ دقائقَ على انتهاءِ الدرسِ. طالبٌ اعترضَ على تقريرِك لمسألةٍ أنت متيقّنٌ من صحّتِها، واعتراضُه فيه سوءُ فهمٍ.",
   options=[
     opt("A","«هذا ليس محلَّ نقاشٍ، الكلامُ واضحٌ» وتُنهي.",{"firmness_when_needed":1,"gentleness":-1,"respect":-1},"baid","حزمٌ صيغتُه مُذِلّةٌ، ويقينُ الحقِّ لا يُبيحُ الغلظةَ (EV-02).",["EV-02"]),
     opt("B","«سؤالُك مهمٌّ؛ الوقتُ ضاقَ، فلنكمِلْه أوّلَ الدرسِ القادمِ — وباختصارٍ: مرادي كذا».",{"gentleness":1,"self_control":1,"timing":1},"aqrab","لينٌ + وعدٌ بالاستكمالِ + إشارةٌ للصوابِ.",["EV-02"]),
     opt("C","تدخلُ في نقاشٍ طويلٍ يتجاوزُ الوقتَ لإفحامِه.",{"firmness_when_needed":1,"self_control":-1,"intention_awareness":-1},"baid","باعثُ الإفحامِ، وإخلالٌ بحقِّ بقيّةِ الحاضرين.",["EV-06"]),
     opt("D","«كلامُك خطأٌ» بجفافٍ ثمّ تخرجُ.",{"truthfulness":1,"gentleness":-1,"timing":-1},"maqbul","صحيحٌ في الحكمِ، فظٌّ في الأسلوبِ والتوقيتِ.",["EV-02"]),
   ],
   probe_ar="حين كنتَ متيقّنًا — هل ازددتَ رفقًا أم غلظةً؟",
   feedback_ar="الأقربُ (B): يقينُ الحقِّ أخطرُ مواطنِ تركِ الرفقِ — «لا يُنزَعُ من شيءٍ إلا شانَه» (EV-02). حزمٌ في المضمونِ، لينٌ في اللفظِ.",
   reflection_ar="حين كنتَ متيقّنًا — هل ازددتَ رفقًا أم غلظةً؟"),
 dict(id="S-10", difficulty=7, setting="family", subskills=["rifq_la_taqta3","rifq_istifzaz","rifq_naqd_qawl","rifq_nush"],
   pressure=["your_reputation","multi_virtue"], composite=True,
   stem_ar="استضفتَ زميلًا لمذاكرةٍ. تكلّمَ عن والدِك بكلمةٍ فيها استخفافٌ غيرُ مقصودٍ، ثمّ سكبَ الشايَ على كتابٍ مُعارٍ لك من شيخِك.",
   options=[
     opt("A","تنفعلُ للكلمةِ عن والدِك وتتركُ أمرَ الكتابِ، وتُشعِرُه بالبرودِ بقيّةَ الجلسةِ.",{"justice":-1,"self_control":-1,"gentleness":-1},"baid","ردّةُ فعلٍ غيرُ متّزنةٍ، وإهمالٌ لحقٍّ آخرَ.",["EV-06"]),
     opt("B","تُكمِلُ الضيافةَ، وفي لحظةٍ مناسبةٍ تبيّنُ خطأَ الكلمةِ بلطفٍ، وتُطمئنُه أنّ أمرَ الكتابِ يسيرٌ وتتولّى إصلاحَه مع الشيخِ بصدقٍ.",{"gentleness":1,"justice":1,"timing":1,"truthfulness":1},"aqrab","موازنةٌ: أدبُ الضيفِ + تصحيحٌ ليّنٌ للكلمةِ + معالجةُ حقِّ الكتابِ بصدقٍ لا تهوينَ.",["EV-06","EV-10","EV-11"]),
     opt("C","تتجاوزُ كلَّ شيءٍ ولا تذكرُ شيئًا حفاظًا على الودِّ، وتُخبرُ الشيخَ أنّ الكتابَ «تلفَ عندك» دون تفصيلٍ.",{"gentleness":1,"truthfulness":-1,"justice":-1},"baid","لينٌ يُسقِطُ الصدقَ في حقِّ الشيخِ وحقِّ الكلمةِ.",["EV-10"]),
     opt("D","تعاتبُه بحزمٍ على الكلمةِ والكتابِ فورًا وبعباراتٍ فيها توبيخٌ.",{"truthfulness":1,"firmness_when_needed":1,"gentleness":-1,"respect":-1},"maqbul","المضمونُ واجبٌ، لكنّ التوبيخَ الفوريَّ للضيفِ يشينُ ويمكنُ تأجيلُه.",["EV-06"]),
   ],
   probe_ar="أيَّ الحقوقِ كنتُ أميلُ لإسقاطِه لأجلِ «عدمِ الإحراجِ»؟",
   feedback_ar="الأقربُ (B): الموقفُ يجمعُ فضائلَ متزاحمةً — الرفقُ لا يُلغي حقَّ الوالدِ ولا الأمانةَ في حقِّ الشيخِ (EV-06، EV-10). لا تُهوِّنْ أمرَ الكتابِ كذبًا باسمِ الرفقِ.",
   reflection_ar="هل استعملتُ «الرفقَ» غطاءً لتركِ حقٍّ صعبٍ؟"),
 dict(id="S-11", difficulty=7, setting="small_majlis", subskills=["rifq_hazm","rifq_nush","rifq_nabra"],
   pressure=["your_reputation","multi_virtue"], composite=True,
   stem_ar="في حلقةٍ، يتكلّمُ أحدُ الطلابِ كثيرًا ويقاطعُ غيرَه. لو نصحتَه بلينٍ ظنَّ بعضُ الحاضرين أنّك تهابُه، ولو أغلظتَ انكسرَ المجلسُ.",
   options=[
     opt("A","تُغلِظُ له علنًا لتُثبِتَ أنّك «لا تهابُ».",{"firmness_when_needed":1,"gentleness":-1,"respect":-1,"intention_awareness":-1},"baid","باعثُ الظهورِ، وكسرٌ للمجلسِ.",["EV-06"]),
     opt("B","تُنظِّمُ الدورَ بلطفٍ وحزمٍ للجميعِ «نسمعُ فلانًا ثمّ فلانًا»، وتنصحُه سرًّا بعد المجلسِ.",{"gentleness":1,"firmness_when_needed":1,"timing":1},"aqrab","حزمٌ في الإجراءِ + لينٌ في اللفظِ + نُصحٌ سرّيٌّ (EV-10، EV-11).",["EV-10","EV-11"]),
     opt("C","تتركُه يستأثرُ بالكلامِ تجنّبًا للإحراجِ.",{"firmness_when_needed":-1,"justice":-1},"baid","ضعفٌ باسمِ الرفقِ، وظلمٌ لبقيّةِ الطلابِ.",["EV-10"]),
     opt("D","تلمزُه بعبارةٍ ذكيّةٍ تُضحِكُ المجلسَ على حسابِه.",{"gentleness":-1,"respect":-1,"intention_awareness":-1},"baid","«حزمٌ» عبر الإهانةِ المُغلَّفةِ.",["EV-06"]),
   ],
   probe_ar="هل كان همّي إصلاحَ المجلسِ، أم صورتي أمام الحاضرين؟",
   feedback_ar="الأقربُ (B): الحزمُ يكونُ في الإجراءِ (تنظيمِ الدورِ)، واللينُ في اللفظِ؛ ما يظنُّه الناسُ ليس مقياسَ الصوابِ.",
   reflection_ar="هل كان همّي إصلاحَ المجلسِ، أم صورتي؟"),
 dict(id="S-12", difficulty=8, setting="with_shaykh", subskills=["rifq_tawqit","rifq_fahs","rifq_hazm","rifq_naqd_qawl","rifq_nush"],
   pressure=["multi_virtue","your_reputation"], composite=True,
   stem_ar="شيخُك أخطأ في نسبةِ قولٍ لإمامٍ (الخطأُ محقّقٌ، ولا يترتّبُ عليه حكمٌ خطيرٌ). أنت في مجلسِه، وطالبٌ مبتدئٌ دوّنَ الخطأَ في كرّاسِه.",
   options=[
     opt("A","تصحّحُ للشيخِ أمام المجلسِ مباشرةً «أحسنَ اللهُ إليك، القولُ لفلانٍ لا فلانٍ».",{"truthfulness":1,"justice":1,"respect":-1,"timing":-1},"maqbul","المضمونُ صحيحٌ ومنعُ انتشارِ الخطأ مقصدٌ، لكن العلنيّةَ مع الشيخِ تحتاجُ ألطفَ، وقد يُغني تلميحٌ.",["EV-06"]),
     opt("B","تصمتُ تمامًا توقيرًا للشيخِ، وتتركُ المبتدئَ على خطئِه.",{"respect":1,"truthfulness":-1,"justice":-1},"baid","التوقيرُ لا يُبيحُ إقرارَ خطأٍ ينتشرُ.",["EV-10"]),
     opt("C","تُلمِّحُ في المجلسِ بأدبٍ «لعلّي واهمٌ، أليس هذا القولُ يُنسَبُ لفلانٍ؟»، وبعد المجلسِ تُراجعُ الشيخَ سرًّا، وتنبّهُ المبتدئَ على انفرادٍ.",{"gentleness":1,"respect":1,"truthfulness":1,"timing":1,"justice":1},"aqrab","يجمعُ: أدبَ الشيخِ + بيانَ الحقِّ بألطفِ صيغةٍ + قطعَ انتشارِ الخطأ عند المبتدئِ سرًّا.",["EV-06","EV-10","EV-11"]),
     opt("D","تنتظرُ انتهاءَ المجلسِ وتصحّحُ للمبتدئِ فقط، وتتركُ الشيخَ.",{"truthfulness":0,"respect":1,"justice":-1},"maqbul","يحفظُ المبتدئَ، لكن يتركُ الخطأَ قائمًا عند بقيّةِ من سمعَه.",["EV-10"]),
   ],
   probe_ar="ما الذي كنتُ أخشاه أكثرَ: أن يبقى الخطأُ، أم أن أبدوَ «مصحِّحًا لشيخي» أمام الناسِ؟",
   feedback_ar="الأقربُ (C): المستوى الثامنُ = موازنةُ فضائلَ متزاحمةٍ. الرفقُ هنا صيغةُ التلميحِ، لا تركُ التصحيحِ؛ وتوقيرُ الشيخِ في العلنِ، والتحقيقُ معه سرًّا (EV-06، EV-10، EV-11).",
   reflection_ar="هل غلّبتُ صورتي، أو توقيرَ الشيخِ، أو الحقَّ؟ وهل كان يمكنُ الجمعُ؟"),
]

CURRICULUM = [
 dict(stage=1, title_ar="تعريفٌ وفهمٌ", subskills=["rifq_ibara"],
   outcome_ar="يفرّقُ بين «تركِ الحقِّ» و«تليينِ الأسلوبِ»؛ يذكرُ مثالًا من يومِه.", scenarios=["S-01"]),
 dict(stage=2, title_ar="تمييزُ الرفقِ من الضعفِ", subskills=["rifq_istifzaz","rifq_naqd_qawl"],
   outcome_ar="حين يُستفزُّ، يردُّ للحقِّ لا للنفسِ، ولا يجاري الفُحشَ.", scenarios=["S-08","S-04"]),
 dict(stage=3, title_ar="تمييزُ الرفقِ من القسوةِ (ومن التمييعِ)", subskills=["rifq_nabra","rifq_hazm","rifq_fahs"],
   outcome_ar="يقولُ «هذا خطأٌ» بوضوحٍ وبعبارةٍ غيرِ جارحةٍ، ولا يغيّرُ الحكمَ ليكونَ لطيفًا.", scenarios=["S-09","S-05","S-06"]),
 dict(stage=4, title_ar="مواقفُ سهلةٌ (تطبيقٌ)", subskills=["rifq_ibara","rifq_tawqit","rifq_taysir","rifq_jahil"],
   outcome_ar="يفتحُ التصحيحَ بما يُقرِّبُ، ويقتصرُ على القدرِ الكافي.", scenarios=["S-01","S-03","S-07"]),
 dict(stage=5, title_ar="مواقفُ تحت الضغطِ", subskills=["rifq_nabra","rifq_istifzaz","rifq_hazm"],
   outcome_ar="تحت ضغطٍ واحدٍ على الأقلِّ، يختارُ الاستجابةَ الليّنةَ الكافيةَ.", scenarios=["S-06","S-09","S-04"]),
 dict(stage=6, title_ar="مواقفُ الخلافِ", subskills=["rifq_fahs","rifq_naqd_qawl","rifq_nush"],
   outcome_ar="يتثبّتُ قبل الإنكارِ، وينقدُ القولَ دون صاحبِه، ويحفظُ قدرَه.", scenarios=["S-05","S-10","S-08"]),
 dict(stage=7, title_ar="مواقفُ مركّبةٌ (اختبارٌ)", subskills=["rifq_hazm","rifq_nush","rifq_tawqit"],
   outcome_ar="في موقفٍ تتزاحمُ فيه فضيلتانِ، لا يُسقِطُ إحداهما باسمِ الأخرى؛ يبحثُ عن الجمعِ.", scenarios=["S-11","S-12","S-10"]),
]

SR = dict(unit="(user × subskill)", tracks=["K knowledge-recall","S scenario-recall","R behavioral-reflection"],
  intervals={"D1":"تعلّم + أوّل موقف","D2":"K","D4":"S","D7":"S+","D14":"R","D30":"S مركّب","D60":"K+S+R"},
  quality_map={"aqrab":5,"maqbul":3,"baid":1}, rule="quality<=1 → يُعاد قريبًا ولا تُرفَع الصعوبة")

# ---- TRANSLATIONS --------------------------------------------------------
# translation_type: literal (scholar/hadith words), pedagogical (app's own),
#   quran_meaning (from a licensed edition ONLY), term_gloss.
# translation_status: generated (by Claude, publishable in the primary pipeline).
# EN is the reference literal translation; FR added for evidence+principles;
# ur/id/tr/am marked pending (faithful literal translation of classical
# religious Arabic in those languages needs a dedicated pass).
TR = []
def tr(ref_kind, ref_id, layer, lang, ttype, text, status="generated", translator="مسودّة أوليّة — Claude", notes=""):
    TR.append(dict(ref_kind=ref_kind, ref_id=ref_id, layer=layer, lang=lang,
                   translation_type=ttype, text=text, translator=translator,
                   translation_status=status, notes=notes))

# --- evidence: literal EN + FR (Qur'an handled specially) ---
EV_EN = {
 "EV-01": '"O ʿĀʾisha, Allah is gentle (rafīq) and loves gentleness; He gives for gentleness what He does not give for harshness, and what He does not give for anything else."',
 "EV-02": '"Gentleness is not present in anything except that it adorns it, and it is not removed from anything except that it disgraces it."',
 "EV-03": '"Whoever is denied gentleness is denied good."',
 "EV-04": '"Make things easy and do not make them hard; calm [people] and do not drive them away." — and in a narration: "...and give glad tidings and do not drive [people] away."',
 "EV-05": 'When the Messenger of Allah ﷺ sent one of his Companions on some errand, he would say: "Give glad tidings and do not drive away; make things easy and do not make them hard."',
 "EV-06": 'A group of the Jews came to the Messenger of Allah ﷺ and said: "as-Sāmu ʿalaykum (death be upon you)." ʿĀʾisha said: I understood it, so I said: "Upon you be death and the curse." The Messenger of Allah ﷺ said: "Gently (mahlan), O ʿĀʾisha; take to gentleness, and beware of harshness and coarse speech." She said: Did you not hear what they said? He said: "Did you not hear what I said? I returned it upon them, so [my supplication] against them is answered and theirs against me is not."',
 "EV-07": 'From the Prophet ﷺ: "Overlook the slips of people of good standing (dhawī al-hayʾāt)."',
 "EV-08": '(Having spoken during the prayer out of ignorance of the prohibition, and the people having rebuked him with their glances) ... then he said: "By my father and mother, I have not seen a teacher before him or after him better in teaching than he; by Allah, he did not scold me (mā kaharanī) nor strike me nor revile me."',
 "EV-09": 'A bedouin stood up and urinated in the mosque, and the people rushed at him. The Prophet ﷺ said to them: "Leave him, and pour over his urine a bucket of water — or a large bucket of water — for you were sent to make things easy and you were not sent to make things hard."',
 "EV-10": 'Ibn Rajab said: "In every case, gentleness in censure (al-inkār) is required." He quoted Sufyān al-Thawrī: "None should enjoin good and forbid evil except one who has three traits: gentle in what he enjoins and gentle in what he forbids, just in what he enjoins and just in what he forbids, knowledgeable in what he enjoins and knowledgeable in what he forbids." And he quoted Imām Aḥmad: "People are in need of gentle handling (mudārāh)..."',
}
EV_FR = {
 "EV-01": '« Ô ʿĀʾisha, Allah est doux (rafīq) et aime la douceur ; Il donne pour la douceur ce qu\'Il ne donne pas pour la dureté, ni pour rien d\'autre. »',
 "EV-02": '« La douceur n\'est en aucune chose sans l\'embellir, et elle n\'est ôtée d\'aucune chose sans l\'enlaidir. »',
 "EV-03": '« Quiconque est privé de douceur est privé du bien. »',
 "EV-04": '« Facilitez et ne rendez pas difficile ; apaisez et ne faites pas fuir. » — et dans une version : « ...annoncez la bonne nouvelle et ne faites pas fuir. »',
 "EV-05": 'Lorsque le Messager d\'Allah ﷺ envoyait l\'un de ses Compagnons pour une affaire, il disait : « Annoncez la bonne nouvelle et ne faites pas fuir ; facilitez et ne rendez pas difficile. »',
 "EV-06": 'Un groupe de Juifs vint auprès du Messager d\'Allah ﷺ et dit : « as-Sāmu ʿalaykum (la mort sur vous) ». ʿĀʾisha dit : Je l\'ai compris et j\'ai répondu : « Sur vous la mort et la malédiction ». Le Messager d\'Allah ﷺ dit : « Doucement (mahlan), ô ʿĀʾisha ; adopte la douceur et garde-toi de la rudesse et de la grossièreté. » Elle dit : N\'as-tu pas entendu ce qu\'ils ont dit ? Il dit : « N\'as-tu pas entendu ce que j\'ai dit ? Je le leur ai retourné : ma [prière] contre eux est exaucée, et la leur contre moi ne l\'est pas. »',
 "EV-07": 'Du Prophète ﷺ : « Pardonnez leurs faux pas aux gens de bonne tenue (dhawī al-hayʾāt). »',
 "EV-08": '(Ayant parlé pendant la prière par ignorance de l\'interdiction, et les gens l\'ayant réprimandé du regard) ... puis il dit : « Par mon père et ma mère, je n\'ai pas vu de maître, avant lui ni après lui, meilleur enseignant que lui ; par Allah, il ne m\'a pas rudoyé (mā kaharanī), ni frappé, ni injurié. »',
 "EV-09": 'Un bédouin se leva et urina dans la mosquée ; les gens se précipitèrent sur lui. Le Prophète ﷺ leur dit : « Laissez-le, et versez sur son urine un seau d\'eau — ou un grand seau d\'eau — car vous avez été envoyés pour faciliter et non pour rendre difficile. »',
 "EV-10": 'Ibn Rajab a dit : « En tout état de cause, la douceur dans la réprobation (al-inkār) est requise. » Il cite Sufyān al-Thawrī : « Nul ne devrait ordonner le bien et interdire le mal sinon celui qui réunit trois qualités : doux dans ce qu\'il ordonne et doux dans ce qu\'il interdit, juste dans ce qu\'il ordonne et juste dans ce qu\'il interdit, savant dans ce qu\'il ordonne et savant dans ce qu\'il interdit. » Et il cite l\'imam Aḥmad : « Les gens ont besoin d\'être ménagés (mudārāh)... »',
}
EV_NOTES = {
 "EV-01": "«رفيق» rendered as 'gentle' with transliteration; the divine attribute is conveyed as it appears, without theological expansion.",
 "EV-06": "«مهلًا» = 'gently/slow down' (mahlan). «الفُحش» = coarse/obscene speech. «فيُستجاب لي فيهم» kept as a passive of answered supplication, not expanded.",
 "EV-08": "«كهر» = harsh scolding/rebuke (kahara); kept with transliteration. Negations «ما ... ولا ... ولا» preserved as a triple negation.",
 "EV-10": "«الإنكار» = censure / forbidding wrong; kept close, with transliteration. Sufyān's three-fold parallel structure preserved.",
}
# Amharic (Ismail is in Ethiopia, 2026-09-13 request: a real translation
# under the Arabic for every language, not just EN/FR). Evidence text
# translated literally from the Arabic hadith wording; EV-11 (Qur'an) uses
# the REAL bundled licensed Amharic Qur'an translation
# (assets/quran/tafsir-amharic_sadiq.jsonl.gz, QuranEnc.com / Sadiq and
# Sani) for 3:134, 7:199, 41:34 — never Claude-generated for Qur'an text.
EV_AM = {
 "EV-01": "«አኢሻ ሆይ! አላህ ገር ነው፤ ገርነትን ይወዳል፤ በገርነት ላይ የማይሰጠውን በጭካኔ ላይ ይሰጣል፤ በሌላ በማንኛውም ነገር ላይም የማይሰጠውን ይሰጣል።»",
 "EV-02": "«ገርነት በያዘው ነገር ሁሉ ውበት ይጨምራል፤ ከተወገደበት ነገር ሁሉም ውርደት ያመጣል።»",
 "EV-03": "«ገርነት የተከለከለ ሰው በጎውን ነገር ተከልክሏል።»",
 "EV-04": "«አቅልሉ እንጂ አታክብዱ፤ አረጋጉ እንጂ አታስፈሩ» — በሌላ ዘገባ፦ «...አብስሩ እንጂ አታስፈሩ።»",
 "EV-05": "የአላህ መልእክተኛ ﷺ ከባልደረቦቻቸው አንዱን በአንዳች ጉዳይ በላኩ ጊዜ፦ «አብስሩ እንጂ አታስፈሩ፤ አቅልሉ እንጂ አታክብዱ» ይሉ ነበር።",
 "EV-06": "ከአይሁድ የሆነ ጭፍራ ወደ አላህ መልእክተኛ ﷺ ገብተው፦ «አልሳሙ ዐለይኩም (ሞት በእናንተ ላይ ይሁን)» አሉ። ዓኢሻ፦ «ተረድቼውና፦ 'ዐለይኩሙ አልሳሙ ወአልለዕነህ' (ሞትና ርግማን በእናንተ ላይ ይሁን) አልኩ» አለች። የአላህ መልእክተኛ ﷺም፦ «ገር ሁኚ አኢሻ ሆይ፣ ገርነትን ያዢ፤ ከጭካኔና ከብልግና ተጠንቀቂ» አሉ። እርሷም፦ «የተናገሩትን አልሰማህም?» አለች። እርሳቸውም፦ «የተናገርኩትን አልሰማሽም? በእነርሱ ላይ መለስኩ፤ በእነርሱ ላይ የእኔ ጸሎት ይሰማል፤ በእኔ ላይ ግን የነርሱ አይሰማም» አሉ።",
 "EV-07": "ከነቢዩ ﷺ፦ «የመልካም ደረጃ ያላቸውን ሰዎች ስህተቶች ይቅር በሉ።»",
 "EV-08": "(በሶላት ውስጥ ክልከላውን ሳያውቅ ተናገረ፣ ሰዎችም በዓይናቸው ገሠጹት)... ከዚያም፦ «በአባቴና በእናቴ እምላለሁ፣ ከእርሳቸው በፊትም ሆነ በኋላ ከእርሳቸው የተሻለ አስተማሪ አላየሁም፤ በአላህ እምላለሁ፣ አልገሠጹኝም፣ አልመቱኝም፣ አልሰደቡኝም» አለ።",
 "EV-09": "አንድ በዱር የሚኖር ሰው ተነስቶ በመስጊድ ውስጥ ሸና፤ ሰዎችም ያዙት፤ ነቢዩ ﷺም፦ «ተውት፤ በሽንቱ ላይም አንድ ባልዲ ውሃ — ወይም ትልቅ ባልዲ ውሃ — አፍስሱ፤ እናንተ ለማቅለል የተላካችሁ እንጂ ለማክበድ አልተላካችሁም» አሉ።",
 "EV-10": "ኢብኑ ረጀብ፦ «በማንኛውም ሁኔታ በተግሣጽ ውስጥ ገርነት የግድ ነው» አሉ። ከሱፍያን አልሠውሪም፦ «በመልካም የሚያዝዝና ከመጥፎ የሚከለክል ሦስት ባህርያት ያለው ብቻ ነው፦ በሚያዝዘውም በሚከለክለውም ገር፣ በሚያዝዘውም በሚከለክለውም ፍትሓዊ፣ በሚያዝዘውም በሚከለክለውም አዋቂ» የሚለውን ጠቀሱ። ከኢማም አሕመድም፦ «ሰዎች ገር አያያዝ ያስፈልጋቸዋል...» የሚለውን ጠቀሱ።",
}
EV_AM_NOTES = {
 "EV-01": "«ረፊቅ» የሚለው የአላህ ስም እንደወረደ ተላልፏል፤ ያለ ተጨማሪ ትርጓሜ።",
 "EV-06": "«አልሳሙ» የሚለው የአይሁድ ሰላምታ ማጣመም (ሞት ማለት) እንደወረደ ተላልፏል።",
 "EV-08": "«ከህር» (ብርቱ ተግሣጽ) የሚለው ቃል በዐረብኛ ትርጉሙ ተጠብቆ ተላልፏል።",
}
EV_AM_QURAN_TEXT = {
 "EV-11": "3:134 — ለእነዚያ በድሎትም ኾነ በችግር ለሚለግሱት፣ ቁጭትንም ገቺዎች ከሰዎችም ይቅርታ አድራጊዎች ለኾኑት (ተደግሳለች)፡፡ አላህም በጎ ሠሪዎችን ይወዳል፡፡ · 7:199 — ገርን ጠባይ ያዝ፡፡ በመልካምም እዘዝ፡፡ ባለጌዎቹንም ተዋቸው፡፡ · 41:34 — መልካሚቱና ክፉይቱም (ጸባይ) አይተካከሉም፡፡ በዚያች እርሷ መልካም በኾነችው ጸባይ (መጥፎይቱን) ገፍትር፡፡ ያን ጊዜ ያ ባንተና በእርሱ መካከል ጠብ ያለው ሰው እርሱ ልክ እንደ አዛኝ ዘመድ ይኾናል፡፡",
}
for e in EV:
    if e["source_type"] == "quran":
        tr("evidence", e["id"], "text", "en", "quran_meaning",
           "[ترجمة معاني الآيات تُؤخَذ من إصدارٍ مُرخَّص عند التنفيذ — Āl ʿImrān 3:134, al-Aʿrāf 7:199, Fuṣṣilat 41:34. NOT generated here.]",
           status="pending", translator="(إصدار مُرخَّص — يُحدَّد لاحقًا)",
           notes="لا تُولَّد ترجمةٌ آليّةٌ للآيات. تُسمّى «ترجمة معاني الآية».")
        tr("evidence", e["id"], "text", "am", "quran_meaning", EV_AM_QURAN_TEXT[e["id"]],
           status="approved", translator="Sadiq and Sani — QuranEnc.com (real licensed Amharic Qur'an translation, already bundled)",
           notes="مأخوذةٌ حرفيًّا من assets/quran/tafsir-amharic_sadiq.jsonl.gz، لا مُولَّدة آليًّا لمعاني القرآن.")
        continue
    tr("evidence", e["id"], "text", "en", "literal", EV_EN[e["id"]], notes=EV_NOTES.get(e["id"], ""))
    tr("evidence", e["id"], "text", "fr", "literal", EV_FR[e["id"]])
    tr("evidence", e["id"], "text", "am", "literal", EV_AM[e["id"]], notes=EV_AM_NOTES.get(e["id"], ""))
    for lang in ("ur", "id", "tr"):
        tr("evidence", e["id"], "text", lang, "literal", "", status="pending",
           translator="—", notes="مسار جاهز؛ الترجمة الحرفيّة لهذه اللغة تحتاج تمريرةً مخصّصة.")

P_EN = {
 "P1": "Gentleness is a means of conveying the truth, not a substitute for it.",
 "P2": "When your tone hardens, the effect of your words decreases — even if you are right.",
 "P3": "Seeking gentleness is intended even when the situation is hard.",
 "P4": "Begin with what brings [people] closer, avoid what drives them away, and proceed gradually.",
 "P5": "Stating the truth remains; gentleness is choosing the lightest sufficient response — neither coarseness nor silent acquiescence.",
 "P6": "A passing slip from a person of good standing is overlooked, not tracked down.",
 "P7": "The ignorant person is taught, not scolded; there is no reproach against him for his ignorance.",
 "P8": "If rebuking now increases the harm, wait — then put it right and teach gently.",
 "P9": "No one should undertake censure except one who combines gentleness in method, justice in judgement, and knowledge of the matter.",
}
P_FR = {
 "P1": "La douceur est un moyen de transmettre la vérité, non un substitut à celle-ci.",
 "P2": "Quand ton ton se durcit, l\'effet de tes paroles diminue — même si tu as raison.",
 "P3": "Rechercher la douceur est visé même lorsque la situation est difficile.",
 "P4": "Commence par ce qui rapproche, évite ce qui fait fuir, et procède graduellement.",
 "P5": "L\'énoncé de la vérité demeure ; la douceur, c\'est choisir la réponse suffisante la plus légère — ni grossièreté ni acquiescement silencieux.",
 "P6": "Un faux pas passager d\'une personne de bonne tenue est pardonné, non traqué.",
 "P7": "L\'ignorant est instruit, non réprimandé ; il n\'y a pas de reproche contre lui pour son ignorance.",
 "P8": "Si réprimander maintenant accroît le mal, patiente — puis rectifie et enseigne avec douceur.",
 "P9": "Nul ne devrait entreprendre la réprobation sinon celui qui réunit la douceur dans la méthode, la justice dans le jugement et la connaissance du sujet.",
}
P_AM = {
 "P1": "ገርነት እውነትን ለማድረስ መንገድ ነው፤ ምትክ አይደለም።",
 "P2": "አነጋገርህ ሲጠነክር የቃልህ ተጽዕኖ ይቀንሳል፣ እውነት ቢሆንም እንኳ።",
 "P3": "ሁኔታው ሲከብድ እንኳ ገርነትን መፈለግ የታሰበ ነው።",
 "P4": "በሚያቀራርብ ነገር ጀምር፤ ከሚያርቅ ተቆጠብ፤ በደረጃ ደረጃ ሂድ።",
 "P5": "እውነትን ማብራራት ይቀራል፤ ገርነት ማለት በቂ የሆነውን ቀላል ምላሽ መምረጥ ነው፤ ብልግናም ዝምታም አይደለም።",
 "P6": "ከመልካም ሰዎች የሚደርስ ጊዜያዊ ስህተት ይታለፋል፣ አይከተልም።",
 "P7": "የማያውቀው ይማራል እንጂ አይገሠጽም፤ በድንቁርናውም አይወቀስም።",
 "P8": "አሁን መገሠጽህ ጉዳትን የሚጨምር ከሆነ ታገሥ፤ ከዚያም በገርነት አስተካክልና አስተምር።",
 "P9": "በተግሣጽ ላይ የሚግባው በዘዴው ገርነትን፣ በፍርዱ ፍትሕን፣ በጉዳዩም እውቀትን የሚያጣምር ብቻ ነው።",
}
for p in P:
    tr("principle", p["id"], "statement", "en", "pedagogical", P_EN[p["id"]])
    tr("principle", p["id"], "statement", "fr", "pedagogical", P_FR[p["id"]])
    tr("principle", p["id"], "statement", "am", "pedagogical", P_AM[p["id"]])

SUB_EN = {
 "rifq_ibara":"Choosing the gentlest sufficient wording to point out an error",
 "rifq_nabra":"Controlling tone of voice and body language when censuring",
 "rifq_tawqit":"Choosing the right time and place to correct (privately when possible)",
 "rifq_taysir":"Beginning with what brings closer before pointing out the error (easing, not repelling)",
 "rifq_fahs":"A prior self-check: am I knowledgeable? is my judgement just? is my method gentle?",
 "rifq_jahil":"Gentleness with the ignorant and the questioner: correcting without scolding or harshness",
 "rifq_la_taqta3":"Not cutting off a situation harshly when doing so increases the harm; putting it right afterward",
 "rifq_istifzaz":"Deliberately choosing gentleness under provocation (gentleness is a choice, not inability)",
 "rifq_hazm":"Combining firmness in substance with softness in style",
 "rifq_naqd_qawl":"Separating criticism of a statement from disparaging the person, while keeping the manners of censure",
 "rifq_nush":"Gentleness in advising: counsel, not public exposure",
 "rifq_mukarrir":"Gentleness with one who repeats a mistake: patience and gradualness without escalating harshness",
}
SUB_AM = {
 "rifq_ibara": "ስህተትን ለማስረዳት በቂ የሆነውን በጣም ገር አገላለጽ መምረጥ",
 "rifq_nabra": "ሲገሥጹ የድምጽ ቃናንና የሰውነት ቋንቋን መቆጣጠር",
 "rifq_tawqit": "ለማረም ተስማሚ ጊዜንና ቦታን መምረጥ (ከተቻለ በግል)",
 "rifq_taysir": "ስህተትን ከመግለጽ በፊት በሚያቀራርብ ነገር መጀመር (ማቅለል እንጂ ማራቅ አይደለም)",
 "rifq_fahs": "ቅድመ ምርመራ፦ አዋቂ ነኝ? ፍርዴ ፍትሓዊ ነው? ዘዴዬ ገር ነው?",
 "rifq_jahil": "ለማያውቀውና ለጠያቂው ገርነት፦ ያለ ተግሣጽና ያለ ጭካኔ ማረም",
 "rifq_la_taqta3": "መቋረጡ ጉዳትን የሚጨምር ከሆነ ሁኔታውን በጭካኔ አለማቋረጥ፤ ከዚያ በኋላ ማስተካከል",
 "rifq_istifzaz": "በቁጣ ጊዜ ሆን ብሎ ገርነትን መምረጥ (ገርነት ምርጫ ነው እንጂ አቅም ማጣት አይደለም)",
 "rifq_hazm": "በይዘት ጥብቅነትንና በዘዴ ገርነትን ማጣመር",
 "rifq_naqd_qawl": "የቃልን ትችት ከሰው ስድብ መለየት፣ የተግሣጽ ሥነ ምግባርን እየጠበቁ",
 "rifq_nush": "በምክር ውስጥ ገርነት፦ ምክር እንጂ ውርደት አይደለም",
 "rifq_mukarrir": "ስህተትን ከደጋገመ ሰው ጋር ገርነት፦ ትዕግስትና ደረጃ በደረጃ መሄድ ያለ እየጨመረ የሚሄድ ጭካኔ",
}
for sid, ar in SUBSKILLS:
    tr("subskill", sid, "title", "en", "pedagogical", SUB_EN[sid])
    tr("subskill", sid, "title", "am", "pedagogical", SUB_AM[sid])

# scenario stems + feedback in EN (proves a non-Arab user can train)
SC_EN_STEM = {
 "S-01":"In a lesson, a peer mentioned a matter and got it wrong; there is goodwill between you.",
 "S-02":"A week ago you pointed out an error to a student; today he repeated it in another gathering.",
 "S-03":"A recently-practising man asked, in a gathering, a question some attendees considered obvious, and some of them smiled.",
 "S-04":"You said something in a comment; someone understood it contrary to your intent and replied to you sharply in public.",
 "S-05":"A peer disagreed with you on a matter with two respected positions and held to his view politely.",
 "S-06":"In a public gathering, someone said, pointing at you: 'Some who put themselves forward to teach cannot read a line well.'",
 "S-07":"A student delivered a benefit before the study circle and attributed a statement to the wrong person. The error causes no urgent harm.",
 "S-08":"A peer conveyed your words, with a changed meaning, to a shaykh; you learned the shaykh understood you contrary to your intent.",
 "S-09":"Five minutes remain in the lesson. A student objected to your account of a matter you are certain is correct; his objection contains a misunderstanding.",
 "S-10":"You hosted a peer to study. He spoke of your father with an unintended slight, then spilled tea on a book lent to you by your shaykh.",
 "S-11":"In a circle, one student talks a great deal and interrupts others. If you advise him gently, some attendees will think you fear him; if you are harsh, the gathering breaks up.",
 "S-12":"Your shaykh erred in attributing a statement to an imam (the error is verified and carries no serious ruling). You are in his gathering, and a beginner student wrote the error in his notebook.",
}
# Full scenario content in EN: options (text+why), probe, feedback, reflection.
# Completes what the first pass deferred (Ismail, 2026-09-13: every AKHLAQ
# text needs a real translation under the Arabic, not just the UI chrome).
SC_EN_OPT = {
 "S-01": {
  "A": ("“How can you say this and you’re a student of knowledge?”",
        "Belittling and demeaning; the effect of the truth diminishes."),
  "B": ("You stay silent and leave it (you’re not in the mood for discussion).",
        "Withholding an easy clarification without excuse."),
  "C": ("“A benefit: the correct view on this matter is such-and-such, and the evidence is...” calmly.",
        "Gentle, sufficient clarification that separates the error from the person."),
  "D": ("You correct him sharply in front of everyone: “This is wrong, the correct view is...”",
        "The content is correct, but the manner disgraces and embarrasses."),
 },
 "S-02": {
  "A": ("“I told you once! Why don’t you remember?” with irritation.",
        "Escalating harshness with repetition."),
  "B": ("You correct calmly, in a different style from the first time, and ask yourself: was my explanation clear?",
        "Patience + changing style + self-review."),
  "C": ("You ignore it — the repetition is “his problem.”",
        "Withholding necessary clarification."),
  "D": ("You correct gently, then add a light sarcastic remark “so you won’t forget it again.”",
        "Gentleness tainted with a jab that weakens its effect."),
 },
 "S-03": {
  "A": ("“A fitting question; the matter has some detail...” then you explain.",
        "Welcome + explanation without rebuke (EV-08)."),
  "B": ("“This is well-known, read the book of purification first.”",
        "Harsh scolding and a referral that belittles."),
  "C": ("You answer curtly then walk away.",
        "Correct content, but no gentleness toward the questioner."),
  "D": ("You laugh along with those present out of courtesy, then answer.",
        "Participating in embarrassing the questioner."),
 },
 "S-04": {
  "A": ("“If you had read carefully you would have understood; but haste is a habit of yours.”",
        "Defending yourself + shifting to attacking the person."),
  "B": ("“I mean such-and-such, because of such-and-such indication, not what you understood. Thanks for pointing it out.”",
        "Clarifying the truth with the lightest response, without being drawn in (EV-06)."),
  "C": ("You delete the comment and withdraw.",
        "You are safe from harm but you forgo a possible harmless clarification."),
  "D": ("“Your words are a blatant misunderstanding” without explanation.",
        "Establishing the truth in a humiliating form."),
 },
 "S-05": {
  "A": ("“Your view is weak and abandoned” and you cut off the discussion.",
        "Declaring error in a matter of legitimate disagreement + a harsh cutoff."),
  "B": ("“The matter has two views; I prefer such-and-such for such-and-such evidence, and your view has a basis.”",
        "Fairness + stating the preferred view without declaring the opponent wrong (EV-10)."),
  "C": ("You flatter him “your words are lovely” and withhold stating what you consider preferable.",
        "Gentleness that squanders stating what you believe is correct."),
  "D": ("You stay silent because you dislike him and don’t want to flatter him.",
        "The motive is personal, not scholarly."),
 },
 "S-06": {
  "A": ("“And you haven’t read a single complete book in your life.”",
        "Meeting obscenity with obscenity (against EV-06)."),
  "B": ("“If you have a specific scholarly remark, I’m listening” calmly, then you continue.",
        "Composure + a response for the truth without being drawn in, preserving your standing."),
  "C": ("You stay silent, show irritation, and leave the gathering.",
        "You avoid a clash, but the sulky withdrawal carries a trace of anger."),
  "D": ("“May Allah forgive you” in a sarcastic tone.",
        "A form of pardon whose surface is gentle but whose core is a jab."),
 },
 "S-07": {
  "A": ("You interrupt him immediately “that is not so.”",
        "Correct, but immediate publicity embarrasses unnecessarily."),
  "B": ("You let him finish, then privately: “your benefit is useful; and the correct attribution is such-and-such.”",
        "Covering + timing that preserves dignity (EV-06, EV-09)."),
  "C": ("You write the error in the circle’s public group so everyone notices.",
        "A “piece of advice” made public = exposure."),
  "D": ("You leave it without any remark at all.",
        "Covering is good, but leaving it wholly unaddressed lets the error stand."),
 },
 "S-08": {
  "A": ("You publish a public clarification naming your peer and describing him as distorting.",
        "Establishing a right in a way that discredits the person and exposes him."),
  "B": ("You clarify your intent to the shaykh directly, and rebuke your peer privately without belittling.",
        "Preserving the truth + a gentle, private rebuke (EV-10, EV-11 “repel with that which is better”)."),
  "C": ("You stay completely silent to preserve “gentleness.”",
        "Weakness, not gentleness; a wrong understanding of you remains."),
  "D": ("You cut off your peer and show him coldness without telling him why.",
        "Punishment without explanation, motivated by defending yourself."),
 },
 "S-09": {
  "A": ("“This is not up for discussion, the matter is clear” and you end it.",
        "Firmness phrased in a humiliating way; certainty of the truth does not permit harshness (EV-02)."),
  "B": ("“Your question matters; time is short, let’s continue it at the start of next lesson — and briefly: my point is such-and-such.”",
        "Gentleness + a promise to continue + a hint at the correct view."),
  "C": ("You enter a long discussion that overruns the time to defeat him.",
        "The motive is to overwhelm him, and it violates the rights of the rest of those present."),
  "D": ("“Your words are wrong” curtly, then you leave.",
        "Correct in ruling, harsh in manner and timing."),
 },
 "S-10": {
  "A": ("You react to the remark about your father and neglect the matter of the book, and you make him feel coldness for the rest of the session.",
        "An unbalanced reaction, and neglect of another right."),
  "B": ("You continue the hospitality, and at a suitable moment you gently point out the error of the remark, and reassure him the matter of the book is minor while you honestly handle fixing it with the shaykh.",
        "Balance: hosting etiquette + gentle correction of the remark + honestly handling the book’s right, without downplaying it."),
  "C": ("You overlook everything and mention nothing to preserve the friendship, and you tell the shaykh the book “got damaged with you” without detail.",
        "Gentleness that sacrifices honesty regarding the shaykh’s right and the remark’s right."),
  "D": ("You rebuke him firmly about the remark and the book immediately, in words containing reproach.",
        "The content is obligatory, but immediate reproach of a guest disgraces and could be deferred."),
 },
 "S-11": {
  "A": ("You are harsh with him publicly to prove you “don’t fear him.”",
        "A motive of self-display, and it breaks up the gathering."),
  "B": ("You organize the turn-taking gently and firmly for everyone, “let’s hear so-and-so, then so-and-so,” and you advise him privately after the gathering.",
        "Firmness in the procedure + gentleness in wording + private advice (EV-10, EV-11)."),
  "C": ("You let him monopolize the talk to avoid embarrassment.",
        "Weakness in the name of gentleness, and injustice to the rest of the students."),
  "D": ("You jab him with a clever remark that makes the gathering laugh at his expense.",
        "“Firmness” through veiled insult."),
 },
 "S-12": {
  "A": ("You correct the shaykh directly in front of the gathering: “May Allah reward you well, the statement belongs to so-and-so, not so-and-so.”",
        "The content is correct and preventing the error from spreading is intended, but publicity with the shaykh needs something gentler, and a hint might suffice."),
  "B": ("You stay completely silent out of respect for the shaykh, and leave the beginner in his error.",
        "Respect does not permit letting a spreading error stand."),
  "C": ("You hint politely in the gathering “perhaps I am mistaken, isn’t this statement attributed to so-and-so?”, and after the gathering you privately review it with the shaykh, and privately alert the beginner.",
        "Combines: respect for the shaykh + stating the truth in the gentlest form + stopping the error’s spread to the beginner privately."),
  "D": ("You wait until the gathering ends and correct only the beginner, leaving the shaykh be.",
        "Preserves the beginner, but leaves the error standing with the rest who heard it."),
 },
}
SC_EN_PROBE = {
 "S-01": "If you chose (A) or (D) — was the motive to clarify the truth, or not to appear lesser than him?",
 "S-02": "Did you get angry at his repetition, or did you review your teaching method?",
 "S-03": "When you were asked an easy question — did you make the questioner feel his weakness?",
 "S-04": "What moved you first: correcting the understanding, or that he “overstepped with you”?",
 "S-05": "Was my stance toward his view because it is wrong, or because it is his?",
 "S-06": "When you responded — was my response for the truth or for myself?",
 "S-07": "Could I have said it to him privately?",
 "S-08": "My first wish: correcting the picture with the shaykh, or punishing my peer?",
 "S-09": "When you were certain — did you increase in gentleness or harshness?",
 "S-10": "Which right was I inclined to drop for the sake of “not causing embarrassment”?",
 "S-11": "Was my concern fixing the gathering, or my image before those present?",
 "S-12": "What did I fear more: that the error would remain, or that I would appear to be “correcting my shaykh” before people?",
}
SC_EN_FEEDBACK = {
 "S-01": "The closest is (C): gentle wording + clarification + evidence, without belittling. (D) is correct but disgraces the situation (EV-02). (A) is belittling. (B) is withholding.",
 "S-02": "The closest is (B). Repetition does not permit harshness (measured against EV-03), and the flaw may be in the clarity of your earlier explanation [TARBAWI].",
 "S-03": "The closest is (A): “he did not scold me, nor strike me, nor revile me” (EV-08) — the question is welcomed, then explained.",
 "S-04": "The closest is (B): clarifying the intent + a word of thanks ends the tension — a response for the truth, not for yourself (EV-03, EV-06).",
 "S-05": "The closest is (B): “just in what he forbids” (EV-10); a matter of legitimate disagreement should not have one side declared “the error.”",
 "S-06": "The closest is (B): “Gently... hold to gentleness and beware of harshness and coarse speech” (EV-06). Gentleness here is a choice despite your ability to respond, not an inability.",
 "S-07": "The closest is (B): combining the correction (so the error doesn’t remain) with covering (choosing the time and place).",
 "S-08": "The closest is (B): “repel with that which is better” (EV-11) — you fix the understanding and rebuke privately. Silence here is weakness, not gentleness.",
 "S-09": "The closest is (B): certainty of the truth is the most dangerous place to abandon gentleness — “it is not removed from anything except that it disgraces it” (EV-02). Firm in content, gentle in wording.",
 "S-10": "The closest is (B): the situation combines competing virtues — gentleness does not cancel your father’s right nor honesty regarding the shaykh’s right (EV-06, EV-10). Do not downplay the book’s matter with a lie in the name of gentleness.",
 "S-11": "The closest is (B): firmness belongs in the procedure (organizing turns), and gentleness in the wording; what people think is not the measure of what is correct.",
 "S-12": "The closest is (C): level eight = balancing competing virtues. Gentleness here is the form of hinting, not abandoning the correction; respecting the shaykh publicly, and addressing it with him privately (EV-06, EV-10, EV-11).",
}
SC_EN_REFLECTION = {
 "S-01": "The last time you corrected someone — did you begin with the benefit or with blaming?",
 "S-02": "Did you get angry at his repetition, or did you review your teaching?",
 "S-03": "The next time you were asked another easy question — did you make the questioner feel his weakness?",
 "S-04": "When you were provoked — did you respond for the truth or for yourself?",
 "S-05": "Was my stance toward his view because it is wrong, or because it is his?",
 "S-06": "Did the trace of provocation remain in me after the gathering ended?",
 "S-07": "Could I have said it to him privately?",
 "S-08": "My first wish: correcting the picture, or punishing my peer?",
 "S-09": "When you were certain — did you increase in gentleness or harshness?",
 "S-10": "Did I use “gentleness” as a cover for dropping a difficult right?",
 "S-11": "Was my concern fixing the gathering, or my image?",
 "S-12": "Did I prioritize my image, or respect for the shaykh, or the truth? And could they have been combined?",
}
for s in S:
    tr("scenario", s["id"], "stem", "en", "pedagogical", SC_EN_STEM[s["id"]])
    for o in s["options"]:
        key = o["ord"]
        text, why = SC_EN_OPT[s["id"]][key]
        tr("scenario_option", f"{s['id']}:{key}", "text", "en", "pedagogical", text)
        tr("scenario_option", f"{s['id']}:{key}", "why", "en", "pedagogical", why)
    tr("scenario", s["id"], "probe", "en", "pedagogical", SC_EN_PROBE[s["id"]])
    tr("scenario", s["id"], "feedback", "en", "pedagogical", SC_EN_FEEDBACK[s["id"]])
    tr("scenario", s["id"], "reflection", "en", "pedagogical", SC_EN_REFLECTION[s["id"]])

tr("virtue", "rifq", "title", "en", "pedagogical", "Gentleness (Rifq)")
tr("virtue", "rifq", "title", "am", "pedagogical", "ገርነት (ሪፍቅ)")

CUR_EN = {
 1:"Distinguishes between 'abandoning the truth' and 'softening the style'; cites an example from his day.",
 2:"When provoked, responds for the truth not for himself, and does not meet coarseness with coarseness.",
 3:"Says 'this is an error' clearly and in non-wounding words, and does not change the ruling to be polite.",
 4:"Opens the correction with what brings closer, and limits himself to what is sufficient.",
 5:"Under at least one pressure, chooses the sufficient gentle response.",
 6:"Verifies before censuring, criticises the statement not its author, and preserves his standing.",
 7:"In a situation where two virtues compete, does not drop one in the name of the other; seeks to combine them.",
}
CUR_AM = {
 1: "በ«እውነትን መተው» እና «ዘዴን ማለስለስ» መካከል ይለያል፤ ከዕለቱ ምሳሌ ይጠቅሳል።",
 2: "ሲቆጣ ለራሱ ሳይሆን ለእውነት ይመልሳል፤ ብልግናንም አይመልስም።",
 3: "«ይህ ስህተት ነው» ብሎ በግልጽና በማይጎዳ አገላለጽ ይናገራል፤ ገር ለመሆንም ፍርዱን አይለውጥም።",
 4: "ማረምን በሚያቀራርብ ነገር ይከፍታል፤ በበቂው መጠንም ይወሰናል።",
 5: "ቢያንስ በአንድ ጫና ውስጥ በቂውን ገር ምላሽ ይመርጣል።",
 6: "ከመገሠጹ በፊት ያረጋግጣል፤ ቃሉን እንጂ ባለቤቱን አይተችም፤ ክብሩንም ይጠብቃል።",
 7: "ሁለት በጎ ምግባራት በሚጋጩበት ሁኔታ አንዱን በሌላው ስም አይተውም፤ ማጣመርን ይፈልጋል።",
}
for c in CURRICULUM:
    tr("stage", str(c["stage"]), "outcome", "en", "pedagogical", CUR_EN[c["stage"]])
    tr("stage", str(c["stage"]), "outcome", "am", "pedagogical", CUR_AM[c["stage"]])

# term glosses
GLOSS = [
 ("rifq","rifq","الرِّفق","en","gentleness / mildness of manner; the opposite of ʿunf (harshness) and khurq (clumsy roughness)."),
 ("unf","unf","العُنف","en","harshness / roughness in word or deed; the opposite of rifq."),
 ("kahr","kahr","الكَهْر","en","harsh scolding or rebuke; to rebuff someone sternly."),
 ("mudarah","mudārāh","المُداراة","en","gentle handling / tactful management of people, without compromising religion."),
 ("dhawu_l_hayat","dhawū al-hayʾāt","ذوو الهيئات","en","people of good standing and dignity, known for uprightness."),
 ("inkar","inkār","الإنكار","en","censure; forbidding a wrong / objecting to it."),
]
GLOSS_AM = {
 "rifq": "ገርነት (ሪፍቅ) — የባህርይ ልስላሴ፤ ተቃራኒው ዑንፍ (ጭካኔ) ነው።",
 "unf": "ጭካኔ (ዑንፍ) — በንግግር ወይም በተግባር ያለ ጭካኔ፤ ተቃራኒው ሪፍቅ (ገርነት) ነው።",
 "kahr": "ብርቱ ተግሣጽ (ከህር) — በጥብቅ መገሠጽ ወይም ሰውን በሐይል መመለስ።",
 "mudarah": "ገር አያያዝ (ሙዳራህ) — ሃይማኖትን ሳይነካ ሰዎችን በዘዴ ማስተናገድ።",
 "dhawu_l_hayat": "የመልካም ደረጃ ሰዎች (ዘዉ አልሀይኣት) — በቅንነትና በታማኝነት የሚታወቁ ሰዎች።",
 "inkar": "ተግሣጽ (ኢንካር) — መጥፎን መከልከል ወይም መቃወም።",
}
for gid, translit, ar, lang, text in GLOSS:
    TR.append(dict(ref_kind="term_gloss", ref_id=gid, layer="gloss", lang=lang,
                   translation_type="term_gloss", text=f"{ar} ({translit}) — {text}",
                   translator="مسودّة أوليّة — Claude", translation_status="generated", notes=""))
    TR.append(dict(ref_kind="term_gloss", ref_id=gid, layer="gloss", lang="am",
                   translation_type="term_gloss", text=GLOSS_AM[gid],
                   translator="مسودّة أوليّة — Claude", translation_status="generated", notes=""))

# ---- assemble ----------------------------------------------------------------
doc = dict(
  slice="al-rifq", virtue=dict(slug="rifq", title_ar="الرِّفق", domain="rel_people",
     opposite="العُنف/الغلظة", strengthened_by=["الحلم","الصبر"], leads_to=["العفو"],
     tension_with=["الغيرة على الحقّ"]),
  policy=dict(pipeline="Source-grounded automated validation",
     human_review="optional future layer — not a gate",
     source_status_values=["source_confirmed","source_located","source_uncertain","weak","disputed"],
     translation_status_values=["generated","machine_assisted","human_reviewed","approved"]),
  evidence=EV,
  principles=[dict(id=p["id"], subskill=p["subskill"], statement_ar=p["statement_ar"],
     interpretation_by="منهج التطبيق التربوي", evidence=p["evidence"]) for p in P],
  subskills=[dict(slug=s, title_ar=t) for s, t in SUBSKILLS],
  behaviors=[dict(id=b[0], subskill=b[1], text_ar=b[2], basis=b[3]) for b in B],
  scenarios=S,
  curriculum=CURRICULUM,
  spaced_repetition=SR,
  translations=TR,
)

io.open(OUT, "w", encoding="utf-8", newline="\n").write(json.dumps(doc, ensure_ascii=False, indent=1))
n_tr_gen = sum(1 for t in TR if t["translation_status"] == "generated")
n_tr_pend = sum(1 for t in TR if t["translation_status"] == "pending")
print(f"wrote {OUT}")
print(f"evidence={len(EV)} principles={len(P)} subskills={len(SUBSKILLS)} behaviors={len(B)} "
      f"scenarios={len(S)} stages={len(CURRICULUM)}")
print(f"translations: {len(TR)} rows  (generated={n_tr_gen}, pending={n_tr_pend})")
