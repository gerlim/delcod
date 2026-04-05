import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class GitHubPagesUpdateSiteRequest {
  const GitHubPagesUpdateSiteRequest({
    required this.owner,
    required this.repository,
    required this.sourceBundleDirectoryPath,
    required this.outputDirectoryPath,
  });

  final String owner;
  final String repository;
  final String sourceBundleDirectoryPath;
  final String outputDirectoryPath;
}

class GitHubPagesUpdateSiteResult {
  const GitHubPagesUpdateSiteResult({
    required this.siteUri,
    required this.updatesBaseUri,
    required this.manifestUri,
    required this.outputDirectoryPath,
  });

  final Uri siteUri;
  final Uri updatesBaseUri;
  final Uri manifestUri;
  final String outputDirectoryPath;
}

class GitHubPagesUpdateSiteBuilder {
  Future<GitHubPagesUpdateSiteResult> build({
    required GitHubPagesUpdateSiteRequest request,
  }) async {
    final owner = request.owner.trim();
    final repository = request.repository.trim();
    if (owner.isEmpty || repository.isEmpty) {
      throw const FormatException(
        'Informe owner e repository para montar a URL do GitHub Pages.',
      );
    }

    final sourceDirectory = Directory(request.sourceBundleDirectoryPath);
    if (!await sourceDirectory.exists()) {
      throw FileSystemException(
        'Bundle de update nao encontrado.',
        request.sourceBundleDirectoryPath,
      );
    }

    final outputDirectory = Directory(request.outputDirectoryPath);
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
    await outputDirectory.create(recursive: true);

    final siteUri = Uri.parse('https://$owner.github.io/$repository/');
    final updatesBaseUri = siteUri.resolve('updates/');
    final manifestUri = updatesBaseUri.resolve('version.json');
    final updatesDirectory = Directory(path.join(outputDirectory.path, 'updates'));
    await updatesDirectory.create(recursive: true);

    await _copyDirectory(sourceDirectory, updatesDirectory);
    await File(path.join(outputDirectory.path, '.nojekyll')).writeAsString('');

    final versionJsonFile = File(path.join(updatesDirectory.path, 'version.json'));
    final currentVersion = await _readCurrentVersionSummary(versionJsonFile);
    await File(path.join(outputDirectory.path, 'index.html')).writeAsString(
      _renderIndexHtml(
        manifestUri: manifestUri,
        apkFileName: currentVersion.apkFileName,
        versionName: currentVersion.versionName,
        versionCode: currentVersion.versionCode,
      ),
    );

    return GitHubPagesUpdateSiteResult(
      siteUri: siteUri,
      updatesBaseUri: updatesBaseUri,
      manifestUri: manifestUri,
      outputDirectoryPath: outputDirectory.path,
    );
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      final entityName = path.basename(entity.path);
      final targetPath = path.join(destination.path, entityName);

      if (entity is File) {
        await entity.copy(targetPath);
        continue;
      }

      if (entity is Directory) {
        final targetDirectory = Directory(targetPath);
        await targetDirectory.create(recursive: true);
        await _copyDirectory(entity, targetDirectory);
      }
    }
  }

  Future<_CurrentVersionSummary> _readCurrentVersionSummary(File manifestFile) async {
    if (!await manifestFile.exists()) {
      throw FileSystemException(
        'version.json nao encontrado no bundle de update.',
        manifestFile.path,
      );
    }

    final contents = jsonDecode(await manifestFile.readAsString());
    if (contents is! Map<String, dynamic>) {
      throw const FormatException('version.json invalido.');
    }

    final apkUrl = contents['apkUrl'] as String?;
    final apkFileName = apkUrl == null ? '' : Uri.parse(apkUrl).pathSegments.last;

    return _CurrentVersionSummary(
      versionName: contents['versionName']?.toString() ?? '',
      versionCode: (contents['versionCode'] as num?)?.toInt() ?? 0,
      apkFileName: apkFileName,
    );
  }

  String _renderIndexHtml({
    required Uri manifestUri,
    required String apkFileName,
    required String versionName,
    required int versionCode,
  }) {
    return '''
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>DelCod Updates</title>
    <style>
      body {
        margin: 0;
        font-family: Arial, sans-serif;
        background: #f2f5f7;
        color: #13232f;
      }
      main {
        max-width: 760px;
        margin: 48px auto;
        padding: 32px;
        background: #ffffff;
        border-radius: 24px;
        box-shadow: 0 20px 60px rgba(19, 35, 47, 0.12);
      }
      h1 {
        margin-top: 0;
        font-size: 32px;
      }
      code {
        display: block;
        margin-top: 8px;
        padding: 12px;
        border-radius: 12px;
        background: #eef3f5;
        overflow-wrap: anywhere;
      }
      a {
        color: #0f766e;
      }
    </style>
  </head>
  <body>
    <main>
      <h1>DelCod Updates</h1>
      <p>Versao atual publicada: <strong>$versionName+$versionCode</strong></p>
      <p>Manifesto do update automatico:</p>
      <code>${manifestUri.toString()}</code>
      <p>APK versionado atual:</p>
      <code>$apkFileName</code>
      <p>
        Esta pagina existe para hospedar o update automatico do APK. O aplicativo Android deve usar o manifesto acima em
        <code>APP_UPDATE_MANIFEST_URL</code>.
      </p>
      <p>
        Download direto do APK:
        <a href="updates/$apkFileName">updates/$apkFileName</a>
      </p>
    </main>
  </body>
</html>
''';
  }
}

class _CurrentVersionSummary {
  const _CurrentVersionSummary({
    required this.versionName,
    required this.versionCode,
    required this.apkFileName,
  });

  final String versionName;
  final int versionCode;
  final String apkFileName;
}
