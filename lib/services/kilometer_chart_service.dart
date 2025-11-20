import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kilometer_chart_data_model.dart';

final supabase = Supabase.instance.client;

class KilometerChartService {
  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Obtiene datos para el gráfico de kilómetros filtrados por período
  Future<List<KilometerChartData>> getKilometerChartData({
    required String carId,
    required String period, // 'week', 'month', 'year'
  }) async {
    final response = await supabase
        .from('kilometer_records')
        .select('date, kilometers, notes')
        .eq('car_id', carId)
        .order('date', ascending: true);

    if (response != null && response is List) {
      List<KilometerChartData> allData = response.map((map) {
        return KilometerChartData(
          date: DateTime.parse(map['date']),
          kilometers: map['kilometers'],
          notes: map['notes'],
        );
      }).toList();

      return _filterByPeriod(allData, period);
    }
    return [];
  }

  List<KilometerChartData> _filterByPeriod(List<KilometerChartData> data, String period) {
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
  Future<Map<String, dynamic>> getKilometerStatsSummary({
    required String carId,
    required String period,
  }) async {
    final chartData = await getKilometerChartData(carId: carId, period: period);
    
    if (chartData.isEmpty) {
      return {
        'totalKilometers': 0,
        'averageKilometers': 0,
        'dataPoints': 0,
      };
    }

    final totalKilometers = chartData.last.kilometers - chartData.first.kilometers;
    final averageKilometers = totalKilometers / chartData.length;

    return {
      'totalKilometers': totalKilometers,
      'averageKilometers': averageKilometers,
      'dataPoints': chartData.length,
    };
  }
}