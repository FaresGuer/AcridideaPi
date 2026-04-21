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
    final isAdmin = user?.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: Color(0xFFF5F9F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Containers',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your farming units',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isAdmin) ...[
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
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 460),
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          isAdmin ? 'No Containers Yet' : 'No Assigned Containers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          isAdmin
                              ? 'Create your first container to start monitoring your locust farm.'
                              : 'You have not been assigned to any containers yet. Contact your administrator.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isAdmin) ...[
                          SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () {
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
                              backgroundColor: Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
