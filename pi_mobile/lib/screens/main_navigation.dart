import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/role_selection_dialog.dart';
import 'home/dashboard_screen.dart';
import 'controls/device_controls_screen.dart';
import 'food/food_distribution_screen.dart';
import 'account/account_management_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    DeviceControlsScreen(),
    FoodDistributionScreen(),
    AccountManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen for login events and show role selection dialog if needed
    AuthService.currentUser.addListener(_handleAuthStateChange);
    // Schedule the dialog to show after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRoleSelectionDialogIfNeeded();
    });
  }

  void _handleAuthStateChange() {
    // Show dialog again if a new user logs in without having selected role
    _showRoleSelectionDialogIfNeeded();
  }

  @override
  void dispose() {
    AuthService.currentUser.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _showRoleSelectionDialogIfNeeded() {
    final currentUser = AuthService.currentUser.value;
    // Only show dialog if user exists and hasn't selected role yet
    if (currentUser != null && !currentUser.roleSelected) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RoleSelectionDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Controls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
