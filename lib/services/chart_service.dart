import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chart_data_model.dart';

final supabase = Supabase.instance.client;

class ChartService {
  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Obtiene datos para el gráfico de combustible filtrados por período
  Future<List<FuelChartData>> getFuelChartData({
    required String carId,
    required String period, // 'week', 'month', 'year'
  }) async {
    final response = await supabase
        .from('refuels')
        .select('date, liters, total_price, price_per_liter')
        .eq('car_id', carId)
        .order('date', ascending: true);

    if (response != null && response is List) {
      List<FuelChartData> allData = response.map((map) {
        return FuelChartData(
          date: DateTime.parse(map['date']),
          pricePerLiter: map['price_per_liter'].toDouble(),
          liters: map['liters'].toDouble(),
          totalPrice: map['total_price'].toDouble(),
        );
      }).toList();

      // Filtrar por período
      return _filterByPeriod(allData, period);
    }
    return [];
  }

  List<FuelChartData> _filterByPeriod(List<FuelChartData> data, String period) {
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
  Future<Map<String, dynamic>> getFuelStatsSummary({
    required String carId,
    required String period,
  }) async {
    final chartData = await getFuelChartData(carId: carId, period: period);
    
    if (chartData.isEmpty) {
      return {
        'averagePrice': 0.0,
        'totalLiters': 0.0,
        'totalSpent': 0.0,
        'dataPoints': 0,
      };
    }

    final totalLiters = chartData.map((d) => d.liters).reduce((a, b) => a + b);
    final totalSpent = chartData.map((d) => d.totalPrice).reduce((a, b) => a + b);
    final averagePrice = totalSpent / totalLiters;

    return {
      'averagePrice': averagePrice,
      'totalLiters': totalLiters,
      'totalSpent': totalSpent,
      'dataPoints': chartData.length,
    };
  }
}