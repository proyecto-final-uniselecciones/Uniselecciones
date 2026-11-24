import 'package:material_ui/material_ui.dart';

/// Paleta de UniSelecciones.
///
/// La referencia visual es la señalética del baloncesto profesional: azul
/// marino profundo como base, superficies claras para el contenido y un rojo
/// de acento para lo que tiene que saltar a la vista. El azul marino manda:
/// las barras, los encabezados de rol y los bloques de marcador van sobre
/// fondo oscuro, y las tarjetas de datos sobre fondo claro, para que leer
/// cifras no canse la vista.
abstract final class UniColors {
  // --- Azules marinos: la base de la identidad ---
  /// El más profundo. Fondo de los bloques tipo marcador.
  static const navy900 = Color(0xFF050B1C);

  /// Barra superior y cabeceras de pantalla.
  static const navy800 = Color(0xFF0A1733);

  /// Superficies elevadas sobre fondo oscuro.
  static const navy700 = Color(0xFF122244);

  /// Bordes y separadores dentro de las zonas oscuras.
  static const navy600 = Color(0xFF1C3160);

  /// Azul marino medio, para degradados.
  static const navy500 = Color(0xFF24417B);

  // --- Acentos ---
  /// Rojo de acento. Marca lo urgente y lo destacado.
  static const red = Color(0xFFD42A3C);
  static const redDark = Color(0xFFA81E2D);

  /// Naranja de balón. Acento del entrenador.
  static const orange = Color(0xFFF2652A);

  /// Azul eléctrico. Acento del jugador.
  static const electric = Color(0xFF1C6EF2);

  /// Oro. Posiciones de privilegio y campeonatos.
  static const gold = Color(0xFFF2B01E);

  /// Verde de estado correcto.
  static const green = Color(0xFF15934F);

  // --- Superficies claras ---
  /// Fondo general de las pantallas de contenido.
  static const canvas = Color(0xFFF2F5FA);
  static const surface = Color(0xFFFFFFFF);

  /// Bordes de tarjeta sobre fondo claro.
  static const line = Color(0xFFDFE5F0);

  // --- Texto ---
  static const ink = Color(0xFF0B1529);
  static const inkSoft = Color(0xFF5A6882);
  static const onNavy = Color(0xFFF4F7FF);
  static const onNavySoft = Color(0xFF9FB1D4);
}

/// Acento de cada rol. Los tres paneles comparten estructura; el acento es
/// lo que los distingue de un vistazo.
abstract final class UniRoleAccent {
  static const jugador = UniColors.electric;
  static const entrenador = UniColors.orange;
  static const institucion = UniColors.red;
}

/// Radios y espaciados, para no repetir números sueltos por todo el código.
abstract final class UniShape {
  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 22.0;
  static const radiusXl = 28.0;

  static BorderRadius get sm => BorderRadius.circular(radiusSm);
  static BorderRadius get md => BorderRadius.circular(radiusMd);
  static BorderRadius get lg => BorderRadius.circular(radiusLg);
  static BorderRadius get xl => BorderRadius.circular(radiusXl);
}

/// Familias tipográficas declaradas en pubspec.yaml.
abstract final class UniFonts {
  /// Condensada: títulos, marcadores y cifras grandes.
  static const display = 'BarlowCondensed';

  /// Texto corrido, formularios y etiquetas.
  static const text = 'Barlow';
}

abstract final class AppTheme {
  /// Estilo de las etiquetas en mayúsculas con mucho espaciado, el recurso
  /// más característico de la rotulación deportiva.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: UniFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 13,
    letterSpacing: 1.6,
    height: 1.1,
  );

  /// Cifra de marcador.
  static const TextStyle scoreboard = TextStyle(
    fontFamily: UniFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1.0,
    letterSpacing: -0.5,
  );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: UniColors.navy800,
      brightness: Brightness.light,
    ).copyWith(
      primary: UniColors.navy800,
      onPrimary: UniColors.onNavy,
      secondary: UniColors.red,
      onSecondary: Colors.white,
      surface: UniColors.surface,
      onSurface: UniColors.ink,
      error: UniColors.redDark,
    );

    // La escala tipográfica mezcla las dos familias a propósito: la
    // condensada para lo que se lee de un vistazo (títulos y números) y la
    // normal para lo que se lee con calma (párrafos y formularios).
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 56,
        height: 1.0,
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 44,
        height: 1.02,
        letterSpacing: -0.8,
      ),
      displaySmall: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 36,
        height: 1.05,
        letterSpacing: -0.6,
      ),
      headlineLarge: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 32,
        height: 1.08,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 27,
        height: 1.1,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 23,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 21,
        height: 1.2,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w400,
        fontSize: 14.5,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontFamily: UniFonts.text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      labelSmall: TextStyle(
        fontFamily: UniFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UniColors.canvas,
      fontFamily: UniFonts.text,
      textTheme: textTheme.apply(
        bodyColor: UniColors.ink,
        displayColor: UniColors.ink,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: UniColors.navy900,
        foregroundColor: UniColors.onNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: UniFonts.display,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: 1.0,
          color: UniColors.onNavy,
        ),
      ),

      cardTheme: CardThemeData(
        color: UniColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: UniColors.line),
          borderRadius: UniShape.lg,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: UniColors.line,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UniColors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: UniColors.line,
          disabledForegroundColor: UniColors.inkSoft,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: UniShape.sm),
          textStyle: const TextStyle(
            fontFamily: UniFonts.display,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: UniShape.sm),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UniColors.navy800,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: UniColors.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: UniShape.sm),
          textStyle: const TextStyle(
            fontFamily: UniFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UniColors.navy800,
          textStyle: const TextStyle(
            fontFamily: UniFonts.text,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9FD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: UniShape.sm,
          borderSide: const BorderSide(color: UniColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UniShape.sm,
          borderSide: const BorderSide(color: UniColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UniShape.sm,
          borderSide: const BorderSide(color: UniColors.navy800, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UniShape.sm,
          borderSide: const BorderSide(color: UniColors.redDark, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UniShape.sm,
          borderSide: const BorderSide(color: UniColors.redDark, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: UniFonts.text,
          color: UniColors.inkSoft,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: UniFonts.text,
          color: UniColors.navy800,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: UniColors.inkSoft,
        suffixIconColor: UniColors.inkSoft,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(UniColors.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: UniShape.sm),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: UniColors.canvas,
        side: const BorderSide(color: UniColors.line),
        labelStyle: const TextStyle(
          fontFamily: UniFonts.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: UniShape.sm),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: UniColors.red,
      ),
    );
  }
}
