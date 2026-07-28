import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/database/isar_models.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GoalProgressModel> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadHistoricalData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadHistoricalData();
    }
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      final now = DateTime.now();
      DateTime startDate;

      switch (_tabController.index) {
        case 0:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 1:
          startDate = now.subtract(const Duration(days: 28));
          break;
        case 2:
        default:
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
      }

      final history = await db.getGoalHistory(startDate, now);
      setState(() {
        _history = history.reversed.toList();
      });
    } catch (_) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vitals = ref.watch(vitalsStreamProvider).value ?? BleVitalsData.empty();
    final profile = ref.watch(profileProvider);

    final distanceKm = CalorieCalculator.calculateDistanceKm(
      steps: vitals.steps,
      heightCm: profile.heightCm ?? 168.0,
      gender: profile.gender ?? 'Female',
    );

    final activeMinutes = CalorieCalculator.estimateActiveMinutes(vitals.steps);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryTabColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(currentIndex: 1),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text('Activity Logs', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryTabColor,
          labelColor: primaryTabColor,
          unselectedLabelColor: subtitleColor,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GlassCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Today\'s Totals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.steps.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${vitals.steps} Steps',
                                style: const TextStyle(color: AppTheme.steps, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              context: context,
                              icon: Icons.local_fire_department_rounded,
                              value: vitals.caloriesBurned > 0 ? '${vitals.caloriesBurned.round()}' : '0',
                              label: 'Calories (kcal)',
                              color: AppTheme.calories,
                            ),
                            _buildMetricItem(
                              context: context,
                              icon: Icons.map_rounded,
                              value: distanceKm.toStringAsFixed(2),
                              label: 'Distance (km)',
                              color: AppTheme.steps,
                            ),
                            _buildMetricItem(
                              context: context,
                              icon: Icons.timer_rounded,
                              value: '$activeMinutes',
                              label: 'Active (mins)',
                              color: AppTheme.tempAmber,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('History List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonList()
                      : _history.isEmpty
                          ? Center(child: Text('No historical logs found.', style: TextStyle(color: subtitleColor.withOpacity(0.6))))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 100.0), // Padding for FloatingNavBar
                              physics: const BouncingScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final item = _history[index];
                                final formattedDate = DateFormat('EEEE, MMM d').format(item.date ?? DateTime.now());
                                final caloriesStr = item.caloriesBurned != null ? '${item.caloriesBurned!.round()}' : '0';
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: AppTheme.steps.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.directions_walk_rounded, color: AppTheme.steps),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(formattedDate, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Steps: ${item.stepsCount} | Calories: $caloriesStr kcal',
                                                style: TextStyle(fontSize: 12, color: subtitleColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (item.stepsGoalAchieved == true)
                                          const Icon(Icons.emoji_events_rounded, color: AppTheme.warning, size: 24)
                                        else
                                          Icon(Icons.circle_outlined, color: subtitleColor.withOpacity(0.2), size: 24),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
        Text(label, style: TextStyle(fontSize: 10, color: subtitleColor)),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: SkeletonLoader(width: double.infinity, height: 60, borderRadius: 16),
      ),
    );
  }
}
