import 'package:flutter/material.dart';
import 'package:bitebuddy/theme/duotone_theme.dart';

class DuotoneCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? elevation;
  final bool hasBorder;
  final Color? borderColor;
  final Color? shadowColor;

  const DuotoneCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.hasBorder = false,
    this.borderColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        elevation: elevation ?? (isDark ? 0 : DuotoneTheme.elevationSm),
        shadowColor: shadowColor ?? (isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.1)),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(DuotoneTheme.radiusMd),
          side: hasBorder ? BorderSide(
            color: borderColor ?? (isDark
                ? Colors.grey.shade800
                : Colors.grey.shade300),
            width: 1,
          ) : BorderSide.none,
        ),
        color: backgroundColor ?? theme.cardColor,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

