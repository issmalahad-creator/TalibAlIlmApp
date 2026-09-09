# الرفق — الترجمة (TRANSLATION)

> تنفيذ طبقة الترجمة (`AKHLAQ_TRANSLATION_MODEL`) على شريحة «الرفق».
> **العربيّة = SOURCE OF TRUTH؛ لا تُستبدَل ولا تختفي.** الطبقات الأربع
> مفصولة: `Source` / `Translation` / `Explanation` / `Pedagogical`.
>
> المصدر الآليّ للبيانات: `docs/akhlaq/alrifq/ar-rifq.json` (مصفوفة
> `translations`). التحقّق: `tool/akhlaq_validate.py` (أخضر —
> `AR-RIFQ_VALIDATION.md`).

- **`translation_type`**: `literal` (لفظ الحديث/الأثر/كلام العالِم) ·
  `pedagogical` (كتابة التطبيق نفسها) · `quran_meaning` (من إصدارٍ مُرخَّص
  فقط) · `term_gloss`.
- **`translation_status`**: `generated` = أنتجها Claude بتطبيق قواعد
  `AKHLAQ_TRANSLATION_MODEL §3`؛ قابلةٌ للنشر في الخطّ الأساسيّ. المراجعة
  البشرية طبقةٌ اختياريّة لاحقة.

---

## 1. الأدلّة — ترجمة حرفيّة (`literal`)

> العرض: `[المصدر]` ثمّ `[النصّ العربيّ]` ثمّ `[Literal translation]` ثمّ
> `[Explanatory note]` عند الحاجة — بلا دمج.

### EV‑01 — مسلم ٢٥٩٣ (عائشة) — `source_confirmed`
- **AR:** «يا عائشةُ! إنَّ اللهَ رفيقٌ يحبُّ الرفقَ، ويُعطي على الرفقِ ما
  لا يُعطي على العُنفِ، وما لا يُعطي على ما سواهُ».
- **EN (literal, generated):** "O ʿĀʾisha, Allah is gentle (*rafīq*) and
  loves gentleness; He gives for gentleness what He does not give for
  harshness, and what He does not give for anything else."
- **FR (literal, generated):** « Ô ʿĀʾisha, Allah est doux (*rafīq*) et
  aime la douceur ; Il donne pour la douceur ce qu'Il ne donne pas pour
  la dureté, ni pour rien d'autre. »
- **[Translator note]:** «رفيق» نُقِل «gentle» مع النقحرة؛ الصفة تُنقَل
  كما وردت بلا توسيعٍ عقديّ.

### EV‑02 — مسلم ٢٥٩٤ (عائشة/شريح) — `source_confirmed`
- **AR:** «إنَّ الرفقَ لا يكونُ في شيءٍ إلا زانَه، ولا يُنزَعُ من شيءٍ إلا
  شانَه».
- **EN:** "Gentleness is not present in anything except that it adorns
  it, and it is not removed from anything except that it disgraces it."
- **FR:** « La douceur n'est en aucune chose sans l'embellir, et elle
  n'est ôtée d'aucune chose sans l'enlaidir. »
- **[Note]:** حُفِظ الحصرُ («لا ... إلا») والتقابلُ (زانه/شانه).

### EV‑03 — مسلم ٢٥٩٢ (جرير) — `source_confirmed`
- **AR:** «مَن يُحرَمِ الرفقَ يُحرَمِ الخيرَ».
- **EN:** "Whoever is denied gentleness is denied good."
- **FR:** « Quiconque est privé de douceur est privé du bien. »
- **[Note]:** الشرطُ والجوابُ محفوظانِ؛ «الخير» بأل الجنسيّة تُرِكت عامّة
  ("good") بلا حصرٍ مُضاف.

### EV‑04 — البخاري ٥٧٧٤ / مسلم ١٧٣٤ (أنس) — `source_confirmed`
- **AR:** «يسِّروا ولا تُعسِّروا، وسكِّنوا ولا تُنفِّروا» — وفي رواية:
  «... وبشِّروا ولا تُنفِّروا».
