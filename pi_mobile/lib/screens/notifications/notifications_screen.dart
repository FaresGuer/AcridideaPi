import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/worker_invitation.dart';
import '../../models/container.dart' as models;
import '../../services/auth_service.dart';
import '../../services/container_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<WorkerInvitation>> _invitationsFuture;
  late Future<List<models.Container>> _containersFuture;
  int? _processingInvitationId;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _invitationsFuture = AuthService.fetchReceivedInvitations();
    _containersFuture = AuthService.fetchContainers();
  }

  Future<void> _refreshInvitations() async {
    setState(() {
      _refreshData();
    });
  }

  Future<void> _respondToInvitation({
    required int invitationId,
    required String action,
  }) async {
    setState(() {
      _processingInvitationId = invitationId;
    });

    try {
      await AuthService.respondToInvitation(
        invitationId: invitationId,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'ACCEPT'
                ? 'Invitation accepted'
                : 'Invitation rejected',
          ),
        ),
      );
      await _refreshInvitations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingInvitationId = null;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Notifications'),
        elevation: 0.5,
      ),
      body: RefreshIndicator(
              onRefresh: _refreshInvitations,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // System Alerts Section
                    FutureBuilder<List<models.Container>>(
                      future: _containersFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox.shrink();

                        final alerts = <Widget>[];
                        for (final container in snapshot.data!) {
                          final temp = container.data?.temperature ?? 0;
                          final hum = container.data?.humidity ?? 0;

                          if (temp > 35 || hum < 30 || hum > 85) {
                            alerts.add(_buildAlertCard(container, 'CRITICAL'));
                          } else if (temp > 28 || hum > 70) {
                            alerts.add(_buildAlertCard(container, 'WARNING'));
                          }
                        }

                        if (alerts.isEmpty) return SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text('System Alerts', style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87
                              )),
                            ),
                            ...alerts,
                          ],
                        );
                      },
                    ),

                    // Invitations Section (Only for Farmers)
                    if (user?.role == 'FARMER')
                      FutureBuilder<List<WorkerInvitation>>(
                        future: _invitationsFuture,
                        builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                            }
                            final invitations = snapshot.data ?? [];
                            if (invitations.isEmpty) return SizedBox.shrink(); // Don't show empty if no invitations

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text('Invitations', style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87
                                  )),
                                ),
                                ...invitations.map((invitation) => _buildInvitationCard(invitation)),
                              ],
                            );
                        },
                      ),

                     SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlertCard(models.Container container, String type) {
    final isCritical = type == 'CRITICAL';
    final color = isCritical ? AppColors.error : Colors.orange;
    final temp = container.data?.temperature ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCritical ? Icons.warning_rounded : Icons.info_outline, color: color),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$type: ${container.name}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isCritical
                        ? 'Temperature ($temp°C) exceeds critical limit!'
                        : 'Environmental conditions require review.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ContainerService.selectContainer(container);
                Navigator.pop(context); // Go back to dashboard/selection
              },
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: color.withOpacity(0.1),
              ),
              child: Text(isCritical ? 'Take Action' : 'Check Alerts'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(WorkerInvitation invitation) {
      final isPending = invitation.status == 'PENDING';
      final isProcessing = _processingInvitationId == invitation.id;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending ? AppColors.primary.withOpacity(0.25) : Colors.grey.shade200,
          ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                    children: [
                    Icon(
                        Icons.mail_outline,
                        color: isPending ? AppColors.primary : AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                        '${invitation.admin.fullName} invited you to join as a worker',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isPending ? FontWeight.w700 : FontWeight.w500,
                        ),
                        ),
                    ),
                    ],
                ),
                SizedBox(height: 8),
                Text(
                    'Sent at: ${_formatDate(invitation.createdAt)}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                SizedBox(height: 8),
                Text(
                    'Status: ${invitation.status}',
                    style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: invitation.status == 'ACCEPTED'
                        ? Colors.green
                        : invitation.status == 'REJECTED'
                            ? Colors.red
                            : AppColors.primary,
                    ),
                ),
                if (isPending) ...[
                    SizedBox(height: 12),
                    Row(
                    children: [
                        Expanded(
                        child: OutlinedButton(
                            onPressed: isProcessing
                                ? null
                                : () => _respondToInvitation(
                                    invitationId: invitation.id,
                                    action: 'REJECT',
                                    ),
                            child: Text('Reject'),
                        ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                        child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () => _respondToInvitation(
                                    invitationId: invitation.id,
                                    action: 'ACCEPT',
                                    ),
                            style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            ),
                            child: isProcessing
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                    ),
                                )
                                : Text('Accept'),
                        ),
                        ),
                    ],
                    ),
                ],
            ],
        ),
      );
  }
}
