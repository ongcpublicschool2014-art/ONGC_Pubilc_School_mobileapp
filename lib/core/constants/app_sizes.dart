import 'package:flutter/material.dart';

/// Tailwind-inspired spacing and sizing constants
class AppSizes {
  AppSizes._();

  // Spacing (Tailwind: p-1, m-2, etc.)
  static const double s0 = 0;
  static const double s1 = 4; // 0.25rem
  static const double s2 = 8; // 0.5rem
  static const double s3 = 12; // 0.75rem
  static const double s4 = 16; // 1rem
  static const double s5 = 20; // 1.25rem
  static const double s6 = 24; // 1.5rem
  static const double s8 = 32; // 2rem
  static const double s10 = 40; // 2.5rem
  static const double s12 = 48; // 3rem
  static const double s16 = 64; // 4rem
  static const double s20 = 80; // 5rem
  static const double s24 = 96; // 6rem
  static const double s32 = 128; // 8rem

  // Border Radius (Tailwind: rounded-sm, rounded-lg, etc.)
  static const double roundedNone = 0;
  static const double roundedSm = 2;
  static const double rounded = 4;
  static const double roundedMd = 6;
  static const double roundedLg = 8;
  static const double roundedXl = 12;
  static const double rounded2xl = 16;
  static const double rounded3xl = 24;
  static const double roundedFull = 9999;

  // Font Sizes (Tailwind: text-xs, text-sm, etc.)
  static const double textXs = 12;
  static const double textSm = 14;
  static const double textBase = 16;
  static const double textLg = 18;
  static const double textXl = 20;
  static const double text2xl = 24;
  static const double text3xl = 30;
  static const double text4xl = 36;
  static const double text5xl = 48;

  // Semantic Font Sizes (UI-specific)
  static const double appTitle = 20;        // App Title - 20px, w600
  static const double sectionTitle = 16;    // Section Title - 16px, w600
  static const double mainAmount = 26;      // Main Amount - 26px, w700
  static const double bodyText = 14;        // Body Text - 14px, w400
  static const double secondaryText = 12;   // Secondary Text - 12px, w400
  static const double buttonText = 15;      // Buttons - 15px, w600
  static const double tagText = 12;         // Tag - 12px, w600

  // Font Weights
  static const FontWeight fontThin = FontWeight.w100;
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemibold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  static const FontWeight fontExtrabold = FontWeight.w800;

  // Icon Sizes
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double icon2xl = 40;

  // Screen breakpoints
  static const double screenSm = 640;
  static const double screenMd = 768;
  static const double screenLg = 1024;
  static const double screenXl = 1280;
}
