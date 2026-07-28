import 'dart:convert';
import 'dart:typed_data';

class BlePacketParser {
  /// Parses a single uint8 byte for Heart Rate (BPM)
  static int parseHeartRate(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    return bytes[0];
  }

  /// Parses 4 bytes as a uint32 for Step Count (Little Endian by default)
  static int parseSteps(List<int> bytes, {bool isLittleEndian = true}) {
    if (bytes.length < 4) return 0;
    final buffer = Uint8List.fromList(bytes).buffer;
    final byteData = ByteData.view(buffer);
    return byteData.getUint32(0, isLittleEndian ? Endian.little : Endian.big);
  }

  /// Parses a single uint8 byte for SpO2 percentage
  static int parseSpO2(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    return bytes[0];
  }

  /// Parses 4 bytes as a float32 for Temperature (Little Endian by default)
  static double parseTemperature(List<int> bytes, {bool isLittleEndian = true}) {
    if (bytes.length < 4) return 0.0;
    final buffer = Uint8List.fromList(bytes).buffer;
    final byteData = ByteData.view(buffer);
    final val = byteData.getFloat32(0, isLittleEndian ? Endian.little : Endian.big);
    // Round to 2 decimal places
    return double.parse(val.toStringAsFixed(2));
  }

  /// Parses a single uint8 byte for Battery level percentage
  static int parseBattery(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    return bytes[0];
  }

  /// Parses bytes to string representing Device Info
  /// format: "firmware,serialNumber,hardwareVersion"
  static Map<String, String> parseDeviceInfo(List<int> bytes) {
    try {
      final text = utf8.decode(bytes);
      final parts = text.split(',');
      return {
        'firmware': parts.isNotEmpty ? parts[0].trim() : 'Unknown',
        'serialNumber': parts.length > 1 ? parts[1].trim() : 'Unknown',
        'hardwareVersion': parts.length > 2 ? parts[2].trim() : 'Unknown',
      };
    } catch (_) {
      return {
        'firmware': 'v1.0.0',
        'serialNumber': 'HS-ESP32-MOCK',
        'hardwareVersion': 'v1.0',
      };
    }
  }

  /// Helper to convert a float to a 4-byte byte array (useful for verification or writing)
  static List<int> floatToBytes(double value, {bool isLittleEndian = true}) {
    final buffer = Uint8List(4);
    final byteData = ByteData.view(buffer.buffer);
    byteData.setFloat32(0, value, isLittleEndian ? Endian.little : Endian.big);
    return buffer.toList();
  }

  /// Helper to convert a uint32 to a 4-byte byte array
  static List<int> uint32ToBytes(int value, {bool isLittleEndian = true}) {
    final buffer = Uint8List(4);
    final byteData = ByteData.view(buffer.buffer);
    byteData.setUint32(0, value, isLittleEndian ? Endian.little : Endian.big);
    return buffer.toList();
  }
}
