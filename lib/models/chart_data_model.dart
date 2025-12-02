class FuelChartData {
  final String period;
  final double pricePerLiter;
  final double totalPrice;
  final double liters;
  final DateTime date;

  FuelChartData({
    required this.period,
    required this.pricePerLiter,
    required this.totalPrice,
    required this.liters,
    required this.date,
  });
}