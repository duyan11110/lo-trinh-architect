// Responsive classes — docs/05 §9. One widget tree; screens branch on the
// window width at three places (shell, S3, S4) plus S1/S2 (docs/05 S1, S2).
import 'package:flutter/widgets.dart';

import 'theme/tokens.dart';

/// docs/05 §9 width classes.
enum LtaLayout {
  /// < 600: bottom nav, one column, margin 20.
  compact,

  /// 600–899: bottom nav, one column centred.
  medium,

  /// 900–1099: nav rail, two columns.
  rail,

  /// ≥ 1100: nav rail, S3 adds the meta column.
  wide;

  static LtaLayout ofWidth(double w) => w >= LtaBreakpoint.wide
      ? wide
      : w >= LtaBreakpoint.rail
      ? rail
      : w >= LtaBreakpoint.medium
      ? medium
      : compact;

  /// From the window width (not the pane), so every screen agrees.
  static LtaLayout of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  /// Nav rail + two-column layouts (≥ 900).
  bool get twoColumn => index >= rail.index;

  /// Content margin (docs/05 §5.3: 20 mobile, 32 web).
  double get margin => twoColumn ? LtaSpace.contentWeb : LtaSpace.contentMobile;
}
