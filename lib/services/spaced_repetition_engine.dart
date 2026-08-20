/// Pure station-scheduling logic — extracted from
/// `MemorizationRepository.recordReview`'s 6-station engine so a second
/// pillar (`KnowledgeReviewRepository`, Ismail's 2026-08-16 "الدماغ الذي
/// يربط" request, Batch 1) can reuse the exact same promotion/demotion
/// rules without duplicating them or touching Quran's own repository.
/// Deliberately has zero database access — it only computes what the next
/// station/status/interval should be given the current state and a review
/// quality; the caller (a repository) is responsible for reading the
/// current row and writing the outcome.
library;

enum ReviewQuality { excellent, good, needsReview }

const stationDays = [1, 3, 7, 14, 30, 60];
const establishedRotationDays = 30;
const needsReviewFallbackStation = 2;

/// The result of one review: what to write back. `status`/`station` are
/// always the actual values to persist (already resolved — e.g. a `good`
/// review on an established item resolves to `status: 'established'`,
/// `station: null`, matching `MemorizationRepository`'s behavior of leaving
/// those columns untouched on a `good` review).
class StationOutcome {
  final String status; // 'reviewing' | 'established'
  final int? station;
  final int intervalDays;
  final int consecutiveGoodCount;
  const StationOutcome({
    required this.status,
    required this.station,
    required this.intervalDays,
    required this.consecutiveGoodCount,
  });
}

/// Mirrors `MemorizationRepository.recordReview`'s three branches exactly:
/// - `needsReview`: always drops to a fixed station 2 (3-day interval),
///   regardless of current station; resets the good-streak.
/// - `good`: stays at the same station (or stays established), just
///   reschedules `next_review_date`; increments the good-streak.
/// - `excellent`: advances one station; graduates to `established`
///   (permanent 30-day rotation) if already at the top station.
StationOutcome nextStation({
  required String currentStatus,
  required int? currentStation,
  required int consecutiveGoodCount,
  required ReviewQuality quality,
}) {
  switch (quality) {
    case ReviewQuality.needsReview:
      return const StationOutcome(
        status: 'reviewing',
        station: needsReviewFallbackStation,
        intervalDays: 3, // stationDays[needsReviewFallbackStation - 1]
        consecutiveGoodCount: 0,
      );

    case ReviewQuality.good:
      final station = currentStation ?? stationDays.length;
      return StationOutcome(
        status: currentStatus,
        station: currentStation,
        intervalDays: stationDays[station - 1],
        consecutiveGoodCount: consecutiveGoodCount + 1,
      );

    case ReviewQuality.excellent:
      final station = currentStation ?? stationDays.length;
      if (station >= stationDays.length) {
        return StationOutcome(
          status: 'established',
          station: null,
          intervalDays: establishedRotationDays,
          consecutiveGoodCount: consecutiveGoodCount + 1,
        );
      }
      final nextStationNum = station + 1;
      return StationOutcome(
        status: 'reviewing',
        station: nextStationNum,
        intervalDays: stationDays[nextStationNum - 1],
        consecutiveGoodCount: consecutiveGoodCount + 1,
      );
  }
}
