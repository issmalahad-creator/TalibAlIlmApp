import '../../models/mosque.dart';

/// «مساجدنا» (Phase 74) — the seam between the app and whatever backend
/// Phase 4 picks (Supabase / Apps-Script). Callers use [MosqueApiClient];
/// they never know the transport. Mirrors the `TurathApiClient` /
/// `TurathRepository` split.
///
/// Today the only implementation is [LocalOnlyMosqueApi] — inert, so the
/// app ships and the UI runs against the seeded demo mosque with no
/// network. When the backend exists, add e.g. `SupabaseMosqueApi` and swap
/// the instance in `MosqueRepository`; nothing above changes.
abstract class MosqueApiClient {
  /// The public directory of verified, active mosques. `[]` on any failure.
  Future<List<Mosque>> listMosques();

  /// One mosque's full record + its sections + content + media, or null.
  Future<MosqueProfileDto?> fetchMosque(String mosqueId);

  /// Whether this client can actually reach a backend (drives "pull to
  /// refresh" affordances). Local-only → false.
  bool get isConfigured;
}

/// Raw payload from the backend for one mosque — the repository maps it into
/// local rows.
class MosqueProfileDto {
  final Mosque mosque;
  final List<MosqueSection> sections;
  final List<MosqueContent> content;
  final List<MosqueMediaItem> media;
  const MosqueProfileDto({
    required this.mosque,
    required this.sections,
    required this.content,
    required this.media,
  });
}

/// The shipping default: no backend. Everything comes from the local
/// database (seeded demo mosque + anything a future sync wrote).
class LocalOnlyMosqueApi implements MosqueApiClient {
  const LocalOnlyMosqueApi();

  @override
  bool get isConfigured => false;

  @override
  Future<List<Mosque>> listMosques() async => const [];

  @override
  Future<MosqueProfileDto?> fetchMosque(String mosqueId) async => null;
}
