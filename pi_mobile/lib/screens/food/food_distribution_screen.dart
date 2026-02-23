import 'package:flutter/material.dart';
import '../../app_colors.dart';

class FoodDistributionScreen extends StatefulWidget {
  const FoodDistributionScreen({Key? key}) : super(key: key);

  @override
  State<FoodDistributionScreen> createState() => _FoodDistributionScreenState();
}

class _FoodDistributionScreenState extends State<FoodDistributionScreen> {
  DateTime _selectedDate = DateTime.now();
  List<FeedingSchedule> _schedules = [
    FeedingSchedule(
      id: 1,
      time: '08:00 AM',
      quantity: '500g',
      foodType: 'Vegetable Scraps',
      colony: 'Colony A',
    ),
    FeedingSchedule(
      id: 2,
      time: '02:00 PM',
      quantity: '300g',
      foodType: 'Commercial Feed',
      colony: 'Colony B',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Food Distribution'),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Section
            Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Simple Date Display with Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(Duration(days: 1));
                            });
                          },
                        ),
                        Column(
                          children: [
                            Text(
                              _getMonthDay(_selectedDate),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _getDayName(_selectedDate),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(Duration(days: 1));
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Mini calendar strip
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final date = DateTime.now().add(Duration(days: index - 3));
                          final isSelected = date.day == _selectedDate.day &&
                              date.month == _selectedDate.month &&
                              date.year == _selectedDate.year;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDate = date),
                            child: Container(
                              width: 50,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDayShort(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textHint,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Feeding Schedule List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s Schedule', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${_schedules.length} feedings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 12),

            if (_schedules.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text(
                        'No feedings scheduled',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add a new feeding schedule to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._schedules.map((schedule) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _ScheduleCard(
                    schedule: schedule,
                    onEdit: () => _showEditDialog(schedule),
                    onDelete: () => _deleteSchedule(schedule.id),
                  ),
                );
              }).toList(),

            SizedBox(height: 24),

            // Add New Schedule Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddDialog(),
                icon: Icon(Icons.add),
                label: Text('Add New Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        onSave: (FeedingSchedule schedule) {
          setState(() => _schedules.add(schedule));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(FeedingSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        initialSchedule: schedule,
        onSave: (FeedingSchedule updatedSchedule) {
          setState(() {
            final index = _schedules.indexWhere((s) => s.id == schedule.id);
            if (index != -1) {
              _schedules[index] = updatedSchedule;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteSchedule(int id) {
    setState(() => _schedules.removeWhere((s) => s.id == id));
  }

  String _getMonthDay(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getDayName(DateTime date) {
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  String _getDayShort(DateTime date) {
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class FeedingSchedule {
  final int id;
  final String time;
  final String quantity;
  final String foodType;
  final String colony;

  FeedingSchedule({
    required this.id,
    required this.time,
    required this.quantity,
    required this.foodType,
    required this.colony,
  });
}

class _ScheduleCard extends StatelessWidget {
  final FeedingSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.time, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 4),
                    Text(schedule.foodType, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.quantity,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(schedule.colony, style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      onPressed: onDelete,
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  final FeedingSchedule? initialSchedule;
  final Function(FeedingSchedule) onSave;

  const _ScheduleDialog({
    this.initialSchedule,
    required this.onSave,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late TextEditingController _timeController;
  late TextEditingController _quantityController;
  String _selectedFoodType = 'Vegetable Scraps';
  String _selectedColony = 'Colony A';

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.initialSchedule?.time ?? '');
    _quantityController = TextEditingController(text: widget.initialSchedule?.quantity ?? '');
    if (widget.initialSchedule != null) {
      _selectedFoodType = widget.initialSchedule!.foodType;
      _selectedColony = widget.initialSchedule!.colony;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialSchedule == null ? 'Add Schedule' : 'Edit Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Time (e.g., 08:00 AM)'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity (e.g., 500g)'),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              decoration: InputDecoration(labelText: 'Food Type'),
              items: ['Vegetable Scraps', 'Commercial Feed', 'Organic Blend'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _selectedFoodType = value ?? ''),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedColony,
              decoration: InputDecoration(labelText: 'Colony'),
              items: ['Colony A', 'Colony B', 'Colony C'].map((colony) {
                return DropdownMenuItem(value: colony, child: Text(colony));
              }).toList(),
              onChanged: (value) => setState(() => _selectedColony = value ?? ''),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onSave(FeedingSchedule(
              id: widget.initialSchedule?.id ?? DateTime.now().millisecondsSinceEpoch,
              time: _timeController.text,
              quantity: _quantityController.text,
              foodType: _selectedFoodType,
              colony: _selectedColony,
            ));
          },
          child: Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
