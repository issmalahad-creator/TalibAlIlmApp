/// "محاسبة الوقت" — Ismail's request 2026-08-16: a reminder, grounded in a
/// real, well-known hadith (not invented), that every hour is a trust and
/// will be asked about on the Day of Judgment. The hadith below is Sunan
/// al-Tirmidhi #2417, one of the most widely cited hadiths on this exact
/// topic — At-Tirmidhi himself graded it "حسن صحيح", and Al-Albani graded
/// it Sahih in "صحيح الجامع". Cited by its known standard wording, not a
/// paraphrase.
library;

const timeAccountabilityHadith =
    'لَا تَزُولُ قَدَمَا عَبْدٍ يَوْمَ الْقِيَامَةِ حَتَّى يُسْأَلَ عَنْ عُمُرِهِ فِيمَا أَفْنَاهُ، وَعَنْ عِلْمِهِ فِيمَ فَعَلَ، وَعَنْ مَالِهِ مِنْ أَيْنَ اكْتَسَبَهُ وَفِيمَ أَنْفَقَهُ، وَعَنْ جِسْمِهِ فِيمَ أَبْلَاهُ';
const timeAccountabilityHadithSource = 'رواه الترمذي (٢٤١٧) وقال: حديث حسن صحيح، وصححه الألباني في صحيح الجامع';

class TimeTip {
  final String titleAr;
  final String bodyAr;
  const TimeTip({required this.titleAr, required this.bodyAr});
}

/// Original, practical tips — not a translation of any single book, same
/// pattern as `practical_lessons_seed.dart`.
const timeAwarenessTips = [
  TimeTip(
    titleAr: 'اجعل لكل ساعة نية',
    bodyAr: 'قبل أن تبدأ أي عمل — دراسة، عمل، راحة — استحضر نيتك فيه. الساعة نفسها تتحول من "وقت يمضي" إلى عبادة بمجرد أن تنويها لله.',
  ),
  TimeTip(
    titleAr: 'استثمر وقت الانتظار',
    bodyAr: 'الطابور، الطريق، انتظار موعد — دقائق متناثرة تجتمع لساعات كل أسبوع. اجعلها فرصة لذكر، أو استماع لمقطع مفيد، أو مراجعة ما حفظته.',
  ),
  TimeTip(
    titleAr: 'قسّم يومك بخطة بسيطة',
    bodyAr: 'لا تحتاج جدولًا معقدًا — فقط 3-4 أوقات ثابتة لأهم ما تريد إنجازه. الخطة البسيطة التي تُنفَّذ خير من الخطة المثالية التي تبقى حبرًا على ورق.',
  ),
  TimeTip(
    titleAr: 'راقب أين تذهب ساعاتك فعلًا',
    bodyAr: 'قبل أن تحاسب نفسك، اعرف الحقيقة أولًا — سجّل بصدق كم ساعة قضيتها فيما ينفعك اليوم. المعرفة الصادقة بداية كل تحسّن حقيقي.',
  ),
  TimeTip(
    titleAr: 'لا تحقر ساعة صغيرة',
    bodyAr: 'عشر دقائق يوميًا في القرآن = أكثر من 60 ساعة بالسنة. الساعات الكبيرة تُبنى من دقائق صغيرة متكررة، لا من قرارات ضخمة نادرة.',
  ),
];
