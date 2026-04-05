// ignore_for_file: prefer_const_constructors

import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/presentation/readings_page.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o total inicial da lista global', (tester) async {
    final repository = _StaticReadingsRepository(
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);
    expect(find.text('Bobinas ativas'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.text('Importar arquivo'), findsOneWidget);
    expect(find.text('Alocar armazem'), findsOneWidget);
    expect(find.text('Exportar Excel'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });

  testWidgets(
      'em telas largas posiciona a lista a direita do painel operacional',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: [
        ReadingItem(
          id: '1',
          code: '789123',
          source: 'manual',
          updatedAt: DateTime.parse('2026-03-25T22:40:00Z'),
          deletedAt: null,
          deviceId: 'web',
          metadataPayload: const {
            'warehouse_code': '05',
            'warehouse_company': 'Bora Embalagens',
            'bobbin_lot': '789123',
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inputCardFinder = find.ancestor(
      of: find.text('Entrada manual'),
      matching: find.byType(Card),
    );
    final listCardFinder = find.ancestor(
      of: find.text('Lista global'),
      matching: find.byType(Card),
    );

    expect(find.text('Acoes da lista'), findsOneWidget);
    expect(inputCardFinder, findsOneWidget);
    expect(listCardFinder, findsOneWidget);
    expect(find.text('Lote de Bobina'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Armazem'), findsAtLeastNWidgets(1));
    expect(
      tester.getTopLeft(listCardFinder).dx,
      greaterThan(tester.getTopLeft(inputCardFinder).dx + 300),
    );
  });

  testWidgets('no mobile mostra secoes separadas para resumo e acoes',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Acoes da lista'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo rapido', skipOffstage: false), findsOneWidget);
    expect(find.text('Acoes da lista'), findsOneWidget);
  });

  testWidgets('no mobile o topo sobe junto quando a pagina rola',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: List.generate(
        18,
        (index) => ReadingItem(
          id: 'item-$index',
          code: '78912$index',
          source: 'manual',
          updatedAt: DateTime.parse('2026-03-25T22:40:00Z')
              .add(Duration(minutes: index)),
          deletedAt: null,
          deviceId: 'android',
          metadataPayload: {
            'warehouse_code': index.isEven ? '05' : 'GLR',
            'warehouse_company':
                index.isEven ? 'Bora Embalagens' : 'ABN Embalagens',
            'bobbin_lot': '78912$index',
          },
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('DelCod'), findsNothing);
  });

  testWidgets('mantem a busca escondida ate clicar na lupa', (tester) async {
    final repository = _StaticReadingsRepository(
      items: [
        _buildItem(
          id: '1',
          lot: '001126023205936309',
          warehouseCode: '05',
          companyName: 'Bora Embalagens',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Pesquisar lote ou armazem'), findsNothing);

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pesquisar lote ou armazem'), findsOneWidget);
  });

  testWidgets('filtra a lista por lote e por armazem', (tester) async {
    final repository = _StaticReadingsRepository(
      items: [
        _buildItem(
          id: '1',
          lot: '001126023205936309',
          warehouseCode: '05',
          companyName: 'Bora Embalagens',
        ),
        _buildItem(
          id: '2',
          lot: 'PPI00004549',
          warehouseCode: 'PPI',
          companyName: 'Bora Embalagens',
        ),
        _buildItem(
          id: '3',
          lot: 'GLR998877',
          warehouseCode: 'GLR',
          companyName: 'ABN Embalagens',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Pesquisar lote ou armazem'),
      '998877',
    );
    await tester.pumpAndSettle();

    expect(find.text('GLR998877'), findsOneWidget);
    expect(find.text('001126023205936309'), findsNothing);
    expect(find.text('PPI00004549'), findsNothing);
    expect(find.text('1 itens'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Pesquisar lote ou armazem'),
      'ppi',
    );
    await tester.pumpAndSettle();

    expect(find.text('PPI00004549'), findsOneWidget);
    expect(find.text('GLR998877'), findsNothing);
    expect(find.text('001126023205936309'), findsNothing);
  });

  testWidgets('mostra estado vazio quando a busca nao encontra itens',
      (tester) async {
    final repository = _StaticReadingsRepository(
      items: [
        _buildItem(
          id: '1',
          lot: '001126023205936309',
          warehouseCode: '05',
          companyName: 'Bora Embalagens',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Pesquisar lote ou armazem'),
      'inexistente',
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum lote encontrado para a pesquisa atual'), findsOneWidget);
  });

  testWidgets('mostra banner de update no Android quando houver nova versao',
      (tester) async {
    final repository = _StaticReadingsRepository(items: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
          appUpdateControllerProvider.overrideWith(
            () => _StaticAppUpdateController(
              AppUpdateState(
                status: AppUpdateStatus.available,
                currentVersionName: '1.0.0',
                currentVersionCode: 1,
                availableManifest: AppUpdateManifest.fromJson(
                  {
                    'versionName': '1.0.1',
                    'versionCode': 2,
                    'apkUrl':
                        'https://updates.delcod.app/DelCod-2.apk',
                  },
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova versao disponivel'), findsOneWidget);
    expect(find.text('Atualizar agora'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);
  });

  testWidgets('mantem banner de update escondido no web', (tester) async {
    final repository = _StaticReadingsRepository(items: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsRepositoryProvider.overrideWithValue(repository),
          syncPollingEnabledProvider.overrideWithValue(false),
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
          appUpdateControllerProvider.overrideWith(
            () => _StaticAppUpdateController(
              AppUpdateState(
                status: AppUpdateStatus.available,
                currentVersionName: '1.0.0',
                currentVersionCode: 1,
                availableManifest: AppUpdateManifest.fromJson(
                  {
                    'versionName': '1.0.1',
                    'versionCode': 2,
                    'apkUrl':
                        'https://updates.delcod.app/DelCod-2.apk',
                  },
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 1000)),
            child: ReadingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova versao disponivel'), findsNothing);
  });

}

ReadingItem _buildItem({
  required String id,
  required String lot,
  required String warehouseCode,
  required String companyName,
  String source = 'manual',
}) {
  return ReadingItem(
    id: id,
    code: lot,
    source: source,
    updatedAt: DateTime.parse('2026-03-25T22:40:00Z'),
    deletedAt: null,
    deviceId: 'test-device',
    metadataPayload: {
      'warehouse_code': warehouseCode,
      'warehouse_company': companyName,
      'bobbin_lot': lot,
    },
  );
}

class _StaticReadingsRepository implements ReadingsRepository {
  const _StaticReadingsRepository({
    required this.items,
  });

  final List<ReadingItem> items;

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkOnlineStatus() async => true;

  @override
  Future<void> clearAll() async {}

  @override
  void dispose() {}

  @override
  Future<bool> existsCode(
    String code, {
    String? excludingId,
  }) async {
    return false;
  }

  @override
  Future<List<ReadingItem>> fetchActive() async => items;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> syncNow() async {}

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {}

  @override
  Stream<List<ReadingItem>> watchActive() => Stream.value(items);

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}

class _StaticAppUpdateController extends AppUpdateController {
  _StaticAppUpdateController(this._state);

  final AppUpdateState _state;

  @override
  AppUpdateState build() => _state;
}
