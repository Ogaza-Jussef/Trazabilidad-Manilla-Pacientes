import 'package:flutter/material.dart';

import 'datos/ajustes_puesto.dart';
import 'presentacion/pantalla_escaner.dart';
import 'presentacion/pantalla_login.dart';
import 'presentacion/widgets_sis/widgets_sis.dart';
import 'tema/tema_sis.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrazabilidadApp());
}

class TrazabilidadApp extends StatelessWidget {
  const TrazabilidadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trazabilidad de manillas',
      theme: TemaSis.claro,
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
      return const FondoSis(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: SpinnerSis(tamano: 42)),
        ),
      );
    }
    final ajustes = _ajustes;
    if (ajustes == null) {
      return PantallaLogin(
        almacen: _almacen,
        alGuardar: (nuevos) => setState(() => _ajustes = nuevos),
      );
    }
    return PantallaEscaner(
      ajustes: ajustes,
      alGuardar: (nuevos) async {
        await _almacen.guardar(nuevos);
        if (mounted) setState(() => _ajustes = nuevos);
      },
      alSalir: () async {
        await _almacen.borrar();
        if (mounted) setState(() => _ajustes = null);
      },
    );
  }
}
