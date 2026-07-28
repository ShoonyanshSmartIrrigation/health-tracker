import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final bleConnection = ref.watch(bleConnectionStateProvider).value ?? BleConnectionState.disconnected;
    final isConnected = bleConnection == BleConnectionState.connected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(currentIndex: 0),
      body: Stack(
        children: [
          // Background Color matching theme specifications
          Container(color: bgColor),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (!isConnected) _buildDisconnectedBanner(),
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0), // Extra bottom padding for floating bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHealthScoreRing(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Live Vitals', onAction: () => context.push('/live')),
                        const SizedBox(height: 12),
                        _buildVitalsGrid(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Weekly Activity', onAction: () => context.push('/analytics')),
                        const SizedBox(height: 12),
                        _buildWeeklyChartCard(),
                        const SizedBox(height: 24),
                        _buildGoalsSummaryCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Container(
      color: AppTheme.error.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Wearable Disconnected. Tap to pair.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/device'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Connect', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
              ),
              Text(
                profile.name ?? 'Jane Doe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Badge(
                  label: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9)),
                  backgroundColor: AppTheme.error,
                  child: Icon(Icons.notifications_outlined, size: 26, color: titleColor),
                ),
                onPressed: () => context.push('/notifications'),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                      width: 1.5,
                    ),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onAction}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: titleColor),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text('View All', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildHealthScoreRing() {
    final vitals = ref.watch(vitalsStreamProvider).value ?? BleVitalsData.empty();
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final stepGoal = profile.dailyStepGoal ?? 10000;
    final stepProgress = stepGoal > 0 ? (vitals.steps / stepGoal) : 0.0;
    final spo2HealthIndex = vitals.spo2 >= 95 ? 1.0 : (vitals.spo2 > 0 ? (vitals.spo2 / 95.0) : 1.0);
    final double healthScorePercentage = ((stepProgress.clamp(0.0, 1.0) * 0.6) + (spo2HealthIndex.clamp(0.0, 1.0) * 0.4)) * 100;
    final displayScore = healthScorePercentage.round();

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          ProgressRing(
            progress: healthScorePercentage / 100.0,
            size: 150,
            strokeWidth: 12,
            gradientColors: const [AppTheme.steps, AppTheme.tempAmber],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Health Score', style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '$displayScore%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor),
                ),
                const SizedBox(height: 2),
                const Text('Optimal', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on_rounded, color: AppTheme.warning, size: 16),
              const SizedBox(width: 6),
              Text(
                'Goal progress optimal. Keep moving!',
                style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVitalsGrid() {
    final vitals = ref.watch(vitalsStreamProvider).value ?? BleVitalsData.empty();
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.45,
      children: [
        _buildVitalCard(
          title: 'Heart Rate',
          value: vitals.heartRate > 0 ? '${vitals.heartRate}' : '--',
          unit: 'BPM',
          icon: Icons.favorite_rounded,
          color: AppTheme.heartRate,
          tapRoute: '/live',
          trendPoints: const [71, 74, 72, 79, 73, 76, 72, 74],
          statusText: vitals.heartRate > 100 ? 'High' : 'Normal',
        ),
        _buildVitalCard(
          title: 'Steps Count',
          value: '${vitals.steps}',
          unit: 'steps',
          icon: Icons.directions_walk_rounded,
          color: AppTheme.steps,
          tapRoute: '/activity',
          trendPoints: const [2000, 3100, 3800, 4200, 4800, 5200, 6000],
          statusText: 'Active',
        ),
        _buildVitalCard(
          title: 'Blood Oxygen',
          value: vitals.spo2 > 0 ? '${vitals.spo2}%' : '--',
          unit: 'SpO₂',
          icon: Icons.opacity_rounded,
          color: AppTheme.spo2Mint,
          tapRoute: '/live',
          trendPoints: const [98, 97, 98, 99, 98, 98, 97, 98],
          statusText: vitals.spo2 < 93 && vitals.spo2 > 0 ? 'Low' : 'Optimal',
        ),
        _buildVitalCard(
          title: 'Temperature',
          value: vitals.temperature > 0 ? '${vitals.temperature}°' : '--',
          unit: 'C',
          icon: Icons.thermostat_rounded,
          color: AppTheme.tempAmber,
          tapRoute: '/analytics',
          trendPoints: const [36.5, 36.6, 36.7, 36.5, 36.8, 36.7],
          statusText: 'Normal',
        ),
        _buildVitalCard(
          title: 'Calories Active',
          value: vitals.caloriesBurned > 0 ? '${vitals.caloriesBurned.round()}' : '--',
          unit: 'kcal',
          icon: Icons.local_fire_department_rounded,
          color: AppTheme.calories,
          tapRoute: '/activity',
          trendPoints: const [100, 180, 240, 310, 420, 480],
          statusText: 'Burned',
        ),
        _buildVitalCard(
          title: 'Band Battery',
          value: vitals.batteryLevel > 0 ? '${vitals.batteryLevel}%' : '--',
          unit: 'batt',
          icon: Icons.battery_charging_full_rounded,
          color: AppTheme.batteryGreen,
          tapRoute: '/device',
          trendPoints: const [100, 95, 90, 88, 85],
          statusText: vitals.batteryLevel < 20 && vitals.batteryLevel > 0 ? 'Low' : 'Good',
        ),
      ],
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String tapRoute,
    required List<double> trendPoints,
    required String statusText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: () => context.push(tapRoute),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: valueColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            unit,
                            style: TextStyle(fontSize: 10, color: labelColor),
                          ),
                        ],
                      ),
                      Text(
                        title,
                        style: TextStyle(fontSize: 11, color: labelColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 22,
                  child: CustomPaint(
                    painter: MiniSparklinePainter(trendPoints, color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Step Analysis', style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12000,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double val, TitleMeta meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Text(
                            days[val.toInt()],
                            style: TextStyle(color: subtitleColor.withOpacity(0.6), fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _buildBarGroup(0, 6200),
                  _buildBarGroup(1, 8400),
                  _buildBarGroup(2, 9100),
                  _buildBarGroup(3, 7300),
                  _buildBarGroup(4, 10200, isToday: true),
                  _buildBarGroup(5, 0),
                  _buildBarGroup(6, 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, {bool isToday = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBarColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isToday ? AppTheme.heartRate : primaryBarColor.withOpacity(0.7),
          width: 14,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 12000,
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.warning, size: 22),
              const SizedBox(width: 8),
              Text('Streak Achieved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You are on a 5-day step streak! Complete today\'s goal to extend it.',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (index) => CircleAvatar(
                radius: 14,
                backgroundColor: index < 5
                    ? AppTheme.success.withOpacity(0.15)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                child: Icon(
                  index < 5 ? Icons.check : Icons.circle_outlined,
                  size: 14,
                  color: index < 5 ? AppTheme.success : (isDark ? Colors.white24 : Colors.black26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  MiniSparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
