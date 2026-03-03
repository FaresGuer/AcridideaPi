import 'package:flutter/foundation.dart';
import '../models/container.dart' as models;

/// Service to manage the currently selected container
class ContainerService {
  static final ValueNotifier<models.Container?> selectedContainer = ValueNotifier<models.Container?>(null);

  static void selectContainer(models.Container container) {
    selectedContainer.value = container;
  }

  static void clearSelection() {
    selectedContainer.value = null;
  }

  static bool get hasSelection => selectedContainer.value != null;
}
