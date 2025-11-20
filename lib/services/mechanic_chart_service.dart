import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mechanic_chart_data_model.dart';

final supabase = Supabase.instance.client;

class MechanicChartService {
  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Obtiene datos para el gráfico de visitas al taller filtrados por período
  Future<List<MechanicChartData>> getMechanicChartData({
    required String carId,
    required String period, // 'week', 'month', 'year'
  }) async {
    final response = await supabase
        .from('mechanic_visits')
        .select('date, cost, workshop, description')
        .eq('car_id', carId)
        .order('date', ascending: true);

    if (response != null && response is List) {
      List<MechanicChartData> allData = response.map((map) {
        return MechanicChartData(
          date: DateTime.parse(map['date']),
          cost: map['cost'].toDouble(),
          workshop: map['workshop'],
          description: map['description'],
        );
      }).toList();

      return _filterByPeriod(allData, period);
    }
    return [];
  }

  List<MechanicChartData> _filterByPeriod(List<MechanicChartData> data, String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return data.where((item) => item.date.isAfter(weekAgo)).toList();
      
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return data.where((item) => item.date.isAfter(monthAgo)).toList();
      
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return data.where((item) => item.date.isAfter(yearAgo)).toList();
      
      default:
        return data;
    }
  }

  /// Obtiene estadísticas resumidas para el período seleccionado
  Future<Map<String, dynamic>> getMechanicStatsSummary({
    required String carId,
    required String period,
  }) async {
    final chartData = await getMechanicChartData(carId: carId, period: period);
    
    if (chartData.isEmpty) {
      return {
        'totalCost': 0.0,
        'averageCost': 0.0,
        'dataPoints': 0,
      };
    }

    final totalCost = chartData.map((d) => d.cost).reduce((a, b) => a + b);
    final averageCost = totalCost / chartData.length;

    return {
      'totalCost': totalCost,
      'averageCost': averageCost,
      'dataPoints': chartData.length,
    };
  }
}