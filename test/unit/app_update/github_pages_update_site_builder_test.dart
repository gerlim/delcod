import 'dart:convert';
import 'dart:io';

import 'package:barcode_app/features/app_update/publishing/github_pages_update_site_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('monta site do GitHub Pages com updates e arquivos de suporte', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'delcod-github-pages-site-',
    );
    addTearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    final bundleDirectory = Directory(path.join(sandbox.path, 'bundle'));
    await bundleDirectory.create(recursive: true);
    await File(path.join(bundleDirectory.path, 'DelCod-45.apk')).writeAsBytes(
      const [1, 2, 3],
    );
    await File(path.join(bundleDirectory.path, 'version.json')).writeAsString(
      jsonEncode(
        {
          'versionName': '1.2.3',
          'versionCode': 45,
          'apkUrl': 'https://gerlim.github.io/delcod/updates/DelCod-45.apk',
          'mandatory': false,
        },
      ),
    );

    final outputDirectory = Directory(path.join(sandbox.path, 'site'));
    final result = await GitHubPagesUpdateSiteBuilder().build(
      request: GitHubPagesUpdateSiteRequest(
        owner: 'gerlim',
        repository: 'delcod',
        sourceBundleDirectoryPath: bundleDirectory.path,
        outputDirectoryPath: outputDirectory.path,
      ),
    );

    expect(
      result.siteUri.toString(),
      'https://gerlim.github.io/delcod/',
    );
    expect(
      result.manifestUri.toString(),
      'https://gerlim.github.io/delcod/updates/version.json',
    );
    expect(await File(path.join(outputDirectory.path, '.nojekyll')).exists(), isTrue);
    expect(
      await File(path.join(outputDirectory.path, 'updates', 'DelCod-45.apk')).exists(),
      isTrue,
    );
    expect(
      await File(path.join(outputDirectory.path, 'updates', 'version.json')).exists(),
      isTrue,
    );

    final indexHtml = await File(
      path.join(outputDirectory.path, 'index.html'),
    ).readAsString();
    expect(indexHtml, contains('DelCod Updates'));
    expect(indexHtml, contains('https://gerlim.github.io/delcod/updates/version.json'));
    expect(indexHtml, contains('DelCod-45.apk'));
  });
}
