import 'package:flutter/material.dart';
import '../../app_colors.dart';

class FoodDistributionScreen extends StatefulWidget {
  const FoodDistributionScreen({Key? key}) : super(key: key);

  @override
  State<FoodDistributionScreen> createState() => _FoodDistributionScreenState();
}

class _FoodDistributionScreenState extends State<FoodDistributionScreen> {
  DateTime _selectedDate = DateTime(2026, 2, 23); // Mon 23 Feb 2026
  final List<DateTime> _days = [
    DateTime(2026, 2, 20),
    DateTime(2026, 2, 21),
    DateTime(2026, 2, 22),
    DateTime(2026, 2, 23),
    DateTime(2026, 2, 24),
    DateTime(2026, 2, 25),
    DateTime(2026, 2, 26),
  ];
  
  // Mock data structure: Map<Day, List<ScheduleItem>>
  final Map<int, List<Map<String, dynamic>>> _schedules = {
    20: [ // Fri
       {'time': '09:00 AM', 'food': 'Fresh Grass', 'amount': '600g', 'colony': 'Colony A', 'icon': Icons.grass, 'color': Colors.green, 'bg': Colors.green.shade50},
       {'time': '03:00 PM', 'food': 'Bran Mix', 'amount': '300g', 'colony': 'Colony B', 'icon': Icons.bakery_dining, 'color': Colors.amber, 'bg': Colors.amber.shade50},
    ],
    21: [ // Sat
       {'time': '08:30 AM', 'food': 'Carrot Tops', 'amount': '550g', 'colony': 'Colony A', 'icon': Icons.eco, 'color': Colors.orange, 'bg': Colors.orange.shade50},
    ],
    22: [ // Sun
       {'time': '10:00 AM', 'food': 'Weekend Mix', 'amount': '700g', 'colony': 'All Colonies', 'icon': Icons.restaurant, 'color': Colors.purple, 'bg': Colors.purple.shade50},
    ],
    23: [ // Mon (Today in demo)
       {'time': '08:00 AM', 'food': 'Vegetable Scraps', 'amount': '500g', 'colony': 'Colony A', 'icon': Icons.eco, 'color': Color(0xFF4CAF50), 'bg': Color(0xFFE8F5E9)},
       {'time': '02:00 PM', 'food': 'Commercial Feed', 'amount': '300g', 'colony': 'Colony B', 'icon': Icons.science, 'color': Color(0xFF1565C0), 'bg': Color(0xFFE3F2FD)},
    ],
    24: [ // Tue
       {'time': '09:00 AM', 'food': 'Wheat Grass', 'amount': '600g', 'colony': 'Colony A', 'icon': Icons.grass, 'color': Colors.lightGreen, 'bg': Colors.lightGreen.shade50},
       {'time': '04:00 PM', 'food': 'Vitamin Supp.', 'amount': '50g', 'colony': 'Colony B', 'icon': Icons.medication, 'color': Colors.red, 'bg': Colors.red.shade50},
    ],
    25: [ // Wed
       {'time': '08:00 AM', 'food': 'Oats & Grains', 'amount': '450g', 'colony': 'Colony A', 'icon': Icons.grain, 'color': Colors.brown, 'bg': Colors.brown.shade50},
    ],
    26: [ // Thu
       {'time': '11:00 AM', 'food': 'Leafy Greens', 'amount': '500g', 'colony': 'Colony B', 'icon': Icons.eco, 'color': Colors.teal, 'bg': Colors.teal.shade50},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.mintBackground],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24),
                    _buildCalendarStrip(),
                    SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: SlideTransition(
                          position: Tween<Offset>(begin: Offset(0.0, 0.05), end: Offset.zero).animate(animation),
                          child: child,
                        ));
                      },
                      child: Column(
                        key: ValueKey(_selectedDate),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           _buildSummaryCard(),
                           SizedBox(height: 24),
                           _buildDailyContent(),
                        ],
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
              Positioned(
                right: 24,
                bottom: 120, // Bottom right position
                child: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.add, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyContent() {
    final dayData = _schedules[_selectedDate.day] ?? [
       {'time': '09:00 AM', 'food': 'Standard Mix', 'amount': '400g', 'colony': 'Colony A', 'icon': Icons.fastfood, 'color': Colors.grey, 'bg': Colors.grey.shade200},
    ];
    final count = dayData.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(
              "Schedule",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Container(
               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.grey.shade200,
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 "$count feeding${count != 1 ? 's' : ''}", 
                 style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
               ),
             ),
           ],
        ),
        SizedBox(height: 16),
        ...List.generate(dayData.length, (index) {
            final item = dayData[index];
            return _buildTimelineItem(
              time: item['time'],
              food: item['food'],
              amount: item['amount'],
              colony: item['colony'],
              icon: item['icon'],
              iconColor: item['color'],
              iconBg: item['bg'],
              isFirst: index == 0,
              isLast: index == dayData.length - 1,
            );
        }),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Food Distribution', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 8),
            Text('Manage feeding schedules for colonies', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 28),
      ],
    );
  }

  Widget _buildCalendarStrip() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('February 2026', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.textSecondary),
                SizedBox(width: 16),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _days.map((date) {
            final isSelected = date.year == _selectedDate.year && 
                               date.month == _selectedDate.month && 
                               date.day == _selectedDate.day;
            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final dayName = dayNames[date.weekday - 1]; 
            
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: _buildDateItem(dayName, date.day.toString(), isSelected),
            );
          }).toList().sublist(0, 5),
        ),
      ],
    );
  }

  Widget _buildDateItem(String day, String date, bool isSelected) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: 60,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.darkGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.darkGreen.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))]
            : null,
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white60 : AppColors.textSecondary, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text(date, style: TextStyle(fontSize: 20, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          if (isSelected) ...[
            SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final dayData = _schedules[_selectedDate.day];
    String total = "0g";
    String count = "0";
    
    if (dayData != null) {
        count = dayData.length.toString();
        // Simple logic to just show first item amount or sum if parsed (demo simplification)
        // Let's just manually map for demo consistency
        if (_selectedDate.day == 23) total = "800g";
        else if (_selectedDate.day == 20) total = "900g";
        else if (_selectedDate.day == 21) total = "550g";
        else if (_selectedDate.day == 22) total = "700g";
        else if (_selectedDate.day == 24) total = "650g";
        else total = "400g";
    }

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('DAILY TOTAL', total, AppColors.darkGreen),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildSummaryItem('FEEDINGS', count, Colors.black),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: Text('Normal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTimelineItem({required String time, required String food, required String amount, required String colony, required IconData icon, required Color iconColor, required Color iconBg, bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
               Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200, margin: EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(food, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.domain, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(colony, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

