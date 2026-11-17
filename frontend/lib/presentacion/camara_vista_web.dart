import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget construirCamara(void Function(String valor) alDetectar) {
  return _CamaraWeb(alDetectar: alDetectar);
}

class _CamaraWeb extends StatefulWidget {
  const _CamaraWeb({required this.alDetectar});

  final void Function(String valor) alDetectar;

  @override
  State<_CamaraWeb> createState() => _CamaraWebState();
}

class _CamaraWebState extends State<_CamaraWeb> {
  static var _consecutivo = 0;

  late final String _vista = 'camara-manilla-${_consecutivo++}';
  final _video = web.HTMLVideoElement();
  final _lienzo = web.HTMLCanvasElement();
  Timer? _reloj;
  JSObject? _detector;
  var _leyendo = false;
  var _abierta = false;
  String? _fallo;

  @override
  void initState() {
    super.initState();
    _video
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    ui_web.platformViewRegistry.registerViewFactory(_vista, (int id) {
      final caja = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#0A2342';
      caja.append(_video);
      return caja;
    });
    _abrir();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    final proveedor = _video.srcObject;
    if (proveedor != null) {
      final flujo = proveedor as web.MediaStream;
      for (final pista in flujo.getTracks().toDart) {
        pista.stop();
      }
    }
    super.dispose();
  }

  Future<void> _abrir() async {
    try {
      if (!globalContext.has('BarcodeDetector')) {
        throw StateError('sin lector');
      }
      final opciones = JSObject();
      opciones.setProperty('formats'.toJS, <JSString>['qr_code'.toJS].toJS);
      _detector = globalContext.getProperty<JSFunction>('BarcodeDetector'.toJS).callAsConstructor<JSObject>(opciones);

      final pedido = web.MediaStreamConstraints(
        video: web.MediaTrackConstraintSet(
          facingMode: 'environment'.toJS,
          width: web.ConstrainULongRange(ideal: 1920),
          height: web.ConstrainULongRange(ideal: 1080),
        ).toJSBox,
      );
      web.MediaStream flujo;
      try {
        flujo = await web.window.navigator.mediaDevices.getUserMedia(pedido).toDart;
      } catch (_) {
        flujo = await web.window.navigator.mediaDevices
            .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
            .toDart;
      }
      _video.srcObject = flujo;
      await _video.play().toDart;
      if (!mounted) return;
      _abierta = true;
      _reloj = Timer.periodic(const Duration(milliseconds: 280), (_) => _leerCentro());
      setState(() => _fallo = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _fallo = 'No se pudo abrir la cámara. Escribe el número de caso.');
    }
  }

  Future<void> _leerCentro() async {
    final detector = _detector;
    if (!_abierta || _leyendo || detector == null) return;
    final ancho = _video.videoWidth;
    final alto = _video.videoHeight;
    if (ancho == 0 || alto == 0) return;
    _leyendo = true;
    try {
      final ladoFuente = (ancho < alto ? ancho : alto) * 0.34;
      final origenX = ((ancho - ladoFuente) / 2).round();
      final origenY = ((alto - ladoFuente) / 2).round();
      const destino = 900;
      _lienzo.width = destino;
      _lienzo.height = destino;
      final contexto = _lienzo.getContext('2d') as web.CanvasRenderingContext2D?;
      if (contexto == null) return;
      contexto.imageSmoothingEnabled = false;
      contexto.drawImage(
        _video,
        origenX,
        origenY,
        ladoFuente.round(),
        ladoFuente.round(),
        0,
        0,
        destino,
        destino,
      );
      final encontrados = await detector.callMethod<JSPromise<JSArray<JSObject>>>('detect'.toJS, _lienzo).toDart;
      for (final item in encontrados.toDart) {
        final texto = item.getProperty<JSString?>('rawValue'.toJS)?.toDart ?? '';
        if (texto.isNotEmpty) widget.alDetectar(texto);
      }
    } catch (_) {
      // Un cuadro borroso no es un fallo de la manilla.
    } finally {
      _leyendo = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallo = _fallo;
    if (fallo != null) {
      return ColoredBox(
        color: const Color(0xFF0A2342),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(fallo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    return HtmlElementView(viewType: _vista);
  }
}

extension on JSObject {
  /// El pedido de la cámara es un objeto y getUserMedia lo recibe como JSAny.
  JSAny get toJSBox => this;
}
