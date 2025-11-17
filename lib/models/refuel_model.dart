class Refuel {
  final String id;
  final String carId;
  final DateTime date;
  final double liters;
  final double totalPrice;
  final double pricePerLiter;

  Refuel({
    required this.id,
    required this.carId,
    required this.date,
    required this.liters,
    required this.totalPrice,
    required this.pricePerLiter,
  });

  Map <String, dynamic> toMap() {
    return {
      'id' : id,
      'car_id' : carId,
      'date' : date.toIso8601String(),
      'liters' : liters,
      'total_price' : totalPrice,
      'price_per_liter' : pricePerLiter,
    };
  }

  factory Refuel.fromMap(Map<String, dynamic> map) {
    return Refuel(
      id: map['id'],
      carId: map['car_id'],
      date: DateTime.parse(map['date']),
      liters: map['liters'].toDouble(),
      totalPrice: map['total_price'].toDouble(),
      pricePerLiter: map['price_per_liter'].toDouble(),
    );
  }
}