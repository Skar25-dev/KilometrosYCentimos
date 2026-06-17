# 🚗 Kilómetros y Céntimos - Gestión Inteligente de tu Vehículo

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-sdk_3.9+-0175C2.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E.svg)
![ML Kit](https://img.shields.io/badge/Google_ML_Kit-OCR-4285F4.svg)
![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS-informational.svg)

Aplicación móvil desarrollada con **Flutter** para llevar un registro completo de tus vehículos: kilómetros recorridos, repostajes y visitas al taller. Incluye un motor de **OCR con Google ML Kit** que escanea tickets de gasolinera y autocompleta el formulario automáticamente, gráficas interactivas por período y sincronización en la nube con **Supabase**.

---

## 🚀 Descripción del Proyecto

Kilómetros y Céntimos es una app pensada para conductores que quieren tener control real sobre el coste y el mantenimiento de su vehículo. Cada coche registrado tiene su propio historial de kilómetros, repostajes y taller, con estadísticas y gráficas que se filtran por semana, mes o año. La funcionalidad estrella es el **escáner de tickets**: el usuario fotografía el recibo de la gasolinera y el motor de OCR extrae automáticamente los litros, el precio por litro y la fecha, rellenando el formulario sin escribir nada.

- **Multi-vehículo:** Gestiona varios coches desde una misma cuenta, cada uno con su foto, modelo y año.
- **Escáner de tickets:** Google ML Kit procesa la imagen del ticket, identifica los valores numéricos por contexto y los clasifica con un nivel de confianza (Muy Alta / Alta / Media / Baja).
- **Backend en la nube:** Supabase gestiona la autenticación y almacena todos los datos de forma persistente, accesibles desde cualquier dispositivo.

---

## ✨ Funcionalidades Clave

✅ **Gestión Multi-coche:** Añade vehículos con nombre, modelo, año y foto. Cada tarjeta muestra un resumen de KM totales, número de repostajes y visitas al taller.  
✅ **Registro de Kilómetros:** Añade lecturas del odómetro con fecha y notas opcionales. Visualiza la evolución con gráficas por período (semana / mes / año).  
✅ **Gestión de Repostajes:** Introduce litros y precio por litro o precio total — la app calcula el campo restante automáticamente. Historial con precio medio, litros acumulados y número de repostajes.  
✅ **Escáner de Tickets con OCR:** Fotografía o selecciona de galería el ticket de la gasolinera. ML Kit extrae litros, precio por litro y fecha mediante análisis de contexto de texto. Un botón autocompleta el formulario con los datos detectados.  
✅ **Registro de Taller:** Anota visitas con descripción, coste, nombre del taller y fecha. Gráficas de gasto por período.  
✅ **Gráficas Interactivas:** Tres módulos de gráficas (combustible, kilómetros y taller) con `fl_chart`, filtrables por semana, mes o año.  
✅ **Autenticación con Supabase:** Login seguro y datos sincronizados en la nube por usuario.

---

## 📸 Galería

### 🚗 Pantalla Principal
Vista general de tus vehículos con resumen de kilómetros totales, repostajes y visitas al taller.
![Home](docs/screenshots/home.png)

### 🤖 Escáner de Tickets OCR
Fotografía el ticket de la gasolinera y la IA extrae litros, precio por litro y fecha automáticamente.
![OCR](docs/screenshots/ocr_ticket.png)

### 📊 Gráficas de Consumo
Evolución del gasto en combustible filtrable por semana, mes o año.
![Gráficas](docs/screenshots/charts.png)

---

## 🏗️ Arquitectura del Proyecto

```text
[ Flutter App ]
      │
      ├── pages/          → Pantallas de la app (UI)
      ├── widgets/        → Componentes reutilizables (gráficas, nav bar...)
      ├── services/       → Lógica de negocio y acceso a datos
      │     ├── supabase_service.dart   → Cliente Supabase compartido
      │     ├── auth_service.dart       → Autenticación
      │     ├── car_service.dart        → CRUD de vehículos
      │     ├── refuel_service.dart     → CRUD de repostajes
      │     ├── kilometer_service.dart  → CRUD de kilómetros
      │     ├── mechanic_service.dart   → CRUD de visitas al taller
      │     ├── ticket_mlkit_service.dart → OCR de tickets con ML Kit
      │     └── chart_service.dart      → Datos agregados para gráficas
      ├── models/         → Clases de datos (Refuel, KilometerRecord, MechanicVisit...)
      └── constants/      → Colores y constantes de la app
            └── app_colors.dart
      │
      └── [ Supabase ] ──► Auth + Base de datos en la nube
```

---

## 📂 Estructura del Proyecto

```text
├── lib/
│   ├── main.dart                        # Punto de entrada e inicialización de Supabase
│   ├── constants/
│   │   └── app_colors.dart              # Paleta de colores de la app
│   ├── models/                          # Modelos de datos
│   │   ├── refuel_model.dart
│   │   ├── kilometer_record_model.dart
│   │   ├── mechanic_visit_model.dart
│   │   └── *_chart_data_model.dart      # Modelos para gráficas
│   ├── pages/                           # Pantallas
│   │   ├── login_page.dart              # Autenticación
│   │   ├── main_wrapper.dart            # Contenedor principal con nav bar
│   │   ├── home_page.dart               # Lista de coches con estadísticas
│   │   ├── add_car_page.dart            # Añadir nuevo vehículo
│   │   ├── car_detail_page.dart         # Detalle de un coche
│   │   ├── refuel_page.dart             # Repostajes + OCR de ticket
│   │   ├── kilometers_page.dart         # Registro de kilómetros
│   │   ├── mechanic_page.dart           # Visitas al taller
│   │   └── select_car_page.dart         # Selector de coche activo
│   ├── services/                        # Lógica y acceso a datos
│   │   ├── supabase_service.dart
│   │   ├── auth_service.dart
│   │   ├── car_service.dart
│   │   ├── refuel_service.dart
│   │   ├── kilometer_service.dart
│   │   ├── mechanic_service.dart
│   │   ├── ticket_mlkit_service.dart    # 🤖 OCR con Google ML Kit
│   │   ├── chart_service.dart
│   │   ├── kilometer_chart_service.dart
│   │   └── mechanic_chart_service.dart
│   └── widgets/                         # Componentes reutilizables
│       ├── app_top_bar.dart
│       ├── bottom_nav_bar.dart
│       ├── fuel_chart_widget.dart
│       ├── kilometer_chart_widget.dart
│       └── mechanic_chart_widget.dart
├── assets/images/                       # Logo y recursos gráficos
├── android/ / ios/                      # Configuración nativa por plataforma
├── pubspec.yaml                         # Dependencias del proyecto
└── firebase.json
```

---

## 🤖 Cómo funciona el OCR de tickets

El servicio `TicketMLKitService` procesa la imagen en tres fases:

1. **Reconocimiento de texto:** ML Kit escanea la imagen y extrae todo el texto en bruto.
2. **Clasificación de números:** Cada número detectado se analiza junto a su contexto (líneas adyacentes) para determinar si es litros, precio por litro o un valor desconocido. El precio por litro se reconoce por tener 3 decimales o por palabras clave como `€/L`; los litros, por estar entre 5 y 150 con 2 decimales y junto a términos como `litros`, `diesel` o `gasolina`.
3. **Extracción de fecha:** Se aplican expresiones regulares sobre múltiples formatos (`DD/MM/AAAA`, `AAAA-MM-DD`, etc.) con validación de rangos.

El resultado incluye un nivel de confianza según cuántos de los tres campos (litros, precio/L, fecha) se han podido extraer.

---

## ⚙️ Instalación y Uso

### Requisitos

- Flutter SDK `>=3.9.0`
- Cuenta en [Supabase](https://supabase.com) con las tablas de la app creadas
- Android o iOS para las funcionalidades de cámara y ML Kit

### Pasos

```bash
git clone https://github.com/tu-usuario/KilometrosYCentimos.git
cd KilometrosYCentimos
flutter pub get
flutter run
```

Las credenciales de Supabase (`url` y `anonKey`) están configuradas en `lib/main.dart`.

### Dependencias principales

```yaml
supabase_flutter: ^2.10.3       # Auth y base de datos en la nube
fl_chart: ^0.66.2               # Gráficas interactivas
google_mlkit_text_recognition: ^0.15.0  # OCR de tickets
image_picker: ^1.1.2            # Cámara y galería
http: ^1.5.0
uuid: ^4.2.1
```

---

## 📓 Notas de Desarrollo

El punto técnico más interesante del proyecto es el motor de OCR. En lugar de buscar patrones fijos en el texto del ticket (que varía enormemente entre gasolineras), el servicio analiza cada número junto a su contexto de ±2 líneas para inferir su tipo. Esto lo hace más robusto frente a la variabilidad real de los tickets. La arquitectura de servicios independientes (un servicio por entidad) facilita la escalabilidad y el testeo de cada módulo por separado.

**build:** versión 1.0.0
