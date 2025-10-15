import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/utils/validators.dart';
import 'package:travel_diary_frontend/core/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
          ),
        );
        return;
      }

      // Clear any previous errors
      ref.read(authControllerProvider.notifier).clearError();

      await ref.read(authControllerProvider.notifier).register(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
          );
      
      if (mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState.isAuthenticated) {
          context.go('/');
        } else if (authState.error != null) {
          _showErrorDialog(authState.error!);
        }
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Registration Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Start your travel journey today',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Username field
                AppTextField(
                  label: 'Username',
                  hint: 'Choose a username',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.username,
                  enabled: !authState.isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Email field
                AppTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                  enabled: !authState.isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Password field
                AppTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: Validators.password,
                  enabled: !authState.isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Confirm password field
                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  enabled: !authState.isLoading,
                ),
                
                const SizedBox(height: 24),
                
                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!authState.isLoading) {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                            });
                          }
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Register button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Account'),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

