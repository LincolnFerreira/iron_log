import 'package:flutter/material.dart';

/// Diálogo da primeira academia: o nome e se as máquinas sem lugar entram nela.
class GymAttachSheet extends StatefulWidget {
  const GymAttachSheet({super.key, required this.nameController});

  final TextEditingController nameController;

  @override
  State<GymAttachSheet> createState() => _GymAttachSheetState();
}

class _GymAttachSheetState extends State<GymAttachSheet> {
  var _attach = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Academia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nome do lugar'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _attach,
            onChanged: (value) => setState(() => _attach = value ?? true),
            title: const Text('Levar as máquinas que ainda não têm lugar'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _attach),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
