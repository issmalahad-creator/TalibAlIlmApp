import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures an on-screen [CertificateCard] (wrapped in a [RepaintBoundary])
/// as a PNG and hands it to the OS share sheet — same
/// save-to-temp-then-`Share.shareXFiles` pattern already used by
/// `HifzExportService`, no new sharing mechanism.
class CertificateService {
  Future<void> shareFromBoundary(GlobalKey boundaryKey, String fileName) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }
}
