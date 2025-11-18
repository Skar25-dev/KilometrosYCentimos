class KilometerRecord {
  final String id;
  final String carId;
  final DateTime date;
  final int kilometers;
  final String? notes;

  KilometerRecord({
    required this.id,
    required this.carId,
    required this.date,
    required this.kilometers,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'date': date.toIso8601String(),
      'kilometers': kilometers,
      'notes': notes,
    };
  }

  factory KilometerRecord.fromMap(Map<String, dynamic> map) {
    return KilometerRecord(
      id: map['id'],
      carId: map['car_id'],
      date: DateTime.parse(map['date']),
      kilometers: map['kilometers'],
      notes: map['notes'],
    );
  }
}