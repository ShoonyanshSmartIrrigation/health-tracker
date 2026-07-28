import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/database/isar_models.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _selectedGender = 'Female';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    final authState = ref.read(authStateProvider);
    final firebaseUser = authState.value;

    String initialName = '';
    if (profile.name != null && profile.name != 'Jane Doe' && profile.name != 'User') {
      initialName = profile.name!;
    } else if (firebaseUser != null && firebaseUser.displayName.isNotEmpty && firebaseUser.displayName != 'User') {
      initialName = firebaseUser.displayName;
    } else {
      initialName = profile.name ?? '';
    }

    _nameController = TextEditingController(text: initialName);
    _ageController = TextEditingController(text: '${profile.age ?? 28}');
    _heightController = TextEditingController(text: '${profile.heightCm ?? 168.0}');
    _weightController = TextEditingController(text: '${profile.weightKg ?? 62.0}');
    _selectedGender = profile.gender ?? 'Female';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profileNotifier = ref.read(profileProvider.notifier);
      final profile = ref.read(profileProvider);

      final updatedProfile = UserProfileModel()
        ..id = profile.id
        ..name = _nameController.text.trim()
        ..age = int.tryParse(_ageController.text) ?? 28
        ..heightCm = double.tryParse(_heightController.text) ?? 168.0
        ..weightKg = double.tryParse(_weightController.text) ?? 62.0
        ..gender = _selectedGender
        ..dailyStepGoal = profile.dailyStepGoal
        ..dailyWaterGoal = profile.dailyWaterGoal
        ..dailyCaloriesGoal = profile.dailyCaloriesGoal
        ..targetSleepHours = profile.targetSleepHours;

      await profileNotifier.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile successfully updated!'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final auth = ref.read(authServiceProvider);
    await auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final dialogText = isDark ? AppTheme.darkText : AppTheme.lightText;
    final dialogTextSec = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: TextStyle(color: dialogText, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: dialogTextSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: dialogTextSec)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = ref.read(authServiceProvider);
      await auth.deleteAccount();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;

    String displayName = 'User';
    if (profile.name != null && profile.name != 'Jane Doe' && profile.name != 'User') {
      displayName = profile.name!;
    } else if (firebaseUser != null && firebaseUser.displayName.isNotEmpty && firebaseUser.displayName != 'User') {
      displayName = firebaseUser.displayName;
    } else {
      displayName = profile.name ?? 'Jane Doe';
    }

    final email = profile.email ?? firebaseUser?.email ?? 'jane.doe@healthsync.com';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final double weight = double.tryParse(_weightController.text) ?? (profile.weightKg ?? 0.0);
    final double height = double.tryParse(_heightController.text) ?? (profile.heightCm ?? 0.0);
    final double bmi = BmiCalculator.calculateBMI(weightKg: weight, heightCm: height);
    final bmiCategory = BmiCalculator.getCategory(bmi);
    final bmiColor = BmiCalculator.getCategoryColor(bmi);
    final bmiAdvice = BmiCalculator.getInterpretation(bmi);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(currentIndex: 4),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text('Personal Profile', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: titleColor),
            onPressed: () => context.push('/settings'),
          ),
        ],
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
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [AppTheme.darkPrimary, AppTheme.darkAccent]
                                    : [AppTheme.lightPrimary, AppTheme.lightAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: primaryBtnColor, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(fontSize: 13, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildHeadingSection('Body Mass Index (BMI)'),
                    const SizedBox(height: 12),
                    _buildBmiDisplayCard(bmi, bmiCategory, bmiColor, bmiAdvice),
                    const SizedBox(height: 24),

                    _buildHeadingSection('Edit Vitals Specifications'),
                    const SizedBox(height: 12),
                    _buildMetricsFormCard(),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Profile Updates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: Icon(Icons.logout_rounded, color: subtitleColor),
                      label: Text('Sign Out', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: subtitleColor.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: _handleDeleteAccount,
                      child: const Text('Permanently Delete My Account', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500)),
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
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
    );
  }

  Widget _buildBmiDisplayCard(double bmi, String category, Color color, String advice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calculated BMI', style: TextStyle(fontSize: 12, color: subtitleColor)),
                  const SizedBox(height: 4),
                  Text(
                    bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  category,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: subtitleColor.withOpacity(0.15)),
          const SizedBox(height: 8),
          Text(
            advice,
            style: TextStyle(color: subtitleColor, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsFormCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return GlassCard(
      child: Column(
        children: [
          _buildTextFieldRow(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            color: primaryBtnColor,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildTextFieldRow(
            controller: _ageController,
            label: 'Age',
            icon: Icons.cake_rounded,
            color: AppTheme.tempAmber,
            isNumber: true,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildTextFieldRow(
            controller: _heightController,
            label: 'Height (cm)',
            icon: Icons.straighten_rounded,
            color: AppTheme.steps,
            isNumber: true,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          _buildTextFieldRow(
            controller: _weightController,
            label: 'Weight (kg)',
            icon: Icons.monitor_weight_rounded,
            color: AppTheme.spo2Mint,
            isNumber: true,
          ),
          Divider(color: subtitleColor.withOpacity(0.15), height: 24),
          Row(
            children: [
              const Icon(Icons.wc_rounded, color: AppTheme.lightAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gender Identity', style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
              ),
              DropdownButton<String>(
                value: _selectedGender,
                dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedGender = val;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool isNumber = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: subtitleColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Required';
              return null;
            },
          ),
        ),
      ],
    );
  }
}
