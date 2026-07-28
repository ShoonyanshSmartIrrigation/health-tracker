import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/core/utils/bmi_calculator.dart';

void main() {
  group('BmiCalculator Unit Tests', () {
    test('BMI Formula Calculation', () {
      final bmi = BmiCalculator.calculateBMI(weightKg: 70, heightCm: 175);
      // BMI = 70 / (1.75 * 1.75) = 22.857
      expect(bmi, closeTo(22.86, 0.05));
    });

    test('BMI Category Matching', () {
      expect(BmiCalculator.getCategory(17.5), equals('Underweight'));
      expect(BmiCalculator.getCategory(22.0), equals('Normal'));
      expect(BmiCalculator.getCategory(27.0), equals('Overweight'));
      expect(BmiCalculator.getCategory(32.5), equals('Obese'));
    });

    test('BMI Color Mapping', () {
      expect(BmiCalculator.getCategoryColor(22.0), equals(Colors.green));
      expect(BmiCalculator.getCategoryColor(27.0), equals(Colors.orange));
    });

    test('Invalid Inputs Check', () {
      final bmiInvalid = BmiCalculator.calculateBMI(weightKg: 0, heightCm: -10);
      expect(bmiInvalid, equals(0.0));
      expect(BmiCalculator.getCategory(bmiInvalid), equals('N/A'));
    });
  });
}
