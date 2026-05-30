import 'package:flutter/material.dart';

abstract class AppColors {
  // === Nền ===
  static const background     = Color(0xFF0D0D1A);  // Deep dark
  static const surface        = Color(0xFF1A1A2E);  // Elevated dark
  static const surfaceLight   = Color(0xFF252542);  // Cards, modals

  // === Chủ đạo ===
  static const primary        = Color(0xFF7C3AED);  // Vivid purple
  static const primaryLight   = Color(0xFF9F67FF);  // Hover state
  static const accent         = Color(0xFFF472B6);  // Warm pink

  // === Text ===
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFB0B0C8);
  static const textMuted      = Color(0xFF6B6B8A);

  // === Trạng thái ===
  static const success        = Color(0xFF10B981);
  static const error          = Color(0xFFEF4444);
  static const warning        = Color(0xFFF59E0B);

  // === TV Specific ===
  static const tvFocusBorder  = Color(0xFFFFFFFF);  // Viền trắng khi D-pad focus
  static const tvFocusGlow    = Color(0x337C3AED);  // Glow tím nhẹ
}
