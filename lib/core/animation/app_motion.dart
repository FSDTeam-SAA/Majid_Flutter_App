import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 620);
  static const Duration route = Duration(milliseconds: 480);
  static const Duration splash = Duration(milliseconds: 2600);
  static const Duration stagger = Duration(milliseconds: 90);

  static const Curve easeOutExpo = Curves.easeOutExpo;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}
