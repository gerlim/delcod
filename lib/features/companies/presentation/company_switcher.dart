import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanySwitcher extends ConsumerWidget {
  const CompanySwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(availableCompaniesProvider);
    final selectedCompany = ref.watch(activeCompanyControllerProvider).valueOrNull;

    return companies.when(
      data: (items) => DropdownMenu<String>(
        initialSelection: selectedCompany,
        label: const Text('Empresa ativa'),
        dropdownMenuEntries: [
          for (final company in items)
            DropdownMenuEntry<String>(
              value: company.companyId,
              label: company.companyName,
            ),
        ],
        onSelected: (value) {
          if (value != null) {
            ref.read(activeCompanyControllerProvider.notifier).selectCompany(value);
          }
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Falha ao carregar empresas'),
    );
  }
}
