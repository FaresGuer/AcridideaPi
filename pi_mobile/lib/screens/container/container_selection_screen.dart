import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/container_service.dart';
import '../../models/container.dart' as models;
import 'no_container_page.dart';
import '../notifications/notifications_screen.dart';

class ContainerSelectionScreen extends StatefulWidget {
  const ContainerSelectionScreen({super.key});

  @override
  State<ContainerSelectionScreen> createState() => _ContainerSelectionScreenState();
}

class _ContainerSelectionScreenState extends State<ContainerSelectionScreen> {
  late Future<List<models.Container>> _containersFuture;
  final _user = AuthService.currentUser.value;
  Future<int>? _pendingInvitesFuture;

  @override
  void initState() {
    super.initState();
    _loadContainers();
    if (_user?.role == 'FARMER') {
      _pendingInvitesFuture = _loadPendingInviteCount();
    }
  }

  void _loadContainers() {
    setState(() {
      _containersFuture = AuthService.fetchContainers();
    });
  }

  Future<int> _loadPendingInviteCount() async {
    final invitations = await AuthService.fetchReceivedInvitations();
    return invitations.where((invitation) => invitation.status == 'PENDING').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Container',
                              style: TextStyle(color: Colors.black,fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _user?.role == 'ADMIN' 
                                  ? 'Choose a container to manage'
                                  : 'Choose an assigned container',
                              style: TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (_user?.role == 'FARMER')
                        FutureBuilder<int>(
                          future: _pendingInvitesFuture,
                          builder: (context, snapshot) {
                            final pendingCount = snapshot.data ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.notifications_outlined, color: AppColors.primary),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => NotificationsScreen()),
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _pendingInvitesFuture = _loadPendingInviteCount();
                                    });
                                  },
                                ),
                                if (pendingCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: BoxConstraints(minWidth: 18),
                                      child: Text(
                                        pendingCount > 99 ? '99+' : '$pendingCount',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Container List
            Expanded(
              child: FutureBuilder<List<models.Container>>(
                future: _containersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          SizedBox(height: 16),
                          Text('Error loading containers', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text(snapshot.error.toString(), style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  final containers = snapshot.data ?? [];

                  if (containers.isEmpty) {
                    // No containers - show empty state page
                    return NoContainerPage();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: containers.length,
                    itemBuilder: (context, index) {
                      final container = containers[index];
                      return _buildContainerCard(container);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerCard(models.Container container) {
    final workerCount = container.workers.length;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Select container - main.dart's ValueListenableBuilder will handle navigation
          ContainerService.selectContainer(container);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2, color: AppColors.primary, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          container.name,
                          style: TextStyle(color: Colors.black,fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Created by ${container.creator.fullName}',
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    '$workerCount worker${workerCount != 1 ? 's' : ''} assigned',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    '${container.latitude.toStringAsFixed(4)}, ${container.longitude.toStringAsFixed(4)}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
