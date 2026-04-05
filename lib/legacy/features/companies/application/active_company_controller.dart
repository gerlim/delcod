import 'package:barcode_app/legacy/features/auth/application/auth_controller.dart';
import 'package:barcode_app/legacy/features/companies/data/company_access_repository.dart';
import 'package:barcode_app/legacy/features/companies/domain/company_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableCompaniesProvider = FutureProvider<List<CompanyAccess>>((ref) {
  return ref.read(companyAccessRepositoryProvider).listAvailableCompanies();
});

final activeCompanyControllerProvider =
    AsyncNotifierProvider<ActiveCompanyController, String?>(
  ActiveCompanyController.new,
);

class ActiveCompanyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final companies = await ref
        .read(companyAccessRepositoryProvider)
        .listAvailableCompanies();
    final session = await ref.read(authControllerProvider.future);

    if (session?.activeCompanyId case final String companyId?) {
      return companyId;
    }

    if (companies.length == 1) {
      final companyId = companies.first.companyId;
      ref.read(authControllerProvider.notifier).setActiveCompany(companyId);
      return companyId;
    }

    return null;
  }

  void selectCompany(String companyId) {
    ref.read(authControllerProvider.notifier).setActiveCompany(companyId);
    state = AsyncData(companyId);
  }
}

