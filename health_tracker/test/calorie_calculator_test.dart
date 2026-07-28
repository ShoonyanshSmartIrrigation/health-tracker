import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/utils/calorie_calculator.dart';

void main() {
  group('CalorieCalculator Unit Tests', () {
    test('Stride Length Estimation', () {
      final maleStride = CalorieCalculator.estimateStrideLengthM(heightCm: 180, gender: 'Male');
      final femaleStride = CalorieCalculator.estimateStrideLengthM(heightCm: 160, gender: 'Female');

      expect(maleStride, closeTo(0.747, 0.01));
      expect(femaleStride, closeTo(0.66, 0.01));
    });

    test('Distance Calculation from Steps', () {
      final distKm = CalorieCalculator.calculateDistanceKm(
        steps: 10000,
        heightCm: 175,
        gender: 'Male',
      );

      // Stride: 175 * 0.415 = 72.625 cm = 0.72625 m
      // 10000 steps * 0.72625 m = 7262.5 m = 7.2625 km
      expect(distKm, closeTo(7.26, 0.02));
    });

    test('Calories Burned calculation', () {
      final calories = CalorieCalculator.calculateCaloriesBurned(
        steps: 8000,
        weightKg: 70,
        heightCm: 178,
        gender: 'Male',
      );

      // Stride: 178 * 0.415 = 0.7387 m
      // Pace standard check: 8000 steps / 100 = 80 min = 1.33 hrs
      // MET net = 3.8 - 1 = 2.8.
      // Net Active Calories = 2.8 * 70 kg * 1.33 hrs = ~261 kcal
      expect(calories, greaterThan(100));
      expect(calories, lessThan(600));
    });

    test('Active minutes estimation', () {
      final mins = CalorieCalculator.estimateActiveMinutes(5200);
      expect(mins, equals(52));
    });
  });
}
