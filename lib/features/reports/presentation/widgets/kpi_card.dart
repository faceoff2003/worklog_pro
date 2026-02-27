import 'package:flutter/material.dart';
import 'package:worklog_pro/core/value_objects/money.dart';

class KPICard extends StatelessWidget {
  final String title;
  final Money amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount.toEurosString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
