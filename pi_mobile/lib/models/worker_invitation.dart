import 'auth_user.dart';

class WorkerInvitation {
  final int id;
  final int adminId;
  final int workerId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final AuthUser admin;
  final AuthUser worker;

  const WorkerInvitation({
    required this.id,
    required this.adminId,
    required this.workerId,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
    required this.admin,
    required this.worker,
  });

  bool get isPending => status == 'PENDING';

  factory WorkerInvitation.fromJson(Map<String, dynamic> json) {
    return WorkerInvitation(
      id: json['id'] as int,
      adminId: json['admin_id'] as int,
      workerId: json['worker_id'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
      admin: AuthUser.fromJson(json['admin'] as Map<String, dynamic>),
      worker: AuthUser.fromJson(json['worker'] as Map<String, dynamic>),
    );
  }
}
