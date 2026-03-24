import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);
  AuthRepository.forTest() : _client = null;

  final SupabaseClient? _client;

  Future<CurrentSession?> loadCurrentSession() async {
    final session = _client?.auth.currentSession;
    if (session == null) {
      return null;
    }

    return CurrentSession(
      userId: session.user.id,
      activeCompanyId: null,
      roles: const {},
    );
  }
}
