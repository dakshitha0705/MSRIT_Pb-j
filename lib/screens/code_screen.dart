import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';

class CodeScreen extends StatefulWidget {
  final String expectedCode;
  final VoidCallback onVerified;
  const CodeScreen(
      {super.key, required this.expectedCode, required this.onVerified});
  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _ctrl = TextEditingController();
  String? _error;

  void _verify() {
    if (_ctrl.text.trim() == widget.expectedCode) {
      widget.onVerified();
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Incorrect code. Please try again.');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              const Text('Enter Session Code',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Ask the other person for the 6-digit session code.',
                  style: TextStyle(color: AppColors.textMed)),
              const SizedBox(height: 24),
              TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8),
                  decoration: const InputDecoration(
                      hintText: '000000', counterText: '')),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger))
              ],
              const SizedBox(height: 24),
              AppButton(label: 'Verify Code', onPressed: _verify),
            ],
          ),
        )),
      );
}
