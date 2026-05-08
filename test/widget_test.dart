import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battery_barter/app.dart';
import 'package:battery_barter/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:battery_barter/services/auth_service.dart';
import 'package:battery_barter/services/firestore_service.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => FirestoreService()),
          ChangeNotifierProvider(create: (_) => AppThemeNotifier()),
        ],
        child: const BatteryBarterApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
