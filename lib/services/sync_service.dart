import '../repositories/submission_repository.dart';
import 'sheets_service.dart';
import 'telegram_service.dart';

/// Queues monthly reports locally and pushes them to Telegram + Google
/// Sheets whenever connectivity allows. Safe to call [retryPending]
/// repeatedly (e.g. on every connectivity-restored event or app launch) —
/// already-sent destinations are skipped.
class SyncService {
  final _submissionRepo = SubmissionRepository();
  final _telegram = TelegramService();
  final _sheets = SheetsService();

  // Static (shared across every SyncService instance — the app creates
  // several) so a submission row can never be processed by two overlapping
  // calls at once. Without this, a connectivity blip during an in-flight
  // send triggers a concurrent retryPending() that re-sends the same
  // not-yet-marked-sent row, duplicating it in Telegram/Sheets.
  static final Set<int> _inFlightIds = {};

  Future<void> submit(String month, Map<String, dynamic> payload, String telegramText) async {
    final id = await _submissionRepo.enqueue(month, {
      ...payload,
      '_telegram_text': telegramText,
    });
    await _trySend(id, payload, telegramText);
  }

  Future<void> retryPending() async {
    final pending = await _submissionRepo.pending();
    for (final item in pending) {
      final text = item.payload['_telegram_text'] as String? ?? '';
      await _trySend(item.id, item.payload, text, alreadyTelegramSent: item.telegramSent, alreadySheetsSent: item.sheetsSent);
    }
  }

  Future<void> _trySend(
    int id,
    Map<String, dynamic> payload,
    String telegramText, {
    bool alreadyTelegramSent = false,
    bool alreadySheetsSent = false,
  }) async {
    if (_inFlightIds.contains(id)) return;
    _inFlightIds.add(id);
    try {
      if (!alreadyTelegramSent) {
        final ok = await _telegram.sendToAllAdmins(telegramText);
        if (ok) await _submissionRepo.markTelegramSent(id);
      }
      if (!alreadySheetsSent) {
        final ok = await _sheets.submit(payload);
        if (ok) await _submissionRepo.markSheetsSent(id);
      }
    } finally {
      _inFlightIds.remove(id);
    }
  }

  Future<bool> hasSubmittedForMonth(String month) => _submissionRepo.hasSubmittedForMonth(month);
}
