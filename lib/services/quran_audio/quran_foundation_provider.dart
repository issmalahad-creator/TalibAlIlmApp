import 'quran_audio_provider.dart';

/// Official Quran Foundation Content API (`api.quran.foundation`) —
/// Ismail's registered app, real `client_id`/`client_secret` obtained
/// 2026-08-16. Deliberately **inert** in this version: the API's own
/// authentication docs state explicitly, in these words, "Do not call the
/// token endpoint from browser or mobile code" — a `client_credentials`
/// token exchange requires the client secret in the request, and any
/// secret embedded in a distributed app binary can be extracted by
/// decompiling it. TalibAlIlmApp has no backend server to hold the secret
/// instead (it's local-first by design everywhere else in this app), and
/// standing one up just for this is a much bigger project than this pass.
///
/// So: this class exists so the `QuranAudioProvider` abstraction is ready
/// for it, but `isConfigured` stays `false` and it makes no network calls
/// at all — `QuranAudioProviderRegistry` skips it silently and falls
/// through to `EveryAyahProvider`, which needs no secret. Wiring this for
/// real later means adding a small server-side token-proxy endpoint the
/// app calls instead of talking to `oauth2.quran.foundation` directly —
/// that's the piece to build first, not this class.
class QuranFoundationProvider implements QuranAudioProvider {
  @override
  String get id => 'quran_foundation';

  @override
  String get displayNameAr => 'Quran Foundation';

  @override
  bool get isConfigured => false;

  @override
  List<QuranReciter> reciters() => const [];

  @override
  String? ayahAudioUrl({required String reciterId, required int surah, required int ayah}) => null;
}
