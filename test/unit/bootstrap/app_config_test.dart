import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrega a configuração quando url e anon key são informadas', () {
    final config = AppConfig.fromDefines(
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'anon-key',
      appEnv: 'production',
    );

    expect(config.supabaseUrl, 'https://project.supabase.co');
    expect(config.supabaseAnonKey, 'anon-key');
    expect(config.appEnv, 'production');
  });

  test('falha quando SUPABASE_URL não for informada', () {
    expect(
      () => AppConfig.fromDefines(
        supabaseUrl: '',
        supabaseAnonKey: 'anon-key',
      ),
      throwsStateError,
    );
  });

  test('falha quando SUPABASE_ANON_KEY não for informada', () {
    expect(
      () => AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: '',
      ),
      throwsStateError,
    );
  });
}
