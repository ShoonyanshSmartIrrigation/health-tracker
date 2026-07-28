import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/database_service.dart';
import '../database/isar_models.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  late DatabaseService _db;
  bool _useFirebase = false;
  final _alertController = StreamController<NotificationLogModel>.broadcast();

  Stream<NotificationLogModel> get alertStream => _alertController.stream;

  // Track threshold triggers to avoid spamming alerts
  bool _isLowBatteryAlerted = false;
  bool _isDisconnectedAlerted = false;
  bool _isHighHrAlerted = false;
  bool _isLowSpo2Alerted = false;
  bool _isStepGoalAlerted = false;

  Future<void> init(DatabaseService db) async {
    _db = db;
    
    try {
      final fcm = FirebaseMessaging.instance;
      _useFirebase = true;
      
      // Request permissions (FCM)
      await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Listen for foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          triggerLocalAlert(
            title: message.notification!.title ?? 'Notification',
            message: message.notification!.body ?? '',
            type: 'push_notification',
          );
        }
      });
    } catch (_) {
      _useFirebase = false;
      print('Firebase Messaging is not configured. Falling back to local alerts.');
    }
  }

  /// Evaluates current vitals and triggers warnings if thresholds are breached
  Future<void> evaluateVitalsAlerts(int hr, int spo2, int battery, int steps, int stepGoal) async {
    // 1. High Heart Rate Alert (> 130 or < 40)
    if (hr > 130) {
      if (!_isHighHrAlerted) {
        await triggerLocalAlert(
          title: 'High Heart Rate Warning',
          message: 'Your heart rate is $hr BPM. Please rest and take a break.',
          type: 'high_heart_rate',
        );
        _isHighHrAlerted = true;
      }
    } else {
      _isHighHrAlerted = false;
    }

    // 2. Low SpO2 Alert (< 92%)
    if (spo2 > 0 && spo2 < 93) {
      if (!_isLowSpo2Alerted) {
        await triggerLocalAlert(
          title: 'Low Oxygen Saturation',
          message: 'Your SpO₂ level has dropped to $spo2%. Take slow deep breaths.',
          type: 'low_spo2',
        );
        _isLowSpo2Alerted = true;
      }
    } else {
      _isLowSpo2Alerted = false;
    }

    // 3. Low Battery Alert (< 15%)
    if (battery > 0 && battery < 15) {
      if (!_isLowBatteryAlerted) {
        await triggerLocalAlert(
          title: 'Low Wearable Battery',
          message: 'Your health band battery is at $battery%. Please charge it soon.',
          type: 'low_battery',
        );
        _isLowBatteryAlerted = true;
      }
    } else {
      _isLowBatteryAlerted = false;
    }

    // 4. Goal Accomplished Alert
    if (steps >= stepGoal && stepGoal > 0) {
      if (!_isStepGoalAlerted) {
        await triggerLocalAlert(
          title: 'Step Goal Achieved! 🏆',
          message: 'Congratulations! You reached your daily goal of $stepGoal steps.',
          type: 'goal_achieved',
        );
        _isStepGoalAlerted = true;
      }
    } else {
      // Reset if steps drop (e.g. new day, although usually handled by calendar roll over)
      if (steps < stepGoal) {
        _isStepGoalAlerted = false;
      }
    }
  }

  Future<void> triggerConnectionAlert(bool isConnected, String deviceName) async {
    if (isConnected) {
      _isDisconnectedAlerted = false;
      await triggerLocalAlert(
        title: 'Device Connected',
        message: 'HealthSync is now active and monitoring $deviceName.',
        type: 'device_connected',
      );
    } else {
      if (!_isDisconnectedAlerted) {
        await triggerLocalAlert(
          title: 'Device Disconnected',
          message: 'Connection to $deviceName was lost. Attempting to reconnect...',
          type: 'device_disconnected',
        );
        _isDisconnectedAlerted = true;
      }
    }
  }

  Future<void> triggerLocalAlert({
    required String title,
    required String message,
    required String type,
  }) async {
    final log = NotificationLogModel()
      ..title = title
      ..message = message
      ..type = type
      ..timestamp = DateTime.now()
      ..isRead = false;

    // Save to local database
    if (_db.isInitialized) {
      await _db.addNotification(log);
    }

    // Emit to listeners
    _alertController.add(log);
  }
}
