import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class TicketMLKitService {
  final TextRecognizer _textRecognizer;

  TicketMLKitService() 
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> processTicketImage(XFile imageFile) async {
    try {
      print('🔍 ML Kit: Procesando imagen...');
      
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String fullText = recognizedText.text;
      print('📄 ML Kit - Texto reconocido:');
      print('=' * 40);
      print(fullText);
      print('=' * 40);
      
      return _extractTicketData(fullText);
      
    } catch (e) {
      print('❌ Error ML Kit: $e');
      throw Exception('Error ML Kit: $e');
    }
  }

  Map<String, dynamic> _extractTicketData(String text) {
    // Extraer todos los números y sus contextos
    final List<NumberWithContext> numbers = _extractAllNumbersWithContext(text);
    
    print('🔍 Números encontrados con contexto:');
    numbers.forEach((numInfo) {
      print('   ${numInfo.value} - Contexto: "${numInfo.context}" - Tipo: ${numInfo.type}');
    });

    // Clasificar los números
    final classified = _classifyNumbers(numbers);
    
    // Extraer fecha
    DateTime? date = _extractDate(text);

    print('⛽ ML Kit - Datos extraídos:');
    print('Litros: ${classified['liters']}');
    print('Precio por litro: ${classified['pricePerLiter']}');
    print('Fecha: $date');

    return {
      'liters': classified['liters'],
      'pricePerLiter': classified['pricePerLiter'],
      'date': date,
      'confidence': _calculateConfidence(
        classified['liters'], 
        classified['pricePerLiter'],
        date
      ),
      'rawText': text,
    };
  }

  List<NumberWithContext> _extractAllNumbersWithContext(String text) {
    final List<NumberWithContext> numbers = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Buscar números con decimales
      final matches = RegExp(r'(\d+[.,]\d+)').allMatches(line);
      
      for (final match in matches) {
        final value = match.group(1);
        if (value != null) {
          final doubleValue = _parseDouble(value);
          if (doubleValue != null && doubleValue > 0.1) {
            // Obtener contexto
            final context = _getNumberContext(lines, i);
            final type = _classifyNumberType(doubleValue, value, context, line);
            
            numbers.add(NumberWithContext(
              value: doubleValue,
              originalText: value,
              context: context,
              type: type,
              lineIndex: i,
              position: match.start
            ));
          }
        }
      }
    }
    
    return numbers;
  }

  String _getNumberContext(List<String> lines, int lineIndex) {
    final contextLines = <String>[];
    
    // Agregar líneas alrededor
    for (int i = max(0, lineIndex - 2); i < min(lines.length, lineIndex + 3); i++) {
      contextLines.add(lines[i].trim());
    }
    
    return contextLines.join(' | ');
  }

  NumberType _classifyNumberType(double value, String original, String context, String line) {
    final lowerContext = context.toLowerCase();
    final lowerLine = line.toLowerCase();
    
    // Precio por litro
    if (_hasThreeDecimals(value) || 
        lowerContext.contains('€/l') || 
        lowerContext.contains('e/l') ||
        lowerLine.contains('€/l') ||
        (value > 1.0 && value < 2.5)) {
      return NumberType.pricePerLiter;
    }
    
    // Litros
    if (_hasTwoDecimals(value) && value > 5 && value < 150) {
      if (lowerContext.contains(' l') ||
          lowerContext.contains('l ') ||
          lowerContext.contains('litro') ||
          lowerContext.contains('cantidad') ||
          lowerContext.contains('volumen') ||
          lowerContext.contains('diesel') ||
          lowerContext.contains('gasolina') ||
          lowerLine.contains(' l') ||
          lowerLine.contains('l ')) {
        return NumberType.liters;
      }
    }
    
    return NumberType.unknown;
  }

  Map<String, double?> _classifyNumbers(List<NumberWithContext> numbers) {
    double? liters;
    double? pricePerLiter;
    
    // Buscar precio por litro
    for (final numInfo in numbers) {
      if (numInfo.type == NumberType.pricePerLiter) {
        pricePerLiter = numInfo.value;
        print('✅ Precio por litro confirmado: $pricePerLiter');
        break;
      }
    }
    
    // Buscar litros
    for (final numInfo in numbers) {
      if (numInfo.type == NumberType.liters) {
        liters = numInfo.value;
        print('✅ Litros confirmados: $liters');
        break;
      }
    }
    
    // Si no encontramos, buscar en desconocidos
    if (liters == null) {
      for (final numInfo in numbers) {
        if (numInfo.type == NumberType.unknown && 
            _hasTwoDecimals(numInfo.value) && 
            numInfo.value > 5 && numInfo.value < 150) {
          liters = numInfo.value;
          print('✅ Litros inferidos: $liters');
          break;
        }
      }
    }
    
    return {
      'liters': liters,
      'pricePerLiter': pricePerLiter,
    };
  }

  DateTime? _extractDate(String text) {
    try {
      // Patrones de fecha más comunes en tickets
      final datePatterns = [
        // DD-MM-AAAA
        r'(\d{1,2})[-./](\d{1,2})[-./](\d{4})',
        // DD-MM-AA
        r'(\d{1,2})[-./](\d{1,2})[-./](\d{2})',
        // AAAA-MM-DD
        r'(\d{4})[-./](\d{1,2})[-./](\d{1,2})',
      ];
      
      for (final pattern in datePatterns) {
        final dateMatch = RegExp(pattern).firstMatch(text);
        if (dateMatch != null) {
          int day, month, year;
          
          if (pattern.contains(r'(\d{4})[-./]')) {
            // Formato AAAA-MM-DD
            year = int.parse(dateMatch.group(1)!);
            month = int.parse(dateMatch.group(2)!);
            day = int.parse(dateMatch.group(3)!);
          } else {
            // Formato DD-MM-AAAA o DD-MM-AA
            day = int.parse(dateMatch.group(1)!);
            month = int.parse(dateMatch.group(2)!);
            year = int.parse(dateMatch.group(3)!);
            
            // Si el año tiene 2 dígitos, convertirlo a 4
            if (year < 100) {
              year += 2000; // Asumimos años 2000+
            }
          }
          
          // Validar que la fecha sea razonable
          if (_isValidDate(day, month, year)) {
            final date = DateTime(year, month, day);
            print('✅ Fecha extraída: $date');
            return date;
          }
        }
      }
    } catch (e) {
      print('❌ Error extrayendo fecha: $e');
    }
    
    return null;
  }

  bool _isValidDate(int day, int month, int year) {
    try {
      // Validar rangos básicos
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      if (year < 2000 || year > 2100) return false;
      
      // Validar días por mes
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return day <= daysInMonth;
    } catch (e) {
      return false;
    }
  }

  bool _hasThreeDecimals(double value) {
    try {
      final parts = value.toString().split('.');
      return parts.length == 2 && parts[1].length >= 3;
    } catch (e) {
      return false;
    }
  }

  bool _hasTwoDecimals(double value) {
    try {
      final parts = value.toString().split('.');
      return parts.length == 2 && parts[1].length == 2;
    } catch (e) {
      return false;
    }
  }

  double? _parseDouble(String? value) {
    if (value == null) return null;
    try {
      return double.tryParse(value.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }

  String _calculateConfidence(double? liters, double? pricePerLiter, DateTime? date) {
    final validFields = [liters, pricePerLiter, date].where((field) => field != null).length;
    
    if (validFields == 3) return 'Muy Alta';
    if (validFields == 2) return 'Alta';
    if (validFields == 1) return 'Media';
    return 'Baja';
  }

  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;

  void dispose() {
    _textRecognizer.close();
  }
}

class NumberWithContext {
  final double value;
  final String originalText;
  final String context;
  final NumberType type;
  final int lineIndex;
  final int position;

  NumberWithContext({
    required this.value,
    required this.originalText,
    required this.context,
    required this.type,
    required this.lineIndex,
    required this.position,
  });
}

enum NumberType {
  liters,
  pricePerLiter,
  unknown
}