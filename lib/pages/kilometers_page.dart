import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/kilometer_service.dart';
import '../models/kilometer_record_model.dart';
import '../models/kilometer_chart_data_model.dart';
import '../services/kilometer_chart_service.dart';
import '../widgets/kilometer_chart_widget.dart';

class KilometersPage extends StatefulWidget {
  const KilometersPage({super.key});

  @override
  State<KilometersPage> createState() => _KilometersPageState();
}

class _KilometersPageState extends State<KilometersPage> {
  final CarService carService = CarService();
  final KilometerService kilometerService = KilometerService();
  final KilometerChartService kilometerChartService = KilometerChartService();
  
  String? selectedCarId;
  List<Map<String, dynamic>> cars = [];
  List<KilometerRecord> records = [];
  Map<String, dynamic> stats = {};

  List<KilometerChartData> kilometerChartData = [];
  String selectedKilometerPeriod = 'month'; // 'week', 'month', 'year'

  // Controladores para el formulario
  final TextEditingController kilometersController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
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
      if (fetched.isNotEmpty) {
        selectedCarId = fetched.first['id'].toString();
        loadRecords(); 
      }
    });
  }

  Future<void> loadRecords() async {
    if (selectedCarId == null) return;
    
    final fetchedRecords = await kilometerService.getRecordsByCar(selectedCarId!);
    final fetchedStats = await kilometerService.getKilometerStats(selectedCarId!);
    
    setState(() {
      records = fetchedRecords;
      stats = fetchedStats;
    });
    
    await loadKilometerChartData();
  }

  Future<void> loadKilometerChartData() async {
    if (selectedCarId == null) return;
    
    final fetchedChartData = await kilometerChartService.getKilometerChartData(
      carId: selectedCarId!,
      period: selectedKilometerPeriod,
    );
    
    setState(() {
      kilometerChartData = fetchedChartData;
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

  Future<void> _addRecord() async {
    if (selectedCarId == null) return;

    final kilometers = int.tryParse(kilometersController.text);
    final notes = notesController.text.trim();

    if (kilometers == null || kilometers <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce kilómetros válidos')),
      );
      return;
    }

    try {
      await kilometerService.addKilometerRecord(
        carId: selectedCarId!,
        date: selectedDate,
        kilometers: kilometers,
        notes: notes.isNotEmpty ? notes : null,
      );

      // Limpiar formulario
      kilometersController.clear();
      notesController.clear();
      setState(() {
        selectedDate = DateTime.now();
      });

      // Recargar datos
      await loadRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro de kilómetros añadido correctamente')),
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
    final isSelected = selectedKilometerPeriod == period;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedKilometerPeriod = period;
        });
        loadKilometerChartData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
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
      appBar: AppBar(title: const Text('Registro de Kilómetros')),
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
                    // ✅ AQUÍ TAMBIÉN - Mensaje contextual mejorado
                    hint: cars.isEmpty ? const Text('No hay coches') : const Text('Elige un coche'),
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
                      loadRecords();
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
              
              KilometerChartWidget(
                chartData: kilometerChartData,
                selectedPeriod: selectedKilometerPeriod,
              ),

              // Formulario para añadir registro
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Añadir Registro de Kilómetros',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Fecha
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Fecha del registro'),
                        subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        onTap: () => _selectDate(context),
                      ),

                      // Kilómetros
                      TextField(
                        controller: kilometersController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kilómetros',
                          border: OutlineInputBorder(),
                          suffixText: 'km',
                          hintText: 'Ej: 125000',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Notas (opcional)
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Viaje a la costa, revisión programada...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _addRecord,
                        child: const Text('Añadir Registro'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de registros
              _buildRecordsList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final lastRecord = stats['lastRecord'];
    final recordCount = stats['recordCount'] ?? 0;
    final sumOfAllRecords = stats['sumOfAllRecords'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estadísticas de Kilómetros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Últimos km', 
                  '${stats['totalKilometers'] ?? 0}',
                  'km'
                ),
                _buildStatItem(
                  'Registros', 
                  '$recordCount',
                  ''
                ),
                _buildStatItem(
                  'Total registrado', 
                  '$sumOfAllRecords',
                  'km'
                ),
              ],
            ),
            if (lastRecord != null) ...[
              const SizedBox(height: 8),
              Text(
                'Último registro: ${lastRecord.day}/${lastRecord.month}/${lastRecord.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          '$value$unit',
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

  Widget _buildRecordsList() {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No hay registros de kilómetros'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Registros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.speed, color: Colors.green),
                    title: Text('${record.kilometers} km'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${record.date.day}/${record.date.month}/${record.date.year}'),
                        if (record.notes != null && record.notes!.isNotEmpty)
                          Text(
                            record.notes!,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await kilometerService.deleteRecord(record.id);
                        await loadRecords();
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