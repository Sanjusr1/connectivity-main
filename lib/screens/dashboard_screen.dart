import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_connection_config.dart';
import '../models/sensor_data.dart';
import '../providers/monitoring_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_line_chart.dart';
import '../widgets/value_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MonitoringProvider>(
      builder: (context, monitor, _) {
        final data = monitor.latest;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Live Monitoring',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your sensor hub over Wi-Fi or USB to ingest real readings and store each sample locally or in the cloud.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _ConnectionSettings(monitor: monitor),
            const SizedBox(height: 16),
            _Controls(monitor: monitor),
            const SizedBox(height: 16),
            _SensorCollectionSelector(monitor: monitor),
            const SizedBox(height: 16),
            _SpeechBanner(isDetected: monitor.speechDetected),
            const SizedBox(height: 16),
            _LiveValues(data: data, monitor: monitor),
            const SizedBox(height: 16),
            _CollectionStatus(monitor: monitor),
            const SizedBox(height: 16),
            _StorageOptions(monitor: monitor),
            const SizedBox(height: 16),
            _CollectedDataFeed(monitor: monitor),
            const SizedBox(height: 16),
            SensorLineChart(
              title: 'Vibration RMS vs Time',
              history: monitor.isSensorActive('piezo_vibration')
                  ? monitor.history
                  : const [],
              series: const [
                ChartSeries(
                  label: 'RMS',
                  color: AppTheme.accentPink,
                  valueBuilder: _vibrationValue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SensorLineChart(
              title: 'Airflow vs Time',
              history: monitor.isSensorActive('airflow_sensor')
                  ? monitor.history
                  : const [],
              series: const [
                ChartSeries(
                  label: 'Airflow',
                  color: AppTheme.accentCyan,
                  valueBuilder: _airflowValue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SensorLineChart(
              title: 'IMU X/Y/Z',
              history: monitor.isSensorActive('imu_sensor')
                  ? monitor.history
                  : const [],
              series: const [
                ChartSeries(
                  label: 'X',
                  color: AppTheme.accentOrange,
                  valueBuilder: _imuXValue,
                ),
                ChartSeries(
                  label: 'Y',
                  color: AppTheme.accentGreen,
                  valueBuilder: _imuYValue,
                ),
                ChartSeries(
                  label: 'Z',
                  color: AppTheme.accentPurple,
                  valueBuilder: _imuZValue,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

double _vibrationValue(SensorData data) => data.vibrationRms;
double _airflowValue(SensorData data) => data.airflow;
double _imuXValue(SensorData data) => data.imuX;
double _imuYValue(SensorData data) => data.imuY;
double _imuZValue(SensorData data) => data.imuZ;

class _Controls extends StatelessWidget {
  const _Controls({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    final canStart =
        monitor.connectionConfig.connectionType != SensorConnectionType.none;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: monitor.isMonitoring
                  ? monitor.stopMonitoring
                  : (canStart ? monitor.startMonitoring : null),
              icon: Icon(monitor.isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(
                monitor.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: monitor.resetSession,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset session',
          ),
        ],
      ),
    );
  }
}

class _SpeechBanner extends StatelessWidget {
  const _SpeechBanner({required this.isDetected});

  final bool isDetected;

  @override
  Widget build(BuildContext context) {
    final color = isDetected ? AppTheme.successGreen : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardWithColor(color),
      child: Row(
        children: [
          Icon(
            isDetected ? Icons.record_voice_over : Icons.hearing_disabled,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            isDetected ? 'Speech Detected' : 'Waiting for airflow threshold',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SensorCollectionSelector extends StatelessWidget {
  const _SensorCollectionSelector({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Individual Sensor Collection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Select exactly which sensor streams should be included in the current data collection session.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in MonitoringProvider.sensorLabels.entries)
                FilterChip(
                  selected: monitor.isSensorActive(entry.key),
                  label: Text(entry.value),
                  onSelected: (value) {
                    monitor.setSensorActive(entry.key, value);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveValues extends StatelessWidget {
  const _LiveValues({required this.data, required this.monitor});

  final SensorData? data;
  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        if (monitor.isSensorActive('temp_humidity')) ...[
          ValueTile(
            label: 'Temperature',
            value: _format(data?.temperature, '°C'),
            icon: Icons.thermostat,
            color: AppTheme.accentOrange,
          ),
          ValueTile(
            label: 'Humidity',
            value: _format(data?.humidity, '%'),
            icon: Icons.water_drop,
            color: AppTheme.accentBlue,
          ),
        ],
        if (monitor.isSensorActive('airflow_sensor'))
          ValueTile(
            label: 'Airflow',
            value: _format(data?.airflow, 'm/s'),
            icon: Icons.air,
            color: AppTheme.accentCyan,
          ),
        if (monitor.isSensorActive('pressure_sensor'))
          ValueTile(
            label: 'Pressure',
            value: _format(data?.pressure, 'Pa'),
            icon: Icons.compress,
            color: AppTheme.accentTeal,
          ),
        if (monitor.isSensorActive('piezo_vibration'))
          ValueTile(
            label: 'Vibration RMS',
            value: _format(data?.vibrationRms, 'RMS'),
            icon: Icons.graphic_eq,
            color: AppTheme.accentPink,
          ),
        if (monitor.isSensorActive('imu_sensor'))
          ValueTile(
            label: 'IMU (X, Y, Z)',
            value: data == null
                ? '--'
                : '${data!.imuX.toStringAsFixed(2)}, ${data!.imuY.toStringAsFixed(2)}, ${data!.imuZ.toStringAsFixed(2)}',
            icon: Icons.threed_rotation,
            color: AppTheme.accentPurple,
          ),
        if (monitor.isSensorActive('mems_microphone'))
          ValueTile(
            label: 'Microphone',
            value: _format(data?.microphoneLevel, 'dB'),
            icon: Icons.mic,
            color: AppTheme.accentGreen,
          ),
      ],
    );
  }

  String _format(double? value, String unit) {
    if (value == null) {
      return '--';
    }
    return '${value.toStringAsFixed(2)} $unit';
  }
}

class _ConnectionSettings extends StatelessWidget {
  const _ConnectionSettings({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    final config = monitor.connectionConfig;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Connection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Expected framing: one packet per line over TCP or USB. JSON, text, CSV, and binary packets are preserved as raw data.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 8),
            Text(
              'Chrome can read USB serial devices after you choose a port. Use a newline-delimited stream for the smoothest ingestion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          SegmentedButton<SensorConnectionType>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(
                value: SensorConnectionType.wifi,
                icon: Icon(Icons.wifi),
                label: Text('Wi-Fi'),
              ),
              ButtonSegment(
                value: SensorConnectionType.usb,
                icon: Icon(Icons.usb),
                label: Text('USB'),
              ),
              ButtonSegment(
                value: SensorConnectionType.mock,
                icon: Icon(Icons.science_outlined),
                label: Text('Mock'),
              ),
            ],
            selected: config.connectionType == SensorConnectionType.none
                ? const <SensorConnectionType>{}
                : <SensorConnectionType>{config.connectionType},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                monitor.setConnectionType(SensorConnectionType.none);
                return;
              }
              monitor.setConnectionType(selection.first);
            },
          ),
          if (config.connectionType == SensorConnectionType.wifi) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: config.wifiHost,
              keyboardType: TextInputType.url,
              onChanged: monitor.setWifiHost,
              decoration: const InputDecoration(
                labelText: 'Sensor hub host/IP',
                hintText: '192.168.1.10',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '${config.wifiPort}',
              keyboardType: TextInputType.number,
              onChanged: monitor.setWifiPort,
              decoration: const InputDecoration(
                labelText: 'TCP port',
                hintText: '9000',
              ),
            ),
          ] else if (config.connectionType == SensorConnectionType.usb) ...[
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Connect the sensor hub to this laptop, then start monitoring and choose the USB serial device in the browser prompt.'
                  : 'Connect the sensor hub with USB OTG. Android will listen for newline-delimited packets from the first readable USB device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '${config.usbBaudRate}',
              keyboardType: TextInputType.number,
              onChanged: monitor.setUsbBaudRate,
              decoration: const InputDecoration(
                labelText: 'USB baud rate',
                hintText: '115200',
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Mock mode stays available for UI testing when the real hub is offline.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          _StatusRow(label: 'Connection mode', value: config.connectionLabel),
          _StatusRow(label: 'Target', value: monitor.connectionSummary),
          _StatusRow(label: 'State', value: monitor.connectionState),
          if (monitor.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.glassCardWithColor(Colors.redAccent),
              child: Text(
                'Connection error: ${monitor.lastError!}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectionStatus extends StatelessWidget {
  const _CollectionStatus({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Collection Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Total frames collected',
            value: '${monitor.totalFrames}',
          ),
          _StatusRow(
            label: 'Combined sensor frames',
            value: '${monitor.combinedSensorFrames}',
          ),
          _StatusRow(
            label: 'Active sensor streams',
            value: '${monitor.activeSensorCount}',
          ),
          _StatusRow(
            label: 'Duration',
            value: _formatDuration(monitor.durationSeconds),
          ),
          _StatusRow(
            label: 'Sampling rate',
            value: '${monitor.samplingRate} frames/sec',
          ),
          const SizedBox(height: 6),
          Text(
            'Assumption: 1 frame = 10 ms.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCollectionStatusSheet(context, monitor),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View individual + combined status'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectionStatusSheet(
    BuildContext context,
    MonitoringProvider monitor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceCard,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'All Sensor Collection Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Individual stream counts are tracked separately. Combined sensor frames adds all enabled sensor streams collected during this session.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _StatusRow(
                label: 'Base timeline frames',
                value: '${monitor.totalFrames}',
              ),
              _StatusRow(
                label: 'Combined sensor frames',
                value: '${monitor.combinedSensorFrames}',
              ),
              _StatusRow(
                label: 'Duration',
                value: _formatDuration(monitor.durationSeconds),
              ),
              _StatusRow(
                label: 'Sampling rate',
                value: '${monitor.samplingRate} frames/sec',
              ),
              const SizedBox(height: 16),
              for (final entry in MonitoringProvider.sensorLabels.entries)
                _SensorStatusTile(
                  label: entry.value,
                  isActive: monitor.isSensorActive(entry.key),
                  frames: monitor.framesForSensor(entry.key),
                  samplingRate: monitor.samplingRate,
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) {
      return '$remainingSeconds sec';
    }
    return '$minutes min $remainingSeconds sec';
  }
}

class _SensorStatusTile extends StatelessWidget {
  const _SensorStatusTile({
    required this.label,
    required this.isActive,
    required this.frames,
    required this.samplingRate,
  });

  final String label;
  final bool isActive;
  final int frames;
  final int samplingRate;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.accentCyan : AppTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCardWithColor(color),
      child: Row(
        children: [
          Icon(isActive ? Icons.sensors : Icons.pause_circle, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Collecting at $samplingRate frames/sec'
                      : 'Paused',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '$frames frames',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CollectedDataFeed extends StatelessWidget {
  const _CollectedDataFeed({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    final readings = monitor.recentReadings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collected Data Stream',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Latest readings from the selected sensors.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: readings.isEmpty
                  ? null
                  : () => _showCollectedDataSheet(context, monitor),
              icon: const Icon(Icons.dataset_outlined),
              label: const Text('Open collected data details'),
            ),
          ),
          const SizedBox(height: 12),
          if (readings.isEmpty)
            Text(
              'Start monitoring to see collected data here.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final reading in readings)
              _CollectedReadingRow(reading: reading, monitor: monitor),
        ],
      ),
    );
  }

  void _showCollectedDataSheet(
    BuildContext context,
    MonitoringProvider monitor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceCard,
      builder: (context) {
        final latest = monitor.latest;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Collected Data Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This view shows the latest raw sensor reading plus the active streams currently being collected.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (latest == null)
                Text(
                  'No readings collected yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                _StatusRow(
                  label: 'Timestamp',
                  value: _formatTime(latest.timestamp),
                ),
                _StatusRow(
                  label: 'Temperature',
                  value: '${latest.temperature.toStringAsFixed(2)} C',
                ),
                _StatusRow(
                  label: 'Humidity',
                  value: '${latest.humidity.toStringAsFixed(2)}%',
                ),
                _StatusRow(
                  label: 'Airflow',
                  value: '${latest.airflow.toStringAsFixed(2)} m/s',
                ),
                _StatusRow(
                  label: 'Pressure',
                  value: '${latest.pressure.toStringAsFixed(2)} Pa',
                ),
                _StatusRow(
                  label: 'Vibration RMS',
                  value: latest.vibrationRms.toStringAsFixed(4),
                ),
                _StatusRow(
                  label: 'Microphone',
                  value: '${latest.microphoneLevel.toStringAsFixed(2)} dB',
                ),
                _StatusRow(
                  label: 'IMU X, Y, Z',
                  value:
                      '${latest.imuX.toStringAsFixed(2)}, ${latest.imuY.toStringAsFixed(2)}, ${latest.imuZ.toStringAsFixed(2)}',
                ),
                _StatusRow(label: 'Raw format', value: latest.rawFormat),
                const SizedBox(height: 16),
                Text(
                  'Raw transport payload',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(latest.rawTransportMap),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (latest.rawPacket != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Original packet line',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    latest.rawPacket!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (latest.rawBytesBase64 != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Raw bytes base64',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    latest.rawBytesBase64!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Active sensor streams',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in MonitoringProvider.sensorLabels.entries)
                      if (monitor.isSensorActive(entry.key))
                        Chip(label: Text(entry.value)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _CollectedReadingRow extends StatelessWidget {
  const _CollectedReadingRow({required this.reading, required this.monitor});

  final SensorData reading;
  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(reading.timestamp),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Raw', value: reading.rawFormat),
              if (monitor.isSensorActive('temp_humidity')) ...[
                _MetricChip(
                  label: 'Temp',
                  value: '${reading.temperature.toStringAsFixed(1)} C',
                ),
                _MetricChip(
                  label: 'Humidity',
                  value: '${reading.humidity.toStringAsFixed(1)}%',
                ),
              ],
              if (monitor.isSensorActive('airflow_sensor'))
                _MetricChip(
                  label: 'Airflow',
                  value: '${reading.airflow.toStringAsFixed(2)} m/s',
                ),
              if (monitor.isSensorActive('pressure_sensor'))
                _MetricChip(
                  label: 'Pressure',
                  value: '${reading.pressure.toStringAsFixed(1)} Pa',
                ),
              if (monitor.isSensorActive('piezo_vibration'))
                _MetricChip(
                  label: 'RMS',
                  value: reading.vibrationRms.toStringAsFixed(3),
                ),
              if (monitor.isSensorActive('imu_sensor'))
                _MetricChip(
                  label: 'IMU',
                  value:
                      '${reading.imuX.toStringAsFixed(2)}, ${reading.imuY.toStringAsFixed(2)}, ${reading.imuZ.toStringAsFixed(2)}',
                ),
              if (monitor.isSensorActive('mems_microphone'))
                _MetricChip(
                  label: 'Mic',
                  value: '${reading.microphoneLevel.toStringAsFixed(1)} dB',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppTheme.surfaceDark,
      side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.18)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StorageOptions extends StatelessWidget {
  const _StorageOptions({required this.monitor});

  final MonitoringProvider monitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage Options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: monitor.storeLocally,
            onChanged: monitor.setStoreLocally,
            title: const Text('Store Locally'),
            subtitle: const Text('Hive box: sensor_data_entries'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: monitor.storeInCloud,
            onChanged: monitor.setStoreInCloud,
            title: const Text('Store in Cloud'),
            subtitle: const Text(
              'FastAPI backend upload for each collected sample',
            ),
          ),
        ],
      ),
    );
  }
}
