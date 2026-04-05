import 'package:barcode_app/legacy/features/admin/data/admin_repository.dart';
import 'package:barcode_app/legacy/features/admin/domain/admin_user_create_request.dart';
import 'package:barcode_app/legacy/features/auth/application/current_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminControllerProvider = NotifierProvider<AdminController, bool>(
  AdminController.new,
);

class AdminController extends Notifier<bool> {
  @override
  bool build() {
    final session = ref.watch(currentSessionProvider);
    return session?.roles.contains('admin') ?? false;
  }

  Future<void> createUser(AdminUserCreateRequest request) async {
    if (!state) {
      throw StateError('Somente administradores podem criar usuarios.');
    }

    await ref.read(adminRepositoryProvider).createUser(request);
  }
}

