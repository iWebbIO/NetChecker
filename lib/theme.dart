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

const Color kInk = Color(0xFF030005);
const Color kPaper = Color(0xFFD1D1D1);
const Color kMute = Color(0xFF8C8C8C);
const Color kLine = Color(0xFF242428);
const Color kOk = Color(0xFF7EBA88);
const Color kTo = Color(0xFFC4A35A);
const Color kFail = Color(0xFFC45C5C);
const Color kLive = Color(0xFFF2F2F2);
const Color kPoison = Color(0xFFFFD600);

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
    surfaceContainerHighest: Color(0xFF0C0A10),
    surfaceContainerHigh: Color(0xFF09070C),
    surfaceContainer: Color(0xFF07050A),
    surfaceContainerLow: Color(0xFF050308),
  );

  final text = TextTheme(
    displayLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 22 : 28,
      height: 1.1,
      color: kPaper,
    ),
    titleLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: compact ? 15 : 18,
      height: 1.2,
      color: kPaper,
    ),
    titleMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: compact ? 13 : 14,
      height: 1.2,
      color: kPaper,
    ),
    titleSmall: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.2,
      color: kPaper,
    ),
    bodyLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: compact ? 13 : 14,
      height: 1.35,
      color: kPaper,
    ),
    bodyMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: compact ? 12 : 13,
      height: 1.35,
      color: kPaper,
    ),
    bodySmall: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.3,
      color: kMute,
    ),
    labelLarge: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.2,
      color: kPaper,
    ),
    labelMedium: TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.04,
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
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: kInk,
      foregroundColor: kPaper,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: compact ? 40 : 48,
      titleTextStyle: text.titleMedium,
    ),
    dividerColor: kLine,
    dividerTheme: const DividerThemeData(color: kLine, space: 1, thickness: 1),
    iconTheme: const IconThemeData(color: kPaper, size: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: text.bodyMedium,
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF0C0A10),
      modalBackgroundColor: Color(0xFF0C0A10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: false,
      border: const UnderlineInputBorder(borderSide: BorderSide(color: kLine)),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kLine),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kPaper),
      ),
      labelStyle: text.bodySmall,
      hintStyle: text.bodySmall,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        return s.contains(WidgetState.selected) ? kInk : kMute;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        return s.contains(WidgetState.selected) ? kPaper : kLine;
      }),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: kPaper,
      inactiveTrackColor: kLine,
      thumbColor: kPaper,
      overlayColor: Color(0x22FFFFFF),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPaper,
        minimumSize: const Size(48, 48),
        textStyle: text.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPaper,
        foregroundColor: kInk,
        minimumSize: const Size(48, 40),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPaper,
        minimumSize: const Size(48, 40),
        side: const BorderSide(color: kPaper),
        shape: const StadiumBorder(),
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
