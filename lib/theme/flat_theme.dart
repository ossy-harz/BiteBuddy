import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flat design system for BiteBuddy app using vibrant colors and minimalist aesthetics
class FlatTheme {
  // Primary Colors
  static const Color primaryLight = Color(0xFF4CAF50);  // Flat Green
  static const Color primaryDark = Color(0xFF4CAF50);   // Same green for dark mode
  static const Color neutralLight = Color(0xFFF9F9F9);  // Almost white background
  static const Color neutralDark = Color(0xFF121212);   // Dark background

  // Secondary Colors
  static const Color secondaryLight = Color(0xFFFF5722); // Flat Orange
  static const Color secondaryDark = Color(0xFFFF5722);  // Same orange for dark mode

  // Accent Colors
  static const Color accentLight = Color(0xFF2196F3);   // Flat Blue
  static const Color accentDark = Color(0xFF2196F3);    // Same blue for dark mode

  // Semantic Colors
  static const Color successColor = Color(0xFF4CAF50);  // Green
  static const Color errorColor = Color(0xFFF44336);    // Red
  static const Color warningColor = Color(0xFFFF9800);  // Orange
  static const Color infoColor = Color(0xFF2196F3);     // Blue

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
  static const Color dairyColor = Color(0xFF2196F3);      // Blue
  static const Color meatColor = Color(0xFF795548);       // Brown
  static const Color grainsColor = Color(0xFFFFC107);     // Amber
  static const Color spicesColor = Color(0xFFFF5722);     // Deep Orange

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;

  // Border Radius
  static const double radiusXs = 0.0;  // Flat design often uses square corners
  static const double radiusSm = 2.0;  // Minimal rounding
  static const double radiusMd = 4.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;
  static const double radiusFull = 999.0;

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // Light Theme
  static ThemeData lightTheme() {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: Colors.white,
        tertiary: accentLight,
        onTertiary: Colors.white,
        tertiaryContainer: accentLight,
        onTertiaryContainer: Colors.white,
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
          side: BorderSide(color: Colors.grey.shade200),
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
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade300),
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
        backgroundColor: Colors.grey.shade100,
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
        elevation: 0,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryLight,
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
        elevation: 0,
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
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: secondaryDark,
        onSecondary: Colors.white,
        secondaryContainer: secondaryDark,
        onSecondaryContainer: Colors.white,
        tertiary: accentDark,
        onTertiary: Colors.white,
        tertiaryContainer: accentDark,
        onTertiaryContainer: Colors.white,
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
          side: BorderSide(color: Colors.grey.shade800),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
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
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade700),
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
        backgroundColor: Colors.grey.shade800,
        selectedColor: primaryDark,
        disabledColor: Colors.grey.shade700,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textPrimaryDark,
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
        backgroundColor: surfaceDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryDark,
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
        foregroundColor: Colors.white,
        elevation: 0,
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

