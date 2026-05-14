import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_import_page.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(platformCapabilitiesProvider);
    if (capabilities.supportsCameraScanning) {
      return const InventoryScanPage();
    }
    return const InventoryImportPage();
  }
}
