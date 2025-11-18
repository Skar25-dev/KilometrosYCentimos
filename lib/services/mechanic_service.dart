import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mechanic_visit_model.dart';

final supabase = Supabase.instance.client;

class MechanicService {
  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Añade una nueva visita al taller
  Future<void> addMechanicVisit({
    required String carId,
    required DateTime date,
    required String description,
    required double cost,
    required String workshop,
  }) async {
    final userId = this.userId;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final visitData = {
      'car_id': carId,
      'date': date.toIso8601String(),
      'description': description,
      'cost': cost,
      'workshop': workshop,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase.from('mechanic_visits').insert(visitData);
    
    if (response != null && response.error != null) {
      throw Exception('Error al guardar visita: ${response.error!.message}');
    }
  }

  /// Obtiene todas las visitas de un coche
  Future<List<MechanicVisit>> getVisitsByCar(String carId) async {
    final response = await supabase
        .from('mechanic_visits')
        .select()
        .eq('car_id', carId)
        .order('date', ascending: false);

    if (response != null && response is List) {
      return response.map((map) => MechanicVisit.fromMap(map)).toList();
    }
    return [];
  }

  /// Elimina una visita
  Future<void> deleteVisit(String visitId) async {
    final response = await supabase.from('mechanic_visits').delete().eq('id', visitId);
    
    if (response != null && response.error != null) {
      throw Exception('Error al eliminar visita: ${response.error!.message}');
    }
  }

  /// Obtiene estadísticas de visitas
  Future<Map<String, dynamic>> getVisitStats(String carId) async {
    final visits = await getVisitsByCar(carId);
    
    if (visits.isEmpty) {
      return {
        'totalCost': 0.0,
        'visitCount': 0,
        'lastVisit': null,
      };
    }

    final totalCost = visits.map((v) => v.cost).reduce((a, b) => a + b);
    final lastVisit = visits.first.date;

    return {
      'totalCost': totalCost,
      'visitCount': visits.length,
      'lastVisit': lastVisit,
    };
  }

  /// Obtiene el número total de visitas al taller para un coche
  Future<int> getTotalVisitsCount(String carId) async {
    final visits = await getVisitsByCar(carId);
    return visits.length;
  }
}