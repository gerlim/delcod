import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:barcode_app/legacy/features/admin/domain/admin_user_create_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAdminRepository(client);
});

abstract class AdminRepository {
  Future<void> createUser(AdminUserCreateRequest request);
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> createUser(AdminUserCreateRequest request) async {
    await _client.functions.invoke(
      'admin-create-user',
      body: request.toJson(),
    );
  }
}

