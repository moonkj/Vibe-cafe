import 'dart:math' show sqrt;

/// Filters invalid dB readings from the noise meter stream.
class NoiseFilter {
  NoiseFilter._();

  static const double _maxValidDb = 120.0;
  static const double _minValidDb = 0.0;
  static const double _outlierMultiplier = 2.5;

  /// Returns true if [db] is a valid measurement.
  static bool isValid(double db) {
    return db >= _minValidDb && db < _maxValidDb && db.isFinite;
  }

  /// Filters outliers from a rolling window using mean + stddev.
  /// Returns filtered list with outliers removed.
  static List<double> filterOutliers(List<double> readings) {
    if (readings.length < 3) return readings;

    final mean = readings.reduce((a, b) => a + b) / readings.length;
    final variance = readings
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        readings.length;
    final stddev = variance == 0 ? 1.0 : sqrt(variance);

    return readings
        .where((x) => (x - mean).abs() <= _outlierMultiplier * stddev)
        .toList();
  }
}
