import 'package:flutter/material.dart';

/// Shows a confirmation dialog before deleting an item.
/// Returns [true] if the user confirms the deletion, [false] or [null] otherwise.
Future<bool?> showDeleteConfirmDialog(
  BuildContext context, {
  required String name,
  required String type,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 8),
          const Text('Confirmer la suppression'),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            const TextSpan(text: 'Supprimer '),
            TextSpan(text: type, style: const TextStyle(fontWeight: FontWeight.w500)),
            const TextSpan(text: ' '),
            TextSpan(
              text: '"$name"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' ?\n\nCette action est '),
            const TextSpan(
              text: 'irréversible',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
