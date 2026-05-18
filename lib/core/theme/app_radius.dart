import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 24;

  static final BorderRadius xsAll = BorderRadius.circular(xs);
  static final BorderRadius smAll = BorderRadius.circular(sm);
  static final BorderRadius mdAll = BorderRadius.circular(md);
  static final BorderRadius lgAll = BorderRadius.circular(lg);
  static final BorderRadius pillAll = BorderRadius.circular(pill);
}
