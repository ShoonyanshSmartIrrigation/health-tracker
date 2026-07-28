import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  bool _isScanning = false;
  Map<String, String>? _deviceInfo;
  bool _loadingDeviceInfo = false;
  String _customDeviceName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = ref.read(bleServiceProvider);
      if (ble.currentConnectionState == BleConnectionState.connected) {
        _fetchDeviceMetadata();
      }
    });
  }

  Future<void> _fetchDeviceMetadata() async {
    setState(() {
      _loadingDeviceInfo = true;
    });
    try {
      final ble = ref.read(bleServiceProvider);
      final info = await ble.fetchDeviceInfo();
      setState(() {
        _deviceInfo = info;
      });
    } catch (_) {
    } finally {
      setState(() {
        _loadingDeviceInfo = false;
      });
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });
    final ble = ref.read(bleServiceProvider);
    await ble.startScan();
    
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _stopScan() async {
    setState(() {
      _isScanning = false;
    });
    final ble = ref.read(bleServiceProvider);
    await ble.stopScan();
  }

  Future<void> _showRenameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final dialogText = isDark ? AppTheme.darkText : AppTheme.lightText;
    final dialogTextSec = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final dialogPrimary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Device', style: TextStyle(color: dialogText, fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: dialogText),
            decoration: InputDecoration(
              labelText: 'New Name',
              labelStyle: TextStyle(color: dialogTextSec),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dialogTextSec.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dialogPrimary),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: dialogTextSec)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _customDeviceName = controller.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleService = ref.watch(bleServiceProvider);
    final connectionState = ref.watch(bleConnectionStateProvider).value ?? BleConnectionState.disconnected;
    final rssi = ref.watch(rssiStreamProvider).value ?? -70;
    final vitals = ref.watch(vitalsStreamProvider).value ?? BleVitalsData.empty();

    final isConnected = connectionState == BleConnectionState.connected;
    final isConnecting = connectionState == BleConnectionState.connecting;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    
    final deviceName = _customDeviceName.isNotEmpty 
        ? _customDeviceName 
        : (bleService.connectedDeviceName ?? 'HealthSync Wearable');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Device Settings', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isConnected) ...[
                    _buildConnectedCard(deviceName, rssi, vitals.batteryLevel),
                    const SizedBox(height: 24),
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 24),
                    _buildOtaUpdateCard(),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await bleService.disconnect();
                        setState(() {
                          _deviceInfo = null;
                        });
                      },
                      icon: const Icon(Icons.bluetooth_disabled_rounded, color: Colors.white),
                      label: const Text('Disconnect Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ] else ...[
                    _buildDisconnectedHeader(isConnecting),
                    const SizedBox(height: 24),
                    _buildScannedDevicesList(bleService, isConnecting),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard(String name, int rssi, int battery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final iconColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    Color batteryColor = AppTheme.batteryGreen;
    if (battery < 20) batteryColor = AppTheme.error;
    else if (battery < 50) batteryColor = AppTheme.warning;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.12),
                ),
                child: Icon(Icons.watch_rounded, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    const Text('Status: Connected', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: subtitleColor.withOpacity(0.7)),
                onPressed: () => _showRenameDialog(name),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: subtitleColor.withOpacity(0.15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.signal_cellular_alt_rounded, color: AppTheme.steps, size: 24),
                  const SizedBox(height: 6),
                  Text('$rssi dBm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
                  Text('Signal Strength', style: TextStyle(fontSize: 11, color: subtitleColor)),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.battery_charging_full_rounded, color: batteryColor, size: 24),
                  const SizedBox(height: 6),
                  Text('$battery%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
                  Text('Battery Level', style: TextStyle(fontSize: 11, color: subtitleColor)),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.sync_rounded, color: AppTheme.tempAmber, size: 24),
                  const SizedBox(height: 6),
                  Text('Just now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor)),
                  Text('Last Sync', style: TextStyle(fontSize: 11, color: subtitleColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    if (_loadingDeviceInfo) {
      return const GlassCard(
        child: Column(
          children: [
            SkeletonLoader(width: double.infinity, height: 16),
            SizedBox(height: 12),
            SkeletonLoader(width: double.infinity, height: 16),
            SizedBox(height: 12),
            SkeletonLoader(width: double.infinity, height: 16),
          ],
        ),
      );
    }

    final info = _deviceInfo ?? {
      'firmware': 'v2.1.0-beta',
      'serialNumber': 'HS-ESP32-94A2-9482',
      'hardwareVersion': 'v2.0-RevC',
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 16),
          _buildInfoRow('Firmware Version', info['firmware']!),
          _buildInfoRow('Serial Number', info['serialNumber']!),
          _buildInfoRow('Hardware Version', info['hardwareVersion']!),
          _buildInfoRow('MAC Address', ref.read(bleServiceProvider).connectedDeviceId ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subtitleColor, fontSize: 13)),
          Text(val, style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOtaUpdateCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_security_update_rounded, color: primaryBtnColor, size: 22),
              const SizedBox(width: 8),
              Text('Firmware Update (OTA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your device is currently running firmware version v2.1.0-beta. A new version is available.',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Firmware up to date. OTA check complete.'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBtnColor,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Check for Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedHeader(bool isConnecting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Column(
      children: [
        Icon(Icons.bluetooth_searching_rounded, color: subtitleColor.withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text(
          'No Connected Device',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan and select your HealthSync Band to begin monitoring.',
          style: TextStyle(fontSize: 13, color: subtitleColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isScanning || isConnecting ? null : _startScan,
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          label: Text(
            _isScanning ? 'Scanning...' : 'Scan Devices',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBtnColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedDevicesList(BleService ble, bool isConnecting) {
    final scanResults = ref.watch(scanResultsStreamProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtitleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryBtnColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    if (_isScanning && scanResults.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 32),
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBtnColor)),
          const SizedBox(height: 16),
          Text('Searching for HealthSync wearable...', style: TextStyle(color: subtitleColor, fontSize: 13)),
        ],
      );
    }

    if (scanResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text('No devices found. Tap Scan above.', style: TextStyle(color: subtitleColor.withOpacity(0.5))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discovered Devices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: scanResults.length,
          itemBuilder: (context, index) {
            final device = scanResults[index];
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
                        color: subtitleColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bluetooth_rounded, color: AppTheme.spo2Mint),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.name, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
                          const SizedBox(height: 2),
                          Text('ID: ${device.id} | RSSI: ${device.rssi} dBm', style: TextStyle(fontSize: 11, color: subtitleColor)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isConnecting
                          ? null
                          : () async {
                              _stopScan();
                              await ble.connect(device.id);
                              await _fetchDeviceMetadata();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isConnecting 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                          : const Text('Pair', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
