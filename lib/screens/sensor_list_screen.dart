import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_info.dart';
import '../providers/monitoring_provider.dart';
import '../services/sensor_info_service.dart';
import '../theme/app_theme.dart';
import 'sensor_detail_screen.dart';

class SensorListScreen extends StatelessWidget {
  const SensorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitoringProvider>(
      builder: (context, monitor, _) {
        return FutureBuilder<List<SensorInfo>>(
          future: SensorInfoService().loadSensors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load sensors: ${snapshot.error}'),
              );
            }

            final sensors = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Sensor Collection',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose individual sensors for collection, or tap a sensor to view its technical role and features.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < sensors.length; i++)
                  _SensorCard(
                    sensor: sensors[i],
                    color:
                        AppTheme.sensorColors[i % AppTheme.sensorColors.length],
                    isCollecting: monitor.isSensorActive(sensors[i].id),
                    onCollectChanged: (value) {
                      monitor.setSensorActive(sensors[i].id, value);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.sensor,
    required this.color,
    required this.isCollecting,
    required this.onCollectChanged,
  });

  final SensorInfo sensor;
  final Color color;
  final bool isCollecting;
  final ValueChanged<bool> onCollectChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardWithColor(
        isCollecting ? color : AppTheme.textMuted,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: isCollecting ? 0.18 : 0.08),
          child: Icon(
            _iconFor(sensor.icon),
            color: isCollecting ? color : AppTheme.textMuted,
          ),
        ),
        title: Text(
          sensor.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          isCollecting
              ? 'Collecting • ${sensor.samplingRate} • ${sensor.unit}'
              : 'Paused • ${sensor.samplingRate} • ${sensor.unit}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: isCollecting, onChanged: onCollectChanged),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SensorDetailScreen(sensor: sensor, accentColor: color),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String icon) {
    return switch (icon) {
      'vibration' => Icons.graphic_eq,
      'mic' => Icons.mic,
      'air' => Icons.air,
      'compress' => Icons.compress,
      '3d_rotation' => Icons.threed_rotation,
      'thermostat' => Icons.thermostat,
      _ => Icons.sensors,
    };
  }
}
