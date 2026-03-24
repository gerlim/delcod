import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:barcode_app/app/bootstrap/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inicializa o Supabase com a configuração carregada', () async {
    final calls = <AppConfig>[];

    final result = await bootstrapApplication(
      config: AppConfig.fromDefines(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
        appEnv: 'production',
      ),
      initializeSupabase: (config) async {
        calls.add(config);
      },
    );

    expect(calls, hasLength(1));
    expect(calls.single.supabaseUrl, 'https://project.supabase.co');
    expect(result.config.appEnv, 'production');
  });
}
