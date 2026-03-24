import 'package:barcode_app/features/auth/application/auth_controller.dart';
import 'package:barcode_app/features/auth/data/auth_repository.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/auth/domain/login_request.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inicia sem sessao autenticada', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(authControllerProvider.future);

    expect(session, isNull);
  });

  test('atualiza a sessao com a empresa escolhida no login', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(
            sessionOnSignIn: const CurrentSession(
              userId: 'user-1',
              matricula: '1001',
              nome: 'Operador Teste',
              activeCompanyId: 'company-b',
              roles: {'operator'},
              availableCompanies: [
                CompanyAccess(
                  companyId: 'company-a',
                  companyCode: 'del-papeis',
                  companyName: 'Del Papeis',
                  role: 'reader',
                ),
                CompanyAccess(
                  companyId: 'company-b',
                  companyCode: 'bora-embalagens',
                  companyName: 'Bora Embalagens',
                  role: 'operator',
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signIn(
          const LoginRequest(
            companyCode: 'bora-embalagens',
            matricula: '1001',
            password: '123456',
          ),
        );

    final session = container.read(authControllerProvider).valueOrNull;
    expect(session?.activeCompanyId, 'company-b');
    expect(session?.roles, contains('operator'));
  });

  test('permite trocar a empresa ativa e recalcula os papeis', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(
            initialSession: const CurrentSession(
              userId: 'user-1',
              matricula: '1001',
              nome: 'Gestor Teste',
              activeCompanyId: 'company-a',
              roles: {'reader'},
              availableCompanies: [
                CompanyAccess(
                  companyId: 'company-a',
                  companyCode: 'del-papeis',
                  companyName: 'Del Papeis',
                  role: 'reader',
                ),
                CompanyAccess(
                  companyId: 'company-b',
                  companyCode: 'bora-embalagens',
                  companyName: 'Bora Embalagens',
                  role: 'admin',
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).setActiveCompany('company-b');

    final session = container.read(authControllerProvider).valueOrNull;
    expect(session?.activeCompanyId, 'company-b');
    expect(session?.roles, contains('admin'));
    expect(session?.roles, isNot(contains('reader')));
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    this.initialSession,
    this.sessionOnSignIn,
  }) : super.forTest();

  final CurrentSession? initialSession;
  final CurrentSession? sessionOnSignIn;

  @override
  Future<CurrentSession?> loadCurrentSession() async {
    return initialSession;
  }

  @override
  Future<CurrentSession> signIn(LoginRequest request) async {
    return sessionOnSignIn ?? initialSession!;
  }
}
