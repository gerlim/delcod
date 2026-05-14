import 'dart:io';

import 'package:barcode_app/features/app_update/publishing/android_update_publication_builder.dart';
import 'package:barcode_app/features/app_update/publishing/github_pages_update_site_builder.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  final options = _parseArguments(args);
  final scriptFile = File(Platform.script.toFilePath());
  final projectRoot = scriptFile.parent.parent.path;

  final repositorySlug =
      options['repo'] as String? ?? await _readRepositorySlug(projectRoot);
  final slugParts = repositorySlug.split('/');
  if (slugParts.length != 2) {
    stderr.writeln(
      'Nao foi possivel identificar owner/repo. Use --repo owner/repo.',
    );
    exitCode = 64;
    return;
  }

  final owner = slugParts[0];
  final repository = slugParts[1];
  final version = FlutterBuildVersion.parse(
    _readPubspecVersion(
      await File(path.join(projectRoot, 'pubspec.yaml')).readAsString(),
    ),
  );
  final sourceApkPath = options['source-apk'] as String? ??
      path.join(
        projectRoot,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      );

  final publicationDirectory = path.join(projectRoot, 'build', 'app_update');
  final siteDirectory = path.join(projectRoot, 'build', 'github_pages_site');
  final updatesBaseUri =
      Uri.parse('https://$owner.github.io/$repository/updates/');

  final publication = await AndroidUpdatePublicationBuilder().build(
    request: AndroidUpdatePublicationRequest(
      sourceApkPath: sourceApkPath,
      outputDirectoryPath: publicationDirectory,
      appFilePrefix: options['app-prefix'] as String? ?? 'DelCod',
      version: version,
      baseUri: updatesBaseUri,
      releaseNotes: options['release-notes'] as String?,
      mandatory: options['mandatory'] as bool? ?? false,
    ),
  );

  final site = await GitHubPagesUpdateSiteBuilder().build(
    request: GitHubPagesUpdateSiteRequest(
      owner: owner,
      repository: repository,
      sourceBundleDirectoryPath: publicationDirectory,
      outputDirectoryPath: siteDirectory,
    ),
  );

  final shouldPush = !(options['no-push'] as bool? ?? false);
  if (shouldPush) {
    await _publishSiteToGhPages(
      projectRoot: projectRoot,
      siteDirectoryPath: siteDirectory,
    );
  }

  stdout.writeln('Publicacao do update preparada com sucesso.');
  stdout.writeln('Repositorio: $repositorySlug');
  stdout.writeln('Site Pages: ${site.siteUri}');
  stdout.writeln('Manifesto: ${site.manifestUri}');
  stdout.writeln('APK versionado: ${publication.apkFilePath}');
  stdout.writeln('Pasta do site: ${site.outputDirectoryPath}');
  if (shouldPush) {
    stdout.writeln('Branch gh-pages atualizada com sucesso.');
  } else {
    stdout
        .writeln('Branch gh-pages nao foi atualizada por causa de --no-push.');
  }
}

Map<String, Object?> _parseArguments(List<String> args) {
  final options = <String, Object?>{};
  for (var index = 0; index < args.length; index += 1) {
    final argument = args[index];
    switch (argument) {
      case '--repo':
      case '--release-notes':
      case '--source-apk':
      case '--app-prefix':
        if (index + 1 >= args.length) {
          throw FormatException('Valor ausente para $argument.');
        }
        options[argument.substring(2)] = args[index + 1];
        index += 1;
        break;
      case '--mandatory':
        options['mandatory'] = true;
        break;
      case '--no-push':
        options['no-push'] = true;
        break;
      default:
        throw FormatException('Argumento desconhecido: $argument');
    }
  }

  return options;
}

