import 'package:flutter/material.dart';
import 'package:kilometrosycentimos/pages/home_page.dart';
import 'package:kilometrosycentimos/pages/kilometers_page.dart';
import 'package:kilometrosycentimos/pages/refuel_page.dart';
import 'package:kilometrosycentimos/pages/mechanic_page.dart';
import 'package:kilometrosycentimos/services/auth_service.dart';
import 'package:kilometrosycentimos/pages/login_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    const HomePage(),
    const KilometersPage(),
    const RefuelPage(),
    const MechanicPage(),
  ];

  Future<void> _signOut() async {
    try {
      await _authService.signOut(); // ✅ Usar Supabase en lugar de Firebase
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // Aún así navegar al login
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilómetros y Céntimos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut, // ✅ Usar la nueva función
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 33, 150, 243),
        unselectedItemColor: const Color.fromARGB(128, 33, 150, 243),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: const IconThemeData(size: 32),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'KM'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Repostajes'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mecánico'),
        ],
      ),
    );
  }
}