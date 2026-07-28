import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/ble/mock_ble_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class DevSimulatorScreen extends ConsumerStatefulWidget {
  const DevSimulatorScreen({super.key});

  @override
  ConsumerState<DevSimulatorScreen> createState() => _DevSimulatorScreenState();
}

class _DevSimulatorScreenState extends ConsumerState<DevSimulatorScreen> {
  final MockBleService _mockBle = MockBleService();

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(bleConnectionStateProvider).value ?? BleConnectionState.disconnected;
    final isConnected = connectionState == BleConnectionState.connected;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('BLE GATT Simulator'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F1026), const Color(0xFF070814)]
                    : [const Color(0xFFE8ECEF), const Color(0xFFF6F8FB)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner explaining the panel
                  _buildIntroCard(),
                  const SizedBox(height: 24),

                  // Connection Simulation Card
                  const Text('Device State Control', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 12),
                  _buildConnectionControlCard(isConnected),
                  const SizedBox(height: 24),

                  // Sensor Readings Sliders
                  const Text('Physiological Signal Override', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 12),
                  _buildVitalsControlCard(isConnected),
                  const SizedBox(height: 24),

                  // Device Actions
                  const Text('Device Simulation Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 12),
                  _buildDeviceActionsCard(isConnected),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This panel overrides the Bluetooth Low Energy stack with simulated feeds. Move sliders to verify live visual changes in graphs and alerts.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionControlCard(bool isConnected) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bluetooth Connectivity Status', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'CONNECTED' : 'DISCONNECTED',
                    style: TextStyle(
                      color: isConnected ? AppTheme.spo2Mint : AppTheme.secondaryCoral,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isConnected) {
                    await _mockBle.disconnect();
                  } else {
                    await _mockBle.connect('HS-MOCK-TEST');
                  }
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? AppTheme.secondaryCoral : const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isConnected ? 'Force Disconnect' : 'Force Connect', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsControlCard(bool isConnected) {
    return GlassCard(
      child: Column(
        children: [
          // Auto fluctuate toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enable Natural Fluctuation (Sine-wave)', style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(
                value: _mockBle.isAutoUpdating,
                onChanged: !isConnected ? null : (val) {
                  setState(() {
                    _mockBle.updateSimulationControls(autoUpdate: val);
                  });
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // Heart Rate Slider
          _buildSliderRow(
            label: 'Heart Rate',
            value: _mockBle.targetHeartRate.toDouble(),
            min: 40,
            max: 180,
            unit: 'BPM',
            color: AppTheme.secondaryCoral,
            enabled: isConnected && !_mockBle.isAutoUpdating,
            onChanged: (val) {
              setState(() {
                _mockBle.updateSimulationControls(hr: val.round());
              });
            },
          ),
          const Divider(color: Colors.white10, height: 24),

          // SpO2 Slider
          _buildSliderRow(
            label: 'Oxygen Saturation',
            value: _mockBle.targetSpO2.toDouble(),
            min: 80,
            max: 100,
            unit: '%',
            color: AppTheme.spo2Mint,
            enabled: isConnected && !_mockBle.isAutoUpdating,
            onChanged: (val) {
              setState(() {
                _mockBle.updateSimulationControls(spo2: val.round());
              });
            },
          ),
          const Divider(color: Colors.white10, height: 24),

          // Temperature Slider
          _buildSliderRow(
            label: 'Skin Temperature',
            value: _mockBle.targetTemperature,
            min: 35.0,
            max: 41.0,
            unit: '°C',
            color: AppTheme.tempAmber,
            enabled: isConnected && !_mockBle.isAutoUpdating,
            onChanged: (val) {
              setState(() {
                _mockBle.updateSimulationControls(temp: double.parse(val.toStringAsFixed(1)));
              });
            },
          ),
          const Divider(color: Colors.white10, height: 24),

          // Battery Slider
          _buildSliderRow(
            label: 'Band Battery level',
            value: _mockBle.targetBattery.toDouble(),
            min: 0,
            max: 100,
            unit: '%',
            color: AppTheme.batteryGreen,
            enabled: isConnected,
            onChanged: (val) {
              setState(() {
                _mockBle.updateSimulationControls(battery: val.round());
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.white24, fontSize: 13)),
            Text('${value.toStringAsFixed(label == 'Skin Temperature' ? 1 : 0)} $unit',
                style: TextStyle(color: enabled ? color : Colors.white24, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: color,
          inactiveColor: Colors.white10,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildDeviceActionsCard(bool isConnected) {
    return GlassCard(
      child: Column(
        children: [
          // Simulate Sensor Failure (BPM/SpO2 drop to zero)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simulate Sensor Failure', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Text(
                    'Simulates MAX30102 hardware disconnect.',
                    style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 10),
                  ),
                ],
              ),
              Switch(
                value: _mockBle.isSensorFailureSimulated,
                onChanged: !isConnected ? null : (val) {
                  setState(() {
                    _mockBle.updateSimulationControls(sensorFailure: val);
                  });
                },
                activeColor: AppTheme.secondaryCoral,
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // Increment Steps Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mock Active Exercise', style: TextStyle(color: Colors.white, fontSize: 13)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: !isConnected ? null : () {
                      setState(() {
                        _mockBle.updateSimulationControls(steps: _mockBle.mockStepCount + 500);
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('+500 Steps', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: !isConnected ? null : () {
                      setState(() {
                        _mockBle.updateSimulationControls(steps: _mockBle.mockStepCount + 2000);
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('+2k Steps', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
