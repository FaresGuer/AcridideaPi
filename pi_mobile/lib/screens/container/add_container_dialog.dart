import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';

class AddContainerMapDialog extends StatefulWidget {
  const AddContainerMapDialog({super.key});

  @override
  State<AddContainerMapDialog> createState() => _AddContainerMapDialogState();
}

class _AddContainerMapDialogState extends State<AddContainerMapDialog> {
  final nameController = TextEditingController();
  double? selectedLat;
  double? selectedLng;
  final MapController mapController = MapController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Container'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Container Name Input
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Container Name',
                hintText: 'e.g., Container A',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Map
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(36.8065, 10.1815), // Default to Tunis, Tunisia
                    initialZoom: 13.0,
                    onTap: (tapPos, latlng) {
                      setState(() {
                        selectedLat = latlng.latitude;
                        selectedLng = latlng.longitude;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.locustapp',
                    ),
                    if (selectedLat != null && selectedLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(selectedLat!, selectedLng!),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Selected Coordinates Display
            if (selectedLat != null && selectedLng != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Location:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${selectedLat!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Lng: ${selectedLng!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                child: Text(
                  'Tap on the map to select a location',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedLat == null || selectedLng == null || nameController.text.trim().isEmpty
              ? null
              : _createContainer,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createContainer() async {
    final name = nameController.text.trim();
    try {
      await AuthService.createContainer(
        name: name,
        latitude: selectedLat!,
        longitude: selectedLng!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Container "$name" created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

