import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

class BatteryBarterApp extends StatelessWidget {
  const BatteryBarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<AppThemeNotifier>();
    return MaterialApp(
      title: 'AmpUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      builder: (context, child) {
        // Force correct text color globally based on theme
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DefaultTextStyle(
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF09090B),
                fontFamily: 'Roboto'),
            child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
