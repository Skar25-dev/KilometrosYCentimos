import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/kilometer_service.dart';
import '../services/refuel_service.dart';
import '../services/mechanic_service.dart';
import 'add_car_page.dart';
import 'kilometers_page.dart';
import 'refuel_page.dart';
import 'mechanic_page.dart';
import 'car_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarService carService = CarService();
  final KilometerService kilometerService = KilometerService();
  final RefuelService refuelService = RefuelService();
  final MechanicService mechanicService = MechanicService();
  
  List<Map<String, dynamic>> cars = [];
  Map<String, dynamic> carStats = {}; // Para almacenar estadísticas por coche

  @override
  void initState() {
    super.initState();
    loadCars();
  }

  Future<void> loadCars() async {
    final data = await carService.getCars();
    setState(() => cars = data);
    
    // Cargar estadísticas para cada coche
    for (final car in data) {
      await loadCarStats(car['id']);
    }
  }

  Future<void> loadCarStats(String carId) async {
    try {
      final totalKilometers = await kilometerService.getTotalKilometersSum(carId);
      final totalRefuels = await refuelService.getTotalRefuelsCount(carId);
      final totalVisits = await mechanicService.getTotalVisitsCount(carId);
      
      setState(() {
        carStats[carId] = {
          'totalKilometers': totalKilometers,
          'totalRefuels': totalRefuels,
          'totalVisits': totalVisits,
        };
      });
    } catch (e) {
      // Si hay error (tablas no creadas), usar valores por defecto
      setState(() {
        carStats[carId] = {
          'totalKilometers': 0,
          'totalRefuels': 0,
          'totalVisits': 0,
        };
      });
    }
  }

  void _showCarOptions(Map<String, dynamic> car) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Ver detalles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarDetailPage(car: car)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Eliminar coche'),
            onTap: () async {
              Navigator.pop(context);

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: Text('¿Seguro que quieres eliminar "${car['name']}" "${car['model']}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await carService.deleteCar(car['id']);
                await loadCars();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Coche "${car['name']}" "${car['model']}" eliminado')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Registrar kilómetros'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KilometersPage()),
              ).then((_) => loadCars()); // Recargar al volver
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: const Text('Registrar repostaje'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefuelPage()),
              ).then((_) => loadCars()); // Recargar al volver
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Registrar visita al taller'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MechanicPage()),
              ).then((_) => loadCars()); // Recargar al volver
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis coches')),
      body: cars.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes coches registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para añadir uno',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                final imageUrl = car['image_url'];
                final carId = car['id'];
                final stats = carStats[carId] ?? {
                  'totalKilometers': 0,
                  'totalRefuels': 0,
                  'totalVisits': 0,
                };
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showCarOptions(car),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🖼️ IMAGEN DEL COCHE
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: imageUrl == null ? Colors.grey[200] : null,
                          ),
                          child: imageUrl == null
                              ? const Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                        
                        // 📋 INFORMACIÓN DEL COCHE
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre y Modelo
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      car['name'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (car['year'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        car['year'].toString(),
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              Text(
                                car['model'] ?? 'Sin modelo',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Estadísticas ACTUALIZADAS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    icon: Icons.speed,
                                    value: '${stats['totalKilometers']}',
                                    label: 'KM',
                                    tooltip: 'Total de kilómetros registrados',
                                  ),
                                  _buildStatItem(
                                    icon: Icons.local_gas_station,
                                    value: '${stats['totalRefuels']}',
                                    label: 'Repostajes',
                                    tooltip: 'Número de repostajes',
                                  ),
                                  _buildStatItem(
                                    icon: Icons.build,
                                    value: '${stats['totalVisits']}',
                                    label: 'Visitas',
                                    tooltip: 'Visitas al taller',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCarPage()),
          );
          if (created == true) {
            loadCars();
          }
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}