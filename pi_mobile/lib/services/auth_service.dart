import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_db_service.dart';
import '../models/auth_user.dart';
import '../models/container.dart';
import '../models/worker_invitation.dart';

class LoginResult {
  final bool requiresTwoFactor;
  final String? verificationToken;
  final String? message;

  const LoginResult({
    required this.requiresTwoFactor,
    this.verificationToken,
    this.message,
  });
}

class AuthService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  static String get _mobileBackendBaseUrl {
    if (kIsWeb) return 'http://localhost:8001';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8001';
    } catch (_) {}
    return 'http://localhost:8001';
  }

  static String? _token;

  static final ValueNotifier<AuthUser?> currentUser = ValueNotifier<AuthUser?>(null);

  static String? get token => _token;

  static Future<http.Response> _withTimeout(
    Future<http.Response> request,
    String action,
  ) {
    return request.timeout(
      _requestTimeout,
      onTimeout: () => throw Exception('$action timed out. Please try again.'),
    );
  }

  /// Initialize authentication - load saved session if available
  static Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        await _loadCurrentUser();
      }
    } catch (e) {
      // Clear invalid token
      _token = null;
      currentUser.value = null;
    }
  }

  /// Save token to SharedPreferences and load current user
  static Future<void> _saveTokenAndLoadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      await _loadCurrentUser();
    } catch (e) {
      // Clear invalid token on error
      _token = null;
      currentUser.value = null;
      rethrow;
    }
  }

  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final tokenResponse = await _withTimeout(
      http.post(
        Uri.parse('$_baseUrl/token'),
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': password,
        },
      ),
      'Sign in request',
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception(_extractError(tokenResponse));
    }

    final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final requiresTwoFactor = tokenJson['requires_two_factor'] as bool? ?? false;

    if (requiresTwoFactor) {
      return LoginResult(
        requiresTwoFactor: true,
        verificationToken: tokenJson['verification_token'] as String?,
        message: tokenJson['message'] as String?,
      );
    }

    _token = tokenJson['access_token'] as String?;

    if (_token == null) {
      throw Exception('Missing access token');
    }

    await _saveTokenAndLoadUser();
    return const LoginResult(requiresTwoFactor: false);
  }

  static Future<void> verifyTwoFactorLogin({
    required String verificationToken,
    required String code,
  }) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse('$_baseUrl/token/verify-2fa'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'verification_token': verificationToken,
          'code': code,
        }),
      ),
      'Two-factor verification',
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final tokenJson = jsonDecode(response.body) as Map<String, dynamic>;
    _token = tokenJson['access_token'] as String?;

    if (_token == null) {
      throw Exception('Missing access token');
    }

    await _saveTokenAndLoadUser();
  }

  static Future<void> _loadCurrentUser() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final meResponse = await _withTimeout(
      http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ),
      'Loading user profile',
    );

    if (meResponse.statusCode != 200) {
      throw Exception(_extractError(meResponse));
    }

    final meJson = jsonDecode(meResponse.body) as Map<String, dynamic>;
    currentUser.value = AuthUser.fromJson(meJson);
  }

  static Future<void> updateProfile({
    required String fullName,
    required String email,
  }) async {
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
        'full_name': fullName,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final updatedJson = jsonDecode(response.body) as Map<String, dynamic>;
    currentUser.value = AuthUser.fromJson(updatedJson);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/users/me/change-password'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  static Future<void> updateTwoFactorEnabled(bool enabled) async {
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
        'two_factor_enabled': enabled,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final updatedJson = jsonDecode(response.body) as Map<String, dynamic>;
    currentUser.value = AuthUser.fromJson(updatedJson);
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
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      // Silently fail if unable to clear session
    }
  }

  static Future<http.Response> _getWithWorkerFallback(String path) async {
    final primary = await _withTimeout(
      http.get(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ),
      'Loading data',
    );

    if (primary.statusCode == 404) {
      return _withTimeout(
        http.get(
          Uri.parse('$_mobileBackendBaseUrl$path'),
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
        'Loading fallback data',
      );
    }

    return primary;
  }

  static Future<http.Response> _postWithWorkerFallback(String path, {Object? body}) async {
    final primary = await _withTimeout(
      http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: body,
      ),
      'Saving data',
    );

    if (primary.statusCode == 404) {
      return _withTimeout(
        http.post(
          Uri.parse('$_mobileBackendBaseUrl$path'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: body,
        ),
        'Saving fallback data',
      );
    }

    return primary;
  }

  static Future<http.Response> _deleteWithWorkerFallback(String path) async {
    final primary = await _withTimeout(
      http.delete(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ),
      'Deleting data',
    );

    if (primary.statusCode == 404) {
      return _withTimeout(
        http.delete(
          Uri.parse('$_mobileBackendBaseUrl$path'),
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
        'Deleting fallback data',
      );
    }

    return primary;
  }

  static Future<List<Map<String, dynamic>>> fetchWorkers() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await _getWithWorkerFallback('/admin/workers/accepted');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> users = jsonDecode(response.body) as List<dynamic>;
    return users.map((user) {
      if (user is Map<String, dynamic>) {
        return user;
      } else if (user is Map) {
        return Map<String, dynamic>.from(user);
      } else {
        throw FormatException('Invalid user format: ${user.runtimeType}');
      }
    }).toList();
  }

  // ==================== CONTAINER METHODS ====================

  static Future<List<Container>> fetchContainers() async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await _withTimeout(
      http.get(
        Uri.parse('$_baseUrl/containers'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ),
      'Loading containers',
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

  static Future<void> assignWorkerToContainer({
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
  }

  static Future<void> removeWorkerFromContainer({
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
  }

  static Future<Map<String, dynamic>> fetchContainerData({
    required int containerId,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    // Prefer local MySQL reads if available
    try {
      final local = await LocalDbService().fetchContainerData(containerId);
      if (local != null) return local;
    } catch (_) {}

    final response = await http.get(
      Uri.parse('$_baseUrl/containers/$containerId/data'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchContainerHistory({
    required int containerId,
    int limit = 120,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    // Prefer local MySQL history if available
    try {
      final local = await LocalDbService().fetchContainerHistory(containerId, limit: limit);
      if (local.isNotEmpty) return local;
    } catch (_) {}

    final response = await http.get(
      Uri.parse('$_baseUrl/containers/$containerId/history?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> updateContainerData({
    required int containerId,
    bool? fanStatus,
    bool? humidifierStatus,
    bool? heaterStatus,
    bool? lightStatus,
    double? targetTemperature,
    double? targetTemperatureMin,
    double? targetHumidity,
    double? targetHumidityMin,
    double? targetLightLevel,
    double? targetLightLevelMin,
    double? targetGasLevel,
    double? targetGasLevelMin,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final body = <String, dynamic>{};
    if (fanStatus != null) body['fan_status'] = fanStatus;
    if (humidifierStatus != null) body['humidifier_status'] = humidifierStatus;
    if (heaterStatus != null) body['heater_status'] = heaterStatus;
    if (lightStatus != null) body['light_status'] = lightStatus;
    if (targetTemperature != null) body['target_temperature'] = targetTemperature;
    if (targetTemperatureMin != null) body['target_temperature_min'] = targetTemperatureMin;
    if (targetHumidity != null) body['target_humidity'] = targetHumidity;
    if (targetHumidityMin != null) body['target_humidity_min'] = targetHumidityMin;
    if (targetLightLevel != null) body['target_light_level'] = targetLightLevel;
    if (targetLightLevelMin != null) body['target_light_level_min'] = targetLightLevelMin;
    if (targetGasLevel != null) body['target_gas_level'] = targetGasLevel;
    if (targetGasLevelMin != null) body['target_gas_level_min'] = targetGasLevelMin;

    final response = await http.put(
      Uri.parse('$_baseUrl/containers/$containerId/data'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    // Mirror to local MySQL (best-effort) so mobile reads remain fast
    try {
      await LocalDbService().writeContainerData(containerId, body);
    } catch (_) {}

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchFeedingSchedules({
    required int containerId,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/containers/$containerId/feeding-schedules'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> createFeedingSchedule({
    required int containerId,
    required DateTime feedingAt,
    required double amount,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/containers/$containerId/feeding-schedules'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'feeding_at': feedingAt.toIso8601String(),
        'amount': amount,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateFeedingSchedule({
    required int containerId,
    required int scheduleId,
    DateTime? feedingAt,
    double? amount,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final body = <String, dynamic>{};
    if (feedingAt != null) body['feeding_at'] = feedingAt.toIso8601String();
    if (amount != null) body['amount'] = amount;

    final response = await http.put(
      Uri.parse('$_baseUrl/containers/$containerId/feeding-schedules/$scheduleId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> deleteFeedingSchedule({
    required int containerId,
    required int scheduleId,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/containers/$containerId/feeding-schedules/$scheduleId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  // ==================== WORKER INVITATION METHODS ====================

  static Future<WorkerInvitation> sendWorkerInvitationByEmail({
    required String email,
  }) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await _postWithWorkerFallback(
      '/worker-invitations',
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

    final response = await _getWithWorkerFallback('/worker-invitations/received');

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

    final response = await _postWithWorkerFallback(
      '/worker-invitations/$invitationId/respond',
      body: jsonEncode({'action': action}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final invitationJson = jsonDecode(response.body) as Map<String, dynamic>;
    return WorkerInvitation.fromJson(invitationJson);
  }

  static Future<void> removeWorkerInvitation({required int workerId}) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await _deleteWithWorkerFallback('/admin/workers/$workerId/revoke');

    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> resetPassword({
    required String resetToken,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reset_token': resetToken,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
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
