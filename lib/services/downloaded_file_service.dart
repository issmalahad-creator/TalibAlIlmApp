import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Caches Telegram-hosted PDFs in the app's own permanent documents
/// directory, keyed by a stable string (a book's id, or a generic content
/// item's URL) — NOT the OS temp directory, which the system can clear at
/// any time and which `book_screen.dart` used to re-download into on every
/// single open. Once a book has been downloaded once, opening it again never
/// touches the network again and works fully offline, matching the app's
/// offline-first design.
class DownloadedFileService {
  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/downloaded_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _safeName(String key) => key.replaceAll(RegExp(r'[^\w؀-ۿ]'), '_');

  Future<File> _fileFor(String key) async {
    final dir = await _dir();
    return File('${dir.path}/${_safeName(key)}.pdf');
  }

  Future<bool> isDownloaded(String key) async => (await _fileFor(key)).exists();

  /// Returns the local file, downloading from [url] only if it isn't already
  /// cached under [key].
  Future<File> ensureDownloaded({required String key, required String url}) async {
    final file = await _fileFor(key);
    if (await file.exists()) return file;
    final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    await file.writeAsBytes(resp.bodyBytes, flush: true);
    return file;
  }
}
