import 'package:flutter/material.dart';

class ChildNameDialog extends StatefulWidget {
  final String initialName;
  final bool canCancel;

  const ChildNameDialog({
    super.key,
    this.initialName = '',
    this.canCancel = false,
  });

  @override
  State<ChildNameDialog> createState() => _ChildNameDialogState();
}

class _ChildNameDialogState extends State<ChildNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Escribe un nombre.';
      });
      return;
    }

    if (name.length > 24) {
      setState(() {
        _errorText = 'Máximo 24 caracteres.';
      });
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nombre del niño/a'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escribe el nombre para personalizar la app.',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ejemplo: Lucía',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _save(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        if (widget.canCancel)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
