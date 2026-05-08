import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  // Lazy getter — only accesses FirebaseAuth when first used,
  // by which point Firebase.initializeApp() has completed
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get uid => _auth.currentUser?.uid ?? '';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await _postSignIn(cred.user!.uid);
    return cred;
  }

  Future<void> signInWithUsername(String username, String password) async {
    final fs = FirestoreService();
    final email = await fs.getEmailByUsername(username);
    if (email == null) throw Exception('Username not found');
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await _postSignIn(cred.user!.uid);
  }

  Future<void> signInWithPhone(String phone, String password) async {
    final fs = FirestoreService();
    final email = await fs.getEmailByPhone(phone);
    if (email == null) throw Exception('Phone number not found');
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await _postSignIn(cred.user!.uid);
  }

  Future<void> _postSignIn(String uid) async {
    try {
      final token = await NotificationService.getFCMToken();
      final fs = FirestoreService();
      await fs.updateUserFields(uid, {
        'last_login': DateTime.now(),
        'is_online': true,
        if (token != null) 'fcm_token': token,
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Post-signin tasks failed (non-critical): $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    if (isLoggedIn) {
      final fs = FirestoreService();
      await fs.updateUserFields(uid, {'is_online': false});
    }
    await _auth.signOut();
    notifyListeners();
  }
}
