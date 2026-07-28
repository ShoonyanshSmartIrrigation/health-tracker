import 'dart:async';
import 'dart:math';
import '../../utils/calorie_calculator.dart';
import 'ble_service.dart';

class MockBleService implements BleService {
  // Singleton pattern for easy configuration
  static final MockBleService _instance = MockBleService._internal();
  factory MockBleService() => _instance;
  MockBleService._internal() {
    _startSimulationTimer();
  }

  // Stream Controllers
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _vitalsController = StreamController<BleVitalsData>.broadcast();
  final _rssiController = StreamController<int>.broadcast();

  // State Variables
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleVitalsData _vitals = BleVitalsData.empty();
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  int _rssi = -65;
  Timer? _vitalsTimer;
  int _tickCount = 0;

  // Simulator Controls (Configurable from Dev Settings Screen)
  double weightKg = 62.0;
  double heightCm = 168.0;
  String gender = 'Female';

  bool isAutoUpdating = true; // Auto fluctuate vitals
  int targetHeartRate = 72;
  int targetSpO2 = 98;
  double targetTemperature = 36.7;
  int targetBattery = 85;
  int mockStepCount = 4250;
  bool isSensorFailureSimulated = false;

  // Mock scan devices list
  final List<BleDevice> _mockDevices = const [
    BleDevice(id: 'HS-ESP32-94A2', name: 'HealthSync Band v2', rssi: -58),
    BleDevice(id: 'HS-ESP32-3482', name: 'HealthSync Band v1', rssi: -72),
    BleDevice(id: 'HS-MOCK-TEST', name: 'HealthSync Simulator', rssi: -40),
  ];

  @override
  Stream<BleConnectionState> get connectionStateStream => _connectionStateController.stream;
  @override
  Stream<List<BleDevice>> get scanResultsStream => _scanResultsController.stream;
  @override
  Stream<BleVitalsData> get vitalsStream => _vitalsController.stream;
  @override
  Stream<int> get rssiStream => _rssiController.stream;

  @override
  BleConnectionState get currentConnectionState => _connectionState;
  @override
  BleVitalsData get currentVitals => _vitals;
  @override
  String? get connectedDeviceId => _connectedDeviceId;
  @override
  String? get connectedDeviceName => _connectedDeviceName;

  void updateSimulationControls({
    int? hr,
    int? spo2,
    double? temp,
    int? battery,
    int? steps,
    bool? autoUpdate,
    bool? sensorFailure,
  }) {
    if (hr != null) targetHeartRate = hr;
    if (spo2 != null) targetSpO2 = spo2;
    if (temp != null) targetTemperature = temp;
    if (battery != null) targetBattery = battery;
    if (steps != null) mockStepCount = steps;
    if (autoUpdate != null) isAutoUpdating = autoUpdate;
    if (sensorFailure != null) isSensorFailureSimulated = sensorFailure;

    // Trigger immediate update if connected
    if (_connectionState == BleConnectionState.connected) {
      _emitCurrentVitals();
    }
  }

  void _startSimulationTimer() {
    _vitalsTimer?.cancel();
    _vitalsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionState != BleConnectionState.connected) return;

      _tickCount++;
      
