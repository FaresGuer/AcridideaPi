import 'package:flutter/material.dart';
import '../../app_colors.dart';

class DeviceControlsScreen extends StatefulWidget {
  const DeviceControlsScreen({Key? key}) : super(key: key);

  @override
  State<DeviceControlsScreen> createState() => _DeviceControlsScreenState();
}

class _DeviceControlsScreenState extends State<DeviceControlsScreen> {
  bool _ventilationActive = false;
  bool _humidifierActive = false;
  bool _heatingActive = false;

  double _tempThreshold = 28;
  double _humidityThreshold = 65;
  double _aqiThreshold = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Device Controls'),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manual Controls Section
            Text(
              'Manual Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),

            // Ventilation Toggle
            _ControlCard(
              icon: Icons.wind_power_outlined,
              title: 'Ventilation System',
              subtitle: 'Air circulation control',
              isActive: _ventilationActive,
              onToggle: (value) {
                setState(() => _ventilationActive = value);
              },
            ),
            SizedBox(height: 12),

            // Humidifier Toggle
            _ControlCard(
              icon: Icons.water_drop_outlined,
              title: 'Humidifier',
              subtitle: 'Moisture regulation',
              isActive: _humidifierActive,
              onToggle: (value) {
                setState(() => _humidifierActive = value);
              },
            ),
            SizedBox(height: 12),

            // Heating Element Toggle
            _ControlCard(
              icon: Icons.local_fire_department_outlined,
              title: 'Heating Element',
              subtitle: 'Temperature control',
              isActive: _heatingActive,
              onToggle: (value) {
                setState(() => _heatingActive = value);
              },
            ),
            SizedBox(height: 32),

            // Sensor Thresholds Section
            Text(
              'Sensor Thresholds',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Temperature Threshold
            _ThresholdCard(
              label: 'Temperature Threshold',
              value: _tempThreshold,
              unit: '°C',
              icon: Icons.thermostat_outlined,
              min: 15,
              max: 35,
              onChanged: (value) {
                setState(() => _tempThreshold = value);
              },
            ),
            SizedBox(height: 20),

            // Humidity Threshold
            _ThresholdCard(
              label: 'Humidity Threshold',
              value: _humidityThreshold,
              unit: '%',
              icon: Icons.opacity_outlined,
              min: 30,
              max: 90,
              onChanged: (value) {
                setState(() => _humidityThreshold = value);
              },
            ),
            SizedBox(height: 20),

            // AQI Threshold
            _ThresholdCard(
              label: 'Air Quality Index Threshold',
              value: _aqiThreshold,
              unit: 'AQI',
              icon: Icons.air_outlined,
              min: 0,
              max: 500,
              onChanged: (value) {
                setState(() => _aqiThreshold = value);
              },
            ),
            SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings saved successfully!')),
                  );
                },
                child: Text('Save Changes'),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _ControlCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textHint,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: onToggle,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ThresholdCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey.shade300,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.toInt()} $unit', style: Theme.of(context).textTheme.labelSmall),
                Text('${max.toInt()} $unit', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
