import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/car_service.dart';
import '../services/refuel_service.dart';
import '../models/refuel_model.dart';
import '../services/chart_service.dart';
import '../models/chart_data_model.dart';
import '../widgets/fuel_chart_widget.dart';

class RefuelPage extends StatefulWidget {
  const RefuelPage({super.key});

  @override
  State<RefuelPage> createState() => _RefuelPageState();
}

class _RefuelPageState extends State<RefuelPage> {
  final CarService carService = CarService();
  final RefuelService refuelService = RefuelService();
  final ChartService chartService = ChartService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? selectedCarId;
  List<Map<String, dynamic>> cars = [];
  List<Refuel> refuels = [];
  Map<String, dynamic> stats = {};

  // Variables para el gráfico
  List<FuelChartData> chartData = [];
  String selectedPeriod = 'month';
  Map<String, dynamic> chartStats = {};

  // Controladores para el formulario
  final TextEditingController litersController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
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
    
    final fetchedRefuels = await refuelService.getRefuelsByCar(selectedCarId!);
    final fetchedStats = await refuelService.getRefuelStats(selectedCarId!);
    
    setState(() {
      refuels = fetchedRefuels;
      stats = fetchedStats;
    });
    
    await loadChartData();
  }

  Future<void> loadChartData() async {
    if (selectedCarId == null) return;
    
    final fetchedChartData = await chartService.getFuelChartData(
      carId: selectedCarId!,
      period: selectedPeriod,
    );
    
    final fetchedStats = await chartService.getFuelStatsSummary(
      carId: selectedCarId!,
      period: selectedPeriod,
    );
    
    setState(() {
      chartData = fetchedChartData;
      chartStats = fetchedStats;
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

  Future<void> _addRefuel() async {
    if (selectedCarId == null) return;

    final liters = double.tryParse(litersController.text);
    final totalPrice = double.tryParse(totalPriceController.text);

    if (liters == null || totalPrice == null || liters <= 0 || totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce valores válidos')),
      );
      return;
    }

    try {
      await refuelService.addRefuel(
        carId: selectedCarId!,
        date: selectedDate,
        liters: liters,
        totalPrice: totalPrice,
      );

      // Limpiar formulario
      litersController.clear();
      totalPriceController.clear();
      setState(() {
        selectedDate = DateTime.now();
      });

      // Recargar datos
      await loadRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repostaje añadido correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Función para manejar la selección de imagen
  Future<void> _onTicketButtonPressed() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        _handleSelectedImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        _handleSelectedImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  void _handleSelectedImage(XFile image) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket seleccionado: ${image.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    debugPrint('Imagen del ticket: ${image.path}');
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
    final isSelected = selectedPeriod == period;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedPeriod = period;
        });
        loadChartData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
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
      appBar: AppBar(title: const Text('Gestión de Repostajes')),
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
              
              // Gráfica
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FuelChartWidget(
                  chartData: chartData,
                  selectedPeriod: selectedPeriod,
                ),
              ),

              // Formulario para añadir repostaje CON BOTÓN DE TICKET
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Añadir Repostaje',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          // Botón del ticket
                          Container(
                            width: 50,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _onTicketButtonPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(6),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt, size: 20),
                                  SizedBox(height: 2),
                                  Text(
                                    'Ticket',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fecha
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Fecha del repostaje'),
                        subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        onTap: () => _selectDate(context),
                      ),

                      // Litros
                      TextField(
                        controller: litersController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Litros repostados',
                          border: OutlineInputBorder(),
                          suffixText: 'L',
                          hintText: 'Ej: 45.50',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Precio total
                      TextField(
                        controller: totalPriceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio total',
                          border: OutlineInputBorder(),
                          suffixText: '€',
                          hintText: 'Ej: 65.25',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Precio por litro (calculado)
                      if (litersController.text.isNotEmpty && totalPriceController.text.isNotEmpty)
                        _buildPricePerLiter(),

                      const SizedBox(height: 16),
                      
                      ElevatedButton(
                        onPressed: _addRefuel,
                        child: const Text('Añadir Repostaje'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de repostajes
              _buildRefuelsList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estadísticas Totales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Repostajes', '${stats['refuelCount'] ?? 0}'),
                _buildStatItem('Litros totales', '${stats['totalLiters']?.toStringAsFixed(1) ?? '0'}L'),
                _buildStatItem('Precio medio', '${stats['averagePricePerLiter']?.toStringAsFixed(3) ?? '0'}€/L'),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPricePerLiter() {
    final liters = double.tryParse(litersController.text) ?? 0;
    final totalPrice = double.tryParse(totalPriceController.text) ?? 0;
    final pricePerLiter = liters > 0 ? totalPrice / liters : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Precio por litro:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${pricePerLiter.toStringAsFixed(3)} €/L',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefuelsList() {
    if (refuels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No hay repostajes registrados'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Repostajes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: refuels.length,
              itemBuilder: (context, index) {
                final refuel = refuels[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.local_gas_station, color: Colors.blue),
                    title: Text('${refuel.liters.toStringAsFixed(2)} L - ${refuel.totalPrice.toStringAsFixed(2)}€'),
                    subtitle: Text(
                      '${refuel.date.day}/${refuel.date.month}/${refuel.date.year} - ${refuel.pricePerLiter.toStringAsFixed(3)}€/L',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await refuelService.deleteRefuel(refuel.id);
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