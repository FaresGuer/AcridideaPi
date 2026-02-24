import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/auth_service.dart';
import 'home/new_dashboard_screen.dart';
import 'auth/role_selection_dialog.dart';
import 'controls/device_controls_screen.dart';
import 'food/food_screen_v2.dart';
import 'account/account_management_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

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
    final List<Widget> screens = [
      DashboardScreen(),
      DeviceControlsScreen(),
      FoodDistributionScreen(),
      AccountManagementScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 100, // Taller to accommodate the curve and FAB
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Custom shape background
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home, Icons.home_outlined, 'Home'),
                  _buildNavItem(1, Icons.tune, Icons.tune_outlined, 'Controls'),
                  SizedBox(width: 56), // Space for FAB
                  _buildNavItem(2, Icons.calendar_today, Icons.calendar_today_outlined, 'Schedule'),
                  _buildNavItem(3, Icons.person, Icons.person_outlined, 'Profile'),
                ],
              ),
            ),
            // Floating Action Button
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                   setState(() => _selectedIndex = 2); // Food screen
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    // Mapping:
    // UI Index 0 (Home) -> Screen 0
    // UI Index 1 (Controls) -> Screen 1
    // UI Center (Food) -> Screen 2
    // UI Index 2 (Schedule) -> Placeholder (Let's map to same as Food for now or handle separately)
    // UI Index 3 (Profile) -> Screen 3 (Account)

    int targetScreenIndex = index;
    // Visually:
    // 0: Home -> Screen 0
    // 1: Controls -> Screen 1
    // 2: Schedule -> Screen 2 (Food Distribution)
    // 3: Profile -> Screen 3 (Account)

    final isSelected = _selectedIndex == targetScreenIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = targetScreenIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.darkGreen : AppColors.textHint,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.darkGreen : AppColors.textHint,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
