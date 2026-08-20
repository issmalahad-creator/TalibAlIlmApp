import 'quran_audio_provider.dart';

/// EveryAyah.com — verified directly (2026-08-16, via `WebFetch`, not
/// assumed) to serve one mp3 per ayah at
/// `https://everyayah.com/data/{folder}/{surah:03}{ayah:03}.mp3` (e.g.
/// `001001.mp3` = surah 1, ayah 1) across 70 real reciter folders at
/// multiple bitrates. This curated list picks ONE bitrate per reciter
/// (preferring 128kbps as the mobile-data/quality balance, falling back to
/// whatever's available) instead of listing all 70 folders — most are
/// duplicate bitrates of the same reciter, which would just clutter the
/// picker. `Husary_Muallim_128kbps` ("الحصري - المعلم") is kept as its own
/// separate entry despite being the same reciter as `Husary_128kbps`: it's
/// the deliberately slow, pause-per-word "teacher" recitation style made
/// specifically for memorization repetition, which is exactly this
/// feature's purpose.
///
/// Works with zero configuration — no signup, no secret, nothing to enter —
/// which is why this is the provider actually running in the app today
/// (see `QuranFoundationProvider`'s doc comment for why that one isn't).
/// The license terms EveryAyah itself points to
/// (`versebyversequran.com/site/license`) are currently a dead link (404,
/// confirmed via `WebFetch`) — reported honestly to Ismail rather than
/// assumed permissive; this is the accepted, known gap in using this
/// source for now.
class EveryAyahProvider implements QuranAudioProvider {
  @override
  String get id => 'everyayah';

  @override
  String get displayNameAr => 'EveryAyah.com';

  @override
  bool get isConfigured => true;

  static const _reciters = [
    QuranReciter(id: 'Alafasy_128kbps', nameAr: 'مشاري العفاسي'),
    QuranReciter(id: 'Abdul_Basit_Murattal_192kbps', nameAr: 'عبد الباسط عبد الصمد (مرتل)'),
    QuranReciter(id: 'Abdul_Basit_Mujawwad_128kbps', nameAr: 'عبد الباسط عبد الصمد (مجوّد)'),
    QuranReciter(id: 'Husary_128kbps', nameAr: 'محمود خليل الحصري'),
    QuranReciter(id: 'Husary_Muallim_128kbps', nameAr: 'الحصري — المعلّم (للتحفيظ)'),
    QuranReciter(id: 'Abdurrahmaan_As-Sudais_192kbps', nameAr: 'عبد الرحمن السديس'),
    QuranReciter(id: 'Saood_ash-Shuraym_128kbps', nameAr: 'سعود الشريم'),
    QuranReciter(id: 'Minshawy_Murattal_128kbps', nameAr: 'محمد صديق المنشاوي (مرتل)'),
    QuranReciter(id: 'MaherAlMuaiqly128kbps', nameAr: 'ماهر المعيقلي'),
    QuranReciter(id: 'Abdullah_Basfar_192kbps', nameAr: 'عبد الله بصفر'),
    QuranReciter(id: 'Hudhaify_128kbps', nameAr: 'علي الحذيفي'),
    QuranReciter(id: 'Ghamadi_40kbps', nameAr: 'سعد الغامدي'),
    QuranReciter(id: 'Muhammad_Ayyoub_128kbps', nameAr: 'محمد أيوب'),
    QuranReciter(id: 'Yasser_Ad-Dussary_128kbps', nameAr: 'ياسر الدوسري'),
    QuranReciter(id: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', nameAr: 'أحمد العجمي'),
    QuranReciter(id: 'Abu_Bakr_Ash-Shaatree_128kbps', nameAr: 'أبو بكر الشاطري'),
    QuranReciter(id: 'warsh', nameAr: 'ورش عن نافع (رواية)'),
  ];

  @override
  List<QuranReciter> reciters() => _reciters;

  @override
  String? ayahAudioUrl({required String reciterId, required int surah, required int ayah}) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterId/$s$a.mp3';
  }
}
