import 'dart:async';

enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting
}

class BleDevice {
  final String id;
  final String name;
  final int rssi;

  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class BleVitalsData {
  final int heartRate;
  final int steps;
  final int spo2;
  final double temperature;
  final int batteryLevel;
  final double caloriesBurned;
  final DateTime timestamp;

  const BleVitalsData({
    required this.heartRate,
    required this.steps,
    required this.spo2,
    required this.temperature,
    required this.batteryLevel,
    required this.caloriesBurned,
    required this.timestamp,
  });

  factory BleVitalsData.empty() {
    return BleVitalsData(
      heartRate: 0,
      steps: 0,
      spo2: 0,
      temperature: 0.0,
      batteryLevel: 0,
      caloriesBurned: 0.0,
      timestamp: DateTime.now(),
    );
  }

  BleVitalsData copyWith({
    int? heartRate,
    int? steps,
    int? spo2,
    double? temperature,
    int? batteryLevel,
    double? caloriesBurned,
    DateTime? timestamp,
  }) {
    return BleVitalsData(
      heartRate: heartRate ?? this.heartRate,
      steps: steps ?? this.steps,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

abstract class BleService {
  // Streams
  Stream<BleConnectionState> get connectionStateStream;
  Stream<List<BleDevice>> get scanResultsStream;
  Stream<BleVitalsData> get vitalsStream;
  Stream<int> get rssiStream;

  // Current values
  BleConnectionState get currentConnectionState;
  BleVitalsData get currentVitals;
  String? get connectedDeviceId;
  String? get connectedDeviceName;

  // Methods
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> readRssi();
  Future<void> writeCommand(String command);
  
  // Device Info metadata
  Future<Map<String, String>> fetchDeviceInfo();
}
