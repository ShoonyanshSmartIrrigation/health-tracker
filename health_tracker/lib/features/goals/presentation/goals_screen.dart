import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/database/isar_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _stepsController;
  late TextEditingController _waterController;
  late TextEditingController _caloriesController;
  late TextEditingController _sleepController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _stepsController = TextEditingController(
      text: '${profile.dailyStepGoal ?? 10000}',
    );
    _waterController = TextEditingController(
      text: '${profile.dailyWaterGoal ?? 2500}',
    );
    _caloriesController = TextEditingController(
      text: '${profile.dailyCaloriesGoal ?? 2200}',
    );
    _sleepController = TextEditingController(
      text: '${profile.targetSleepHours ?? 8.0}',
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _waterController.dispose();
    _caloriesController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profileNotifier = ref.read(profileProvider.notifier);
      final profile = ref.read(profileProvider);

      final updatedProfile = UserProfileModel()
        ..id = profile.id
        ..name = profile.name
        ..age = profile.age
        ..gender = profile.gender
        ..heightCm = profile.heightCm
        ..weightKg = profile.weightKg
        ..dailyStepGoal = int.tryParse(_stepsController.text) ?? 10000
        ..dailyWaterGoal = int.tryParse(_waterController.text) ?? 2500
        ..dailyCaloriesGoal = int.tryParse(_caloriesController.text) ?? 2200
        ..targetSleepHours = double.tryParse(_sleepController.text) ?? 8.0;

      await profileNotifier.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily goals updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (_) {
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final primaryBtnColor = isDark
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'Goals & Achievements',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStreakHeaderCard(),
                    const SizedBox(height: 24),

                    _buildHeadingSection('Achievements & Badges'),
                    const SizedBox(height: 12),
                    _buildBadgesGrid(),
                    const SizedBox(height: 12),

                    _buildHeadingSection('Configure Daily Targets'),
                    const SizedBox(height: 12),
                    _buildGoalInputsCard(),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveGoals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Target Modifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingSection(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: titleColor,
      ),
    );
  }

  Widget _buildStreakHeaderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.tempAmber.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.tempAmber,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5-Day Active Streak!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You are ranking in the top 10% of health enthusiasts this week.',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final badges = [
      const BadgeItem(
        title: 'First Sync',
        desc: 'Paired wearable band.',
        icon: Icons.sync_lock_rounded,
        color: AppTheme.steps,
        unlocked: true,
      ),
      const BadgeItem(
        title: '10k Club',
        desc: '10,000 steps in one day.',
        icon: Icons.directions_run_rounded,
        color: AppTheme.heartRate,
        unlocked: true,
      ),
      const BadgeItem(
        title: 'Hydro Hero',
        desc: 'Met water goals for 3 days.',
        icon: Icons.water_drop_rounded,
        color: AppTheme.lightAccent,
        unlocked: true,
      ),
      const BadgeItem(
        title: 'Sleep Guru',
        desc: '8 hours of restful sleep.',
        icon: Icons.nights_stay_rounded,
        color: AppTheme.spo2Mint,
        unlocked: false,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final b = badges[index];
        final cardTextColor = b.unlocked
            ? titleColor
            : titleColor.withOpacity(0.3);

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    b.icon,
                    color: b.unlocked
                        ? b.color
                        : subtitleColor.withOpacity(0.25),
                    size: 24,
                  ),
                  if (b.unlocked)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.success,
                      size: 16,
                    )
                  else
                    Icon(
                      Icons.lock_rounded,
                      color: subtitleColor.withOpacity(0.25),
                      size: 14,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cardTextColor,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    b.desc,
                    style: TextStyle(fontSize: 10, color: subtitleColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalInputsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        children: [
          _buildGoalField(
            controller: _stepsController,
            label: 'Daily Step Goal',
            unit: 'steps',
            icon: Icons.directions_walk_rounded,
            color: AppTheme.steps,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildGoalField(
            controller: _waterController,
            label: 'Daily Water Intake Goal',
            unit: 'ml',
            icon: Icons.water_drop_rounded,
            color: AppTheme.lightAccent,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildGoalField(
            controller: _caloriesController,
            label: 'Daily Calories Burn Goal',
            unit: 'kcal',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.calories,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildGoalField(
            controller: _sleepController,
            label: 'Sleep Duration Target',
            unit: 'hours',
            icon: Icons.nights_stay_rounded,
            color: AppTheme.spo2Mint,
            isDouble: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required Color color,
    bool isDouble = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: titleColor,
                ),
              ),
              Text(
                'Unit: $unit',
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 90,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: subtitleColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (isDouble) {
                if (double.tryParse(val) == null) return 'Invalid';
              } else {
                if (int.tryParse(val) == null) return 'Invalid';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class BadgeItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const BadgeItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}
