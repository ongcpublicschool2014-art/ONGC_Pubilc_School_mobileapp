import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The parent app's visual language, on the FIT School desktop "Peacock"
/// theme: a warm paper page, cream cards with a hairline border and the
/// desktop's soft card shadow, one teal hero per screen, marigold only as a
/// highlight, and colour used only to say something (a due date, a status, a
/// fee group).
class AppUi {
  AppUi._();

  // Surfaces
  static const Color pageBg = AppColors.paper;
  static const Color card = AppColors.card;
  static const Color line = AppColors.line;
  static const Color lineSoft = AppColors.line2;
  static const Color fill = AppColors.segmentBg;

  // Ink
  static const Color ink = AppColors.ink;
  static const Color inkMuted = AppColors.ink2;
  static const Color inkFaint = AppColors.ink3;

  // The one teal per screen — the balance hero and the primary button. (The
  // names are kept from the old navy theme so every screen follows along.)
  static const Color navy = AppColors.primary;
  static const Color navyDeep = AppColors.primaryDark;
  static const Color link = AppColors.primary;

  // Marigold highlight (bars, rules, dots -- never small text).
  static const Color marigold = AppColors.gold;

  // Status tints: a pale ground with ink dark enough to read on it.
  static const Color dueBg = AppColors.goldSoft;
  static const Color dueInk = AppColors.goldInk;
  static const Color paidBg = AppColors.primarySoft;
  static const Color paidInk = AppColors.primaryDark;
  static const Color failBg = AppColors.coralBg;
  static const Color failInk = AppColors.coralInk;

  static const double gutter = 20;
  static const double radius = 14; // desktop card radius
  static const double controlRadius = 10; // desktop buttons / inputs

  /// The card every list and panel is built from (desktop AppCard).
  static BoxDecoration cardBox({Color? border, double r = radius}) =>
      BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: border ?? line),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(23, 35, 43, 0.03), offset: Offset(0, 1)),
          BoxShadow(
              color: Color.fromRGBO(23, 35, 43, 0.35),
              offset: Offset(0, 12),
              blurRadius: 28,
              spreadRadius: -22),
        ],
      );

  /// A group's accent: [0] the pale tile behind its icon, [1] its ink.
  ///
  /// Every group gets one, keyed by name, so a third group is never left
  /// looking like an afterthought next to the first two.
  static List<Color> groupTint(String groupName) {
    final n = groupName.toUpperCase();
    if (n.contains('ARREAR')) return const [AppColors.coralBg, AppColors.coralInk];
    if (n.contains('HOSTEL') || n.contains('MESS')) {
      return const [AppColors.purpleBg, AppColors.purple];
    }
    if (n.contains('COLLEGE') || n.contains('TUITION') || n.contains('SCHOOL')) {
      return const [AppColors.primarySoft, AppColors.primaryDark];
    }
    if (n.contains('TRANSPORT') || n.contains('BUS') || n.contains('VAN')) {
      return const [AppColors.blueBg, AppColors.blue];
    }
    if (n.contains('EXAM') || n.contains('TEST')) {
      return const [AppColors.goldSoft, AppColors.goldInk];
    }
    const palette = <List<Color>>[
      [AppColors.goldSoft, AppColors.goldInk],
      [AppColors.purpleBg, AppColors.purple],
      [AppColors.blueBg, AppColors.blue],
      [AppColors.primaryTint, AppColors.primary],
      [AppColors.coralBg, AppColors.coralInk],
    ];
    return palette[n.hashCode.abs() % palette.length];
  }

  /// The icon a fee group carries, from the project's linear icon set.
  static String groupIcon(String groupName) {
    final n = groupName.toUpperCase();
    if (n.contains('ARREAR')) return 'clock-1';
    if (n.contains('HOSTEL') || n.contains('MESS')) return 'home-2';
    if (n.contains('TRANSPORT') || n.contains('BUS') || n.contains('VAN')) {
      return 'bus';
    }
    if (n.contains('EXAM') || n.contains('TEST')) return 'task-square';
    if (n.contains('COLLEGE') || n.contains('TUITION') || n.contains('SCHOOL')) {
      return 'book';
    }
    return 'receipt';
  }
}

/// The three desktop Peacock typefaces (Google Fonts).
///  * [heading] Fraunces -- page titles, the "FIT School" brand, the school
///    name, avatar letters. Lining numerals.
///  * [body] Plus Jakarta Sans -- everything else (the theme's default font).
///  * [figure] Plus Jakarta Sans at display weight -- money on cards and heroes
///    (the user prefers the sans rupee sign for figures).
///  * [mono] JetBrains Mono -- admission numbers, receipt numbers, IDs.
class AppFonts {
  AppFonts._();
  static const List<FontFeature> lining = [FontFeature('lnum'), FontFeature.tabularFigures()];

  static TextStyle heading({double? size, FontWeight weight = FontWeight.w600, Color color = AppColors.ink, double? height, double? letterSpacing}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing, fontFeatures: lining);

  static TextStyle body({double? size, FontWeight weight = FontWeight.w500, Color color = AppColors.ink, double? letterSpacing, double? height}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height, fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle figure({double? size, FontWeight weight = FontWeight.w700, Color color = AppColors.ink, double? height}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: height,
          letterSpacing: size == null ? null : -0.02 * size, fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle mono({double? size, FontWeight weight = FontWeight.w500, Color color = AppColors.ink}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  /// Family name of the heading font (Fraunces), for page titles written as
  /// plain TextStyles.
  static String get headingFamily => GoogleFonts.fraunces().fontFamily!;

  /// Family name of the body font, for widgets that only take a family.
  static String get bodyFamily => GoogleFonts.plusJakartaSans().fontFamily!;
}