- **EN:** "Make things easy and do not make them hard; calm [people] and
  do not drive them away." — and in a narration: "...and give glad
  tidings and do not drive [people] away."
- **FR:** « Facilitez et ne rendez pas difficile ; apaisez et ne faites
  pas fuir. » — et dans une version : « ...annoncez la bonne nouvelle et
  ne faites pas fuir. »
- **[Note]:** أُبقيَت الروايتانِ («سكِّنوا» و«بشِّروا»)؛ لم يُدمَجا.

### EV‑05 — مسلم ١٧٣٢ (أبو موسى) — `source_confirmed`
- **AR:** كان رسولُ اللهِ ﷺ إذا بعثَ أحدًا من أصحابِه في بعضِ أمرِه قال:
  «بشِّروا ولا تُنفِّروا، ويسِّروا ولا تُعسِّروا».
- **EN:** When the Messenger of Allah ﷺ sent one of his Companions on
  some errand, he would say: "Give glad tidings and do not drive away;
  make things easy and do not make them hard."
- **FR:** Lorsque le Messager d'Allah ﷺ envoyait l'un de ses Compagnons
  pour une affaire, il disait : « Annoncez la bonne nouvelle et ne
  faites pas fuir ; facilitez et ne rendez pas difficile. »

### EV‑06 — الصحيحان، عبر الأدب المفرد ٤٦٢ (عائشة) — `source_confirmed`
- **AR:** دخلَ رهطٌ من اليهودِ على رسولِ اللهِ ﷺ فقالوا: السَّامُ عليكم.
  قالت عائشةُ: ففهِمتُها فقلتُ: عليكمُ السَّامُ واللعنةُ. فقال رسولُ اللهِ
  ﷺ: «مَهلًا يا عائشةُ، عليكِ بالرفقِ، وإيّاكِ والعُنفَ والفُحشَ». قالت:
  أوَلم تسمعْ ما قالوا؟ قال: «أوَلم تسمعي ما قلتُ؟ رددتُ عليهم، فيُستجابُ
  لي فيهم ولا يُستجابُ لهم فيَّ».
- **EN:** A group of the Jews came to the Messenger of Allah ﷺ and said:
  "*as-Sāmu ʿalaykum* (death be upon you)." ʿĀʾisha said: I understood it,
  so I said: "Upon you be death and the curse." The Messenger of Allah ﷺ
  said: "Gently (*mahlan*), O ʿĀʾisha; take to gentleness, and beware of
  harshness and coarse speech." She said: Did you not hear what they
  said? He said: "Did you not hear what I said? I returned it upon them,
  so [my supplication] against them is answered and theirs against me is
  not."
- **FR:** Un groupe de Juifs vint auprès du Messager d'Allah ﷺ et dit :
  « *as-Sāmu ʿalaykum* (la mort sur vous) ». ʿĀʾisha dit : Je l'ai
  compris et j'ai répondu : « Sur vous la mort et la malédiction ». Le
  Messager d'Allah ﷺ dit : « Doucement (*mahlan*), ô ʿĀʾisha ; adopte la
  douceur et garde-toi de la rudesse et de la grossièreté. » Elle dit :
  N'as-tu pas entendu ce qu'ils ont dit ? Il dit : « N'as-tu pas entendu
  ce que j'ai dit ? Je le leur ai retourné : ma [prière] contre eux est
  exaucée, et la leur contre moi ne l'est pas. »
- **[Translator note]:** «مهلًا» = "gently / slow down"؛ «الفُحش» = coarse
  / obscene speech؛ «فيُستجاب لي فيهم» أُبقيَت مبنيّةً للمجهول بلا توسيع.

### EV‑07 — الأدب المفرد ٤٦٥ («أقيلوا ذوي الهيئات») — `source_located`
- **AR:** «أقيلوا ذوي الهيئاتِ عثراتِهم».
- **EN:** "Overlook the slips of people of good standing (*dhawī
  al-hayʾāt*)."
