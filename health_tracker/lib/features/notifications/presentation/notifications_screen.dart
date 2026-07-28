import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database/isar_models.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationLogModel> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationLogs();
  }

  Future<void> _loadNotificationLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      final logs = await db.getNotifications();
      setState(() {
        _logs = logs;
      });
    } catch (_) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllLogs() async {
    final db = ref.read(databaseServiceProvider);
    await db.clearNotifications();
    await _loadNotificationLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications log cleared.'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications Panel', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_logs.isNotEmpty)
            TextButton(
              onPressed: _clearAllLogs,
              child: const Text('Clear All', style: TextStyle(color: AppTheme.heartRate, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alert Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
                        const SizedBox(height: 12),
                        _buildSwitchRow(
                          context: context,
                          label: 'Enable Alert Notifications',
                          value: settings.enableNotifications ?? true,
                          onChanged: (val) {
                            final updated = SettingsModel()
                              ..id = settings.id
                              ..isDarkMode = settings.isDarkMode
                              ..themeMode = settings.themeMode
                              ..languageCode = settings.languageCode
                              ..unitSystem = settings.unitSystem
                              ..autoReconnect = settings.autoReconnect
                              ..isDeveloperMode = settings.isDeveloperMode
                              ..enableNotifications = val;
                            settingsNotifier.updateSettings(updated);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'System Alert Log',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonList()
                      : _logs.isEmpty
                          ? Center(child: Text('No system alerts recorded.', style: TextStyle(color: subtitleColor.withOpacity(0.5))))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                final formattedTime = DateFormat('MMM d, h:mm a').format(log.timestamp ?? DateTime.now());
                                
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
                                            color: _getAlertColor(log.type ?? '').withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_getAlertIcon(log.type ?? ''), color: _getAlertColor(log.type ?? '')),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(log.title ?? 'Alert Triggered', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
                                              const SizedBox(height: 2),
                                              Text(log.message ?? '', style: TextStyle(fontSize: 12, color: subtitleColor)),
                                            ],
                                          ),
                                        ),
                                        Text(formattedTime, style: TextStyle(fontSize: 10, color: subtitleColor.withOpacity(0.6))),
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

  Widget _buildSwitchRow({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final activeSwitchColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: titleColor, fontWeight: FontWeight.bold)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeSwitchColor,
        ),
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

  Color _getAlertColor(String type) {
    switch (type) {
      case 'high_heart_rate':
      case 'low_spo2':
      case 'low_battery':
      case 'device_disconnected':
        return AppTheme.heartRate;
      case 'device_connected':
      case 'goal_achieved':
        return AppTheme.success;
      default:
        return AppTheme.steps;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'high_heart_rate':
        return Icons.favorite_rounded;
      case 'low_spo2':
        return Icons.opacity_rounded;
      case 'low_battery':
        return Icons.battery_alert_rounded;
      case 'device_disconnected':
        return Icons.bluetooth_disabled_rounded;
      case 'device_connected':
        return Icons.bluetooth_connected_rounded;
      case 'goal_achieved':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
