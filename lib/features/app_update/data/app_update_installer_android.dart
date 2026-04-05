import 'dart:async';
import 'dart:io';

import 'package:barcode_app/features/app_update/data/app_update_installer.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const _appUpdateMethodChannel = MethodChannel('com.gerlim.delcod/app_update');

AppUpdateInstaller createAppUpdateInstaller() {
  if (!Platform.isAndroid) {
    return _UnsupportedAppUpdateInstaller();
  }

  return AndroidAppUpdateInstaller(
    downloadService: HttpApkDownloadService(),
    installLauncher: const MethodChannelApkInstallLauncher(),
  );
}

class _UnsupportedAppUpdateInstaller implements AppUpdateInstaller {
  @override
  Stream<AppUpdateInstallResult> install(AppUpdateManifest manifest) async* {
    yield const AppUpdateInstallResult.installerOpenFailed(
      message: 'Atualizacao automatica indisponivel nesta plataforma.',
    );
  }
}

class AndroidAppUpdateInstaller implements AppUpdateInstaller {
  AndroidAppUpdateInstaller({
    required ApkDownloadService downloadService,
    required ApkInstallLauncher installLauncher,
  }) : _downloadService = downloadService,
       _installLauncher = installLauncher;

  final ApkDownloadService _downloadService;
  final ApkInstallLauncher _installLauncher;

  @override
  Stream<AppUpdateInstallResult> install(AppUpdateManifest manifest) async* {
    String? downloadedFilePath;

    try {
      await for (final update in _downloadService.download(manifest)) {
        if (update.progress != null) {
          yield AppUpdateInstallResult.downloading(progress: update.progress!);
        }

        if (update.filePath != null) {
          downloadedFilePath = update.filePath;
        }
      }
    } on AppUpdateDownloadException catch (error) {
      yield AppUpdateInstallResult.downloadFailed(message: error.message);
      return;
    } catch (error) {
      yield AppUpdateInstallResult.downloadFailed(message: error.toString());
      return;
    }

    final resolvedFilePath = downloadedFilePath;
    if (resolvedFilePath == null || resolvedFilePath.isEmpty) {
      yield const AppUpdateInstallResult.downloadFailed(
        message: 'Nao foi possivel preparar a atualizacao para instalacao.',
      );
      return;
    }

    final launchResult = await _installLauncher.launch(resolvedFilePath);
    switch (launchResult.status) {
      case AppUpdateInstallLaunchStatus.readyToInstall:
        yield const AppUpdateInstallResult.installing();
        return;
      case AppUpdateInstallLaunchStatus.permissionDenied:
        yield AppUpdateInstallResult.permissionDenied(
          message: launchResult.message,
        );
        return;
      case AppUpdateInstallLaunchStatus.failed:
        yield AppUpdateInstallResult.installerOpenFailed(
          message: launchResult.message,
        );
        return;
      case AppUpdateInstallLaunchStatus.canceled:
        yield AppUpdateInstallResult.canceled(message: launchResult.message);
        return;
    }
  }
}

abstract class ApkDownloadService {
  Stream<ApkDownloadUpdate> download(AppUpdateManifest manifest);
}

class ApkDownloadUpdate {
  const ApkDownloadUpdate._({
    this.progress,
    this.filePath,
  });

  const ApkDownloadUpdate.progress(double progress)
    : this._(progress: progress);

  const ApkDownloadUpdate.completed(String filePath) : this._(filePath: filePath);

  final double? progress;
  final String? filePath;
}

