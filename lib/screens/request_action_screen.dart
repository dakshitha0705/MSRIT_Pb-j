import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';
import '../models/session_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/pastel_card.dart';
import 'session_screen.dart';

class RequestActionScreen extends StatefulWidget {
  final String sessionId;
  const RequestActionScreen({super.key, required this.sessionId});

  @override
  State<RequestActionScreen> createState() => _RequestActionScreenState();
}

class _RequestActionScreenState extends State<RequestActionScreen> {
  bool _accepting = false;
  bool _rejecting = false;
  SessionModel? _session;
  String _requesterName = '';
  String _requesterUsername = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final fs = context.read<FirestoreService>();
    final session = await fs.getSession(widget.sessionId);
    if (session == null || !mounted) return;

    // senderUserId in the codebase = the person who SENT the request (requester)
    final requester = await fs.getUserById(session.senderUserId);
    if (mounted) {
      setState(() {
        _session = session;
        _requesterName = requester?.name ?? 'Someone';
        _requesterUsername = requester?.username ?? '';
      });
    }
  }

  Future<void> _accept() async {
    if (_session == null || _accepting) return;
    setState(() => _accepting = true);
    try {
      final auth = context.read<AuthService>();
      final fs = context.read<FirestoreService>();
      // receiverUid here = lender (current user) — matches session.receiverUserId
      await SessionService(fs).acceptSession(widget.sessionId, auth.uid);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionScreen(
            sessionId: widget.sessionId,
            isSender: true, // isSender=true means current user is the lender/helper
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _accepting = false);
      }
    }
  }

  Future<void> _reject() async {
    if (_session == null || _rejecting) return;
    setState(() => _rejecting = true);
    try {
      final auth = context.read<AuthService>();
      final fs = context.read<FirestoreService>();
      await SessionService(fs).rejectSession(widget.sessionId, auth.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _rejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = _session;
    final isEmergency = session?.metadata['emergency'] == true;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: session == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Incoming Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Request card — no private lender details shown here
                      PastelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isEmergency)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '🚨 EMERGENCY REQUEST',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            // Requester identity
                            Row(children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  _requesterName.isNotEmpty
                                      ? _requesterName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _requesterName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.starWhite
                                            : AppColors.textDark,
                                      ),
                                    ),
                                    if (_requesterUsername.isNotEmpty)
                                      Text(
                                        '@$_requesterUsername',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMed),
                                      ),
                                  ],
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),

                            // Request type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                const Text('📋',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  'Request type: ${session.featureType.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Credits involved: ${session.credits} ⚡',
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textMed),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Status-aware content
                      if (session.status == 'rejected')
                        PastelCard(
                          child: Row(children: [
                            const Text('❌',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            const Text('You declined this request.',
                                style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        )
                      else if (session.status == 'accepted' ||
                          session.status == 'completed' ||
                          session.status == 'verified')
                        AppButton(
                          label: 'View Active Session',
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionScreen(
                                sessionId: widget.sessionId,
                                isSender: true,
                              ),
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Accept / Reject — only for pending 'requested' status
                      if (session.status == 'requested') ...[
                        AppButton(
                          label: '✅  Accept Request',
                          loading: _accepting,
                          onPressed: _accept,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Decline',
                          outlined: true,
                          color: AppColors.danger,
                          loading: _rejecting,
                          onPressed: _reject,
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
