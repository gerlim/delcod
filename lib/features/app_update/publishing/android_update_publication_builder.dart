import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class FlutterBuildVersion {
  const FlutterBuildVersion({
    required this.versionName,
    required this.versionCode,
  });

  factory FlutterBuildVersion.parse(String value) {
    final match = RegExp(
      r'^([0-9A-Za-z\.\-\+_]+)\+([0-9]+)$',
    ).firstMatch(value.trim());

    if (match == null) {
      throw const FormatException(
        'Versao invalida em pubspec.yaml. Use o formato x.y.z+build.',
      );
    }

    return FlutterBuildVersion(
      versionName: match.group(1)!,
      versionCode: int.parse(match.group(2)!),
    );
  }

  final String versionName;
  final int versionCode;
}

class AndroidUpdatePublicationRequest {
  const AndroidUpdatePublicationRequest({
    required this.sourceApkPath,
    required this.outputDirectoryPath,
    required this.appFilePrefix,
    required this.version,
    required this.baseUri,
    this.releaseNotes,
    this.mandatory = false,
  });

  final String sourceApkPath;
  final String outputDirectoryPath;
  final String appFilePrefix;
  final FlutterBuildVersion version;
  final Uri baseUri;
  final String? releaseNotes;
  final bool mandatory;
}

class AndroidUpdatePublicationResult {
  const AndroidUpdatePublicationResult({
    required this.apkFilePath,
    required this.manifestFilePath,
    required this.apkUri,
    required this.manifestUri,
  });

  final String apkFilePath;
  final String manifestFilePath;
  final Uri apkUri;
  final Uri manifestUri;
}

class AndroidUpdatePublicationBuilder {
  Future<AndroidUpdatePublicationResult> build({
    required AndroidUpdatePublicationRequest request,
  }) async {
    final baseUri = _normalizeBaseUri(request.baseUri);
    final sourceApk = File(request.sourceApkPath);
    if (!await sourceApk.exists()) {
      throw FileSystemException(
        'APK de origem nao encontrado.',
        request.sourceApkPath,
      );
    }

    final outputDirectory = Directory(request.outputDirectoryPath);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final versionedApkName =
        '${request.appFilePrefix}-${request.version.versionCode}.apk';
    final apkFilePath = path.join(outputDirectory.path, versionedApkName);
    final manifestFilePath = path.join(outputDirectory.path, 'version.json');
    final apkUri = baseUri.resolve(versionedApkName);
    final manifestUri = baseUri.resolve('version.json');

    await sourceApk.copy(apkFilePath);

    final manifestPayload = <String, dynamic>{
      'versionName': request.version.versionName,
      'versionCode': request.version.versionCode,
      'apkUrl': apkUri.toString(),
      'mandatory': request.mandatory,
    };

    final releaseNotes = request.releaseNotes?.trim();
    if (releaseNotes != null && releaseNotes.isNotEmpty) {
      manifestPayload['releaseNotes'] = releaseNotes;
    }

    final manifestFile = File(manifestFilePath);
    const encoder = JsonEncoder.withIndent('  ');
    await manifestFile.writeAsString('${encoder.convert(manifestPayload)}\n');

    return AndroidUpdatePublicationResult(
      apkFilePath: apkFilePath,
      manifestFilePath: manifestFilePath,
      apkUri: apkUri,
      manifestUri: manifestUri,
    );
  }

  Uri _normalizeBaseUri(Uri uri) {
    if (!uri.isAbsolute || uri.scheme != 'https') {
      throw const FormatException(
        'Use uma URL base HTTPS absoluta para publicar o update.',
      );
    }

    final normalizedPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: normalizedPath, query: null, fragment: null);
  }
}
