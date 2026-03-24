import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:barcode_app/features/companies/data/company_access_repository.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('exige seleção explícita quando há múltiplas empresas disponíveis', () async {
    final container = ProviderContainer(
      overrides: [
        companyAccessRepositoryProvider.overrideWithValue(
          _FakeCompanyAccessRepository(
            const [
              CompanyAccess(
                companyId: 'company-a',
                companyName: 'Empresa A',
                role: 'gestor',
              ),
              CompanyAccess(
                companyId: 'company-b',
                companyName: 'Empresa B',
                role: 'admin',
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final selectedCompany = await container.read(activeCompanyControllerProvider.future);

    expect(selectedCompany, isNull);
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
