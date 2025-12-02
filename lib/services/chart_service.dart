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
    required String chartType, // 'pricePerLiter' o 'totalPrice'
  }) async {
    final response = await supabase
        .from('refuels')
        .select('date, liters, total_price, price_per_liter')
        .eq('car_id', carId)
        .order('date', ascending: true);

    if (response != null && response is List) {
      List<FuelChartData> allData = response.map<FuelChartData>((map) {
        final date = DateTime.parse(map['date'] as String);
        return FuelChartData(
          period: _getPeriodKey(date, period),
          date: date,
          pricePerLiter: (map['price_per_liter'] as num).toDouble(),
          liters: (map['liters'] as num).toDouble(),
          totalPrice: (map['total_price'] as num).toDouble(),
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

  String _getPeriodKey(DateTime date, String period) {
    switch (period) {
      case 'week':
        final weekNumber = _getWeekNumber(date);
        return 'Semana $weekNumber';
      case 'month':
        final monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                           'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        return monthNames[date.month - 1];
      case 'year':
        return date.year.toString();
      default:
        return '${date.day}/${date.month}';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.add(Duration(days: (daysOffset >= 0 ? 7 - daysOffset : -daysOffset)));
    final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }

  /// Obtiene estadísticas resumidas para el período seleccionado
  Future<Map<String, dynamic>> getFuelStatsSummary({
    required String carId,
    required String period,
    required String chartType, // 'pricePerLiter' o 'totalPrice'
  }) async {
    // Primero obtener todos los datos sin filtrar por período
    final response = await supabase
        .from('refuels')
        .select('date, liters, total_price, price_per_liter')
        .eq('car_id', carId)
        .order('date', ascending: true);

    if (response == null || response is! List || response.isEmpty) {
      // Devolver estructura diferente según el tipo de gráfico
      if (chartType == 'pricePerLiter') {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'totalRefuels': 0,
          'unit': '€/L',
        };
      } else {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'totalRefuels': 0,
          'unit': '€',
        };
      }
    }

    // Convertir respuesta a FuelChartData
    List<FuelChartData> allData = response.map<FuelChartData>((map) {
      final date = DateTime.parse(map['date'] as String);
      return FuelChartData(
        period: _getPeriodKey(date, period),
        date: date,
        pricePerLiter: (map['price_per_liter'] as num).toDouble(),
        liters: (map['liters'] as num).toDouble(),
        totalPrice: (map['total_price'] as num).toDouble(),
      );
    }).toList();

    // Filtrar por período
    final filteredData = _filterByPeriod(allData, period);
    
    if (filteredData.isEmpty) {
      if (chartType == 'pricePerLiter') {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'totalRefuels': 0,
          'unit': '€/L',
        };
      } else {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'totalRefuels': 0,
          'unit': '€',
        };
      }
    }

    if (chartType == 'pricePerLiter') {
      // Estadísticas para precio por litro
      final totalLiters = filteredData.fold(0.0, (sum, d) => sum + d.liters);
      final totalSpent = filteredData.fold(0.0, (sum, d) => sum + d.totalPrice);
      final averagePricePerLiter = totalLiters > 0 ? totalSpent / totalLiters : 0;
      
      // Encontrar precio mínimo y máximo por litro
      double minPrice = double.infinity;
      double maxPrice = 0;
      
      for (final refuel in filteredData) {
        final pricePerLiter = refuel.pricePerLiter;
        if (pricePerLiter < minPrice) minPrice = pricePerLiter;
        if (pricePerLiter > maxPrice) maxPrice = pricePerLiter;
      }
      
      return {
        'average': averagePricePerLiter,
        'min': minPrice == double.infinity ? 0 : minPrice,
        'max': maxPrice,
        'totalRefuels': filteredData.length,
        'unit': '€/L',
      };
    } else {
      // Estadísticas para precio total
      final totalSpent = filteredData.fold(0.0, (sum, d) => sum + d.totalPrice);
      final averageTotal = filteredData.isNotEmpty ? totalSpent / filteredData.length : 0;
      
      // Encontrar total mínimo y máximo
      double minTotal = double.infinity;
      double maxTotal = 0;
      
      for (final refuel in filteredData) {
        final total = refuel.totalPrice;
        if (total < minTotal) minTotal = total;
        if (total > maxTotal) maxTotal = total;
      }
      
      return {
        'average': averageTotal,
        'min': minTotal == double.infinity ? 0 : minTotal,
        'max': maxTotal,
        'totalRefuels': filteredData.length,
        'unit': '€',
      };
    }
  }
}