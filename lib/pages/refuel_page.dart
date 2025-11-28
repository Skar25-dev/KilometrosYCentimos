import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/car_service.dart';
import '../services/refuel_service.dart';
import '../models/refuel_model.dart';
import '../services/chart_service.dart';
import '../models/chart_data_model.dart';
import '../widgets/fuel_chart_widget.dart';
import '../services/ticket_mlkit_service.dart';

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
  final TicketMLKitService _mlKitService = TicketMLKitService();
  
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

  // Modo de cálculo
  String _calculationMode = 'pricePerLiter'; // 'pricePerLiter' o 'totalPrice'

  @override
  void initState() {
    super.initState();
    loadCars();
    
    // Agregar listeners para recalcular automáticamente
    litersController.addListener(_recalculateFields);
    totalPriceController.addListener(_recalculateFields);
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

  // Función para recalcular campos automáticamente
  void _recalculateFields() {
    final liters = double.tryParse(litersController.text) ?? 0;
    final inputValue = double.tryParse(totalPriceController.text) ?? 0;
    
    if (liters > 0 && inputValue > 0) {
      if (_calculationMode == 'pricePerLiter') {
        // Modo: Ingresar precio por litro → Calcular total
        final total = liters * inputValue;
        // No actualizamos el controlador para evitar loop infinito
      } else {
        // Modo: Ingresar total → Calcular precio por litro
        final pricePerLiter = inputValue / liters;
        // No actualizamos el controlador para evitar loop infinito
      }
    }
  }

  Future<void> _addRefuel() async {
    if (selectedCarId == null) return;

    final liters = double.tryParse(litersController.text);
    final inputValue = double.tryParse(totalPriceController.text);

    if (liters == null || inputValue == null || liters <= 0 || inputValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce valores válidos')),
      );
      return;
    }

    // Calcular el precio total final según el modo
    double totalPrice;
    if (_calculationMode == 'pricePerLiter') {
      totalPrice = liters * inputValue;
    } else {
      totalPrice = inputValue;
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

  void _handleSelectedImage(XFile image) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ML Kit: Analizando ticket...'),
            ],
          ),
        ),
      );

      // ✅ USAR EL SERVICIO SEPARADO
      final extractedData = await _mlKitService.processTicketImage(image);
      
      Navigator.pop(context); // Cerrar loading

      // Mostrar resultados
      _showMLKitResults(extractedData);
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ML Kit: $e')),
      );
    }
  }

  void _showMLKitResults(Map<String, dynamic> data) {
    // Calcular precio total si tenemos ambos datos
    double? calculatedTotal;
    if (data['liters'] != null && data['pricePerLiter'] != null) {
      calculatedTotal = data['liters'] * data['pricePerLiter'];
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue),
            SizedBox(width: 8),
            Text('ML Kit - Resultados'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['liters'] != null)
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: const Text('Litros detectados'),
                  subtitle: Text('${data['liters']} L', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              else
                const ListTile(
                  leading: Icon(Icons.error, color: Colors.orange),
                  title: Text('Litros no detectados'),
                  subtitle: Text('No se pudo encontrar la cantidad de litros'),
                ),
              
              if (data['pricePerLiter'] != null)
                ListTile(
                  leading: const Icon(Icons.sell, color: Colors.green),
                  title: const Text('Precio por litro detectado'),
                  subtitle: Text('${data['pricePerLiter']} €/L', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              else
                const ListTile(
                  leading: Icon(Icons.error, color: Colors.orange),
                  title: Text('Precio por litro no detectado'),
                  subtitle: Text('No se pudo encontrar el precio por litro'),
                ),
              
              if (calculatedTotal != null)
                ListTile(
                  leading: const Icon(Icons.euro, color: Colors.orange),
                  title: const Text('Precio total calculado'),
                  subtitle: Text('${calculatedTotal.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              
              if (data['date'] != null)
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.purple),
                  title: const Text('Fecha detectada'),
                  subtitle: Text('${data['date'].day}/${data['date'].month}/${data['date'].year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              
              ListTile(
                leading: const Icon(Icons.verified, color: Colors.blue),
                title: const Text('Confianza'),
                subtitle: Text(data['confidence']),
              ),

              // Para debug
              const SizedBox(height: 16),
              const Text('Texto reconocido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['rawText'] ?? 'No hay texto',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
              
              const SizedBox(height: 16),
              if (data['liters'] != null || data['pricePerLiter'] != null || data['date'] != null)
                ElevatedButton(
                  onPressed: () => _autofillForm(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Autocompletar Formulario'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _autofillForm(Map<String, dynamic> data) {
    bool filledAnyField = false;
    
    if (data['liters'] != null) {
      litersController.text = data['liters'].toString();
      filledAnyField = true;
      print('✅ Autocompletado - Litros: ${data['liters']}');
    }
    
    if (data['pricePerLiter'] != null) {
      // Dependiendo del modo, usamos un campo u otro
      if (_calculationMode == 'pricePerLiter') {
        totalPriceController.text = data['pricePerLiter'].toString();
      } else {
        // Si estamos en modo total, calculamos el total
        final liters = double.tryParse(litersController.text) ?? 0;
        if (liters > 0) {
          final total = liters * data['pricePerLiter']!;
          totalPriceController.text = total.toStringAsFixed(2);
        }
      }
      filledAnyField = true;
      print('✅ Precio por litro detectado: ${data['pricePerLiter']}');
    }
    
    if (data['date'] != null) {
      setState(() {
        selectedDate = data['date'];
      });
      filledAnyField = true;
      print('✅ Fecha autocompletada: ${data['date']}');
    }
    
    Navigator.pop(context); // Cerrar diálogo
    
    if (filledAnyField) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos autocompletados con ML Kit'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron extraer datos del ticket'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildModeButton(String label, String mode) {
    final isSelected = _calculationMode == mode;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _calculationMode = mode;
        });
        _recalculateFields();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
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

                      // Selector de modo de cálculo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modo de cálculo:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModeButton('Precio por litro', 'pricePerLiter'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildModeButton('Precio total', 'totalPrice'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Campo de precio (cambia según el modo)
                      TextField(
                        controller: totalPriceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _calculationMode == 'pricePerLiter' ? 'Precio por litro' : 'Precio total',
                          border: const OutlineInputBorder(),
                          suffixText: _calculationMode == 'pricePerLiter' ? '€/L' : '€',
                          hintText: _calculationMode == 'pricePerLiter' ? 'Ej: 1.499' : 'Ej: 65.25',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Información calculada
                      if (litersController.text.isNotEmpty && totalPriceController.text.isNotEmpty)
                        _buildCalculatedInfo(),

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

  Widget _buildCalculatedInfo() {
    final liters = double.tryParse(litersController.text) ?? 0;
    final inputValue = double.tryParse(totalPriceController.text) ?? 0;
    
    if (liters == 0 || inputValue == 0) return const SizedBox();

    double calculatedValue;
    String label;
    Color color;

    if (_calculationMode == 'pricePerLiter') {
      // Modo: Ingresar precio por litro → Mostrar total calculado
      calculatedValue = liters * inputValue;
      label = 'Precio total calculado';
      color = Colors.orange;
    } else {
      // Modo: Ingresar total → Mostrar precio por litro calculado
      calculatedValue = inputValue / liters;
      label = 'Precio por litro calculado';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _calculationMode == 'pricePerLiter' 
                ? '${calculatedValue.toStringAsFixed(2)} €'
                : '${calculatedValue.toStringAsFixed(3)} €/L',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
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

  @override
  void dispose() {
    _mlKitService.dispose();
    litersController.removeListener(_recalculateFields);
    totalPriceController.removeListener(_recalculateFields);
    super.dispose();
  }
}