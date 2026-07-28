import 'package:flutter/material.dart';

class BmiCalculator {
  static double calculateBMI({required double weightKg, required double heightCm}) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  static String getCategory(double bmi) {
    if (bmi <= 0) return 'N/A';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  static Color getCategoryColor(double bmi) {
    if (bmi <= 0) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  static String getInterpretation(double bmi) {
    if (bmi <= 0) return 'Enter your physical attributes to calculate BMI.';
    if (bmi < 18.5) {
      return 'You are underweight. Focus on a nutrient-rich diet and strength training.';
    } else if (bmi < 25.0) {
      return 'Great! You have a healthy weight. Keep maintaining your lifestyle.';
    } else if (bmi < 30.0) {
      return 'You are slightly overweight. Regular exercise and portion control can help.';
    } else {
      return 'You are in the obese category. Consider consulting a health professional.';
    }
  }
}
