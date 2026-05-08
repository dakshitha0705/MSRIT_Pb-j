import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});
  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _isEmail => _identifier.text.contains('@');
  bool get _isPhone =>
      RegExp(r'^\+?[0-9]{7,}').hasMatch(_identifier.text.trim());

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final id = _identifier.text.trim();

      if (_isEmail) {
        await auth.signInWithEmail(id, _pass.text);
      } else if (_isPhone) {
        await auth.signInWithPhone(id, _pass.text);
      } else {
        await auth.signInWithUsername(id, _pass.text);
      }

      final fs = context.read<FirestoreService>();
      await fs.loadUser(auth.uid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('wrong-password') || msg.contains('invalid-credential'))
        msg = 'Incorrect email or password';
      if (msg.contains('user-not-found')) msg = 'Account not found';
      if (msg.contains('too-many-requests'))
        msg = 'Too many attempts. Please try again later.';
      if (msg.contains('network'))
        msg = 'Network error. Check your connection.';
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: isDark
                              ? AppColors.starWhite
                              : AppColors.textDark),
                      onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.starWhite
                              : AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('Sign in to continue',
                      style:
                          TextStyle(fontSize: 15, color: AppColors.textLight)),
                  const SizedBox(height: 32),
                  AppTextField(
                      label: 'Email / Username / Phone',
                      controller: _identifier,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter your email, username, or phone'
                          : null),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Password',
                      controller: _pass,
                      prefixIcon: Icons.lock_outline,
                      obscure: !_showPass,
                      suffix: IconButton(
                          icon: Icon(
                              _showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight),
                          onPressed: () =>
                              setState(() => _showPass = !_showPass)),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password is required'
                          : null),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Forgot password?',
                            style: TextStyle(color: AppColors.primaryBlue))),
                  ),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(
                      label: 'Sign In', loading: _loading, onPressed: _submit),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No account?  ',
                          style: TextStyle(color: AppColors.textMed)),
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Create one',
                              style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
