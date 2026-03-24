import 'package:barcode_app/app/bootstrap/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  await initializer(resolvedConfig);

  return BootstrapResult(config: resolvedConfig);
}

Future<void> _initializeSupabase(AppConfig config) {
  return Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );
}
