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

  // Incognito mode switch row.
  static const EdgeInsets incognitoSwitchPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // Pipeline log entry tile.
  static const EdgeInsets pipelineLogTile = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );

  static const EdgeInsets pipelineLogTagChip = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 2,
  );

  static const EdgeInsets pipelineLogExpandTap = EdgeInsets.symmetric(
    vertical: 2,
  );

  // Message input field action rows.
  static const EdgeInsets inputActionRow = EdgeInsets.symmetric(
    horizontal: xs,
    vertical: xs,
  );

  static const EdgeInsets inputActionRowCompact = EdgeInsets.symmetric(
    horizontal: xs,
    vertical: 6,
  );

  static const EdgeInsets inputIconTap = EdgeInsets.all(2);
}
