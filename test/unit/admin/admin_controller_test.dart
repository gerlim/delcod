import 'package:barcode_app/features/admin/application/admin_controller.dart';
import 'package:barcode_app/features/admin/data/admin_repository.dart';
import 'package:barcode_app/features/admin/domain/admin_user_create_request.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('somente admins podem criar usuários', () async {
    final repository = _FakeAdminRepository();
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(
          const CurrentSession(
            userId: 'user-1',
            activeCompanyId: 'company-a',
            roles: {'operator'},
          ),
        ),
        adminRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(adminControllerProvider.notifier).createUser(
            const AdminUserCreateRequest(
              matricula: '1001',
              nome: 'Novo Usuário',
              memberships: [
                CompanyRoleAssignment(
                  companyId: 'company-a',
                  role: 'reader',
                ),
              ],
            ),
          ),
      throwsStateError,
    );
  });

  test('admin consegue criar usuários via repositório administrativo',
      () async {
    final repository = _FakeAdminRepository();
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWithValue(
          const CurrentSession(
            userId: 'admin-1',
            activeCompanyId: 'company-a',
            roles: {'admin'},
          ),
        ),
        adminRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(adminControllerProvider.notifier).createUser(
          const AdminUserCreateRequest(
            matricula: '1002',
            nome: 'Operador Logística',
            memberships: [
              CompanyRoleAssignment(
                companyId: 'company-a',
                role: 'operator',
              ),
            ],
            globalRole: 'manager',
          ),
        );

    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.matricula, '1002');
  });
}

class _FakeAdminRepository implements AdminRepository {
  final List<AdminUserCreateRequest> requests = [];

  @override
  Future<void> createUser(AdminUserCreateRequest request) async {
    requests.add(request);
  }
}
