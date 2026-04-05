import 'dart:async';

import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_installer_stub.dart'
    if (dart.library.io) 'app_update_installer_android.dart';

final appUpdateInstallerProvider = Provider<AppUpdateInstaller>((ref) {
  return createAppUpdateInstaller();
});

enum AppUpdateInstallStep {
  downloading,
  installing,
  permissionDenied,
  installerOpenFailed,
  downloadFailed,
  canceled,
}

class AppUpdateInstallResult {
  const AppUpdateInstallResult._({
    required this.step,
    this.progress,
    this.message,
  });

  const AppUpdateInstallResult.downloading({
    required double progress,
  }) : this._(
         step: AppUpdateInstallStep.downloading,
         progress: progress,
       );

  const AppUpdateInstallResult.installing()
    : this._(step: AppUpdateInstallStep.installing);

  const AppUpdateInstallResult.permissionDenied({
    String? message,
  }) : this._(
         step: AppUpdateInstallStep.permissionDenied,
         message: message,
       );

  const AppUpdateInstallResult.installerOpenFailed({
    String? message,
  }) : this._(
         step: AppUpdateInstallStep.installerOpenFailed,
         message: message,
       );

  const AppUpdateInstallResult.downloadFailed({
    String? message,
  }) : this._(
         step: AppUpdateInstallStep.downloadFailed,
         message: message,
       );

  const AppUpdateInstallResult.canceled({
    String? message,
  }) : this._(
         step: AppUpdateInstallStep.canceled,
         message: message,
       );

  final AppUpdateInstallStep step;
  final double? progress;
  final String? message;
}

abstract class AppUpdateInstaller {
  Stream<AppUpdateInstallResult> install(AppUpdateManifest manifest);
}
