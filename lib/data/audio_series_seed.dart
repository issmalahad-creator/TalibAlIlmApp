/// "كتب صوتية من اليوتيوب" (Phase 13, Ismail's request 2026-08-16) —
/// metadata-only pointers to YouTube playlists. This app never downloads
/// or rehosts the actual audio/video: every entry here is just an ID this
/// app streams through YouTube's own official embedded player, exactly
/// like the "مصادر موصى بها" screens elsewhere cite books by title/author
/// without reproducing their text. Fixed const list, not DB-driven — same
/// pattern as `wird_templates.dart`.
class AudioSeries {
  final String id;
  final String titleAr;
  final String authorAr;
  final String categoryAr;
  final String playlistId;
  final String firstVideoId;
  final String descriptionAr;

  const AudioSeries({
    required this.id,
    required this.titleAr,
    required this.authorAr,
    required this.categoryAr,
    required this.playlistId,
    required this.firstVideoId,
    required this.descriptionAr,
  });

  String get youtubePlaylistUrl =>
      'https://www.youtube.com/playlist?list=$playlistId';
}

const List<AudioSeries> audioSeries = [
  AudioSeries(
    id: 'bidayah_wa_nihayah',
    titleAr: 'البداية والنهاية',
    authorAr: 'الحافظ ابن كثير',
    categoryAr: 'كتاب صوتي',
    playlistId: 'PLdWPl6wgK3SQPjHcMSWKKrU5Qy6xYujRB',
    firstVideoId: 'gY_IPK_D_44',
    descriptionAr:
        'قراءة صوتية لكتاب "البداية والنهاية" لابن كثير، تبدأ بذكر بدء الخلق.',
  ),
  AudioSeries(
    id: 'madarij_audio',
    titleAr: 'مدارج السالكين (شرح صوتي)',
    authorAr: 'ابن القيم الجوزية',
    categoryAr: 'كتاب صوتي',
    playlistId: 'PLBOng7CIGmTr7QubIapYrhTd7caBfGCwR',
    firstVideoId: '9aKw9NarFuU',
    descriptionAr:
        'شرح صوتي لكتاب مدارج السالكين — رفيق مسموع لنص الكتاب المتوفر في قسم "مدارج السالكين" بالتطبيق.',
  ),
  AudioSeries(
    id: 'ajlan_tafsir_baqarah',
    titleAr: 'تفسير ابن كثير — سورة البقرة',
    authorAr: 'الشيخ عبدالرحمن العجلان',
    categoryAr: 'تفسير',
    playlistId: 'PLQI-l5kqLXsZpyPXSNjOASBmG48dRtNj2',
    firstVideoId: 'L8UhfiNs2TA',
    descriptionAr:
        'شرح صوتي لتفسير ابن كثير لسورة البقرة، للشيخ عبدالرحمن العجلان.',
  ),
];
