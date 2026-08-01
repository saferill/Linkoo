import 'package:flutter/material.dart';

class LinkoLogo extends StatelessWidget {
  final bool withText;

  const LinkoLogo({required this.withText});

  @override
  Widget build(BuildContext context) {
    if (withText) {
      return Image.asset(
        'assets/img/logo-full.png',
        height: 80,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else {
      return Image.asset(
        'assets/img/logo-512.png',
        width: 160,
        height: 160,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
  }
}
