/// «مساجدنا» (Phase 74) — plain data for the mosque platform's local layer.
/// The backend (Phase 4) is the source of truth for a mosque; these rows are
/// its offline read-cache. `Mosque.id` (e.g. `MOSQ_000001`) is the permanent
/// identity — never a Telegram `chat_id`. See `docs/MOSQUE_PLATFORM_VISION.md`.
library;

int _i(Object? v, [int d = 0]) => v is int ? v : (v is num ? v.toInt() : d);
double? _d(Object? v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
bool _b(Object? v) => v == true || v == 1 || v == '1' || v == 'true';
String _s(Object? v, [String d = '']) => v?.toString() ?? d;
String? _sn(Object? v) => v?.toString();

/// The content kinds a mosque can publish. `activity` reuses the same table
/// as the rest (with the event_* columns); a dedicated activities table can
/// come in Phase 4 if it earns its place.
enum MosqueContentKind {
  lesson,
  khutbah,
  announcement,
  recording,
  library,
  need,
  activity;

  static MosqueContentKind fromKey(String? k) => switch (k) {
        'lesson' => MosqueContentKind.lesson,
        'khutbah' => MosqueContentKind.khutbah,
        'announcement' => MosqueContentKind.announcement,
        'recording' => MosqueContentKind.recording,
        'library' => MosqueContentKind.library,
        'need' => MosqueContentKind.need,
        'activity' => MosqueContentKind.activity,
        _ => MosqueContentKind.announcement,
      };

  String get key => name;

  /// i18n key for the section's label — resolved with `basicText()`.
  String get labelKey => 'mosque_kind_$name';
}

class Mosque {
  final String id;
  final String name;
  final String? imamName;
  final String? description;
  final String? city;
  final String? area;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? imageUrl;
  final bool verified;
  final String status; // active | pending | suspended
  final bool isMine;
  final bool isDemo;
  final String? syncedAt;
  final String createdAt;

  const Mosque({
    required this.id,
    required this.name,
    this.imamName,
    this.description,
    this.city,
    this.area,
    this.lat,
    this.lng,
    this.phone,
    this.imageUrl,
    this.verified = false,
    this.status = 'active',
    this.isMine = false,
    this.isDemo = false,
    this.syncedAt,
    required this.createdAt,
  });

  String get locationLabel =>
      [city, area].where((e) => (e ?? '').isNotEmpty).join(' · ');

  bool get hasGeo => lat != null && lng != null;

  factory Mosque.fromRow(Map<String, Object?> r) => Mosque(
        id: _s(r['id']),
        name: _s(r['name']),
        imamName: _sn(r['imam_name']),
        description: _sn(r['description']),
        city: _sn(r['city']),
        area: _sn(r['area']),
        lat: _d(r['lat']),
        lng: _d(r['lng']),
        phone: _sn(r['phone']),
        imageUrl: _sn(r['image_url']),
        verified: _b(r['verified']),
        status: _s(r['status'], 'active'),
        isMine: _b(r['is_mine']),
        isDemo: _b(r['is_demo']),
        syncedAt: _sn(r['synced_at']),
        createdAt: _s(r['created_at']),
      );

  factory Mosque.fromJson(Map<String, dynamic> j) => Mosque(
        id: _s(j['id']),
        name: _s(j['name']),
        imamName: _sn(j['imam_name'] ?? j['imamName']),
        description: _sn(j['description']),
        city: _sn(j['city']),
        area: _sn(j['area']),
        lat: _d(j['lat']),
        lng: _d(j['lng']),
        phone: _sn(j['phone']),
        imageUrl: _sn(j['image_url'] ?? j['imageUrl']),
        verified: _b(j['verified']),
        status: _s(j['status'], 'active'),
        syncedAt: DateTime.now().toUtc().toIso8601String(),
        createdAt: _s(j['created_at'] ?? DateTime.now().toUtc().toIso8601String()),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'imam_name': imamName,
        'description': description,
        'city': city,
        'area': area,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        'image_url': imageUrl,
        'verified': verified ? 1 : 0,
        'status': status,
        'is_mine': isMine ? 1 : 0,
        'is_demo': isDemo ? 1 : 0,
        'synced_at': syncedAt,
        'created_at': createdAt,
      };
}

class MosqueSection {
  final String mosqueId;
  final MosqueContentKind type;
  final String title;
  final String? icon;
  final bool enabled;
  final int sortOrder;

  const MosqueSection({
    required this.mosqueId,
    required this.type,
    required this.title,
    this.icon,
    this.enabled = true,
    this.sortOrder = 0,
  });

  factory MosqueSection.fromRow(Map<String, Object?> r) => MosqueSection(
        mosqueId: _s(r['mosque_id']),
        type: MosqueContentKind.fromKey(r['type'] as String?),
        title: _s(r['title']),
        icon: _sn(r['icon']),
        enabled: _b(r['enabled']),
        sortOrder: _i(r['sort_order']),
      );

  Map<String, Object?> toRow() => {
        'mosque_id': mosqueId,
        'type': type.key,
        'title': title,
        'icon': icon,
        'enabled': enabled ? 1 : 0,
        'sort_order': sortOrder,
      };
}

class MosqueContent {
  final String id;
  final String mosqueId;
  final MosqueContentKind kind;
  final String? title;
  final String? description;
  final String? mediaUrl;
  final String? mediaKind; // audio | pdf | video | image | link
  final String? eventDate;
  final String? startsAt;
  final String? endsAt;
  final String? location;
  final String? organizer;
  final String status; // published | pending | draft | rejected
  final bool pinned;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  const MosqueContent({
    required this.id,
    required this.mosqueId,
    required this.kind,
    this.title,
    this.description,
    this.mediaUrl,
    this.mediaKind,
    this.eventDate,
    this.startsAt,
    this.endsAt,
    this.location,
    this.organizer,
    this.status = 'published',
    this.pinned = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasMedia => (mediaUrl ?? '').isNotEmpty;
  bool get isAudio => mediaKind == 'audio';

  factory MosqueContent.fromRow(Map<String, Object?> r) => MosqueContent(
        id: _s(r['id']),
        mosqueId: _s(r['mosque_id']),
        kind: MosqueContentKind.fromKey(r['kind'] as String?),
        title: _sn(r['title']),
        description: _sn(r['description']),
        mediaUrl: _sn(r['media_url']),
        mediaKind: _sn(r['media_kind']),
        eventDate: _sn(r['event_date']),
        startsAt: _sn(r['starts_at']),
        endsAt: _sn(r['ends_at']),
        location: _sn(r['location']),
        organizer: _sn(r['organizer']),
        status: _s(r['status'], 'published'),
        pinned: _b(r['pinned']),
        createdBy: _sn(r['created_by']),
        createdAt: _s(r['created_at']),
        updatedAt: _s(r['updated_at']),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'mosque_id': mosqueId,
        'kind': kind.key,
        'title': title,
        'description': description,
        'media_url': mediaUrl,
        'media_kind': mediaKind,
        'event_date': eventDate,
        'starts_at': startsAt,
        'ends_at': endsAt,
        'location': location,
        'organizer': organizer,
        'status': status,
        'pinned': pinned ? 1 : 0,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class MosqueMediaItem {
  final String id;
  final String mosqueId;
  final String category; // mosque | circle | activity | project | event
  final String? contentId;
  final String url;
  final String? caption;
  final String? date;

  const MosqueMediaItem({
    required this.id,
    required this.mosqueId,
    required this.category,
    this.contentId,
    required this.url,
    this.caption,
    this.date,
  });

  factory MosqueMediaItem.fromRow(Map<String, Object?> r) => MosqueMediaItem(
        id: _s(r['id']),
        mosqueId: _s(r['mosque_id']),
        category: _s(r['category'], 'mosque'),
        contentId: _sn(r['content_id']),
        url: _s(r['url']),
        caption: _sn(r['caption']),
        date: _sn(r['date']),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'mosque_id': mosqueId,
        'category': category,
        'content_id': contentId,
        'url': url,
        'caption': caption,
        'date': date,
      };
}

/// Everything one mosque profile needs in a single read.
class MosqueProfile {
  final Mosque mosque;
  final List<MosqueSection> sections; // enabled, sorted
  final Map<MosqueContentKind, List<MosqueContent>> previews; // few per section
  final List<MosqueMediaItem> gallery; // recent

  const MosqueProfile({
    required this.mosque,
    required this.sections,
    required this.previews,
    required this.gallery,
  });
}
