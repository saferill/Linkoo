import 'package:flutter/material.dart';
import 'package:linko_app/widget/responsive_builder.dart';

class BigButton extends StatelessWidget {
  static const double desktopWidth = 100.0;
  static const double mobileWidth = 90.0;

  final IconData icon;
  final String label;
  final bool filled;
  final double? width;
  final VoidCallback onTap;

  const BigButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizingInformation = SizingInformation(MediaQuery.sizeOf(context).width);
    final buttonWidth = width ?? (sizingInformation.isDesktop ? desktopWidth : mobileWidth);
    return SizedBox(
      width: buttonWidth,
      height: 68.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: filled ? 2 : 0,
          backgroundColor: filled
              ? colorScheme.primary
              : (colorScheme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainerLow),
          foregroundColor: filled
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: filled
                ? BorderSide.none
                : BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
          ),
          padding: const EdgeInsets.only(left: 4, right: 4, top: 10, bottom: 8),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon),
            FittedBox(
              alignment: Alignment.bottomCenter,
              child: Text(label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
