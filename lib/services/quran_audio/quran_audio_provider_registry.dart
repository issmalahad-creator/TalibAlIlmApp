import 'everyayah_provider.dart';
import 'quran_audio_provider.dart';
import 'quran_foundation_provider.dart';

/// Tries providers in priority order, first configured one wins — Ismail's
/// explicit "كلاهما، أيهما فشل يفشل عادي وأيهما نجح يكمل" instruction.
/// `QuranFoundationProvider` is listed first (would take priority once it's
/// ever wired for real — see its doc comment) but stays unconfigured today,
/// so `EveryAyahProvider` is what actually serves every call right now.
class QuranAudioProviderRegistry {
  static final List<QuranAudioProvider> _providers = [
    QuranFoundationProvider(),
    EveryAyahProvider(),
  ];

  static QuranAudioProvider get active => _providers.firstWhere((p) => p.isConfigured, orElse: () => _providers.last);

  static List<QuranReciter> reciters() => active.reciters();

  static String? ayahAudioUrl({required String reciterId, required int surah, required int ayah}) =>
      active.ayahAudioUrl(reciterId: reciterId, surah: surah, ayah: ayah);
}
