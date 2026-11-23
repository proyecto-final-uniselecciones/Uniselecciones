import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const Color _brandBlue = Color(0xFF245FE5);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
