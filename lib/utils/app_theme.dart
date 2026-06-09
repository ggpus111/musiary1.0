import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── 색상 팔레트 (썸원 스타일 — 따뜻한 크림/베이지 톤) ─────────────
  static const Color primary = Color(0xFFC4966A);       // 따뜻한 카라멜 브라운
  static const Color primaryLight = Color(0xFFE8CEAF);  // 연한 베이지
  static const Color secondary = Color(0xFFE8A898);     // 따뜻한 피치 핑크
  static const Color background = Color(0xFFFAF7F2);    // 크림 화이트
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EFE6); // 따뜻한 베이지 카드
  static const Color textPrimary = Color(0xFF3D2E22);   // 따뜻한 다크 브라운
  static const Color textSecondary = Color(0xFF8B7355); // 미디엄 브라운
  static const Color textHint = Color(0xFFC4AD96);
  static const Color divider = Color(0xFFEDE3D8);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansKr(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.notoSansKr(
          fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleMedium: GoogleFonts.notoSansKr(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.notoSansKr(
          fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.65,
        ),
        bodyMedium: GoogleFonts.notoSansKr(
          fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.55,
        ),
        labelLarge: GoogleFonts.notoSansKr(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: primary.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── 공통 그라디언트 ───────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient get softGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary.withValues(alpha: 0.08), primaryLight.withValues(alpha: 0.05)],
  );

  // ── 공통 그림자 ──────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFFC4966A).withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}
