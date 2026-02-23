import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;
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
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Join us to monitor your greenhouse',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 32),
              // Name Field
              Text('Full Name', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 24),
              // Terms & Conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to Terms of Service and Privacy Policy',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRegister,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Sign Up'),
                ),
              ),
              SizedBox(height: 16),
              // Login Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                  child: Text('Already have an account? Login'),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.register(
        email: email,
        fullName: name,
        password: password,
        role: 'FARMER',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created. Please sign in.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
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
