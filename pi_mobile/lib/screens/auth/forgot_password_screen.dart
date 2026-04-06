import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSubmitting = false;
  String? _resetToken;
  String _currentStep = 'email'; // email, code, newPassword

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestResetCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await AuthService.forgotPassword(email: email);
      
      if (mounted) {
        setState(() {
          _resetToken = response['reset_token'];
          _currentStep = 'code';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Reset code sent to your email')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyResetCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid 6-digit code')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // In a real app, you'd verify the code here
      // For now, just move to the next step
      setState(() {
        _currentStep = 'newPassword';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both passwords.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_resetToken == null) {
        throw Exception('Reset session lost');
      }

      final code = _codeController.text.trim();
      await AuthService.resetPassword(
        resetToken: _resetToken!,
        code: code,
        newPassword: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset successfully! Please log in.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep != 'email') {
          setState(() {
            _currentStep = _currentStep == 'code' ? 'email' : 'code';
            if (_currentStep == 'email') {
              _emailController.clear();
              _codeController.clear();
              _resetToken = null;
            }
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
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
                      // Back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFE3E8EF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back, color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Title
                      Center(
                        child: Text(
                          _currentStep == 'email'
                              ? 'Forgot Password?'
                              : _currentStep == 'code'
                                  ? 'Verify Code'
                                  : 'Set New Password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          _currentStep == 'email'
                              ? 'Enter your email to receive a reset code'
                              : _currentStep == 'code'
                                  ? 'Enter the 6-digit code sent to your email'
                                  : 'Create a new password for your account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      SizedBox(height: 48),

                      // Form Card
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
                            if (_currentStep == 'email') ...[
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
                            ] else if (_currentStep == 'code') ...[
                              Text('Verification Code', style: Theme.of(context).textTheme.titleMedium),
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
                                  controller: _codeController,
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                ),
                              ),
                            ] else ...[
                              Text('New Password', style: Theme.of(context).textTheme.titleMedium),
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
                                    hintText: 'Enter new password',
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
                              SizedBox(height: 12),
                              Text('Confirm Password', style: Theme.of(context).textTheme.titleMedium),
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
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm password',
                                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  obscureText: true,
                                ),
                              ),
                            ],
                            SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        if (_currentStep == 'email') {
                                          _requestResetCode();
                                        } else if (_currentStep == 'code') {
                                          _verifyResetCode();
                                        } else {
                                          _resetPassword();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  shadowColor: AppColors.primary.withOpacity(0.4),
                                ),
                                child: _isSubmitting
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _currentStep == 'email'
                                            ? 'Send Reset Code'
                                            : _currentStep == 'code'
                                                ? 'Verify Code'
                                                : 'Reset Password',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),
                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Remember your password?", style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
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
      ),
    );
  }
}
