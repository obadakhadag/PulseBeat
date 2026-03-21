import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFF5F5F5);
  static const Color _lightText = Color(0xFF111111);
  static const Color _lightTextSecondary = Color(0xFF4A4A4A);
  static const Color _night = Color(0xFF0D0D0D);
  static const Color _nightCard = Color(0xFF1A1A1A);
  static const Color _nightCardSoft = Color(0xFF232323);
  static const Color _darkTextSecondary = Color(0xFF9A9A9A);
  static const Color _violet = Color(0xFF9B5CFF);
  static const Color _orange = Color(0xFFFF8A3D);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _lavender = Color(0xFFD8C3FF);
  static const Color _shadow = Color(0x4D000000);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _violet,
      primary: _violet,
      secondary: _orange,
      tertiary: _pink,
      surface: _lightCard,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightCard,
      canvasColor: _lightBackground,
      shadowColor: _shadow,
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.soraTextTheme().apply(
        bodyColor: _lightText,
        displayColor: _lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color: _lightText),
      cardTheme: CardThemeData(
        color: _lightCard.withValues(alpha: 0.94),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: _lightCard,
        selectedColor: _orange,
        secondarySelectedColor: _orange,
        labelStyle: GoogleFonts.sora(
          fontWeight: FontWeight.w600,
          color: _lightTextSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          color: _white,
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightCard.withValues(alpha: 0.92),
        selectedItemColor: _orange,
        unselectedItemColor: _lightText.withValues(alpha: 0.60),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightCard.withValues(alpha: 0.94),
        hintStyle: const TextStyle(color: _lightTextSecondary),
        prefixIconColor: _lightTextSecondary,
        suffixIconColor: _lightTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _orange.withValues(alpha: 0.45)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: _lightCard.withValues(alpha: 0.94),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: _orange,
        inactiveTrackColor: _lightText.withValues(alpha: 0.12),
        thumbColor: _orange,
        overlayColor: _orange.withValues(alpha: 0.12),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: <Color>[_orange, _pink]),
        ),
        labelColor: _white,
        unselectedLabelColor: _lightTextSecondary,
        labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w600),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightText,
          side: BorderSide(color: _lightText.withValues(alpha: 0.10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSurfaces(
          primaryGlow: _violet,
          secondaryGlow: _orange,
          accentSoft: _lavender,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _violet,
      primary: _violet,
      secondary: _orange,
      tertiary: _pink,
      surface: _night,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _night,
      cardColor: _nightCard,
      canvasColor: _night,
      shadowColor: _shadow,
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.soraTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: _white, displayColor: _white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _nightCard.withValues(alpha: 0.92),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: _white.withValues(alpha: 0.08),
        selectedColor: _orange,
        secondarySelectedColor: _orange,
        labelStyle: GoogleFonts.sora(
          fontWeight: FontWeight.w600,
          color: _darkTextSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.sora(
          fontWeight: FontWeight.w700,
          color: _white,
        ),
        side: BorderSide.none,
      ),
      dividerColor: _white.withValues(alpha: 0.08),
      iconTheme: const IconThemeData(color: _white),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _orange),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white.withValues(alpha: 0.06),
        hintStyle: const TextStyle(color: _darkTextSecondary),
        prefixIconColor: _darkTextSecondary,
        suffixIconColor: _darkTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _orange.withValues(alpha: 0.55)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: _nightCardSoft.withValues(alpha: 0.95),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: _orange,
        inactiveTrackColor: _white.withValues(alpha: 0.12),
        thumbColor: _orange,
        overlayColor: _orange.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _orange;
          }
          return _white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _orange.withValues(alpha: 0.42);
          }
          return _white.withValues(alpha: 0.16);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: <Color>[_orange, _pink]),
        ),
        labelColor: _white,
        unselectedLabelColor: _darkTextSecondary,
        labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w600),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: BorderSide(color: _white.withValues(alpha: 0.10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: _white.withValues(alpha: 0.04),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _white,
          backgroundColor: _white.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return _orange;
            }
            return _white.withValues(alpha: 0.04);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return _white;
            }
            return _darkTextSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: _white.withValues(alpha: 0.08)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _nightCardSoft.withValues(alpha: 0.95),
        selectedItemColor: _orange,
        unselectedItemColor: _darkTextSecondary,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _nightCardSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _nightCardSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppSurfaces(
          primaryGlow: _violet,
          secondaryGlow: _orange,
          accentSoft: _nightCardSoft,
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
