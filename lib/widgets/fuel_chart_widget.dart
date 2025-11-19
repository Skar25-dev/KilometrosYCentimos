import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data_model.dart';

class FuelChartWidget extends StatefulWidget {
  final List<FuelChartData> chartData;
  final String selectedPeriod;

  const FuelChartWidget({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis de Combustible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildChart(),
            const SizedBox(height: 16),
            _buildStatsSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
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
              sideTitles: _leftTitles,
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
          minY: _getMinPrice(),
          maxY: _getMaxPrice(),
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    return widget.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.pricePerLiter);
    }).toList();
  }

  double _getMinPrice() {
    if (widget.chartData.isEmpty) return 0;
    final minPrice = widget.chartData.map((d) => d.pricePerLiter).reduce((a, b) => a < b ? a : b);
    return (minPrice * 0.90); // ✅ Más margen (antes era 0.95)
  }

  double _getMaxPrice() {
    if (widget.chartData.isEmpty) return 1;
    final maxPrice = widget.chartData.map((d) => d.pricePerLiter).reduce((a, b) => a > b ? a : b);
    return (maxPrice * 1.10); // ✅ Más margen (antes era 1.05)
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value.toInt() >= widget.chartData.length) return const Text('');
          final data = widget.chartData[value.toInt()];
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${data.date.day}/${data.date.month}',
              style: const TextStyle(fontSize: 10),
            ),
          );
        },
      );

  SideTitles get _leftTitles => SideTitles(
        showTitles: true,
        reservedSize: 50, // ✅ Más espacio reservado para el eje Y
        interval: _getPriceInterval(), // ✅ Intervalo más espaciado
        getTitlesWidget: (value, meta) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0), // ✅ Más padding a la derecha
            child: Text(
              '${value.toStringAsFixed(2)}€',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        },
      );

  // ✅ Nuevo método para calcular intervalos más espaciados
  double _getPriceInterval() {
    if (widget.chartData.isEmpty) return 1.0;
    
    final minPrice = _getMinPrice();
    final maxPrice = _getMaxPrice();
    final range = maxPrice - minPrice;
    
    if (range <= 0.1) return 0.02;  // Para rangos muy pequeños
    if (range <= 0.5) return 0.05;  // Para rangos pequeños
    if (range <= 1.0) return 0.10;  // Para rangos medianos
    return 0.20;                    // Para rangos grandes
  }

  Widget _buildStatsSummary() {
    final totalLiters = widget.chartData.map((d) => d.liters).reduce((a, b) => a + b);
    final totalSpent = widget.chartData.map((d) => d.totalPrice).reduce((a, b) => a + b);
    final averagePrice = totalSpent / totalLiters;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Precio medio', '${averagePrice.toStringAsFixed(3)} €/L'),
        _buildStatItem('Litros totales', '${totalLiters.toStringAsFixed(1)} L'),
        _buildStatItem('Total gastado', '${totalSpent.toStringAsFixed(2)} €'),
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

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.bar_chart, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay datos para mostrar',
              style: TextStyle(color: Colors.grey),
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