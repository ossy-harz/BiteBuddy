import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern design system for BiteBuddy app using a food-inspired color palette
class AppTheme {
  // Primary Colors
  static const Color primaryLight = Color(0xFF5CAA47);  // Fresh Green
  static const Color primaryDark = Color(0xFF7CC26C);   // Lighter Green for dark mode
  static const Color neutralLight = Color(0xFFF8F9FA);  // Off-white background
  static const Color neutralDark = Color(0xFF121212);   // Dark background

  // Secondary Colors
  static const Color secondaryLight = Color(0xFFFF8A65); // Warm Orange
  static const Color secondaryDark = Color(0xFFFFAB91);  // Lighter Orange for dark mode

  // Accent Colors
  static const Color accentLight = Color(0xFF42A5F5);   // Blue for contrast
  static const Color accentDark = Color(0xFF64B5F6);    // Lighter Blue for dark mode

  // Semantic Colors
  static const Color successColor = Color(0xFF66BB6A);  // Green
  static const Color errorColor = Color(0xFFE57373);    // Red
  static const Color warningColor = Color(0xFFFFB74D);  // Amber
  static const Color infoColor = Color(0xFF4FC3F7);     // Light Blue

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);  // White
  static const Color surfaceDark = Color(0xFF1E1E1E);   // Dark Gray

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  // Food Category Colors
  static const Color fruitsColor = Color(0xFFE91E63);     // Pink
  static const Color vegetablesColor = Color(0xFF4CAF50); // Green
  static const Color dairyColor = Color(0xFF42A5F5);      // Blue
  static const Color meatColor = Color(0xFFBF360C);       // Brown
  static const Color grainsColor = Color(0xFFFFB300);     // Amber
  static const Color spicesColor = Color(0xFFFF5722);     // Deep Orange

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // Elevation
  static const List<BoxShadow> lightElevation1 = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lightElevation2 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lightElevation3 = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkElevation1 = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> darkElevation2 = [
    BoxShadow(
      color: Color(0x52000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> darkElevation3 = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Light Theme
  static ThemeData lightTheme() {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primaryLight.withOpacity(0.1),
        onPrimaryContainer: primaryLight.withOpacity(0.8),
        secondary: secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight.withOpacity(0.1),
        onSecondaryContainer: secondaryLight.withOpacity(0.8),
        tertiary: accentLight,
        onTertiary: Colors.white,
        tertiaryContainer: accentLight.withOpacity(0.1),
        onTertiaryContainer: accentLight.withOpacity(0.8),
        background: neutralLight,
        onBackground: textPrimaryLight,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: neutralLight,
      cardColor: surfaceLight,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textPrimaryLight,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textSecondaryLight,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textSecondaryLight,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: BorderSide(color: primaryLight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight.withOpacity(0.1),
        selectedColor: primaryLight,
        disabledColor: Colors.grey.shade200,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textPrimaryLight,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryLight.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.bodySmall?.copyWith(
              color: primaryLight,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.bodySmall?.copyWith(
            color: textSecondaryLight,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: primaryLight,
              size: 24,
            );
          }
          return IconThemeData(
            color: textSecondaryLight,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryLight,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: primaryLight,
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: spacingMd,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLg),
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.black,
        primaryContainer: primaryDark.withOpacity(0.2),
        onPrimaryContainer: primaryDark,
        secondary: secondaryDark,
        onSecondary: Colors.black,
        secondaryContainer: secondaryDark.withOpacity(0.2),
        onSecondaryContainer: secondaryDark,
        tertiary: accentDark,
        onTertiary: Colors.black,
        tertiaryContainer: accentDark.withOpacity(0.2),
        onTertiaryContainer: accentDark,
        background: neutralDark,
        onBackground: textPrimaryDark,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: neutralDark,
      cardColor: surfaceDark,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textPrimaryDark,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textSecondaryDark,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textSecondaryDark,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: BorderSide(color: primaryDark),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primaryDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryDark.withOpacity(0.2),
        selectedColor: primaryDark,
        disabledColor: Colors.grey.shade800,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textPrimaryDark,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.black,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryDark.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.bodySmall?.copyWith(
              color: primaryDark,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.bodySmall?.copyWith(
            color: textSecondaryDark,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: primaryDark,
              size: 24,
            );
          }
          return IconThemeData(
            color: textSecondaryDark,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryDark,
        unselectedLabelColor: textSecondaryDark,
        indicatorColor: primaryDark,
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: spacingMd,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLg),
          ),
        ),
      ),
    );
  }

  /// Helper method to get elevation based on theme brightness
  static List<BoxShadow> getElevation(BuildContext context, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (level) {
      case 1:
        return isDark ? darkElevation1 : lightElevation1;
      case 2:
        return isDark ? darkElevation2 : lightElevation2;
      case 3:
        return isDark ? darkElevation3 : lightElevation3;
      default:
        return isDark ? darkElevation1 : lightElevation1;
    }
  }

  /// Get color for food category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return fruitsColor;
      case 'vegetables':
        return vegetablesColor;
      case 'dairy':
        return dairyColor;
      case 'meat':
        return meatColor;
      case 'grains':
        return grainsColor;
      case 'spices':
        return spicesColor;
      default:
        return primaryLight;
    }
  }
}