class AppUpdateDownloadException implements Exception {
  const AppUpdateDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HttpApkDownloadService implements ApkDownloadService {
  HttpApkDownloadService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Stream<ApkDownloadUpdate> download(AppUpdateManifest manifest) async* {
    final request = http.Request('GET', manifest.apkUri);
    late final http.StreamedResponse response;

    try {
      response = await _client.send(request);
    } on SocketException {
      throw const AppUpdateDownloadException(
        'Sem conexao para baixar a atualizacao.',
      );
    } catch (error) {
      throw AppUpdateDownloadException(error.toString());
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppUpdateDownloadException(
        'Servidor retornou ${response.statusCode} ao baixar a atualizacao.',
      );
    }

    final updatesDirectory = await _resolveUpdatesDirectory();
    final destinationPath = path.join(
      updatesDirectory.path,
      _destinationFilename(manifest.apkUri),
    );
    final file = File(destinationPath);

    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    var receivedBytes = 0;
    final totalBytes = response.contentLength;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes != null && totalBytes > 0) {
          final rawProgress = receivedBytes / totalBytes;
          final clamped = rawProgress.clamp(0.0, 1.0).toDouble();
          yield ApkDownloadUpdate.progress(clamped);
        }
      }
    } on SocketException {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      throw const AppUpdateDownloadException(
        'A conexao caiu durante o download da atualizacao.',
      );
    } catch (error) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      throw AppUpdateDownloadException(error.toString());
    }

    await sink.close();

    if (totalBytes == null || totalBytes <= 0) {
      yield const ApkDownloadUpdate.progress(1.0);
    }

    yield ApkDownloadUpdate.completed(file.path);
  }

  Future<Directory> _resolveUpdatesDirectory() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    final updatesDirectory = Directory(
      path.join(appSupportDirectory.path, 'updates'),
    );

    if (!await updatesDirectory.exists()) {
      await updatesDirectory.create(recursive: true);
    }

    return updatesDirectory;
  }

  String _destinationFilename(Uri uri) {
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    return segment.isEmpty ? 'DelCod-update.apk' : segment;
  }
}

abstract class ApkInstallLauncher {
  Future<AppUpdateInstallLaunchResult> launch(String filePath);
}

enum AppUpdateInstallLaunchStatus {
  readyToInstall,
  permissionDenied,
  failed,
  canceled,
}

class AppUpdateInstallLaunchResult {
  const AppUpdateInstallLaunchResult._({
    required this.status,
    this.message,
  });

  const AppUpdateInstallLaunchResult.readyToInstall({
    String? message,
  }) : this._(
         status: AppUpdateInstallLaunchStatus.readyToInstall,
         message: message,
       );

  const AppUpdateInstallLaunchResult.permissionDenied([
    String? message,
  ]) : this._(
         status: AppUpdateInstallLaunchStatus.permissionDenied,
         message: message,
       );

  const AppUpdateInstallLaunchResult.failed([
    String? message,
  ]) : this._(
         status: AppUpdateInstallLaunchStatus.failed,
         message: message,
       );

  const AppUpdateInstallLaunchResult.canceled([
    String? message,
  ]) : this._(
         status: AppUpdateInstallLaunchStatus.canceled,
         message: message,
       );

  final AppUpdateInstallLaunchStatus status;
  final String? message;
}

class MethodChannelApkInstallLauncher implements ApkInstallLauncher {
  const MethodChannelApkInstallLauncher();

  @override
  Future<AppUpdateInstallLaunchResult> launch(String filePath) async {
    try {
      final result =
          await _appUpdateMethodChannel.invokeMapMethod<String, dynamic>(
            'launchInstaller',
            <String, dynamic>{'filePath': filePath},
          ) ??
          const <String, dynamic>{};

      final status = result['status'] as String? ?? 'failed';
      final message = result['message'] as String?;

      switch (status) {
        case 'readyToInstall':
          return AppUpdateInstallLaunchResult.readyToInstall(message: message);
        case 'permissionDenied':
          return AppUpdateInstallLaunchResult.permissionDenied(message);
        case 'canceled':
          return AppUpdateInstallLaunchResult.canceled(message);
        default:
          return AppUpdateInstallLaunchResult.failed(message);
      }
    } on PlatformException catch (error) {
      return AppUpdateInstallLaunchResult.failed(
        error.message ?? error.code,
      );
    } catch (error) {
      return AppUpdateInstallLaunchResult.failed(error.toString());
    }
  }
}
