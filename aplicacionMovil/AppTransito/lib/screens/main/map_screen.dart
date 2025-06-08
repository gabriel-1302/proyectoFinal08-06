import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  final String role;
  final String token;

  const MapScreen({
    super.key,
    required this.role,
    required this.token,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  String? _errorMessage;
  LocationData? _currentLocation;
  final Location _location = Location();
  final TextEditingController _placaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _infraccionesTimer;

  final String restrictionsApiUrl = 'http://192.168.1.9:8000/api/zonas-restringidas/';
  final String infraccionesApiUrl = 'http://192.168.1.9:8080/api/infracciones/';
  String _displayMode = 'both';

  @override
  void initState() {
    super.initState();
    _loadRestrictions();
    _loadRestrictedZone();
    _getCurrentLocation();
    if (widget.role == 'policia') {
      _fetchInfracciones();
      _infraccionesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _fetchInfracciones();
      });
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _infraccionesTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInfracciones() async {
    if (widget.role != 'policia') return;

    try {
      final response = await http.get(
        Uri.parse('$infraccionesApiUrl?pagado=false'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value.startsWith('infraccion_'));
          for (var infraccion in data) {
            if (infraccion['latitud'] != null && infraccion['longitud'] != null) {
              _markers.add(
                Marker(
                  markerId: MarkerId('infraccion_${infraccion['id']}'),
                  position: LatLng(infraccion['latitud'], infraccion['longitud']),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: 'Infracción: ${infraccion['placa']}',
                    snippet: 'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(infraccion['fecha_hora']))}',
                  ),
                ),
              );
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar infracciones: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar infracciones: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _errorMessage = 'El servicio de ubicación está deshabilitado.';
          });
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _errorMessage = 'Permiso de ubicación denegado.';
          });
          return;
        }
      }

      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = locationData;
      });

      if (_controller != null && locationData.latitude != null && locationData.longitude != null) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(locationData.latitude!, locationData.longitude!),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ubicación: $e';
      });
    }
  }

  Future<void> _loadRestrictions() async {
    try {
      final response = await http.get(Uri.parse(restrictionsApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          setState(() {
            _errorMessage = 'No se encontraron restricciones.';
          });
          return;
        }

        setState(() {
          _polylines.clear();
          for (var item in data) {
            if (item['coordenada1_lat'] != null &&
                item['coordenada1_lon'] != null &&
                item['coordenada2_lat'] != null &&
                item['coordenada2_lon'] != null) {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('restriction_${item['id']}'),
                  points: [
                    LatLng(item['coordenada1_lat'], item['coordenada1_lon']),
                    LatLng(item['coordenada2_lat'], item['coordenada2_lon']),
                  ],
                  color: Colors.red,
                  width: 6,
                ),
              );
            }
          }
          _errorMessage = _polylines.isEmpty
              ? 'No se pudieron cargar restricciones válidas.'
              : null;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar restricciones: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  void _loadRestrictedZone() {
    final List<LatLng> polygonPoints = [
      LatLng(-19.043649, -65.259926),
      LatLng(-19.048225, -65.263821),
      LatLng(-19.052142742264422, -65.259280231523),
      LatLng(-19.04746079069352, -65.25523259852747),
    ];

    setState(() {
      _polygons.clear();
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('restricted_zone'),
          points: polygonPoints,
          fillColor: Colors.yellow.withOpacity(0.3),
          strokeColor: Colors.yellow,
          strokeWidth: 2,
        ),
      );
    });
  }

  void _toggleDisplayMode() {
    setState(() {
      if (_displayMode == 'both') {
        _displayMode = 'restrictions';
      } else if (_displayMode == 'restrictions') {
        _displayMode = 'zone';
      } else {
        _displayMode = 'both';
      }
    });
  }

  IconData _getModeIcon() {
    switch (_displayMode) {
      case 'restrictions':
        return Icons.directions;
      case 'zone':
        return Icons.crop_square;
      default:
        return Icons.layers;
    }
  }

  Set<Polyline> _getVisiblePolylines() {
    return _displayMode == 'restrictions' || _displayMode == 'both' ? _polylines : {};
  }

  Set<Polygon> _getVisiblePolygons() {
    return _displayMode == 'zone' || _displayMode == 'both' ? _polygons : {};
  }

  Future<void> _registrarInfraccion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo obtener la ubicación actual.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(infraccionesApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'placa': _placaController.text,
          'latitud': _currentLocation!.latitude,
          'longitud': _currentLocation!.longitude,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Infracción registrada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
        _placaController.clear();
        if (widget.role == 'policia') {
          _fetchInfracciones();
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar infracción: ${error['error'] ?? response.body}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar infracción: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showInfraccionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final now = DateTime.now();
        final formatter = DateFormat('MM/dd/yyyy hh:mm:ss a');
        final fechaHora = formatter.format(now);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Infracción',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _placaController,
                  decoration: InputDecoration(
                    labelText: 'Placa',
                    prefixIcon: const Icon(Icons.confirmation_number, color: Colors.green),
                    filled: true,
                    fillColor: Colors.green.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Por favor ingresa la placa' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _currentLocation != null
                      ? '${_currentLocation!.latitude}, ${_currentLocation!.longitude}'
                      : 'No disponible',
                  decoration: InputDecoration(
                    labelText: 'Coordenadas',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                    filled: true,
                    fillColor: Colors.green.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: fechaHora,
                  decoration: InputDecoration(
                    labelText: 'Fecha y Hora',
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                    filled: true,
                    fillColor: Colors.green.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registrarInfraccion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Registrar Infracción',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-19.048, -65.260),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              if (_currentLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      zoom: 15,
                    ),
                  ),
                );
              }
            },
            polygons: _getVisiblePolygons(),
            polylines: _getVisiblePolylines(),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 50,
            left: 10,
            child: FloatingActionButton(
              onPressed: _toggleDisplayMode,
              backgroundColor: Colors.white,
              child: Icon(
                _getModeIcon(),
                color: Colors.black,
              ),
            ),
          ),
          if (widget.role == 'policia')
            Positioned(
              bottom: 80,
              left: 10,
              child: FloatingActionButton(
                onPressed: _showInfraccionModal,
                backgroundColor: Colors.green,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                color: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.all(8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}