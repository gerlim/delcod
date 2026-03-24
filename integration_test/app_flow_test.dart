import 'package:barcode_app/features/auth/presentation/login_page.dart';
import 'package:barcode_app/features/companies/data/company_access_repository.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/companies/presentation/company_switcher.dart';
import 'package:barcode_app/features/collections/presentation/collections_page.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renderiza login, seleção de empresa, coletas e leituras',
      (tester) async {
    final readingsRepository = ReadingsRepository();
    await readingsRepository.saveReading(
      const ReadingInput(
        collectionId: 'collection-1',
        code: '7891234567890',
        source: 'camera',
        codeType: 'EAN-13',
        operatorName: 'Operador 01',
        recordedAt: DateTime(2026, 3, 23, 10, 30),
      ),
    );

    await _pumpScreen(
      tester,
      const LoginPage(),
    );

    expect(find.text('Barcode App'), findsOneWidget);
    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Matrícula'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);

    await _pumpScreen(
      tester,
      const Scaffold(
        body: Center(
          child: CompanySwitcher(),
        ),
      ),
      overrides: [
        companyAccessRepositoryProvider.overrideWithValue(
          const _FakeCompanyAccessRepository(
            [
              CompanyAccess(
                companyId: 'company-a',
                companyName: 'Empresa A',
                role: 'operator',
              ),
              CompanyAccess(
                companyId: 'company-b',
                companyName: 'Empresa B',
                role: 'reader',
              ),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Empresa ativa'), findsOneWidget);

    await _pumpScreen(
      tester,
      const CollectionsPage(),
      overrides: [
        syncPollingEnabledProvider.overrideWithValue(false),
      ],
    );

    expect(find.text('Coletas'), findsOneWidget);
    expect(find.text('Nova coleta'), findsOneWidget);

    await _pumpScreen(
      tester,
      const ReadingsPage(
        collectionId: 'collection-1',
        collectionTitle: 'Coleta Expedição 01',
      ),
      overrides: [
        syncPollingEnabledProvider.overrideWithValue(false),
        readingsRepositoryProvider.overrideWithValue(readingsRepository),
      ],
    );

    expect(find.text('Coleta Expedição 01'), findsOneWidget);
    expect(find.text('Total: 1'), findsOneWidget);
    expect(find.text('Exportar XLSX'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(const Duration(milliseconds: 150));
}

class _FakeCompanyAccessRepository extends CompanyAccessRepository {
  const _FakeCompanyAccessRepository(this._items);

  final List<CompanyAccess> _items;

  @override
  Future<List<CompanyAccess>> listAvailableCompanies() async {
    return _items;
  }
}
