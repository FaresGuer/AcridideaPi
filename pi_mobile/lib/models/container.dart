import 'auth_user.dart';

class Container {
  final int id;
  final String name;
  final int createdBy;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthUser creator;
  final List<AuthUser> workers;
  final ContainerData? data;

  Container({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
    required this.workers,
    this.data,
  });

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      id: json['id'] as int,
      name: json['name'] as String,
      createdBy: json['created_by'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: AuthUser.fromJson(json['creator'] as Map<String, dynamic>),
      workers: (json['workers'] as List<dynamic>)
          .map((w) => AuthUser.fromJson(w as Map<String, dynamic>))
          .toList(),
      data: json['data'] != null ? ContainerData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_by': createdBy,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'creator': creator,
    'workers': workers,
    'data': data?.toJson(),
  };
}

class ContainerData {
  final double? temperature;
  final double? humidity;

  ContainerData({this.temperature, this.humidity});

  factory ContainerData.fromJson(Map<String, dynamic> json) {
    return ContainerData(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
  };
}
