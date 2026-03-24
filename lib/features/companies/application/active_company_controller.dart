import 'package:barcode_app/features/companies/data/company_access_repository.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableCompaniesProvider = FutureProvider<List<CompanyAccess>>((ref) {
  return ref.read(companyAccessRepositoryProvider).listAvailableCompanies();
});

final activeCompanyControllerProvider =
    AsyncNotifierProvider<ActiveCompanyController, String?>(ActiveCompanyController.new);

class ActiveCompanyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    await ref.read(companyAccessRepositoryProvider).listAvailableCompanies();
    return null;
  }

  void selectCompany(String companyId) {
    state = AsyncData(companyId);
  }
}
