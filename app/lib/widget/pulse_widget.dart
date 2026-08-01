import 'package:flutter/material.dart';

/// A smooth, elegant breathing / pulse animation widget.
/// Ideal for branding logos, radar indicators, and scanning elements.
class PulseWidget extends StatefulWidget {
  final Widget child;
  final bool active;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseWidget({
    required this.child,
    this.active = true,
    this.duration = const Duration(milliseconds: 2400),
    this.minScale = 0.97,
    this.maxScale = 1.05,
    super.key,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
