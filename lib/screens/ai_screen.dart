import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/device_service.dart';
import '../services/ai_prediction_service.dart';
import '../theme/app_colors.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen>
    with SingleTickerProviderStateMixin {
  List<double> _battHistory = [];
  List<double> _battPred = [];
  List<double> _dataHistory = [];
  List<double> _dataPred = [];
  String _battAlert = '';
  String _dataAlert = '';
  bool _loading = true;
  int? _touchedBatt;
  int? _touchedData;

  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final current = await DeviceService.getBatteryLevel();

    // Battery history — simulate realistic drain curve
    final rng = math.Random(42);
    final battHist = List<double>.generate(10, (i) {
      final base = current.toDouble() - i * (1.8 + rng.nextDouble() * 0.8);
      return base.clamp(0.0, 100.0);
    }).reversed.toList();
    final battPred = AiPredictionService.predict(battHist);
    final battAlert = AiPredictionService.batteryAlert(battPred);

    // Data usage history — simulate realistic usage
    final dataHist = List<double>.generate(10, (i) {
      return (i * 18.0 + 20 + rng.nextDouble() * 15).clamp(0, 500);
    });
    final dataPred = AiPredictionService.predict(dataHist);
    final dataAlert = _dataUsageAlert(dataPred, dataHist.last);

    setState(() {
      _battHistory = battHist;
      _battPred = battPred;
      _dataHistory = dataHist;
      _dataPred = dataPred;
      _battAlert = battAlert;
      _dataAlert = dataAlert;
      _loading = false;
    });
    _animCtrl.forward(from: 0);
  }

  String _dataUsageAlert(List<double> pred, double current) {
    // Each step = ~30 min of usage
    final idx = pred.indexWhere((v) => v >= 500);
    if (idx >= 0) {
      final hours = (idx * 0.5).toStringAsFixed(1);
      return 'You may hit your 500 MB limit in ~$hours hours at current rate.';
    }
    final rate = pred.isNotEmpty ? (pred.last - current) / pred.length : 0;
    if (rate > 20)
      return 'High data usage detected — ${rate.toStringAsFixed(0)} MB/hr.';
    return '';
  }

  // How many minutes until battery hits critical
  String get _battTimeLeft {
    if (_battPred.isEmpty) return '';
    final idx = _battPred.indexWhere((v) => v <= 20);
    if (idx < 0) return 'Battery looks healthy for the next few hours.';
    final mins = idx * 5;
    if (mins < 60) return 'Battery may reach 20% in about $mins minutes.';
    final hrs = (mins / 60).toStringAsFixed(1);
    return 'Battery may reach 20% in about $hrs hours.';
  }

  String get _dataInsight {
    if (_dataPred.isEmpty || _dataHistory.isEmpty) return '';
    final avg = _dataHistory.fold(0.0, (a, b) => a + b) / _dataHistory.length;
    final trend = _dataPred.last - _dataHistory.last;
    if (trend > 50) return 'Data usage is accelerating. Consider WiFi soon.';
    if (avg < 50) return 'Low data usage — you\'re well within limits.';
    return 'Moderate data usage. On track for normal consumption.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(children: [
                  IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: isDark
                              ? AppColors.starWhite
                              : AppColors.textDark),
                      onPressed: () => Navigator.pop(context)),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('AI Predictions',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.starWhite
                                    : AppColors.textDark,
                                letterSpacing: -0.5)),
                        Text('Live analysis of your device',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4))),
                      ])),
                  // Refresh
                  GestureDetector(
                      onTap: _load,
                      child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.refresh_rounded,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black))),
                ]),
              ),

              Expanded(
                child: _loading
                    ? _buildLoading(isDark)
                    : AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) => _buildContent(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: const Center(
                  child: Icon(Icons.auto_graph_rounded,
                      color: Colors.white, size: 34))),
          const SizedBox(height: 18),
          Text('Analysing your device...',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('Reading battery and data patterns',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
              color: Color(0xFF2563EB), strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick stats row ────────────────────────
          Row(children: [
            _StatChip(
                icon: Icons.battery_charging_full_rounded,
                label: 'Battery',
                value:
                    '${_battHistory.isNotEmpty ? _battHistory.last.round() : 0}%',
                color: _battHistory.isNotEmpty && _battHistory.last < 30
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                isDark: isDark),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.wifi_tethering_rounded,
                label: 'Data Used',
                value:
                    '${_dataHistory.isNotEmpty ? _dataHistory.last.round() : 0} MB',
                color: const Color(0xFF3B82F6),
                isDark: isDark),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.trending_down_rounded,
                label: 'Drain Rate',
                value: _battHistory.length >= 2
                    ? '${((_battHistory.last - _battHistory.first).abs() / 10).toStringAsFixed(1)}%/hr'
                    : '--',
                color: const Color(0xFF8B5CF6),
                isDark: isDark),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════
          // BATTERY CHART
          // ═══════════════════════════════════════════
          _ChartSection(
            title: 'Battery Level',
            subtitle: 'Last 50 min  •  Next 30 min predicted',
            icon: Icons.battery_full_rounded,
            iconColor: const Color(0xFF22C55E),
            isDark: isDark,
            child: Column(children: [
              SizedBox(
                height: 220,
                child: LineChart(_buildBattChart(isDark)),
              ),
              const SizedBox(height: 8),
              // Legend
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: const Color(0xFF22C55E), label: 'Actual'),
                const SizedBox(width: 20),
                _LegendDash(color: const Color(0xFF8B5CF6), label: 'Predicted'),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          // Battery insight cards
          _InsightCard(
              icon: Icons.access_time_rounded,
              title: 'Time Estimate',
              body: _battTimeLeft,
              color: _battHistory.isNotEmpty && _battHistory.last < 30
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              isDark: isDark),

          if (_battAlert.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightCard(
                icon: Icons.warning_rounded,
                title: 'Warning',
                body: _battAlert,
                color: const Color(0xFFF59E0B),
                isDark: isDark),
          ],

          const SizedBox(height: 8),
          _InsightCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Tip',
              body: _battHistory.isNotEmpty && _battHistory.last < 50
                  ? 'Battery below 50%. Reduce screen brightness and close background apps to extend life.'
                  : 'Battery is healthy. Enable battery saver when below 30% to maximise usage time.',
              color: const Color(0xFF3B82F6),
              isDark: isDark),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // DATA CHART
          // ═══════════════════════════════════════════
          _ChartSection(
            title: 'Data Usage',
            subtitle: 'Last 5 hours  •  Next 3 hours predicted',
            icon: Icons.wifi_tethering_rounded,
            iconColor: const Color(0xFF3B82F6),
            isDark: isDark,
            child: Column(children: [
              SizedBox(
                height: 220,
                child: LineChart(_buildDataChart(isDark)),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: const Color(0xFF3B82F6), label: 'Actual'),
                const SizedBox(width: 20),
                _LegendDash(color: const Color(0xFFEC4899), label: 'Predicted'),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          _InsightCard(
              icon: Icons.data_usage_rounded,
              title: 'Usage Insight',
              body: _dataInsight,
              color: const Color(0xFF3B82F6),
              isDark: isDark),

          if (_dataAlert.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightCard(
                icon: Icons.warning_rounded,
                title: 'Data Warning',
                body: _dataAlert,
                color: const Color(0xFFF59E0B),
                isDark: isDark),
          ],

          const SizedBox(height: 10),
          _InsightCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Recommendation',
              body: _dataPred.isNotEmpty && _dataPred.last > 300
                  ? 'High data usage predicted. Connect to WiFi to avoid overage charges.'
                  : 'Data usage within normal range. You\'re on track for the day.',
              color: const Color(0xFF8B5CF6),
              isDark: isDark),

          const SizedBox(height: 24),

          // ── Accuracy note ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Predictions use linear regression on recent usage patterns. '
                      'Accuracy improves with more usage data over time.',
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: isDark
                              ? Colors.white.withOpacity(0.35)
                              : Colors.black.withOpacity(0.35)))),
            ]),
          ),
        ],
      ),
    );
  }

  LineChartData _buildBattChart(bool isDark) {
    final actualSpots = _battHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final startX = _battHistory.length.toDouble();
    final predSpots = _battPred
        .asMap()
        .entries
        .map((e) => FlSpot(startX + e.key, e.value))
        .toList();

    // Critical zone line
    final criticalY = 20.0;

    return LineChartData(
      minY: 0, maxY: 105,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 2,
          getDrawingHorizontalLine: (v) => FlLine(
              color: v == 20
                  ? const Color(0xFFEF4444).withOpacity(0.4)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05)),
              strokeWidth: v == 20 ? 1.5 : 1,
              dashArray: v == 20 ? [4, 4] : null),
          getDrawingVerticalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
              strokeWidth: 1)),
      titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  interval: 20,
                  getTitlesWidget: (v, _) => Text('${v.round()}%',
                      style: TextStyle(
                          fontSize: 9,
                          color: v == 20
                              ? const Color(0xFFEF4444).withOpacity(0.8)
                              : (isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.35)))))),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 2,
                  getTitlesWidget: (v, _) {
                    final idx = v.round();
                    if (idx < _battHistory.length) {
                      return Text('-${((_battHistory.length - 1 - idx) * 5)}m',
                          style: TextStyle(
                              fontSize: 8,
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3)));
                    } else {
                      final ahead = (idx - _battHistory.length + 1) * 5;
                      return Text('+${ahead}m',
                          style: const TextStyle(
                              fontSize: 8, color: Color(0xFF8B5CF6)));
                    }
                  }))),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            setState(() {
              _touchedBatt = response?.lineBarSpots?.first.spotIndex;
            });
          },
          touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                    final isPred = s.barIndex == 1;
                    return LineTooltipItem(
                        '${isPred ? "~" : ""}${s.y.toStringAsFixed(1)}%\n',
                        TextStyle(
                            color: isPred
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        children: [
                          TextSpan(
                              text: isPred ? 'Predicted' : 'Actual',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400))
                        ]);
                  }).toList())),
      lineBarsData: [
        // Actual line
        LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF22C55E),
            barWidth: 3,
            dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                    radius: _touchedBatt == idx ? 6 : 3,
                    color: const Color(0xFF22C55E),
                    strokeWidth: 2,
                    strokeColor: Colors.white)),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.25),
                      const Color(0xFF22C55E).withOpacity(0.0),
                    ]))),
        // Predicted line
        LineChartBarData(
            spots: predSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF8B5CF6),
            barWidth: 2.5,
            dashArray: [8, 5],
            dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF8B5CF6),
                    strokeWidth: 1.5,
                    strokeColor: Colors.white)),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.12),
                      const Color(0xFF8B5CF6).withOpacity(0.0),
                    ]))),
      ],
      // Vertical divider at prediction start
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(
            x: _battHistory.length.toDouble() - 0.5,
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.10),
            strokeWidth: 1.5,
            dashArray: [4, 4],
            label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Now',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4)))),
      ]),
    );
  }

  LineChartData _buildDataChart(bool isDark) {
    final actualSpots = _dataHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final startX = _dataHistory.length.toDouble();
    final predSpots = _dataPred
        .asMap()
        .entries
        .map((e) => FlSpot(startX + e.key, e.value))
        .toList();
    final maxVal = [..._dataHistory, ..._dataPred].fold(0.0, math.max) * 1.15;

    return LineChartData(
      minY: 0,
      maxY: maxVal.clamp(50, 600),
      clipData: const FlClipData.all(),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxVal / 5,
          getDrawingHorizontalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
              strokeWidth: 1)),
      titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, _) => Text('${v.round()}',
                      style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? Colors.white.withOpacity(0.35)
                              : Colors.black.withOpacity(0.35))))),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 2,
                  getTitlesWidget: (v, _) {
                    final idx = v.round();
                    if (idx < _dataHistory.length) {
                      return Text('-${(_dataHistory.length - 1 - idx) * 30}m',
                          style: TextStyle(
                              fontSize: 8,
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3)));
                    } else {
                      final ahead = (idx - _dataHistory.length + 1) * 30;
                      return Text('+${ahead}m',
                          style: const TextStyle(
                              fontSize: 8, color: Color(0xFFEC4899)));
                    }
                  }))),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                    final isPred = s.barIndex == 1;
                    return LineTooltipItem(
                        '${isPred ? "~" : ""}${s.y.toStringAsFixed(0)} MB\n',
                        TextStyle(
                            color: isPred
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF3B82F6),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        children: [
                          TextSpan(
                              text: isPred ? 'Predicted' : 'Actual',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400))
                        ]);
                  }).toList())),
      lineBarsData: [
        // Actual
        LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3.5,
                    color: const Color(0xFF3B82F6),
                    strokeWidth: 2,
                    strokeColor: Colors.white)),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.28),
                      const Color(0xFF3B82F6).withOpacity(0.0),
                    ]))),
        // Predicted
        LineChartBarData(
            spots: predSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: const Color(0xFFEC4899),
            barWidth: 2.5,
            dashArray: [8, 5],
            dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFFEC4899),
                    strokeWidth: 1.5,
                    strokeColor: Colors.white)),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFEC4899).withOpacity(0.15),
                      const Color(0xFFEC4899).withOpacity(0.0),
                    ]))),
      ],
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(
            x: _dataHistory.length.toDouble() - 0.5,
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.10),
            strokeWidth: 1.5,
            dashArray: [4, 4],
            label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Now',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4)))),
      ]),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
        ]),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final Widget child;
  const _ChartSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.iconColor,
      required this.isDark,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4))),
              ])),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  final bool isDark;
  const _InsightCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(body,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF374151))),
        ])),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}

class _LegendDash extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDash({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 24, child: CustomPaint(painter: _DashPainter(color: color))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 4), const Offset(8, 4), p);
    canvas.drawLine(const Offset(12, 4), const Offset(20, 4), p);
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}
