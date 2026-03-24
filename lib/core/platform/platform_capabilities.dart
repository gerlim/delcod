import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformCapabilities {
  const PlatformCapabilities({
    required this.supportsCameraScanning,
    required this.supportsManualEntry,
  });

  final bool supportsCameraScanning;
  final bool supportsManualEntry;
}

final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  if (kIsWeb) {
    return const PlatformCapabilities(
      supportsCameraScanning: false,
      supportsManualEntry: true,
    );
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return const PlatformCapabilities(
        supportsCameraScanning: true,
        supportsManualEntry: true,
      );
    case TargetPlatform.windows:
      return const PlatformCapabilities(
        supportsCameraScanning: false,
        supportsManualEntry: true,
      );
    default:
      return const PlatformCapabilities(
        supportsCameraScanning: false,
        supportsManualEntry: true,
      );
  }
});
