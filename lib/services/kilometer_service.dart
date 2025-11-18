import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kilometer_record_model.dart';

final supabase = Supabase.instance.client;

class KilometerService {
  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Añade un nuevo registro de kilómetros
  Future<void> addKilometerRecord({
    required String carId,
    required DateTime date,
    required int kilometers,
    String? notes,
  }) async {
    final userId = this.userId;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final recordData = {
      'car_id': carId,
      'date': date.toIso8601String(),
      'kilometers': kilometers,
      'notes': notes,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase.from('kilometer_records').insert(recordData);
    
    if (response != null && response.error != null) {
      throw Exception('Error al guardar registro: ${response.error!.message}');
    }
  }

  /// Obtiene todos los registros de un coche
  Future<List<KilometerRecord>> getRecordsByCar(String carId) async {
    final response = await supabase
        .from('kilometer_records')
        .select()
        .eq('car_id', carId)
        .order('date', ascending: false);

    if (response != null && response is List) {
      return response.map((map) => KilometerRecord.fromMap(map)).toList();
    }
    return [];
  }

  /// Elimina un registro
  Future<void> deleteRecord(String recordId) async {
    final response = await supabase.from('kilometer_records').delete().eq('id', recordId);
    
    if (response != null && response.error != null) {
      throw Exception('Error al eliminar registro: ${response.error!.message}');
    }
  }

  /// Obtiene estadísticas de kilómetros - SUMA SIMPLE DE TODOS LOS REGISTROS
  Future<Map<String, dynamic>> getKilometerStats(String carId) async {
    final records = await getRecordsByCar(carId);
    
    if (records.isEmpty) {
      return {
        'totalKilometers': 0,
        'recordCount': 0,
        'lastRecord': null,
        'sumOfAllRecords': 0,
      };
    }

    // Ordenar por fecha ascendente para tener el orden correcto
    final sortedRecords = List<KilometerRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalKilometers = sortedRecords.last.kilometers;
    final lastRecord = sortedRecords.last.date;
    
    // SIMPLE SUMA DE TODOS LOS VALORES DE KILÓMETROS REGISTRADOS
    int sumOfAllRecords = 0;
    for (final record in sortedRecords) {
      sumOfAllRecords += record.kilometers;
    }

    return {
      'totalKilometers': totalKilometers,
      'recordCount': records.length,
      'lastRecord': lastRecord,
      'sumOfAllRecords': sumOfAllRecords,
    };
  }

  /// Obtiene la suma total de kilómetros registrados para un coche
  Future<int> getTotalKilometersSum(String carId) async {
    final records = await getRecordsByCar(carId);
    
    if (records.isEmpty) return 0;
    
    int totalSum = 0;
    for (final record in records) {
      totalSum += record.kilometers;
    }
    
    return totalSum;
  }
}