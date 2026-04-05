import 'dart:convert';
import 'dart:io';

import 'package:barcode_app/features/app_update/publishing/android_update_publication_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('parseia version do Flutter em versionName e versionCode', () {
    final version = FlutterBuildVersion.parse('1.2.3+45');

    expect(version.versionName, '1.2.3');
    expect(version.versionCode, 45);
  });

  test('gera pacote de publicacao com apk versionado e version.json', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'delcod-update-publication-',
    );
    addTearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    final sourceApk = File(path.join(sandbox.path, 'DelCod.apk'));
    await sourceApk.writeAsBytes(const [1, 2, 3, 4]);

    final outputDirectory = Directory(path.join(sandbox.path, 'bundle'));
    final builder = AndroidUpdatePublicationBuilder();

    final result = await builder.build(
      request: AndroidUpdatePublicationRequest(
        sourceApkPath: sourceApk.path,
        outputDirectoryPath: outputDirectory.path,
        appFilePrefix: 'DelCod',
        version: FlutterBuildVersion.parse('1.2.3+45'),
        baseUri: Uri.parse('https://updates.delcod.app/releases/'),
        releaseNotes: 'Melhorias na importacao.',
        mandatory: false,
      ),
    );

    final copiedApk = File(result.apkFilePath);
    final manifestFile = File(result.manifestFilePath);

    expect(await copiedApk.exists(), isTrue);
    expect(path.basename(copiedApk.path), 'DelCod-45.apk');
    expect(await copiedApk.readAsBytes(), [1, 2, 3, 4]);

    expect(await manifestFile.exists(), isTrue);

    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    expect(manifest['versionName'], '1.2.3');
    expect(manifest['versionCode'], 45);
    expect(
      manifest['apkUrl'],
      'https://updates.delcod.app/releases/DelCod-45.apk',
    );
    expect(manifest['releaseNotes'], 'Melhorias na importacao.');
    expect(manifest['mandatory'], false);
    expect(
      result.manifestUri.toString(),
      'https://updates.delcod.app/releases/version.json',
    );
  });
}
