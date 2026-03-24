import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final companyAccessRepositoryProvider = Provider<CompanyAccessRepository>((ref) {
  return const CompanyAccessRepository();
});

class CompanyAccessRepository {
  const CompanyAccessRepository();

  Future<List<CompanyAccess>> listAvailableCompanies() async {
    return const [];
  }
}
