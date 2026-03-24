import 'package:barcode_app/features/auth/application/auth_controller.dart';
import 'package:barcode_app/features/auth/data/auth_repository.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:barcode_app/features/companies/data/company_access_repository.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exige selecao explicita quando ha multiplas empresas disponiveis', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
        companyAccessRepositoryProvider.overrideWithValue(
          _FakeCompanyAccessRepository(
            const [
              CompanyAccess(
                companyId: 'company-a',
                companyCode: 'empresa-a',
                companyName: 'Empresa A',
                role: 'manager',
              ),
              CompanyAccess(
                companyId: 'company-b',
                companyCode: 'empresa-b',
                companyName: 'Empresa B',
                role: 'admin',
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final selectedCompany =
        await container.read(activeCompanyControllerProvider.future);

    expect(selectedCompany, isNull);
  });

  test('mantem a empresa ativa definida no login', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(
            const CurrentSession(
              userId: 'user-1',
              matricula: '1001',
              nome: 'Operador Teste',
              activeCompanyId: 'company-c',
              roles: {'manager'},
              availableCompanies: [
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
            ),
          ),
        ),
        companyAccessRepositoryProvider.overrideWithValue(
          _FakeCompanyAccessRepository(
            const [
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
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final selectedCompany =
        await container.read(activeCompanyControllerProvider.future);

    expect(selectedCompany, 'company-c');
  });
}

class _FakeCompanyAccessRepository extends CompanyAccessRepository {
  _FakeCompanyAccessRepository(this._entries);

  final List<CompanyAccess> _entries;

  @override
  Future<List<CompanyAccess>> listAvailableCompanies() async {
    return _entries;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._session) : super.forTest();

  final CurrentSession? _session;

  @override
  Future<CurrentSession?> loadCurrentSession() async {
    return _session;
  }
}
