import 'package:flutter/material.dart';

import 'datos/ajustes_puesto.dart';
import 'presentacion/pantalla_escaner.dart';
import 'presentacion/pantalla_puesto.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrazabilidadApp());
}

class TrazabilidadApp extends StatelessWidget {
  const TrazabilidadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F));
    return MaterialApp(
      title: 'Trazabilidad de manillas',
      theme: ThemeData(
        colorScheme: esquema,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _almacen = AlmacenAjustes();
  AjustesPuesto? _ajustes;
  var _listo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ajustes = await _almacen.leer();
    if (!mounted) return;
    setState(() {
      _ajustes = ajustes;
      _listo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_listo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ajustes = _ajustes;
    if (ajustes == null) {
      return PantallaPuesto(
        almacen: _almacen,
        alGuardar: (nuevos) => setState(() => _ajustes = nuevos),
      );
    }
    return PantallaEscaner(
      ajustes: ajustes,
      almacen: _almacen,
      alGuardar: (nuevos) => setState(() => _ajustes = nuevos),
    );
  }
}
