import 'package:flutter/material.dart';

class ManualEntryForm extends StatefulWidget {
  const ManualEntryForm({
    super.key,
    required this.onSubmit,
    required this.selectedWarehouseCode,
    required this.onWarehouseChanged,
    required this.warehouseOptions,
    required this.companyPreview,
  });

  final ValueChanged<String> onSubmit;
  final String? selectedWarehouseCode;
  final ValueChanged<String?> onWarehouseChanged;
  final List<DropdownMenuItem<String?>> warehouseOptions;
  final String? companyPreview;

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }

    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final input = TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Lote de Bobina',
      ),
      onSubmitted: (_) => _submit(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact) input else Expanded(child: input),
            SizedBox(width: compact ? 0 : 12, height: compact ? 12 : 0),
            FilledButton(
              onPressed: _submit,
              child: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: widget.selectedWarehouseCode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Armazem',
          ),
          items: widget.warehouseOptions,
          onChanged: widget.onWarehouseChanged,
        ),
        const SizedBox(height: 10),
        Text(
          widget.companyPreview == null
              ? 'Sem armazem selecionado, o lote entra como pendente.'
              : 'Empresa derivada: ${widget.companyPreview}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.companyPreview == null
                    ? const Color(0xFFC53030)
                    : const Color(0xFF0F766E),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
