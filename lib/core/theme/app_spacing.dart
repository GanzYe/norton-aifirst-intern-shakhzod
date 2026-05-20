import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screenContent = EdgeInsets.fromLTRB(lg, xs, lg, 0);

  static const EdgeInsets resultSection = EdgeInsets.fromLTRB(lg, xs, lg, xxl);

  static const EdgeInsets inputContent = EdgeInsets.all(md);

  static const EdgeInsets card = EdgeInsets.all(lg);

  static const EdgeInsets riskBadge = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  static const EdgeInsets exampleTile = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: sm,
  );

  static const EdgeInsets exampleItemBottom = EdgeInsets.only(bottom: xs);

  static const double splashFooterBottom = xxl;

  // MessageInputField internal layout.
  static const EdgeInsets inputFieldText = EdgeInsets.fromLTRB(md, md, md, xs);
  static const EdgeInsets inputFieldActions = EdgeInsets.fromLTRB(
    sm,
    0,
    sm,
    sm,
  );
  static const EdgeInsets inputInlineButton = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 0,
  );
  static const double inputActionsGap = xs;

  // AnalysisLoadingIndicator layout.
  static const EdgeInsets loaderContent = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );
  static const double loaderTitleTop = md;
  static const double loaderSubtitleTop = xs;
  static const double loaderDotsTop = md;
  static const double loaderDotsGap = xs;
}
