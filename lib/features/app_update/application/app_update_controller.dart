import 'dart:async';

import 'package:barcode_app/features/app_update/data/app_update_installer.dart';
import 'package:barcode_app/features/app_update/data/app_update_repository.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appUpdateFeatureEnabledProvider = Provider<bool>((ref) {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android;
});

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );

enum AppUpdateStatus {
  idle,
  disabled,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  failed,
}

enum AppUpdateFailureType {
  permissionDenied,
  installerFailed,
  downloadFailed,
}

class AppUpdateState {
  const AppUpdateState({
    required this.status,
    required this.currentVersionName,
    required this.currentVersionCode,
    this.availableManifest,
    this.downloadProgress,
    this.lastError,
    this.failureType,
  });

  const AppUpdateState.initial({
    required bool enabled,
  }) : status = enabled ? AppUpdateStatus.checking : AppUpdateStatus.disabled,
       currentVersionName = '',
       currentVersionCode = 0,
       availableManifest = null,
       downloadProgress = null,
       lastError = null,
       failureType = null;

  final AppUpdateStatus status;
  final String currentVersionName;
  final int currentVersionCode;
  final AppUpdateManifest? availableManifest;
  final double? downloadProgress;
  final String? lastError;
  final AppUpdateFailureType? failureType;

  bool get shouldShowBanner =>
      status == AppUpdateStatus.available ||
      status == AppUpdateStatus.downloading ||
      status == AppUpdateStatus.installing ||
      status == AppUpdateStatus.failed;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    String? currentVersionName,
    int? currentVersionCode,
    AppUpdateManifest? availableManifest,
    double? downloadProgress,
    String? lastError,
    AppUpdateFailureType? failureType,
    bool clearManifest = false,
    bool clearProgress = false,
    bool clearError = false,
    bool clearFailureType = false,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      currentVersionName: currentVersionName ?? this.currentVersionName,
      currentVersionCode: currentVersionCode ?? this.currentVersionCode,
      availableManifest: clearManifest
          ? null
          : (availableManifest ?? this.availableManifest),
      downloadProgress: clearProgress
          ? null
          : (downloadProgress ?? this.downloadProgress),
      lastError: clearError ? null : (lastError ?? this.lastError),
      failureType: clearFailureType
          ? null
          : (failureType ?? this.failureType),
    );
  }
}

class AppUpdateController extends Notifier<AppUpdateState> {
  bool _startupCheckScheduled = false;
  bool _isChecking = false;
  int? _dismissedVersionCode;

  @override
  AppUpdateState build() {
    final enabled = ref.read(appUpdateFeatureEnabledProvider);

    if (enabled && !_startupCheckScheduled) {
      _startupCheckScheduled = true;
      scheduleMicrotask(() => unawaited(checkForUpdates()));
    }

    return AppUpdateState.initial(enabled: enabled);
  }

  Future<void> checkForUpdates() async {
    if (_isChecking) {
      return;
    }

    if (!ref.read(appUpdateFeatureEnabledProvider)) {
      state = state.copyWith(
        status: AppUpdateStatus.disabled,
        clearManifest: true,
        clearProgress: true,
        clearError: true,
        clearFailureType: true,
      );
      return;
    }

    _isChecking = true;
    state = state.copyWith(
      status: AppUpdateStatus.checking,
      clearProgress: true,
      clearError: true,
      clearFailureType: true,
    );

    try {
      final result = await ref.read(appUpdateRepositoryProvider).checkForUpdate();

      switch (result.status) {
        case AppUpdateCheckStatus.disabled:
          state = state.copyWith(
            status: AppUpdateStatus.disabled,
            currentVersionName: result.currentVersionName,
            currentVersionCode: result.currentVersionCode,
            clearManifest: true,
            clearProgress: true,
            clearError: true,
            clearFailureType: true,
          );
          break;
        case AppUpdateCheckStatus.upToDate:
          state = state.copyWith(
            status: AppUpdateStatus.upToDate,
            currentVersionName: result.currentVersionName,
            currentVersionCode: result.currentVersionCode,
            clearManifest: true,
            clearProgress: true,
            clearError: true,
            clearFailureType: true,
          );
          break;
        case AppUpdateCheckStatus.available:
          final manifest = result.manifest;
          if (manifest == null) {
            state = state.copyWith(
              status: AppUpdateStatus.idle,
              currentVersionName: result.currentVersionName,
              currentVersionCode: result.currentVersionCode,
              clearManifest: true,
              clearProgress: true,
              clearError: true,
              clearFailureType: true,
            );
            break;
          }

          if (_dismissedVersionCode == manifest.versionCode) {
            state = state.copyWith(
              status: AppUpdateStatus.idle,
              currentVersionName: result.currentVersionName,
              currentVersionCode: result.currentVersionCode,
              clearManifest: true,
              clearProgress: true,
              clearError: true,
              clearFailureType: true,
            );
            break;
          }

          state = state.copyWith(
            status: AppUpdateStatus.available,
            currentVersionName: result.currentVersionName,
            currentVersionCode: result.currentVersionCode,
            availableManifest: manifest,
            clearProgress: true,
            clearError: true,
            clearFailureType: true,
          );
          break;
      }
    } catch (_) {
      state = state.copyWith(
        status: AppUpdateStatus.idle,
        clearManifest: true,
        clearProgress: true,
        clearError: true,
        clearFailureType: true,
      );
    } finally {
      _isChecking = false;
    }
  }

  void dismissForSession() {
    final manifest = state.availableManifest;
    if (manifest != null) {
      _dismissedVersionCode = manifest.versionCode;
    }

    state = state.copyWith(
      status: AppUpdateStatus.idle,
      clearManifest: true,
      clearProgress: true,
      clearError: true,
      clearFailureType: true,
    );
  }

  Future<void> startUpdate() async {
    final manifest = state.availableManifest;
    if (manifest == null) {
      return;
    }

    state = state.copyWith(
      status: AppUpdateStatus.downloading,
      downloadProgress: 0,
      clearError: true,
      clearFailureType: true,
    );

    await for (final event
        in ref.read(appUpdateInstallerProvider).install(manifest)) {
      switch (event.step) {
        case AppUpdateInstallStep.downloading:
          state = state.copyWith(
            status: AppUpdateStatus.downloading,
            downloadProgress: event.progress,
          );
          break;
        case AppUpdateInstallStep.installing:
          state = state.copyWith(
            status: AppUpdateStatus.installing,
          );
          break;
        case AppUpdateInstallStep.permissionDenied:
          state = state.copyWith(
            status: AppUpdateStatus.failed,
            lastError:
                event.message ??
                'Permita a instalacao de apps desconhecidos para continuar.',
            failureType: AppUpdateFailureType.permissionDenied,
          );
          return;
        case AppUpdateInstallStep.downloadFailed:
          state = state.copyWith(
            status: AppUpdateStatus.failed,
            lastError:
                event.message ??
                'Nao foi possivel baixar a atualizacao agora.',
            failureType: AppUpdateFailureType.downloadFailed,
          );
          return;
        case AppUpdateInstallStep.installerOpenFailed:
          state = state.copyWith(
            status: AppUpdateStatus.failed,
            lastError:
                event.message ??
                'Nao foi possivel abrir a instalacao da atualizacao.',
            failureType: AppUpdateFailureType.installerFailed,
          );
          return;
        case AppUpdateInstallStep.canceled:
          state = state.copyWith(
            status: AppUpdateStatus.available,
            clearProgress: true,
            clearError: true,
            clearFailureType: true,
          );
          return;
      }
    }
  }
}
