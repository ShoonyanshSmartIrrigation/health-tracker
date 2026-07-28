import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../utils/ble_packet_parser.dart';
import '../../utils/calorie_calculator.dart';
import 'ble_service.dart';

class RealBleService implements BleService {
  static final RealBleService _instance = RealBleService._internal();
  factory RealBleService() => _instance;
  RealBleService._internal() {
    _initBluetoothStateListener();
  }

  // UUID Configuration
  static const String serviceUuid = '0000A000-0000-1000-8000-00805F9B34FB';
  static const String hrCharUuid = '0000A001-0000-1000-8000-00805F9B34FB';
  static const String stepsCharUuid = '0000A002-0000-1000-8000-00805F9B34FB';
  static const String spo2CharUuid = '0000A003-0000-1000-8000-00805F9B34FB';
  static const String tempCharUuid = '0000A004-0000-1000-8000-00805F9B34FB';
  static const String battCharUuid = '0000A005-0000-1000-8000-00805F9B34FB';
  static const String devCharUuid = '0000A006-0000-1000-8000-00805F9B34FB';

  // Stream Controllers
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _vitalsController = StreamController<BleVitalsData>.broadcast();
  final _rssiController = StreamController<int>.broadcast();

  // Internal state
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleVitalsData _vitals = BleVitalsData.empty();
  BluetoothDevice? _activeDevice;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  int _rssi = -100;
  bool _shouldAutoReconnect = true;

  // Timers and Subscriptions
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionStateSub;
  Timer? _rssiTimer;
  final List<StreamSubscription> _charNotificationSubscriptions = [];

  // Profile data for calorie calculation (defaults)
  double weightKg = 62.0;
  double heightCm = 168.0;
  String gender = 'Female';

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

  void updateProfileData({required double weight, required double height, required String sex}) {
    weightKg = weight;
    heightCm = height;
    gender = sex;
  }

