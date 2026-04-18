import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  late Timer _refreshTimer;
  bool _isGeneratingReport = false;

  // For chart data
  final List<Map<String, dynamic>> _temperatureHistory = [];
  final List<Map<String, dynamic>> _humidityHistory = [];
  final List<Map<String, dynamic>> _lightHistory = [];
  final List<Map<String, dynamic>> _gasHistory = [];
  static const int MAX_HISTORY = 30; // Keep last 30 data points

  @override
  void initState() {
    super.initState();
    _loadContainerData();
    // Reload container data every 5 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _loadContainerData();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _loadContainerData() async {
    final selectedContainer = ContainerService.selectedContainer.value;
    if (selectedContainer == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await AuthService.fetchContainerData(containerId: selectedContainer.id);
      final history = await AuthService.fetchContainerHistory(
        containerId: selectedContainer.id,
        limit: MAX_HISTORY * 4,
      );
      if (!mounted) return;

      final lastUpdate = _resolveLastUpdatedAt(data, history);
      final timeLabel = _formatTimestamp(lastUpdate);

      setState(() {
        _containerData = data;
        _lastUpdated = timeLabel;
        _isLoading = false;
        _currentContainerId = selectedContainer.id;

        _applyHistoryEntries(history);
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
    final temp = (_containerData?['temperature'] as num?)?.toDouble();
    final hum = (_containerData?['humidity'] as num?)?.toDouble();
    final light = (_containerData?['light_level'] as num?)?.toDouble();
    final gas = (_containerData?['gas_level'] as num?)?.toDouble();

    final tempMin = (_containerData?['target_temperature_min'] as num?)?.toDouble() ?? 20.0;
    final tempMax = (_containerData?['target_temperature'] as num?)?.toDouble() ?? 28.0;
    final humMin = (_containerData?['target_humidity_min'] as num?)?.toDouble() ?? 40.0;
    final humMax = (_containerData?['target_humidity'] as num?)?.toDouble() ?? 65.0;
    final lightMin = (_containerData?['target_light_level_min'] as num?)?.toDouble() ?? 30.0;
    final lightMax = (_containerData?['target_light_level'] as num?)?.toDouble() ?? 75.0;
    final gasMin = (_containerData?['target_gas_level_min'] as num?)?.toDouble() ?? 1000.0;
    final gasMax = (_containerData?['target_gas_level'] as num?)?.toDouble() ?? 2000.0;

    final tempStatus = temp == null
        ? '--'
      : _evaluateStatusInRange(
            value: temp,
        min: tempMin,
        max: tempMax,
          );
    final humStatus = hum == null
        ? '--'
      : _evaluateStatusInRange(
            value: hum,
        min: humMin,
        max: humMax,
          );
    final lightStatus = light == null
        ? '--'
      : _evaluateStatusInRange(
            value: light,
        min: lightMin,
        max: lightMax,
          );
    final gasStatus = gas == null
        ? '--'
      : _evaluateStatusInRange(
            value: gas,
        min: gasMin,
        max: gasMax,
          );

    final containerName = ContainerService.selectedContainer.value?.name ?? 'Container';

    // Generate dynamic alerts based on real data
    final alerts = <Map<String, dynamic>>[];

    if (tempStatus == 'CRITICAL' && temp != null) {
      alerts.add({
        'title': 'Critical Temperature',
        'desc': '$containerName temperature: ${temp.toStringAsFixed(1)}°C',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.thermostat,
      });
    } else if (tempStatus == 'WARNING' && temp != null) {
      alerts.add({
        'title': 'Temperature Warning',
        'desc': '$containerName temperature: ${temp.toStringAsFixed(1)}°C',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.thermostat,
      });
    }

    if (humStatus == 'CRITICAL' && hum != null) {
      alerts.add({
        'title': 'Critical Humidity',
        'desc': '$containerName humidity: ${hum.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.water_drop,
      });
    } else if (humStatus == 'WARNING' && hum != null) {
      alerts.add({
        'title': 'Humidity Warning',
        'desc': '$containerName humidity: ${hum.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.water_drop,
      });
    }

    if (lightStatus == 'CRITICAL' && light != null) {
      alerts.add({
        'title': 'Critical Light Level',
        'desc': '$containerName light: ${light.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.light_mode_outlined,
      });
    } else if (lightStatus == 'WARNING' && light != null) {
      alerts.add({
        'title': 'Light Warning',
        'desc': '$containerName light: ${light.toStringAsFixed(0)}%',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.light_mode_outlined,
      });
    }

    if (gasStatus == 'CRITICAL' && gas != null) {
      alerts.add({
        'title': 'Critical Gas Level',
        'desc': '$containerName gas: ${gas.toStringAsFixed(0)} ppm',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'critical',
        'icon': Icons.co2,
      });
    } else if (gasStatus == 'WARNING' && gas != null) {
      alerts.add({
        'title': 'Gas Warning',
        'desc': '$containerName gas: ${gas.toStringAsFixed(0)} ppm',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'warning',
        'icon': Icons.co2,
      });
    }

    final hasAnySensorData = temp != null || hum != null || light != null || gas != null;

    if (!hasAnySensorData) {
      alerts.add({
        'title': 'Waiting For Sensor Data',
        'desc': 'No live sensor values available for $containerName yet',
        'time': _lastUpdated,
        'date': 'Today',
        'type': 'info',
        'icon': Icons.sensors,
      });
    }

    // Add success alert if all is good
    if (alerts.isEmpty && hasAnySensorData) {
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
        Text(
          'Alerts & Logs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
                    onPressed: _isGeneratingReport ? null : _generateFullReport,
                    icon: Icon(Icons.download_rounded, size: 20),
                    label: _isGeneratingReport
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Generating PDF...'),
                            ],
                          )
                        : Text('Generate Full Report'),
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

  DateTime _resolveLastUpdatedAt(Map<String, dynamic> data, List<Map<String, dynamic>> history) {
    for (final entry in history.reversed) {
      final recordedAtRaw = entry['recorded_at'] as String?;
      final recordedAt = recordedAtRaw != null ? DateTime.tryParse(recordedAtRaw) : null;
      if (recordedAt != null) {
        return recordedAt.toLocal();
      }
    }

    final dataUpdatedRaw = data['last_updated'] as String?;
    final dataUpdated = dataUpdatedRaw != null ? DateTime.tryParse(dataUpdatedRaw) : null;
    return (dataUpdated ?? DateTime.now()).toLocal();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    final isToday =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    if (isToday) {
      return '$hour:$minute';
    }

    return '$day/$month $hour:$minute';
  }

  Future<void> _generateFullReport() async {
    final selectedContainer = ContainerService.selectedContainer.value;
    if (selectedContainer == null || _containerData == null) return;

    setState(() => _isGeneratingReport = true);

    try {
      final pdf = pw.Document();
      final temp = (_containerData?['temperature'] as num?)?.toDouble();
      final hum = (_containerData?['humidity'] as num?)?.toDouble();
      final light = (_containerData?['light_level'] as num?)?.toDouble();
      final gas = (_containerData?['gas_level'] as num?)?.toDouble();

      final tempMin = (_containerData?['target_temperature_min'] as num?)?.toDouble() ?? 20.0;
      final tempMax = (_containerData?['target_temperature'] as num?)?.toDouble() ?? 28.0;
      final humMin = (_containerData?['target_humidity_min'] as num?)?.toDouble() ?? 40.0;
      final humMax = (_containerData?['target_humidity'] as num?)?.toDouble() ?? 65.0;
      final lightMin = (_containerData?['target_light_level_min'] as num?)?.toDouble() ?? 30.0;
      final lightMax = (_containerData?['target_light_level'] as num?)?.toDouble() ?? 75.0;
      final gasMin = (_containerData?['target_gas_level_min'] as num?)?.toDouble() ?? 1000.0;
      final gasMax = (_containerData?['target_gas_level'] as num?)?.toDouble() ?? 2000.0;

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Locust Farm Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Container: ${selectedContainer.name}'),
            pw.Text('Generated: ${_formatTimestamp(DateTime.now().toLocal())}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const ['Metric', 'Value', 'Target', 'Status'],
              data: [
                ['Temperature', temp == null ? '--' : '${temp.toStringAsFixed(1)} °C', '${tempMin.toStringAsFixed(1)}-${tempMax.toStringAsFixed(1)} °C', temp == null ? '--' : _evaluateStatusInRange(value: temp, min: tempMin, max: tempMax)],
                ['Humidity', hum == null ? '--' : '${hum.toStringAsFixed(0)} %', '${humMin.toStringAsFixed(0)}-${humMax.toStringAsFixed(0)} %', hum == null ? '--' : _evaluateStatusInRange(value: hum, min: humMin, max: humMax)],
                ['Light', light == null ? '--' : '${light.toStringAsFixed(0)} %', '${lightMin.toStringAsFixed(0)}-${lightMax.toStringAsFixed(0)} %', light == null ? '--' : _evaluateStatusInRange(value: light, min: lightMin, max: lightMax)],
                ['Gas', gas == null ? '--' : '${gas.toStringAsFixed(0)} ppm', '${gasMin.toStringAsFixed(0)}-${gasMax.toStringAsFixed(0)} ppm', gas == null ? '--' : _evaluateStatusInRange(value: gas, min: gasMin, max: gasMax)],
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('History samples', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Temperature: ${_temperatureHistory.length} samples'),
            pw.Text('Humidity: ${_humidityHistory.length} samples'),
            pw.Text('Light: ${_lightHistory.length} samples'),
            pw.Text('Gas: ${_gasHistory.length} samples'),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        name: 'locust_farm_report_${selectedContainer.id}.pdf',
        onLayout: (_) async => bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generated. Use Save in the system dialog.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
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
    final temp = (_containerData?['temperature'] as num?)?.toDouble();
    final hum = (_containerData?['humidity'] as num?)?.toDouble();
    final light = (_containerData?['light_level'] as num?)?.toDouble();
    final gas = (_containerData?['gas_level'] as num?)?.toDouble();

    final tempMin = (_containerData?['target_temperature_min'] as num?)?.toDouble() ?? 20.0;
    final tempMax = (_containerData?['target_temperature'] as num?)?.toDouble() ?? 28.0;
    final humMin = (_containerData?['target_humidity_min'] as num?)?.toDouble() ?? 40.0;
    final humMax = (_containerData?['target_humidity'] as num?)?.toDouble() ?? 65.0;
    final lightMin = (_containerData?['target_light_level_min'] as num?)?.toDouble() ?? 30.0;
    final lightMax = (_containerData?['target_light_level'] as num?)?.toDouble() ?? 75.0;
    final gasMin = (_containerData?['target_gas_level_min'] as num?)?.toDouble() ?? 1000.0;
    final gasMax = (_containerData?['target_gas_level'] as num?)?.toDouble() ?? 2000.0;

    final tempStatus = temp == null
        ? '--'
      : _evaluateStatusInRange(
            value: temp,
        min: tempMin,
        max: tempMax,
          );
    final humStatus = hum == null
        ? '--'
      : _evaluateStatusInRange(
            value: hum,
        min: humMin,
        max: humMax,
          );
    final lightStatus = light == null
        ? '--'
      : _evaluateStatusInRange(
            value: light,
        min: lightMin,
        max: lightMax,
          );
    final gasStatus = gas == null
        ? '--'
      : _evaluateStatusInRange(
            value: gas,
        min: gasMin,
        max: gasMax,
          );

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
                value: _isLoading || temp == null ? '--' : temp.toStringAsFixed(1),
                unit: '°C',
                progress: (temp != null && tempMax > 0 ? (temp / (tempMax * 1.25)) : 0).clamp(0.0, 1.0).toDouble(),
                progressColor: AppColors.temperature,
                status: tempStatus,
                statusColor: _getStatusColor(tempStatus),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop,
                iconColor: AppColors.humidity,
                label: 'Humidity',
                value: _isLoading || hum == null ? '--' : hum.toStringAsFixed(0),
                unit: '%',
                progress: (hum != null ? (hum / 100.0) : 0).clamp(0.0, 1.0).toDouble(),
                progressColor: AppColors.humidity,
                status: humStatus,
                statusColor: _getStatusColor(humStatus),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.light_mode_outlined,
                iconColor: Colors.amber,
                label: 'Light',
                value: _isLoading || light == null ? '--' : light.toStringAsFixed(0),
                unit: '%',
                progress: (light != null && lightMax > 0 ? (light / (lightMax * 1.25)) : 0).clamp(0.0, 1.0).toDouble(),
                progressColor: Colors.amber,
                status: lightStatus,
                statusColor: _getStatusColor(lightStatus),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.co2,
                iconColor: Colors.deepOrange,
                label: 'Gas',
                value: _isLoading || gas == null ? '--' : gas.toStringAsFixed(0),
                unit: 'ppm',
                progress: (gas != null && gasMax > 0 ? (gas / (gasMax * 1.25)) : 0).clamp(0.0, 1.0).toDouble(),
                progressColor: Colors.deepOrange,
                status: gasStatus,
                statusColor: _getStatusColor(gasStatus),
              ),
            ),
          ],
        ),
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
    required String status,
    required Color statusColor,
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
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          // ...existing code...
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
                duration: Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        val.toStringAsFixed(value.contains('.') ? 1 : 0),
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
                  );
                },
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

  Widget _buildEnvironmentalCharts() {
    final temp = (_containerData?['temperature'] as num?)?.toDouble();
    final hum = (_containerData?['humidity'] as num?)?.toDouble();
    final light = (_containerData?['light_level'] as num?)?.toDouble();
    final gas = (_containerData?['gas_level'] as num?)?.toDouble();

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
          currentValue: _isLoading || temp == null ? '--' : temp.toStringAsFixed(1),
          chartColor: AppColors.temperature,
          dataPoints: _getTemperatureData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Humidity',
          icon: Icons.water_drop,
          iconColor: AppColors.humidity,
          unit: '%',
          currentValue: _isLoading || hum == null ? '--' : hum.toStringAsFixed(0),
          chartColor: AppColors.humidity,
          dataPoints: _getHumidityData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Light',
          icon: Icons.light_mode_outlined,
          iconColor: Colors.amber,
          unit: '%',
          currentValue: _isLoading || light == null ? '--' : light.toStringAsFixed(0),
          chartColor: Colors.amber,
          dataPoints: _getLightData(),
        ),
        SizedBox(height: 16),
        _buildChartCard(
          title: 'Gas',
          icon: Icons.co2,
          iconColor: Colors.deepOrange,
          unit: 'ppm',
          currentValue: _isLoading || gas == null ? '--' : gas.toStringAsFixed(0),
          chartColor: Colors.deepOrange,
          dataPoints: _getGasData(),
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
  // Return temperature history from API calls
  List<double> _getTemperatureData() {
    if (_temperatureHistory.isEmpty) {
      final current = (_containerData?['temperature'] as num?)?.toDouble() ?? 24.0;
      return List.generate(7, (_) => current);
    }
    // Return the last 7 data points
    return _temperatureHistory.map((e) => e['y'] as double).toList();
  }

  // Return humidity history from API calls
  List<double> _getHumidityData() {
    if (_humidityHistory.isEmpty) {
      final current = (_containerData?['humidity'] as num?)?.toDouble() ?? 65.0;
      return List.generate(7, (_) => current);
    }
    // Return the last 7 data points
    return _humidityHistory.map((e) => e['y'] as double).toList();
  }

  List<double> _getLightData() {
    if (_lightHistory.isEmpty) {
      final current = (_containerData?['light_level'] as num?)?.toDouble() ?? 75.0;
      return List.generate(7, (_) => current);
    }
    return _lightHistory.map((e) => e['y'] as double).toList();
  }

  List<double> _getGasData() {
    if (_gasHistory.isEmpty) {
      final current = (_containerData?['gas_level'] as num?)?.toDouble() ?? 350.0;
      return List.generate(7, (_) => current);
    }
    return _gasHistory.map((e) => e['y'] as double).toList();
  }

  void _applyHistoryEntries(List<Map<String, dynamic>> historyEntries) {
    _temperatureHistory.clear();
    _humidityHistory.clear();
    _lightHistory.clear();
    _gasHistory.clear();

    for (final entry in historyEntries) {
      final sensorType = entry['sensor_type'] as String?;
      final value = (entry['value'] as num?)?.toDouble();
      final recordedAtRaw = entry['recorded_at'] as String?;
      final recordedAt = recordedAtRaw != null ? DateTime.tryParse(recordedAtRaw) : null;
      final timestamp = recordedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
      final timeLabel = recordedAt != null
          ? '${recordedAt.hour}:${recordedAt.minute.toString().padLeft(2, '0')}'
          : '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

      if (sensorType == null || value == null) continue;

      final sample = {
        'x': timestamp,
        'y': value,
        'time': timeLabel,
      };

      switch (sensorType) {
        case 'temperature':
          _temperatureHistory.add(sample);
          if (_temperatureHistory.length > MAX_HISTORY) {
            _temperatureHistory.removeAt(0);
          }
          break;
        case 'humidity':
          _humidityHistory.add(sample);
          if (_humidityHistory.length > MAX_HISTORY) {
            _humidityHistory.removeAt(0);
          }
          break;
        case 'light_level':
          _lightHistory.add(sample);
          if (_lightHistory.length > MAX_HISTORY) {
            _lightHistory.removeAt(0);
          }
          break;
        case 'gas_level':
          _gasHistory.add(sample);
          if (_gasHistory.length > MAX_HISTORY) {
            _gasHistory.removeAt(0);
          }
          break;
      }
    }
  }

  String _evaluateStatusInRange({
    required double value,
    required double min,
    required double max,
    double warningBandRatio = 0.1,
  }) {
    final lower = min <= max ? min : max;
    final upper = max >= min ? max : min;

    if (value < lower || value > upper) {
      return 'CRITICAL';
    }

    final range = upper - lower;
    if (range <= 0) {
      return 'SAFE';
    }

    final warningBand = range * warningBandRatio;
    final nearLower = (value - lower) <= warningBand;
    final nearUpper = (upper - value) <= warningBand;
    if (nearLower || nearUpper) {
      return 'WARNING';
    }

    return 'SAFE';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SAFE':
        return Colors.green;
      case 'WARNING':
        return AppColors.warning;
      case 'CRITICAL':
        return AppColors.liveRed;
      default:
        return AppColors.textSecondary;
    }
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
    final safeDataPoints = dataPoints.where((value) => value.isFinite).toList();
    if (safeDataPoints.isEmpty) return;

    // Find min and max for scaling
    final minValue = safeDataPoints.reduce((a, b) => a < b ? a : b);
    final maxValue = safeDataPoints.reduce((a, b) => a > b ? a : b);
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
    if (safeDataPoints.length == 1) {
      final normalizedValue = range > 0 ? (safeDataPoints.first - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(size.width / 2, y));
    } else {
      final segmentWidth = size.width / (safeDataPoints.length - 1);

      for (int i = 0; i < safeDataPoints.length; i++) {
        final x = i * segmentWidth;
        final normalizedValue = range > 0 ? (safeDataPoints[i] - minValue) / range : 0.5;
        final y = size.height - (normalizedValue * size.height * 0.9) - (size.height * 0.05);
        points.add(Offset(x, y));
      }
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

  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}









