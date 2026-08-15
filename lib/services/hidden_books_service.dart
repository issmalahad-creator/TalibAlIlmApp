import 'package:shared_preferences/shared_preferences.dart';

/// Optional, per-device book hiding — a student can declutter their own
/// book list without touching the shared admin data in the Sheet (that's
/// what the admin's "#حذف_اخر_كتاب" Telegram command is for; this is purely
/// local and always reversible). Ismail explicitly asked for deletion to be
/// "اختياري وليس إجباري" (optional, not mandatory) from the student's side.
class HiddenBooksService {
  static const _key = 'hidden_book_ids';

  Future<Set<String>> getHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> hide(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet()..add(bookId);
    await prefs.setStringList(_key, ids.toList());
  }

  Future<void> unhide(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet()..remove(bookId);
    await prefs.setStringList(_key, ids.toList());
  }
}
