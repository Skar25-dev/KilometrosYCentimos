import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_model.dart';

class FuelChartWidget extends StatefulWidget {
  final List<FuelChartData> chartData;
  final String selectedPeriod;
  final String chartType; // 'pricePerLiter' o 'totalPrice'
  final Map<String, dynamic>? chartStats;

  const FuelChartWidget({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
    required this.chartType,
    this.chartStats,
  });

  @override
  State<FuelChartWidget> createState() => _FuelChartWidgetState();
}

class _FuelChartWidgetState extends State<FuelChartWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
      return _buildEmptyState();
    }

    final chartTitle = widget.chartType == 'pricePerLiter' 
        ? 'Evolución del Precio por Litro'
        : 'Evolución del Precio Total por Repostaje';
    
    final yAxisTitle = widget.chartType == 'pricePerLiter' ? '€/L' : '€';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Estadísticas del gráfico
            if (widget.chartStats != null && widget.chartStats!.isNotEmpty)
              _buildChartStats(),
            
            const SizedBox(height: 16),
            _buildChart(yAxisTitle),
            const SizedBox(height: 16),
            _buildStatsSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String yAxisTitle) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: _bottomTitles,
            ),
            leftTitles: AxisTitles(
              sideTitles: _leftTitles(yAxisTitle),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: widget.chartData.length > 1 ? (widget.chartData.length - 1).toDouble() : 1,
          minY: _getMinValue(),
          maxY: _getMaxValue(),
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(),
              isCurved: true,
              color: Colors.blue, // ✅ Mismo color azul para ambas gráficas
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1), // ✅ Mismo color con transparencia
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartStats() {
    final stats = widget.chartStats!;
    final unit = stats['unit'] ?? '';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Media', '${stats['average']?.toStringAsFixed(3) ?? '0'} $unit'),
        _buildStatItem('Mín', '${stats['min']?.toStringAsFixed(2) ?? '0'} $unit'),
        _buildStatItem('Máx', '${stats['max']?.toStringAsFixed(2) ?? '0'} $unit'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  List<FlSpot> _getChartSpots() {
    return widget.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = widget.chartType == 'pricePerLiter' 
          ? data.pricePerLiter 
          : data.totalPrice;
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  double _getMinValue() {
    if (widget.chartData.isEmpty) return 0;
    
    final values = widget.chartType == 'pricePerLiter'
        ? widget.chartData.map((d) => d.pricePerLiter)
        : widget.chartData.map((d) => d.totalPrice);
    
    final minValue = values.reduce((a, b) => a < b ? a : b);
    return minValue * 0.90; // Margen del 10%
  }

  double _getMaxValue() {
    if (widget.chartData.isEmpty) return 1;
    
    final values = widget.chartType == 'pricePerLiter'
        ? widget.chartData.map((d) => d.pricePerLiter)
        : widget.chartData.map((d) => d.totalPrice);
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.10; // Margen del 10%
  }

  double _getValueInterval() {
    if (widget.chartData.isEmpty) return 1.0;
    
    final minValue = _getMinValue();
    final maxValue = _getMaxValue();
    final range = maxValue - minValue;
    
    if (range <= 0) return 1.0;
    
    // Para precio por litro (valores pequeños)
    if (widget.chartType == 'pricePerLiter') {
      if (range <= 0.1) return 0.02;
      if (range <= 0.5) return 0.05;
      if (range <= 1.0) return 0.10;
      return 0.20;
    } 
    // Para precio total (valores más grandes)
    else {
      if (range <= 5) return 1.0;
      if (range <= 20) return 5.0;
      if (range <= 50) return 10.0;
      if (range <= 100) return 20.0;
      return 50.0;
    }
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value.toInt() >= widget.chartData.length) return const Text('');
          final data = widget.chartData[value.toInt()];
          
          // Formato según el período seleccionado
          String label;
          switch (widget.selectedPeriod) {
            case 'week':
              label = 'Sem ${data.date.day}/${data.date.month}';
              break;
            case 'month':
              label = '${data.date.day}/${data.date.month}';
              break;
            case 'year':
              label = '${_getMonthName(data.date.month)}';
              break;
            default:
              label = '${data.date.day}/${data.date.month}';
          }
          
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10),
            ),
          );
        },
      );

  SideTitles _leftTitles(String yAxisTitle) => SideTitles(
        showTitles: true,
        reservedSize: 50,
        interval: _getValueInterval(),
        getTitlesWidget: (value, meta) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              widget.chartType == 'pricePerLiter'
                  ? '${value.toStringAsFixed(2)}$yAxisTitle'
                  : '${value.toStringAsFixed(0)}$yAxisTitle',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        },
      );

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  Widget _buildStatsSummary() {
    final totalLiters = widget.chartData.fold(0.0, (sum, d) => sum + d.liters);
    final totalSpent = widget.chartData.fold(0.0, (sum, d) => sum + d.totalPrice);
    final averagePrice = totalLiters > 0 ? totalSpent / totalLiters : 0;
    final averageTotal = widget.chartData.isNotEmpty ? totalSpent / widget.chartData.length : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (widget.chartType == 'pricePerLiter')
          _buildStatItem('Precio medio', '${averagePrice.toStringAsFixed(3)} €/L')
        else
          _buildStatItem('Media por repostaje', '${averageTotal.toStringAsFixed(2)} €'),
        
        _buildStatItem('Litros totales', '${totalLiters.toStringAsFixed(1)} L'),
        _buildStatItem('Total gastado', '${totalSpent.toStringAsFixed(2)} €'),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.bar_chart, 
              size: 50, 
              color: Colors.blue 
            ),
            const SizedBox(height: 16),
            Text(
              widget.chartType == 'pricePerLiter'
                  ? 'No hay datos de precio por litro'
                  : 'No hay datos de precio total',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade repostajes para ver el gráfico',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}