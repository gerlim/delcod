class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appEnv,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appEnv;

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromDefines(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      appEnv: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
    );
  }

  factory AppConfig.fromDefines({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String appEnv = 'development',
  }) {
    final trimmedUrl = supabaseUrl.trim();
    final trimmedAnonKey = supabaseAnonKey.trim();
    final trimmedEnv = appEnv.trim().isEmpty ? 'development' : appEnv.trim();

    if (trimmedUrl.isEmpty) {
      throw StateError('SUPABASE_URL não foi informada em --dart-define.');
    }

    if (trimmedAnonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY não foi informada em --dart-define.');
    }

    return AppConfig(
      supabaseUrl: trimmedUrl,
      supabaseAnonKey: trimmedAnonKey,
      appEnv: trimmedEnv,
    );
  }
}
