import 'package:flutter/material.dart';

import 'probe/models.dart';

/// THESIS: A running step-row instrument. The live cell is the chase light;
/// everything else is last-known truth. Not a card dashboard.
/// OWN-WORLD: moreweb.ir Poppins + Space Mono on rgb(3,0,5). Hairline grid,
/// no neon, no glow, no gradient type. Status is type, not decoration.
/// STORY: An engineer glances and knows what the tunnel is doing right now.
/// FIRST VIEWPORT: DNS row, proto/edge/hunt strips, then the site grid.
/// FORM: bench step-row (seed 7261d2de) raised with chase-light discipline.
/// FINISH: unreviewed and undocumented is unfinished; this build ends with
/// the finish review, the verdict, DESIGN.md, and every shipping raster
/// carrying its provenance.

const Color kInk = Color(0xFF09090B); // zinc-950 background
const Color kCard = Color(0xFF121215); // zinc-900 card surface
const Color kCardMuted = Color(0xFF18181B); // zinc-900 border/hover surface
const Color kPaper = Color(0xFFF4F4F5); // zinc-100 primary text
const Color kMute = Color(0xFFA1A1AA); // zinc-400 muted text
const Color kSubtle = Color(0xFF71717A); // zinc-500 subtle metadata
const Color kLine = Color(0xFF27272A); // zinc-800 border
const Color kOk = Color(0xFF10B981); // emerald-500
const Color kTo = Color(0xFFF59E0B); // amber-500
const Color kFail = Color(0xFFF43F5E); // rose-500
const Color kLive = Color(0xFFFAFAFA); // zinc-50
const Color kPoison = Color(0xFFFFD600); // electric yellow

ThemeData buildTheme({required bool compact}) {
  const family = 'Poppins';
  final scheme = const ColorScheme.dark(
    primary: kPaper,
    onPrimary: kInk,
    secondary: kMute,
    onSecondary: kInk,
    surface: kInk,
    onSurface: kPaper,
    error: kFail,
    onError: kPaper,
    outline: kLine,
    surfaceContainerHighest: Color(0xFF18181B),
    surfaceContainerHigh: Color(0xFF141417),
    surfaceContainer: Color(0xFF121215),
    surfaceContainerLow: Color(0xFF0D0D10),
  );

  final text = TextTheme(
    displayLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 22 : 28,
      height: 1.15,
      letterSpacing: -0.5,
      color: kPaper,
    ),
    titleLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 16 : 18,
      height: 1.25,
      letterSpacing: -0.3,
      color: kPaper,
    ),
    titleMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 13 : 14,
      height: 1.25,
      letterSpacing: -0.2,
      color: kPaper,
    ),
    titleSmall: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.25,
      letterSpacing: -0.1,
      color: kPaper,
    ),
    bodyLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: compact ? 13 : 14,
      height: 1.4,
      color: kPaper,
    ),
    bodyMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: compact ? 12 : 13,
      height: 1.4,
      color: kPaper,
    ),
    bodySmall: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.35,
      color: kMute,
    ),
    labelLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.2,
      letterSpacing: 0.1,
      color: kPaper,
    ),
    labelMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.3,
      height: 1.2,
      color: kMute,
    ),
    labelSmall: const TextStyle(
      fontFamily: 'Space Mono',
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.2,
      color: kPaper,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kInk,
    canvasColor: kInk,
    cardColor: kCard,
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: kInk,
      foregroundColor: kPaper,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: compact ? 44 : 52,
      titleTextStyle: text.titleMedium,
    ),
    dividerColor: kLine,
    dividerTheme: const DividerThemeData(color: kLine, space: 1, thickness: 1),
    iconTheme: const IconThemeData(color: kPaper, size: 18),
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kLine, width: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF18181B),
      contentTextStyle: text.bodyMedium?.copyWith(color: kPaper),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kLine),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF0F0F12),
      modalBackgroundColor: Color(0xFF0F0F12),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: kLine, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF121215),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kLine, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF121215),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPaper, width: 1.2),
      ),
      labelStyle: text.bodySmall?.copyWith(color: kMute),
      hintStyle: text.bodySmall?.copyWith(color: kSubtle),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        return s.contains(WidgetState.selected) ? kInk : kMute;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        return s.contains(WidgetState.selected) ? kPaper : kLine;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kPaper,
      inactiveTrackColor: kLine,
      thumbColor: kPaper,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      trackHeight: 3,
      overlayColor: const Color(0x22FFFFFF),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPaper,
        minimumSize: const Size(40, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPaper,
        foregroundColor: kInk,
        minimumSize: const Size(44, 38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: kInk),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPaper,
        minimumSize: const Size(44, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: const BorderSide(color: kLine, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
  );
}

Color statusColor(HitStatus status) {
  switch (status) {
    case HitStatus.ok:
      return kOk;
    case HitStatus.timeout:
      return kTo;
    case HitStatus.fail:
      return kFail;
    case HitStatus.checking:
      return kLive;
    case HitStatus.idle:
      return kMute;
  }
}
