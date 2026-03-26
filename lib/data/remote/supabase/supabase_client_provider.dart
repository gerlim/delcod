import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientRegistry.instance;
});

class SupabaseClientRegistry {
  static SupabaseClient? _client;

  static void initialize(SupabaseClient client) {
    _client = client;
  }

  static SupabaseClient get instance {
    final client = _client;
    if (client == null) {
      throw StateError('SupabaseClient nao foi inicializado.');
    }
    return client;
  }

  static SupabaseClient? tryRead() => _client;
}
