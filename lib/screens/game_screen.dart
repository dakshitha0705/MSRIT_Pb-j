import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/dino_game.dart';
import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? _lastEarned;
  bool _saving = false;
  String? _saveMsg;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide status bar — full immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _handleGameOver(int earned) async {
    setState(() {
      _lastEarned = earned;
      _saving = true;
      _saveMsg = null;
    });
    try {
      final uid = context.read<AuthService>().uid;
      final fs = context.read<FirestoreService>();
      final cs = CreditService(fs);
      final actual = await cs.addGameCredits(uid, earned);
      await fs.loadUser(uid);
      if (!mounted) return;
      setState(() {
        _saveMsg =
            actual > 0 ? '+$actual credits earned!' : 'Keep playing for fun!';
        _saving = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _saveMsg = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game takes 100% of screen
          Positioned.fill(
            child: DinoGame(onGameOver: _handleGameOver),
          ),

          // Back button — top left overlay
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // Credits toast — bottom center, only shows after game over
          if (_saveMsg != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _saveMsg != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _saveMsg!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
