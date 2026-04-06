import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  late MqttServerClient _client;

  static const String brokerAddress = "broker.hivemq.com";
  static const int brokerPort = 1883;
  static const String clientId = "flutter_mobile_app";

  factory MqttService() {
    return _instance;
  }

  MqttService._internal() {
    _client = MqttServerClient(brokerAddress, clientId);
    _client.port = brokerPort;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
  }

  /// Connect to MQTT broker
  Future<bool> connect() async {
    try {
      await _client.connect();
      return _client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (e) {
      print('[MQTT] Connection Error: $e');
      return false;
    }
  }

  /// Publish message to a topic
  void publish(String topic, String message) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('[MQTT] Published to $topic: $message');
    } else {
      print('[MQTT] Not connected. Attempting to reconnect...');
      connect().then((_) {
        if (_client.connectionStatus?.state == MqttConnectionState.connected) {
          final builder = MqttClientPayloadBuilder();
          builder.addString(message);
          _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
          print('[MQTT] Published to $topic: $message');
        }
      });
    }
  }

  /// Subscribe to a topic
  void subscribe(String topic) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atLeastOnce);
      print('[MQTT] Subscribed to $topic');
    }
  }

  /// Disconnect from broker
  void disconnect() {
    _client.disconnect();
  }

  /// Get subscription updates
  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates =>
      _client.updates;

  /// Connection callback
  void _onConnected() {
    print('[MQTT] Connected to broker');
  }

  /// Disconnection callback
  void _onDisconnected() {
    print('[MQTT] Disconnected from broker');
  }

  /// Check if connected
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;
}
