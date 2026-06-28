// lib/presentation/pages/registrar_producto_page.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrarProductoPage extends StatefulWidget {
  const RegistrarProductoPage({super.key});

  @override
  State<RegistrarProductoPage> createState() => _RegistrarProductoPageState();
}

class _RegistrarProductoPageState extends State<RegistrarProductoPage> {
  final _formKey    = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _catCtrl    = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  bool _loading     = false;

  @override
  void dispose() {
    _codigoCtrl.dispose(); _nombreCtrl.dispose(); _catCtrl.dispose();
    _precioCtrl.dispose(); _stockCtrl.dispose();  _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConstants.productosEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo':      _codigoCtrl.text.trim(),
          'nombre':      _nombreCtrl.text.trim(),
          'categoria':   _catCtrl.text.trim(),
          'precio':      double.parse(_precioCtrl.text.trim()),
          'stock':       int.tryParse(_stockCtrl.text.trim()) ?? 0,
          'descripcion': _descCtrl.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Producto registrado exitosamente'),
          backgroundColor: Colors.green.shade700,
        ));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al registrar'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Error de conexión con el servidor'),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Producto'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código *',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(labelText: 'Categoría *',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio *',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (double.tryParse(v.trim()) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.warehouse)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _registrar,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_loading ? 'Guardando...' : 'Registrar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}