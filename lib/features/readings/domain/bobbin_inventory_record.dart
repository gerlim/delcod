import 'package:barcode_app/features/readings/data/readings_repository.dart';

class WarehouseOption {
  const WarehouseOption({
    required this.code,
    required this.companyName,
  });

  final String code;
  final String companyName;

  String get label => '$code · $companyName';
}

class BobbinInventoryRecord {
  const BobbinInventoryRecord({
    required this.lot,
    required this.warehouseCode,
    required this.companyName,
  });

  static const List<WarehouseOption> warehouseOptions = <WarehouseOption>[
    WarehouseOption(code: '05', companyName: 'Bora Embalagens'),
    WarehouseOption(code: 'PPI', companyName: 'Bora Embalagens'),
    WarehouseOption(code: '04', companyName: 'ABN Embalagens'),
    WarehouseOption(code: 'GLR', companyName: 'ABN Embalagens'),
  ];

  final String lot;
  final String? warehouseCode;
  final String? companyName;

  bool get hasWarehouseAllocated =>
      warehouseCode != null && warehouseCode!.trim().isNotEmpty;

  bool get isComplete => hasWarehouseAllocated && companyName != null;

  String get warehouseLabel => warehouseCode ?? 'Nao informado';

  String get companyLabel => companyName ?? 'Pendente';

  String get statusLabel {
    if (!hasWarehouseAllocated) {
      return 'Sem armazem alocado';
    }
    if (companyName == null) {
      return 'Armazem nao mapeado';
    }
    return 'Completo';
  }

  static BobbinInventoryRecord fromItem(ReadingItem item) {
    final metadata = item.metadataPayload ?? const <String, dynamic>{};
    final lot = (metadata['bobbin_lot'] as String?)?.trim();
    final warehouseCode = normalizeWarehouseCode(
      metadata['warehouse_code'] as String?,
    );
    final storedCompanyName = (metadata['warehouse_company'] as String?)?.trim();
    final companyName = warehouseCode == null
        ? null
        : storedCompanyName != null && storedCompanyName.isNotEmpty
            ? storedCompanyName
            : deriveCompanyName(warehouseCode);

    return BobbinInventoryRecord(
      lot: (lot != null && lot.isNotEmpty) ? lot : item.code,
      warehouseCode: warehouseCode,
      companyName: companyName,
    );
  }

  static Map<String, dynamic> buildMetadata({
    required String lot,
    String? warehouseCode,
    Map<String, dynamic>? seed,
  }) {
    final metadata = Map<String, dynamic>.from(seed ?? const <String, dynamic>{});
    final normalizedWarehouseCode = normalizeWarehouseCode(warehouseCode);

    metadata['bobbin_lot'] = lot.trim();
    if (normalizedWarehouseCode == null) {
      metadata.remove('warehouse_code');
      metadata.remove('warehouse_company');
      return metadata;
    }

    metadata['warehouse_code'] = normalizedWarehouseCode;
    final companyName = deriveCompanyName(normalizedWarehouseCode);
    if (companyName == null) {
      metadata.remove('warehouse_company');
    } else {
      metadata['warehouse_company'] = companyName;
    }
    return metadata;
  }

  static String? normalizeWarehouseCode(String? rawValue) {
    final normalized = rawValue?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static String? deriveCompanyName(String? warehouseCode) {
    final normalizedCode = normalizeWarehouseCode(warehouseCode);
    if (normalizedCode == null) {
      return null;
    }

    for (final option in warehouseOptions) {
      if (option.code == normalizedCode) {
        return option.companyName;
      }
    }

    return null;
  }
}
