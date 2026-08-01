import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final Widget? icon;
  final Widget title;
  final Widget subTitle;
  final Widget? trailing;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const CustomListTile({
    this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 15),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      child: title,
                    ),
                    const SizedBox(height: 5),
                    subTitle,
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
