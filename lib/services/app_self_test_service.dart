import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/curriculum_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/placement_repository.dart';
import '../repositories/worship_coach_repository.dart';
import 'companion_chat_engine.dart';

class SelfTestResult {
  final String name;
  final bool passed;
  final String detail;
  const SelfTestResult({required this.name, required this.passed, required this.detail});
}

/// "اختبار شامل" (Ismail's 2026-08-20 request) — a real, on-device smoke
/// test suite Ismail runs on his own phone, since this dev environment has
/// no direct access to a real device's actual runtime state. Every check is
/// wrapped so one failure never stops the rest; results feed
/// `ClaudeDiagnosticsService` for analysis, or get copied raw to a future
/// Claude Code session. Deliberately a flat list of independent checks, not
/// a test framework — this runs inside the shipped app itself, not `flutter
/// test`, so it has to stay simple and dependency-free.
class AppSelfTestService {
  Future<List<SelfTestResult>> runAll() async {
    final checks = <Future<SelfTestResult> Function()>[
      _checkDatabaseOpens,
      _checkQuranAyatCount,
      _checkTafsirSourcesPresent,
      _checkMemorizationDueToday,
      _checkCompletionGoals,
      _checkCurriculumStatuses,
      _checkKnowledgeReviewDueToday,
      _checkPlacementRepository,
      _checkWorshipCoach,
      _checkCompanionEngine,
    ];
    final results = <SelfTestResult>[];
    for (final check in checks) {
      try {
        results.add(await check());
      } catch (e, st) {
        results.add(SelfTestResult(name: check.toString(), passed: false, detail: '$e\n$st'));
      }
    }
    return results;
  }

  Future<SelfTestResult> _checkDatabaseOpens() async {
    final db = await DatabaseHelper.instance.database;
    final version = await db.getVersion();
    return SelfTestResult(name: 'فتح قاعدة البيانات', passed: version > 0, detail: 'إصدار المخطط: $version');
  }

  Future<SelfTestResult> _checkQuranAyatCount() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM quran_ayat');
    final count = rows.first['c'] as int;
    return SelfTestResult(
      name: 'عدد آيات القرآن المستوردة',
      passed: count == 6236,
      detail: count == 6236 ? '6236 آية (صحيح)' : 'العدد الفعلي: $count — متوقَّع 6236',
    );
  }

  Future<SelfTestResult> _checkTafsirSourcesPresent() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('SELECT source, COUNT(*) AS c FROM tafsir_entries GROUP BY source');
    if (rows.isEmpty) return const SelfTestResult(name: 'مصادر التفسير', passed: false, detail: 'لا يوجد أي تفسير مستورد');
    final summary = rows.map((r) => '${r['source']}: ${r['c']}').join('، ');
    return SelfTestResult(name: 'مصادر التفسير', passed: true, detail: summary);
  }

  Future<SelfTestResult> _checkMemorizationDueToday() async {
    final due = await MemorizationRepository().dueToday();
    return SelfTestResult(name: 'محرك مراجعة الحفظ (dueToday)', passed: true, detail: '${due.length} صفحة مستحقة اليوم');
  }

  Future<SelfTestResult> _checkCompletionGoals() async {
    final goals = await CompletionGoalRepository().activeGoals();
    return SelfTestResult(name: 'خطط الختم النشطة', passed: true, detail: '${goals.length} خطة نشطة');
  }

  Future<SelfTestResult> _checkCurriculumStatuses() async {
    final statuses = await CurriculumRepository().allStatuses();
    final totalItems = statuses.values.fold<int>(0, (sum, list) => sum + list.length);
    return SelfTestResult(name: 'خريطة المنهج (allStatuses)', passed: totalItems > 0, detail: '$totalItems عنصر عبر ${statuses.length} مستوى');
  }

  Future<SelfTestResult> _checkKnowledgeReviewDueToday() async {
    final due = await KnowledgeReviewRepository().dueTodayAll();
    final total = due.values.fold<int>(0, (sum, list) => sum + list.length);
    return SelfTestResult(name: 'مراجعة الحديث/الواسطية/الأذكار', passed: true, detail: '$total عنصر مستحق اليوم');
  }

  Future<SelfTestResult> _checkPlacementRepository() async {
    final done = await PlacementRepository().hasCompleted();
    return SelfTestResult(name: 'اختبار تحديد المستوى (رسالتي)', passed: true, detail: done ? 'مكتمل' : 'لم يُنجَز بعد');
  }

  Future<SelfTestResult> _checkWorshipCoach() async {
    final consistency = await WorshipCoachRepository().prayerConsistency();
    return SelfTestResult(
      name: 'مدرب العبادة (استمرارية الصلاة)',
      passed: consistency >= 0 && consistency <= 1,
      detail: '${(consistency * 100).toStringAsFixed(0)}% خلال آخر 7 أيام',
    );
  }

  Future<SelfTestResult> _checkCompanionEngine() async {
    final engine = CompanionChatEngine();
    final id = engine.matchIntentId('السلام عليكم');
    return SelfTestResult(
      name: 'محرك الرفيق (تطابق أساسي)',
      passed: id == 'greeting',
      detail: id == 'greeting' ? 'تطابق التحية يعمل بشكل صحيح' : 'فشل التطابق — النتيجة: $id',
    );
  }
}
