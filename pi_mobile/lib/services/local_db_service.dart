import 'dart:io';
import 'package:mysql1/mysql1.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;

  LocalDbService._internal();

  // Adjust defaults as needed for your environment
  final String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  final int port = 3306;
  final String user = 'root';
  final String password = '';
  final String db = 'locust_farm';

  Future<MySqlConnection> _connect() async {
    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
    return await MySqlConnection.connect(settings);
  }

  Future<Map<String, dynamic>?> fetchContainerData(int containerId) async {
    try {
      final conn = await _connect();
      final results = await conn.query(
        'SELECT * FROM container_data WHERE container_id = ?',
        [containerId],
      );
      await conn.close();

      if (results.isEmpty) return null;
      final row = results.first;
      return {
        'temperature': row['temperature'],
        'humidity': row['humidity'],
        'light_level': row['light_level'],
        'gas_level': row['gas_level'],
        'heater_status': row['heater_status'] == 1 || row['heater_status'] == true,
        'fan_status': row['fan_status'] == 1 || row['fan_status'] == true,
        'light_status': row['light_status'] == 1 || row['light_status'] == true,
        'humidifier_status': row['humidifier_status'] == 1 || row['humidifier_status'] == true,
        'target_temperature': row['target_temperature'],
        'target_humidity': row['target_humidity'],
        'target_light_level': row['target_light_level'],
        'target_gas_level': row['target_gas_level'],
        'target_temperature_min': row['target_temperature_min'],
        'target_humidity_min': row['target_humidity_min'],
        'target_light_level_min': row['target_light_level_min'],
        'target_gas_level_min': row['target_gas_level_min'],
        'last_updated': row['last_updated']?.toString(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchContainerHistory(int containerId, {int limit = 200}) async {
    try {
      final conn = await _connect();
      final results = await conn.query(
        'SELECT sensor_type, value, recorded_at FROM container_sensor_history WHERE container_id = ? ORDER BY recorded_at DESC LIMIT ?',
        [containerId, limit],
      );
      await conn.close();

      return results.map((r) => {
        'sensor_type': r['sensor_type'],
        'value': r['value'],
        'recorded_at': r['recorded_at']?.toString(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeContainerData(int containerId, Map<String, dynamic> body) async {
    try {
      final conn = await _connect();

      // Update container_data row if exists
      final updateFields = <String>[];
      final values = <dynamic>[];

      final allowed = {
        'fan_status': 'fan_status',
        'humidifier_status': 'humidifier_status',
        'heater_status': 'heater_status',
        'light_status': 'light_status',
        'target_temperature': 'target_temperature',
        'target_temperature_min': 'target_temperature_min',
        'target_humidity': 'target_humidity',
        'target_humidity_min': 'target_humidity_min',
        'target_light_level': 'target_light_level',
        'target_light_level_min': 'target_light_level_min',
        'target_gas_level': 'target_gas_level',
        'target_gas_level_min': 'target_gas_level_min',
      };

      body.forEach((k, v) {
        if (allowed.containsKey(k)) {
          updateFields.add('${allowed[k]} = ?');
          values.add(v);
        }
      });

      if (updateFields.isNotEmpty) {
        values.add(containerId);
        await conn.query('UPDATE container_data SET ${updateFields.join(', ')} WHERE container_id = ?', values);
      }

      // Optionally insert sensor history records if sensor values provided
      final sensorMapping = {
        'temperature': 'temperature',
        'humidity': 'humidity',
        'light_level': 'light_level',
        'gas_level': 'gas_level',
      };

      final now = DateTime.now().toIso8601String();
      for (final k in sensorMapping.keys) {
        if (body.containsKey(k) && body[k] != null) {
          await conn.query(
            'INSERT INTO container_sensor_history (container_id, sensor_type, value, recorded_at) VALUES (?, ?, ?, ?)',
            [containerId, sensorMapping[k], body[k], now],
          );
        }
      }

      await conn.close();
    } catch (e) {
      // best-effort, ignore errors
    }
  }

  /// Create container and its container_data row in the local MySQL DB.
  /// Expects the same shape as the API `ContainerResponse`.
  Future<void> createContainerLocal(Map<String, dynamic> containerJson) async {
    try {
      final conn = await _connect();

      final int id = containerJson['id'];
      final String name = containerJson['name'] ?? '';
      final double latitude = (containerJson['latitude'] ?? 0).toDouble();
      final double longitude = (containerJson['longitude'] ?? 0).toDouble();
      final int createdBy = containerJson['created_by'] ?? 0;

      // Insert container row (ignore if exists)
      await conn.query(
        'INSERT INTO containers (id, name, created_by, latitude, longitude, created_at) VALUES (?, ?, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE name = VALUES(name), latitude = VALUES(latitude), longitude = VALUES(longitude)',
        [id, name, createdBy, latitude, longitude],
      );

      // Insert container_data default row if not exists
      final data = containerJson['data'] as Map<String, dynamic>?;
      if (data != null) {
        await conn.query(
          '''
          INSERT INTO container_data (container_id, temperature, humidity, light_level, gas_level, heater_status, fan_status, light_status, humidifier_status, target_temperature, target_temperature_min, target_humidity, target_humidity_min, target_light_level, target_light_level_min, target_gas_level, target_gas_level_min, last_updated)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            temperature = VALUES(temperature), humidity = VALUES(humidity), light_level = VALUES(light_level), gas_level = VALUES(gas_level),
            heater_status = VALUES(heater_status), fan_status = VALUES(fan_status), light_status = VALUES(light_status), humidifier_status = VALUES(humidifier_status),
            target_temperature = VALUES(target_temperature), target_temperature_min = VALUES(target_temperature_min),
            target_humidity = VALUES(target_humidity), target_humidity_min = VALUES(target_humidity_min),
            target_light_level = VALUES(target_light_level), target_light_level_min = VALUES(target_light_level_min),
            target_gas_level = VALUES(target_gas_level), target_gas_level_min = VALUES(target_gas_level_min),
            last_updated = VALUES(last_updated)
          ''',
          [
            id,
            data['temperature'],
            data['humidity'],
            data['light_level'],
            data['gas_level'],
            data['heater_status'] == true ? 1 : 0,
            data['fan_status'] == true ? 1 : 0,
            data['light_status'] == true ? 1 : 0,
            data['humidifier_status'] == true ? 1 : 0,
            data['target_temperature'],
            data['target_temperature_min'],
            data['target_humidity'],
            data['target_humidity_min'],
            data['target_light_level'],
            data['target_light_level_min'],
            data['target_gas_level'],
            data['target_gas_level_min'],
            data['last_updated']?.toString(),
          ],
        );
      } else {
        // Ensure there is at least an empty container_data row
        await conn.query(
          'INSERT IGNORE INTO container_data (container_id) VALUES (?)',
          [id],
        );
      }

      await conn.close();
    } catch (e) {
      // best-effort, ignore errors
    }
  }
}
