class CalorieCalculator {
  /// Estimates stride length in meters based on height in cm and gender
  static double estimateStrideLengthM({required double heightCm, required String gender}) {
    // Standard empirical ratios
    final isMale = gender.toLowerCase() == 'male';
    final ratio = isMale ? 0.415 : 0.413;
    return (heightCm * ratio) / 100.0;
  }

  /// Calculates total distance in kilometers
  static double calculateDistanceKm({
    required int steps,
    required double heightCm,
    required String gender,
  }) {
    if (steps <= 0 || heightCm <= 0) return 0.0;
    final strideM = estimateStrideLengthM(heightCm: heightCm, gender: gender);
    final distanceMeters = steps * strideM;
    return distanceMeters / 1000.0;
  }

  /// Calculates active calories burned based on weight, height, steps, and gender
  /// Using standard MET (Metabolic Equivalent) approximation for walking/running:
  /// Active Calories = MET * Weight (kg) * Time (hours).
  /// Average walking MET = 3.5. Average steps/min = 100.
  /// Hence, 1 step ≈ 0.0005 kcal * weight_kg (a very common standard estimate).
  static double calculateCaloriesBurned({
    required int steps,
    required double weightKg,
    required double heightCm,
    required String gender,
  }) {
    if (steps <= 0 || weightKg <= 0 || heightCm <= 0) return 0.0;
    
    // Stride length to understand intensity
    final strideM = estimateStrideLengthM(heightCm: heightCm, gender: gender);
    final distanceMeters = steps * strideM;
    
    // We assume an average MET value of 3.8 (moderate walk)
    // Dynamic adjustment: longer stride usually implies faster walking/jogging and higher MET
    double met = 3.8;
    if (strideM > 0.8) {
      met = 5.0; // Fast walking/jogging
    } else if (strideM < 0.6) {
      met = 3.0; // Slow stroll
    }

    // Active duration: estimate time active. 100 steps per minute is standard moderate pace.
    final durationMinutes = steps / 100.0;
    final durationHours = durationMinutes / 60.0;
    
    // Net Calories = MET * Weight (kg) * Time (hr)
    // For net active calories, we subtract resting metabolic rate (1 MET)
    final netMet = met - 1.0; 
    return netMet * weightKg * durationHours;
  }

  /// Calculates active minutes based on steps assuming a pace of >= 60 steps/minute counts as active
  static int estimateActiveMinutes(int steps) {
    if (steps <= 0) return 0;
    // Standard approximation: 100 steps represents ~1 active minute
    return (steps / 100).ceil();
  }
}
