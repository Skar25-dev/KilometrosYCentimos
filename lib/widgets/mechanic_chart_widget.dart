import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mechanic_chart_data_model.dart';

class MechanicChartWidget extends StatefulWidget {
  final List<MechanicChartData> chartData;
  final String selectedPeriod;

  const MechanicChartWidget({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
  });

  @override
  State<MechanicChartWidget> createState() => _MechanicChartWidgetState();
}

class _MechanicChartWidgetState extends State<MechanicChartWidget> {
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
              'Gastos en Taller',
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
      child: BarChart(
        BarChartData(
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
          minY: 0,
          maxY: _getMaxCost(),
          barGroups: _getBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return widget.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.cost,
            color: Colors.orange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxCost() {
    if (widget.chartData.isEmpty) return 1;
    final maxCost = widget.chartData.map((d) => d.cost).reduce((a, b) => a > b ? a : b);
    return (maxCost * 1.20); // 20% más de margen
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
        interval: _getCostInterval(),
        getTitlesWidget: (value, meta) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              '${value.toInt()}€',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        },
      );

  double _getCostInterval() {
    if (widget.chartData.isEmpty) return 50;
    
    final maxCost = _getMaxCost();
    
    if (maxCost <= 50) return 10;
    if (maxCost <= 100) return 20;
    if (maxCost <= 500) return 50;
    if (maxCost <= 1000) return 100;
    return 200;
  }

  Widget _buildStatsSummary() {
    final totalCost = widget.chartData.map((d) => d.cost).reduce((a, b) => a + b);
    final averageCost = totalCost / widget.chartData.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total gastado', '${totalCost.toStringAsFixed(2)}€'),
        _buildStatItem('Costo promedio', '${averageCost.toStringAsFixed(2)}€'),
        _buildStatItem('Visitas', '${widget.chartData.length}'),
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
            const Icon(Icons.build, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay datos para mostrar',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade visitas al taller para ver el gráfico',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}