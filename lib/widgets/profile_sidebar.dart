import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../models/transaction_model.dart';
import '../models/app_file_model.dart';
import '../screens/welcome_screen.dart';
import '../screens/avatar_creator_screen.dart';
import '../screens/spin_wheel_screen.dart';
import '../widgets/avatar_display.dart';

class ProfileSidebar extends StatefulWidget {
  const ProfileSidebar({super.key});
  @override
  State<ProfileSidebar> createState() => _ProfileSidebarState();
}

class _ProfileSidebarState extends State<ProfileSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _rescanning = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _selectedTab = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<FirestoreService>().currentUser;
    if (user == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2))),
          ),
          _ProfileHeader(user: user, isDark: isDark),
          _CustomTabBar(
            tabs: const [
              _TabItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
              _TabItem(
                  icon: Icons.face_retouching_natural_rounded, label: 'Avatar'),
              _TabItem(icon: Icons.history_rounded, label: 'History'),
              _TabItem(icon: Icons.phone_android_rounded, label: 'Device'),
              _TabItem(icon: Icons.folder_open_rounded, label: 'Files'),
              _TabItem(icon: Icons.casino_rounded, label: 'Daily Spin'),
              _TabItem(
                  icon: Icons.power_settings_new_rounded, label: 'Sign Out'),
            ],
            controller: _tabs,
            isDark: isDark,
            selectedIndex: _selectedTab,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TransactionsTab(),
                _AvatarTab(),
                _HistoryTab(),
                _DeviceTab(rescanning: _rescanning, onRescan: _rescan),
                _FilesTab(),
                _SpinTab(),
                _LogoutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rescan() async {
    setState(() => _rescanning = true);
    try {
      final device = await DeviceService.detect();
      final uid = context.read<AuthService>().uid;
      await context
          .read<FirestoreService>()
          .updateUserFields(uid, {'device': device.toMap()});
    } finally {
      if (mounted) setState(() => _rescanning = false);
    }
  }
}

// ── Spin Tab ────────────────────────────────────────
class _SpinTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<FirestoreService>().currentUser;

    // Check if already spun today
    bool hasSpunToday = false;
    if (user?.lastSpinDate != null) {
      final now = DateTime.now();
      final last = user!.lastSpinDate!;
      hasSpunToday = now.year == last.year &&
          now.month == last.month &&
          now.day == last.day;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Wheel icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 20)
                ]),
            child: const Center(
                child: Icon(Icons.casino_rounded,
                    color: Color(0xFFFFD700), size: 48)),
          ),
          const SizedBox(height: 20),
          Text('Daily Spin Wheel',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(
              hasSpunToday
                  ? 'You already spun today!\nCome back tomorrow.'
                  : 'Spin once per day to win credits.\nMatch segments for big wins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: hasSpunToday
                ? null
                : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SpinWheelScreen())),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  gradient: hasSpunToday
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  color: hasSpunToday
                      ? (isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasSpunToday
                      ? null
                      : [
                          BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]),
              child: Center(
                  child: Text(hasSpunToday ? 'Spun Today' : 'Spin Now',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: hasSpunToday
                              ? (isDark
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.25))
                              : Colors.black))),
            ),
          ),
          if (hasSpunToday) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_time_rounded,
                  size: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3)),
              const SizedBox(width: 5),
              Text('Resets at midnight',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.3))),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Profile Header ──────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _ProfileHeader({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(children: [
        AvatarDisplay(avatarUrl: user.avatarUrl, size: 60, showGlow: true),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.name,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('@${user.username}',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text('${user.credits}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ])),
      ]),
    );
  }
}

// ── Custom Tab Bar ──────────────────────────────────
class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _CustomTabBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final TabController controller;
  final bool isDark;
  final int selectedIndex;
  const _CustomTabBar(
      {required this.tabs,
      required this.controller,
      required this.isDark,
      required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06))),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final tab = e.value;
          final sel = i == selectedIndex;
          final isLogout = i == 6;
          final isSpin = i == 5;
          final color = isLogout
              ? AppColors.danger
              : isSpin
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF2563EB);
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon,
                          size: 18,
                          color: sel
                              ? color
                              : (isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.3))),
                      const SizedBox(height: 2),
                      Text(tab.label,
                          style: TextStyle(
                              fontSize: 8.5,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel
                                  ? color
                                  : (isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.28)),
                              letterSpacing: 0.2)),
                    ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Transactions Tab ────────────────────────────────
