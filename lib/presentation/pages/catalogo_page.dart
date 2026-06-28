// lib/presentation/pages/catalogo_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/producto_viewmodel.dart';
import '../viewmodels/producto_state.dart';
import '../widgets/nav_drawer.dart';
import 'registrar_producto_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<ProductoViewModel>().cargarProductos());
  }

  Future<void> _eliminar(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Deseas eliminar "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.productosEndpoint}/$id'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Producto eliminado'),
          backgroundColor: Colors.green,
        ));
        context.read<ProductoViewModel>().cargarProductos();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al eliminar'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _editar(Map<String, dynamic> producto) async {
    final nombreCtrl = TextEditingController(text: producto['nombre']);
    final catCtrl    = TextEditingController(text: producto['categoria']);
    final precioCtrl = TextEditingController(text: producto['precio'].toString());
    final stockCtrl  = TextEditingController(text: producto['stock'].toString());
    final descCtrl   = TextEditingController(text: producto['descripcion'] ?? '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Categoría')),
              TextField(controller: precioCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio')),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock')),
              TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar')),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.productosEndpoint}/${producto['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre':      nombreCtrl.text.trim(),
          'categoria':   catCtrl.text.trim(),
          'precio':      double.tryParse(precioCtrl.text.trim()) ?? 0,
          'stock':       int.tryParse(stockCtrl.text.trim()) ?? 0,
          'descripcion': descCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Producto actualizado'),
          backgroundColor: Colors.green,
        ));
        context.read<ProductoViewModel>().cargarProductos();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al actualizar'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductoViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: const NavDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegistrarProductoPage()));
          if (result == true && mounted) {
            context.read<ProductoViewModel>().cargarProductos();
          }
        },
      ),
      body: switch (vm.state.status) {
        ProductoStatus.loading => const Center(child: CircularProgressIndicator()),
        ProductoStatus.error   => Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(vm.state.errorMessage),
          ],
        )),
        ProductoStatus.success when vm.state.productos.isEmpty =>
          const Center(child: Text('No hay productos disponibles.')),
        ProductoStatus.success => ListView.separated(
          padding:          const EdgeInsets.all(12),
          itemCount:        vm.state.productos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) {
            final p = vm.state.productos[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Text(p.nombre[0],
                    style: const TextStyle(color: Colors.white)),
                ),
                title: Text(p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p.categoria}  │  S/ ${p.precio.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      onPressed: () => _editar({
                        'id':          p.id,
                        'nombre':      p.nombre,
                        'categoria':   p.categoria,
                        'precio':      p.precio,
                        'stock':       p.stock,
                        'descripcion': p.descripcion,
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminar(p.id, p.nombre),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        _ => const Center(child: Text('Cargando...')),
      },
    );
  }
}