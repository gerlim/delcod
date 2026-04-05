class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appEnv,
    this.appUpdateManifestUri,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appEnv;
  final Uri? appUpdateManifestUri;

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromDefines(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      appEnv: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      appUpdateManifestUrl: const String.fromEnvironment(
        'APP_UPDATE_MANIFEST_URL',
      ),
    );
  }

  factory AppConfig.fromDefines({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String appEnv = 'development',
    String appUpdateManifestUrl = '',
  }) {
    final trimmedUrl = supabaseUrl.trim();
    final trimmedAnonKey = supabaseAnonKey.trim();
    final trimmedEnv = appEnv.trim().isEmpty ? 'development' : appEnv.trim();
    final trimmedManifestUrl = appUpdateManifestUrl.trim();

    if (trimmedUrl.isEmpty) {
      throw StateError('SUPABASE_URL nao foi informada em --dart-define.');
    }

    if (trimmedAnonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY nao foi informada em --dart-define.');
    }

    final manifestUri = trimmedManifestUrl.isEmpty
        ? null
        : Uri.tryParse(trimmedManifestUrl);

    if (trimmedManifestUrl.isNotEmpty &&
        (manifestUri == null ||
            !manifestUri.isAbsolute ||
            manifestUri.scheme != 'https')) {
      throw StateError(
        'APP_UPDATE_MANIFEST_URL deve ser uma URL https absoluta.',
      );
    }

    return AppConfig(
      supabaseUrl: trimmedUrl,
      supabaseAnonKey: trimmedAnonKey,
      appEnv: trimmedEnv,
      appUpdateManifestUri: manifestUri,
    );
  }
}

class AppConfigRegistry {
  static AppConfig? _config;

  static void initialize(AppConfig config) {
    _config = config;
  }

  static AppConfig get instance {
    final config = _config;
    if (config == null) {
      throw StateError('AppConfig nao foi inicializada.');
    }
    return config;
  }

  static AppConfig? tryRead() => _config;
}