Future<String> _readRepositorySlug(String projectRoot) async {
  final remoteResult = await Process.run(
    'git',
    ['config', '--get', 'remote.origin.url'],
    workingDirectory: projectRoot,
  );
  if (remoteResult.exitCode != 0) {
    throw ProcessException(
      'git',
      const ['config', '--get', 'remote.origin.url'],
      remoteResult.stderr.toString(),
      remoteResult.exitCode,
    );
  }

  final remoteUrl = remoteResult.stdout.toString().trim();
  return _slugFromRemoteUrl(remoteUrl);
}

String _slugFromRemoteUrl(String remoteUrl) {
  final normalized = remoteUrl.trim();
  final httpsMatch = RegExp(r'github\.com[:/](.+?)(?:\.git)?$').firstMatch(
    normalized,
  );
  if (httpsMatch == null) {
    throw FormatException('Remote origin invalido para GitHub: $remoteUrl');
  }

  return httpsMatch.group(1)!;
}

Future<void> _publishSiteToGhPages({
  required String projectRoot,
  required String siteDirectoryPath,
}) async {
  final worktreeDirectory = Directory(
    path.join(projectRoot, 'build', 'gh_pages_worktree'),
  );

  if (await worktreeDirectory.exists()) {
    await Process.run(
      'git',
      ['worktree', 'remove', worktreeDirectory.path, '--force'],
      workingDirectory: projectRoot,
    );
    await worktreeDirectory.delete(recursive: true);
  }

  final hasLocalBranch = await _gitSucceeds(
    projectRoot,
    ['show-ref', '--verify', '--quiet', 'refs/heads/gh-pages'],
  );
  if (!hasLocalBranch) {
    final hasRemoteBranch = await _gitSucceeds(
      projectRoot,
      ['show-ref', '--verify', '--quiet', 'refs/remotes/origin/gh-pages'],
    );

    if (hasRemoteBranch) {
      await _runGit(
        projectRoot,
        ['branch', '--track', 'gh-pages', 'origin/gh-pages'],
      );
    } else {
      await _runGit(
        projectRoot,
        ['branch', 'gh-pages', 'HEAD'],
      );
    }
  }

  await _runGit(
    projectRoot,
    ['worktree', 'add', worktreeDirectory.path, 'gh-pages'],
  );

  try {
    await _clearDirectory(worktreeDirectory);
    await _copyDirectory(
      Directory(siteDirectoryPath),
      worktreeDirectory,
    );

    await _runGit(
      worktreeDirectory.path,
      ['add', '--all'],
    );

    final status = await Process.run(
      'git',
      ['status', '--short'],
      workingDirectory: worktreeDirectory.path,
    );
    final hasChanges = status.stdout.toString().trim().isNotEmpty;
    if (!hasChanges) {
      return;
    }

    await _runGit(
      worktreeDirectory.path,
      ['commit', '-m', 'chore: publish android update bundle'],
    );
    await _runGit(
      worktreeDirectory.path,
      ['push', 'origin', 'gh-pages'],
    );
  } finally {
    await Process.run(
      'git',
      ['worktree', 'remove', worktreeDirectory.path, '--force'],
      workingDirectory: projectRoot,
    );
  }
}

Future<void> _clearDirectory(Directory directory) async {
  await for (final entity in directory.list(recursive: false)) {
    final baseName = path.basename(entity.path);
    if (baseName == '.git') {
      continue;
    }

    await entity.delete(recursive: true);
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (final entity in source.list(recursive: false)) {
    final name = path.basename(entity.path);
    final targetPath = path.join(destination.path, name);
    if (entity is File) {
      await entity.copy(targetPath);
    } else if (entity is Directory) {
      final targetDirectory = Directory(targetPath);
      await targetDirectory.create(recursive: true);
      await _copyDirectory(entity, targetDirectory);
    }
  }
}

Future<void> _runGit(String workingDirectory, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
}

Future<bool> _gitSucceeds(
    String workingDirectory, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  return result.exitCode == 0;
}

String _readPubspecVersion(String contents) {
  for (final line in contents.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      final value = trimmed.substring('version:'.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }

  throw const FormatException('Campo version nao encontrado em pubspec.yaml.');
}