      if (isAutoUpdating && !isSensorFailureSimulated) {
        // Fluctuate heart rate slightly using sine wave (simulating breathing rhythm)
        final hrFluctuation = (3 * sin(_tickCount * 0.1)).round();
        final currentHr = targetHeartRate + hrFluctuation;

        // Periodic SpO2 drops
        final spo2Fluctuation = _tickCount % 40 == 0 ? -1 : 0;
        final currentSpO2 = max(80, min(100, targetSpO2 + spo2Fluctuation));

        // Temperature variations
        final tempFluctuation = 0.05 * sin(_tickCount * 0.05);
        final currentTemp = targetTemperature + tempFluctuation;

        // Increment steps periodically (simulate walking)
        if (_tickCount % 3 == 0) {
          mockStepCount += Random().nextInt(3) + 1; // 1-3 steps
        }

        // Slowly drain battery (every 100 seconds)
        if (_tickCount % 100 == 0 && targetBattery > 0) {
          targetBattery--;
        }

        // Calculate dynamic active calories burned based on step count
        final double calories = CalorieCalculator.calculateCaloriesBurned(
          steps: mockStepCount,
          weightKg: weightKg,
          heightCm: heightCm,
          gender: gender,
        );

        _vitals = BleVitalsData(
          heartRate: currentHr,
          steps: mockStepCount,
          spo2: currentSpO2,
          temperature: double.parse(currentTemp.toStringAsFixed(2)),
          batteryLevel: targetBattery,
          caloriesBurned: double.parse(calories.toStringAsFixed(1)),
          timestamp: DateTime.now(),
        );
      } else if (isSensorFailureSimulated) {
        // Simulating sensor fail values (like zero readings)
        _vitals = BleVitalsData(
          heartRate: 0,
          steps: mockStepCount,
          spo2: 0,
          temperature: 0.0,
          batteryLevel: targetBattery,
          caloriesBurned: 0.0,
          timestamp: DateTime.now(),
        );
      } else {
        // Manual override static values
        final double calories = CalorieCalculator.calculateCaloriesBurned(
          steps: mockStepCount,
          weightKg: weightKg,
          heightCm: heightCm,
          gender: gender,
        );

        _vitals = BleVitalsData(
          heartRate: targetHeartRate,
          steps: mockStepCount,
          spo2: targetSpO2,
          temperature: targetTemperature,
          batteryLevel: targetBattery,
          caloriesBurned: double.parse(calories.toStringAsFixed(1)),
          timestamp: DateTime.now(),
        );
      }

      _emitCurrentVitals();

      // Fluctuate RSSI
      if (_tickCount % 5 == 0) {
        _rssi = -40 - Random().nextInt(30); // between -40 and -70 dBm
        _rssiController.add(_rssi);
      }
    });
  }

  void _emitCurrentVitals() {
    _vitalsController.add(_vitals);
  }

  @override
  Future<void> startScan() async {
    _connectionStateController.add(_connectionState);
    
    // Simulate scan duration and deliver results
    await Future.delayed(const Duration(milliseconds: 600));
    _scanResultsController.add(_mockDevices);
  }

  @override
  Future<void> stopScan() async {
    // Scan stopped
  }

  @override
  Future<void> connect(String deviceId) async {
    if (_connectionState == BleConnectionState.connected) return;

    _connectionState = BleConnectionState.connecting;
    _connectionStateController.add(_connectionState);

    // Find device
    final device = _mockDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => BleDevice(id: deviceId, name: 'HealthSync Band v2', rssi: -50),
    );

    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate connection delay

    _connectionState = BleConnectionState.connected;
    _connectedDeviceId = device.id;
    _connectedDeviceName = device.name;
    
    _connectionStateController.add(_connectionState);
    _rssiController.add(-45);

    // Emit initial vitals
    final double calories = CalorieCalculator.calculateCaloriesBurned(
      steps: mockStepCount,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
    );
    _vitals = BleVitalsData(
      heartRate: targetHeartRate,
      steps: mockStepCount,
      spo2: targetSpO2,
      temperature: targetTemperature,
      batteryLevel: targetBattery,
      caloriesBurned: calories,
      timestamp: DateTime.now(),
    );
    _emitCurrentVitals();
  }

  @override
  Future<void> disconnect() async {
    if (_connectionState == BleConnectionState.disconnected) return;

    _connectionState = BleConnectionState.disconnecting;
    _connectionStateController.add(_connectionState);

    await Future.delayed(const Duration(milliseconds: 500));

    _connectionState = BleConnectionState.disconnected;
    _connectedDeviceId = null;
    _connectedDeviceName = null;

    _connectionStateController.add(_connectionState);
  }

  @override
  Future<void> readRssi() async {
    _rssiController.add(_rssi);
  }

  @override
  Future<void> writeCommand(String command) async {
    // Write mock logs
    print('Mock BLE Command Written: $command');
  }

  @override
  Future<Map<String, String>> fetchDeviceInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'firmware': 'v2.1.0-beta',
      'serialNumber': 'HS-ESP32-94A2-9482',
      'hardwareVersion': 'v2.0-RevC',
    };
  }

  void forceDisconnect() {
    _connectionState = BleConnectionState.disconnected;
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _connectionStateController.add(_connectionState);
  }
}
