import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
  });

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados importados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _field('Empresa', item.companyName),
          _field('Codigo', item.bobbinCode),
          _field('Descricao', item.itemDescription),
          _field('Codigo de barras', item.barcode),
          _field('Peso', item.weight),
          _field('Armazem', item.warehouse),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(value.isEmpty ? 'Nao informado' : value),
        ],
      ),
    );
  }
}
