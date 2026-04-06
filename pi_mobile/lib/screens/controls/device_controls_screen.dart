import 'package:flutter/material.dart';
import 'dart:async';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/container_service.dart';

class DeviceControlsScreen extends StatefulWidget {
  const DeviceControlsScreen({super.key});

  @override
  State<DeviceControlsScreen> createState() => _DeviceControlsScreenState();
}

class _DeviceControlsScreenState extends State<DeviceControlsScreen> {
  // Manual Control States
  bool _ventilationActive = true;
  bool _humidifierActive = false;
  bool _heatingActive = true;
  bool _lightingActive = false;

  // Threshold States
  double _tempMinThreshold = 20.0;
  double _tempThreshold = 28.0;
  double _humidityMinThreshold = 40.0;
  double _humidityThreshold = 65.0;
  double _lightMinThreshold = 30.0;
  double _lightThreshold = 75.0;
  double _gasMinThreshold = 150.0;
  double _gasThreshold = 350.0;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadContainerData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadContainerData(showLoader: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContainerData({bool showLoader = true}) async {
    final selectedContainer = ContainerService.selectedContainer.value;
    if (selectedContainer == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final data = await AuthService.fetchContainerData(containerId: selectedContainer.id);
      if (!mounted) return;
      setState(() {
        _ventilationActive = data['fan_status'] as bool? ?? _ventilationActive;
        _humidifierActive = data['humidifier_status'] as bool? ?? _humidifierActive;
        _heatingActive = data['heater_status'] as bool? ?? _heatingActive;
        _lightingActive = data['light_status'] as bool? ?? _lightingActive;
        _tempMinThreshold = (data['target_temperature_min'] as num?)?.toDouble() ?? _tempMinThreshold;
        _tempThreshold = (data['target_temperature'] as num?)?.toDouble() ?? _tempThreshold;
        _humidityMinThreshold = (data['target_humidity_min'] as num?)?.toDouble() ?? _humidityMinThreshold;
        _humidityThreshold = (data['target_humidity'] as num?)?.toDouble() ?? _humidityThreshold;
        _lightMinThreshold = (data['target_light_level_min'] as num?)?.toDouble() ?? _lightMinThreshold;
        _lightThreshold = (data['target_light_level'] as num?)?.toDouble() ?? _lightThreshold;
        _gasMinThreshold = (data['target_gas_level_min'] as num?)?.toDouble() ?? _gasMinThreshold;
        _gasThreshold = (data['target_gas_level'] as num?)?.toDouble() ?? _gasThreshold;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContainerData({
    bool? fanStatus,
    bool? humidifierStatus,
    bool? heaterStatus,
    bool? lightStatus,
    double? targetTemperatureMin,
    double? targetTemperature,
    double? targetHumidityMin,
    double? targetHumidity,
    double? targetLightLevelMin,
    double? targetLightLevel,
    double? targetGasLevelMin,
    double? targetGasLevel,
  }) async {
    final selectedContainer = ContainerService.selectedContainer.value;
    if (selectedContainer == null) return;

    try {
      final updated = await AuthService.updateContainerData(
        containerId: selectedContainer.id,
        fanStatus: fanStatus,
        humidifierStatus: humidifierStatus,
        heaterStatus: heaterStatus,
        lightStatus: lightStatus,
        targetTemperatureMin: targetTemperatureMin,
        targetTemperature: targetTemperature,
        targetHumidityMin: targetHumidityMin,
        targetHumidity: targetHumidity,
        targetLightLevelMin: targetLightLevelMin,
        targetLightLevel: targetLightLevel,
        targetGasLevelMin: targetGasLevelMin,
        targetGasLevel: targetGasLevel,
      );

      if (!mounted) return;
      setState(() {
        _ventilationActive = updated['fan_status'] as bool? ?? _ventilationActive;
        _humidifierActive = updated['humidifier_status'] as bool? ?? _humidifierActive;
        _heatingActive = updated['heater_status'] as bool? ?? _heatingActive;
        _lightingActive = updated['light_status'] as bool? ?? _lightingActive;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // backgroundColor: AppColors.mintBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.mintBackground,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 32),

              Text(
                'Manual Controls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),

              _buildControlCard(
                title: 'Ventilation System',
                status: _ventilationActive ? 'Running at 40%' : 'System paused',
                icon: Icons.wind_power,
                isActive: _ventilationActive,
                activeColor: AppColors.success,
                onChanged: (val) {
                  setState(() => _ventilationActive = val);
                  _saveContainerData(fanStatus: val);
                },
              ),
              SizedBox(height: 16),

              _buildControlCard(
                title: 'Humidifier',
                status: _humidifierActive ? 'Regulating moisture' : 'Moisture regulation paused',
                icon: Icons.water_drop,
                isActive: _humidifierActive,
                activeColor: AppColors.info, // Use blue for water/humidifier logically, though design might differ slightly
                onChanged: (val) {
                  setState(() => _humidifierActive = val);
                  _saveContainerData(humidifierStatus: val);
                },
              ),
              SizedBox(height: 16),

              _buildControlCard(
                title: 'Heating Element',
                status: _heatingActive ? 'Targeting 28.5°C' : 'Heating disabled',
                icon: Icons.thermostat,
                isActive: _heatingActive,
                activeColor: AppColors.success,
                onChanged: (val) {
                  setState(() => _heatingActive = val);
                  _saveContainerData(heaterStatus: val);
                },
              ),
              SizedBox(height: 16),
              _buildControlCard(
                title: 'Lighting System',
                status: _lightingActive ? 'Targeting 60%' : 'Lighting disabled',
                icon: Icons.lightbulb_outline,
                isActive: _lightingActive,
                activeColor: AppColors.success,
                onChanged: (val) {
                  setState(() => _lightingActive = val);
                  _saveContainerData(lightStatus: val);
                },
              ),

              SizedBox(height: 32),
              Text(
                'Sensor Thresholds',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),

              _buildThresholdCard(
                title: 'Temperature',
                minThresholdValue: _tempMinThreshold,
                value: _tempThreshold,
                unit: '°C',
                min: 15,
                max: 35,
                icon: Icons.thermostat_outlined,
                iconColor: Color(0xFF009688), // Teal
                iconBgColor: Color(0xFFE0F2F1), // Light Teal
                sliderColor: Color(0xFF009688),
                onChanged: (val) => setState(() {
                  _tempThreshold = val;
                  if (_tempMinThreshold > _tempThreshold) {
                    _tempMinThreshold = _tempThreshold;
                  }
                }),
                onChangeEnd: (val) => _saveContainerData(
                  targetTemperature: val,
                  targetTemperatureMin: _tempMinThreshold,
                ),
                onMinThresholdChanged: (val) => setState(() {
                  _tempMinThreshold = val;
                  if (_tempThreshold < _tempMinThreshold) {
                    _tempThreshold = _tempMinThreshold;
                  }
                }),
                onMinThresholdChangeEnd: (val) => _saveContainerData(
                  targetTemperatureMin: val,
                  targetTemperature: _tempThreshold,
                ),
              ),
              SizedBox(height: 16),

              _buildThresholdCard(
                title: 'Humidity',
                minThresholdValue: _humidityMinThreshold,
                value: _humidityThreshold,
                unit: '%',
                min: 0,
                max: 100,
                icon: Icons.water_drop,
                iconColor: Color(0xFF2962FF), // Blue
                iconBgColor: Color(0xFFE3F2FD), // Light Blue
                sliderColor: Color(0xFF448AFF),
                onChanged: (val) => setState(() {
                  _humidityThreshold = val;
                  if (_humidityMinThreshold > _humidityThreshold) {
                    _humidityMinThreshold = _humidityThreshold;
                  }
                }),
                onChangeEnd: (val) => _saveContainerData(
                  targetHumidity: val,
                  targetHumidityMin: _humidityMinThreshold,
                ),
                onMinThresholdChanged: (val) => setState(() {
                  _humidityMinThreshold = val;
                  if (_humidityThreshold < _humidityMinThreshold) {
                    _humidityThreshold = _humidityMinThreshold;
                  }
                }),
                onMinThresholdChangeEnd: (val) => _saveContainerData(
                  targetHumidityMin: val,
                  targetHumidity: _humidityThreshold,
                ),
              ),

              SizedBox(height: 16),

              _buildThresholdCard(
                title: 'Light',
                minThresholdValue: _lightMinThreshold,
                value: _lightThreshold,
                unit: '%',
                min: 0,
                max: 100,
                icon: Icons.light_mode_outlined,
                iconColor: Color(0xFFFFA000),
                iconBgColor: Color(0xFFFFF8E1),
                sliderColor: Color(0xFFFFB300),
                onChanged: (val) => setState(() {
                  _lightThreshold = val;
                  if (_lightMinThreshold > _lightThreshold) {
                    _lightMinThreshold = _lightThreshold;
                  }
                }),
                onChangeEnd: (val) => _saveContainerData(
                  targetLightLevel: val,
                  targetLightLevelMin: _lightMinThreshold,
                ),
                onMinThresholdChanged: (val) => setState(() {
                  _lightMinThreshold = val;
                  if (_lightThreshold < _lightMinThreshold) {
                    _lightThreshold = _lightMinThreshold;
                  }
                }),
                onMinThresholdChangeEnd: (val) => _saveContainerData(
                  targetLightLevelMin: val,
                  targetLightLevel: _lightThreshold,
                ),
              ),

              SizedBox(height: 16),

              _buildThresholdCard(
                title: 'Gas',
                minThresholdValue: _gasMinThreshold,
                value: _gasThreshold,
                unit: 'ppm',
                min: 0,
                max: 1000,
                icon: Icons.co2,
                iconColor: Color(0xFFE65100),
                iconBgColor: Color(0xFFFFF3E0),
                sliderColor: Color(0xFFFF6D00),
                onChanged: (val) => setState(() {
                  _gasThreshold = val;
                  if (_gasMinThreshold > _gasThreshold) {
                    _gasMinThreshold = _gasThreshold;
                  }
                }),
                onChangeEnd: (val) => _saveContainerData(
                  targetGasLevel: val,
                  targetGasLevelMin: _gasMinThreshold,
                ),
                onMinThresholdChanged: (val) => setState(() {
                  _gasMinThreshold = val;
                  if (_gasThreshold < _gasMinThreshold) {
                    _gasThreshold = _gasMinThreshold;
                  }
                }),
                onMinThresholdChangeEnd: (val) => _saveContainerData(
                  targetGasLevelMin: val,
                  targetGasLevel: _gasThreshold,
                ),
              ),

              SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Controls',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  ContainerService.selectedContainer.value?.name ?? 'Container',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'All systems nominal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.settings, color: Colors.grey.shade700),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildControlCard({
    required String title,
    required String status,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    // Custom colors based on screenshot
    // Active: Light greenish bg, Dark green icon, Green/Check switch
    final backgroundColor = isActive ? Color(0xFFE8F5E9) : Colors.white; // Green 50 vs White
    final borderColor = isActive ? Color(0xFFC8E6C9) : Colors.transparent;
    // Icon colors:
    // Active: Icon is green (0xFF00C853?), bg is white.
    // Inactive: Icon is grey? Screenshot shows inactive humidifier.
    // Humidifier inactive: Icon is grey (0xFF78909C), bg is light grey (0xFFECEFF1).
    final iconColor = isActive ? Color(0xFF00C853) : Color(0xFF546E7A);
    final iconBgColor = isActive ? Colors.white : Color(0xFFECEFF1); // BlueGrey 50
    final switchActiveColor = Color(0xFF00C853);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (!isActive)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? Color(0xFF2E7D32) : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Custom Switch
          GestureDetector(
            onTap: () => onChanged(!isActive),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 60,
              height: 34,
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive ? switchActiveColor : Color(0xFFCFD8DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutBack, // Bouncy effect
                    alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                         child: AnimatedOpacity(
                            duration: Duration(milliseconds: 200),
                            opacity: isActive ? 1.0 : 0.0,
                            child: Icon(Icons.check, size: 16, color: switchActiveColor),
                         ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard({
    required String title,
    required double minThresholdValue,
    required double value,
    required String unit,
    required double min,
    required double max,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color sliderColor,
    required ValueChanged<double> onMinThresholdChanged,
    ValueChanged<double>? onMinThresholdChangeEnd,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          // Custom Slider with Tooltip
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: sliderColor,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Colors.white,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
                  overlayColor: sliderColor.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              // Floating Label (Simplified positioning)
              Positioned(
                left: _calculateThumbPosition(context, value, min, max) - 20, // Approximate offset
                top: -30,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(1)}°',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.toInt()}$unit',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  '${max.toInt()}$unit',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min Threshold',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                '${minThresholdValue.toStringAsFixed(1)} $unit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: iconColor),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: iconColor,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: iconColor,
              overlayColor: iconColor.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: minThresholdValue,
              min: min,
              max: max,
              onChanged: onMinThresholdChanged,
              onChangeEnd: onMinThresholdChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to calculate slider thumb position for the label
  double _calculateThumbPosition(BuildContext context, double value, double min, double max) {
    // This is a rough approximation relying on fixed layout width assumptions
    // For a real production app, LayoutBuilder is better, but this works for demo
    // Screen width - padding (48) / 2 approx center
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
          final width = box.size.width - 48; // padding
          final percent = (value - min) / (max - min);
          return width * percent;
      }
    } catch (_) {}
    return 100; // Default fallback
  }
}
