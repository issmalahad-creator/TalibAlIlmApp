import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/knowledge_tree_node.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/depth.dart';
import '../theme/motion.dart';

/// The paper palette of the knowledge trees: cream page, dark-teal hexagons,
/// grey value nodes; the gold accent is the only colour of state.
abstract final class KnowledgeTreePalette {
  static const page = Color(0xFFFBF6EE);
  static const ink = Color(0xFF1F3B44);
  static const leafFill = Color(0xFFF1EEE8);
  static const gold = Color(0xFFD9A441);
}

/// How one node shows its state — supplied by the screen that owns the
/// tree (the usul tree: what the sources say about an ayah; the fiqh tree:
/// the matn's ruling word).
class KnowledgeNodeLook {
  const KnowledgeNodeLook({this.icon, this.iconColor, this.forceIcon = false, this.highlighted = false});

  final IconData? icon;
  final Color? iconColor;

  /// Show the icon on a dark (branch) node too.
  final bool forceIcon;

  /// Gold edge once lit.
  final bool highlighted;
}

class _Placed {
  _Placed(this.node, this.rect);
  final KnowledgeTreeNode node;
  final Rect rect;
}

/// The shared 3D tree canvas (moved from the usul-tafsir screen, U3, unchanged
/// in look): laid out right-to-left like the paper map — the root a slim
/// trunk pillar on the right edge, branches and their nodes in columns to its
/// left, leaves stacked, each parent centred on its children; soft perspective
/// and layered shadows; pinch to zoom; a gold pulse walks the connectors in
/// reading order and lights each node it reaches.
class KnowledgeTree3D extends StatefulWidget {
  const KnowledgeTree3D({
    super.key,
    required this.root,
    required this.look,
    required this.onTap,
    this.columnWidths = const [38.0, 146.0, 166.0],
    this.rowHeight = 70.0,
    this.walkStep = const Duration(milliseconds: 380),
    this.tilt = 0.05,
  });

  final KnowledgeTreeNode root;
  final KnowledgeNodeLook Function(KnowledgeTreeNode node) look;
  final void Function(KnowledgeTreeNode node) onTap;
  final List<double> columnWidths;
  final double rowHeight;
  final Duration walkStep;

  /// The map's perspective tilt (radians). A tall tree (dozens of leaves)
  /// passes 0: on a sheet thousands of pixels tall the same tilt would push
  /// the first rows off the top and shrink the last ones.
  final double tilt;

  @override
  State<KnowledgeTree3D> createState() => _KnowledgeTree3DState();
}

class _KnowledgeTree3DState extends State<KnowledgeTree3D> with SingleTickerProviderStateMixin {
  static const _gapX = 20.0;
  static const _pad = 12.0;

  final _view = TransformationController();
  double? _fittedFor;

  late final List<_Placed> _placed = _layout();

  /// The walk (USUL_TAFSIR_TREE.md §المرور): a light pulse runs down each
  /// connector in reading order — a branch, then its leaves — and the node
  /// it reaches lights up. Order index per node.
  late final Map<String, int> _step = {for (final (i, id) in _walkOrder(widget.root).indexed) id: i};
  late final AnimationController _walk = AnimationController(vsync: this, duration: widget.walkStep * _step.length);
  bool _started = false;

  static List<String> _walkOrder(KnowledgeTreeNode root) {
    final out = <String>[];
    void visit(KnowledgeTreeNode n) {
      if (n.depth > 0) out.add(n.id);
      n.children.forEach(visit);
    }

    visit(root);
    return out;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: show the lit tree at once.
    if (MediaQuery.of(context).disableAnimations) {
      _walk.value = 1;
    } else {
      _walk.forward();
    }
  }

  @override
  void dispose() {
    _walk.dispose();
    _view.dispose();
    super.dispose();
  }

  /// Walk position in steps: node i is reached when this passes i + 1.
  double get _pos => _walk.value * _step.length;
  bool _lit(KnowledgeTreeNode n) => n.depth == 0 || _pos >= (_step[n.id] ?? 0) + 1;

