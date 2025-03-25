import 'package:flutter/material.dart';

class AuthColors {
  final Color scaffoldBg;
  final Color labelColor;
  final Color iconColor;
  final Color borderColor;
  final Color focusBorderColor;
  final Color hintColor;
  final Color buttonColor;
  final Color cursorColor;

  const AuthColors({
    required this.scaffoldBg,
    required this.labelColor,
    required this.iconColor,
    required this.borderColor,
    required this.focusBorderColor,
    required this.hintColor,
    required this.buttonColor,
    required this.cursorColor,
  });

  /// Skema warna untuk Light Theme
  factory AuthColors.light() {
    return AuthColors(
      scaffoldBg: Colors.white,
      labelColor: Colors.black87,
      iconColor: Colors.grey.shade600,
      borderColor: Colors.grey.shade400,
      focusBorderColor: Colors.orangeAccent,
      hintColor: Colors.grey.shade400,
      buttonColor: Colors.orangeAccent,
      cursorColor: Colors.orangeAccent,
    );
  }

  /// Skema warna untuk Dark Theme
  factory AuthColors.dark() {
    return AuthColors(
      scaffoldBg: Colors.black,
      labelColor: Colors.white70,
      iconColor: Colors.white70,
      borderColor: Colors.grey.shade600,
      focusBorderColor: Colors.deepOrangeAccent,
      hintColor: Colors.white54,
      buttonColor: Colors.deepOrange,
      cursorColor: Colors.deepOrangeAccent,
    );
  }
}