- **FR:** « Pardonnez leurs faux pas aux gens de bonne tenue (*dhawī
  al-hayʾāt*). »
- **[Note]:** «ذوو الهيئات» مصطلحٌ محفوظٌ بالنقحرة + شرحُه في §5.

### EV‑08 — مسلم ٥٣٧ (معاوية بن الحكم) — `source_confirmed`
- **AR:** (تكلّم في الصلاة جاهلًا بالنهي، فزجرَه القومُ بأبصارِهم) ... ثمّ
  قال: «فبأبي هو وأمّي، ما رأيتُ معلِّمًا قبلَه ولا بعدَه أحسنَ تعليمًا
  منه؛ فواللهِ ما كهَرني ولا ضرَبني ولا شتَمني».
- **EN:** (Having spoken during the prayer out of ignorance of the
  prohibition, and the people having rebuked him with their glances) ...
  then he said: "By my father and mother, I have not seen a teacher
  before him or after him better in teaching than he; by Allah, he did
  not scold me (*mā kaharanī*) nor strike me nor revile me."
- **FR:** (Ayant parlé pendant la prière par ignorance de l'interdiction,
  et les gens l'ayant réprimandé du regard) ... puis il dit : « Par mon
  père et ma mère, je n'ai pas vu de maître, avant lui ni après lui,
  meilleur enseignant que lui ; par Allah, il ne m'a pas rudoyé (*mā
  kaharanī*), ni frappé, ni injurié. »
- **[Note]:** «كهر» = harsh scolding (*kahara*)؛ النفيُ الثلاثيّ «ما ...
  ولا ... ولا» محفوظٌ.

### EV‑09 — البخاري ٢١٧ (الأعرابي في المسجد) — `source_confirmed`
- **AR:** قامَ أعرابيٌّ فبالَ في المسجدِ، فتناولَه الناسُ، فقال لهمُ
  النبيُّ ﷺ: «دَعوه، وهَريقوا على بولِه سَجْلًا من ماءٍ — أو ذَنوبًا من
  ماءٍ — فإنّما بُعِثتم ميسِّرين، ولم تُبعَثوا معسِّرين».
- **EN:** A bedouin stood up and urinated in the mosque, and the people
  rushed at him. The Prophet ﷺ said to them: "Leave him, and pour over
  his urine a bucket of water — or a large bucket of water — for you were
  sent to make things easy and you were not sent to make things hard."
- **FR:** Un bédouin se leva et urina dans la mosquée ; les gens se
  précipitèrent sur lui. Le Prophète ﷺ leur dit : « Laissez-le, et versez
  sur son urine un seau d'eau — ou un grand seau d'eau — car vous avez
  été envoyés pour faciliter et non pour rendre difficile. »
- **[Note]:** «سَجْل / ذَنوب» = دلوٌ كبيرة؛ نُقِلا "bucket / large bucket"
  مع الإشارة.

### EV‑10 — جامع العلوم والحكم (ابن رجب) — `source_confirmed` — `qawl_alim`
- **AR:** قال ابنُ رجب: «وبكلِّ حالٍ يتعيَّنُ الرفقُ في الإنكارِ». ونقلَ
  عن سفيانَ الثوريِّ: «لا يأمرُ بالمعروفِ وينهى عنِ المنكرِ إلا من كان فيه
  خصالٌ ثلاثٌ: رفيقٌ بما يأمرُ رفيقٌ بما ينهى، عدلٌ بما يأمرُ عدلٌ بما
  ينهى، عالمٌ بما يأمرُ عالمٌ بما ينهى». ونقلَ عن الإمامِ أحمدَ: «الناسُ
  محتاجون إلى مُداراةٍ ...».
- **EN:** Ibn Rajab said: "In every case, gentleness in censure
  (*al-inkār*) is required." He quoted Sufyān al-Thawrī: "None should
  enjoin good and forbid evil except one who has three traits: gentle in
  what he enjoins and gentle in what he forbids, just in what he enjoins
  and just in what he forbids, knowledgeable in what he enjoins and
  knowledgeable in what he forbids." And he quoted Imām Aḥmad: "People
  are in need of gentle handling (*mudārāh*)..."
