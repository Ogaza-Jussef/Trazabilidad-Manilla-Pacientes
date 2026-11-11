import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ColoresSis {
  const ColoresSis._();

  static const navy = Color(0xFF0A2342);
  static const tinta = Color(0xFF1B2D4B);
  static const suave = Color(0xFF5D6F88);
  static const mudo = Color(0xFF8696AD);
  static const linea = Color(0xFFD5DFED);
  static const linea2 = Color(0xFFE4EBF6);
  static const verde = Color(0xFF1E8E3E);
  static const verdeOscuro = Color(0xFF00751F);
  static const verdeClaro = Color(0xFF58C52E);
  static const azul = Color(0xFF2468C8);
  static const foco = Color(0xFF2F7DF0);
  static const fondo = Color(0xFFEEF3FB);

  static const procesandoFondo = Color(0xFFDCEFFE);
  static const procesandoBorde = Color(0xFFBCDCF8);
  static const exitoFondo = Color(0xFFD8F5DF);
  static const exitoBorde = Color(0xFFB6E5C2);
  static const exitoTexto = Color(0xFF0B6A26);
  static const avisoFondo = Color(0xFFFEEFC8);
  static const avisoBorde = Color(0xFFF6D98D);
  static const avisoTexto = Color(0xFF9A5B05);
  static const errorFondo = Color(0xFFF9DFEA);
  static const errorBorde = Color(0xFFF2B8CC);
  static const errorTexto = Color(0xFFB3202E);

  static const puntoOk = Color(0xFF2FAE3F);
  static const puntoAviso = Color(0xFFF0A30A);
  static const puntoError = Color(0xFFE0434D);
  static const puntoVacio = Color(0xFFC3CEDD);

  static const panelOk = Color(0xFFF5FBF6);
  static const panelAviso = Color(0xFFFFFAF0);
  static const panelFallo = Color(0xFFFFF6F7);
  static const textoError = Color(0xFFC0262F);

  static const campoFondo = Color(0xFFF8FAFD);
  static const campoBorde = Color(0xFFDBE5F2);
  static const anilloSpinner = Color(0xFFCFE3D3);
  static const pista = Color(0xFFCDDFF2);
  static const seleccion = Color(0xFFF5FBF6);
}

class GradientesSis {
  const GradientesSis._();

  static const boton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF35B729), Color(0xFF00751F)],
  );

  static const paso = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2FA83A), Color(0xFF067A26)],
  );

  static const fondo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE9F0FB), Color(0xFFF3F7FD), Color(0xFFEDF3FB)],
  );

  static const barra = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF14893A), Color(0xFF018026)],
  );

  static const botonNormal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF2F6FC)],
  );

  static const botonPeligro = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFDF1F3)],
  );

  static const brillo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromRGBO(255, 255, 255, 0.35), Color.fromRGBO(255, 255, 255, 0)],
  );
}

class FuentesSis {
  const FuentesSis._();

  static TextStyle inter({
    double tamano = 16,
    FontWeight peso = FontWeight.w400,
    Color color = ColoresSis.tinta,
    FontStyle estilo = FontStyle.normal,
    bool titulo = false,
  }) {
    final tracking = titulo ? tamano * -0.025 : 0.0;
    try {
      return GoogleFonts.inter(
        fontSize: tamano,
        fontWeight: peso,
        color: color,
        fontStyle: estilo,
        letterSpacing: tracking,
      );
    } catch (_) {
      return TextStyle(
        fontSize: tamano,
        fontWeight: peso,
        color: color,
        fontStyle: estilo,
        letterSpacing: tracking,
      );
    }
  }

  static TextStyle mono({
    double tamano = 15,
    Color color = ColoresSis.tinta,
    FontWeight peso = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['monospace'],
      fontSize: tamano,
      color: color,
      fontWeight: peso,
    );
  }
}

class TemaSis {
  const TemaSis._();

  static ThemeData get claro {
    final texto = TextTheme(
      headlineLarge: FuentesSis.inter(tamano: 32, peso: FontWeight.w800, color: ColoresSis.navy, titulo: true),
      headlineMedium: FuentesSis.inter(tamano: 28, peso: FontWeight.w800, color: ColoresSis.navy, titulo: true),
      headlineSmall: FuentesSis.inter(tamano: 22, peso: FontWeight.w800, color: ColoresSis.navy, titulo: true),
      titleLarge: FuentesSis.inter(tamano: 20, peso: FontWeight.w700, color: ColoresSis.navy, titulo: true),
      titleMedium: FuentesSis.inter(tamano: 16, peso: FontWeight.w700, color: ColoresSis.navy),
      titleSmall: FuentesSis.inter(tamano: 14, peso: FontWeight.w600, color: ColoresSis.navy),
      bodyLarge: FuentesSis.inter(tamano: 16, color: ColoresSis.tinta),
      bodyMedium: FuentesSis.inter(tamano: 14, color: ColoresSis.tinta),
      bodySmall: FuentesSis.inter(tamano: 12, color: ColoresSis.suave),
      labelLarge: FuentesSis.inter(tamano: 14, peso: FontWeight.w500, color: ColoresSis.suave),
      labelMedium: FuentesSis.inter(tamano: 12, peso: FontWeight.w500, color: ColoresSis.suave),
    );
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresSis.campoBorde),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColoresSis.verde,
        brightness: Brightness.light,
        primary: ColoresSis.verde,
        onPrimary: Colors.white,
        secondary: ColoresSis.azul,
        surface: ColoresSis.fondo,
        onSurface: ColoresSis.tinta,
        onSurfaceVariant: ColoresSis.suave,
        error: ColoresSis.errorTexto,
        outline: ColoresSis.linea,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: ColoresSis.fondo,
      textTheme: texto,
      focusColor: ColoresSis.foco,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ColoresSis.navy,
        titleTextStyle: FuentesSis.inter(tamano: 18, peso: FontWeight.w700, color: ColoresSis.navy, titulo: true),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresSis.campoFondo,
        labelStyle: FuentesSis.inter(tamano: 14, peso: FontWeight.w500, color: ColoresSis.mudo),
        hintStyle: FuentesSis.inter(tamano: 14, color: ColoresSis.mudo),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresSis.foco, width: 2)),
        errorBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresSis.errorBorde)),
        focusedErrorBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresSis.foco, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: ColoresSis.verde,
          foregroundColor: Colors.white,
          textStyle: FuentesSis.inter(tamano: 16, peso: FontWeight.w700, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: ColoresSis.navy,
          textStyle: FuentesSis.inter(tamano: 16, peso: FontWeight.w600, color: ColoresSis.navy),
          side: const BorderSide(color: Color(0xFFD3DFF0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColoresSis.linea),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.selected)) return ColoresSis.verde;
          return ColoresSis.suave;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ColoresSis.verde),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: FuentesSis.inter(tamano: 20, peso: FontWeight.w700, color: ColoresSis.navy, titulo: true),
      ),
    );
  }
}
