import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/mechanic_service.dart';
import '../models/mechanic_visit_model.dart';
import '../services/mechanic_chart_service.dart';
import '../models/mechanic_chart_data_model.dart'; 
import '../widgets/mechanic_chart_widget.dart';

class MechanicPage extends StatefulWidget {
  const MechanicPage({super.key});

  @override
  State<MechanicPage> createState() => _MechanicPageState();
}

class _MechanicPageState extends State<MechanicPage> {
  final CarService carService = CarService();
  final MechanicService mechanicService = MechanicService();
  final MechanicChartService mechanicChartService = MechanicChartService();
  
  String? selectedCarId;
  List<Map<String, dynamic>> cars = [];
  List<MechanicVisit> visits = [];
  Map<String, dynamic> stats = {};

  List<MechanicChartData> mechanicChartData = [];
  String selectedMechanicPeriod = 'month'; // 'week', 'month', 'year'

  // Controladores para el formulario
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController workshopController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadCars();
  }

  Future<void> loadCars() async {
    final fetched = await carService.getCars();
    setState(() {
      cars = fetched;
      if (fetched.isNotEmpty && selectedCarId == null) {
        selectedCarId = fetched.first['id'].toString();
        loadVisits(); 
      }
    });
  }

  Future<void> loadVisits() async {
    if (selectedCarId == null) return;
    
    final fetchedVisits = await mechanicService.getVisitsByCar(selectedCarId!);
    final fetchedStats = await mechanicService.getVisitStats(selectedCarId!);
    
    setState(() {
      visits = fetchedVisits;
      stats = fetchedStats;
    });
    
    await loadMechanicChartData();
  }

  Future<void> loadMechanicChartData() async {
    if (selectedCarId == null) return;
    
    final fetchedChartData = await mechanicChartService.getMechanicChartData(
      carId: selectedCarId!,
      period: selectedMechanicPeriod,
    );
    
    setState(() {
      mechanicChartData = fetchedChartData;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _addVisit() async {
    if (selectedCarId == null) return;

    final description = descriptionController.text.trim();
    final cost = double.tryParse(costController.text);
    final workshop = workshopController.text.trim();

    if (description.isEmpty || workshop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce un coste válido')),
      );
      return;
    }

    try {
      await mechanicService.addMechanicVisit(
        carId: selectedCarId!,
        date: selectedDate,
        description: description,
        cost: cost,
        workshop: workshop,
      );

      // Limpiar formulario
      descriptionController.clear();
      costController.clear();
      workshopController.clear();
      setState(() {
        selectedDate = DateTime.now();
      });

      // Recargar datos
      await loadVisits();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita al taller añadida correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPeriodSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPeriodButton('Esta semana', 'week'),
            _buildPeriodButton('Este mes', 'month'),
            _buildPeriodButton('Este año', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = selectedMechanicPeriod == period;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedMechanicPeriod = period;
        });
        loadMechanicChartData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitas al Taller')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selección de coche
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Selecciona un coche:', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCarId,
                    hint: const Text('Elige un coche'),
                    isExpanded: true,
                    items: cars.map((car) {
                      return DropdownMenuItem(
                        value: car['id'].toString(),
                        child: Text('${car['name']} (${car['model']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCarId = value;
                      });
                      loadVisits();
                    },
                  ),
                ],
              ),
            ),

            if (selectedCarId != null) ...[
              // Estadísticas
              _buildStatsCard(),
              const SizedBox(height: 20),

              _buildPeriodSelector(),
              
              MechanicChartWidget(
                chartData: mechanicChartData,
                selectedPeriod: selectedMechanicPeriod,
              ),

              // Formulario para añadir visita
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Añadir Visita al Taller',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Fecha
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Fecha de la visita'),
                        subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        onTap: () => _selectDate(context),
                      ),

                      // Taller
                      TextField(
                        controller: workshopController,
                        decoration: const InputDecoration(
                          labelText: 'Taller',
                          border: OutlineInputBorder(),
                          hintText: 'Nombre del taller',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Descripción
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción de la reparación',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Cambio de aceite y filtro, revisión general...',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Coste
                      TextField(
                        controller: costController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Coste total',
                          border: OutlineInputBorder(),
                          suffixText: '€',
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _addVisit,
                        child: const Text('Añadir Visita'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de visitas
              _buildVisitsList(),
            ] else if (cars.isEmpty) ...[
              // Mostrar mensaje cuando no hay coches
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No hay coches disponibles. Añade un coche primero.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final lastVisit = stats['lastVisit'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estadísticas de Taller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Visitas', '${stats['visitCount'] ?? 0}'),
                _buildStatItem('Total gastado', '${stats['totalCost']?.toStringAsFixed(2) ?? '0'}€'),
                _buildStatItem(
                  'Última visita', 
                  lastVisit != null 
                    ? '${lastVisit.day}/${lastVisit.month}/${lastVisit.year}'
                    : 'Nunca'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVisitsList() {
    if (visits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No hay visitas al taller registradas'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Visitas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.build, color: Colors.orange),
                    title: Text(visit.workshop),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit.description),
                        Text(
                          '${visit.date.day}/${visit.date.month}/${visit.date.year} - ${visit.cost.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await mechanicService.deleteVisit(visit.id);
                        await loadVisits();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}