import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehiclesScreen extends StatefulWidget {
  final String token;
  final String role;
  final int userProfileId;

  const VehiclesScreen({
    super.key,
    required this.token,
    required this.role,
    required this.userProfileId,
  });

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> vehicles = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController placaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool isEditing = false;
  int? editingVehicleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('Token recibido en VehiclesScreen: ${widget.token}');
    fetchVehicles();
  }

  @override
  void dispose() {
    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    placaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.9:8080/api/vehicles/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print('Estado de la respuesta /vehicles/: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          vehicles = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar vehículos: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error en fetchVehicles: $e');
      setState(() {
        errorMessage = 'Error al cargar vehículos: $e';
        isLoading = false;
      });
    }
  }

  Future<void> saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'marca': marcaController.text,
        'modelo': modeloController.text,
        'color': colorController.text,
        'placa': placaController.text,
      };
      final url =
          isEditing
              ? Uri.parse(
                'http://192.168.1.9:8080/api/vehicles/$editingVehicleId/',
              )
              : Uri.parse('http://192.168.1.9:8080/api/vehicles/');
      final method = isEditing ? http.put : http.post;

      final response = await method(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(data),
      );

      print(
        'Estado de la respuesta ${isEditing ? 'PUT' : 'POST'} /vehicles/: ${response.statusCode}',
      );
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == (isEditing ? 200 : 201)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Vehículo actualizado exitosamente'
                  : 'Vehículo guardado exitosamente',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        marcaController.clear();
        modeloController.clear();
        colorController.clear();
        placaController.clear();
        setState(() {
          isEditing = false;
          editingVehicleId = null;
        });
        await fetchVehicles();
        _tabController.animateTo(0);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${isEditing ? 'actualizar' : 'guardar'} vehículo: ${error['error'] ?? response.body}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error en ${isEditing ? 'updateVehicle' : 'saveVehicle'}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al ${isEditing ? 'actualizar' : 'guardar'} vehículo: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.9:8080/api/vehicles/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print(
        'Estado de la respuesta DELETE /vehicles/$id/: ${response.statusCode}',
      );
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehículo eliminado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await fetchVehicles();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar vehículo: ${error['error'] ?? response.body}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error en deleteVehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar vehículo: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void editVehicle(Map<String, dynamic> vehicle) {
    marcaController.text = vehicle['marca'];
    modeloController.text = vehicle['modelo'];
    colorController.text = vehicle['color'];
    placaController.text = vehicle['placa'];
    setState(() {
      isEditing = true;
      editingVehicleId = vehicle['id'];
    });
    _tabController.animateTo(1); // Ir a la pestaña de formulario
  }

  void showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este vehículo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteVehicle(id);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Vehículos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Lista'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Añadir'),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchVehicles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña 1: Lista de Vehículos
                  vehicles.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay vehículos registrados',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: fetchVehicles,
                        color: Colors.blue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  '${vehicle['marca']} ${vehicle['modelo']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Placa: ${vehicle['placa']} | Color: ${vehicle['color']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => editVehicle(vehicle),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => showDeleteConfirmation(
                                            vehicle['id'],
                                          ),
                                    ),
                                  ],
                                ),
                                onTap: () => editVehicle(vehicle),
                              ),
                            );
                          },
                        ),
                      ),

                  // Pestaña 2: Añadir/Editar Vehículo
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Editar Vehículo'
                                    : 'Agregar Nuevo Vehículo',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: marcaController,
                                decoration: InputDecoration(
                                  labelText: 'Marca',
                                  prefixIcon: const Icon(
                                    Icons.branding_watermark,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Por favor ingresa la marca'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: modeloController,
                                decoration: InputDecoration(
                                  labelText: 'Modelo',
                                  prefixIcon: const Icon(
                                    Icons.directions_car,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Por favor ingresa el modelo'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: colorController,
                                decoration: InputDecoration(
                                  labelText: 'Color',
                                  prefixIcon: const Icon(
                                    Icons.color_lens,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Por favor ingresa el color'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: placaController,
                                decoration: InputDecoration(
                                  labelText: 'Placa',
                                  prefixIcon: const Icon(
                                    Icons.confirmation_number,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Por favor ingresa la placa'
                                            : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: saveVehicle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade900,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: Text(
                                    isEditing
                                        ? 'Actualizar Vehículo'
                                        : 'Guardar Vehículo',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (isEditing) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () {
                                      marcaController.clear();
                                      modeloController.clear();
                                      colorController.clear();
                                      placaController.clear();
                                      setState(() {
                                        isEditing = false;
                                        editingVehicleId = null;
                                      });
                                    },
                                    child: const Text(
                                      'Cancelar Edición',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
