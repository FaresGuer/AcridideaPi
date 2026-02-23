import 'package:flutter/material.dart';
import '../../app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Monitoring System for Locust'),
        elevation: 0.5,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greenhouse Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Greenhouse A', style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('All Systems Safe', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_circle, color: AppColors.success, size: 32),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Live Camera Preview
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Live Camera', style: Theme.of(context).textTheme.titleLarge),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Streaming',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/locust_camera.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ViewfinderPainter(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Cam 01 - Nursery Zone',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Sensor Readings
            Text('Real-Time Gauges', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),

            _ReadingGaugeCard(
              icon: Icons.thermostat_outlined,
              iconColor: AppColors.primary,
              label: 'Temperature',
              value: 28.5,
              unit: '°C',
              min: 10,
              max: 40,
              safeMin: 22,
              safeMax: 30,
            ),
            SizedBox(height: 12),

            _ReadingGaugeCard(
              icon: Icons.opacity_outlined,
              iconColor: AppColors.secondary,
              label: 'Humidity',
              value: 65,
              unit: '%',
              min: 20,
              max: 90,
              safeMin: 55,
              safeMax: 70,
            ),
            SizedBox(height: 12),

            _ReadingGaugeCard(
              icon: Icons.air_outlined,
              iconColor: AppColors.primary,
              label: 'Air Quality',
              value: 120,
              unit: 'AQI',
              min: 0,
              max: 200,
              safeMin: 0,
              safeMax: 80,
            ),
            SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),

            // Action Buttons Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.wind_power_outlined,
                  label: 'Ventilation',
                  onPressed: () {},
                ),
                _QuickActionButton(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidifier',
                  onPressed: () {},
                ),
                _QuickActionButton(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Heating',
                  onPressed: () {},
                ),
                _QuickActionButton(
                  icon: Icons.power_settings_new,
                  label: 'All Off',
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingGaugeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final double safeMin;
  final double safeMax;

  const _ReadingGaugeCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.safeMin,
    required this.safeMax,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max);
    final percent = (clampedValue - min) / (max - min);
    final isSafe = value >= safeMin && value <= safeMax;
    final gaugeColor = isSafe ? AppColors.success : AppColors.error;
    final statusLabel = isSafe ? 'Safe' : 'Not Safe';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 4),
                      Text('${value.toStringAsFixed(1)} $unit', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gaugeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: gaugeColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: CustomPaint(
                painter: _GaugePainter(
                  percent: percent,
                  color: gaugeColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: gaugeColor,
                            ),
                      ),
                      Text(
                        unit,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;

  _GaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweep = (percent.clamp(0.0, 1.0)) * 2 * 3.14159265359;
    final startAngle = -3.14159265359 / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), gridPaint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), gridPaint);

    final corner = 18.0;
    canvas.drawLine(Offset(12, 12), Offset(12 + corner, 12), paint);
    canvas.drawLine(Offset(12, 12), Offset(12, 12 + corner), paint);

    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12 - corner, 12), paint);
    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12, 12 + corner), paint);

    canvas.drawLine(Offset(12, size.height - 12), Offset(12 + corner, size.height - 12), paint);
    canvas.drawLine(Offset(12, size.height - 12), Offset(12, size.height - 12 - corner), paint);

    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12 - corner, size.height - 12), paint);
    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12, size.height - 12 - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
