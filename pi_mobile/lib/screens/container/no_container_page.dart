import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../notifications/notifications_screen.dart';
import '../account/account_management_screen.dart';

class NoContainerPage extends StatelessWidget {
  const NoContainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser.value;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header with notification button (workers only)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Expanded(
                    child: Text(
                      'Locust Farm',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isAdmin) ...[
                    // Notifications button for workers
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationsScreen()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFE3E8EF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_outlined, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AccountManagementScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3E8EF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Empty state content
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 32),
                      Text(
                        isAdmin ? 'No Containers Yet' : 'No Assigned Containers',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        isAdmin
                            ? 'Create your first container to start monitoring your locust farm.'
                            : 'You haven\'t been assigned to any containers yet. Contact your administrator.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to account/containers tab
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountManagementScreen(initialTab: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.add),
                          label: Text('Create Container'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
