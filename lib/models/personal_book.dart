/// A book the student picked themselves from their own device (via the
/// "مكتبتي" / My Library feature) — distinct from admin-sent [BookEntry]s.
/// The student can get this file from anywhere (Maktaba Shamela's own app,
/// Waqfeya, a friend, anywhere) — this app never fetches or hosts it itself,
/// just stores a permanent local copy and gives it the same reading
/// experience (progress bookmark, offline access) as admin-sent books.
class PersonalBook {
  final int? id;
  final String title;
  final String filePath;
  final String addedAt;

  /// Which "قسم" (section/folder) this book was filed under — the student's
  /// own organizational category, e.g. "الفقه". Null = uncategorized.
  final int? categoryId;

  PersonalBook({this.id, required this.title, required this.filePath, required this.addedAt, this.categoryId});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'file_path': filePath,
        'added_at': addedAt,
        'category_id': categoryId,
      };

  factory PersonalBook.fromMap(Map<String, dynamic> map) => PersonalBook(
        id: map['id'] as int?,
        title: map['title'] as String,
        filePath: map['file_path'] as String,
        addedAt: map['added_at'] as String,
        categoryId: map['category_id'] as int?,
      );
}

/// A student-created organizational section/folder for [PersonalBook]s (e.g.
/// "الفقه", "العقيدة") — purely local, no relation to the admin-sent book
/// list or the Telegram content feed.
class PersonalBookCategory {
  final int? id;
  final String name;

  PersonalBookCategory({this.id, required this.name});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };

  factory PersonalBookCategory.fromMap(Map<String, dynamic> map) => PersonalBookCategory(
        id: map['id'] as int?,
        name: map['name'] as String,
      );
}
