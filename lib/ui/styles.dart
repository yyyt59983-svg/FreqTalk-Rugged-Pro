import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TacticalTheme {
  static const Color background = Color(0xFF0D1117);
  static const Color accent = Color(0xFF2ECC71); // Tactical Green
  static const Color alert = Color(0xFFE74C3C);  // Transmission Red
  static const Color surface = Color(0xFF161B22);
  static const Color glass = Color(0x1AFFFFFF);

  static TextStyle get headline => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static TextStyle get mono => GoogleFonts.robotoMono(
    fontSize: 16,
    color: accent,
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: glass,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white12, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, 4),
      )
    ],
  );
}
