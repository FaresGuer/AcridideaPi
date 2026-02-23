import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'registration_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48),
              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.agriculture_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to your account',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 40),
              // Email Field
              Text('Email Address', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              // Password Field
              Text('Password', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: Icon(Icons.visibility_off_outlined, color: AppColors.textHint),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        activeColor: AppColors.primary,
                      ),
                      Text('Remember me', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('Forgot Password?'),
                  ),
                ],
              ),
              SizedBox(height: 32),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleLogin,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Login'),
                ),
              ),
              SizedBox(height: 16),
              // Sign Up Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => RegistrationScreen()),
                    );
                  },
                  child: Text("Don't have an account? Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      await AuthService.login(email: email, password: password);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
