import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/personal_book.dart';
import '../repositories/personal_book_repository.dart';

/// Lets a student build their own personal library from PDFs already on
/// their own device — brought in from Maktaba Shamela's own app, Waqfeya,
/// or anywhere else. This app never fetches, scrapes, or redistributes
/// third-party book content itself; it only stores a permanent local copy
/// of whatever file the student already has and chooses to add, and gives
/// it the same reading experience (page bookmark, offline access) as
/// admin-sent books. This is deliberately kept this simple/local — a full
/// external-library integration (Shamela/Waqfeya import, search, etc.) is a
/// much larger, separate concern (see the future IKOS project), not this.
class PersonalLibraryService {
  final _repo = PersonalBookRepository();

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/personal_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Opens the system file picker restricted to PDFs, copies the chosen file
  /// into permanent app storage, and saves a `personal_books` row (optionally
  /// filed straight into [categoryId]). Returns null if the student
  /// cancelled the picker.
  Future<PersonalBook?> pickAndAdd({int? categoryId}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final picked = result?.files.single;
    if (picked == null || picked.path == null) return null;

    final title = picked.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final dir = await _dir();
    final safeName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(RegExp(r'[^\w؀-ۿ]'), '_')}.pdf';
    final destFile = File('${dir.path}/$safeName');
    await File(picked.path!).copy(destFile.path);

    final book = PersonalBook(
        title: title, filePath: destFile.path, addedAt: DateTime.now().toIso8601String(), categoryId: categoryId);
    final id = await _repo.add(book);
    return PersonalBook(id: id, title: book.title, filePath: book.filePath, addedAt: book.addedAt, categoryId: categoryId);
  }

  Future<List<PersonalBook>> all() => _repo.all();

  Future<void> remove(PersonalBook book) async {
    if (book.id != null) await _repo.delete(book.id!);
    final file = File(book.filePath);
    if (await file.exists()) await file.delete();
  }

  Future<List<PersonalBookCategory>> categories() => _repo.categories();

  Future<int> createCategory(String name) => _repo.addCategory(name);

  Future<void> renameCategory(int id, String name) => _repo.renameCategory(id, name);

  Future<void> deleteCategory(int id) => _repo.deleteCategory(id);
}