  List<_Placed> _layout() {
    final colW = widget.columnWidths;
    final rowH = widget.rowHeight;
    final placed = <_Placed>[];
    var nextRow = 0.0;
    final width = colW.fold<double>(0, (s, w) => s + w) + _gapX * (colW.length - 1) + _pad * 2;
    double xFor(int depth) {
      var right = width - _pad;
      for (var d = 0; d < depth; d++) {
        right -= colW[math.min(d, colW.length - 1)] + _gapX;
      }
      return right - colW[math.min(depth, colW.length - 1)];
    }

    double place(KnowledgeTreeNode n) {
      final w = colW[math.min(n.depth, colW.length - 1)];
      final h = n.depth == 1 ? 68.0 : 54.0;
      double cy;
      if (n.children.isEmpty) {
        cy = _pad + nextRow * rowH + rowH / 2;
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
    placed[i] = _Placed(placed[i].node, Rect.fromLTRB(r.left, _pad, r.right, _pad + nextRow * rowH));
    return placed;
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed;
    final size = Size(
      placed.map((p) => p.rect.right).reduce(math.max) + _pad,
      placed.map((p) => p.rect.bottom).reduce(math.max) + _pad + 72, // room above the walk controls
    );
    final byId = {for (final p in placed) p.node.id: p};
    return LayoutBuilder(
      builder: (context, box) {
        final fit = math.min(1.0, box.maxWidth / size.width);
        if (_fittedFor != box.maxWidth) {
          _fittedFor = box.maxWidth;
          _view.value = Matrix4.identity()
            ..translateByDouble(box.maxWidth - size.width * fit, 0, 0, 1)
            ..scaleByDouble(fit, fit, 1, 1);
        }
        return Stack(
          children: [
            Positioned.fill(child: _viewer(size, placed, byId, fit)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: Center(
                child: _WalkControls(walk: _walk, lang: LanguagePreferenceService.currentLanguage),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _viewer(Size size, List<_Placed> placed, Map<String, _Placed> byId, double fit) {
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
          ..rotateX(widget.tilt),
        child: SizedBox.fromSize(
          size: size,
          child: AnimatedBuilder(
            animation: _walk,
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _Connectors(placed, byId, _step, _pos))),
                for (final p in placed)
                  Positioned.fromRect(
                    rect: p.rect,
                    child: p.node.depth == 0
                        ? _TrunkView(node: p.node, onTap: () => widget.onTap(p.node))
                        : _NodeView(
                            node: p.node,
                            lit: _lit(p.node),
                            look: widget.look(p.node),
                            onTap: () => widget.onTap(p.node),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pause / skip while the pulse walks; replay once it has finished.
/// Stateful because `stop()` notifies nobody — the label must still flip.
class _WalkControls extends StatefulWidget {
  const _WalkControls({required this.walk, required this.lang});
  final AnimationController walk;
  final String lang;

  @override
  State<_WalkControls> createState() => _WalkControlsState();
}

class _WalkControlsState extends State<_WalkControls> {
  AnimationController get walk => widget.walk;
  String get lang => widget.lang;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: walk,
      builder: (context, _) {
        final done = walk.value >= 1;
        final running = walk.isAnimating;
        Widget btn(IconData icon, String key, VoidCallback onTap) => TextButton.icon(
          onPressed: () {
            onTap();
            setState(() {});
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(0, 40)),
          icon: Icon(icon, size: 20),
          label: Text(basicText(key, lang), style: const TextStyle(fontWeight: FontWeight.w700)),
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: KnowledgeTreePalette.ink.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: KnowledgeTreePalette.gold.withValues(alpha: 0.5)),
            boxShadow: DepthShadows.floating(KnowledgeTreePalette.ink),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: done
                ? [btn(Icons.replay_rounded, 'usul_walk_replay', () => walk.forward(from: 0))]
                : [
                    running
                        ? btn(Icons.pause_rounded, 'usul_walk_pause', walk.stop)
                        : btn(Icons.play_arrow_rounded, 'usul_walk_resume', walk.forward),
                    btn(Icons.skip_next_rounded, 'usul_walk_skip', () => walk.value = 1),
                  ],
          ),
        );
      },
    );
  }
}

/// The root as the tree's trunk: a tall pillar with its name written down it.
class _TrunkView extends StatelessWidget {
  const _TrunkView({required this.node, required this.onTap});
  final KnowledgeTreeNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KnowledgeTreePalette.ink,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: KnowledgeTreePalette.gold.withValues(alpha: 0.7), width: 1.5),
          boxShadow: DepthShadows.modal(KnowledgeTreePalette.ink),
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
  _Connectors(this.placed, this.byId, this.step, this.pos);
  final List<_Placed> placed;
  final Map<String, _Placed> byId;
  final Map<String, int> step;
  final double pos;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()
      ..color = KnowledgeTreePalette.ink.withValues(alpha: 0.3)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final lit = Paint()
      ..color = KnowledgeTreePalette.gold.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = KnowledgeTreePalette.gold.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()..color = KnowledgeTreePalette.gold;
    for (final p in placed) {
      final parent = p.node.parentId == null ? null : byId[p.node.parentId];
      if (parent == null) continue;
      final from = parent.node.depth == 0 ? Offset(parent.rect.left, p.rect.center.dy) : parent.rect.centerLeft;
      final to = p.rect.centerRight;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx - 10, from.dy, to.dx + 10, to.dy, to.dx, to.dy);
      // Dotted, like the paper map; gold up to where the pulse has run.
      final i = step[p.node.id] ?? 0;
      final t = (pos - i).clamp(0.0, 1.0);
      for (final m in path.computeMetrics()) {
        final reached = m.length * t;
        for (var d = 0.0; d < m.length; d += 7) {
          final seg = m.extractPath(d, math.min(d + 3.5, m.length));
          canvas.drawPath(seg, d < reached ? lit : dim);
        }
        if (t > 0 && t < 1) {
          final at = m.getTangentForOffset(reached)?.position;
          if (at != null) {
            canvas.drawCircle(at, 9, glow);
            canvas.drawCircle(at, 3.5, core);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Connectors old) => old.placed != placed || old.pos != pos;
}

class _NodeView extends StatelessWidget {
  const _NodeView({required this.node, required this.lit, required this.look, required this.onTap});
  final KnowledgeTreeNode node;

  /// False until the walk's pulse reaches this node: drawn faint, no state.
  final bool lit;
  final KnowledgeNodeLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = node.depth <= 1 && node.children.isNotEmpty || node.depth == 0;
    const ink = KnowledgeTreePalette.ink;
    final shadows = node.depth == 0
        ? DepthShadows.modal(ink)
        : node.depth == 1
        ? DepthShadows.floating(ink)
        : DepthShadows.soft(ink);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: lit ? 1 : 0.35,
        duration: AppMotion.fast,
        curve: AppMotion.entranceCurve,
        child: AnimatedScale(
          scale: lit ? 1 : 0.96,
          duration: AppMotion.fast,
          curve: AppMotion.entranceCurve,
          child: CustomPaint(
            painter: _HexPainter(
              fill: dark ? ink : KnowledgeTreePalette.leafFill,
              edge: lit && look.highlighted ? KnowledgeTreePalette.gold : null,
              shadows: lit ? shadows : const [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (look.icon != null && (look.forceIcon || !dark))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Icon(
                        lit ? look.icon : Icons.radio_button_unchecked,
                        size: 16,
                        color: dark ? Colors.white70 : (lit ? look.iconColor : Colors.grey),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      node.title,
                      maxLines: node.depth == 1 ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white : ink,
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
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.fill != fill || old.edge != edge;
}
