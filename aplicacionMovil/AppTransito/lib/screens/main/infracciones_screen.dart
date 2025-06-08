import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class InfraccionesScreen extends StatefulWidget {
  final String token;

  const InfraccionesScreen({super.key, required this.token});

  @override
  State<InfraccionesScreen> createState() => _InfraccionesScreenState();
}

class _InfraccionesScreenState extends State<InfraccionesScreen> {
  List<dynamic> infracciones = [];
  bool isLoading = true;
  String errorMessage = '';
  DateTime? selectedDate;
  String? selectedPagado;
  final TextEditingController _placaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInfracciones();
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> fetchInfracciones({String? fecha, String? pagado, String? placa}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      var url = Uri.parse('http://192.168.1.9:8080/api/infracciones/');
      if (fecha != null || pagado != null || placa != null) {
        final queryParams = <String, String>{};
        if (fecha != null) queryParams['fecha'] = fecha;
        if (pagado != null) queryParams['pagado'] = pagado;
        if (placa != null && placa.isNotEmpty) queryParams['placa'] = placa;
        url = Uri.http(url.authority, url.path, queryParams);
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          infracciones = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar infracciones: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar infracciones: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateInfraccionPagado(int infraccionId, bool pagado) async {
    try {
      final requestBody = {
        'id': infraccionId,
        'pagado': pagado,
      };
      
      print('Enviando PATCH request:');
      print('URL: http://192.168.1.9:8080/api/infracciones/');
      print('Body: ${json.encode(requestBody)}');
      
      final response = await http.patch(
        Uri.parse('http://192.168.1.9:8080/api/infracciones/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Actualizar la lista local
        setState(() {
          final index = infracciones.indexWhere((inf) => inf['id'] == infraccionId);
          if (index != -1) {
            infracciones[index]['pagado'] = pagado;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${pagado ? 'Pagado' : 'No Pagado'}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    fetchInfracciones(
      fecha: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
      pagado: selectedPagado,
      placa: _placaController.text.trim().isNotEmpty ? _placaController.text.trim() : null,
    );
  }

  void _clearFilters() {
    setState(() {
      selectedDate = null;
      selectedPagado = null;
      _placaController.clear();
    });
    fetchInfracciones();
  }

  void _showEditDialog(Map<String, dynamic> infraccion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Infracción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${infraccion['placa']}', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(infraccion['fecha_hora']))}'),
              SizedBox(height: 16),
              Text('Estado actual: ${infraccion['pagado'] ? 'Pagado' : 'No Pagado'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            if (!infraccion['pagado'])
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  updateInfraccionPagado(infraccion['id'], true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Marcar como Pagado'),
              ),
            if (infraccion['pagado'])
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  updateInfraccionPagado(infraccion['id'], false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Marcar como No Pagado'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    // Campo de filtro por placa
                    TextField(
                      controller: _placaController,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por placa',
                        prefixIcon: const Icon(Icons.drive_eta, color: Colors.green),
                        filled: true,
                        fillColor: Colors.green.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Ingresa placa (ej: ABC123)',
                        suffixIcon: _placaController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _placaController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        // Aplicar filtro automáticamente después de 500ms de pausa
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_placaController.text == value) {
                            _applyFilters();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Fecha',
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                              filled: true,
                              fillColor: Colors.green.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              hintText: selectedDate == null
                                  ? 'Selecciona una fecha'
                                  : DateFormat('dd/MM/yyyy').format(selectedDate!),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPagado,
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              prefixIcon: const Icon(Icons.check_circle, color: Colors.green),
                              filled: true,
                              fillColor: Colors.green.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Todos')),
                              DropdownMenuItem(value: 'true', child: Text('Pagado')),
                              DropdownMenuItem(value: 'false', child: Text('No Pagado')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedPagado = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Limpiar Filtros', style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => fetchInfracciones(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : infracciones.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No hay infracciones registradas',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => fetchInfracciones(
                              fecha: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
                              pagado: selectedPagado,
                              placa: _placaController.text.trim().isNotEmpty ? _placaController.text.trim() : null,
                            ),
                            color: Colors.green,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: infracciones.length,
                              itemBuilder: (context, index) {
                                final infraccion = infracciones[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: infraccion['pagado'] 
                                          ? Colors.green.shade100 
                                          : Colors.red.shade100,
                                      child: Icon(
                                        infraccion['pagado'] ? Icons.check_circle : Icons.warning,
                                        color: infraccion['pagado'] ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      'Placa: ${infraccion['placa']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(infraccion['fecha_hora']))}'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: infraccion['pagado'] ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            infraccion['pagado'] ? 'Pagado' : 'No Pagado',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        Text('Coordenadas: ${infraccion['latitud']}, ${infraccion['longitud']}'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditDialog(infraccion),
                                    ),
                                    onTap: () => _showEditDialog(infraccion),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}