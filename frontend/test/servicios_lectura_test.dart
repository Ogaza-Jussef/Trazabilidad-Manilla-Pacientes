import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trazabilidad_manillas/dominio/servicios_lectura.dart';

void main() {
  test('el servicio elegido queda una sola vez en el desplegable', () {
    expect(
      opcionesServicio('Admision', ['Admision', 'Admision', 'Cirugia']),
      ['Admision', 'Cirugia'],
    );
  });

  test('conserva el servicio del puesto si la lista de la empresa no lo trae', () {
    expect(
      opcionesServicio('Admision', ['Colocación de manilla']),
      ['Admision', 'Colocación de manilla'],
    );
  });

  testWidgets('el desplegable muestra Admision sin cortar la pantalla', (tester) async {
    final opciones = opcionesServicio('Admision', const ['Admision', 'Cirugia']);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: opciones.contains('Admision') ? 'Admision' : null,
            items: [
              for (final servicio in opciones) DropdownMenuItem(value: servicio, child: Text(servicio)),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Admision'), findsOneWidget);
  });
}
