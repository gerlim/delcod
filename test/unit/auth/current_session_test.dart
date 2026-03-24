import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recalcula papeis conforme a empresa ativa', () {
    const session = CurrentSession(
      userId: 'user-1',
      matricula: '1001',
      nome: 'Operador Teste',
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
          role: 'operator',
        ),
      ],
    );

    final updated = session.withActiveCompany('company-b');

    expect(updated.activeCompanyId, 'company-b');
    expect(updated.roles, contains('operator'));
    expect(updated.roles, isNot(contains('reader')));
  });

  test('admin global mantem capacidades administrativas em qualquer empresa', () {
    const session = CurrentSession(
      userId: 'user-1',
      matricula: '9001',
      nome: 'Admin Global',
      activeCompanyId: null,
      globalRole: 'admin_global',
      roles: {'admin'},
      availableCompanies: [
        CompanyAccess(
          companyId: 'company-c',
          companyCode: 'abn-embalagens',
          companyName: 'ABN Embalagens',
          role: 'reader',
        ),
      ],
    );

    final updated = session.withActiveCompany('company-c');

    expect(updated.roles, contains('admin'));
    expect(updated.roles, contains('manager'));
    expect(updated.roles, contains('operator'));
  });
}
