import 'package:barcode_app/features/admin/application/admin_controller.dart';
import 'package:barcode_app/features/admin/data/admin_repository.dart';
import 'package:barcode_app/features/admin/domain/admin_user_create_request.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('somente admins podem criar usuarios', () async {
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
              nome: 'Novo Usuario',
              senhaInicial: 'Temp@123',
              memberships: [
                CompanyRoleAssignment(
                  companyCode: 'del-papeis',
                  role: 'reader',
                ),
              ],
            ),
          ),
      throwsStateError,
    );
  });

  test('admin consegue criar usuarios via repositorio administrativo',
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
            nome: 'Operador Logistica',
            senhaInicial: 'Temp@456',
            memberships: [
              CompanyRoleAssignment(
                companyCode: 'del-papeis',
                role: 'operator',
              ),
            ],
            globalRole: 'gestor_global',
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
