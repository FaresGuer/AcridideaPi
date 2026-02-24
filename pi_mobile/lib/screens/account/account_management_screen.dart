import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/auth_user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with SingleTickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _twoFactorEnabled = true;
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {
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
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  _buildAnimatedItem(0, _buildHeader()),
                  SizedBox(height: 24),
                  _buildAnimatedItem(1, _buildProfileCard(user)),
                  SizedBox(height: 24),
                  _buildAnimatedItem(2, _buildSectionLabel('ENVIRONMENTAL ALERTS')),
                  SizedBox(height: 12),
                  _buildAnimatedItem(3, _buildEnvironmentalSection()),
                  SizedBox(height: 24),
                  _buildAnimatedItem(4, _buildSectionLabel('SECURITY')),
                  SizedBox(height: 12),
                  _buildAnimatedItem(5, _buildSecuritySection()),
                  SizedBox(height: 24),
                  _buildAnimatedItem(6, _buildSectionLabel('GENERAL')),
                  SizedBox(height: 12),
                  _buildAnimatedItem(7, _buildGeneralSection()),
                  if (user?.role == 'ADMIN') ...[
                    SizedBox(height: 24),
                    _buildAnimatedItem(8, _buildSectionLabel('WORKERS MANAGEMENT')),
                    SizedBox(height: 12),
                    _buildAnimatedItem(9, _buildWorkersSection()),
                    SizedBox(height: 24),
                    _buildAnimatedItem(10, _buildLogoutButton()),
                  ] else ...[
                    SizedBox(height: 24),
                    _buildAnimatedItem(8, _buildLogoutButton()),
                  ],
                  SizedBox(height: 32),
                  _buildAnimatedItem(11, Center(
                    child: Text(
                      'Version 2.4.0 (Build 394)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        InkWell(
          onTap: () {
            // Toggle theme action
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Theme toggled')));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFE3E8EF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.dark_mode, color: Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(AuthUser? user) {
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
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFFFCCBC),
                child: Text('AM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'ADMIN',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Alex Morgan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  user?.email ?? 'alex.morgan@locust.farm',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12),
                InkWell(
                  onTap: _showEditProfileDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEnvironmentalSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.thermostat,
            iconColor: Color(0xFFD32F2F),
            iconBg: Color(0xFFFFEBEE),
            title: 'Temp Thresholds',
            subtitle: 'Alerts above 30�C',
            onTap: () => _showSliderDialog('Temperature Threshold', '�C', 20, 40, 30),
          ),
          Divider(height: 1, indent: 64),
          _buildSettingsTile(
            icon: Icons.water_drop,
            iconColor: Color(0xFF1976D2),
            iconBg: Color(0xFFE3F2FD),
            title: 'Humidity Levels',
            subtitle: 'Optimized for Nursery Zone',
            onTap: () => _showSliderDialog('Humidity Target', '%', 40, 90, 65),
          ),
          Divider(height: 1, indent: 64),
          _buildSettingsTile(
            icon: Icons.notifications_active,
            iconColor: Color(0xFF7B1FA2),
            iconBg: Color(0xFFF3E5F5),
            title: 'Push Notifications',
            subtitle: _pushNotifications ? 'Instant alerts enabled' : 'Notifications disabled',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.lock,
            iconColor: Color(0xFF455A64),
            iconBg: Color(0xFFECEFF1),
            title: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          Divider(height: 1, indent: 64),
          _buildSettingsTile(
            icon: Icons.security,
            iconColor: Color(0xFF455A64),
            iconBg: Color(0xFFECEFF1),
            title: 'Two-Factor Auth',
            subtitle: _twoFactorEnabled ? 'Enabled' : 'Disabled',
            subtitleColor: _twoFactorEnabled ? Color(0xFF2E7D32) : Colors.grey,
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (val) => setState(() => _twoFactorEnabled = val),
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.language,
            iconColor: Color(0xFF455A64),
            iconBg: Color(0xFFECEFF1),
            title: 'Language',
            subtitle: 'English (US)',
            onTap: _showLanguageDialog,
          ),
          Divider(height: 1, indent: 64),
          _buildSettingsTile(
            icon: Icons.help_outline,
            iconColor: Color(0xFF455A64),
            iconBg: Color(0xFFECEFF1),
            title: 'Help & Support',
            onTap: _showHelpDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor ?? AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing else Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkersSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService.fetchWorkers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Error loading workers: ${snapshot.error}',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        final workers = snapshot.data ?? [];
        final farmers = workers.where((w) => w['role'] == 'FARMER').toList();

        if (farmers.isEmpty) {
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text('No farmers found', style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              farmers.length,
              (index) {
                final worker = farmers[index];
                final isLast = index == farmers.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFFC8E6C9),
                            child: Text(
                              worker['full_name']?.substring(0, 1).toUpperCase() ?? '?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker['full_name'] ?? 'Unknown',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                                Text(
                                  worker['email'] ?? 'No email',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 1, indent: 64),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        setState(() => _isLoading = true);
        await Future.delayed(Duration(seconds: 1)); // Mock delay
        await AuthService.logout();
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFFFCDD2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
               SizedBox(
                 width: 20,
                 height: 20,
                 child: CircularProgressIndicator(color: Color(0xFFD32F2F), strokeWidth: 2),
               )
            else ...[
              Icon(Icons.logout, color: Color(0xFFD32F2F), size: 20),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Dialog Helpers
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name', hintText: 'Alex Morgan')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Email', hintText: 'alex@locust.farm')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Save')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Current Password'), obscureText: true),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'New Password'), obscureText: true),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Confirm Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Update')),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text('English (US)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text('Fran�ais'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text('Espa�ol'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Text('For assistance, please contact our support team at support@locust.farm or call +1-800-LOCUST.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showSliderDialog(String title, String unit, double min, double max, double current) {
    double tempValue = current;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(' ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: tempValue,
                    min: min,
                    max: max,
                    divisions: 100,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => tempValue = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Set')),
              ],
            );
          },
        );
      },
    );
  }
}
