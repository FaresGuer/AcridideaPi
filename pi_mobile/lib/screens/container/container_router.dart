import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/container.dart' as models;
import 'container_selection_screen.dart';
import 'no_container_page.dart';
import '../auth/role_selection_dialog.dart';

/// Router that decides which screen to show based on whether user has containers
class ContainerRouter extends StatefulWidget {
  const ContainerRouter({super.key});

  @override
  State<ContainerRouter> createState() => _ContainerRouterState();
}

class _ContainerRouterState extends State<ContainerRouter> {
  late Future<List<models.Container>> _containersFuture;

  @override
  void initState() {
    super.initState();
    _containersFuture = AuthService.fetchContainers();
    // Listen for login events and show role selection dialog if needed
    AuthService.currentUser.addListener(_handleAuthStateChange);
    // Schedule the dialog to show after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRoleSelectionDialogIfNeeded();
    });
  }

  void _handleAuthStateChange() {
    // Show dialog again if a new user logs in without having selected role
    _showRoleSelectionDialogIfNeeded();
  }

  @override
  void dispose() {
    AuthService.currentUser.removeListener(_handleAuthStateChange);
    super.dispose();
  }

  void _showRoleSelectionDialogIfNeeded() {
    final currentUser = AuthService.currentUser.value;
    // Only show dialog if user exists and hasn't selected role yet
    if (currentUser != null && !currentUser.roleSelected) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RoleSelectionDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<models.Container>>(
      future: _containersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFFE8F5E9),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  SizedBox(height: 16),
                  Text('Error loading containers'),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _containersFuture = AuthService.fetchContainers();
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final containers = snapshot.data ?? [];

        // If user has containers, show selection screen
        // Otherwise show no container page
        if (containers.isNotEmpty) {
          return ContainerSelectionScreen();
        } else {
          return NoContainerPage();
        }
      },
    );
  }
}
