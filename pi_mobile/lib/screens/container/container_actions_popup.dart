import 'package:flutter/material.dart';
import '../../models/container.dart' as models;
import '../../services/auth_service.dart';

class ContainerActionsBottomSheet extends StatelessWidget {
  final models.Container container;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const ContainerActionsBottomSheet({
    super.key,
    required this.container,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              container.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(),
          // Edit Option
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
            title: const Text('Edit Container'),
            subtitle: const Text('Update name and location'),
            onTap: () async {
              Navigator.pop(context);
              onUpdate();
            },
          ),
          // Delete Option
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text(
              'Delete Container',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete this container'),
            onTap: () async {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Container?'),
        content: Text(
          'Are you sure you want to delete "${container.name}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteContainer(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContainer(BuildContext context) async {
    try {
      await AuthService.deleteContainer(container.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Container "${container.name}" deleted successfully')),
        );
        onDelete();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
