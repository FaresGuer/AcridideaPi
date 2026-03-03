import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/container_service.dart';
import '../../models/feeding_schedule.dart';

class FoodDistributionScreen extends StatefulWidget {
  const FoodDistributionScreen({super.key});

  @override
  State<FoodDistributionScreen> createState() => _FoodDistributionScreenState();
}

class _FoodDistributionScreenState extends State<FoodDistributionScreen> {
  List<FeedingSchedule> _schedules = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFeedingSchedules();
  }

  Future<void> _loadFeedingSchedules() async {
    try {
      final container = ContainerService.selectedContainer.value;
      if (container == null) {
        setState(() => _isLoading = false);
        return;
      }

      final rows = await AuthService.fetchFeedingSchedules(containerId: container.id);
      setState(() {
        _schedules = rows.map((item) => FeedingSchedule.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedules: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _showScheduleFormDialog({
    FeedingSchedule? existing,
  }) async {
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    DateTime selectedDateTime = existing?.dateTime ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Feeding Schedule' : 'Edit Feeding Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text('Date & Time'),
                  subtitle: Text(
                    '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*([\.,]\d{0,2})?$')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (g)',
                    hintText: 'e.g. 250 or 250.5',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final parsedAmount = _parseAmount(amountController.text);
                if (parsedAmount == null || parsedAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enter a valid amount greater than 0')),
                  );
                  return;
                }

                final container = ContainerService.selectedContainer.value;
                if (container == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No container selected')),
                  );
                  return;
                }

                try {
                  if (existing == null) {
                    final created = await AuthService.createFeedingSchedule(
                      containerId: container.id,
                      feedingAt: selectedDateTime,
                      amount: parsedAmount,
                    );

                    if (!mounted) return;
                    setState(() {
                      _schedules.add(FeedingSchedule.fromJson(created));
                    });
                  } else {
                    if (existing.id == null) {
                      throw Exception('Missing schedule ID');
                    }

                    final updated = await AuthService.updateFeedingSchedule(
                      containerId: container.id,
                      scheduleId: existing.id!,
                      feedingAt: selectedDateTime,
                      amount: parsedAmount,
                    );

                    if (!mounted) return;
                    setState(() {
                      final index = _schedules.indexWhere((s) => s.id == existing.id);
                      if (index != -1) {
                        _schedules[index] = FeedingSchedule.fromJson(updated);
                      }
                    });
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving schedules: $e')),
                  );
                }
              },
              child: Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(FeedingSchedule schedule) async {
    final container = ContainerService.selectedContainer.value;
    if (container == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No container selected')),
      );
      return;
    }

    if (schedule.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete schedule without ID')),
      );
      return;
    }

    try {
      await AuthService.deleteFeedingSchedule(
        containerId: container.id,
        scheduleId: schedule.id!,
      );

      if (!mounted) return;
      setState(() {
        _schedules.removeWhere((s) => s.id == schedule.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule: $e')),
      );
    }
  }

  void _showScheduleActionsDialog(FeedingSchedule schedule) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primary),
              title: Text('Update schedule'),
              onTap: () {
                Navigator.pop(context);
                _showScheduleFormDialog(existing: schedule);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete schedule'),
              onTap: () async {
                Navigator.pop(context);
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete schedule'),
                    content: Text('Are you sure you want to delete this schedule?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  await _deleteSchedule(schedule);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog() {
    _showScheduleFormDialog();
  }

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
                    _buildSummaryCard(),
                    SizedBox(height: 24),
                    _buildDailyContent(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final today = DateTime.now();

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show 30 days
        itemBuilder: (context, index) {
          final date = DateTime(today.year, today.month, today.day).add(Duration(days: index));
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          
          // Count schedules for this date
          final schedulesForDate = _schedules.where((schedule) {
            return schedule.dateTime.year == date.year &&
                schedule.dateTime.month == date.month &&
                schedule.dateTime.day == date.day;
          }).length;
          
          return _buildDateItem(date, isSelected, schedulesForDate);
        },
      ),
    );
  }

  Widget _buildDateItem(DateTime date, bool isSelected, int count) {
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(date.weekday - 1) % 7];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        width: 70,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (count > 0) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Filter schedules by selected date
    final filteredSchedules = _schedules.where((schedule) {
      return schedule.dateTime.year == _selectedDate.year &&
          schedule.dateTime.month == _selectedDate.month &&
          schedule.dateTime.day == _selectedDate.day;
    }).toList();

    // Sort schedules by datetime
    final sortedSchedules = List<FeedingSchedule>.from(filteredSchedules)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    final count = sortedSchedules.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Row(
               children: [
                 Text(
                  "Schedule",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(width: 12),
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
             IconButton(
               onPressed: _showAddScheduleDialog,
               icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
               padding: EdgeInsets.zero,
               constraints: BoxConstraints(),
             ),
           ],
        ),
        SizedBox(height: 16),
        if (sortedSchedules.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text(
                    'No feeding schedules yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a schedule',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(sortedSchedules.length, (index) {
            final schedule = sortedSchedules[index];
            return _buildTimelineItem(
              dateTime: schedule.dateTime,
              amount: schedule.amount,
              onTap: () => _showScheduleActionsDialog(schedule),
              isFirst: index == 0,
              isLast: index == sortedSchedules.length - 1,
            );
        }),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Food Distribution', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
        SizedBox(height: 8),
        Text('Manage feeding schedules for colonies', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final count = _schedules.length.toString();
    
    // Calculate total amount
    double totalGrams = 0;
    for (var schedule in _schedules) {
      totalGrams += schedule.amount;
    }
    final total = "${totalGrams.toInt()}g";

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

  Widget _buildTimelineItem({required DateTime dateTime, required double amount, required VoidCallback onTap, bool isFirst = false, bool isLast = false}) {
    final iconBg = AppColors.primary.withOpacity(0.1);
    final iconColor = AppColors.primary;

    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    final amountText = amount % 1 == 0 ? '${amount.toInt()}g' : '${amount.toStringAsFixed(1)}g';

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
                child: Icon(Icons.restaurant, color: iconColor, size: 24),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200, margin: EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                SizedBox(height: 2),
                                Text(timeStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                              child: Text(amountText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

