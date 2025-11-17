import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refuel_model.dart';

final supabase = Supabase.instance.client;

class RefuelService {
  String? get userId => supabase.auth.currentUser?.id;

  Future<void> addRefuel({
    required String carId,
    required DateTime date,
    required double liters,
    required double totalPrice,
  }) async {
    final userId = this.userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    
    final pricePerLiter = totalPrice / liters;

    final refuelData = {
      'car_id': carId,
      'date': date.toIso8601String(),
      'liters': liters,
      'total_price': totalPrice,
      'price_per_liter': pricePerLiter,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase.from('refuels').insert(refuelData);

    if (response != null && response.error != null) {
      throw Exception('Error al guardar el repostaje: ${response.error!.message}');
    }
  }

  Future<List<Refuel>> getRefuelsByCar(String carId) async {
    final response = await supabase
        .from('refuels')
        .select()
        .eq('car_id', carId)
        .order('date', ascending: false);

    if (response != null && response is List) {
      return response.map((map) => Refuel.fromMap(map)).toList();
    }
    return [];
  }

  Future<void> deleteRefuel(String refuelId) async {
    final response = await supabase.from('refuels').delete().eq('id', refuelId);
    
    if (response != null && response.error != null) {
      throw Exception('Error al eliminar repostaje: ${response.error!.message}');
    }
  }

  Future<Map<String, dynamic>> getRefuelStats(String carId) async {
    final refuels = await getRefuelsByCar(carId);
    
    if (refuels.isEmpty) {
      return {
        'totalLiters': 0.0,
        'totalSpent': 0.0,
        'averagePricePerLiter': 0.0,
        'refuelCount': 0,
      };
    }

    final totalLiters = refuels.map((r) => r.liters).reduce((a, b) => a + b);
    final totalSpent = refuels.map((r) => r.totalPrice).reduce((a, b) => a + b);
    final averagePricePerLiter = totalSpent / totalLiters;

    return {
      'totalLiters': totalLiters,
      'totalSpent': totalSpent,
      'averagePricePerLiter': averagePricePerLiter,
      'refuelCount': refuels.length,
    };
  }
}