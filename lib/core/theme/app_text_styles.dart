import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base =>
      GoogleFonts.plusJakartaSans(color: AppColors.textPrimary);

  static TextStyle get display => _base.copyWith(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.75,
  );

  static TextStyle get title => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static TextStyle get body => _base.copyWith(
    fontSize: 15,
    height: 1.55,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get heading => _base.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  static TextStyle get label => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textLabel,
  );

  static TextStyle get small =>
      _base.copyWith(fontSize: 13, height: 1.5, color: AppColors.textSecondary);

  static TextStyle get input => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.7,
  );

  static TextStyle get fieldValue =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  static TextStyle get cardTitle =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700);

  static TextStyle get caption =>
      _base.copyWith(fontSize: 12, color: AppColors.textSecondary);
}
