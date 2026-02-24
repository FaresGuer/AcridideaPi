import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app_colors.dart';

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

  // Threshold States
  double _tempThreshold = 28.0;
  double _humidityThreshold = 65.0;

  @override
  Widget build(BuildContext context) {
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
                onChanged: (val) => setState(() => _ventilationActive = val),
              ),
              SizedBox(height: 16),

              _buildControlCard(
                title: 'Humidifier',
                status: _humidifierActive ? 'Regulating moisture' : 'Moisture regulation paused',
                icon: Icons.water_drop,
                isActive: _humidifierActive,
                activeColor: AppColors.info, // Use blue for water/humidifier logically, though design might differ slightly
                onChanged: (val) => setState(() => _humidifierActive = val),
              ),
              SizedBox(height: 16),

              _buildControlCard(
                title: 'Heating Element',
                status: _heatingActive ? 'Targeting 28.5°C' : 'Heating disabled',
                icon: Icons.thermostat,
                isActive: _heatingActive,
                activeColor: AppColors.success,
                onChanged: (val) => setState(() => _heatingActive = val),
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
                value: _tempThreshold,
                unit: '°C',
                min: 15,
                max: 35,
                icon: Icons.thermostat_outlined,
                iconColor: Color(0xFF009688), // Teal
                iconBgColor: Color(0xFFE0F2F1), // Light Teal
                sliderColor: Color(0xFF009688),
                onChanged: (val) => setState(() => _tempThreshold = val),
              ),
              SizedBox(height: 16),

              _buildThresholdCard(
                title: 'Humidity',
                value: _humidityThreshold,
                unit: '%',
                min: 0,
                max: 100,
                icon: Icons.water_drop,
                iconColor: Color(0xFF2962FF), // Blue
                iconBgColor: Color(0xFFE3F2FD), // Light Blue
                sliderColor: Color(0xFF448AFF),
                onChanged: (val) => setState(() => _humidityThreshold = val),
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
                  'Greenhouse A',
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
              color: Colors.black.withOpacity(0.05),
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
                            color: Colors.black.withOpacity(0.1),
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
    required double value,
    required String unit,
    required double min,
    required double max,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color sliderColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
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
                  overlayColor: sliderColor.withOpacity(0.1),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
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