class _TransactionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthService>().uid;
    final fs = context.read<FirestoreService>();
    return StreamBuilder<List<TransactionModel>>(
      stream: fs.transactionsStream(uid),
      builder: (_, snap) {
        final txns = snap.data ?? [];
        if (txns.isEmpty)
          return _EmptyState(
              icon: Icons.receipt_long_rounded,
              message: 'No transactions yet',
              sub: 'Credits will appear here after sessions',
              isDark: isDark);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txns.length,
          itemBuilder: (_, i) {
            final t = txns[i];
            final isCredit = t.type == 'credit';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isCredit
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.danger.withOpacity(0.2))),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: isCredit
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        isCredit
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isCredit ? AppColors.success : AppColors.danger,
                        size: 18)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t.featureType,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      Text(t.createdAt.toString().substring(0, 16),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.35))),
                    ])),
                Text('${isCredit ? '+' : '-'}${t.amount}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color:
                            isCredit ? AppColors.success : AppColors.danger)),
                const SizedBox(width: 4),
                Icon(Icons.bolt_rounded,
                    size: 14,
                    color: isCredit ? AppColors.success : AppColors.danger),
              ]),
            );
          },
        );
      },
    );
  }
}

// ── Avatar Tab ──────────────────────────────────────
class _AvatarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<FirestoreService>().currentUser;
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarDisplay(avatarUrl: user?.avatarUrl, size: 150, showGlow: true),
          const SizedBox(height: 20),
          Text(hasAvatar ? 'Looking good!' : 'No avatar yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(
              hasAvatar
                  ? 'Tap below to update your avatar'
                  : 'Create your personalised avatar',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AvatarCreatorScreen())),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    hasAvatar
                        ? Icons.edit_rounded
                        : Icons.face_retouching_natural_rounded,
                    color: Colors.white,
                    size: 20),
                const SizedBox(width: 10),
                Text(hasAvatar ? 'Edit Avatar' : 'Create Avatar',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.verified_rounded,
                size: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3)),
            const SizedBox(width: 5),
            Text('Powered by Ready Player Me',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3))),
          ]),
        ],
      ),
    );
  }
}

// ── History Tab ─────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _EmptyState(
        icon: Icons.history_rounded,
        message: 'No session history yet',
        sub: 'Completed sessions will appear here',
        isDark: isDark);
  }
}

// ── Device Tab ──────────────────────────────────────
class _DeviceTab extends StatelessWidget {
  final bool _rescanning;
  final VoidCallback _onRescan;
  const _DeviceTab({required bool rescanning, required VoidCallback onRescan})
      : _rescanning = rescanning,
        _onRescan = onRescan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = context.watch<FirestoreService>().currentUser?.device;
    if (d == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DeviceSection(title: 'Hardware', isDark: isDark, rows: [
          _DeviceRow(
              icon: Icons.phone_android_rounded,
              label: 'Model',
              value: d.model,
              isDark: isDark),
          _DeviceRow(
              icon: Icons.android_rounded,
              label: 'OS',
              value: '${d.os} ${d.osVersion}',
              isDark: isDark),
        ]),
        const SizedBox(height: 12),
        _DeviceSection(title: 'Battery', isDark: isDark, rows: [
          _DeviceRow(
              icon: Icons.battery_full_rounded,
              label: 'Level',
              value: '${d.batteryPercentage}%',
              isDark: isDark),
          _DeviceRow(
              icon: Icons.electric_bolt_rounded,
              label: 'Capacity',
              value: d.batteryCapacity != null
                  ? '${d.batteryCapacity} mAh'
                  : 'Unknown',
              isDark: isDark),
          _DeviceRow(
              icon: Icons.cable_rounded,
              label: 'Standard',
              value: d.chargingStandard,
              isDark: isDark),
        ]),
        const SizedBox(height: 12),
        _DeviceSection(title: 'Connectivity', isDark: isDark, rows: [
          _DeviceRow(
              icon: Icons.bluetooth_rounded,
              label: 'Bluetooth',
              value: d.bluetoothSupported ? 'Supported' : 'Unknown',
              isDark: isDark),
          _DeviceRow(
              icon: Icons.wifi_rounded,
              label: 'WiFi Direct',
              value: d.wifiDirectSupported ? 'Yes' : 'No',
              isDark: isDark),
          _DeviceRow(
              icon: Icons.battery_charging_full_rounded,
              label: 'Wireless Chg',
              value: d.wirelessCharging ? 'Yes' : 'No',
              isDark: isDark),
          _DeviceRow(
              icon: Icons.rotate_left_rounded,
              label: 'Reverse WC',
              value: d.reverseWirelessCharging ? 'Yes' : 'No',
              isDark: isDark),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _rescanning ? null : _onRescan,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
                gradient: _rescanning
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                color: _rescanning
                    ? (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06))
                    : null,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: _rescanning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 10),
                            Text('Scanning…',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))
                          ])
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Re-scan Device',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14))
                          ])),
          ),
        ),
        const SizedBox(height: 8),
        Text('Device info is detected automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.black.withOpacity(0.25))),
      ],
    );
  }
}

