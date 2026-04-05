import 'dart:convert';

import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  final config = AppConfigRegistry.tryRead();
  if (config == null) {
    return const DisabledAppUpdateRepository();
  }

  return DefaultAppUpdateRepository(config: config);
});

enum AppUpdateCheckStatus {
  disabled,
  upToDate,
  available,
}

class InstalledAppVersion {
  const InstalledAppVersion({
    required this.versionName,
    required this.versionCode,
  });

  final String versionName;
  final int versionCode;
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.status,
    required this.currentVersionName,
    required this.currentVersionCode,
    this.manifest,
  });

  final AppUpdateCheckStatus status;
  final String currentVersionName;
  final int currentVersionCode;
  final AppUpdateManifest? manifest;
}

abstract class AppUpdateRepository {
  Future<AppUpdateCheckResult> checkForUpdate();
}

class DisabledAppUpdateRepository implements AppUpdateRepository {
  const DisabledAppUpdateRepository();

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    return const AppUpdateCheckResult(
      status: AppUpdateCheckStatus.disabled,
      currentVersionName: '',
      currentVersionCode: 0,
    );
  }
}

abstract class AppVersionReader {
  Future<InstalledAppVersion> readInstalledVersion();
}

abstract class AppUpdateManifestReader {
  Future<AppUpdateManifest> read(Uri manifestUri);
}

class DefaultAppUpdateRepository implements AppUpdateRepository {
  DefaultAppUpdateRepository({
    AppConfig? config,
    AppVersionReader? versionReader,
    AppUpdateManifestReader? manifestReader,
  }) : _config = config ?? AppConfigRegistry.instance,
       _versionReader = versionReader ?? PackageInfoAppVersionReader(),
       _manifestReader = manifestReader ?? HttpAppUpdateManifestReader();

  final AppConfig _config;
  final AppVersionReader _versionReader;
  final AppUpdateManifestReader _manifestReader;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    final currentVersion = await _versionReader.readInstalledVersion();
    final manifestUri = _config.appUpdateManifestUri;

    if (manifestUri == null) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.disabled,
        currentVersionName: currentVersion.versionName,
        currentVersionCode: currentVersion.versionCode,
      );
    }

    final manifest = await _manifestReader.read(manifestUri);

    if (manifest.apkUri.origin != manifestUri.origin) {
      throw const FormatException(
        'apkUrl deve usar a mesma origem do manifesto remoto.',
      );
    }

    if (manifest.versionCode > currentVersion.versionCode) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.available,
        currentVersionName: currentVersion.versionName,
        currentVersionCode: currentVersion.versionCode,
        manifest: manifest,
      );
    }

    return AppUpdateCheckResult(
      status: AppUpdateCheckStatus.upToDate,
      currentVersionName: currentVersion.versionName,
      currentVersionCode: currentVersion.versionCode,
    );
  }
}

class PackageInfoAppVersionReader implements AppVersionReader {
  @override
  Future<InstalledAppVersion> readInstalledVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionCode = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;

    return InstalledAppVersion(
      versionName: packageInfo.version.trim(),
      versionCode: versionCode,
    );
  }
}

class HttpAppUpdateManifestReader implements AppUpdateManifestReader {
  HttpAppUpdateManifestReader({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<AppUpdateManifest> read(Uri manifestUri) async {
    final response = await _client.get(
      manifestUri,
      headers: const {'cache-control': 'no-cache'},
    );

    if (response.statusCode != 200) {
      throw FormatException(
        'Manifesto de update indisponivel (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifesto de update invalido.');
    }

    return AppUpdateManifest.fromJson(decoded);
  }
}
