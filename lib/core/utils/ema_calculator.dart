/// Exponential Moving Average calculator for dB values.
///
/// Formula: NewAvg = (OldAvg × 0.7) + (CurrentdB × 0.3)
/// Recent readings carry higher weight, outdated values decay naturally.
class EmaCalculator {
  EmaCalculator._();

  static const double _alpha = 0.3; // weight for new reading
  static const double _beta = 0.7;  // weight for historical average

  /// Calculate new EMA given [oldAvg] and [newDb].
  /// If [reportCount] is 0 (first report), returns [newDb] directly.
  static double calculate({
    required double oldAvg,
    required double newDb,
    required int reportCount,
  }) {
    if (reportCount == 0) return newDb;
    return (oldAvg * _beta) + (newDb * _alpha);
  }
}
