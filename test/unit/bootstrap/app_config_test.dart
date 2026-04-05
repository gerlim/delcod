import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrega a configuracao quando url e anon key sao informadas', () {
    final config = AppConfig.fromDefines(
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'anon-key',
      appEnv: 'production',
      appUpdateManifestUrl: 'https://updates.delcod.app/version.json',
    );

    expect(config.supabaseUrl, 'https://project.supabase.co');
    expect(config.supabaseAnonKey, 'anon-key');
    expect(config.appEnv, 'production');
    expect(
      config.appUpdateManifestUri,
      Uri.parse('https://updates.delcod.app/version.json'),
    );
  });

  test(
    'mantem update automatico desabilitado quando manifest url nao for informada',
    () {
      final config = AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );

      expect(config.appUpdateManifestUri, isNull);
    },
  );

  test('falha quando SUPABASE_URL nao for informada', () {
    expect(
      () => AppConfig.fromDefines(
        supabaseUrl: '',
        supabaseAnonKey: 'anon-key',
      ),
      throwsStateError,
    );
  });

  test('falha quando SUPABASE_ANON_KEY nao for informada', () {
    expect(
      () => AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: '',
      ),
      throwsStateError,
    );
  });

  test('falha quando APP_UPDATE_MANIFEST_URL nao for https absoluto', () {
    expect(
      () => AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
        appUpdateManifestUrl: 'http://updates.delcod.app/version.json',
      ),
      throwsStateError,
    );
  });
}
