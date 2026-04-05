import 'dart:async';

import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/data/app_update_installer.dart';
import 'package:barcode_app/features/app_update/data/app_update_repository.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('faz checagem automatica e expõe update disponivel', () async {
    final repository = _FakeAppUpdateRepository(
      result: AppUpdateCheckResult(
        status: AppUpdateCheckStatus.available,
        currentVersionName: '1.0.0',
        currentVersionCode: 1,
        manifest: _manifest(versionCode: 2),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(repository),
        appUpdateInstallerProvider.overrideWithValue(_FakeAppUpdateInstaller()),
        appUpdateFeatureEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(appUpdateControllerProvider);
    expect(state.status, AppUpdateStatus.checking);

    await Future<void>.delayed(Duration.zero);

    final resolved = container.read(appUpdateControllerProvider);
    expect(resolved.status, AppUpdateStatus.available);
    expect(resolved.availableManifest?.versionCode, 2);
    expect(repository.checkCount, 1);
  });

  test('esconde a mesma versao na sessao quando usuario escolhe depois', () async {
    final repository = _FakeAppUpdateRepository(
      result: AppUpdateCheckResult(
        status: AppUpdateCheckStatus.available,
        currentVersionName: '1.0.0',
        currentVersionCode: 1,
        manifest: _manifest(versionCode: 2),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(repository),
        appUpdateInstallerProvider.overrideWithValue(_FakeAppUpdateInstaller()),
        appUpdateFeatureEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(appUpdateControllerProvider.notifier);
    await notifier.checkForUpdates();

    notifier.dismissForSession();
    final dismissed = container.read(appUpdateControllerProvider);

    expect(dismissed.status, AppUpdateStatus.idle);

    await notifier.checkForUpdates();
    final rechecked = container.read(appUpdateControllerProvider);

    expect(rechecked.status, AppUpdateStatus.idle);
    expect(repository.checkCount, 2);
  });

  test('atualiza progresso ao baixar e instalar', () async {
    final installer = _FakeAppUpdateInstaller(
      events: [
        const AppUpdateInstallResult.downloading(progress: 0.35),
        const AppUpdateInstallResult.installing(),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(
          _FakeAppUpdateRepository(
            result: AppUpdateCheckResult(
              status: AppUpdateCheckStatus.available,
              currentVersionName: '1.0.0',
              currentVersionCode: 1,
              manifest: _manifest(versionCode: 2),
            ),
          ),
        ),
        appUpdateInstallerProvider.overrideWithValue(installer),
        appUpdateFeatureEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(appUpdateControllerProvider.notifier);
    await notifier.checkForUpdates();
    await notifier.startUpdate();

    final state = container.read(appUpdateControllerProvider);
    expect(state.status, AppUpdateStatus.installing);
    expect(state.downloadProgress, 0.35);
    expect(installer.installCalls, 1);
  });

  test('mostra erro recuperavel quando Android bloquear fontes desconhecidas', () async {
    final installer = _FakeAppUpdateInstaller(
      events: [
        const AppUpdateInstallResult.permissionDenied(),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(
          _FakeAppUpdateRepository(
            result: AppUpdateCheckResult(
              status: AppUpdateCheckStatus.available,
              currentVersionName: '1.0.0',
              currentVersionCode: 1,
              manifest: _manifest(versionCode: 2),
            ),
          ),
        ),
        appUpdateInstallerProvider.overrideWithValue(installer),
        appUpdateFeatureEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(appUpdateControllerProvider.notifier);
    await notifier.checkForUpdates();
    await notifier.startUpdate();

    final state = container.read(appUpdateControllerProvider);
    expect(state.status, AppUpdateStatus.failed);
    expect(state.failureType, AppUpdateFailureType.permissionDenied);
    expect(state.lastError, contains('Permita a instalacao'));
  });

  test('permite tentar novamente apos falha ao abrir instalador', () async {
    final installer = _FakeAppUpdateInstaller(
      sequence: [
        [const AppUpdateInstallResult.installerOpenFailed()],
        [const AppUpdateInstallResult.installing()],
      ],
    );
    final container = ProviderContainer(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(
          _FakeAppUpdateRepository(
            result: AppUpdateCheckResult(
              status: AppUpdateCheckStatus.available,
              currentVersionName: '1.0.0',
              currentVersionCode: 1,
              manifest: _manifest(versionCode: 2),
            ),
          ),
        ),
        appUpdateInstallerProvider.overrideWithValue(installer),
        appUpdateFeatureEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(appUpdateControllerProvider.notifier);
    await notifier.checkForUpdates();

    await notifier.startUpdate();
    final failed = container.read(appUpdateControllerProvider);
    expect(failed.failureType, AppUpdateFailureType.installerFailed);

    await notifier.startUpdate();
    final recovered = container.read(appUpdateControllerProvider);
    expect(recovered.status, AppUpdateStatus.installing);
    expect(installer.installCalls, 2);
  });
}

AppUpdateManifest _manifest({
  required int versionCode,
}) {
  return AppUpdateManifest.fromJson(
    {
      'versionName': '1.0.$versionCode',
      'versionCode': versionCode,
      'apkUrl': 'https://updates.delcod.app/DelCod-$versionCode.apk',
    },
  );
}

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository({
    required this.result,
  });

  final AppUpdateCheckResult result;
  int checkCount = 0;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    checkCount += 1;
    return result;
  }
}

class _FakeAppUpdateInstaller implements AppUpdateInstaller {
  _FakeAppUpdateInstaller({
    List<AppUpdateInstallResult>? events,
    List<List<AppUpdateInstallResult>>? sequence,
  }) : _events = events,
       _sequence = sequence;

  final List<AppUpdateInstallResult>? _events;
  final List<List<AppUpdateInstallResult>>? _sequence;
  int installCalls = 0;

  @override
  Stream<AppUpdateInstallResult> install(AppUpdateManifest manifest) async* {
    installCalls += 1;
    final batches = _sequence;
    if (batches != null && batches.isNotEmpty) {
      final current = batches.removeAt(0);
      yield* Stream<AppUpdateInstallResult>.fromIterable(current);
      return;
    }

    yield* Stream<AppUpdateInstallResult>.fromIterable(
      _events ?? const [],
    );
  }
}
