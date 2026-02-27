import 'package:flutter/material.dart';

/// A read-only row that shows a label + value with an optional edit pencil icon.
/// Used in all detail pages.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onEdit;
  final bool isMultiline;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onEdit,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.indigo.shade400;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment:
              isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : '—',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value.isNotEmpty
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: color),
                tooltip: 'Modifier',
                onPressed: onEdit,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section title for detail pages
class DetailSection extends StatelessWidget {
  final String title;
  const DetailSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
