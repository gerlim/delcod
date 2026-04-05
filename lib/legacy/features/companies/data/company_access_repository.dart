import 'package:barcode_app/legacy/features/auth/application/auth_controller.dart';
import 'package:barcode_app/legacy/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final companyAccessRepositoryProvider =
    Provider<CompanyAccessRepository>((ref) {
  return SessionCompanyAccessRepository(ref);
});

abstract class CompanyAccessRepository {
  Future<List<CompanyAccess>> listAvailableCompanies();
}

class SessionCompanyAccessRepository implements CompanyAccessRepository {
  SessionCompanyAccessRepository(this._ref);

  final Ref _ref;

  @override
  Future<List<CompanyAccess>> listAvailableCompanies() async {
    final session = await _ref.read(authControllerProvider.future);
    return session?.availableCompanies ?? const [];
  }
}

