import 'dart:convert';

import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:barcode_app/features/app_update/data/app_update_repository.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('retorna desabilitado quando APP_UPDATE_MANIFEST_URL nao foi configurada', () async {
    final repository = DefaultAppUpdateRepository(
      config: AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      ),
      versionReader: const _FakeVersionReader(
        InstalledAppVersion(
          versionName: '1.0.0',
          versionCode: 1,
        ),
      ),
      manifestReader: _UnusedManifestReader(),
    );

    final result = await repository.checkForUpdate();

    expect(result.status, AppUpdateCheckStatus.disabled);
    expect(result.manifest, isNull);
  });

  test('retorna update disponivel quando versionCode remoto for maior', () async {
    final repository = DefaultAppUpdateRepository(
      config: AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
        appUpdateManifestUrl: 'https://updates.delcod.app/version.json',
      ),
      versionReader: const _FakeVersionReader(
        InstalledAppVersion(
          versionName: '1.0.0',
          versionCode: 1,
        ),
      ),
      manifestReader: _FakeManifestReader(
        AppUpdateManifest.fromJson(
          {
            'versionName': '1.0.1',
            'versionCode': 2,
            'apkUrl': 'https://updates.delcod.app/DelCod-2.apk',
          },
        ),
      ),
    );

    final result = await repository.checkForUpdate();

    expect(result.status, AppUpdateCheckStatus.available);
    expect(result.manifest?.versionCode, 2);
    expect(result.currentVersionCode, 1);
  });

  test('retorna atualizado quando versionCode remoto nao for maior', () async {
    final repository = DefaultAppUpdateRepository(
      config: AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
        appUpdateManifestUrl: 'https://updates.delcod.app/version.json',
      ),
      versionReader: const _FakeVersionReader(
        InstalledAppVersion(
          versionName: '1.0.1',
          versionCode: 2,
        ),
      ),
      manifestReader: _FakeManifestReader(
        AppUpdateManifest.fromJson(
          {
            'versionName': '1.0.1',
            'versionCode': 2,
            'apkUrl': 'https://updates.delcod.app/DelCod-2.apk',
          },
        ),
      ),
    );

    final result = await repository.checkForUpdate();

    expect(result.status, AppUpdateCheckStatus.upToDate);
    expect(result.manifest, isNull);
  });

  test('falha quando o apkUrl nao usa a mesma origem do manifesto', () async {
    final repository = DefaultAppUpdateRepository(
      config: AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
        appUpdateManifestUrl: 'https://updates.delcod.app/version.json',
      ),
      versionReader: const _FakeVersionReader(
        InstalledAppVersion(
          versionName: '1.0.0',
          versionCode: 1,
        ),
      ),
      manifestReader: _FakeManifestReader(
        AppUpdateManifest.fromJson(
          {
            'versionName': '1.0.1',
            'versionCode': 2,
            'apkUrl': 'https://cdn.delcod.app/DelCod-2.apk',
          },
        ),
      ),
    );

    expect(
      repository.checkForUpdate,
      throwsFormatException,
    );
  });

  test('faz a leitura do manifesto com cache buster para evitar resposta antiga', () async {
    final client = _RecordingClient();
    final reader = HttpAppUpdateManifestReader(client: client);

    await reader.read(Uri.parse('https://gerlim.github.io/delcod/updates/version.json'));

    expect(client.lastUri, isNotNull);
    expect(client.lastUri!.host, 'gerlim.github.io');
    expect(client.lastUri!.path, '/delcod/updates/version.json');
    expect(client.lastUri!.queryParameters['t'], isNotEmpty);
    expect(client.lastHeaders['cache-control'], 'no-cache');
  });
}

class _FakeVersionReader implements AppVersionReader {
  const _FakeVersionReader(this.version);

  final InstalledAppVersion version;

  @override
  Future<InstalledAppVersion> readInstalledVersion() async => version;
}

class _FakeManifestReader implements AppUpdateManifestReader {
  const _FakeManifestReader(this.manifest);

  final AppUpdateManifest manifest;

  @override
  Future<AppUpdateManifest> read(Uri manifestUri) async => manifest;
}

class _UnusedManifestReader implements AppUpdateManifestReader {
  @override
  Future<AppUpdateManifest> read(Uri manifestUri) {
    throw UnimplementedError();
  }
}

class _RecordingClient extends http.BaseClient {
  Uri? lastUri;
  Map<String, String> lastHeaders = const {};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastHeaders = Map<String, String>.from(request.headers);

    final bytes = utf8.encode(
      '{"versionName":"1.0.1","versionCode":2,"apkUrl":"https://gerlim.github.io/delcod/updates/DelCod-2.apk"}',
    );

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
