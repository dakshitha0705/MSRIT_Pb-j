import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';

class PasscodeEntryScreen extends StatefulWidget {
  final String sessionId;
  const PasscodeEntryScreen({super.key, required this.sessionId});

  @override
  State<PasscodeEntryScreen> createState() => _PasscodeEntryScreenState();
}

class _PasscodeEntryScreenState extends State<PasscodeEntryScreen> {
  final _codeController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _verifying) return;

    setState(() => _verifying = true);
    try {
      final fs = context.read<FirestoreService>();
      final success =
          await SessionService(fs).verifySession(widget.sessionId, code);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verification successful! Credits transferred.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close passcode screen
        Navigator.pop(context); // Close session screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid passcode. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.close,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark),
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text('Enter Passcode',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Instructions
                const Text(
                  'Enter the 6-digit passcode shown by the battery donor to complete the verification.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMed, height: 1.4),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Passcode input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 32,
                        letterSpacing: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                ),

                const SizedBox(height: 32),

                // Verify button
                AppButton(
                  label: 'Verify & Complete',
                  loading: _verifying,
                  onPressed: _verify,
                ),

                const Spacer(),

                // Alternative QR option
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close passcode screen
                    // Navigate to QR scanner - will be handled by parent
                  },
                  child: const Text(
                    'Use QR Scanner Instead',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
