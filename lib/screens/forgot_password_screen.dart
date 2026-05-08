import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false, _sent = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('user-not-found'))
        msg = 'No account found with this email.';
      if (msg.contains('invalid-email')) msg = 'Invalid email address.';
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 24),
                Text('🔑 Reset Password',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark)),
                const SizedBox(height: 8),
                const Text(
                    'Enter your email address. We will send you a reset link.',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textMed, height: 1.5)),
                const SizedBox(height: 32),
                if (_sent) ...[
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.4))),
                      child: const Text(
                          '✅ Reset email sent! Check your inbox and spam folder.',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 14,
                              height: 1.4))),
                  const SizedBox(height: 20),
                  AppButton(
                      label: 'Back to Sign In',
                      onPressed: () => Navigator.pop(context)),
                ] else ...[
                  AppTextField(
                      label: 'Email Address',
                      controller: _ctrl,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                      label: 'Send Reset Email',
                      loading: _loading,
                      onPressed: _reset),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
