class KilometerChartData {
  final DateTime date;
  final int kilometers;
  final String? notes;

  KilometerChartData({
    required this.date,
    required this.kilometers,
    this.notes,
  });
}