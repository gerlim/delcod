import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra horario da ultima sincronizacao quando houver sucesso',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncControllerProvider.overrideWith(() => _StaticSyncController(
                SyncState(
                  status: SyncStatus.synced,
                  pendingCount: 0,
                  lastAttemptAt: DateTime(2026, 4, 24, 10, 30),
                  lastSyncedAt: DateTime(2026, 4, 24, 10, 31),
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusBanner(),
          ),
        ),
      ),
    );

    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.textContaining('Ultima sincronizacao'), findsOneWidget);
  });

  testWidgets('mostra detalhe do erro quando a sincronizacao falhar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncControllerProvider.overrideWith(() => _StaticSyncController(
                SyncState(
                  status: SyncStatus.failed,
                  pendingCount: 3,
                  lastAttemptAt: DateTime(2026, 4, 24, 10, 31),
                  lastError: 'remote timeout',
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusBanner(),
          ),
        ),
      ),
    );

    expect(find.text('Falha na sincronizacao'), findsOneWidget);
    expect(find.textContaining('remote timeout'), findsOneWidget);
  });
}

class _StaticSyncController extends SyncController {
  _StaticSyncController(this._state);

  final SyncState _state;

  @override
  SyncState build() => _state;
}
