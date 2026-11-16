import 'dart:convert';

import 'package:flutter/services.dart';

// The connected fiqh tree (docs/KNOWLEDGE_TREE_ZAD_PLAN.md): Zad al-Mustaqni'
// is the tree, Bulugh al-Maram the evidence, al-Rawd al-Murbi' the
// explanation. Data: assets/knowledge_trees/<id>.json, built by
// tool/knowledge/build_zad_tree.py from the Turath library (authors' own
// words only — no modern editor's footnotes or gradings).

/// One ruling of the matn, exactly as al-Hajjawi wrote it.
class FiqhMasala {
  const FiqhMasala({required this.id, required this.text, required this.ruling});
  final String id;
  final String text;

  /// The matn's own ruling words found in this line (يُكره، يُسنّ، يجب…),
  /// shown as highlights — never a ruling the matn didn't state.
  final List<String> ruling;

  factory FiqhMasala.fromJson(Map<String, dynamic> j) => FiqhMasala(
        id: j['id'] as String,
        text: j['text'] as String,
        ruling: [for (final r in (j['ruling'] as List? ?? const [])) r as String],
      );
}

/// A hadith of Bulugh al-Maram: Ibn Hajr's words (hadith + his own takhrij).
class BulughHadith {
  const BulughHadith({required this.n, required this.text, this.sub});
  final int n;
  final String text;

  /// The edition's added hadith under the same number: «٢٠٣ (أ)».
  final String? sub;

  /// «203» or «203 أ».
  String get label => sub == null ? '$n' : '$n $sub';

  factory BulughHadith.fromJson(Map<String, dynamic> j) =>
      BulughHadith(n: j['n'] as int, text: j['text'] as String, sub: j['sub'] as String?);
}

class FiqhChapter {
  const FiqhChapter({
    required this.id,
    required this.title,
    required this.masail,
    required this.sharhExcerpt,
    required this.sharhChapter,
    required this.sharhPage,
    required this.evidenceChapter,
  });

  final String id;
  final String title;
  final List<FiqhMasala> masail;

  /// The opening of al-Rawd's explanation of this chapter (public domain);
  /// the full text opens in the Turath reader at [sharhPage].
  final String sharhExcerpt;
  final String sharhChapter;
  final int sharhPage;

  /// The Bulugh al-Maram chapter that gathers this chapter's evidence.
  final String evidenceChapter;
}

class FiqhTree {
  const FiqhTree({
    required this.id,
    required this.title,
    required this.chapters,
    required this.hadithByChapter,
    required this.sources,
  });

  final String id;
  final String title;
  final List<FiqhChapter> chapters;
  final Map<String, List<BulughHadith>> hadithByChapter;

  /// source key (zad / rawd / bulugh) → {turath_id, title, author, …}
  final Map<String, Map<String, dynamic>> sources;

  List<BulughHadith> evidenceFor(FiqhChapter c) => hadithByChapter[c.evidenceChapter] ?? const [];
  int get turathRawdId => (sources['rawd']?['turath_id'] as num).toInt();

  static const zadTaharah = 'assets/knowledge_trees/zad_taharah.json';
  static const indexAsset = 'assets/knowledge_trees/index.json';

  /// The trees that exist (one per kitab of Zad's worship), in book order.
  static Future<List<FiqhTreeEntry>> index({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(indexAsset);
    return [
      for (final t in ((jsonDecode(raw) as Map<String, dynamic>)['trees'] as List).cast<Map<String, dynamic>>())
        FiqhTreeEntry(
          id: t['id'] as String,
          title: t['title'] as String,
          asset: t['asset'] as String,
          masail: (t['masail'] as num).toInt(),
          hadith: (t['hadith'] as num).toInt(),
        ),
    ];
  }

  static Future<FiqhTree> load({String asset = zadTaharah, AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(asset);
    return FiqhTree.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory FiqhTree.fromJson(Map<String, dynamic> j) => FiqhTree(
        id: j['id'] as String,
        title: j['title'] as String,
        sources: {
          for (final e in (j['sources'] as Map<String, dynamic>).entries) e.key: (e.value as Map).cast<String, dynamic>(),
        },
        hadithByChapter: {
          for (final e in (j['bulugh'] as Map<String, dynamic>).entries)
            e.key: [for (final h in e.value as List) BulughHadith.fromJson(h as Map<String, dynamic>)],
        },
        chapters: [
          for (final c in (j['chapters'] as List).cast<Map<String, dynamic>>())
            FiqhChapter(
              id: c['id'] as String,
              title: c['title'] as String,
              masail: [for (final m in c['masail'] as List) FiqhMasala.fromJson(m as Map<String, dynamic>)],
              sharhExcerpt: (c['sharh'] as Map)['excerpt'] as String,
              sharhChapter: (c['sharh'] as Map)['chapter'] as String,
              sharhPage: ((c['sharh'] as Map)['page'] as num).toInt(),
              evidenceChapter: (c['evidence'] as Map)['chapter'] as String,
            ),
        ],
      );
}

/// One row of assets/knowledge_trees/index.json.
class FiqhTreeEntry {
  const FiqhTreeEntry({required this.id, required this.title, required this.asset, required this.masail, required this.hadith});
  final String id;
  final String title;
  final String asset;
  final int masail;
  final int hadith;
}
