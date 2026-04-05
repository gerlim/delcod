import 'package:barcode_app/features/app_update/data/app_update_installer.dart';
import 'package:barcode_app/features/app_update/data/app_update_installer_android.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidAppUpdateInstaller', () {
    test('baixa o apk, reporta progresso e abre a instalacao', () async {
      final installer = AndroidAppUpdateInstaller(
        downloadService: _FakeApkDownloadService(
          events: [
            const ApkDownloadUpdate.progress(0.25),
            const ApkDownloadUpdate.progress(1.0),
            const ApkDownloadUpdate.completed('C:/DelCod/updates/DelCod-2.apk'),
          ],
        ),
        installLauncher: _FakeApkInstallLauncher(
          result: const AppUpdateInstallLaunchResult.readyToInstall(),
        ),
      );

      final results = await installer.install(_manifest()).toList();

      expect(
        results.map((event) => event.step),
        [
          AppUpdateInstallStep.downloading,
          AppUpdateInstallStep.downloading,
          AppUpdateInstallStep.installing,
        ],
      );
      expect(results[0].progress, 0.25);
      expect(results[1].progress, 1.0);
    });

    test('retorna falha de download quando o arquivo nao baixa', () async {
      final installer = AndroidAppUpdateInstaller(
        downloadService: _FakeApkDownloadService(
          error: const AppUpdateDownloadException('Falha no download'),
        ),
        installLauncher: _FakeApkInstallLauncher(
          result: const AppUpdateInstallLaunchResult.readyToInstall(),
        ),
      );

      final results = await installer.install(_manifest()).toList();

      expect(results.single.step, AppUpdateInstallStep.downloadFailed);
      expect(results.single.message, 'Falha no download');
    });

    test('retorna erro de permissao quando Android bloquear fontes desconhecidas', () async {
      final installer = AndroidAppUpdateInstaller(
        downloadService: _FakeApkDownloadService(
          events: [
            const ApkDownloadUpdate.completed('C:/DelCod/updates/DelCod-2.apk'),
          ],
        ),
        installLauncher: _FakeApkInstallLauncher(
          result: const AppUpdateInstallLaunchResult.permissionDenied(
            'Permita apps desconhecidos',
          ),
        ),
      );

      final results = await installer.install(_manifest()).toList();

      expect(results.single.step, AppUpdateInstallStep.permissionDenied);
      expect(results.single.message, 'Permita apps desconhecidos');
    });
  });
}

AppUpdateManifest _manifest() {
  return AppUpdateManifest.fromJson(
    {
      'versionName': '1.0.1',
      'versionCode': 2,
      'apkUrl': 'https://updates.delcod.app/DelCod-2.apk',
    },
  );
}

class _FakeApkDownloadService implements ApkDownloadService {
  _FakeApkDownloadService({
    this.events = const [],
    this.error,
  });

  final List<ApkDownloadUpdate> events;
  final Object? error;

  @override
  Stream<ApkDownloadUpdate> download(AppUpdateManifest manifest) async* {
    if (error != null) {
      throw error!;
    }

    yield* Stream<ApkDownloadUpdate>.fromIterable(events);
  }
}

class _FakeApkInstallLauncher implements ApkInstallLauncher {
  _FakeApkInstallLauncher({
    required this.result,
  });

  final AppUpdateInstallLaunchResult result;

  @override
  Future<AppUpdateInstallLaunchResult> launch(String filePath) async => result;
}
