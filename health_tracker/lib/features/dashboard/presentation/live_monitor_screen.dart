import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class LiveMonitorScreen extends ConsumerStatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  ConsumerState<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends ConsumerState<LiveMonitorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;
  
  final List<FlSpot> _hrSpots = [];
  final List<FlSpot> _spo2Spots = [];
  int _dataCount = 0;
  
  StreamSubscription? _vitalsSub;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _heartScaleAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOutBack),
    );

    _listenToLiveVitals();
  }

  @override
  void dispose() {
    _vitalsSub?.cancel();
    _heartController.dispose();
    super.dispose();
  }

  void _listenToLiveVitals() {
    final ble = ref.read(bleServiceProvider);
    
    _vitalsSub = ble.vitalsStream.listen((vitals) {
      if (vitals.heartRate > 0) {
        final ms = (60000 / vitals.heartRate).round();
        if (mounted && ms > 100 && ms < 3000) {
          _heartController.duration = Duration(milliseconds: (ms / 2).round());
          if (!_heartController.isAnimating) {
            _heartController.repeat(reverse: true);
          }
        }
      } else {
        if (mounted) _heartController.stop();
      }

      setState(() {
        _dataCount++;
        
        _hrSpots.add(FlSpot(_dataCount.toDouble(), vitals.heartRate.toDouble()));
        if (_hrSpots.length > 20) {
          _hrSpots.removeAt(0);
        }

        _spo2Spots.add(FlSpot(_dataCount.toDouble(), vitals.spo2.toDouble()));
        if (_spo2Spots.length > 20) {
          _spo2Spots.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(bleConnectionStateProvider).value ?? BleConnectionState.disconnected;
    final isConnected = connectionState == BleConnectionState.connected;
    final vitals = ref.watch(vitalsStreamProvider).value ?? BleVitalsData.empty();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Live Vital Stream', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            child: isConnected
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPulseVisualizerCard(vitals.heartRate, vitals.spo2),
                        const SizedBox(height: 24),

                        _buildLiveChartCard(
                          title: 'Live Electrocardiogram Wave',
                          subtitle: 'Heart Rate Activity (BPM)',
                          spots: _hrSpots,
                          minY: 40,
                          maxY: 180,
                          color: AppTheme.heartRate,
                        ),
                        const SizedBox(height: 24),

                        _buildLiveChartCard(
                          title: 'Live Pulse Oximetry Wave',
                          subtitle: 'Oxygen Saturation (SpO₂ %)',
                          spots: _spo2Spots,
                          minY: 80,
                          maxY: 100,
                          color: AppTheme.spo2Mint,
                        ),
                        const SizedBox(height: 24),

                        _buildSystemStatusCard(vitals),
                      ],
                    ),
                  )
                : _buildDisconnectedErrorView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseVisualizerCard(int hr, int spo2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRippleCircle(70, 0.4),
                    _buildRippleCircle(95, 0.2),
                    ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: Container(
                        height: 64,
                        width: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.heartRate,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.heartRate,
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Live Rhythm', style: TextStyle(color: subtitleColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hr > 0 ? '$hr' : '--',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    const SizedBox(width: 4),
                    const Text('BPM', style: TextStyle(fontSize: 14, color: AppTheme.heartRate, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      spo2 > 0 ? '$spo2' : '--',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    const SizedBox(width: 4),
                    const Text('% SpO₂', style: TextStyle(fontSize: 14, color: AppTheme.spo2Mint, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRippleCircle(double size, double opacity) {
    return AnimatedBuilder(
      animation: _heartScaleAnimation,
      builder: (context, child) {
        final scale = 1.0 + (_heartScaleAnimation.value - 0.9) * 1.5;
        return Container(
          height: size * scale,
          width: size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.heartRate.withOpacity(opacity * (1.5 - _heartScaleAnimation.value)),
          ),
        );
      },
    );
  }

  Widget _buildLiveChartCard({
    required String title,
    required String subtitle,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: subtitleColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: spots.length < 2
                ? Center(child: Text('Awaiting vital stream...', style: TextStyle(color: subtitleColor.withOpacity(0.5))))
                : LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: const LineTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          strokeWidth: 1.0,
                        ),
                      ),
                      titlesData: const FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [color.withOpacity(0.25), color.withOpacity(0.01)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(BleVitalsData vitals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final hasHrAlarm = vitals.heartRate > 120 || (vitals.heartRate > 0 && vitals.heartRate < 45);
    final hasOxygenAlarm = vitals.spo2 > 0 && vitals.spo2 < 93;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Diagnostics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                hasHrAlarm ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: hasHrAlarm ? AppTheme.error : AppTheme.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasHrAlarm 
                      ? 'Caution: Abnormal Heart Rhythm detected.' 
                      : 'Heart rate limits are within normal boundaries.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasOxygenAlarm ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: hasOxygenAlarm ? AppTheme.error : AppTheme.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasOxygenAlarm 
                      ? 'Caution: Oxygen level drops below safe thresholds.' 
                      : 'Blood Oxygen (SpO₂) is optimal.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedErrorView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bluetooth_disabled_rounded, color: AppTheme.error, size: 64),
              const SizedBox(height: 16),
              Text('Device Disconnected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(height: 8),
              Text(
                'Live monitoring requires an active connection to your custom health band.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Pairing Settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
