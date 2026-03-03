import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_colors.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _rememberMe = false;
  bool _isSubmitting = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutBack));
    _animationController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final savedPassword = prefs.getString('remembered_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (mounted && rememberMe && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color handled by theme (mintBackground)
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Icon with enhanced design
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 48),

                    // Login Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field
                          Text('Email Address', style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'example@email.com',
                                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          SizedBox(height: 24),

                          // Password Field
                          Text('Password', style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() => _showPassword = !_showPassword);
                                  },
                                  child: Icon(
                                    _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              obscureText: !_showPassword,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.1,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) async {
                                        final prefs = await SharedPreferences.getInstance();
                                        if (value ?? false) {
                                          // Save credentials
                                          await prefs.setString('remembered_email', _emailController.text);
                                          await prefs.setString('remembered_password', _passwordController.text);
                                          await prefs.setBool('remember_me', true);
                                        } else {
                                          // Clear saved credentials
                                          await prefs.remove('remembered_email');
                                          await prefs.remove('remembered_password');
                                          await prefs.setBool('remember_me', false);
                                        }
                                        setState(() => _rememberMe = value ?? false);
                                      },
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    ),
                                  ),
                                  Text('Remember me', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                  );
                                },
                                child: Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                              ),
                              child: _isSubmitting
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegistrationScreen()),
                            );
                          },
                          child: Text('Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            )
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final loginResult = await AuthService.login(email: email, password: password);

      if (loginResult.requiresTwoFactor) {
        final verificationToken = loginResult.verificationToken;
        if (verificationToken == null || verificationToken.isEmpty) {
          throw Exception('Missing verification session');
        }

        if (mounted && loginResult.message != null && loginResult.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loginResult.message!)),
          );
        }

        final verified = await _showTwoFactorDialog(verificationToken);
        if (!verified) {
          return;
        }
      }

      // Login successful - wait a moment for ValueNotifier to propagate
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      // Don't navigate manually - main.dart's ValueListenableBuilder will handle routing
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<bool> _showTwoFactorDialog(String verificationToken) async {
    final codeController = TextEditingController();
    bool isVerifying = false;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Two-Factor Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 6-digit code sent to your email.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(dialogContext, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Enter a valid 6-digit code')),
                        );
                        return;
                      }

                      setDialogState(() => isVerifying = true);
                      try {
                        await AuthService.verifyTwoFactorLogin(
                          verificationToken: verificationToken,
                          code: code,
                        );
                        if (mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isVerifying = false);
                        }
                      }
                    },
              child: isVerifying
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Verify'),
            ),
          ],
        ),
      ),
    );

    return verified ?? false;
  }
}
