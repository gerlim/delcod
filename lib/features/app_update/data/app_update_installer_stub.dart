import 'package:barcode_app/features/app_update/data/app_update_installer.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';

AppUpdateInstaller createAppUpdateInstaller() => UnsupportedAppUpdateInstaller();

class UnsupportedAppUpdateInstaller implements AppUpdateInstaller {
  @override
  Stream<AppUpdateInstallResult> install(AppUpdateManifest manifest) async* {
    yield const AppUpdateInstallResult.installerOpenFailed(
      message: 'Atualizacao automatica indisponivel nesta plataforma.',
    );
  }
}
