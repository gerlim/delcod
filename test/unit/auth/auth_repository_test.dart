import 'package:barcode_app/features/auth/data/auth_repository.dart';
import 'package:barcode_app/features/auth/domain/login_request.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa e-mail tecnico global derivado apenas da matricula', () async {
    final remote = _FakeAuthRemoteDataSource(
      profile: const AuthProfile(
        userId: 'user-1',
        matricula: '1001',
        nome: 'Operador Teste',
        status: 'active',
      ),
      companyAccesses: const [
        CompanyAccess(
          companyId: 'company-a',
          companyCode: 'del-papeis',
          companyName: 'Del Papeis',
          role: 'reader',
        ),
      ],
    );
    final repository = AuthRepository(remote);

    await repository.signIn(
      const LoginRequest(
        companyCode: 'del-papeis',
        matricula: '1001',
        password: '123456',
      ),
    );

    expect(remote.lastEmail, '1001@barcode-app.test');
  });

  test('recusa login quando a empresa escolhida nao esta liberada', () async {
    final remote = _FakeAuthRemoteDataSource(
      profile: const AuthProfile(
        userId: 'user-1',
        matricula: '1001',
        nome: 'Operador Teste',
        status: 'active',
      ),
      companyAccesses: const [
        CompanyAccess(
          companyId: 'company-b',
          companyCode: 'bora-embalagens',
          companyName: 'Bora Embalagens',
          role: 'reader',
        ),
      ],
    );
    final repository = AuthRepository(remote);

    await expectLater(
      repository.signIn(
        const LoginRequest(
          companyCode: 'del-papeis',
          matricula: '1001',
          password: '123456',
        ),
      ),
      throwsStateError,
    );
    expect(remote.didSignOut, isTrue);
  });

  test('carrega sessao com empresa preferida e papeis resolvidos', () async {
    final remote = _FakeAuthRemoteDataSource(
      profile: const AuthProfile(
        userId: 'user-1',
        matricula: '1001',
        nome: 'Admin Teste',
        status: 'active',
        globalRole: 'admin_global',
      ),
      companyAccesses: const [
        CompanyAccess(
          companyId: 'company-a',
          companyCode: 'del-papeis',
          companyName: 'Del Papeis',
          role: 'reader',
        ),
        CompanyAccess(
          companyId: 'company-c',
          companyCode: 'abn-embalagens',
          companyName: 'ABN Embalagens',
          role: 'manager',
        ),
      ],
    );
    final repository = AuthRepository(remote);

    final session = await repository.signIn(
      const LoginRequest(
        companyCode: 'abn-embalagens',
        matricula: '1001',
        password: '123456',
      ),
    );

    expect(session.activeCompanyId, 'company-c');
    expect(session.roles, contains('admin'));
    expect(session.roles, contains('manager'));
    expect(session.availableCompanies, hasLength(2));
  });
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    required this.profile,
    required this.companyAccesses,
  });

  @override
  String? currentUserId = 'user-1';

  final AuthProfile? profile;
  final List<CompanyAccess> companyAccesses;
  String? lastEmail;
  bool didSignOut = false;

  @override
  Future<List<CompanyAccess>> fetchAccessibleCompanies({
    required String userId,
    required String? globalRole,
  }) async {
    return companyAccesses;
  }

  @override
  Future<AuthProfile?> fetchProfile(String userId) async {
    return profile;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
  }

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }

  @override
  Future<void> updateLastLogin(String userId) async {}
}
