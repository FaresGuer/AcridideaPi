class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