class _DeviceSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> rows;
  const _DeviceSection(
      {required this.title, required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3)))),
      Container(
        decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06))),
        child: Column(
            children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(children: [
            e.value,
            if (!isLast)
              Divider(
                  height: 1,
                  indent: 48,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05)),
          ]);
        }).toList()),
      ),
    ]);
  }
}

class _DeviceRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  const _DeviceRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(icon,
            size: 16,
            color: isDark
                ? Colors.white.withOpacity(0.35)
                : Colors.black.withOpacity(0.3)),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.55)
                    : Colors.black.withOpacity(0.55))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ]),
    );
  }
}

// ── Files Tab ───────────────────────────────────────
class _FilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthService>().uid;
    final fs = context.read<FirestoreService>();
    return StreamBuilder<List<AppFileModel>>(
      stream: fs.filesStream(uid),
      builder: (_, snap) {
        final files = snap.data ?? [];
        if (files.isEmpty)
          return _EmptyState(
              icon: Icons.folder_open_rounded,
              message: 'No files yet',
              sub: 'Received files will appear here',
              isDark: isDark);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: files.length,
          itemBuilder: (_, i) {
            final f = files[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06))),
              child: Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.insert_drive_file_rounded,
                        color: AppColors.primaryPurple, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(f.fileName,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      Text(
                          '${f.fileSizeLabel}  ·  ${f.createdAt.toString().substring(0, 10)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.35))),
                    ])),
              ]),
            );
          },
        );
      },
    );
  }
}

// ── Logout Tab ──────────────────────────────────────
class _LogoutTab extends StatefulWidget {
  @override
  State<_LogoutTab> createState() => _LogoutTabState();
}

class _LogoutTabState extends State<_LogoutTab> {
  bool _confirming = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<FirestoreService>().currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06))),
          child: Row(children: [
            AvatarDisplay(avatarUrl: user?.avatarUrl, size: 48),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(user?.name ?? '',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A))),
                  Text(user?.email ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.4))),
                ])),
          ]),
        ),
        const Spacer(),
        if (!_confirming) ...[
          GestureDetector(
            onTap: () => setState(() => _confirming = true),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.4), width: 1.5),
                  color: AppColors.danger.withOpacity(0.06)),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.power_settings_new_rounded,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger)),
                  ]),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.danger.withOpacity(0.2))),
            child: Column(children: [
              const Icon(Icons.power_settings_new_rounded,
                  color: AppColors.danger, size: 28),
              const SizedBox(height: 10),
              Text('Sign out of AmpUp?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text("You'll need to sign in again",
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4))),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => setState(() => _confirming = false),
              child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05)),
                  child: Center(
                      child: Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))))),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: GestureDetector(
              onTap: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await context.read<AuthService>().signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const WelcomeScreen()),
                          (_) => false);
                    },
              child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.danger,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.danger.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]),
                  child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign Out',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)))),
            )),
          ]),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Empty State ─────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  final bool isDark;
  const _EmptyState(
      {required this.icon,
      required this.message,
      required this.sub,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04)),
            child: Icon(icon,
                size: 28,
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.black.withOpacity(0.2))),
        const SizedBox(height: 14),
        Text(message,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.4))),
        const SizedBox(height: 4),
        Text(sub,
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.black.withOpacity(0.25))),
      ]),
    );
  }
}
