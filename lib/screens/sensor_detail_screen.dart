import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_info.dart';
import '../providers/monitoring_provider.dart';
import '../theme/app_theme.dart';

class SensorDetailScreen extends StatelessWidget {
  const SensorDetailScreen({
    required this.sensor,
    required this.accentColor,
    super.key,
  });

  final SensorInfo sensor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sensor.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCardWithColor(accentColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  sensor.purpose,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Consumer<MonitoringProvider>(
            builder: (context, monitor, _) {
              final isCollecting = monitor.isSensorActive(sensor.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCardWithColor(
                  isCollecting ? accentColor : AppTheme.textMuted,
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isCollecting,
                  onChanged: (value) {
                    monitor.setSensorActive(sensor.id, value);
                  },
                  title: const Text('Collect this sensor individually'),
                  subtitle: Text(
                    isCollecting
                        ? 'Enabled in the live monitoring dashboard.'
                        : 'Paused for collection. At least one sensor must stay enabled.',
                  ),
                ),
              );
            },
          ),
          _InfoSection(
            title: 'Sampling Rate',
            child: Text(
              sensor.samplingRate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _InfoSection(
            title: 'Measurement',
            child: Text(
              '${sensor.unit} • ${sensor.range}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          _InfoSection(
            title: 'Features',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final feature in sensor.features)
                  Chip(
                    label: Text(feature),
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          _InfoSection(
            title: 'Role in System',
            child: Text(
              sensor.role,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
