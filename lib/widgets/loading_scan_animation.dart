import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingScanAnimation extends StatefulWidget {
  final String label;
  const LoadingScanAnimation(
      {super.key, this.label = 'Scanning nearby users…'});
  @override
  State<LoadingScanAnimation> createState() => _LoadingScanAnimationState();
}

class _LoadingScanAnimationState extends State<LoadingScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.batteryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                )
              ],
            ),
            child:
                const Center(child: Text('📡', style: TextStyle(fontSize: 36))),
          ),
        ),
        const SizedBox(height: 24),
        Text(widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.starWhite : AppColors.textMed,
            )),
      ],
    );
  }
}
