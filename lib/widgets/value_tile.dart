import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ValueTile extends StatelessWidget {
  const ValueTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.accentCyan,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCardWithColor(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
