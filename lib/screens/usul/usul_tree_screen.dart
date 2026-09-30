import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/quran_surahs.dart';
import '../../l10n/basic_translations.dart';
import '../../repositories/usul_tree_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/packs/content_pack_engine.dart';
import '../../services/usul/usul_answers.dart';
import '../../theme/app_theme.dart';
import '../../theme/depth.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/packs/pack_ui.dart';
import '../ayah_study_screen.dart';

/// «شجرة أصول التفسير» for one ayah (docs/quran/USUL_TAFSIR_TREE.md U3) —
/// the paper mind-map Ismail showed: root on the right, the four branches of
/// Ibn Taymiyya's Muqaddima, their nodes, dotted connectors; soft 3D depth
/// (layered heights + shadows + a light perspective), pinch to zoom. Each
/// node is lit by what the sources say about THIS ayah; tapping it opens a
/// quick card, never a reader.
class UsulTreeScreen extends StatefulWidget {
  const UsulTreeScreen({super.key, required this.surah, required this.ayah});
  final int surah;
  final int ayah;

  @override
  State<UsulTreeScreen> createState() => _UsulTreeScreenState();
}

// The paper palette: cream page, dark-teal hexagons like the image, grey
// value nodes; the gold accent is the only colour of state.
const _page = Color(0xFFFBF6EE);
const _ink = Color(0xFF1F3B44);
const _leafFill = Color(0xFFF1EEE8);
const _gold = Color(0xFFD9A441);

