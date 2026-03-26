import 'package:barcode_app/features/companies/domain/company_access.dart';

class CurrentSession {
  const CurrentSession({
    required this.userId,
    required this.activeCompanyId,
    required this.roles,
    this.matricula = '',
    this.nome = '',
    this.globalRole,
    this.availableCompanies = const [],
  });

  final String userId;
  final String? activeCompanyId;
  final Set<String> roles;
  final String matricula;
  final String nome;
  final String? globalRole;
  final List<CompanyAccess> availableCompanies;

  CurrentSession withActiveCompany(String? companyId) {
    final resolvedRoles = <String>{};

    if (globalRole case final String role?) {
      resolvedRoles.add(role);
      switch (role) {
        case 'admin_global':
          resolvedRoles
              .addAll(const {'admin', 'manager', 'operator', 'reader'});
        case 'gestor_global':
          resolvedRoles.addAll(const {'manager', 'operator', 'reader'});
      }
    }

    if (companyId != null) {
      for (final company in availableCompanies) {
        if (company.companyId == companyId) {
          resolvedRoles.add(company.role);
          break;
        }
      }
    }

    return CurrentSession(
      userId: userId,
      activeCompanyId: companyId,
      roles: resolvedRoles,
      matricula: matricula,
      nome: nome,
      globalRole: globalRole,
      availableCompanies: availableCompanies,
    );
  }
}
