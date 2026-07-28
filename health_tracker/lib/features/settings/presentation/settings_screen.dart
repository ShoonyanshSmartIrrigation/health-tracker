import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/database/isar_models.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportHealthData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseServiceProvider);
      final profile = ref.read(profileProvider);
      
      final now = DateTime.now();
      final history = await db.getHealthDataPoints(now.subtract(const Duration(days: 7)), now);
      
      if (history.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No historical logs found to export.'), backgroundColor: AppTheme.error),
          );
        }
        return;
      }

      final StringBuffer csv = StringBuffer();
      csv.writeln('Timestamp,HeartRate(BPM),Steps,SpO2(%),Temp(C),Calories(kcal)');
      for (var point in history) {
        csv.writeln('${point.timestamp},${point.heartRate},${point.steps},${point.spo2},${point.temperature},${point.caloriesBurned}');
      }

      await Share.share(
        csv.toString(),
        subject: 'HealthSync Export: ${profile.name ?? "User"}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final themeModeStr = settings.themeMode ?? 'system';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text('App Settings', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- APPEARANCE ---
                  Text('Appearance settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtitleColor)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, color: primaryBtnColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Theme Mode', style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: SegmentedButton<String>(
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: primaryBtnColor.withOpacity(0.15),
                              selectedForegroundColor: primaryBtnColor,
                            ),
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'light',
                                label: Text('Light', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.light_mode_outlined, size: 16),
                              ),
                              ButtonSegment<String>(
                                value: 'dark',
                                label: Text('Dark', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.dark_mode_outlined, size: 16),
                              ),
                              ButtonSegment<String>(
                                value: 'system',
                                label: Text('System', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.settings_suggest_outlined, size: 16),
                              ),
                            ],
                            selected: <String>{themeModeStr},
                            onSelectionChanged: (Set<String> newSelection) {
                              settingsNotifier.updateThemeMode(newSelection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- GENERAL PREFERENCES ---
                  Text('General Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtitleColor)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildDropdownRow(
                          context: context,
                          label: 'Measurement Units',
                          icon: Icons.straighten_rounded,
                          value: settings.unitSystem ?? 'metric',
                          items: const {
                            'metric': 'Metric (kg, cm)',
                            'imperial': 'Imperial (lbs, inches)',
                          },
                          onChanged: (val) {
                            if (val != null) settingsNotifier.updateUnits(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CONNECTIVITY ---
                  Text('Connectivity Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtitleColor)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          context: context,
                          label: 'Automatic BLE Reconnection',
                          icon: Icons.bluetooth_audio_rounded,
                          value: settings.autoReconnect ?? true,
                          onChanged: (val) {
                            final updated = SettingsModel()
                              ..id = settings.id
                              ..isDarkMode = settings.isDarkMode
                              ..themeMode = settings.themeMode
                              ..languageCode = settings.languageCode
                              ..unitSystem = settings.unitSystem
                              ..enableNotifications = settings.enableNotifications
                              ..isDeveloperMode = settings.isDeveloperMode
                              ..autoReconnect = val;
                            settingsNotifier.updateSettings(updated);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- DEVELOPER OPTIONS ---
                  Text('Developer Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtitleColor)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSwitchRow(
                          context: context,
                          label: 'BLE Interactive Simulator Mode',
                          icon: Icons.terminal_rounded,
                          value: settings.isDeveloperMode ?? true,
                          onChanged: (val) {
                            settingsNotifier.toggleDeveloperMode(val);
                          },
                        ),
                        if (settings.isDeveloperMode == true) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/simulator'),
                            icon: const Icon(Icons.settings_input_component_rounded, color: Colors.white),
                            label: const Text('Open Simulator Control Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBtnColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- DATA SECURITY ---
                  Text('Account & Data Security', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtitleColor)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.download_rounded, color: AppTheme.spo2Mint),
                          title: Text('Export Vitals Log (CSV)', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text('Share or download a complete report of your health metrics.', style: TextStyle(color: subtitleColor, fontSize: 11)),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, color: subtitleColor.withOpacity(0.5), size: 16),
                          onTap: () => _exportHealthData(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final activeSwitchColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Row(
      children: [
        Icon(icon, color: subtitleColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeSwitchColor,
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Row(
      children: [
        Icon(icon, color: subtitleColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
          underline: const SizedBox(),
          items: items.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value, style: TextStyle(color: titleColor)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
