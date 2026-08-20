/// One reciter offered by a `QuranAudioProvider`.
class QuranReciter {
  final String id; // stable, provider-scoped key (used as the local download folder name too)
  final String nameAr;
  const QuranReciter({required this.id, required this.nameAr});
}

/// Swappable Quran-recitation audio source — Ismail's 2026-08-16 P0 request
/// ("افصل مصدر التلاوة عن محرك الحفظ"). `QuranAudioEngine`/
/// `QuranAudioDownloadService` only ever talk to this interface, never to a
/// concrete provider directly, so a provider can fail or be unconfigured
/// without the memorization feature breaking — see
/// `QuranAudioProviderRegistry`'s doc comment for the actual fallback order.
abstract class QuranAudioProvider {
  String get id;
  String get displayNameAr;

  /// Whether this provider is actually usable right now. `EveryAyahProvider`
  /// is always `true` (no signup needed). `QuranFoundationProvider` is
  /// always `false` in this version — see its doc comment for why.
  bool get isConfigured;

  List<QuranReciter> reciters();

  /// The playable/downloadable URL for one ayah, or null if this provider
  /// can't serve it (unconfigured, or the reciter/ayah isn't available).
  String? ayahAudioUrl({required String reciterId, required int surah, required int ayah});
}
