import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:supabase/supabase.dart';

typedef SupabaseInitializer = Future<void> Function(AppConfig config);

class BootstrapResult {
  const BootstrapResult({
    required this.config,
  });

  final AppConfig config;
}

Future<BootstrapResult> bootstrapApplication({
  AppConfig? config,
  SupabaseInitializer? initializeSupabase,
}) async {
  final resolvedConfig = config ?? AppConfig.fromEnvironment();
  final initializer = initializeSupabase ?? _initializeSupabase;

  AppConfigRegistry.initialize(resolvedConfig);
  await initializer(resolvedConfig);

  return BootstrapResult(config: resolvedConfig);
}

Future<void> _initializeSupabase(AppConfig config) {
  SupabaseClientRegistry.initialize(
    SupabaseClient(
      config.supabaseUrl,
      config.supabaseAnonKey,
    ),
  );
  return Future.value();
}
