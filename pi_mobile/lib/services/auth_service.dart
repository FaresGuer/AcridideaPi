import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import '../models/container.dart';
import '../models/worker_invitation.dart';

class AuthService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  static String? _token;

  static final ValueNotifier<AuthUser?> currentUser = ValueNotifier<AuthUser?>(null);

  static String? get token => _token;

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final tokenResponse = await http.post(
      Uri.parse('$_baseUrl/token'),
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception(_extractError(tokenResponse));
    }

    final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    _token = tokenJson['access_token'] as String?;

    if (_token == null) {
      throw Exception('Missing access token');
    }

    final meResponse = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (meResponse.statusCode != 200) {
      throw Exception(_extractError(meResponse));
    }

    final meJson = jsonDecode(meResponse.body) as Map<String, dynamic>;
    currentUser.value = AuthUser.fromJson(meJson);
  }

  static Future<void> register({
    required String email,
    required String fullName,
    required String password,
    String role = 'FARMER',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  static Future<void> updateUserRole(String newRole) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': newRole,
        'role_selected': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final updatedJson = jsonDecode(response.body) as Map<String, dynamic>;
    currentUser.value = AuthUser.fromJson(updatedJson);
  }

  static Future<void> logout() async {
    _token = null;
    currentUser.value = null;
  }

  static Future<List<Map<String, dynamic>>> fetchWorkers() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/workers/accepted'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> users = jsonDecode(response.body) as List<dynamic>;
    return users.cast<Map<String, dynamic>>();
  }

  // ==================== CONTAINER METHODS ====================

  static Future<List<Container>> fetchContainers() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/containers'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> containers = jsonDecode(response.body) as List<dynamic>;
    return containers
        .map((c) => Container.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Future<Container> createContainer({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/containers'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }

    final containerJson = jsonDecode(response.body) as Map<String, dynamic>;
    return Container.fromJson(containerJson);
  }

  static Future<Container> getContainer(int containerId) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/containers/$containerId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final containerJson = jsonDecode(response.body) as Map<String, dynamic>;
    return Container.fromJson(containerJson);
  }

  static Future<Container> updateContainer({
    required int containerId,
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http.put(
      Uri.parse('$_baseUrl/containers/$containerId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final containerJson = jsonDecode(response.body) as Map<String, dynamic>;
    return Container.fromJson(containerJson);
  }

  static Future<void> deleteContainer(int containerId) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/containers/$containerId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  static Future<Container> assignWorkerToContainer({
    required int containerId,
    required int workerId,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/containers/$containerId/workers/$workerId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final containerJson = jsonDecode(response.body) as Map<String, dynamic>;
    return Container.fromJson(containerJson);
  }

  static Future<Container> removeWorkerFromContainer({
    required int containerId,
    required int workerId,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/containers/$containerId/workers/$workerId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final containerJson = jsonDecode(response.body) as Map<String, dynamic>;
    return Container.fromJson(containerJson);
  }

  // ==================== WORKER INVITATION METHODS ====================

  static Future<WorkerInvitation> sendWorkerInvitationByEmail({
    required String email,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/worker-invitations'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }

    final invitationJson = jsonDecode(response.body) as Map<String, dynamic>;
    return WorkerInvitation.fromJson(invitationJson);
  }

  static Future<List<WorkerInvitation>> fetchReceivedInvitations() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/worker-invitations/received'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> invitations = jsonDecode(response.body) as List<dynamic>;
    return invitations
        .map((inv) => WorkerInvitation.fromJson(inv as Map<String, dynamic>))
        .toList();
  }

  static Future<WorkerInvitation> respondToInvitation({
    required int invitationId,
    required String action,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/worker-invitations/$invitationId/respond'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final invitationJson = jsonDecode(response.body) as Map<String, dynamic>;
    return WorkerInvitation.fromJson(invitationJson);
  }

  static String _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}
