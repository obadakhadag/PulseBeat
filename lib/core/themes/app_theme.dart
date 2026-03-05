import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color _cream = Color(0xFFF6F1E8);
  static const Color _ink = Color(0xFF111111);
  static const Color _coral = Color(0xFFFF6B4A);
  static const Color _teal = Color(0xFF0F8B8D);
  static const Color _sand = Color(0xFFF3D9B1);
  static const Color _night = Color(0xFF0C1017);
  static const Color _nightCard = Color(0xFF151C27);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _coral,
      primary: _coral,
      secondary: _teal,
      surface: _cream,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _cream,
      textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: _ink,
        displayColor: _ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.78),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        selectedColor: _ink,
        secondarySelectedColor: _ink,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
        secondaryLabelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: BorderSide.none,
      ),
      sliderTheme: const SliderThemeData(trackHeight: 4),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSurfaces(
          primaryGlow: _coral,
          secondaryGlow: _teal,
          accentSoft: _sand,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _teal,
      primary: _sand,
      secondary: _coral,
      surface: _night,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _night,
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _nightCard.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        selectedColor: _sand,
        secondarySelectedColor: _sand,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        secondaryLabelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: _night,
        ),
        side: BorderSide.none,
      ),
      sliderTheme: const SliderThemeData(trackHeight: 4),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSurfaces(
          primaryGlow: _coral,
          secondaryGlow: _teal,
          accentSoft: _nightCard,
        ),
      ],
    );
  }
}

@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.accentSoft,
  });

  final Color primaryGlow;
  final Color secondaryGlow;
  final Color accentSoft;

  @override
  AppSurfaces copyWith({
    Color? primaryGlow,
    Color? secondaryGlow,
    Color? accentSoft,
  }) {
    return AppSurfaces(
      primaryGlow: primaryGlow ?? this.primaryGlow,
      secondaryGlow: secondaryGlow ?? this.secondaryGlow,
      accentSoft: accentSoft ?? this.accentSoft,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) {
      return this;
    }

    return AppSurfaces(
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t) ?? primaryGlow,
      secondaryGlow:
          Color.lerp(secondaryGlow, other.secondaryGlow, t) ?? secondaryGlow,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
    );
  }
}