- **FR:** Ibn Rajab a dit : « En tout état de cause, la douceur dans la
  réprobation (*al-inkār*) est requise. » Il cite Sufyān al-Thawrī :
  « Nul ne devrait ordonner le bien et interdire le mal sinon celui qui
  réunit trois qualités : doux dans ce qu'il ordonne et doux dans ce
  qu'il interdit, juste... juste..., savant... savant... » Et il cite
  l'imam Aḥmad : « Les gens ont besoin d'être ménagés (*mudārāh*)... »
- **[Note]:** «الإنكار» = censure / forbidding wrong؛ التوازي الثلاثيّ
  عند سفيان محفوظٌ حرفيًّا.

### EV‑11 — الآيات (تبويب النووي) — `source_located` — `quran`
- **AR:** ﴿وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ وَاللَّهُ
  يُحِبُّ الْمُحْسِنِينَ﴾ [آل عمران: ١٣٤] · ﴿خُذِ الْعَفْوَ وَأْمُرْ
  بِالْعُرْفِ وَأَعْرِضْ عَنِ الْجَاهِلِينَ﴾ [الأعراف: ١٩٩] · ﴿ادْفَعْ
  بِالَّتِي هِيَ أَحْسَنُ ...﴾ [فصّلت: ٣٤]
- **ترجمة المعاني:** `translation_type = quran_meaning`, `status =
  pending`. **تُؤخَذ من إصدارٍ مُرخَّص** (Āl ʿImrān 3:134 · al-Aʿrāf
  7:199 · Fuṣṣilat 41:34) عند التنفيذ — **لا تُولَّد آليًّا**، ولا تُسمّى
  «ترجمة القرآن» بل **«ترجمة معاني الآية»**. الرسم وأرقام الآيات تُثبَّت من
  المصحف المحلّي.

---

## 2. المبادئ — ترجمة (`pedagogical`، `generated`)

> كتابةُ التطبيقِ نفسها، تُوسَم «منهج التطبيق التربوي» — لا تُنسَب لعالِم.

| # | AR | EN | FR |
|---|---|---|---|
| P1 | اللِّينُ طريقٌ لإيصالِ الحقِّ، لا بديلٌ عنه. | Gentleness is a means of conveying the truth, not a substitute for it. | La douceur est un moyen de transmettre la vérité, non un substitut à celle-ci. |
| P2 | حين تشتدُّ لهجتُك يَنقُصُ أثرُ كلامِك ولو كان حقًّا. | When your tone hardens, the effect of your words decreases — even if you are right. | Quand ton ton se durcit, l'effet de tes paroles diminue — même si tu as raison. |
| P3 | التماسُ اللِّينِ مقصودٌ حتى حين يصعبُ الموقفُ. | Seeking gentleness is intended even when the situation is hard. | Rechercher la douceur est visé même lorsque la situation est difficile. |
| P4 | ابدأْ بما يُقرِّبُ، وتجنَّبْ ما يُنفِّرُ، وتدرَّجْ. | Begin with what brings [people] closer, avoid what drives them away, and proceed gradually. | Commence par ce qui rapproche, évite ce qui fait fuir, et procède graduellement. |
| P5 | بيانُ الحقِّ يبقى؛ والرفقُ هو اختيارُ أخفِّ ردٍّ كافٍ. | Stating the truth remains; gentleness is choosing the lightest sufficient response — neither coarseness nor silent acquiescence. | L'énoncé de la vérité demeure ; la douceur, c'est choisir la réponse suffisante la plus légère. |
| P6 | الهفوةُ العابرةُ من أهلِ الفضلِ تُقالُ، ولا تُتتبَّعُ. | A passing slip from a person of good standing is overlooked, not tracked down. | Un faux pas passager d'une personne de bonne tenue est pardonné, non traqué. |
| P7 | الجاهلُ يُعلَّمُ لا يُزجَرُ؛ ولا تثريبَ عليه في جهلِه. | The ignorant person is taught, not scolded; there is no reproach against him for his ignorance. | L'ignorant est instruit, non réprimandé. |
| P8 | إذا كان زجرُك الآنَ يزيدُ الضررَ، فأمهِلْ، ثمّ أصلِحْ وعلِّمْ برفقٍ. | If rebuking now increases the harm, wait — then put it right and teach gently. | Si réprimander maintenant accroît le mal, patiente — puis rectifie et enseigne avec douceur. |
| P9 | لا يُقدِمُ على الإنكارِ إلا من يجمعُ: الرفقَ في الطريقةِ، والعدلَ في الحكمِ، والعلمَ بالمسألةِ. | No one should undertake censure except one who combines gentleness in method, justice in judgement, and knowledge of the matter. | Nul ne devrait entreprendre la réprobation sinon celui qui réunit la douceur dans la méthode, la justice dans le jugement et la connaissance du sujet. |

