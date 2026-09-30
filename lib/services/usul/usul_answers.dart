import 'narrator_tiers.dart';

/// U2 of docs/quran/USUL_TAFSIR_TREE.md — what each node of the usul-tafsir
/// tree says about ONE ayah, from data we ship. Pure (no DB) so every rule
/// is tested directly.
///
/// The honest states of §3 — never a score:
/// * [UsulStatus.sourced] — the source itself says it; evidence is quoted.
/// * [UsulStatus.curated] — «منسَّق ومُراجَع»: an usul book names this ayah
///   as an example of the node (U5), quoted with its page.
/// * [UsulStatus.hint] — «قد ينطبق — للمراجعة», an automatic signal shown
///   differently, never as an answer.
/// * [UsulStatus.notFound] — «لم نجد في مصادرنا».
/// * [UsulStatus.notDownloaded] — lite build without the athar pack.
enum UsulStatus { sourced, curated, hint, notFound, notDownloaded }

class UsulEvidence {
  const UsulEvidence({required this.text, required this.sayer, required this.source, this.judgment});

  /// A short verbatim excerpt (clipped at a word, marked «…»).
  final String text;

  /// Who said it (the narrators as the source lists them), or the book.
  final String sayer;

  /// Where it is quoted from.
  final String source;

  /// For the «النقل» branch: the takhrij's own verdict, quoted.
  final String? judgment;
}

class UsulNodeAnswer {
  const UsulNodeAnswer(this.status, {this.evidence = const [], this.count = 0});
  final UsulStatus status;

  /// At most three items — the card is a quick read; «للمزيد» opens the rest.
  final List<UsulEvidence> evidence;

  /// How many sourced items exist in total.
  final int count;

  static const notFound = UsulNodeAnswer(UsulStatus.notFound);
  static const notDownloaded = UsulNodeAnswer(UsulStatus.notDownloaded);
}

/// Answer keys used by the tree's `usul_answer` blocks.
abstract final class UsulKeys {
  static const bayanNabawi = 'bayan_nabawi';
  static const ikhtilaf = 'ikhtilaf_explicit';
  static const nuzul = 'nuzul';
  static const ijma = 'ijma';
  static const naql = 'naql';
  static const turuqSahabi = 'turuq_sahabi';
  static const turuqTabii = 'turuq_tabii';
  static const all = [bayanNabawi, ikhtilaf, nuzul, ijma, naql, turuqSahabi, turuqTabii];
}

const athar = 'أقوال السلف (Quranpedia)';
const _maxEvidence = 3;
const _excerpt = 220;

final _marfu = RegExp(
    r'(قال رسول الله ﷺ|أنّ? (?:رسول الله|النبي) ﷺ قال|سمعت (?:رسول الله|النبي) ﷺ|سألت (?:رسول الله|النبي) ﷺ|عن النبي ﷺ)');
final _ijma = RegExp(r'أجمع|إجماع|لا خلاف');
final _ikhtilaf = RegExp(r'اختلف|اختلاف');
final _judgment = RegExp(r'إسناده صحيح|إسناده حسن|إسناده ضعيف جدًّا|إسناده ضعيف|مرسل|منقطع|موضوع|إسرائيلي');

/// [sayings] = the ayah's athar list as stored (null → pack not installed);
/// [asbab] = rows from the bundled asbāb books ({name, html}).
Map<String, UsulNodeAnswer> usulAnswersFor({required List<Object?>? sayings, List<Map<String, Object?>> asbab = const []}) {
  final out = <String, UsulNodeAnswer>{};
  final nuzulFromBooks = [
    for (final r in asbab)
      UsulEvidence(text: _clip(_plain(r['html'] as String? ?? '')), sayer: r['name'] as String? ?? '', source: r['name'] as String? ?? ''),
  ];

  if (sayings == null) {
    for (final k in UsulKeys.all) {
      out[k] = UsulNodeAnswer.notDownloaded;
    }
    // Asbāb books are bundled in both flavors — still answer from them.
    if (nuzulFromBooks.isNotEmpty) out[UsulKeys.nuzul] = _sourced(nuzulFromBooks);
    return out;
  }

  final buckets = {for (final k in UsulKeys.all) k: <UsulEvidence>[]};
  var tafsirSayings = 0;
  for (final raw in sayings) {
    if (raw is! Map) continue;
    final html = raw['text'] as String? ?? '';
    final body = _plain(html.split('<footer').first);
    final notes = RegExp(r'title="([^"]*)"').allMatches(html).map((m) => m.group(1)!).join(' ');
    final type = raw['type'] as String? ?? '';
    final names = [
      for (final n in (raw['narrators'] as List? ?? const []))
        if (n is Map && n['name'] is String) n['name'] as String,
    ];
    final sayer = names.isEmpty ? athar : names.join('، ');
    UsulEvidence ev({String? judgment}) => UsulEvidence(text: _clip(body), sayer: sayer, source: athar, judgment: judgment);

    if (type.startsWith('تفسير')) tafsirSayings++;
    if (_marfu.hasMatch(body)) buckets[UsulKeys.bayanNabawi]!.add(ev());
    if (_ijma.hasMatch(body)) buckets[UsulKeys.ijma]!.add(ev());
    if (_ikhtilaf.hasMatch(body)) buckets[UsulKeys.ikhtilaf]!.add(ev());
    if (type.contains('نزول') || body.contains('نزلت')) buckets[UsulKeys.nuzul]!.add(ev());
    final j = _judgmentSentence(notes);
    if (j != null) buckets[UsulKeys.naql]!.add(ev(judgment: j));
    final tiers = {for (final n in names) narratorTier(n)};
    if (tiers.contains(NarratorTier.sahabi)) buckets[UsulKeys.turuqSahabi]!.add(ev());
    if (tiers.contains(NarratorTier.tabii)) buckets[UsulKeys.turuqTabii]!.add(ev());
  }
  buckets[UsulKeys.nuzul]!.addAll(nuzulFromBooks);

  for (final e in buckets.entries) {
    out[e.key] = e.value.isEmpty ? UsulNodeAnswer.notFound : _sourced(e.value);
  }
  // Several tafsir sayings but no one says «اختلف»: a hint to review, never
  // a verdict on the kind of disagreement.
  if (out[UsulKeys.ikhtilaf]!.status == UsulStatus.notFound && tafsirSayings >= 2) {
    out[UsulKeys.ikhtilaf] = UsulNodeAnswer(UsulStatus.hint, count: tafsirSayings);
  }
  return out;
}

UsulNodeAnswer _sourced(List<UsulEvidence> all) =>
    UsulNodeAnswer(UsulStatus.sourced, evidence: all.take(_maxEvidence).toList(), count: all.length);

String _plain(String html) => html
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Clipped at a word, marked «…» — a quote never pretends to be whole.
String _clip(String s) {
  if (s.length <= _excerpt) return s;
  final cut = s.lastIndexOf(' ', _excerpt);
  return '${s.substring(0, cut > 0 ? cut : _excerpt)} …';
}

/// The takhrij sentence that carries the verdict, quoted as written.
String? _judgmentSentence(String notes) {
  final m = _judgment.firstMatch(notes);
  if (m == null) return null;
  final start = notes.lastIndexOf(RegExp(r'[.؛]'), m.start);
  final end = notes.indexOf(RegExp(r'[.؛]'), m.end);
  return notes.substring(start < 0 ? 0 : start + 1, end < 0 ? notes.length : end + 1).trim();
}
