import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Variant 3 — Cyberpunk / Cyber Security Design Tokens & Theme Builder.
class CyberpunkColors {
  CyberpunkColors._();

  static const Color bgPrimary = Color(0xFF0B1020);
  static const Color bgSecondary = Color(0xFF121826);
  static const Color surfaceCard = Color(0xFF161B2E);
  static const Color borderSubtle = Color(0xFF24304A);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color electricViolet = Color(0xFF7C3AED);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFFF3B6B);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFEAF2FF);
  static const Color textSecondary = Color(0xFF9AA8C7);
}

class CyberpunkTheme {
  CyberpunkTheme._();

  static ThemeData build({Brightness brightness = Brightness.dark}) {
    final scheme = ColorScheme.dark(
      brightness: brightness,
      primary: CyberpunkColors.neonCyan,
      onPrimary: CyberpunkColors.bgPrimary,
      primaryContainer: const Color(0xFF11223D),
      onPrimaryContainer: CyberpunkColors.textPrimary,
      secondary: CyberpunkColors.electricViolet,
      onSecondary: CyberpunkColors.textPrimary,
      secondaryContainer: const Color(0xFF231845),
      onSecondaryContainer: CyberpunkColors.textPrimary,
      tertiary: CyberpunkColors.successGreen,
      onTertiary: CyberpunkColors.bgPrimary,
      error: CyberpunkColors.dangerRed,
      onError: Colors.white,
      errorContainer: const Color(0xFF3A1224),
      onErrorContainer: const Color(0xFFFFB3C6),
      surface: CyberpunkColors.surfaceCard,
      onSurface: CyberpunkColors.textPrimary,
      onSurfaceVariant: CyberpunkColors.textSecondary,
      surfaceContainerHighest: CyberpunkColors.bgSecondary,
      outline: CyberpunkColors.borderSubtle,
      outlineVariant: CyberpunkColors.borderSubtle.withValues(alpha: 0.65),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'CyberTech',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      colorScheme: scheme,
      scaffoldBackgroundColor: CyberpunkColors.bgPrimary,
      canvasColor: CyberpunkColors.bgPrimary,
      dividerColor: CyberpunkColors.borderSubtle,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
        titleLarge: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
        titleMedium: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        titleSmall: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.38,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w400,
          height: 1.38,
        ),
        bodySmall: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textSecondary,
          fontWeight: FontWeight.w300,
          height: 1.38,
          letterSpacing: 0.15,
        ),
        labelLarge: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CyberpunkColors.bgPrimary,
        foregroundColor: CyberpunkColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'CyberTech',
          color: CyberpunkColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
      cardTheme: CardThemeData(
        color: CyberpunkColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: CyberpunkColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberpunkColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: CyberpunkColors.neonCyan.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: CyberpunkColors.neonCyan.withValues(alpha: 0.45),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CyberpunkColors.neonCyan);
          }
          return const IconThemeData(color: CyberpunkColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CyberpunkColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: CyberpunkColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberpunkColors.bgSecondary,
        hintStyle: const TextStyle(color: CyberpunkColors.textSecondary),
        labelStyle: const TextStyle(color: CyberpunkColors.textSecondary),
        prefixIconColor: CyberpunkColors.neonCyan,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberpunkColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: CyberpunkColors.neonCyan,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberpunkColors.borderSubtle),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CyberpunkColors.neonCyan,
          foregroundColor: CyberpunkColors.bgPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberpunkColors.textPrimary,
          side: const BorderSide(color: CyberpunkColors.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CyberpunkColors.bgSecondary,
        selectedColor: CyberpunkColors.neonCyan.withValues(alpha: 0.18),
        disabledColor: CyberpunkColors.bgSecondary.withValues(alpha: 0.5),
        side: const BorderSide(color: CyberpunkColors.borderSubtle),
        labelStyle: const TextStyle(color: CyberpunkColors.textPrimary),
        secondaryLabelStyle: const TextStyle(
          color: CyberpunkColors.neonCyan,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return CyberpunkColors.neonCyan.withValues(alpha: 0.18);
            }
            return CyberpunkColors.bgSecondary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return CyberpunkColors.neonCyan;
            }
            return CyberpunkColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: CyberpunkColors.borderSubtle),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberpunkColors.neonCyan;
          }
          return CyberpunkColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberpunkColors.neonCyan.withValues(alpha: 0.25);
          }
          return CyberpunkColors.bgSecondary;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CyberpunkColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: CyberpunkColors.borderSubtle),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CyberpunkColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CyberpunkColors.borderSubtle),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CyberpunkColors.surfaceCard,
        contentTextStyle: const TextStyle(color: CyberpunkColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CyberpunkColors.neonCyan),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CyberpunkColors.neonCyan,
        foregroundColor: CyberpunkColors.bgPrimary,
      ),
    );
  }
}

