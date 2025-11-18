class MechanicVisit {
  final String id;
  final String carId;
  final DateTime date;
  final String description;
  final double cost;
  final String workshop;

  MechanicVisit({
    required this.id,
    required this.carId,
    required this.date,
    required this.description,
    required this.cost,
    required this.workshop,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'date': date.toIso8601String(),
      'description': description,
      'cost': cost,
      'workshop': workshop,
    };
  }

  factory MechanicVisit.fromMap(Map<String, dynamic> map) {
    return MechanicVisit(
      id: map['id'],
      carId: map['car_id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      cost: map['cost'].toDouble(),
      workshop: map['workshop'],
    );
  }
}