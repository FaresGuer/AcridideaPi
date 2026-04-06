import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../app_colors.dart';
import '../../models/auth_user.dart';
import '../../models/container.dart' as app_models;
import '../../services/auth_service.dart';
import '../../services/container_service.dart';
import '../auth/login_screen.dart';
import '../container/container_router.dart';

class AccountManagementScreen extends StatefulWidget {
  final int? initialTab;
  
  const AccountManagementScreen({super.key, this.initialTab});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with TickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _twoFactorEnabled = false;
  bool _isLoading = false;
  late bool _isAdminView;
  late AnimationController _controller;
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _workersFuture;
  late Future<List<app_models.Container>> _containersFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _isAdminView = AuthService.currentUser.value?.role == 'ADMIN';
    _twoFactorEnabled = AuthService.currentUser.value?.twoFactorEnabled ?? false;
    _tabController = TabController(
      length: _isAdminView ? 3 : 1,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _initializeAdminFutures();
  }

  void _initializeAdminFutures() {
    if (!_isAdminView) {
      _workersFuture = Future.value([]);
      _containersFuture = Future.value([]);
      return;
    }

    _workersFuture = AuthService.fetchWorkers();
    _containersFuture = AuthService.fetchContainers();
  }

  void _refreshWorkers() {
    if (!mounted) return;
    setState(() {
      _workersFuture = AuthService.fetchWorkers();
    });
  }

