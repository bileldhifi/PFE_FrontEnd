import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/auth/data/repo/auth_repository.dart';
import 'package:travel_diary_frontend/core/widgets/app_text_field.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String? initialEmail;
  const VerifyResetCodeScreen({super.key, this.initialEmail});
  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = AuthRepository();
      final token = await repo.verifyResetCode(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );
      if (!mounted) return;
      context.go('/auth/reset-password?token=$token');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 20),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to your email. Enter it below.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Verification Code',
                  hint: '6-digit code',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Code is required';
                    if (v.length != 6) return 'Enter the 6-digit code';
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  SelectableText(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

