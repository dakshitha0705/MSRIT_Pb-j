import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/music_player_service.dart';

import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging instance
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM Token
  String? token = await messaging.getToken();

  print("=================================");
  print("FCM TOKEN: $token");
  print("=================================");

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground notification received!");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: const BatteryBarterApp(),
    ),
  );
}
