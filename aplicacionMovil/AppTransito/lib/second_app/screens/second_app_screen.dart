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
  final String apiBaseUrl = 'http://192.168.1.3:8001';
  String get apiUrl => '$apiBaseUrl/api/infractions/';
  int lastProcessedId = 0;
  Timer? _timer;
  List<ApiMessage> mensajes = [];
  bool isLoading = false;

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
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
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('Fetching messages from: $apiUrl');
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('API response: $data');

        final List<ApiMessage> newMessages =
            data.map((item) => ApiMessage.fromJson(item, apiBaseUrl)).toList();

        for (var message in newMessages) {
          print(
            'Processing message ID: ${message.id}, Image: ${message.image}',
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Excepción al cargar datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> mostrarNotificacionDesdeApi(ApiMessage message) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

  void showImageModal(BuildContext context, String? imageUrl) {
    final String displayUrl = imageUrl ?? 'https://via.placeholder.com/640x480';
    print('Opening modal with image: $displayUrl');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Imagen de la infracción',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      displayUrl,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: MediaQuery.of(context).size.width * 0.8,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print(
                          'Error loading modal image: $error, StackTrace: $stackTrace',
                        );
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Error al cargar la imagen'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Monitor de Infracciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_notificationId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con botón de refresh
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : fetchMessages,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                          : const Icon(Icons.refresh),
                  label: Text(isLoading ? 'Verificando...' : 'Verificar API'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Última actualización: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Infracciones Recientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mensajes.length} total',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child:
                        mensajes.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay infracciones registradas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Los nuevas infracciones aparecerán aquí',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              itemCount: mensajes.length,
                              separatorBuilder:
                                  (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final reversedIndex =
                                    mensajes.length - 1 - index;
                                final mensaje = mensajes[reversedIndex];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap:
                                        mensaje.image != null
                                            ? () => showImageModal(
                                              context,
                                              mensaje.image,
                                            )
                                            : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Imagen/Icono
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.grey[200],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  mensaje.image != null
                                                      ? Image.network(
                                                        mensaje.image!,
                                                        fit: BoxFit.cover,
                                                        cacheWidth: 120,
                                                        cacheHeight: 120,
                                                        loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          );
                                                        },
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                            size: 30,
                                                          );
                                                        },
                                                      )
                                                      : const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                        size: 30,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Contenido
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'ID: ${mensaje.id}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.red[700],
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${mensaje.timestamp.hour}:${mensaje.timestamp.minute.toString().padLeft(2, '0')}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  mensaje.mensaje,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Indicador de imagen
                                          if (mensaje.image != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.touch_app,
                                                color: Colors.blue[600],
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
