import 'dart:io';

import 'package:barcode_app/features/app_update/publishing/android_update_publication_builder.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  final options = _parseArguments(args);

  if (options['base-url'] == null || (options['base-url'] as String).isEmpty) {
    stderr.writeln(
      'Uso: dart run scripts/prepare_android_update.dart --base-url https://updates.seu-host/',
    );
    exitCode = 64;
    return;
  }

  final scriptFile = File(Platform.script.toFilePath());
  final projectRoot = scriptFile.parent.parent.path;
  final pubspecFile = File(path.join(projectRoot, 'pubspec.yaml'));
  final version = FlutterBuildVersion.parse(
    _readPubspecVersion(await pubspecFile.readAsString()),
  );

  final sourceApkPath =
      options['source-apk'] as String? ??
      path.join(projectRoot, 'build', 'app', 'outputs', 'apk', 'release', 'DelCod.apk');
  final outputDirectoryPath =
      options['output-dir'] as String? ??
      path.join(projectRoot, 'build', 'app_update');
  final appFilePrefix = options['app-prefix'] as String? ?? 'DelCod';

  final result = await AndroidUpdatePublicationBuilder().build(
    request: AndroidUpdatePublicationRequest(
      sourceApkPath: sourceApkPath,
      outputDirectoryPath: outputDirectoryPath,
      appFilePrefix: appFilePrefix,
      version: version,
      baseUri: Uri.parse(options['base-url'] as String),
      releaseNotes: options['release-notes'] as String?,
      mandatory: options['mandatory'] as bool? ?? false,
    ),
  );

  stdout.writeln('Pacote de update preparado com sucesso.');
  stdout.writeln('APK versionado: ${result.apkFilePath}');
  stdout.writeln('Manifesto: ${result.manifestFilePath}');
  stdout.writeln('apkUrl: ${result.apkUri}');
  stdout.writeln('APP_UPDATE_MANIFEST_URL: ${result.manifestUri}');
  stdout.writeln('');
  stdout.writeln('Proximo passo: publique os dois arquivos no mesmo host.');
}

Map<String, Object?> _parseArguments(List<String> args) {
  final options = <String, Object?>{};
  for (var index = 0; index < args.length; index += 1) {
    final argument = args[index];
    switch (argument) {
      case '--base-url':
      case '--release-notes':
      case '--source-apk':
      case '--output-dir':
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
      default:
        throw FormatException('Argumento desconhecido: $argument');
    }
  }

  return options;
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
