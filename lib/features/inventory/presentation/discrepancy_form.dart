import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:flutter/material.dart';

class DiscrepancyForm extends StatefulWidget {
  const DiscrepancyForm({
    super.key,
    required this.onSubmit,
  });

  final void Function(Set<InventoryDiscrepancyField> fields, String? note)
      onSubmit;

  @override
  State<DiscrepancyForm> createState() => _DiscrepancyFormState();
}

class _DiscrepancyFormState extends State<DiscrepancyForm> {
  final Set<InventoryDiscrepancyField> _selected =
      <InventoryDiscrepancyField>{};
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campos divergentes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...InventoryDiscrepancyField.values.map(
          (field) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(field.label),
            value: _selected.contains(field),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selected.add(field);
                } else {
                  _selected.remove(field);
                }
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observacao opcional',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => widget.onSubmit(
            Set.unmodifiable(_selected),
            _noteController.text,
          ),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar divergencia'),
        ),
      ],
    );
  }
}