  void _initBluetoothStateListener() {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off) {
        _handleDisconnect();
      }
    });
  }

  @override
  Future<void> startScan() async {
    // Make sure we stop any active scans
    await stopScan();

    final List<BleDevice> discoveredDevices = [];
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Filter for devices advertising our custom service or starting with name HS
        final name = r.device.platformName;
        final hasService = r.advertisementData.serviceUuids.any(
          (uuid) => uuid.toString().toUpperCase() == serviceUuid.toUpperCase(),
        );
        final matchesPrefix = name.startsWith('HS-') || name.startsWith('HealthSync');

        if (hasService || matchesPrefix) {
          final device = BleDevice(
            id: r.device.remoteId.toString(),
            name: name.isNotEmpty ? name : 'HealthSync Device',
            rssi: r.rssi,
          );
          if (!discoveredDevices.contains(device)) {
            discoveredDevices.add(device);
            _scanResultsController.add(List.from(discoveredDevices));
          }
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Failed to start scan: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSub?.cancel();
    _scanSub = null;
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();

    if (_activeDevice != null && _activeDevice!.remoteId.toString() == deviceId) {
      if (_connectionState == BleConnectionState.connected) return;
    }

    _connectionState = BleConnectionState.connecting;
    _connectionStateController.add(_connectionState);

    _activeDevice = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    _shouldAutoReconnect = true;

    // Listen to connection state updates
    _connectionStateSub?.cancel();
    _connectionStateSub = _activeDevice!.connectionState.listen((BluetoothConnectionState state) {
      switch (state) {
        case BluetoothConnectionState.connected:
          _handleConnected();
          break;
        case BluetoothConnectionState.disconnected:
          _handleDisconnect();
          break;
        case BluetoothConnectionState.connecting:
          _connectionState = BleConnectionState.connecting;
          _connectionStateController.add(_connectionState);
          break;
        case BluetoothConnectionState.disconnecting:
          _connectionState = BleConnectionState.disconnecting;
          _connectionStateController.add(_connectionState);
          break;
      }
    });

    try {
      await _activeDevice!.connect(autoConnect: false, timeout: const Duration(seconds: 10));
    } catch (e) {
      print('Connection failed: $e');
      _handleDisconnect();
    }
  }

  Future<void> _handleConnected() async {
    if (_activeDevice == null) return;
    
    _connectionState = BleConnectionState.connected;
    _connectedDeviceId = _activeDevice!.remoteId.toString();
    _connectedDeviceName = _activeDevice!.platformName.isNotEmpty 
        ? _activeDevice!.platformName 
        : 'HealthSync Band';
    
    _connectionStateController.add(_connectionState);

    try {
      // MTU Negotiation
      await _activeDevice!.requestMtu(512);
    } catch (e) {
      print('MTU negotiation failed: $e');
    }

    try {
      // Services Discovery
      List<BluetoothService> services = await _activeDevice!.discoverServices();
      BluetoothService? customService;

      for (var s in services) {
        if (s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          customService = s;
          break;
        }
      }

      if (customService != null) {
        await _subscribeToCharacteristics(customService);
      } else {
        print('Custom service not found on device.');
      }
    } catch (e) {
      print('Error during service discovery: $e');
    }

    // Start RSSI periodic read
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 5), (_) => readRssi());
  }

  Future<void> _subscribeToCharacteristics(BluetoothService service) async {
    // Clear old subscriptions
    for (var sub in _charNotificationSubscriptions) {
      sub.cancel();
    }
    _charNotificationSubscriptions.clear();

    for (BluetoothCharacteristic c in service.characteristics) {
      final uuidStr = c.uuid.toString().toUpperCase();

      if (uuidStr == hrCharUuid.toUpperCase()) {
        await c.setNotifyValue(true);
        final sub = c.onValueReceived.listen((bytes) {
          final hr = BlePacketParser.parseHeartRate(bytes);
          _vitals = _vitals.copyWith(
            heartRate: hr,
            timestamp: DateTime.now(),
          );
          _vitalsController.add(_vitals);
        });
        _charNotificationSubscriptions.add(sub);
      } else if (uuidStr == stepsCharUuid.toUpperCase()) {
        await c.setNotifyValue(true);
        final sub = c.onValueReceived.listen((bytes) {
          final steps = BlePacketParser.parseSteps(bytes);
          final calories = CalorieCalculator.calculateCaloriesBurned(
            steps: steps,
            weightKg: weightKg,
            heightCm: heightCm,
            gender: gender,
          );
          _vitals = _vitals.copyWith(
            steps: steps,
            caloriesBurned: double.parse(calories.toStringAsFixed(1)),
            timestamp: DateTime.now(),
          );
          _vitalsController.add(_vitals);
        });
        _charNotificationSubscriptions.add(sub);
      } else if (uuidStr == spo2CharUuid.toUpperCase()) {
        await c.setNotifyValue(true);
        final sub = c.onValueReceived.listen((bytes) {
          final spo2 = BlePacketParser.parseSpO2(bytes);
          _vitals = _vitals.copyWith(
            spo2: spo2,
            timestamp: DateTime.now(),
          );
          _vitalsController.add(_vitals);
        });
        _charNotificationSubscriptions.add(sub);
      } else if (uuidStr == tempCharUuid.toUpperCase()) {
        await c.setNotifyValue(true);
        final sub = c.onValueReceived.listen((bytes) {
          final temp = BlePacketParser.parseTemperature(bytes);
          _vitals = _vitals.copyWith(
            temperature: temp,
            timestamp: DateTime.now(),
          );
          _vitalsController.add(_vitals);
        });
        _charNotificationSubscriptions.add(sub);
      } else if (uuidStr == battCharUuid.toUpperCase()) {
        await c.setNotifyValue(true);
        final sub = c.onValueReceived.listen((bytes) {
          final batt = BlePacketParser.parseBattery(bytes);
          _vitals = _vitals.copyWith(
            batteryLevel: batt,
            timestamp: DateTime.now(),
          );
          _vitalsController.add(_vitals);
        });
        _charNotificationSubscriptions.add(sub);
      }
    }
  }

  void _handleDisconnect() {
    _rssiTimer?.cancel();
    _rssiTimer = null;

    for (var sub in _charNotificationSubscriptions) {
      sub.cancel();
    }
    _charNotificationSubscriptions.clear();

    _connectionStateSub?.cancel();
    _connectionStateSub = null;

    _connectionState = BleConnectionState.disconnected;
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _activeDevice = null;
    _connectionStateController.add(_connectionState);

    // Auto reconnect loop logic can trigger here if enabled
    if (_shouldAutoReconnect) {
      // Reconnect logic can be triggered by higher-level providers or locally.
    }
  }

  @override
  Future<void> disconnect() async {
    _shouldAutoReconnect = false;
    if (_activeDevice != null) {
      try {
        await _activeDevice!.disconnect();
      } catch (_) {}
    }
    _handleDisconnect();
  }

  @override
  Future<void> readRssi() async {
    if (_activeDevice == null || _connectionState != BleConnectionState.connected) return;
    try {
      _rssi = await _activeDevice!.readRssi();
      _rssiController.add(_rssi);
    } catch (_) {}
  }

  @override
  Future<void> writeCommand(String command) async {
    if (_activeDevice == null || _connectionState != BleConnectionState.connected) return;

    try {
      // Find the device info or custom write characteristic and send
      List<BluetoothService> services = await _activeDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          for (var c in s.characteristics) {
            // Write commands to device info char or custom command char
            if (c.uuid.toString().toUpperCase() == devCharUuid.toUpperCase() && c.properties.write) {
              await c.write(command.codeUnits);
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Write command failed: $e');
    }
  }

  @override
  Future<Map<String, String>> fetchDeviceInfo() async {
    if (_activeDevice == null || _connectionState != BleConnectionState.connected) {
      return {'firmware': 'Unknown', 'serialNumber': 'Unknown', 'hardwareVersion': 'Unknown'};
    }

    try {
      List<BluetoothService> services = await _activeDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toUpperCase() == devCharUuid.toUpperCase()) {
              final bytes = await c.read();
              return BlePacketParser.parseDeviceInfo(bytes);
            }
          }
        }
      }
    } catch (e) {
      print('Fetch device info failed: $e');
    }

    return {'firmware': 'v1.0.0', 'serialNumber': 'HS-ESP32-DEV', 'hardwareVersion': 'v1.0'};
  }
}
