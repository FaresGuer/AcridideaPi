import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring System for Locust Farming',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: ValueListenableBuilder(
        valueListenable: AuthService.currentUser,
        builder: (context, user, child) {
          return user == null ? LoginScreen() : MainNavigation();
        },
      ),
    );
  }
}
