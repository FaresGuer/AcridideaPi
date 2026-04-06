import 'package:flutter/foundation.dart';
import '../models/container.dart' as models;
import 'mqtt_service.dart';

/// Service to manage the currently selected container
class ContainerService {
  static final ValueNotifier<models.Container?> selectedContainer = ValueNotifier<models.Container?>(null);
  static final MqttService _mqttService = MqttService();

  static void selectContainer(models.Container container) {
    selectedContainer.value = container;
    _publishContainerSelection(container.id.toString());
  }

  static void _publishContainerSelection(String containerId) {
    _mqttService.publish("gateway/container", containerId);
  }

  static void clearSelection() {
    selectedContainer.value = null;
  }

  static bool get hasSelection => selectedContainer.value != null;
}
