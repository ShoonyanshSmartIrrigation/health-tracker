import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/utils/ble_packet_parser.dart';

void main() {
  group('BlePacketParser Unit Tests', () {
    test('Parse Heart Rate Byte', () {
      final bytes = [78]; // 78 BPM
      final hr = BlePacketParser.parseHeartRate(bytes);
      expect(hr, equals(78));
    });

    test('Parse Steps uint32 Little Endian', () {
      // 4500 steps = 0x00001194. In Little Endian bytes: [0x94, 0x11, 0x00, 0x00]
      final bytes = [0x94, 0x11, 0x00, 0x00];
      final steps = BlePacketParser.parseSteps(bytes);
      expect(steps, equals(4500));
    });

    test('Parse SpO2 Byte', () {
      final bytes = [98]; // 98% oxygen
      final spo2 = BlePacketParser.parseSpO2(bytes);
      expect(spo2, equals(98));
    });

    test('Parse Temperature Float32', () {
      // 36.7 °C as a float32 in Little Endian: [0xCD, 0xCC, 0x12, 0x42]
      final bytes = [0xCD, 0xCC, 0x12, 0x42];
      final temp = BlePacketParser.parseTemperature(bytes);
      expect(temp, closeTo(36.7, 0.05));
    });

    test('Convert Float to Bytes and Parse Back', () {
      final floatBytes = BlePacketParser.floatToBytes(37.54);
      final parsed = BlePacketParser.parseTemperature(floatBytes);
      expect(parsed, closeTo(37.54, 0.01));
    });

    test('Parse Device Info Metadata String', () {
      // "v2.0.1,HS-ESP32-1234,v1.2"
      final text = 'v2.0.1,HS-ESP32-1234,v1.2';
      final info = BlePacketParser.parseDeviceInfo(text.codeUnits);
      
      expect(info['firmware'], equals('v2.0.1'));
      expect(info['serialNumber'], equals('HS-ESP32-1234'));
      expect(info['hardwareVersion'], equals('v1.2'));
    });
  });
}
