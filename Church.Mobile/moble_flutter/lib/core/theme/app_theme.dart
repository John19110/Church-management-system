import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_palette.dart';

/// Central theme definition for My Church.
///
/// Backwards-compatible: the original color constants (e.g. [AppTheme.primary])
/// are still exposed so existing screens keep compiling while they migrate to
/// the ColorScheme / [AppPalette] tokens.
class AppTheme {
  AppTheme._();

  // ---- Legacy constants kept for backwards compatibility --------------------
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color accent = AppColors.gold;
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color error = AppColors.danger;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkPrimary = AppColors.primaryLight;
  static const Color darkTextPrimary = AppColors.darkTextPrimary;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;

  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.gold,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      error: AppColors.danger,
    );

    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final baseText = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    final textTheme = _textTheme(baseText, textPrimary, palette.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.neutralSoft,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelLarge!,
        secondaryLabelStyle: textTheme.labelLarge!,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: scheme.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        errorMaxLines: 6,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
          height: 1.35,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.border),
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: palette.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  static TextTheme _textTheme(
    TextTheme base,
    Color primaryText,
    Color secondaryText,
  ) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primaryText),
      bodyMedium: base.bodyMedium?.copyWith(color: primaryText),
      bodySmall: base.bodySmall?.copyWith(color: secondaryText),
      labelLarge: base.labelLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
