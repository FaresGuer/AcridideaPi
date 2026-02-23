import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/auth_user.dart';
import '../../services/auth_service.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<Worker> _workers = [
    Worker(
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      role: 'Manager',
      status: 'Active',
      joinDate: 'Jan 15, 2024',
    ),
    Worker(
      id: 2,
      name: 'Sarah Smith',
      email: 'sarah@example.com',
      role: 'Technician',
      status: 'Active',
      joinDate: 'Feb 20, 2024',
    ),
    Worker(
      id: 3,
      name: 'Mike Johnson',
      email: 'mike@example.com',
      role: 'Operator',
      status: 'Inactive',
      joinDate: 'Dec 10, 2023',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {
        final isAdmin = (user?.role ?? '').toUpperCase() == 'ADMIN';
        final tabCount = isAdmin ? 2 : 1;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text('Account Management'),
              elevation: 0.5,
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.primary,
                tabs: [
                  if (isAdmin) Tab(text: 'Workers'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                if (isAdmin) _buildWorkersTab(context),
                _buildSettingsTab(context, user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkersTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.people_outline,
                  label: 'Total Workers',
                  value: '${_workers.length}',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle_outline,
                  label: 'Active',
                  value: '${_workers.where((w) => w.status == 'Active').length}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Invite New Worker
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showInviteDialog(),
              icon: Icon(Icons.person_add_outlined),
              label: Text('Grant Access - Invite Worker'),
            ),
          ),
          SizedBox(height: 24),

          // Worker List
          Text('Team Members', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),

          ..._workers.map((worker) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _WorkerCard(
                worker: worker,
                onEdit: () => _showEditWorkerDialog(worker),
                onRemove: () => _removeWorker(worker.id),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, AuthUser? user) {
    final roleLabel = (user?.role ?? 'FARMER').toUpperCase();
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile Information', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),

          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          Text('Security Settings', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline, color: AppColors.primary),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.security_outlined, color: AppColors.primary),
                  title: Text('Two-Factor Authentication'),
                  trailing: Switch(value: false, onChanged: (value) {}),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: AppColors.primary),
                  title: Text('Email Notifications'),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language_outlined, color: AppColors.primary),
                  title: Text('Language'),
                  trailing: Text('English', style: Theme.of(context).textTheme.bodySmall),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                await AuthService.logout();
              },
              child: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'worker@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Role'),
              value: 'Operator',
              items: ['Manager', 'Technician', 'Operator'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _workers.add(Worker(
                  id: _workers.length + 1,
                  name: emailController.text.split('@')[0],
                  email: emailController.text,
                  role: 'Operator',
                  status: 'Pending',
                  joinDate: 'Today',
                ));
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invitation sent successfully!')),
              );
            },
            child: Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: worker.name),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: worker.email),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Role'),
              value: worker.role,
              items: ['Manager', 'Technician', 'Operator'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeWorker(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Worker'),
        content: Text('Are you sure you want to remove this worker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() => _workers.removeWhere((w) => w.id == id));
              Navigator.pop(context);
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class Worker {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String joinDate;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joinDate,
  });
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _WorkerCard({
    required this.worker,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 4),
                  Text(worker.email, style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          worker.role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: worker.status == 'Active'
                              ? AppColors.success.withOpacity(0.1)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          worker.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: worker.status == 'Active' ? AppColors.success : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: onEdit,
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                  onTap: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
