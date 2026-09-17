import 'package:flutter/material.dart';

/// Colors ported 1:1 from tailwind.config.ts of the original eMaap web app.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF0B3D91);
  static const Color deepNavy = Color(0xFF082B63);
  static const Color saffron = Color(0xFFFF7A00);
  static const Color success = Color(0xFF168A45);
  static const Color amber = Color(0xFFF4A623);
  static const Color errorRed = Color(0xFFD64545);
  static const Color ink = Color(0xFF172033);
  static const Color slate = Color(0xFF667085);
  static const Color slate400 = Color(0xFF98A2B3);
  static const Color slate100 = Color(0xFFF1F3F6);
  static const Color slate200 = Color(0xFFE4E8EE);
  static const Color background = Color(0xFFF6F8FB);

  static const Color blue50 = Color(0xFFEBF2FE);
  static const Color blue100 = Color(0xFFD7E4FB);
  static const Color green50 = Color(0xFFE9F7EF);
  static const Color green100 = Color(0xFFCFEFDC);
  static const Color red50 = Color(0xFFFBEBEB);
  static const Color red100 = Color(0xFFF6D6D6);
  static const Color red200 = Color(0xFFF0C0C0);
  static const Color orange50 = Color(0xFFFFF2E6);
  static const Color orange200 = Color(0xFFFFD3A8);
  static const Color amber50 = Color(0xFFFEF6E7);
  static const Color amber200 = Color(0xFFFBE0AA);

  static const Color scanBg = Color(0xFF101A2A);

  static const LinearGradient heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF174D9F), Color(0xFF0A3279)],
  );

  static const LinearGradient sealTexture = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF637D82), Color(0xFFB9C8BF), Color(0xFF596E6E)],
  );
}
