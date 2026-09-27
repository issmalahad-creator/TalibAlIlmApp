/// Where a content pack is in its life (CONTENT_PACKS_ARCHITECTURE.md §3.3).
/// Every failure is a state with a reason the UI can explain — the engine
/// never throws at the UI.
sealed class PackState {
  const PackState();
}

class PackNotInstalled extends PackState {
  const PackNotInstalled();
}

/// Bundled in this build (the full flavor) — usable, nothing to download.
class PackBundled extends PackState {
  const PackBundled();
}

class PackQueued extends PackState {
  const PackQueued();
}

/// The student chose «عند توفر Wi-Fi» while on mobile data.
class PackWaitingForWifi extends PackState {
  const PackWaitingForWifi();
}

class PackDownloading extends PackState {
  const PackDownloading({required this.received, required this.total, this.bytesPerSecond});
  final int received;
  final int total;
  final double? bytesPerSecond;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1).toDouble();

  Duration? get remaining {
    final bps = bytesPerSecond;
    if (bps == null || bps <= 0) return null;
    return Duration(seconds: ((total - received) / bps).ceil());
  }
}

class PackPaused extends PackState {
  const PackPaused({required this.received, required this.total});
  final int received;
  final int total;
}

class PackVerifying extends PackState {
  const PackVerifying();
}

class PackInstalling extends PackState {
  const PackInstalling();
}

class PackInstalled extends PackState {
  const PackInstalled({required this.version, required this.bytesOnDisk, this.updateAvailable = false});
  final int version;
  final int bytesOnDisk;
  final bool updateAvailable;
}

enum PackFailure { offline, noSpace, checksum, notFound, server, cancelled }

class PackFailed extends PackState {
  const PackFailed(this.reason);
  final PackFailure reason;
}

extension PackStateX on PackState {
  bool get isUsable => this is PackInstalled || this is PackBundled;
  bool get isBusy => this is PackQueued || this is PackDownloading || this is PackVerifying || this is PackInstalling;
}
