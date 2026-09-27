/// `packs_manifest.json` — the source of truth for every downloadable content
/// pack (docs/architecture/CONTENT_PACKS_ARCHITECTURE.md §3.2). A snapshot is
/// bundled so sizes show offline; the live one sits on the `packs-v1` GitHub
/// Release. Published files never change — a new version gets a new name.
class PackManifest {
  const PackManifest({required this.schema, required this.base, required this.packs});

  final int schema;

  /// URL prefix every [PackFile.name] is appended to.
  final String base;
  final List<PackInfo> packs;

  static const supportedSchema = 1;

  PackInfo? byId(String id) {
    for (final p in packs) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Unknown schema → null, so an older app never misreads a newer format.
  static PackManifest? tryParse(Map<String, dynamic> json) {
    try {
      final schema = json['schema'] as int;
      if (schema > supportedSchema) return null;
      return PackManifest(
        schema: schema,
        base: json['base'] as String,
        packs: [for (final p in json['packs'] as List) PackInfo.fromJson(p as Map<String, dynamic>)],
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'base': base,
        'packs': [for (final p in packs) p.toJson()],
      };
}

class PackInfo {
  const PackInfo({
    required this.id,
    required this.kind,
    required this.version,
    required this.title,
    required this.files,
    required this.installer,
    this.author = const {},
    this.summary = const {},
  });

  /// Stable, dotted: `tafsir.ibn_kathir`, `corpus.sayings`.
  final String id;

  /// Grouping in «التنزيلات والمساحة»: tafsir · translation · corpus · voice.
  final String kind;
  final int version;
  final Map<String, String> title;
  final Map<String, String> author;
  final Map<String, String> summary;
  final List<PackFile> files;

  /// Which installer turns downloaded files into usable content.
  final String installer;

  int get bytes => files.fold(0, (sum, f) => sum + f.bytes);

  String titleFor(String lang) => title[lang] ?? title['ar'] ?? id;
  String? authorFor(String lang) => author[lang] ?? author['ar'];
  String? summaryFor(String lang) => summary[lang] ?? summary['ar'];

  factory PackInfo.fromJson(Map<String, dynamic> j) => PackInfo(
        id: j['id'] as String,
        kind: j['kind'] as String,
        version: j['version'] as int,
        title: Map<String, String>.from(j['title'] as Map),
        author: Map<String, String>.from((j['author'] as Map?) ?? const {}),
        summary: Map<String, String>.from((j['summary'] as Map?) ?? const {}),
        files: [for (final f in j['files'] as List) PackFile.fromJson(f as Map<String, dynamic>)],
        installer: j['installer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'version': version,
        'title': title,
        if (author.isNotEmpty) 'author': author,
        if (summary.isNotEmpty) 'summary': summary,
        'files': [for (final f in files) f.toJson()],
        'installer': installer,
      };
}

class PackFile {
  const PackFile({required this.name, required this.bytes, required this.sha256});

  final String name;
  final int bytes;

  /// Lower-case hex. Mandatory: a file without one is never installed.
  final String sha256;

  factory PackFile.fromJson(Map<String, dynamic> j) =>
      PackFile(name: j['name'] as String, bytes: j['bytes'] as int, sha256: (j['sha256'] as String).toLowerCase());

  Map<String, dynamic> toJson() => {'name': name, 'bytes': bytes, 'sha256': sha256};
}
