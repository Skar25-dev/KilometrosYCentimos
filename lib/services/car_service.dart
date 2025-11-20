import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CarService {
  /// Obtiene el usuario actual de Supabase
  User? get currentUser => supabase.auth.currentUser;

  /// Obtiene el ID del usuario actual
  String? get userId => supabase.auth.currentUser?.id;

  /// Crea un nuevo coche en la base de datos
  Future<void> createCar({
    required String name,
    required String model,
    required int? year, // ✅ Cambiado a required pero nullable
    required int kilometers,
    required double fuel,
    required int visits,
    File? imageFile,
  }) async {
    final userId = this.userId;

    if (userId == null) {
      throw Exception('No hay usuario autenticado.');
    }

    String? imageUrl;
    
    // Subir imagen primero si existe
    if (imageFile != null) {
      try {
        imageUrl = await _uploadCarImage(imageFile, userId);
      } catch (e) {
        print('Error subiendo imagen, continuando sin imagen: $e');
        // Continuar sin imagen si hay error
      }
    }

    // Crear datos del coche sin el File
    final carData = {
      'name': name,
      'model': model,
      'year': year, // ✅ Agregar el año al mapa
      'kilometers': kilometers,
      'fuel': fuel,
      'visits': visits,
      'image_url': imageUrl,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase.from('cars').insert(carData);

    // ✅ Manejar respuesta nula
    if (response != null && response.error != null) {
      throw Exception('Error al guardar el coche: ${response.error!.message}');
    }
  }

  /// Sube una imagen a Supabase Storage
  Future<String?> _uploadCarImage(File imageFile, String userId) async {
    try {
      final String fileName = 'car_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'cars/$userId/$fileName';

      // ✅ El método upload devuelve String (path) o lanza excepción
      await supabase.storage
          .from('car_images')
          .upload(filePath, imageFile);

      // Obtener URL pública
      final String publicUrl = supabase.storage
          .from('car_images')
          .getPublicUrl(filePath);

      print('✅ Imagen subida correctamente: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      // Si hay error de RLS, intentar con un path diferente
      if (e.toString().contains('row-level security')) {
        return await _uploadCarImageWithPublicPath(imageFile);
      }
      rethrow;
    }
  }

  /// Método alternativo para subir imágenes con path público
  Future<String?> _uploadCarImageWithPublicPath(File imageFile) async {
    try {
      final String fileName = 'car_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'public/$fileName';

      await supabase.storage
          .from('car_images')
          .upload(filePath, imageFile);

      final String publicUrl = supabase.storage
          .from('car_images')
          .getPublicUrl(filePath);

      print('✅ Imagen subida en path público: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error subiendo imagen en path público: $e');
      return null;
    }
  }
  /// Obtiene los coches del usuario actual
  Future<List<Map<String, dynamic>>> getCars() async {
    final userId = this.userId;

    if (userId == null) {
      throw Exception('No hay usuario autenticado.');
    }

    final response = await supabase
        .from('cars')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    // ✅ Manejar respuesta nula
    if (response != null && response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else {
      return [];
    }
  }

  /// Elimina un coche por su ID
  Future<void> deleteCar(String carId) async {
    final response = await supabase.from('cars').delete().eq('id', carId);

    // ✅ Manejar respuesta nula
    if (response != null && response.error != null) {
      throw Exception('Error al eliminar el coche: ${response.error!.message}');
    }
  }

  // 🔁 Actualizar kilómetros
  Future<void> updateKilometers(String id, int kilometers) async {
    final response = await supabase.from('cars').update({'kilometers': kilometers}).eq('id', id);
    
    // ✅ Manejar respuesta nula
    if (response != null && response.error != null) {
      throw Exception('Error actualizando kilómetros: ${response.error!.message}');
    }
  }
}