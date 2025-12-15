import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color icon;
  final Color navBackground;
  final Color navBorder;
  final Color navText;
  final Color storyGradientStart;
  final Color storyGradientEnd;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.navBackground,
    required this.navBorder,
    required this.navText,
    required this.storyGradientStart,
    required this.storyGradientEnd,
  });

  static const light = AppPalette(
    background: Color(0xFFF5F5F7),
    surface: Colors.white,
    card: Colors.white,
    cardBorder: Color(0xFFE0E0E5),
    textPrimary: Colors.black,
    textSecondary: Color(0xFF4A4A4A),
    icon: Colors.black54,
    navBackground: Colors.white,
    navBorder: Color(0xFFE1E1E6),
    navText: Colors.black87,
    storyGradientStart: Color(0xFFF5F5F7),
    storyGradientEnd: Color(0xFFE0E0E5),
  );

  static const dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF111111),
    card: Color(0xFF161616),
    cardBorder: Color(0xFF1F1F1F),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    icon: Colors.white70,
    navBackground: Color(0xFF0F0F0F),
    navBorder: Color(0x33FFFFFF),
    navText: Colors.white70,
    storyGradientStart: Color(0xFF111111),
    storyGradientEnd: Color(0xFF0A0A0A),
  );

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? icon,
    Color? navBackground,
    Color? navBorder,
    Color? navText,
    Color? storyGradientStart,
    Color? storyGradientEnd,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      icon: icon ?? this.icon,
      navBackground: navBackground ?? this.navBackground,
      navBorder: navBorder ?? this.navBorder,
      navText: navText ?? this.navText,
      storyGradientStart: storyGradientStart ?? this.storyGradientStart,
      storyGradientEnd: storyGradientEnd ?? this.storyGradientEnd,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(
      ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navText: Color.lerp(navText, other.navText, t)!,
      storyGradientStart:
          Color.lerp(storyGradientStart, other.storyGradientStart, t)!,
      storyGradientEnd:
          Color.lerp(storyGradientEnd, other.storyGradientEnd, t)!,
    );
  }
}
