import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/kilometer_chart_data_model.dart';

class KilometerChartWidget extends StatefulWidget {
  final List<KilometerChartData> chartData;
  final String selectedPeriod;

  const KilometerChartWidget({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
  });

  @override
  State<KilometerChartWidget> createState() => _KilometerChartWidgetState();
}

class _KilometerChartWidgetState extends State<KilometerChartWidget> {
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
              'Evolución de Kilómetros',
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
          minY: _getMinKilometers(),
          maxY: _getMaxKilometers(),
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(),
              isCurved: true,
              color: Colors.green,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.3),
              ),
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
      return FlSpot(index.toDouble(), data.kilometers.toDouble());
    }).toList();
  }

  double _getMinKilometers() {
    if (widget.chartData.isEmpty) return 0;
    final minKm = widget.chartData.map((d) => d.kilometers).reduce((a, b) => a < b ? a : b);
    return (minKm * 0.95);
  }

  double _getMaxKilometers() {
    if (widget.chartData.isEmpty) return 1;
    final maxKm = widget.chartData.map((d) => d.kilometers).reduce((a, b) => a > b ? a : b);
    return (maxKm * 1.05);
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
        reservedSize: 60,
        interval: _getKilometerInterval(),
        getTitlesWidget: (value, meta) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              '${value.toInt()}',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        },
      );

  double _getKilometerInterval() {
    if (widget.chartData.isEmpty) return 1000;
    
    final minKm = _getMinKilometers();
    final maxKm = _getMaxKilometers();
    final range = maxKm - minKm;
    
    if (range <= 100) return 20;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    if (range <= 5000) return 500;
    return 1000;
  }

  Widget _buildStatsSummary() {
    final totalKilometers = widget.chartData.last.kilometers - widget.chartData.first.kilometers;
    final averagePerRecord = totalKilometers / widget.chartData.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Kilómetros totales', '$totalKilometers km'),
        _buildStatItem('Promedio por registro', '${averagePerRecord.toStringAsFixed(0)} km'),
        _buildStatItem('Registros', '${widget.chartData.length}'),
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
            const Icon(Icons.trending_up, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay datos para mostrar',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade registros de kilómetros para ver el gráfico',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}