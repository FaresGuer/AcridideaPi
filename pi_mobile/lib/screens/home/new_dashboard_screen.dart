import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/container_service.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _containerData;
  bool _isLoading = true;
  String _lastUpdated = 'Loading...';
  int? _currentContainerId;

  @override
  void initState() {
    super.initState();
    _loadContainerData();
  }

  Future<void> _loadContainerData() async {
    final selectedContainer = ContainerService.selectedContainer.value;
    if (selectedContainer == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Check if we need to reload (different container selected)
    if (_currentContainerId == selectedContainer.id && _containerData != null) {
      return; // Already loaded this container's data
    }

    setState(() {
      _isLoading = true;
      _currentContainerId = selectedContainer.id;
    });

    try {
      final data = await AuthService.fetchContainerData(containerId: selectedContainer.id);
      if (!mounted) return;

      final now = DateTime.now();
      final lastUpdate = data['last_updated'] != null
          ? DateTime.parse(data['last_updated'] as String)
          : now;
      final diff = now.difference(lastUpdate);

      String timeAgo;
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }

      setState(() {
        _containerData = data;
        _lastUpdated = timeAgo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ContainerService.selectedContainer,
      builder: (context, container, child) {
        // Reload data when container changes
        if (container != null && _currentContainerId != container.id) {
          Future.microtask(() => _loadContainerData());
        }

        return Scaffold(
          // backgroundColor: AppColors.mintBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC8E6C9), // Darker Mint (Green 100) on top left
                  Colors.white,      // Fades to White (lighter)
                ],
                stops: [0.0, 0.7],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSystemStatusCard(),
                          SizedBox(height: 24),
                          _buildLiveCameraCard(),
                          SizedBox(height: 24),
                          _buildEnvironmentSection(),
                          SizedBox(height: 24),
                          _buildEnvironmentalCharts(),
                          SizedBox(height: 24),
                          _buildAlertsSection(),
                          SizedBox(height: 80), // Bottom spacer for FAB
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsSection() {
    final temp = (_containerData?['temperature'] as num?)?.toDouble() ?? 0.0;
    final hum = (_containerData?['humidity'] as num?)?.toDouble() ?? 0.0;
    final containerName = ContainerService.selectedContainer.value?.name ?? 'Container';

    // Generate dynamic alerts based on real data
    final alerts = <Map<String, dynamic>>[];

    if (temp > 35) {
      alerts.add({
        'title': 'Critical Temperature',
        'desc': '$containerName temperature: ${temp.toStringAsFixed(1)}°C',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.thermostat,
      });
    } else if (temp > 28) {
      alerts.add({
        'title': 'High Temperature',
        'desc': '$containerName temperature: ${temp.toStringAsFixed(1)}°C',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.thermostat,
      });
    }

    if (hum > 85) {
      alerts.add({
        'title': 'Critical Humidity',
        'desc': '$containerName humidity > 85%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.water_drop,
      });
    } else if (hum > 70) {
      alerts.add({
        'title': 'High Humidity',
        'desc': '$containerName humidity: ${hum.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.water_drop,
      });
    } else if (hum < 30) {
      alerts.add({
        'title': 'Low Humidity',
        'desc': '$containerName humidity: ${hum.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.water_drop,
      });
    }

    // Add success alert if all is good
    if (alerts.isEmpty) {
      alerts.add({
        'title': 'System Check',
        'desc': 'All sensors nominal for $containerName',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'success',
        'icon': Icons.check_circle,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts & Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                // Add filter or view all logic
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: alerts.length,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 64, endIndent: 24, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getAlertColor(alert['type'] as String).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                alert['icon'] as IconData,
                                color: _getAlertColor(alert['type'] as String),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        alert['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        alert['time'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    alert['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              SizedBox(width: 16),
                              Text('Generating Report...'),
                            ],
                          ),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // Simulate report generation
                      Future.delayed(Duration(seconds: 2), () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report Downloaded Successfully'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      });
                    },
                    icon: Icon(Icons.download_rounded, size: 20),
                    label: Text('Generate Full Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Dark/Modern Look
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'warning': return Colors.orange;
      case 'critical': return AppColors.liveRed;
      case 'success': return AppColors.success;
      case 'info': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOCUST FARM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                ContainerService.selectedContainer.value?.name ?? 'Container',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          _buildNotificationBell(),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    final user = AuthService.currentUser.value;

    return FutureBuilder<int>(
      future: _fetchPendingInvitationCount(user?.role),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _fetchPendingInvitationCount(String? role) async {
    if (role != 'FARMER') {
      return 0;
    }

    try {
      final invitations = await AuthService.fetchReceivedInvitations();
      return invitations.where((inv) => inv.status == 'PENDING').length;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mintBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'All metrics nominal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mintBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ONLINE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nursery Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.liveRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/locust_camera.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Grid overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CAM-01 • 1080p',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fullscreen, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentSection() {
    final temp = (_containerData?['temperature'] as num?)?.toDouble() ?? 0.0;
    final hum = (_containerData?['humidity'] as num?)?.toDouble() ?? 0.0;
    final tempProgress = temp / 50.0; // Assuming max temp 50°C
    final humProgress = hum / 100.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Environment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              _isLoading ? 'Loading...' : 'Updated $_lastUpdated',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.thermostat,
                iconColor: AppColors.temperature,
                label: 'Temperature',
                value: _isLoading ? '--' : temp.toStringAsFixed(1),
                unit: '°C',
                progress: tempProgress.clamp(0.0, 1.0),
                progressColor: AppColors.temperature,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop,
                iconColor: AppColors.humidity,
                label: 'Humidity',
                value: _isLoading ? '--' : hum.toStringAsFixed(0),
                unit: '%',
                progress: humProgress.clamp(0.0, 1.0),
                progressColor: AppColors.humidity,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildAirQualityCard(),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                'SAFE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mintBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Air Quality',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          '120',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AQI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.liveRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'WARNING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.liveRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFA5D6A7), // Soft Green/Mint
                    Color(0xFFFFCC80), // Soft Orange/Peach
                    Color(0xFFEF9A9A)  // Soft Red/Pink
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                   Align(
                      alignment: Alignment(-0.2, 0), // Position for ~120 AQI (visual approximation)
                      child: Container(
                        width: 4,
                        height: 6,
                        decoration: BoxDecoration(
                           color: Colors.white,
                           border: Border.all(color: Colors.black, width: 1),
                           borderRadius: BorderRadius.circular(2),
                        ),
                      )
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ventilation Needed',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                'Moderate',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalCharts() {
    final temp = (_containerData?['temperature'] as num?)?.toDouble() ?? 0.0;
    final hum = (_containerData?['humidity'] as num?)?.toDouble() ?? 0.0;
    final light = (_containerData?['light_level'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Environmental History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Temperature',
          icon: Icons.thermostat,
          iconColor: AppColors.temperature,
          unit: '°C',
          currentValue: _isLoading ? '--' : temp.toStringAsFixed(1),
          chartColor: AppColors.temperature,
          dataPoints: _getTemperatureData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Humidity',
          icon: Icons.water_drop,
          iconColor: AppColors.humidity,
          unit: '%',
          currentValue: _isLoading ? '--' : hum.toStringAsFixed(0),
          chartColor: AppColors.humidity,
          dataPoints: _getHumidityData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Air Quality (AQI)',
          icon: Icons.air,
          iconColor: AppColors.primary,
          unit: 'AQI',
          currentValue: _isLoading ? '--' : '120',
          chartColor: AppColors.primary,
          dataPoints: _getAirQualityData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'CO₂ Level',
          icon: Icons.cloud,
          iconColor: Colors.purple,
          unit: 'ppm',
          currentValue: _isLoading ? '--' : '450',
          chartColor: Colors.purple,
          dataPoints: _getCO2Data(),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String unit,
    required String currentValue,
    required Color chartColor,
    required List<double> dataPoints,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          currentValue,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+2.5%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: LineChartPainter(
                dataPoints: dataPoints,
                lineColor: chartColor,
                fillColor: chartColor.withOpacity(0.1),
              ),
              child: Container(),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('04:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('08:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('12:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('16:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('20:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('24:00', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // Dynamic data for temperature (in °C) based on container ID
  List<double> _getTemperatureData() {
    final containerId = _currentContainerId ?? 1;
    final baseTemp = (_containerData?['temperature'] as num?)?.toDouble() ?? 25.0;
    final seed = containerId * 17; // Use container ID as seed

    return List.generate(7, (i) {
      final variance = ((seed + i * 13) % 10 - 5) / 2.0; // -2.5 to +2.5
      return (baseTemp + variance).clamp(20.0, 40.0);
    });
  }

  // Dynamic data for humidity (in %) based on container ID
  List<double> _getHumidityData() {
    final containerId = _currentContainerId ?? 1;
    final baseHum = (_containerData?['humidity'] as num?)?.toDouble() ?? 60.0;
    final seed = containerId * 23;

    return List.generate(7, (i) {
      final variance = ((seed + i * 19) % 20 - 10) / 2.0; // -5 to +5
      return (baseHum + variance).clamp(30.0, 90.0);
    });
  }

  // Dynamic data for air quality (AQI) based on container ID
  List<double> _getAirQualityData() {
    final containerId = _currentContainerId ?? 1;
    final seed = containerId * 31;

    return List.generate(7, (i) {
      final base = 100 + (seed % 30);
      final variance = ((seed + i * 11) % 30 - 15).toDouble();
      return (base + variance).clamp(80.0, 200.0);
    });
  }

  // Dynamic data for CO2 (in ppm) based on container ID
  List<double> _getCO2Data() {
    final containerId = _currentContainerId ?? 1;
    final seed = containerId * 41;

    return List.generate(7, (i) {
      final base = 400 + (seed % 100);
      final variance = ((seed + i * 7) % 80 - 40).toDouble();
      return (base + variance).clamp(350.0, 600.0);
    });
  }



}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Find min and max for scaling
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points for the line
    final points = <Offset>[];
    final segmentWidth = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * segmentWidth;
      final normalizedValue = range > 0 ? (dataPoints[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    // Draw fill area
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final prevPoint = points[i - 1];
      final currentPoint = points[i];

      // Create smooth curve using quadratic bezier
      final controlPointX = (prevPoint.dx + currentPoint.dx) / 2;
      linePath.quadraticBezierTo(
        controlPointX, prevPoint.dy,
        controlPointX, (prevPoint.dy + currentPoint.dy) / 2,
      );
      linePath.quadraticBezierTo(
        controlPointX, currentPoint.dy,
        currentPoint.dx, currentPoint.dy,
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Draw data point circles
    final circlePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 5, borderPaint);
      canvas.drawCircle(point, 4, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}









