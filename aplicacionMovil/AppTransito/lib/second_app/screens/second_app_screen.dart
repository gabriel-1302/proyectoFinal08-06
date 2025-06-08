import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

class SecondAppScreen extends StatefulWidget {
  const SecondAppScreen({super.key});

  @override
  State<SecondAppScreen> createState() => _SecondAppScreenState();
}

class _SecondAppScreenState extends State<SecondAppScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  int _notificationId = 0;
  final String apiBaseUrl = 'http://192.168.1.9:8001';
  String get apiUrl => '$apiBaseUrl/api/infractions/';
  int lastProcessedId = 0;
  Timer? _timer;
  List<ApiMessage> mensajes = [];

  @override
  void initState() {
    super.initState();
    init();
    startApiPolling();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/La_Paz'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  void startApiPolling() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchMessages();
    });
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      print('Fetching messages from: $apiUrl');
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('API response: $data');
        
        final List<ApiMessage> newMessages = data
            .map((item) => ApiMessage.fromJson(item, apiBaseUrl))
            .toList();
        
        for (var message in newMessages) {
          print('Processing message ID: ${message.id}, Image: ${message.image}');
          if (message.id > lastProcessedId) {
            lastProcessedId = message.id;
            mostrarNotificacionDesdeApi(message);
            setState(() {
              mensajes.add(message);
            });
          }
        }
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al cargar datos: $e');
    }
  }

  Future<void> enviarMensajePrueba() async {
    final mensaje = {
      'mensaje': 'Mensaje de prueba ${DateTime.now()}',
    };
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mensaje),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Mensaje enviado correctamente');
        fetchMessages();
      } else {
        print('Error al enviar mensaje: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al enviar mensaje: $e');
    }
  }

  Future<void> mostrarNotificacionDesdeApi(ApiMessage message) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'api_canal',
      'Notificaciones de API',
      channelDescription: 'Canal para las notificaciones desde la API',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      when: message.timestamp.millisecondsSinceEpoch,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    setState(() {
      _notificationId++;
    });
    
    final String formattedTime = 
        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    
    await flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Notificación #${message.id}',
      '${message.mensaje}\n[$formattedTime]',
      notificationDetails,
    );
  }

  Future<void> mostrarNotificacionManual() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_manual',
      'Notificaciones Manuales',
      channelDescription: 'Canal para las notificaciones manuales',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    setState(() {
      _notificationId++;
    });
    
    await flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Notificación Manual #$_notificationId',
      'Esta es una notificación manual creada desde la app',
      notificationDetails,
    );
  }

  void showImageModal(BuildContext context, String? imageUrl) {
    final String displayUrl = imageUrl ?? 'https://via.placeholder.com/640x480';
    print('Opening modal with image: $displayUrl');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  displayUrl,
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading modal image: $error, StackTrace: $stackTrace');
                    return const Text('Error al cargar la imagen');
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Notificaciones desde API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Notificaciones de la API',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: enviarMensajePrueba,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Enviar mensaje de prueba a la API',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: mostrarNotificacionManual,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Crear notificación manual',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchMessages,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Verificar API ahora',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total de notificaciones: $_notificationId',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Mensajes recibidos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: mensajes.isEmpty
                  ? const Center(child: Text('No hay mensajes recibidos todavía'))
                  : ListView.builder(
                      itemCount: mensajes.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = mensajes.length - 1 - index;
                        final mensaje = mensajes[reversedIndex];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => showImageModal(context, mensaje.image),
                              child: mensaje.image != null
                                  ? Image.network(
                                      mensaje.image!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      cacheWidth: 160,
                                      cacheHeight: 160,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const CircularProgressIndicator();
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading thumbnail: $error, StackTrace: $stackTrace');
                                        return const Icon(Icons.broken_image, size: 80);
                                      },
                                    )
                                  : const Icon(Icons.image_not_supported, size: 80),
                            ),
                            title: Text('ID: ${mensaje.id}'),
                            subtitle: Text(mensaje.mensaje),
                            trailing: Text(
                              '${mensaje.timestamp.hour}:${mensaje.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiMessage {
  final int id;
  final String mensaje;
  final DateTime timestamp;
  final String? image;
  
  ApiMessage({
    required this.id,
    required this.mensaje,
    required this.timestamp,
    this.image,
  });
  
  factory ApiMessage.fromJson(Map<String, dynamic> json, String apiBaseUrl) {
    String? imageUrl;
    if (json['image'] != null) {
      String imagePath = json['image'];
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageUrl = imagePath;
      } else {
        imageUrl = '$apiBaseUrl$imagePath';
      }
      print('Constructed image URL: $imageUrl');
    } else {
      print('No image in JSON: $json');
    }
    
    return ApiMessage(
      id: json['id'],
      mensaje: json['mensaje'],
      timestamp: DateTime.parse(json['timestamp']),
      image: imageUrl,
    );
  }
}