  void _refreshContainers() {
    if (!mounted) return;
    setState(() {
      _containersFuture = AuthService.fetchContainers();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {
        final isAdmin = _isAdminView;
        
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
              child: Column(
                children: [
                  // Header and Profile Card
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildAnimatedItem(0, _buildHeader()),
                        ],
                      ),
                    ),
                  ),
                  // Tab Bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: [
                        Tab(text: 'Settings'),
                        if (isAdmin) Tab(text: 'Workers'),
                        if (isAdmin) Tab(text: 'Containers'),
                      ],
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Settings Tab
                        SingleChildScrollView(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
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
                              SizedBox(height: 32),
                              _buildAnimatedItem(8, _buildLogoutButton()),
                              SizedBox(height: 32),
                              _buildAnimatedItem(9, Center(
                                child: Text(
                                  'Version 2.4.0 (Build 394)',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              )),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                        // Workers Tab (Admin only)
                        if (isAdmin)
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: _buildWorkersSection(),
                          ),
                        // Containers Tab (Admin only)
                        if (isAdmin)
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: _buildContainersListSection(),
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
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? 'alex.morgan@locust.farm',
                  style: TextStyle(
                    fontSize: 13, 
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
            icon: Icons.notifications_active,
            iconColor: Color(0xFF7B1FA2),
            iconBg: Color(0xFFF3E5F5),
            title: 'Push Notifications',
            subtitle: _pushNotifications ? 'Instant alerts enabled' : 'Notifications disabled',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
              thumbColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) => AppColors.primary,
              ),
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
              onChanged: _isLoading ? null : _handleTwoFactorToggle,
              thumbColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) => AppColors.primary,
              ),
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
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withOpacity(0.1),
            title: 'Change Container',
            subtitle: ContainerService.selectedContainer.value?.name ?? 'None selected',
            onTap: () {
              // Clear selection and navigate to container router
              ContainerService.clearSelection();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ContainerRouter()),
              );
            },
          ),
          Divider(height: 1, indent: 64),
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
    return Column(
      children: [
        // Add Worker Button
        ElevatedButton.icon(
          onPressed: _showAddWorkerDialog,
          icon: Icon(Icons.add),
          label: Text('Add Worker'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 24),
        // Workers List
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _workersFuture,
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
                  'Error loading workers: ${_humanizeError(snapshot.error!)}',
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
                        InkWell(
                          onTap: () => _showWorkerActionsDialog(worker),
                          child: Padding(
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
                                Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
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
        ),
        SizedBox(height: 40), // Bottom padding
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        if (_isLoading) return;

        setState(() => _isLoading = true);
        try {
          await AuthService.logout();
          ContainerService.clearSelection();  // Clear selected container
          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
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
  Widget _buildContainersListSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Back to Container Selection Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                // Clear current container selection and navigate back to selection screen
                ContainerService.clearSelection();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ContainerRouter()),
                  (route) => false,
                );
              },
              icon: Icon(Icons.grid_view_rounded, size: 20),
              label: Text('Back to Container Selection'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Add Container Button
          ElevatedButton.icon(
            onPressed: _showAddContainerDialog,
            icon: Icon(Icons.add),
            label: Text('Add Container'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 24),
          // Containers List
          FutureBuilder<List<app_models.Container>>(
            future: _containersFuture,
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
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                    'Error loading containers: ${_humanizeError(snapshot.error!)}',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                );
              }

              final containers = snapshot.data ?? [];

              if (containers.isEmpty) {
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
                    child: Text('No containers found', style: TextStyle(color: AppColors.textSecondary)),
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
                    containers.length,
                    (index) {
                      final container = containers[index];
                      final isLast = index == containers.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _showContainerWorkersDialog(container),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFBBDEFB),
                                    child: Icon(Icons.location_on, color: AppColors.primary),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          container.name,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                        ),
                                        Text(
                                          'Lat: ${container.latitude.toStringAsFixed(4)}, Lng: ${container.longitude.toStringAsFixed(4)}',
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                ],
                              ),
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
          ),
          SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  void _showContainerWorkersDialog(app_models.Container container) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${container.name} Workers'),
        content: SizedBox(
          width: 320,
          child: container.workers.isEmpty
              ? Center(
                  child: Text(
                    'No workers assigned',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: container.workers.length,
                  itemBuilder: (context, index) {
                    final worker = container.workers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFC8E6C9),
                        child: Text(
                          worker.fullName.isNotEmpty ? worker.fullName.substring(0, 1).toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      title: Text(worker.fullName),
                      subtitle: Text(worker.email),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final currentUser = AuthService.currentUser.value;
    final fullNameController = TextEditingController(text: currentUser?.fullName ?? '');
    final emailController = TextEditingController(text: currentUser?.email ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name', hintText: 'Alex Morgan'),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email', hintText: 'alex@locust.farm'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final fullName = fullNameController.text.trim();
                        final email = emailController.text.trim();

                        if (fullName.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Full name and email are required')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await AuthService.updateProfile(fullName: fullName, email: email);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Profile updated successfully')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Error: ${_humanizeError(e)}')),
                          );
                        } finally {
                          if (mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final currentPassword = currentPasswordController.text.trim();
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword = confirmPasswordController.text.trim();

                        if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('All password fields are required')),
                          );
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('New password and confirmation do not match')),
                          );
                          return;
                        }

                        if (newPassword.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('New password must be at least 6 characters')),
                          );
                          return;
                        }

                        setDialogState(() => isUpdating = true);
                        try {
                          await AuthService.changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                          );
                          if (!mounted || !context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Password changed successfully')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Error: ${_humanizeError(e)}')),
                          );
                        } finally {
                          if (mounted && context.mounted) {
                            setDialogState(() => isUpdating = false);
                          }
                        }
                      },
                child: isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleTwoFactorToggle(bool enabled) async {
    final previous = _twoFactorEnabled;
    setState(() {
      _twoFactorEnabled = enabled;
      _isLoading = true;
    });

    try {
      await AuthService.updateTwoFactorEnabled(enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Two-Factor Authentication ${enabled ? 'enabled' : 'disabled'}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _twoFactorEnabled = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_humanizeError(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _showAddWorkerDialog() async {
    final emailController = TextEditingController();
    bool isSending = false;

    final wasAdded = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Invite Worker',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the email address of the worker you want to invite to your team.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'worker@locust.farm',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      errorText: emailController.text.isNotEmpty && !emailController.text.contains('@')
                          ? 'Please enter a valid email'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSending || emailController.text.isEmpty || !emailController.text.contains('@')
                    ? null
                    : () async {
                        setDialogState(() => isSending = true);
                        final email = emailController.text.trim();

                        try {
                          await AuthService.sendWorkerInvitationByEmail(email: email);
                          if (!mounted) return;

                          Navigator.pop(context, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Invitation sent to $email successfully!')),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() => isSending = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${_humanizeError(e)}')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Send Invite'),
              ),
            ],
          );
        });
      },
    );

    if (wasAdded == true) {
      _refreshWorkers();
    }
  }

  Future<void> _showAddContainerDialog() async {
    final wasCreated = await showDialog<bool>(
      context: context,
      builder: (context) => _AddContainerMapDialog(),
    );

    if (wasCreated == true) {
      _refreshContainers();
    }
  }

  Future<void> _showWorkerActionsDialog(Map<String, dynamic> worker) async {
    final workerId = (worker['id'] ?? worker['worker_id']) as int?;
    final workerName = (worker['full_name'] ?? worker['name'] ?? 'Unknown') as String;

    if (workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Worker ID not found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage worker assignments',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showAssignWorkerToContainerDialog(workerId, workerName);
            },
            child: Text('Assign to Container'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmRemoveWorkerRelationship(workerId, workerName);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('End Collaboration'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignWorkerToContainerDialog(int workerId, String workerName) async {
    Future<List<app_models.Container>> dialogContainersFuture = _containersFuture;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Color(0xFFE0F7FA), // Light teal for container
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_ind_rounded, color: Color(0xFF00796B), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Container',
                        style: TextStyle(
                          color: Color(0xFF00796B),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'For $workerName',
                        style: TextStyle(
                          color: Color(0xFF004D40),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 340,
            height: 400,
            child: Column(
              children: [
                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search containers...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    // Implement filter logic if needed
                  },
                ),
                SizedBox(height: 16),
                // List of Containers
                Expanded(
                  child: FutureBuilder<List<app_models.Container>>(
                    future: dialogContainersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading containers', style: TextStyle(color: Colors.red)));
                      }

                      final containers = snapshot.data ?? [];

                      if (containers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                              SizedBox(height: 12),
                              Text('No containers available', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: containers.length,
                        separatorBuilder: (context, index) => SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final container = containers[index];
                          final isAssignedToWorker = container.workers.any((worker) => worker.id == workerId);

                          return Container(
                            decoration: BoxDecoration(
                              color: isAssignedToWorker ? Color(0xFFE8F5E9) : Colors.white,
                              border: Border.all(
                                color: isAssignedToWorker ? Color(0xFF66BB6A) : Colors.grey[300]!,
                                width: isAssignedToWorker ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (isAssignedToWorker) {
                                     // Unassign confirmation
                                     final shouldUnassign = await showDialog<bool>(
                                       context: context,
                                       builder: (context) => AlertDialog(
                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                         title: Text('Unassign Worker?'),
                                         content: Text('Are you sure you want to unassign $workerName from ${container.name}?'),
                                         actions: [
                                           TextButton(
                                             onPressed: () => Navigator.pop(context, false),
                                             child: Text('Cancel'),
                                           ),
                                           TextButton(
                                             onPressed: () => Navigator.pop(context, true),
                                             style: TextButton.styleFrom(foregroundColor: Colors.red),
                                             child: Text('Unassign'),
                                           ),
                                         ],
                                       ),
                                     ) ?? false;

                                     if (!shouldUnassign) return;
                                     await _unassignWorkerFromContainer(workerId, container.id);
                                  } else {
                                     // Assign
                                     await _assignWorkerToContainer(workerId, container.id);
                                  }

                                  // Refresh data
                                  final refreshed = AuthService.fetchContainers();
                                  if (mounted) setState(() { _containersFuture = refreshed; });
                                  setDialogState(() { dialogContainersFuture = refreshed; });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isAssignedToWorker ? Colors.green[100] : Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isAssignedToWorker ? Icons.check_rounded : Icons.add_rounded,
                                          color: isAssignedToWorker ? Colors.green[700] : Colors.blue[700],
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              container.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              'lat: ${container.latitude.toStringAsFixed(2)}, lng: ${container.longitude.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isAssignedToWorker)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[600],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignWorkerToContainer(int workerId, int containerId) async {

    try {
      await AuthService.assignWorkerToContainer(
        containerId: containerId,
        workerId: workerId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker assigned to container successfully')),
      );
      _refreshContainers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_humanizeError(e)}')),
      );
    }
  }

  Future<void> _unassignWorkerFromContainer(int workerId, int containerId) async {
    try {
      await AuthService.removeWorkerFromContainer(
        containerId: containerId,
        workerId: workerId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker unassigned from container successfully')),
      );
      _refreshContainers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_humanizeError(e)}')),
      );
    }
  }

  Future<void> _removeWorkerRelationship(int workerId) async {
    try {
      await AuthService.removeWorkerInvitation(workerId: workerId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collaboration ended.')),
      );
      _refreshWorkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_humanizeError(e)}')),
      );
    }
  }

  Future<void> _confirmRemoveWorkerRelationship(int workerId, String workerName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Collaboration?'),
        content: Text(
          'This will remove $workerName from your team.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeWorkerRelationship(workerId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('End Collaboration'),
          ),
        ],
      ),
    );
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}

class _AddContainerMapDialog extends StatefulWidget {
  @override
  State<_AddContainerMapDialog> createState() => _AddContainerMapDialogState();
}

class _AddContainerMapDialogState extends State<_AddContainerMapDialog> {
  final nameController = TextEditingController();
  double? selectedLat;
  double? selectedLng;
  final MapController mapController = MapController();

  String _humanizeError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Container'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Container Name Input
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Container Name',
                hintText: 'e.g., Container A',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            // Map
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(36.8065, 10.1815), // Default to Tunis, Tunisia
                    initialZoom: 13.0,
                    onTap: (tapPos, latlng) {
                      setState(() {
                        selectedLat = latlng.latitude;
                        selectedLng = latlng.longitude;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.flutter_application_1',
                    ),
                    if (selectedLat != null && selectedLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(selectedLat!, selectedLng!),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            // Selected Coordinates Display
            if (selectedLat != null && selectedLng != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lat: ${selectedLat!.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Lng: ${selectedLng!.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tap on the map to select a location',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        ElevatedButton(
          onPressed: selectedLat == null || selectedLng == null || nameController.text.isEmpty
              ? null
              : () async {
                  final name = nameController.text.trim();
                  try {
                    await AuthService.createContainer(
                      name: name,
                      latitude: selectedLat!,
                      longitude: selectedLng!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Container "$name" created successfully')),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${_humanizeError(e)}')),
                    );
                  }
                },
          child: Text('Create'),
        ),
      ],
    );
  }
}

