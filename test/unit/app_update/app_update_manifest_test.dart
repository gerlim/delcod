import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseia manifesto valido', () {
    final manifest = AppUpdateManifest.fromJson(
      {
        'versionName': '1.0.1',
        'versionCode': 2,
        'apkUrl': 'https://updates.delcod.app/DelCod-2.apk',
        'releaseNotes': 'Melhorias gerais',
        'mandatory': false,
      },
    );

    expect(manifest.versionName, '1.0.1');
    expect(manifest.versionCode, 2);
    expect(
      manifest.apkUri,
      Uri.parse('https://updates.delcod.app/DelCod-2.apk'),
    );
    expect(manifest.releaseNotes, 'Melhorias gerais');
    expect(manifest.mandatory, isFalse);
  });

  test('falha quando versionCode nao for maior que zero', () {
    expect(
      () => AppUpdateManifest.fromJson(
        {
          'versionName': '1.0.1',
          'versionCode': 0,
          'apkUrl': 'https://updates.delcod.app/DelCod-2.apk',
        },
      ),
      throwsFormatException,
    );
  });

  test('falha quando apkUrl nao for https', () {
    expect(
      () => AppUpdateManifest.fromJson(
        {
          'versionName': '1.0.1',
          'versionCode': 2,
          'apkUrl': 'http://updates.delcod.app/DelCod-2.apk',
        },
      ),
      throwsFormatException,
    );
  });
}
