import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _uname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _uname.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final fs = context.read<FirestoreService>();

      final taken = await fs.isUsernameTaken(_uname.text.trim().toLowerCase());
      if (taken) {
        setState(() {
          _error = 'Username already taken';
          _loading = false;
        });
        return;
      }

      final cred = await auth.signUpWithEmail(_email.text.trim(), _pass.text);
      final uid = cred.user!.uid;

      await PermissionService.requestLocation();
      await PermissionService.requestBluetooth();
      await PermissionService.requestStorage();
      await PermissionService.requestNotifications();
      final perms = await PermissionService.checkAll();
      final device = await DeviceService.detect();
      final fcmToken = await NotificationService.getFCMToken() ?? '';

      await fs.createUser(UserModel(
        userId: uid,
        name: _name.text.trim(),
        username: _uname.text.trim().toLowerCase(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        avatar: 'panda',
        credits: 10,
        fcmToken: fcmToken,
        isOnline: true,
        device: device,
        permissions: perms,
        location: {
          'lat': null,
          'lng': null,
          'last_updated': DateTime.now().toString(),
        },
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      ));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('email-already-in-use')) msg = 'Email already in use';
      if (msg.contains('weak-password')) msg = 'Password is too weak';
      if (msg.contains('invalid-email')) msg = 'Invalid email address';
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
                  Text('Create Account',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.starWhite
                              : AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('Join AmpUp today',
                      style:
                          TextStyle(fontSize: 15, color: AppColors.textLight)),
                  const SizedBox(height: 28),
                  AppTextField(
                      label: 'Full Name',
                      controller: _name,
                      prefixIcon: Icons.person_outline,
                      validator: AppValidators.name),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Username',
                      controller: _uname,
                      prefixIcon: Icons.alternate_email,
                      hint: 'lowercase letters, numbers, underscores',
                      validator: AppValidators.username),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Phone Number',
                      controller: _phone,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: '+91XXXXXXXXXX',
                      validator: AppValidators.phone),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Email Address',
                      controller: _email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.email),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Password',
                      controller: _pass,
                      prefixIcon: Icons.lock_outline,
                      obscure: !_showPass,
                      hint: 'Min 8 chars, 1 uppercase, 1 number',
                      suffix: IconButton(
                          icon: Icon(
                              _showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textLight),
                          onPressed: () =>
                              setState(() => _showPass = !_showPass)),
                      validator: AppValidators.password),
                  const SizedBox(height: 14),
                  AppTextField(
                      label: 'Confirm Password',
                      controller: _confirm,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      validator: (v) =>
                          AppValidators.confirmPassword(v, _pass.text)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.danger, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                      label: 'Create Account',
                      loading: _loading,
                      onPressed: _submit),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?  ',
                          style: TextStyle(color: AppColors.textMed)),
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign In',
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
