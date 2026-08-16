import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../utils/month.dart';

class AudioResumePoint {
  final String videoId;
  final int positionSeconds;

  const AudioResumePoint({required this.videoId, required this.positionSeconds});
}

class AudioReflection {
  final int id;
  final String? videoId;
  final String text;
  final String? resumeNote;
  final String createdDate;

  const AudioReflection({
    required this.id,
    required this.videoId,
    required this.text,
    required this.resumeNote,
    required this.createdDate,
  });
}

class CustomAudioSeries {
  final int id;
  final String titleAr;
  final String? playlistId;
  final String? videoId;

  const CustomAudioSeries({
    required this.id,
    required this.titleAr,
    required this.playlistId,
    required this.videoId,
  });
}

/// Pulls a playlist id (`list=`) and/or video id (`v=` or youtu.be/ID)
/// out of any YouTube URL the user pastes in. Returns nulls if neither is
/// found — the caller shows an error rather than saving a broken entry.
class ParsedYoutubeUrl {
  final String? playlistId;
  final String? videoId;
  const ParsedYoutubeUrl({this.playlistId, this.videoId});
  bool get isValid => playlistId != null || videoId != null;
}

ParsedYoutubeUrl parseYoutubeUrl(String input) {
  final trimmed = input.trim();
  Uri? uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return const ParsedYoutubeUrl();
  }
  String? playlistId = uri.queryParameters['list'];
  String? videoId = uri.queryParameters['v'];
  if (videoId == null && uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    videoId = uri.pathSegments.first;
  }
  return ParsedYoutubeUrl(playlistId: playlistId, videoId: videoId);
}

/// Repository for "كتب صوتية من اليوتيوب" — stores only the user's own
/// resume position and self-written reflections. The audio series list
/// itself is a fixed const (`audioSeries` in audio_series_seed.dart), not
/// DB-driven, since it's app-curated metadata pointing at YouTube content
/// this app never downloads or rehosts.
class AudioLibraryRepository {
  Future<AudioResumePoint?> resumePointFor(String seriesId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('audio_progress', where: 'series_id = ?', whereArgs: [seriesId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AudioResumePoint(
      videoId: row['video_id'] as String,
      positionSeconds: row['position_seconds'] as int,
    );
  }

  Future<void> saveResumePoint(String seriesId, String videoId, int positionSeconds) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'audio_progress',
      {
        'series_id': seriesId,
        'video_id': videoId,
        'position_seconds': positionSeconds,
        'updated_date': todayDate(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All reflections for a series. Pass [videoId] to scope to one specific
  /// episode instead — used so "دفتر الفوائد" shows notes for the episode
  /// actually playing, not every note ever written across the whole
  /// series mixed together.
  Future<List<AudioReflection>> reflectionsFor(String seriesId, {String? videoId}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'audio_reflection_log',
      where: videoId == null ? 'series_id = ?' : 'series_id = ? AND video_id = ?',
      whereArgs: videoId == null ? [seriesId] : [seriesId, videoId],
      orderBy: 'id DESC',
    );
    return rows
        .map((r) => AudioReflection(
              id: r['id'] as int,
              videoId: r['video_id'] as String?,
              text: r['reflection_text'] as String,
              resumeNote: r['resume_note'] as String?,
              createdDate: r['created_date'] as String,
            ))
        .toList();
  }

  Future<void> addReflection(String seriesId, String? videoId, String text, {String? resumeNote}) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('audio_reflection_log', {
      'series_id': seriesId,
      'video_id': videoId,
      'reflection_text': text,
      'resume_note': resumeNote,
      'created_date': todayDate(),
    });
  }

  Future<void> updateReflection(int id, String text, {String? resumeNote}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'audio_reflection_log',
      {'reflection_text': text, 'resume_note': resumeNote},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReflection(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('audio_reflection_log', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalReflectionCount() async {
    final db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audio_reflection_log')) ?? 0;
  }

  Future<List<CustomAudioSeries>> listCustomSeries() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('custom_audio_series', orderBy: 'id DESC');
    return rows
        .map((r) => CustomAudioSeries(
              id: r['id'] as int,
              titleAr: r['title_ar'] as String,
              playlistId: r['playlist_id'] as String?,
              videoId: r['video_id'] as String?,
            ))
        .toList();
  }

  Future<void> addCustomSeries(String titleAr, ParsedYoutubeUrl parsed) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('custom_audio_series', {
      'title_ar': titleAr,
      'playlist_id': parsed.playlistId,
      'video_id': parsed.videoId,
      'created_date': todayDate(),
    });
  }

  Future<void> deleteCustomSeries(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('custom_audio_series', where: 'id = ?', whereArgs: [id]);
  }
}