---

## 3. المهارات الفرعية — عناوينها (`pedagogical`, EN, `generated`)

| slug | AR | EN |
|---|---|---|
| rifq_ibara | اختيار أرفق عبارةٍ كافية لبيان الخطأ | Choosing the gentlest sufficient wording to point out an error |
| rifq_nabra | ضبط نبرة الصوت ولغة الجسد عند الإنكار | Controlling tone of voice and body language when censuring |
| rifq_tawqit | اختيار الوقت والمكان المناسبين للتصحيح | Choosing the right time and place to correct (privately when possible) |
| rifq_taysir | البدء بما يُقرّب قبل بيان الخطأ | Beginning with what brings closer before pointing out the error |
| rifq_fahs | فحصٌ قبليّ: أعالِمٌ؟ أعادلٌ؟ أرفيقةٌ طريقتي؟ | A prior self-check: am I knowledgeable? is my judgement just? is my method gentle? |
| rifq_jahil | الرفق بالجاهل والسائل بلا كَهْرٍ | Gentleness with the ignorant and the questioner: correcting without scolding |
| rifq_la_taqta3 | عدم قطع الموقف بعنفٍ إذا زاد الضرر | Not cutting off a situation harshly when doing so increases the harm |
| rifq_istifzaz | تعمّد اللين عند الاستفزاز | Deliberately choosing gentleness under provocation |
| rifq_hazm | الجمع بين الحزم في المضمون واللين في الأسلوب | Combining firmness in substance with softness in style |
| rifq_naqd_qawl | فصل نقد القول عن ذمّ الشخص | Separating criticism of a statement from disparaging the person |
| rifq_nush | الرفق في النصيحة: نُصحٌ لا فضيحة | Gentleness in advising: counsel, not public exposure |
| rifq_mukarrir | الرفق مع من كرّر الخطأ: صبرٌ وتدرّج | Gentleness with one who repeats a mistake: patience and gradualness |

---

## 4. السيناريوهات — نصّ الموقف (`pedagogical`, EN, `generated`)

> الخيارات وحواشيها الكاملة بالإنجليزيّة مؤجَّلة إلى مرحلة الكود (تُبنى من
> `ar-rifq.json`)؛ نصّ الموقف يكفي لإثبات أنّ غير العربيّ يستطيع التدريب.

| # | diff | EN stem |
|---|---|---|
| S‑01 | 1 | In a lesson, a peer mentioned a matter and got it wrong; there is goodwill between you. |
| S‑02 | 3 | A week ago you pointed out an error to a student; today he repeated it in another gathering. |
| S‑03 | 2 | A recently-practising man asked, in a gathering, a question some attendees considered obvious, and some smiled. |
| S‑04 | 4 | You said something in a comment; someone understood it contrary to your intent and replied sharply in public. |
| S‑05 | 3 | A peer disagreed with you on a matter with two respected positions and held to his view politely. |
| S‑06 | 5 | In a public gathering, someone said, pointing at you: "Some who put themselves forward to teach cannot read a line well." |
| S‑07 | 4 | A student delivered a benefit before the circle and attributed a statement to the wrong person. No urgent harm. |
| S‑08 | 5 | A peer conveyed your words, with a changed meaning, to a shaykh; the shaykh understood you contrary to your intent. |
| S‑09 | 6 | Five minutes remain in the lesson. A student objected to your account of a matter you are certain of; his objection contains a misunderstanding. |
| S‑10 | 7 | You hosted a peer to study. He spoke of your father with an unintended slight, then spilled tea on a book lent by your shaykh. |
| S‑11 | 7 | One student talks a great deal and interrupts others. Gentle advice → some think you fear him; harshness → the gathering breaks up. |
| S‑12 | 8 | Your shaykh mis-attributed a statement to an imam (verified, no serious ruling). You are in his gathering; a beginner wrote the error down. |

