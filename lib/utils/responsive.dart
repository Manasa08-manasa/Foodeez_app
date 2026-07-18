import 'package:flutter/material.dart';

/// Layout breakpoints for phones and tablets.
class AppBreakpoints {
  static const compact = 360.0;
  static const medium = 600.0;
  static const expanded = 900.0;
}

/// Screen-size helpers shared across the partner app.
class AppResponsive {
  AppResponsive._(this.context, this.size);

  final BuildContext context;
  final Size size;

  factory AppResponsive.of(BuildContext context) {
    return AppResponsive._(context, MediaQuery.sizeOf(context));
  }

  double get width => size.width;
  bool get isCompact => width < AppBreakpoints.compact;
  bool get isTablet => width >= AppBreakpoints.medium;
  bool get isWide => width >= AppBreakpoints.expanded;

  /// Readable content width on tablets; full bleed on phones.
  double get contentMaxWidth {
    if (isWide) return 840;
    if (isTablet) return 720;
    return double.infinity;
  }

  /// Bottom sheets / alerts — capped on tablet so they don't stretch edge-to-edge.
  double get sheetMaxWidth => isTablet ? 520 : double.infinity;

  /// Floating dock width — centered pill on tablet.
  double get dockMaxWidth {
    if (isWide) return 560;
    if (isTablet) return 480;
    return double.infinity;
  }

  double get pageHPad => isTablet ? 28 : 20;

  /// Clearance under scroll content for the floating dock + system nav.
  double dockClearance({bool showDock = true}) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    if (!showDock) return 28 + bottomInset;
    return 118 + bottomInset;
  }

  int gridColumns({int phone = 2, int tablet = 3, int wide = 4}) {
    if (isWide) return wide;
    if (isTablet) return tablet;
    return phone;
  }

  EdgeInsets scrollPadding({bool showDock = true, double? horizontal}) {
    final h = horizontal ?? pageHPad;
    return EdgeInsets.fromLTRB(h, 4, h, dockClearance(showDock: showDock));
  }

  /// Safe bottom padding for sticky footers / sheets.
  double safeBottom({double extra = 20}) =>
      extra + MediaQuery.viewPaddingOf(context).bottom;
}

/// Centers [child] and constrains width on tablets.
class AdaptiveContentWidth extends StatelessWidget {
  const AdaptiveContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final max = maxWidth ?? AppResponsive.of(context).contentMaxWidth;
    if (!max.isFinite) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
