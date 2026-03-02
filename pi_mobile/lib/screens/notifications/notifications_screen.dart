import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/worker_invitation.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<WorkerInvitation>> _invitationsFuture;
  int? _processingInvitationId;

  @override
  void initState() {
    super.initState();
    _invitationsFuture = AuthService.fetchReceivedInvitations();
  }

  Future<void> _refreshInvitations() async {
    setState(() {
      _invitationsFuture = AuthService.fetchReceivedInvitations();
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
      body: user?.role != 'FARMER'
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Worker invitation notifications are shown for farmer accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshInvitations,
              child: FutureBuilder<List<WorkerInvitation>>(
                future: _invitationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      children: [
                        SizedBox(height: 220),
                        Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      padding: EdgeInsets.all(24),
                      children: [
                        Text(
                          'Failed to load notifications: ${snapshot.error}',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshInvitations,
                          child: Text('Retry'),
                        ),
                      ],
                    );
                  }

                  final invitations = snapshot.data ?? [];

                  if (invitations.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: 180),
                        Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No invitation notifications',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
                      final isPending = invitation.status == 'PENDING';
                      final isProcessing = _processingInvitationId == invitation.id;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
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
                    },
                  );
                },
              ),
            ),
    );
  }
}
