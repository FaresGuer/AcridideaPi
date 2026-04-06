import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/container_service.dart';
import '../../models/container.dart' as models;
import 'no_container_page.dart';
import 'add_container_dialog.dart';
import '../account/account_management_screen.dart';

class ContainerSelectionScreen extends StatefulWidget {
  const ContainerSelectionScreen({super.key});

  @override
  State<ContainerSelectionScreen> createState() => _ContainerSelectionScreenState();
}

class _ContainerSelectionScreenState extends State<ContainerSelectionScreen> {
  late Future<List<models.Container>> _containersFuture;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  void _loadContainers() {
    setState(() {
      _containersFuture = AuthService.fetchContainers();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildProfileButton(context),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<models.Container>>(
                future: _containersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading containers'));
                  }
                  final containers = snapshot.data ?? [];
                  if (containers.isEmpty) {
                    return NoContainerPage();
                  }
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.60,
                    ),
                    itemCount: containers.length,
                    itemBuilder: (context, index) {
                      final container = containers[index];
                      // ...existing code...
                      return _ContainerGridCard(
                        container: container,
                        index: index,
                        // isWarning removed as it's calculated internally
                        imageAsset: 'assets/images/locust_camera.jpg',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const AddContainerMapDialog(),
          );
          if (result == true) {
            _loadContainers();
          }
        },
        backgroundColor: Color(0xFF00C853),
        shape: CircleBorder(),
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _ContainerGridCard extends StatelessWidget {
  final models.Container container;
  final int index;
  final String? imageAsset;

  const _ContainerGridCard({
    required this.container,
    required this.index,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    // Use real data from backend, fallback to safe defaults if not yet populated
    final temp = container.data?.temperature ?? 25.0;
    final hum = container.data?.humidity ?? 60.0;
    final sector = (index % 4) + 1;
    // Mock last updated for now, or use updatedAt difference
    final minsAgo = DateTime.now().difference(container.updatedAt).inMinutes.abs();
    final displayMins = minsAgo > 60 ? '${(minsAgo/60).floor()}h' : '${minsAgo}m';

    // Status Logic
    String status = 'ACTIVE';
    Color statusColor = const Color(0xFF00C853);
    bool isCritical = false;

    if (temp > 35 || hum < 30 || hum > 85) {
      status = 'CRITICAL';
      statusColor = AppColors.error;
      isCritical = true;
    } else if (temp > 28 || hum > 70) {
      status = 'WARNING';
      statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        ContainerService.selectContainer(container);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                    child: imageAsset != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(imageAsset!, fit: BoxFit.cover),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(Icons.eco, size: 48, color: Color(0xFFE2E8F0)),
                          )
                        ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25), // Darker shadow for depth
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCritical ? Icons.error_outline : (status == 'WARNING' ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Color.fromARGB(60, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          container.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Sector $sector',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: $displayMins ago',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Divider
                    Container(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                      margin: EdgeInsets.symmetric(vertical: 2),
                    ),

                    const SizedBox(height: 2),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric('TEMP', '${temp.toStringAsFixed(0)}°C',
                            isCritical || (status == 'WARNING' && temp > 28) ? statusColor : const Color(0xFF00C853)),
                        _buildMetric('HUM', '${hum.toStringAsFixed(0)}%',
                            isCritical || (status == 'WARNING' && (hum > 70 || hum < 30)) ? statusColor : const Color(0xFF00C853)),
                      ],
                    ),

                    const Spacer(),

                    // Action Link
                    Row(
                      children: [
                        Text(
                          status == 'ACTIVE' ? 'Details' : (status == 'CRITICAL' ? 'Take Action' : 'Review Alerts'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
