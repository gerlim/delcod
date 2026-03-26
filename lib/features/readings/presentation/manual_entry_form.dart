import 'package:flutter/material.dart';

class ManualEntryForm extends StatefulWidget {
  const ManualEntryForm({
    super.key,
    required this.onSubmit,
  });

  final ValueChanged<String> onSubmit;

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
        labelText: 'Codigo',
      ),
      onSubmitted: (_) => _submit(),
    );

    return Flex(
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
    );
  }
}