/// Version A — Hexagonal Shield + AI Neural Core badge that renders
/// `assets/branding/app_icon_cyberpunk_vA.png` with a neon cyan glow frame
/// and vector fallback.
class CyberHexShieldIcon extends StatelessWidget {
  const CyberHexShieldIcon({
    super.key,
    this.size = 64,
    this.accentColor = CyberpunkColors.neonCyan,
    this.secondaryColor = CyberpunkColors.electricViolet,
  });

  final double size;
  final Color accentColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/branding/app_icon_cyberpunk_vA.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size.square(size),
            painter: _CyberHexShieldPainter(
              accentColor: accentColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberHexShieldPainter extends CustomPainter {
  const _CyberHexShieldPainter({
    required this.accentColor,
    required this.secondaryColor,
  });

  final Color accentColor;
  final Color secondaryColor;

  List<Offset> _hexPoints(Offset center, double radius) {
    return List<Offset>.generate(6, (i) {
      final rad = (-90.0 + i * 60.0) * math.pi / 180.0;
      return Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
    });
  }

  Path _polygonPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide * 0.44;
    final innerR = size.shortestSide * 0.37;
    final orbitR = size.shortestSide * 0.21;

    final outerPts = _hexPoints(center, outerR);
    final innerPts = _hexPoints(center, innerR);
    final nodePts = _hexPoints(center, orbitR);

    final outerPath = _polygonPath(outerPts);
    final innerPath = _polygonPath(innerPts);

    // Soft Neon Cyan outer glow
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.08
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Dark navy/purple shield fill
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CyberpunkColors.bgSecondary,
            Color(0xFF1D143B),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );

    // Inner Electric Violet hexagon frame
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = secondaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.2, size.shortestSide * 0.022),
    );

    // Outer Neon Cyan hexagon frame
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.8, size.shortestSide * 0.036),
    );

    // Neural network connections
    final violetSynapse = Paint()
      ..color = secondaryColor.withValues(alpha: 0.75)
      ..strokeWidth = math.max(1.0, size.shortestSide * 0.018);
    final cyanAxon = Paint()
      ..color = accentColor.withValues(alpha: 0.90)
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.022);

    canvas.drawPath(_polygonPath(nodePts), violetSynapse..style = PaintingStyle.stroke);
    for (final pt in nodePts) {
      canvas.drawLine(center, pt, cyanAxon);
    }

    // Outer neural nodes
    final nodeR = math.max(2.0, size.shortestSide * 0.038);
    final nodePaint = Paint()..color = accentColor;
    final whiteCore = Paint()..color = CyberpunkColors.textPrimary;
    for (final pt in nodePts) {
      canvas.drawCircle(pt, nodeR, nodePaint);
      canvas.drawCircle(pt, nodeR * 0.45, whiteCore);
    }

    // Central AI neural core
    canvas.drawCircle(
      center,
      size.shortestSide * 0.11,
      Paint()..color = accentColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.075,
      Paint()..color = secondaryColor,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.050,
      nodePaint,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.024,
      whiteCore,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberHexShieldPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor ||
      oldDelegate.secondaryColor != secondaryColor;
}
