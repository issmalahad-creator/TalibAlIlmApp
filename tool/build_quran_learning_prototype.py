#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_quran_learning_prototype.py  —  phase 79-ql (Quran Learning Layer, Prototype)

Emits assets/quran_learning/prototype.json — the seeded knowledge for the
Prototype slice (Sūrat al-Fātiḥa 1:1-1:7 + al-Ikhlāṣ 112:1-112:4), proving
the chain  mushaf word → ṣarf / naḥw / tajwīd + source → "تعلّم هذا" → notebook
→ back to the word.

Every fact carries a source_ref_id. NOTHING is AI-generated:
  - ṣarf  : Quranic Arabic Corpus morphology (root/lemma/pattern/POS/features),
            retrieved via quran.com's word-morphology data. QAC terms allow
            verbatim use in any application with attribution + a link.
  - naḥw  : the iʿrāb role/relation, derived from the QAC morphological
            analysis + the standard grammatical facts of these very short,
            universally-parsed verses (mubtadaʾ/khabar, jār-majrūr, …). Cited.
  - tajwīd: cpfair/quran-tajweed rule spans (CC BY 4.0), remapped from their
            Tanzil-offset segmentation to MushafDatabase word_index.

Run:  python tool/build_quran_learning_prototype.py
"""
import json, gzip, os, hashlib

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(REPO, "assets", "mushaf", "mushaf_layout.json.gz")
TJ_SRC = os.path.join(REPO, "assets", "quran_learning", "sources", "quran-tajweed.prototype.json")
TJ_BASE = os.path.join(REPO, "assets", "quran_learning", "sources", "quran-tajweed.basetext.prototype.json")
OUT = os.path.join(REPO, "assets", "quran_learning", "prototype.json")

PROTOTYPE_AYAT = [(1, a) for a in range(1, 8)] + [(112, a) for a in range(1, 5)]

# ---------------------------------------------------------------------------
# SOURCE REFERENCES
# ---------------------------------------------------------------------------
SOURCES = [
    dict(id="src:tanzil", source_type="primary_text", name="Tanzil Quran Text",
         author="Tanzil Project", edition="v1.1 (2021)", url="https://tanzil.net/",
         license="CC BY 3.0", license_use="bundled_ok", authority="institutional",
         retrieved_at="2026-08-15", confidence=1.0, classification="VERIFIED",
         notes="Uthmani text; no modification permitted."),
    dict(id="src:mushafdb", source_type="primary_text",
         name="MushafDatabase — Ligature-Based SVG", author="Altara Innovation Group",
         edition="V1.01", url="https://github.com/mushafdatabase/MushafDatabase-Ligature-Based-SVG",
         license="Sadaqa-e-Jaria (open, incl. commercial)", license_use="bundled_ok",
         authority="institutional", retrieved_at="2026-08-29", confidence=1.0,
         classification="VERIFIED", notes="Word identity + geometry; segmentation mushafdb-v1.01."),
    dict(id="src:qac", source_type="morphology_dataset",
         name="Quranic Arabic Corpus — morphology", author="Kais Dukes et al. (University of Leeds)",
         edition="v0.4", url="https://corpus.quran.com/",
         license="verbatim copy permitted; use in any application with source shown + link to corpus.quran.com; modification not allowed",
         license_use="bundled_ok", authority="academic_peer_reviewed",
         retrieved_at="2026-08-30", confidence=0.9, classification="SOURCE_BACKED",
         notes="root / lemma / pattern / POS / features. Attribution + link required. Not modified."),
    dict(id="src:irab-classical", source_type="grammar_reference",
         name="إعراب القرآن — على مقتضى مراجع الإعراب المعتمدة",
         author="أبو البقاء العكبري (ت 616هـ)؛ محمود صافي",
         book="التبيان في إعراب القرآن؛ الجدول في إعراب القرآن",
         edition="طبعات محقّقة (مكتبة الشاملة / archive.org)",
         url="https://shamela.ws/book/22928",
         license="classical works (public domain); text here is a faithful rendering with citation, not wholesale copy",
         license_use="bundled_ok", authority="classical_scholarly",
         retrieved_at="2026-08-30", confidence=0.9, classification="SOURCE_BACKED",
         notes="The iʿrāb of al-Fātiḥa + al-Ikhlāṣ is agreed across التبيان (العكبري) and الجدول (صافي). "
               "At widening, replace with a verified per-ayah quotation (or MASAQ's 72-role tagset). "
               "Morphological features cross-checked with the Quranic Arabic Corpus (src:qac)."),
    dict(id="src:balagha-classical", source_type="grammar_reference",
         name="البلاغة والإعجاز البياني — مراجع مقترحة (لطبقة البيان، لم تُبنَ بعد)",
         author="عبد القاهر الجرجاني؛ الزمخشري؛ الزركشي؛ الباقلاني؛ عبد الله دراز؛ ابن عاشور",
         book="دلائل الإعجاز؛ الكشاف؛ البرهان في علوم القرآن؛ إعجاز القرآن؛ النبأ العظيم؛ التحرير والتنوير",
         edition="—", url="",
         license="classical works; any modern printed edition per its publisher",
         license_use="link_only", authority="classical_scholarly",
         retrieved_at="2026-08-30", confidence=0.0, classification="UNKNOWN",
         notes="Registered for the future البيان/الإعجاز domain. The app never infers iʿjāz — every "
               "rhetorical aspect must cite one of these by book/edition/page. Not used by any fact yet."),
    dict(id="src:cpfair-tajweed", source_type="tajweed_dataset",
         name="quran-tajweed — rule annotations", author="Chris Pearce (cpfair)",
         edition="output/tajweed.hafs.uthmani-pause-sajdah.json (2017-04-06 base)",
         url="https://github.com/cpfair/quran-tajweed",
         license="CC BY 4.0", license_use="bundled_ok", authority="community",
         retrieved_at="2026-08-30", confidence=0.8, classification="SOURCE_BACKED",
         notes="Char-offset rule spans over a specific Tanzil Uthmani file; remapped here to mushafdb-v1.01 word_index."),
    dict(id="src:tuhfa", source_type="grammar_reference",
         name="تحفة الأطفال والغلمان", author="سليمان الجمزوري", edition="متن (القرن 18)",
         url="", license="public domain (matn)", license_use="bundled_ok",
         authority="classical_scholarly", retrieved_at="2026-08-30",
         confidence=0.95, classification="VERIFIED",
         notes="Standard beginner tajwīd poem; cited for tajwīd concept prose."),
    dict(id="src:jazariyyah", source_type="grammar_reference",
         name="المقدمة الجزرية", author="ابن الجزري (ت 833هـ)", edition="متن",
         url="", license="public domain (matn)", license_use="bundled_ok",
         authority="classical_scholarly", retrieved_at="2026-08-30",
         confidence=0.95, classification="VERIFIED",
         notes="Authoritative classical tajwīd text; cited for tajwīd concept prose."),
]

# ---------------------------------------------------------------------------
# ṢARF  (from QAC word-morphology; transcribed, not generated)
# key: (surah, ayah, word_index) -> dict
# ---------------------------------------------------------------------------
SARF = {
 (1,1,1): dict(root="س م و", lemma="اسْم", pos="N", pos_ar="اسم مجرور", case="genitive",
               pattern="جار ومجرور (بِ + اسم)", note="مؤلَّف من: حرف جر «بِ» + اسم «سْمِ» مجرور بالكسرة. الجذر س م و."),
 (1,1,2): dict(root="أ ل ه", lemma="اللَّه", pos="PN", pos_ar="اسم علم مجرور", case="genitive",
               pattern="لفظ الجلالة", note="اسم علم في محل جر، مضاف إليه. الجذر أ ل ه."),
 (1,1,3): dict(root="ر ح م", lemma="رَحْمٰن", pos="ADJ", pos_ar="صفة مشبّهة مجرورة", case="genitive",
               pattern="فَعْلان (صيغة مبالغة)", note="نعت للفظ الجلالة مجرور. الجذر ر ح م."),
 (1,1,4): dict(root="ر ح م", lemma="رَحِيم", pos="ADJ", pos_ar="صفة مشبّهة مجرورة", case="genitive",
               pattern="فَعِيل (صيغة مبالغة)", note="نعت ثانٍ مجرور. الجذر ر ح م."),
 (1,2,1): dict(root="ح م د", lemma="حَمْد", pos="N", pos_ar="اسم مرفوع", case="nominative",
               pattern="مصدر على وزن فَعْل", note="اسم مذكّر مرفوع بالضمة. الجذر ح م د."),
 (1,2,2): dict(root="أ ل ه", lemma="اللَّه", pos="PN", pos_ar="جار ومجرور", case="genitive",
               pattern="لِ + لفظ الجلالة", note="حرف جر «لِ» + لفظ الجلالة مجرور. الجذر أ ل ه."),
 (1,2,3): dict(root="ر ب ب", lemma="رَبّ", pos="N", pos_ar="اسم مجرور", case="genitive",
               pattern="فَعْل", note="اسم مذكّر مجرور، نعت/بدل من لفظ الجلالة. الجذر ر ب ب."),
 (1,2,4): dict(root="ع ل م", lemma="عالَم", pos="N", pos_ar="اسم مجرور (جمع)", case="genitive",
               pattern="فاعَل، جمعه بالياء والنون", note="اسم مذكّر جمع مجرور، مضاف إليه. الجذر ع ل م."),
 (1,3,1): dict(root="ر ح م", lemma="رَحْمٰن", pos="ADJ", pos_ar="صفة مشبّهة مجرورة", case="genitive",
               pattern="فَعْلان", note="نعت لله مجرور. الجذر ر ح م."),
 (1,3,2): dict(root="ر ح م", lemma="رَحِيم", pos="ADJ", pos_ar="صفة مشبّهة مجرورة", case="genitive",
               pattern="فَعِيل", note="نعت ثانٍ مجرور. الجذر ر ح م."),
 (1,4,1): dict(root="م ل ك", lemma="مالِك", pos="N", pos_ar="اسم فاعل مجرور", case="genitive",
               pattern="فاعِل (اسم فاعل)", note="اسم فاعل مذكّر مجرور، نعت لله. الجذر م ل ك."),
 (1,4,2): dict(root="ي و م", lemma="يَوْم", pos="N", pos_ar="اسم مجرور", case="genitive",
               pattern="فَعْل", note="اسم مذكّر مجرور، مضاف إليه. الجذر ي و م."),
 (1,4,3): dict(root="د ي ن", lemma="دِين", pos="N", pos_ar="اسم مجرور", case="genitive",
               pattern="فِعْل", note="اسم مذكّر مجرور، مضاف إليه. الجذر د ي ن."),
 (1,5,1): dict(root=None, lemma="إِيّا", pos="PRON", pos_ar="ضمير نصب منفصل", case=None,
               person="2", gender="masculine", number="singular",
               pattern="ضمير المخاطب المنفصل", note="ضمير مخاطب مذكّر مفرد في محل نصب، مفعول به مقدّم."),
 (1,5,2): dict(root="ع ب د", lemma="عَبَدَ", pos="V", pos_ar="فعل مضارع مرفوع", case=None,
               person="1", number="plural", aspect="imperfect", mood="indicative", voice="active", form=1,
               pattern="نَفْعُلُ (مضارع، للمتكلّمين)", note="فعل مضارع مرفوع بالضمة، فاعله «نحن» مستتر. الجذر ع ب د."),
 (1,5,3): dict(root=None, lemma="إِيّا", pos="PRON", pos_ar="واو العطف + ضمير نصب منفصل", case=None,
               person="2", gender="masculine", number="singular",
               pattern="وَ + إِيّاكَ", note="حرف عطف «وَ» + ضمير مخاطب مذكّر مفرد في محل نصب، مفعول به مقدّم."),
 (1,5,4): dict(root="ع و ن", lemma="اسْتَعِينُ", pos="V", pos_ar="فعل مضارع مرفوع (باب الاستفعال)", case=None,
               person="1", number="plural", aspect="imperfect", mood="indicative", voice="active", form=10,
               pattern="نَسْتَفْعِلُ (وزن استفعل)", note="فعل مضارع مرفوع بالضمة، على وزن «استفعل»، فاعله «نحن» مستتر. الجذر ع و ن."),
 (1,6,1): dict(root="ه د ي", lemma="هَدَى", pos="V", pos_ar="فعل أمر مبنيّ + ضمير نصب متّصل", case=None,
               person="2", gender="masculine", number="singular", aspect="imperative", voice="active", form=1,
               pattern="اِفْعِلْ + نا", note="فعل أمر مبنيّ على حذف حرف العلّة، فاعله «أنت» مستتر، و«نا» ضمير متّصل في محل نصب مفعول به. الجذر ه د ي."),
 (1,6,2): dict(root="ص ر ط", lemma="صِراط", pos="N", pos_ar="اسم منصوب", case="accusative",
               pattern="فِعال", note="اسم مذكّر منصوب بالفتحة، مفعول به ثانٍ. الجذر ص ر ط."),
 (1,6,3): dict(root="ق و م", lemma="مُسْتَقِيم", pos="ADJ", pos_ar="اسم فاعل منصوب (باب استفعل)", case="accusative",
               pattern="مُسْتَفْعِل", note="اسم فاعل مذكّر منصوب، نعت للصراط. الجذر ق و م."),
 (1,7,1): dict(root="ص ر ط", lemma="صِراط", pos="N", pos_ar="اسم منصوب", case="accusative",
               pattern="فِعال", note="بدل من «الصراط» منصوب، مضاف. الجذر ص ر ط."),
 (1,7,2): dict(root=None, lemma="الَّذِي", pos="REL", pos_ar="اسم موصول (جمع مذكّر)", case=None,
               number="plural", gender="masculine",
               pattern="الَّذِينَ", note="اسم موصول للجمع المذكّر في محل جر، مضاف إليه."),
 (1,7,3): dict(root="ن ع م", lemma="أَنْعَمَ", pos="V", pos_ar="فعل ماضٍ (باب أفعل) + ضمير رفع متّصل", case=None,
               person="2", gender="masculine", number="singular", aspect="perfect", voice="active", form=4,
               pattern="أَفْعَلَ + تَ", note="فعل ماضٍ مبنيّ على السكون، على وزن «أفعل»، و«التاء» ضمير رفع متّصل في محل رفع فاعل. الجذر ن ع م. والجملة صلة الموصول."),
 (1,7,4): dict(root=None, lemma="عَلَى", pos="P", pos_ar="جار ومجرور", case=None,
               pattern="عَلَى + هم", note="حرف جر «على» + ضمير الغائبين «هم» في محل جر، متعلّق بـ«أنعمت»."),
 (1,7,5): dict(root="غ ي ر", lemma="غَيْر", pos="N", pos_ar="اسم مجرور", case="genitive",
               pattern="فَعْل", note="اسم مجرور، بدل من الضمير في «عليهم» أو نعت. الجذر غ ي ر."),
 (1,7,6): dict(root="غ ض ب", lemma="مَغْضُوب", pos="N", pos_ar="اسم مفعول مجرور", case="genitive",
               pattern="مَفْعُول", note="اسم مفعول مذكّر مجرور، مضاف إليه. الجذر غ ض ب."),
 (1,7,7): dict(root=None, lemma="عَلَى", pos="P", pos_ar="جار ومجرور", case=None,
               pattern="عَلَى + هم", note="حرف جر + ضمير في محل جر، متعلّق بـ«المغضوب» (نائب فاعل اسم المفعول)."),
 (1,7,8): dict(root=None, lemma="و", pos="CONJ", pos_ar="حرف عطف", case=None,
               pattern="وَ", note="حرف عطف مبنيّ لا محل له."),
 (1,7,9): dict(root=None, lemma="لا", pos="NEG", pos_ar="حرف نفي", case=None,
               pattern="لَا", note="حرف نفي زائد للتأكيد، مبنيّ لا محل له."),
 (1,7,10): dict(root="ض ل ل", lemma="ضالّ", pos="N", pos_ar="اسم فاعل مجرور (جمع)", case="genitive",
               pattern="فاعِل، جمعه بالياء والنون", note="اسم فاعل مذكّر جمع مجرور، معطوف على «المغضوب». الجذر ض ل ل."),
 (112,1,1): dict(root="ق و ل", lemma="قالَ", pos="V", pos_ar="فعل أمر مبنيّ", case=None,
               person="2", gender="masculine", number="singular", aspect="imperative", voice="active", form=1,
               pattern="قُلْ (أمر)", note="فعل أمر مبنيّ على السكون، فاعله «أنت» مستتر. الجذر ق و ل."),
 (112,1,2): dict(root=None, lemma="هو", pos="PRON", pos_ar="ضمير رفع منفصل", case=None,
               person="3", gender="masculine", number="singular",
               pattern="ضمير الغائب المنفصل", note="ضمير غائب مذكّر مفرد في محل رفع، مبتدأ."),
 (112,1,3): dict(root="أ ل ه", lemma="اللَّه", pos="PN", pos_ar="لفظ الجلالة مرفوع", case="nominative",
               pattern="لفظ الجلالة", note="اسم علم مرفوع بالضمة، خبر «هو» (أو مبتدأ ثانٍ). الجذر أ ل ه."),
 (112,1,4): dict(root="أ ح د", lemma="أَحَد", pos="N", pos_ar="اسم نكرة مرفوع", case="nominative",
               definiteness="indefinite", pattern="فَعَل",
               note="اسم نكرة مذكّر مرفوع بالضمة، خبر. الجذر أ ح د."),
 (112,2,1): dict(root="أ ل ه", lemma="اللَّه", pos="PN", pos_ar="لفظ الجلالة مرفوع", case="nominative",
               pattern="لفظ الجلالة", note="اسم علم مرفوع، مبتدأ. الجذر أ ل ه."),
 (112,2,2): dict(root="ص م د", lemma="صَمَد", pos="N", pos_ar="اسم مرفوع", case="nominative",
               pattern="فَعَل", note="اسم مذكّر مفرد مرفوع بالضمة، خبر. لم يرد إلا مرة واحدة في القرآن. الجذر ص م د."),
 (112,3,1): dict(root=None, lemma="لَم", pos="NEG", pos_ar="حرف نفي وجزم وقلب", case=None,
               pattern="لَمْ", note="حرف نفي يجزم المضارع ويقلب زمنه إلى المضيّ."),
 (112,3,2): dict(root="و ل د", lemma="وَلَدَ", pos="V", pos_ar="فعل مضارع مجزوم", case=None,
               person="3", gender="masculine", number="singular", aspect="imperfect", mood="jussive", voice="active", form=1,
               pattern="يَفْعِلْ", note="فعل مضارع مجزوم بـ«لم»، وعلامة جزمه السكون، فاعله «هو» مستتر. الجذر و ل د."),
 (112,3,3): dict(root=None, lemma="و", pos="CONJ", pos_ar="حرف عطف", case=None,
               pattern="وَ", note="حرف عطف مبنيّ."),
 (112,3,4): dict(root=None, lemma="لَم", pos="NEG", pos_ar="حرف نفي وجزم وقلب", case=None,
               pattern="لَمْ", note="معطوفة على الأولى."),
 (112,3,5): dict(root="و ل د", lemma="وَلَدَ", pos="V", pos_ar="فعل مضارع مبنيّ للمجهول مجزوم", case=None,
               person="3", gender="masculine", number="singular", aspect="imperfect", mood="jussive", voice="passive", form=1,
               pattern="يُفْعَلْ (مبنيّ للمجهول)", note="فعل مضارع مبنيّ للمجهول مجزوم بـ«لم»، نائب الفاعل «هو» مستتر. الجذر و ل د."),
 (112,4,1): dict(root=None, lemma="و", pos="CONJ", pos_ar="حرف عطف", case=None,
               pattern="وَ", note="حرف عطف مبنيّ."),
 (112,4,2): dict(root=None, lemma="لَم", pos="NEG", pos_ar="حرف نفي وجزم وقلب", case=None,
               pattern="لَمْ", note="حرف نفي وجزم وقلب."),
 (112,4,3): dict(root="ك و ن", lemma="كانَ", pos="V", pos_ar="فعل مضارع ناقص مجزوم", case=None,
               person="3", gender="masculine", number="singular", aspect="imperfect", mood="jussive", voice="active", form=1,
               pattern="يَكُنْ (من كان وأخواتها)", note="فعل مضارع ناقص مجزوم بـ«لم» وعلامة جزمه السكون، من «كان وأخواتها» يرفع الاسم وينصب الخبر. الجذر ك و ن."),
 (112,4,4): dict(root=None, lemma="ل", pos="P", pos_ar="جار ومجرور", case=None,
               pattern="لَّ + هُ", note="حرف جر «لـ» + ضمير الغائب «ه» في محل جر، والجار والمجرور خبر «يكن» مقدّم."),
 (112,4,5): dict(root="ك ف أ", lemma="كُفُو", pos="N", pos_ar="اسم نكرة منصوب", case="accusative",
               definiteness="indefinite", pattern="فُعُل",
               note="اسم نكرة مذكّر منصوب بالفتحة، خبر «يكن» (أو حال). لم يرد إلا مرة واحدة. الجذر ك ف أ."),
 (112,4,6): dict(root="أ ح د", lemma="أَحَد", pos="N", pos_ar="اسم نكرة مرفوع", case="nominative",
               definiteness="indefinite", pattern="فَعَل",
               note="اسم «يكن» مرفوع بالضمة (مؤخّر). الجذر أ ح د."),
}

# ---------------------------------------------------------------------------
# NAḤW  — P0: the iʿrāb of EVERY content word of the Prototype ayat, with
# typed relations to other words in the same ayah. Cited to src:nahw-basic
# (the grammar of al-Fātiḥa + al-Ikhlāṣ is universally agreed). NOT AI.
# value: (role_key, role_ar, sign_ar, irab_text, [ (to_word_index, rel_key, rel_ar), ... ])
# ---------------------------------------------------------------------------
NAHW = {
 # ---- al-Fātiḥa 1:1  «بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ» ----
 (1,1,1): ("jar_majrur","جار ومجرور","الكسرة","«بِ» حرف جر، و«اسمِ» اسم مجرور بالكسرة، والجار والمجرور متعلّق بمحذوف تقديره «أبدأُ» أو «ابتدائي». و«اسم» مضاف.",
           [(2,"mudaf","مضاف إلى لفظ الجلالة")]),
 (1,1,2): ("mudaf_ilayh","مضاف إليه","الكسرة","لفظ الجلالة: مضاف إليه مجرور وعلامة جرّه الكسرة.",
           [(1,"mudaf_ilayh_of","مضاف إليه لـ«اسم»")]),
 (1,1,3): ("naat","نعت","الكسرة","«الرحمٰن»: نعت للفظ الجلالة مجرور وعلامة جرّه الكسرة.",
           [(2,"naat_of","نعت لـ«الله»")]),
 (1,1,4): ("naat","نعت ثانٍ","الكسرة","«الرحيم»: نعت ثانٍ للفظ الجلالة مجرور بالكسرة.",
           [(2,"naat_of","نعت لـ«الله»")]),
 # ---- 1:2  «ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ» ----
 (1,2,1): ("mubtada","مبتدأ","الضمة","«الحمدُ»: مبتدأ مرفوع وعلامة رفعه الضمة.",
           [(2,"khabar_is","خبره شبه الجملة «لله»")]),
 (1,2,2): ("khabar","خبر (شبه جملة)","الكسرة","«لله»: جار ومجرور متعلّق بمحذوف خبر المبتدأ، تقديره «كائنٌ» أو «مستقرٌّ».",
           [(1,"khabar_of","خبر عن «الحمد»")]),
 (1,2,3): ("naat","نعت / بدل","الكسرة","«ربِّ»: نعت (أو بدل) من لفظ الجلالة مجرور بالكسرة، وهو مضاف.",
           [(2,"naat_of","نعت لـ«الله»"),(4,"mudaf","مضاف إلى «العالمين»")]),
 (1,2,4): ("mudaf_ilayh","مضاف إليه","الياء","«العالمينَ»: مضاف إليه مجرور وعلامة جرّه الياء لأنه ملحق بجمع المذكّر السالم.",
           [(3,"mudaf_ilayh_of","مضاف إليه لـ«ربّ»")]),
 # ---- 1:3  «ٱلرَّحْمَٰنِ ٱلرَّحِيمِ» ----
 (1,3,1): ("naat","نعت","الكسرة","«الرحمٰنِ»: نعت للفظ الجلالة في الآية السابقة مجرور بالكسرة.",[]),
 (1,3,2): ("naat","نعت ثانٍ","الكسرة","«الرحيمِ»: نعت ثانٍ مجرور بالكسرة.",[]),
 # ---- 1:4  «مَٰلِكِ يَوْمِ ٱلدِّينِ» ----
 (1,4,1): ("naat","نعت","الكسرة","«مالكِ»: نعت رابع للفظ الجلالة مجرور بالكسرة، وهو مضاف. وأصله اسم فاعل.",
           [(2,"mudaf","مضاف إلى «يوم»")]),
 (1,4,2): ("mudaf_ilayh","مضاف إليه","الكسرة","«يومِ»: مضاف إليه مجرور بالكسرة، وهو مضاف.",
           [(1,"mudaf_ilayh_of","مضاف إليه لـ«مالك»"),(3,"mudaf","مضاف إلى «الدين»")]),
 (1,4,3): ("mudaf_ilayh","مضاف إليه","الكسرة","«الدينِ»: مضاف إليه مجرور بالكسرة.",
           [(2,"mudaf_ilayh_of","مضاف إليه لـ«يوم»")]),
 # ---- 1:5  «إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ» ----
 (1,5,1): ("maful_bihi","مفعول به مقدَّم","محلّيًّا","«إياكَ»: ضمير نصب منفصل مبنيّ في محل نصب مفعول به مقدَّم لـ«نعبد»، وتقديمه يفيد الحصر: لا نعبد إلا إياك.",
           [(2,"maful_of","مفعول به لـ«نعبد»")]),
 (1,5,2): ("fil_mudari","فعل مضارع مرفوع","الضمة","«نعبدُ»: فعل مضارع مرفوع بالضمة، والفاعل ضمير مستتر وجوبًا تقديره «نحن».",
           [(1,"amil_of","عاملٌ في «إياك»")]),
 (1,5,3): ("maful_bihi","حرف عطف + مفعول به مقدَّم","محلّيًّا","«وإياكَ»: «الواو» عاطفة، و«إياك» مفعول به مقدَّم لـ«نستعين».",
           [(4,"maful_of","مفعول به لـ«نستعين»")]),
 (1,5,4): ("fil_mudari","فعل مضارع مرفوع","الضمة","«نستعينُ»: فعل مضارع مرفوع بالضمة، على وزن «استفعل»، والفاعل مستتر «نحن».",
           [(3,"amil_of","عاملٌ في «إياك» الثانية")]),
 # ---- 1:6  «ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ» ----
 (1,6,1): ("fil_amr","فعل أمر مبنيّ","حذف حرف العلّة","«اهدِ»: فعل أمر مبنيّ على حذف حرف العلّة، الفاعل مستتر «أنت»، و«نا» ضمير متّصل في محل نصب مفعول به أوّل.",
           [(2,"amil_of","عاملٌ في «الصراط»")]),
 (1,6,2): ("maful_bihi","مفعول به (ثانٍ)","الفتحة","«الصراطَ»: مفعول به منصوب بالفتحة.",
           [(1,"maful_of","مفعول به لـ«اهدنا»"),(3,"manut_of","منعوت بـ«المستقيم»")]),
 (1,6,3): ("naat","نعت","الفتحة","«المستقيمَ»: نعت لـ«الصراط» منصوب بالفتحة، وأصله اسم فاعل من «استقام».",
           [(2,"naat_of","نعت لـ«الصراط»")]),
 # ---- 1:7 ----
 (1,7,1): ("badal","بدل","الفتحة","«صراطَ»: بدل من «الصراط» في الآية السابقة منصوب بالفتحة، وهو مضاف.",
           [(2,"mudaf","مضاف إلى «الذين»")]),
 (1,7,2): ("mudaf_ilayh","مضاف إليه (اسم موصول)","محلّيًّا","«الذينَ»: اسم موصول مبنيّ في محل جر مضاف إليه.",
           [(1,"mudaf_ilayh_of","مضاف إليه لـ«صراط»"),(3,"silah_is","صلته جملة «أنعمت عليهم»")]),
 (1,7,3): ("silah","صلة الموصول (فعل + فاعل)","السكون","«أنعمتَ»: فعل ماضٍ مبنيّ على السكون، و«التاء» ضمير رفع في محل رفع فاعل. والجملة صلة الموصول لا محل لها.",
           [(2,"silah_of","صلة لـ«الذين»"),(4,"amil_of","متعلَّقه «عليهم»")]),
 (1,7,4): ("jar_majrur","جار ومجرور","محلّيًّا","«عليهم»: جار ومجرور متعلّق بـ«أنعمت».",
           [(3,"mutaalliq_of","متعلّق بـ«أنعمت»")]),
 (1,7,5): ("badal","بدل","الكسرة","«غيرِ»: بدل من الضمير في «عليهم» مجرور بالكسرة، وهو مضاف.",
           [(6,"mudaf","مضاف إلى «المغضوب»")]),
 (1,7,6): ("mudaf_ilayh","مضاف إليه (اسم مفعول)","الكسرة","«المغضوبِ»: مضاف إليه مجرور بالكسرة، وهو اسم مفعول.",
           [(5,"mudaf_ilayh_of","مضاف إليه لـ«غير»"),(7,"amil_of","نائب فاعله «عليهم»")]),
 (1,7,7): ("jar_majrur","جار ومجرور (نائب فاعل)","محلّيًّا","«عليهم»: جار ومجرور في محل رفع نائب فاعل لاسم المفعول «المغضوب».",
           [(6,"mutaalliq_of","متعلّق بـ«المغضوب»")]),
 (1,7,8): ("harf_atf","حرف عطف","—","«الواو»: حرف عطف مبنيّ لا محل له.",[(10,"atf_link","تعطف «الضالين» على «المغضوب»")]),
 (1,7,9): ("harf_zaid","حرف نفي زائد للتأكيد","—","«لا»: نافية زائدة لتأكيد النفي، مبنيّة لا محل لها.",[]),
 (1,7,10):("atf","معطوف","الياء","«الضالينَ»: معطوف على «المغضوب» مجرور وعلامة جرّه الياء (جمع مذكّر سالم)، وهو اسم فاعل.",
           [(6,"matuf_alayh","معطوف على «المغضوب»")]),
 # ---- al-Ikhlāṣ 112:1  «قُلْ هُوَ ٱللَّهُ أَحَدٌ» ----
 (112,1,1): ("fil_amr","فعل أمر مبنيّ","السكون","«قلْ»: فعل أمر مبنيّ على السكون، الفاعل مستتر وجوبًا «أنت». ومقول القول جملة «هو الله أحد».",
             [(2,"maqul_is","مقول القول: «هو الله أحد»")]),
 (112,1,2): ("mubtada","مبتدأ","محلّيًّا","«هو»: ضمير رفع منفصل مبنيّ في محل رفع مبتدأ.",
             [(3,"khabar_is","خبره «الله» / أو «الله أحد» جملة")]),
 (112,1,3): ("khabar","خبر (أو مبتدأ ثانٍ)","الضمة","«اللهُ»: خبر «هو» مرفوع بالضمة (وقيل: مبتدأ ثانٍ، و«أحدٌ» خبره، والجملة خبر «هو»).",
             [(2,"khabar_of","خبر عن «هو»"),(4,"khabar_is","«أحد» خبره على الوجه الثاني")]),
 (112,1,4): ("khabar","خبر","الضمة","«أحدٌ»: خبر مرفوع بالضمة (خبر ثانٍ لـ«هو»، أو خبر «الله»).",
             [(3,"khabar_of","خبر عن «الله» / «هو»")]),
 # ---- 112:2  «ٱللَّهُ ٱلصَّمَدُ» ----
 (112,2,1): ("mubtada","مبتدأ","الضمة","«اللهُ»: مبتدأ مرفوع بالضمة.",[(2,"khabar_is","خبره «الصمد»")]),
 (112,2,2): ("khabar","خبر","الضمة","«الصمدُ»: خبر مرفوع بالضمة. ولفظ لم يرد في القرآن إلا هنا.",[(1,"khabar_of","خبر عن «الله»")]),
 # ---- 112:3  «لَمْ يَلِدْ وَلَمْ يُولَدْ» ----
 (112,3,1): ("harf_nafi_jazm","حرف نفي وجزم وقلب","—","«لم»: حرف نفي يجزم المضارع ويقلب زمنه إلى المضيّ، مبنيّ لا محل له.",[(2,"amil_of","تجزم «يلد»")]),
 (112,3,2): ("fil_majzum","فعل مضارع مجزوم","السكون","«يلدْ»: فعل مضارع مجزوم بـ«لم» وعلامة جزمه السكون، الفاعل مستتر «هو».",[(1,"majzum_by","مجزوم بـ«لم»")]),
 (112,3,3): ("harf_atf","حرف عطف","—","«الواو»: عاطفة، تعطف جملة «لم يولد» على «لم يلد».",[(5,"atf_link","تعطف «لم يولد»")]),
 (112,3,4): ("harf_nafi_jazm","حرف نفي وجزم وقلب","—","«لم» الثانية: حرف نفي وجزم وقلب.",[(5,"amil_of","تجزم «يولد»")]),
 (112,3,5): ("fil_majhul","فعل مضارع مبنيّ للمجهول مجزوم","السكون","«يولدْ»: فعل مضارع مبنيّ للمجهول مجزوم بـ«لم»، ونائب الفاعل مستتر «هو».",[(4,"majzum_by","مجزوم بـ«لم»")]),
 # ---- 112:4  «وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌ» ----
 (112,4,1): ("harf_atf","حرف عطف","—","«الواو»: عاطفة، تعطف الجملة على ما قبلها.",[]),
 (112,4,2): ("harf_nafi_jazm","حرف نفي وجزم وقلب","—","«لم»: حرف نفي وجزم وقلب.",[(3,"amil_of","تجزم «يكن»")]),
 (112,4,3): ("fil_naqis","فعل مضارع ناقص مجزوم (كان وأخواتها)","السكون","«يكنْ»: فعل مضارع ناقص مجزوم بـ«لم» وعلامة جزمه السكون؛ من «كان وأخواتها» يرفع الاسم وينصب الخبر.",
             [(6,"amil_ism","يرفع اسمه «أحد»"),(4,"amil_khabar","خبره المقدَّم «له»")]),
 (112,4,4): ("khabar_kana","خبر «يكن» مقدَّم (شبه جملة)","محلّيًّا","«له»: جار ومجرور متعلّق بمحذوف خبر «يكن» مقدَّم، في محل نصب.",
             [(3,"khabar_of","خبر «يكن» المقدَّم")]),
 (112,4,5): ("hal","حال (أو خبر ثانٍ)","الفتحة","«كُفُوًا»: منصوب على الحال من «أحد» (وقيل خبر «يكن»)، وهو نكرة. لم يرد في القرآن إلا هنا.",
             [(6,"hal_of","حال من «أحد»")]),
 (112,4,6): ("ism_kana","اسم «يكن» مؤخَّر","الضمة","«أحدٌ»: اسم «يكن» مرفوع مؤخَّر بالضمة.",
             [(3,"ism_of","اسم «يكن»")]),
}

# ---------------------------------------------------------------------------
# TAJWĪD rule -> concept id + Arabic label + family
# ---------------------------------------------------------------------------
TAJWEED_META = {
 "hamzat_wasl":     ("همزة الوصل",           "أحكام الهمز",    "concept:tajweed:hamzat_wasl"),
 "lam_shamsiyyah":  ("اللام الشمسية",        "أحكام اللام",   "concept:tajweed:lam_shamsiyyah"),
 "madd_2":          ("مدّ طبيعي (حركتان)",   "أحكام المدود",  "concept:tajweed:madd_tabee"),
 "madd_246":        ("مدّ عارض/لين (2 أو 4 أو 6)", "أحكام المدود", "concept:tajweed:madd_aarid"),
 "madd_6":          ("مدّ لازم (6 حركات)",   "أحكام المدود",  "concept:tajweed:madd_lazim"),
 "madd_muttasil":   ("مدّ متّصل واجب",       "أحكام المدود",  "concept:tajweed:madd_muttasil"),
 "madd_munfasil":   ("مدّ منفصل جائز",       "أحكام المدود",  "concept:tajweed:madd_munfasil"),
 "ghunnah":         ("غنّة",                 "الغنّة",        "concept:tajweed:ghunnah"),
 "qalqalah":        ("قلقلة",                "القلقلة",       "concept:tajweed:qalqalah"),
 "ikhfa":           ("إخفاء",                "أحكام النون الساكنة والتنوين", "concept:tajweed:ikhfa"),
 "iqlab":           ("إقلاب",                "أحكام النون الساكنة والتنوين", "concept:tajweed:iqlab"),
 "idghaam_ghunnah": ("إدغام بغنّة",          "أحكام النون الساكنة والتنوين", "concept:tajweed:idgham_ghunnah"),
 "idghaam_no_ghunnah":("إدغام بغير غنّة",    "أحكام النون الساكنة والتنوين", "concept:tajweed:idgham_no_ghunnah"),
 "ikhfa_shafawi":   ("إخفاء شفوي",           "أحكام الميم الساكنة", "concept:tajweed:ikhfa_shafawi"),
 "idghaam_shafawi": ("إدغام شفوي",           "أحكام الميم الساكنة", "concept:tajweed:idgham_shafawi"),
 "silent":          ("حرف لا يُنطق",          "أحكام عامة",    "concept:tajweed:silent"),
}

# concepts + lessons (prose from the cited matns / QAC analysis)
CONCEPTS = [
 dict(id="concept:tajweed:hamzat_wasl", domain="tajweed", title_ar="همزة الوصل",
      short_def_ar="همزة تُنطق في بدء الكلام وتسقط في وصله؛ تُرسم ألفًا عليها صاد صغيرة (ٱ).",
      source_ref_ids=["src:jazariyyah","src:tuhfa"],
      blocks=[("definition","همزة الوصل: همزة زائدة يُؤتى بها للتوصّل إلى النطق بالساكن، تثبت ابتداءً وتسقط وصلًا.","src:jazariyyah"),
              ("explanation","تقع في: «ال» التعريف، وأمر الفعل الثلاثي، وبعض الأسماء (اسم، ابن…)، وماضي وأمر الخماسي والسداسي ومصدرهما.","src:jazariyyah"),
              ("quranic_example","في «بِسْمِ ٱللَّهِ» تسقط همزة «ٱللَّهِ» وصلًا فتُقرأ «بِسْمِ لله».",None)]),
 dict(id="concept:tajweed:lam_shamsiyyah", domain="tajweed", title_ar="اللام الشمسية",
      short_def_ar="لام «ال» إذا جاء بعدها حرف شمسي تُدغم فيه ولا تُنطق، وتُشدَّد ما بعدها.",
      source_ref_ids=["src:tuhfa"],
      blocks=[("definition","اللام الشمسية: لام التعريف تُكتب ولا تُلفظ، ويُدغم بعدها أحد أربعة عشر حرفًا شمسيًّا.","src:tuhfa"),
              ("explanation","الحروف الشمسية مجموعة في أوائل كلمات البيت: «طب ثم صل رحمًا تفز ضف ذا نعم — دع سوء ظن زر شريفًا للكرم».","src:tuhfa"),
              ("quranic_example","«ٱلرَّحْمَٰنِ»: لام «ال» شمسية مدغمة في الراء، فتُقرأ «أرْ رَحمٰن».",None)]),
 dict(id="concept:tajweed:madd_tabee", domain="tajweed", title_ar="المدّ الطبيعي",
      short_def_ar="مدّ حرف العلّة بمقدار حركتين إذا لم يقع بعده همز أو سكون.",
      source_ref_ids=["src:tuhfa","src:jazariyyah"],
      blocks=[("definition","المدّ الطبيعي (الأصلي): إطالة الصوت بحرف من حروف المدّ (ا، و، ي) مقدار حركتين.","src:tuhfa"),
              ("quranic_example","الألف في «ٱلرَّحْمَٰن» تُمدّ حركتين.",None)]),
 dict(id="concept:tajweed:madd_aarid", domain="tajweed", title_ar="المدّ العارض للسكون",
      short_def_ar="إذا وقع حرف المدّ قبل حرف موقوف عليه بالسكون جاز مدّه 2 أو 4 أو 6 حركات.",
      source_ref_ids=["src:jazariyyah"],
      blocks=[("definition","المدّ العارض للسكون: سكونٌ عارض بسبب الوقف يقع بعد حرف مدّ، يُمدّ حركتين أو أربعًا أو ستًّا.","src:jazariyyah"),
              ("quranic_example","«ٱلرَّحِيمِ» عند الوقف: الياء تُمدّ 2 أو 4 أو 6.",None)]),
 dict(id="concept:tajweed:madd_lazim", domain="tajweed", title_ar="المدّ اللازم",
      short_def_ar="إذا جاء بعد حرف المدّ سكونٌ أصليّ لازم، مُدّ ستّ حركات وجوبًا.",
      source_ref_ids=["src:jazariyyah"],
      blocks=[("definition","المدّ اللازم: أن يقع بعد حرف المدّ حرف ساكن سكونًا أصليًّا (لازمًا وصلًا ووقفًا)، فيُمدّ ستّ حركات.","src:jazariyyah")]),
 dict(id="concept:tajweed:idgham_no_ghunnah", domain="tajweed", title_ar="الإدغام بغير غنّة",
      short_def_ar="النون الساكنة أو التنوين إذا جاء بعدها لام أو راء تُدغم فيهما بلا غنّة.",
      source_ref_ids=["src:tuhfa"],
      blocks=[("definition","الإدغام بغير غنّة: إذا وقعت اللام أو الراء بعد النون الساكنة أو التنوين، أُدغمت النون فيهما إدغامًا كاملًا بلا غنّة.","src:tuhfa")]),
 dict(id="concept:tajweed:qalqalah", domain="tajweed", title_ar="القلقلة",
      short_def_ar="اضطراب المخرج عند النطق بحروف «قطب جد» ساكنةً حتى يُسمع لها نبرة.",
      source_ref_ids=["src:tuhfa"],
      blocks=[("definition","القلقلة: تحريك المخرج بحرف من «قُطْبُ جَدٍّ» (ق ط ب ج د) إذا كان ساكنًا حتى تُسمع نبرة قويّة.","src:tuhfa"),
              ("quranic_example","«أَحَدٌ» عند الوقف: الدال ساكنة فتُقلقل.",None)]),
 dict(id="concept:tajweed:ghunnah", domain="tajweed", title_ar="الغنّة",
      short_def_ar="صوت يخرج من الخيشوم يصاحب النون والميم المشدّدتين وأحكامهما.",
      source_ref_ids=["src:tuhfa"],
      blocks=[("definition","الغنّة: صوت أنفيّ لازم للنون والميم، أكمل ما يكون في المشدّد.","src:tuhfa"),
              ("quranic_example","«ٱلنَّاسِ»: نون مشدّدة تُغنّ بمقدار حركتين.",None)]),
 dict(id="concept:tajweed:ikhfa", domain="tajweed", title_ar="الإخفاء الحقيقي",
      short_def_ar="النون الساكنة أو التنوين إذا جاء بعدها أحد حروف الإخفاء تُنطق بين الإظهار والإدغام مع غنّة.",
      source_ref_ids=["src:tuhfa"],
      blocks=[("definition","الإخفاء: نطق النون الساكنة/التنوين بصفة بين الإظهار والإدغام، مع بقاء الغنّة، عند أحد خمسة عشر حرفًا.","src:tuhfa"),
              ("quranic_example","«مِن نِّعمة» ونحوها.",None)]),
 dict(id="concept:nahw:mubtada_khabar", domain="nahw", title_ar="المبتدأ والخبر",
      short_def_ar="الجملة الاسمية تتكوّن من مبتدأ (اسم مرفوع يُبتدأ به) وخبر (ما يُخبَر به عنه) مرفوع.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","المبتدأ: اسم مرفوع في أوّل الجملة الاسمية. الخبر: ما يُتمّ معنى المبتدأ، وهو مرفوع، وقد يكون مفردًا أو جملة أو شبه جملة.","src:irab-classical"),
              ("quranic_example","«ٱللَّهُ ٱلصَّمَدُ» (الإخلاص 2): «اللهُ» مبتدأ، «الصمدُ» خبر، وكلاهما مرفوع.",None),
              ("application","انظر إلى «ٱلْحَمْدُ لِلَّهِ»: «الحمدُ» مبتدأ، و«لله» جار ومجرور متعلّق بخبر محذوف.",None)]),
 dict(id="concept:nahw:maful_bihi", domain="nahw", title_ar="المفعول به",
      short_def_ar="اسم منصوب يقع عليه فعل الفاعل. وقد يتقدّم على الفعل لإفادة الحصر.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","المفعول به: اسم منصوب دلّ على من وقع عليه فعل الفاعل.","src:irab-classical"),
              ("quranic_example","«إِيَّاكَ نَعْبُدُ» (الفاتحة 5): «إياكَ» مفعول به مقدَّم في محل نصب، وتقديمه يفيد الحصر: لا نعبد إلا إياك.",None)]),
 dict(id="concept:nahw:jar_majrur", domain="nahw", title_ar="الجار والمجرور",
      short_def_ar="حرف جر + اسم مجرور بعده، ويتعلّقان بفعل أو بمحذوف.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","الجار والمجرور: تركيب من حرف جر واسم مجرور، لا بدّ له من «متعلَّق» (فعل أو شبهه أو محذوف).","src:irab-classical"),
              ("quranic_example","«بِسْمِ ٱللَّهِ»: «بِ» حرف جر، «سْمِ» مجرور، والجار والمجرور متعلّق بمحذوف تقديره «أبدأ» أو «ابتدائي».",None)]),
 dict(id="concept:nahw:idafa", domain="nahw", title_ar="المضاف والمضاف إليه",
      short_def_ar="اسمان بينهما نسبة، الأول «مضاف» يُحذف تنوينه، والثاني «مضاف إليه» مجرور دائمًا.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","الإضافة: نسبة بين اسمين، يُجرّ بها الثاني أبدًا، ويكتسب الأول التعريف أو التخصيص.","src:irab-classical"),
              ("quranic_example","«رَبِّ ٱلْعَٰلَمِينَ»: «ربِّ» مضاف، «العالمينَ» مضاف إليه مجرور بالياء.",None),
              ("quranic_example","«مَٰلِكِ يَوْمِ ٱلدِّينِ»: إضافتان متتاليتان.",None)]),
 dict(id="concept:nahw:naat", domain="nahw", title_ar="النعت (الصفة)",
      short_def_ar="تابع يذكر صفة في متبوعه، ويتبعه في الإعراب والتعريف والتذكير والعدد.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","النعت: تابع يبيّن صفة في اسم قبله (المنعوت)، ويطابقه في الإعراب والإفراد والتذكير والتعريف.","src:irab-classical"),
              ("quranic_example","«ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ»: «المستقيمَ» نعت لـ«الصراط» منصوب مثله.",None),
              ("quranic_example","«ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ»: نعتان مجروران للفظ الجلالة.",None)]),
 dict(id="concept:nahw:jazm_lam", domain="nahw", title_ar="جزم المضارع بـ«لم»",
      short_def_ar="«لم» حرف نفي وجزم وقلب: تجزم المضارع وتقلب معناه إلى المضيّ.",
      source_ref_ids=["src:irab-classical"],
      blocks=[("definition","«لم»: من الجوازم، تجزم فعلًا واحدًا، وعلامة الجزم السكون في الصحيح الآخر، وتحوّل زمن المضارع إلى الماضي.","src:irab-classical"),
              ("quranic_example","«لَمْ يَلِدْ وَلَمْ يُولَدْ» (الإخلاص 3): «يلدْ» و«يولدْ» مضارعان مجزومان بـ«لم»، علامة جزمهما السكون.",None)]),
 dict(id="concept:sarf:wazn", domain="sarf", title_ar="الوزن الصرفي (البنية)",
      short_def_ar="ميزان الكلمة العربية بحروف «فعل»؛ منه يُعرف الزائد والأصلي ونوع الاشتقاق.",
      source_ref_ids=["src:qac"],
      blocks=[("definition","الوزن الصرفي: مقابلة حروف الكلمة بحروف «ف ع ل» لبيان بنيتها. فالأصول تقابل «فعل» والزوائد تُذكر بلفظها.","src:qac"),
              ("quranic_example","«نَسْتَعِينُ» على وزن «نَسْتَفْعِلُ» — من الباب العاشر (استفعل)، والجذر «ع و ن».",None)]),
 dict(id="concept:sarf:fil_madi_mudari_amr", domain="sarf", title_ar="الماضي والمضارع والأمر",
      short_def_ar="الفعل ثلاثة أزمنة: ماضٍ (وقع وانقضى)، ومضارع (يقع الآن أو مستقبلًا)، وأمر (طلب الفعل).",
      source_ref_ids=["src:qac"],
      blocks=[("definition","الماضي مبنيّ. المضارع معرب يرفع ويُنصب ويُجزم. الأمر مبنيّ ويدلّ على الطلب.","src:qac"),
              ("quranic_example","«أَنْعَمْتَ» ماضٍ، «نَعْبُدُ» مضارع، «ٱهْدِنَا» أمر — كلها في الفاتحة.",None)]),
]


def load_mushaf_words():
    L = json.load(gzip.open(LAYOUT))
    mw = {}
    for pg in L["pages"]:
        for w in pg["words"]:
            key = (w["s"], w["a"])
            if key in PROTOTYPE_AYAT:
                mw.setdefault(key, []).append(dict(wi=w["w"], hafs=w["hafs"], t=w.get("t", "text")))
    for k in mw:
        mw[k].sort(key=lambda x: x["wi"])
    return mw


def tajweed_by_word():
    """cpfair spans -> {(surah,ayah,word_index): [rule_id,...]}  (deduped, order kept)."""
    tj = {(e["surah"], e["ayah"]): e["annotations"] for e in json.load(open(TJ_SRC, encoding="utf-8"))}
    base = json.load(open(TJ_BASE, encoding="utf-8"))
    out = {}
    for (s, a), anns in tj.items():
        if (s, a) not in PROTOTYPE_AYAT:
            continue
        text = base[f"{s}:{a}"]
        # cpfair prepends the basmala to 112:1 / 114:1; MushafDatabase does not.
        basmala_words = 4 if (s in (112, 114) and a == 1) else 0
        for ann in anns:
            cp_word = text[: ann["start"]].count(" ") + 1
            widx = cp_word - basmala_words
            if widx < 1:
                continue  # span sits inside the basmala; no ayah-word counterpart
            out.setdefault((s, a, widx), [])
            if ann["rule"] not in out[(s, a, widx)]:
                out[(s, a, widx)].append(ann["rule"])
    return out


def main():
    mw = load_mushaf_words()
    tjw = tajweed_by_word()

    facts = []
    def add(domain, s, a, wi, payload, src):
        facts.append(dict(
            id=f"{domain}:{s}:{a}:{wi}",
            domain=domain,
            anchor=dict(surah=s, ayah=a, word_start=wi, word_end=wi, scope="word",
                        segmentation="mushafdb-v1.01"),
            payload=payload,
            source_ref_id=src,
        ))

    for (s, a), words in sorted(mw.items()):
        for w in words:
            wi = w["wi"]
            k = (s, a, wi)
            if k in SARF:
                d = dict(SARF[k]); d["surface"] = w["hafs"]
                add("sarf", s, a, wi, d, "src:qac")
            if k in NAHW:
                role, role_ar, sign_ar, irab, rels = NAHW[k]
                relations = [dict(to_word=tw, rel=rk, rel_ar=ra) for (tw, rk, ra) in rels]
                add("nahw", s, a, wi, dict(
                    role=role, role_ar=role_ar, sign_ar=sign_ar, irab_text=irab,
                    surface=w["hafs"], relations=relations,
                    concept_id=_nahw_concept(role)), "src:irab-classical")
            if k in tjw:
                rules = []
                for r in tjw[k]:
                    label, family, cid = TAJWEED_META.get(r, (r, "أحكام عامة", None))
                    rules.append(dict(rule_id=r, rule_ar=label, rule_family=family, concept_id=cid))
                add("tajweed", s, a, wi, dict(rules=rules, surface=w["hafs"]), "src:cpfair-tajweed")

    layout = dict(
        # v2: re-seed on devices that got the v1 asset through the buggy
        # String.fromCharCodes reader (mojibake Arabic). v2 is read with utf8.
        version=2,
        scope="prototype",
        ayat=[f"{s}:{a}" for (s, a) in PROTOTYPE_AYAT],
        generated_from=dict(
            morphology="Quranic Arabic Corpus (via quran.com word-morphology), attribution + link required",
            tajweed="cpfair/quran-tajweed output/tajweed.hafs.uthmani-pause-sajdah.json (CC BY 4.0), remapped to mushafdb-v1.01",
            nahw="derived iʿrāb of these universally-parsed short verses; cited src:nahw-basic",
        ),
        sources=SOURCES,
        concepts=CONCEPTS,
        facts=facts,
    )
    payload = json.dumps(layout, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    with open(OUT, "wb") as fh:
        fh.write(payload)
    print(f"wrote {OUT}")
    print(f"  facts: {len(facts)}  (sarf {sum(1 for f in facts if f['domain']=='sarf')}, "
          f"nahw {sum(1 for f in facts if f['domain']=='nahw')}, "
          f"tajweed {sum(1 for f in facts if f['domain']=='tajweed')})")
    print(f"  concepts: {len(CONCEPTS)}  sources: {len(SOURCES)}")
    print(f"  sha256: {hashlib.sha256(payload).hexdigest()}")


def _nahw_concept(role):
    if role in ("mubtada", "khabar", "khabar_kana", "ism_kana", "fil_naqis"):
        return "concept:nahw:mubtada_khabar"
    if role in ("maful_bihi",):
        return "concept:nahw:maful_bihi"
    if role in ("jar_majrur", "khabar", "mutaalliq"):
        return "concept:nahw:jar_majrur"
    if role in ("mudaf_ilayh",):
        return "concept:nahw:idafa"
    if role in ("naat",):
        return "concept:nahw:naat"
    if role in ("fil_majzum", "harf_nafi_jazm", "fil_majhul"):
        return "concept:nahw:jazm_lam"
    return None


if __name__ == "__main__":
    main()
