import 'package:flutter/material.dart';

class AvatarDisplay extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final bool showGlow;

  const AvatarDisplay({
    super.key,
    required this.avatarUrl,
    this.size = 48,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasAvatar
            ? null
            : const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
        color: hasAvatar
            ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE))
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                      child: SizedBox(
                          width: size * 0.35,
                          height: size * 0.35,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF2563EB))));
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Center(
      child:
          Icon(Icons.person_rounded, color: Colors.white, size: size * 0.52));
}
