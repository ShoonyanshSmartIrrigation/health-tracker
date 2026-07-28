import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedVitalIndex = 0; // 0: HR, 1: SpO2, 2: Steps, 3: Temp
  String _timeFrame = 'Week'; // Week, Month, Year

  final List<String> _vitalsNames = ['Heart Rate', 'Oxygen (SpO₂)', 'Steps Count', 'Temperature'];
  final List<Color> _vitalsColors = [
    AppTheme.heartRate,
    AppTheme.spo2Mint,
    AppTheme.steps,
    AppTheme.tempAmber,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _vitalsColors[_selectedVitalIndex];
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(currentIndex: 2),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text('Detailed Analytics', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeframeSelector(),
                  const SizedBox(height: 20),
                  _buildSegmentedVitalSelector(),
                  const SizedBox(height: 24),
                  _buildTrendChartCard(activeColor),
                  const SizedBox(height: 24),
                  _buildSummaryStatisticsCard(),
                  const SizedBox(height: 24),
                  _buildHealthInsightsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Week', 'Month', 'Year'].map((t) {
        final isSelected = _timeFrame == t;
        return GestureDetector(
          onTap: () {
            setState(() {
              _timeFrame = t;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activeBtnColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                color: isSelected ? Colors.white : labelColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentedVitalSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_vitalsNames.length, (index) {
          final isSelected = _selectedVitalIndex == index;
          final color = _vitalsColors[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVitalIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    index == 0
                        ? Icons.favorite_rounded
                        : index == 1
                            ? Icons.opacity_rounded
                            : index == 2
                                ? Icons.directions_walk_rounded
                                : Icons.thermostat_rounded,
                    color: isSelected ? color : labelColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _vitalsNames[index],
                    style: TextStyle(
                      color: isSelected ? color : labelColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrendChartCard(Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_vitalsNames[_selectedVitalIndex]} Trends',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
              ),
              Icon(Icons.zoom_in_map_rounded, color: labelColor.withOpacity(0.4), size: 18),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => isDark ? AppTheme.darkSurface.withOpacity(0.95) : AppTheme.lightSurface.withOpacity(0.95),
                    tooltipBorder: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      width: 1.0,
                    ),
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(_selectedVitalIndex == 3 ? 1 : 0)}',
                          TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: TextStyle(color: labelColor.withOpacity(0.5), fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Text(days[val.toInt()], style: TextStyle(color: labelColor.withOpacity(0.5), fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getTrendSpots(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 1.5,
                        strokeColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      ),
                    ),
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

  List<FlSpot> _getTrendSpots() {
    switch (_selectedVitalIndex) {
      case 0:
        return const [
          FlSpot(0, 72),
          FlSpot(1, 68),
          FlSpot(2, 85),
          FlSpot(3, 76),
          FlSpot(4, 94),
          FlSpot(5, 70),
          FlSpot(6, 73),
        ];
      case 1:
        return const [
          FlSpot(0, 98),
          FlSpot(1, 99),
          FlSpot(2, 97),
          FlSpot(3, 98),
          FlSpot(4, 98),
          FlSpot(5, 99),
          FlSpot(6, 98),
        ];
      case 2:
        return const [
          FlSpot(0, 6200),
          FlSpot(1, 8400),
          FlSpot(2, 9100),
          FlSpot(3, 7300),
          FlSpot(4, 10200),
          FlSpot(5, 4500),
          FlSpot(6, 8000),
        ];
      case 3:
        return const [
          FlSpot(0, 36.6),
          FlSpot(1, 36.8),
          FlSpot(2, 36.7),
          FlSpot(3, 36.5),
          FlSpot(4, 36.9),
          FlSpot(5, 36.7),
          FlSpot(6, 36.6),
        ];
      default:
        return [];
    }
  }

  Widget _buildSummaryStatisticsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    String average = '74';
    String peak = '98';
    String min = '62';
    String unit = '';

    switch (_selectedVitalIndex) {
      case 0:
        average = '76'; peak = '114'; min = '58'; unit = ' BPM';
        break;
      case 1:
        average = '98%'; peak = '99%'; min = '96%'; unit = '';
        break;
      case 2:
        average = '7,671'; peak = '10,200'; min = '4,500'; unit = ' steps';
        break;
      case 3:
        average = '36.7'; peak = '37.1'; min = '36.4'; unit = ' °C';
        break;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Summary Metrics', style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildStatMetricItem('Average', '$average$unit', AppTheme.steps)),
              Expanded(child: _buildStatMetricItem('Highest', '$peak$unit', AppTheme.heartRate)),
              Expanded(child: _buildStatMetricItem('Lowest', '$min$unit', AppTheme.tempAmber)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetricItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: labelColor),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHealthInsightsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    String message = '';
    IconData icon = Icons.check_circle_rounded;
    Color color = AppTheme.success;

    switch (_selectedVitalIndex) {
      case 0:
        message = 'Your average heart rate is stable at 76 BPM. Cardiorespiratory endurance is optimal.';
        icon = Icons.favorite_rounded;
        color = AppTheme.heartRate;
        break;
      case 1:
        message = 'Oxygen Saturation levels (SpO₂) remained at a safe average of 98.2%. No signs of hypoxia.';
        icon = Icons.opacity_rounded;
        color = AppTheme.spo2Mint;
        break;
      case 2:
        message = 'You completed your daily step goal twice this week. Try to increase steps on the weekend.';
        icon = Icons.directions_walk_rounded;
        color = AppTheme.steps;
        break;
      case 3:
        message = 'Body temperature averages 36.7°C, which is healthy. No febrile events recorded.';
        icon = Icons.thermostat_rounded;
        color = AppTheme.tempAmber;
        break;
    }

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Health Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor)),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
