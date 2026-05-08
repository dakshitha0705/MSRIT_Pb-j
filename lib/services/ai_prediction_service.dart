class AiPredictionService {
  static List<double> predict(List<double> values, {int steps = 6}) {
    if (values.length < 2) {
      return List.filled(steps, values.isEmpty ? 0.0 : values.last);
    }
    final n = values.length;
    final sumX = n * (n - 1) / 2.0;
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6.0;
    final sumY = values.fold(0.0, (a, b) => a + b);
    double sumXY = 0;
    for (int i = 0; i < n; i++) sumXY += i * values[i];
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    return List<double>.generate(steps, (i) {
      final v = intercept + slope * (n + i);
      return v.clamp(0.0, double.maxFinite);
    });
  }

  static String batteryAlert(List<double> predicted) {
    final idx = predicted.indexWhere((v) => v <= 5);
    if (idx < 0) return '';
    final mins = idx * 5;
    return 'Your battery may hit 5% in about $mins minutes.';
  }
}
