import 'package:uuid/uuid.dart';
import 'firestore_service.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class CreditService {
  final FirestoreService _fs;
  CreditService(this._fs);

  Future<void> addCredits(
      String userId, int amount, String featureType, String sessionId) async {
    final user = await _fs.getUserById(userId);
    if (user == null) return;
    await _fs.updateUserFields(userId, {
      'credits': user.credits + amount,
    });
    await _fs.addTransaction(TransactionModel(
      transactionId: const Uuid().v4(),
      userId: userId,
      type: 'credit',
      featureType: featureType,
      amount: amount,
      sessionId: sessionId,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> deductCredits(
      String userId, int amount, String featureType, String sessionId) async {
    final user = await _fs.getUserById(userId);
    if (user == null) return;
    final newCredits = user.credits - amount;
    if (newCredits < AppConstants.minCreditsAllowed) {
      throw Exception(
          'Credits would fall below minimum (${AppConstants.minCreditsAllowed})');
    }
    await _fs.updateUserFields(userId, {'credits': newCredits});
    await _fs.addTransaction(TransactionModel(
      transactionId: const Uuid().v4(),
      userId: userId,
      type: 'debit',
      featureType: featureType,
      amount: amount,
      sessionId: sessionId,
      createdAt: DateTime.now(),
    ));
  }

  Future<int> addGameCredits(String userId, int earnedRaw) async {
    final user = await _fs.getUserById(userId);
    if (user == null) return 0;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final alreadyToday =
        user.dailyGameDate == today ? user.dailyGameCredits : 0;
    final canAdd =
        (AppConstants.dailyGameCreditCap - alreadyToday).clamp(0, earnedRaw);
    if (canAdd <= 0) return 0;

    await _fs.updateUserFields(userId, {
      'credits': user.credits + canAdd,
      'daily_game_credits': alreadyToday + canAdd,
      'daily_game_date': today,
    });
    await _fs.addTransaction(TransactionModel(
      transactionId: const Uuid().v4(),
      userId: userId,
      type: 'credit',
      featureType: 'game',
      amount: canAdd,
      sessionId: '',
      createdAt: DateTime.now(),
    ));
    return canAdd;
  }
}