class _UsulTreeScreenState extends State<UsulTreeScreen> {
  final _repo = UsulTreeRepository();
  UsulTreeNode? _root;
  Map<String, UsulNodeAnswer> _answers = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final root = await _repo.tree();
    final answers = await _repo.answersFor(widget.surah, widget.ayah);
    if (!mounted) return;
    setState(() {
      _root = root;
      _answers = answers;
      _loading = false;
    });
  }

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  Widget build(BuildContext context) {
    final surahName = widget.surah >= 1 && widget.surah <= quranSurahs.length ? quranSurahs[widget.surah - 1].name : '';
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        title: Column(
          children: [
            Text(basicText('usul_tree_title', _lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('$surahName · ${widget.ayah}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.account_tree_outlined, message: basicText('loading_quran', _lang))
          : _root == null
              ? Center(child: Text(basicText('usul_status_not_found', _lang)))
              : _TreeCanvas(root: _root!, answers: _answers, onTap: _openNode),
    );
  }

  Future<void> _openNode(UsulTreeNode n) async {
    final name = n.sourceRefId == null ? null : await _repo.sourceName(n.sourceRefId!);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(n.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink)),
            if (n.question != null) ...[
              const SizedBox(height: 4),
              Text(n.question!, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
            if (n.definition != null) ...[
              const SizedBox(height: 14),
              _QuoteBox(
                label: basicText('usul_definition_label', _lang),
                text: n.definition!,
                attribution: [name, n.locator].whereType<String>().join('، '),
              ),
            ],
            if (n.children.isEmpty || n.answerKey != null) ...[
              const SizedBox(height: 18),
              Text(basicText('usul_for_this_ayah', _lang),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ..._answerBody(n),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AyahStudyScreen(
                        surah: widget.surah, ayah: widget.ayah, initialFamily: AyahStudyFamily.uloom),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(basicText('ql_open_ayah_page', _lang)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _answerBody(UsulTreeNode n) {
    final a = n.answerKey == null ? null : _answers[n.answerKey];
    if (a == null) return [_StatusChip(status: null, lang: _lang), const SizedBox(height: 6), Text(basicText('usul_curated_pending', _lang), style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted))];
    final out = <Widget>[_StatusChip(status: a.status, lang: _lang), const SizedBox(height: 10)];
    switch (a.status) {
      case UsulStatus.notDownloaded:
        out.add(FutureBuilder(
          future: ContentPackEngine.instance.manifest(),
          builder: (_, snap) {
            final pack = snap.data?.byId('corpus.sayings');
            return pack == null ? const SizedBox.shrink() : Align(alignment: AlignmentDirectional.centerStart, child: PackStatusView(pack: pack));
          },
        ));
      case UsulStatus.hint:
        out.add(Text(basicText('usul_hint_note', _lang), style: const TextStyle(fontSize: 13.5, height: 1.6)));
      case UsulStatus.notFound:
        break;
      case UsulStatus.sourced:
        for (final e in a.evidence) {
          out.add(_QuoteBox(text: e.text, attribution: '${e.sayer} — ${e.source}', judgment: e.judgment));
          out.add(const SizedBox(height: 8));
        }
        if (a.count > a.evidence.length) {
          out.add(Text(basicText('usul_more_items', _lang).replaceAll('{n}', '${a.count - a.evidence.length}'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)));
        }
    }
    return out;
  }
}

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({required this.text, required this.attribution, this.label, this.judgment});
  final String text;
  final String attribution;
  final String? label;
  final String? judgment;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: _page,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: const BorderDirectional(start: BorderSide(color: _gold, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Text(label!, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            Text('«$text»', style: const TextStyle(fontSize: 15, height: 1.75)),
            if (judgment != null) ...[
              const SizedBox(height: 4),
              Text(judgment!, style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900)),
            ],
            const SizedBox(height: 4),
            Text(attribution, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.lang});
  final UsulStatus? status;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final (key, color, icon) = statusStyle(status);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(basicText(key, lang), style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

(String, Color, IconData) statusStyle(UsulStatus? s) => switch (s) {
      UsulStatus.sourced => ('usul_status_sourced', AppColors.primary, Icons.check_circle_rounded),
      UsulStatus.hint => ('usul_status_hint', _gold, Icons.adjust_rounded),
      UsulStatus.notDownloaded => ('usul_status_not_downloaded', Colors.blueGrey, Icons.download_for_offline_outlined),
      UsulStatus.notFound || null => ('usul_status_not_found', Colors.grey, Icons.radio_button_unchecked),
    };

// ---------------------------------------------------------------- the canvas

class _Placed {
  _Placed(this.node, this.rect);
  final UsulTreeNode node;
  final Rect rect;
}

/// Lays the tree out right-to-left like the paper map: the root is a slim
/// trunk pillar on the right edge (its name is also the screen title), the
/// branches and their nodes are columns to its left, leaves stacked, each
/// parent centred on its children. Sized so a phone shows the whole map at
/// ~0.9 scale; it opens fitted to the width and aligned right (RTL).
class _TreeCanvas extends StatefulWidget {
  const _TreeCanvas({required this.root, required this.answers, required this.onTap});
  final UsulTreeNode root;
  final Map<String, UsulNodeAnswer> answers;
  final void Function(UsulTreeNode) onTap;

  @override
  State<_TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<_TreeCanvas> {
  static const _colW = [38.0, 146.0, 166.0];
  static const _gapX = 20.0;
  static const _rowH = 70.0;
  static const _pad = 12.0;

  final _view = TransformationController();
  double? _fittedFor;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  List<_Placed> _layout() {
    final placed = <_Placed>[];
    var nextRow = 0.0;
    final width = _colW.fold<double>(0, (s, w) => s + w) + _gapX * (_colW.length - 1) + _pad * 2;
    double xFor(int depth) {
      var right = width - _pad;
      for (var d = 0; d < depth; d++) {
        right -= _colW[math.min(d, _colW.length - 1)] + _gapX;
      }
      return right - _colW[math.min(depth, _colW.length - 1)];
    }

    double place(UsulTreeNode n) {
      final w = _colW[math.min(n.depth, _colW.length - 1)];
      final h = n.depth == 1 ? 68.0 : 54.0;
      double cy;
      if (n.children.isEmpty) {
        cy = _pad + nextRow * _rowH + _rowH / 2;
        nextRow++;
      } else {
        final ys = [for (final c in n.children) place(c)];
        cy = (ys.first + ys.last) / 2;
      }
      placed.add(_Placed(n, Rect.fromCenter(center: Offset(xFor(n.depth) + w / 2, cy), width: w, height: h)));
      return cy;
    }

    place(widget.root);
    // The trunk runs the full height of the map.
    final i = placed.indexWhere((p) => p.node.depth == 0);
    final r = placed[i].rect;
    placed[i] = _Placed(placed[i].node, Rect.fromLTRB(r.left, _pad, r.right, _pad + nextRow * _rowH));
    return placed;
  }

  @override
  Widget build(BuildContext context) {
    final placed = _layout();
    final size = Size(
      placed.map((p) => p.rect.right).reduce(math.max) + _pad,
      placed.map((p) => p.rect.bottom).reduce(math.max) + _pad,
    );
    final byId = {for (final p in placed) p.node.id: p};
    return LayoutBuilder(builder: (context, box) {
      final fit = math.min(1.0, box.maxWidth / size.width);
      if (_fittedFor != box.maxWidth) {
        _fittedFor = box.maxWidth;
        _view.value = Matrix4.identity()
          ..translateByDouble(box.maxWidth - size.width * fit, 0, 0, 1)
          ..scaleByDouble(fit, fit, 1, 1);
      }
      return InteractiveViewer(
        transformationController: _view,
        constrained: false,
        minScale: fit * 0.8,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(80),
        child: Transform(
          // Soft depth: a hint of perspective tilting the sheet away from the
          // reader — like a map lying on a desk — never enough to distort text.
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0007)
            ..rotateX(0.05),
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _Connectors(placed, byId))),
                for (final p in placed)
                  Positioned.fromRect(
                    rect: p.rect,
                    child: p.node.depth == 0
                        ? _TrunkView(node: p.node, onTap: () => widget.onTap(p.node))
                        : _NodeView(
                            node: p.node,
                            status: p.node.answerKey == null ? null : widget.answers[p.node.answerKey]?.status,
                            onTap: () => widget.onTap(p.node),
                          ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// The root as the tree's trunk: a tall pillar with its name written down it.
class _TrunkView extends StatelessWidget {
  const _TrunkView({required this.node, required this.onTap});
  final UsulTreeNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.5),
          boxShadow: DepthShadows.modal(_ink),
        ),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            node.title,
            maxLines: 1,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _Connectors extends CustomPainter {
  _Connectors(this.placed, this.byId);
  final List<_Placed> placed;
  final Map<String, _Placed> byId;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ink.withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final p in placed) {
      final parent = p.node.parentId == null ? null : byId[p.node.parentId];
      if (parent == null) continue;
      final from = parent.node.depth == 0 ? Offset(parent.rect.left, p.rect.center.dy) : parent.rect.centerLeft;
      final to = p.rect.centerRight;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx - 10, from.dy, to.dx + 10, to.dy, to.dx, to.dy);
      // Dotted, like the paper map.
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 7) {
          final seg = m.extractPath(d, math.min(d + 3.5, m.length));
          canvas.drawPath(seg, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Connectors old) => old.placed != placed;
}

class _NodeView extends StatelessWidget {
  const _NodeView({required this.node, required this.status, required this.onTap});
  final UsulTreeNode node;
  final UsulStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = node.depth <= 1 && node.children.isNotEmpty || node.depth == 0;
    final (_, stateColor, icon) = statusStyle(status);
    final shadows = node.depth == 0
        ? DepthShadows.modal(_ink)
        : node.depth == 1
            ? DepthShadows.floating(_ink)
            : DepthShadows.soft(_ink);
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _HexPainter(fill: dark ? _ink : _leafFill, edge: status == UsulStatus.sourced ? _gold : null, shadows: shadows),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (node.answerKey != null || !dark)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Icon(icon, size: 16, color: dark ? Colors.white70 : stateColor),
                ),
              Expanded(
                child: Text(
                  node.title,
                  maxLines: node.depth == 1 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark ? Colors.white : _ink,
                    fontWeight: node.depth == 0 ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A stretched hexagon — the paper map's node shape — with the project's
/// layered depth shadows.
class _HexPainter extends CustomPainter {
  _HexPainter({required this.fill, required this.edge, required this.shadows});
  final Color fill;
  final Color? edge;
  final List<BoxShadow> shadows;

  Path _hex(Size s) {
    final c = s.height / 2;
    return Path()
      ..moveTo(c * 0.6, 0)
      ..lineTo(s.width - c * 0.6, 0)
      ..lineTo(s.width, c)
      ..lineTo(s.width - c * 0.6, s.height)
      ..lineTo(c * 0.6, s.height)
      ..lineTo(0, c)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hex(size);
    for (final sh in shadows) {
      canvas.drawPath(
        path.shift(sh.offset),
        Paint()
          ..color = sh.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sh.blurRadius / 2),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (edge != null) {
      canvas.drawPath(
          path,
          Paint()
            ..color = edge!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.fill != fill || old.edge != edge;
}
