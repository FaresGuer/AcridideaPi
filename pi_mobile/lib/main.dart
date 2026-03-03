import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/container/container_router.dart';
import 'services/auth_service.dart';
import 'services/container_service.dart';
import 'models/container.dart' as models;
import 'models/auth_user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication - load saved session if available
    AuthService.initializeAuth();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {
        return ValueListenableBuilder<models.Container?>(
          valueListenable: ContainerService.selectedContainer,
          builder: (context, selectedContainer, child) {
            // Build home widget based on auth and container state
            Widget homeWidget;
            String stateKey;
            
            if (user == null) {
              homeWidget = LoginScreen();
              stateKey = 'no_user';
            } else if (selectedContainer != null) {
              homeWidget = MainNavigation();
              stateKey = 'user_${user.id}_container_${selectedContainer.id}';
            } else {
              homeWidget = ContainerRouter();
              stateKey = 'user_${user.id}_no_container';
            }
            
            return MaterialApp(
              key: ValueKey(stateKey), // Force rebuild on state change
              title: 'Monitoring System for Locust Farming',
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              home: homeWidget,
            );
          },
        );
      },
    );
  }
}