---

## 5. مسرد المصطلحات (`term_gloss`, EN, `generated`)

| المصطلح | نقحرة | EN gloss |
|---|---|---|
| الرِّفق | *rifq* | gentleness / mildness of manner; opposite of *ʿunf* (harshness) and *khurq* (clumsy roughness). |
| العُنف | *ʿunf* | harshness / roughness in word or deed; the opposite of *rifq*. |
| الكَهْر | *kahr* | harsh scolding or rebuke; to rebuff someone sternly. |
| المُداراة | *mudārāh* | gentle handling / tactful management of people, without compromising religion. |
| ذوو الهيئات | *dhawū al-hayʾāt* | people of good standing and dignity, known for uprightness. |
| الإنكار | *inkār* | censure; forbidding a wrong / objecting to it. |

---

## 6. المنهج — مخرجات المراحل (`pedagogical`, EN, `generated`)

| Stage | AR outcome | EN outcome |
|---|---|---|
| 1 | يفرّق بين «ترك الحقّ» و«تليين الأسلوب» | Distinguishes 'abandoning the truth' from 'softening the style'; cites an example from his day. |
| 2 | يردّ للحقّ لا للنفس، ولا يجاري الفُحش | When provoked, responds for the truth not for himself, and does not meet coarseness with coarseness. |
| 3 | يقول «هذا خطأ» بوضوح وبعبارة غير جارحة | Says "this is an error" clearly and in non-wounding words, and does not change the ruling to be polite. |
| 4 | يفتح التصحيح بما يُقرّب، ويقتصر على الكافي | Opens the correction with what brings closer, and limits himself to what is sufficient. |
| 5 | تحت ضغطٍ، يختار الاستجابة الليّنة الكافية | Under at least one pressure, chooses the sufficient gentle response. |
| 6 | يتثبّت قبل الإنكار، وينقد القول لا صاحبه | Verifies before censuring, criticises the statement not its author, and preserves his standing. |
| 7 | لا يُسقِط فضيلة باسم أخرى؛ يجمع | In a situation where two virtues compete, does not drop one in the name of the other; seeks to combine them. |

---

## 7. تغطية اللغات

| اللغة | الأدلّة | المبادئ | المهارات | المواقف (stem) | المنهج | المسرد | الحالة |
|---|---|---|---|---|---|---|---|
| **ar (source)** | ✔ أصل | ✔ | ✔ | ✔ | ✔ | ✔ | الأصل |
| **en** | ✔ literal | ✔ | ✔ | ✔ | ✔ | ✔ | `generated` |
| **fr** | ✔ literal | ✔ | — | — | — | — | `generated` |
| ur · id · tr | مسار جاهز | — | — | — | — | — | `pending` (تمريرة مخصّصة) |
| am | مسار جاهز | — | — | — | — | — | `pending` |
| القرآن (EV‑11) | — | — | — | — | — | — | `pending` — إصدار مُرخَّص، لا يُولَّد |

- **116 صفّ ترجمة** في `ar-rifq.json` — 75 `generated`، 41 `pending`.
- **العربيّة حاضرةٌ في كلّ صفّ**؛ لا سقوط ولا تلفيق للغةٍ بلا ترجمة.
- توسيعُ اللغات = صفوفٌ جديدةٌ في نفس المصفوفة، بلا تغيير بنية.
