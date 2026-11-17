import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Widget construirCamara(void Function(String valor) alDetectar) {
  return _CamaraNativa(alDetectar: alDetectar);
}

class _CamaraNativa extends StatefulWidget {
  const _CamaraNativa({required this.alDetectar});

  final void Function(String valor) alDetectar;

  @override
  State<_CamaraNativa> createState() => _CamaraNativaState();
}

class _CamaraNativaState extends State<_CamaraNativa> {
  final _camara = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );
  var _yaAcercado = false;

  @override
  void initState() {
    super.initState();
    _camara.addListener(_acercar);
  }

  @override
  void dispose() {
    _camara.removeListener(_acercar);
    _camara.dispose();
    super.dispose();
  }

  void _acercar() {
    if (_yaAcercado || !_camara.value.isRunning) return;
    _yaAcercado = true;
    _camara.setZoomScale(0.55);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cuadro = constraints.maxHeight * 0.34;
        final ventana = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: cuadro,
          height: cuadro,
        );
        return MobileScanner(
          controller: _camara,
          fit: BoxFit.cover,
          scanWindow: ventana,
          onDetect: (captura) {
            for (final codigo in captura.barcodes) {
              final valor = codigo.rawValue;
              if (valor != null && valor.isNotEmpty) widget.alDetectar(valor);
            }
          },
        );
      },
    );
  }
}
