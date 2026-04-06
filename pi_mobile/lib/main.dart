import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/container/container_router.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/container_service.dart';
import 'services/mqtt_service.dart';
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
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    // Initialize authentication - load saved session if available
    AuthService.initializeAuth();
    // Initialize MQTT connection
    MqttService().connect();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash/loading while checking onboarding status
    if (_seenOnboarding == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {

        // If user hasn't seen onboarding and is not logged in, show onboarding
        if (!_seenOnboarding! && user == null) {
           return MaterialApp(
            title: 'Monitoring System for Locust Farming',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: OnboardingScreen(
              onDone: () {
                setState(() {
                  _seenOnboarding = true;
                });
              },
            ),
          );
        }

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
