import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const OnboardingScreen({super.key, this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Real-Time\nEnvironmental\nMonitoring',
      description:
          'Monitor temperature, humidity, air quality, and lighting conditions inside your farming containers in real time.',
      image: 'assets/images/onboarding1.png', // Placeholder
      icon: Icons.sensors,
      color: Color(0xFFE8F5E9),
      customWidget: _FloatingDataCardsWidget(),
    ),
    OnboardingContent(
      title: 'Automated Climate\nControl',
      description:
          'Automatically regulate ventilation, heating, humidification, and feeding to maintain optimal growth conditions.',
      image: 'assets/images/onboarding2.png',
      icon: Icons.ac_unit,
      color: Color(0xFFE1F5FE),
    ),
    OnboardingContent(
      title: 'AI Behavioral Insights',
      description:
          'Use advanced AI vision analysis to monitor locust activity, detect anomalies, and predict health risks.',
      image: 'assets/images/onboarding3.png',
      icon: Icons.visibility,
      color: Color(0xFFF3E5F5),
    ),
    OnboardingContent(
      title: 'Stay Informed,\nAnytime, Anywhere',
      description:
          'Receive instant alerts and manage your farming containers remotely from anywhere in the world.',
      image: 'assets/images/onboarding4.png',
      icon: Icons.notifications_active,
      color: Color(0xFFFFF3E0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF4CAF50), // Green color matching design
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(content: _contents[index]);
                },
              ),
            ),

            // Bottom Section (Indicators + Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF00C853) // Active green
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853), // Green button
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _contents.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String image;
  final IconData icon;
  final Color color;
  final Widget? customWidget;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    required this.color,
    this.customWidget,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Check if title contains "Anywhere" to apply special styling
    final isLastSlide = content.title.contains('Anywhere');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image / Illustration Placeholder or Custom Widget
            content.customWidget ??
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: content.color,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // In a real app, use Image.asset(content.image)
                      // Using Icon as placeholder matching the design style
                      Icon(
                        content.icon,
                        size: 100,
                        color: Colors.green.shade700.withOpacity(0.5),
                      ),
                      // Decorative elements simulating the screenshot
                      Positioned(
                          top: 20,
                          right: 20,
                          child: Icon(Icons.cloud_queue, color: Colors.white, size: 40)),
                      Positioned(
                          bottom: 30,
                          left: 30,
                          child: Icon(Icons.air, color: Colors.white, size: 30)),
                    ],
                  ),
                ),
            const SizedBox(height: 48),

            // Title
            isLastSlide
                ? RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B), // Slate 800
                        height: 1.2,
                        fontFamily: 'Roboto', // Ensure font consistency
                      ),
                      children: [
                        TextSpan(text: 'Stay Informed,\n'),
                        TextSpan(
                          text: 'Anytime, Anywhere',
                          style: TextStyle(color: Color(0xFF00C853)),
                        ),
                      ],
                    ),
                  )
                : Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B), // Slate 800
                      height: 1.2,
                    ),
                  ),
            const SizedBox(height: 16),

            // Description
            Text(
              content.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B), // Slate 500
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDataCardsWidget extends StatefulWidget {
  @override
  State<_FloatingDataCardsWidget> createState() => _FloatingDataCardsWidgetState();
}

class _FloatingDataCardsWidgetState extends State<_FloatingDataCardsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Central Chip Icon with Glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.memory, color: Color(0xFF00C853), size: 40),
          ),

          // Connecting Lines (Static behind)
          // Simplified as just position relative to center

          // Floating Cards
          // Top Left - Temp
          _buildFloatingCard(
            alignment: Alignment(-0.7, -0.6),
            icon: Icons.thermostat,
            label: 'TEMP',
            value: '24.5°C',
            color: Colors.orange.shade50,
            iconColor: Colors.orange,
            delay: 0.0,
          ),

          // Top Right - Humidity
          _buildFloatingCard(
            alignment: Alignment(0.7, -0.7),
            icon: Icons.water_drop,
            label: 'HUMID',
            value: '65%',
            color: Colors.blue.shade50,
            iconColor: Colors.blue,
            delay: 1.0, // Different phase
          ),

          // Bottom Left - Air
          _buildFloatingCard(
            alignment: Alignment(-0.6, 0.7),
            icon: Icons.air,
            label: 'AIR',
            value: '98 AQI',
            color: Colors.green.shade50,
            iconColor: Colors.green,
            delay: 2.0, // Different phase
          ),

          // Bottom Right - Light
          _buildFloatingCard(
            alignment: Alignment(0.8, 0.6),
            icon: Icons.wb_sunny,
            label: 'LIGHT',
            value: '12k Lux',
            color: Colors.amber.shade50,
            iconColor: Colors.amber,
            delay: 1.5, // Different phase
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required Alignment alignment,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
    required double delay,
  }) {
    // Generate a unique floating animation based on delay/phase
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Create a sine wave motion: sin(2*pi*t + phase)
          // We use _controller.value (0..1) to drive time
          // But since we repeat(reverse: true), value goes 0->1->0.
          // For continuous floating, just repeat() is better, but bouncing up/down works too.
          // math.sin requires dart:math import which we added.

          final offset = 10.0 *
              (1 + 0.5 * delay) * // slightly different amplitude
              math.sin(2 * math.pi * _controller.value + delay); // distinct phase

          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
