import 'package:flutter/material.dart';

/// Navigation transition configuration replacing RouterinoTransition
class RouterinoTransition {
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)? transitionBuilder;
  final Duration duration;

  const RouterinoTransition({this.transitionBuilder, this.duration = const Duration(milliseconds: 300)});

  static const RouterinoTransition none = RouterinoTransition(duration: Duration.zero);
  static const RouterinoTransition noTransition = RouterinoTransition(duration: Duration.zero);
  static const RouterinoTransition fade = RouterinoTransition(transitionBuilder: _fadeTransition, duration: Duration(milliseconds: 250));
  static const RouterinoTransition slide = RouterinoTransition(transitionBuilder: _slideTransition, duration: Duration(milliseconds: 300));
  static const RouterinoTransition cupertino = RouterinoTransition(duration: Duration(milliseconds: 300));
  static const RouterinoTransition material = RouterinoTransition(duration: Duration(milliseconds: 300));
  static const RouterinoTransition bottomSheet = RouterinoTransition(duration: Duration(milliseconds: 300));

  RouterinoTransition call() => this;

  static Widget _fadeTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Widget _slideTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
      child: child,
    );
  }
}

/// Global Navigation Manager replacing Routerino
class AppNavigator {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static RouterinoTransition transition = RouterinoTransition.noTransition;

  static BuildContext? get currentContext => navigatorKey.currentContext;
  static BuildContext get context => navigatorKey.currentContext!;

  static Route<T> _createRoute<T>(Widget Function() builder, {bool fullscreenDialog = false, RouterinoTransition? transition}) {
    final t = transition ?? AppNavigator.transition;
    if (t.transitionBuilder != null) {
      return PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionsBuilder: t.transitionBuilder!,
        transitionDuration: t.duration,
        fullscreenDialog: fullscreenDialog,
      );
    } else if (t.duration == Duration.zero) {
      return PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPageRoute<T>(
      builder: (_) => builder(),
      fullscreenDialog: fullscreenDialog,
    );
  }

  static Future<T?> push<T>(Widget Function() builder, {bool fullscreenDialog = false, RouterinoTransition? transition}) {
    return navigatorKey.currentState!.push<T>(_createRoute<T>(builder, fullscreenDialog: fullscreenDialog, transition: transition));
  }

  static Future<T?> pushRoot<T>(Widget Function() builder, {RouterinoTransition? transition}) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      _createRoute<T>(builder, transition: transition),
      (route) => false,
    );
  }

  static Future<T?> pushRootImmediately<T>(Widget Function() builder) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  static Future<T?> pushImmediately<T>(Widget Function() builder) {
    return navigatorKey.currentState!.push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>({
    required dynamic removeUntil,
    required Widget Function() builder,
    RouterinoTransition? transition,
  }) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      _createRoute<T>(builder, transition: transition),
      _createPredicate(removeUntil),
    );
  }

  static Future<T?> pushAndRemoveUntilImmediately<T>({
    required dynamic removeUntil,
    required Widget Function() builder,
  }) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
      _createPredicate(removeUntil),
    );
  }

  static Future<T?> pushBottomSheet<T>(Widget Function() builder) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return Future.value(null);
    return showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => builder(),
    );
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  static void popUntil(dynamic target) {
    navigatorKey.currentState!.popUntil(_createPredicate(target));
  }

  static void popUntilRoot() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  static bool Function(Route<dynamic>) _createPredicate(dynamic target) {
    if (target is bool Function(Route<dynamic>)) {
      return target;
    } else if (target is Type) {
      return (route) => route.settings.name == target.toString() || route is MaterialPageRoute;
    }
    return (route) => route.isFirst;
  }
}

// Global alias for compatibility
typedef Routerino = AppNavigator;

/// Standard bottom sheet modal widget replacing RouterinoBottomSheet
class RouterinoBottomSheet extends StatelessWidget {
  final String title;
  final String? description;
  final Color? backgroundColor;
  final double borderRadius;
  final Widget child;

  const RouterinoBottomSheet({
    super.key,
    required this.title,
    this.description,
    this.backgroundColor,
    this.borderRadius = 20,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(description!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Standard home wrapper widget replacing RouterinoHome
class RouterinoHome extends StatelessWidget {
  final Widget Function() builder;

  const RouterinoHome({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}

/// Extension on BuildContext for standard Flutter navigation
extension BuildContextNavigationExtension on BuildContext {
  Future<T?> push<T>(Widget Function() builder, {bool fullscreenDialog = false, RouterinoTransition? transition}) {
    return Navigator.of(this).push<T>(
      AppNavigator._createRoute<T>(builder, fullscreenDialog: fullscreenDialog, transition: transition),
    );
  }

  Future<T?> pushImmediately<T>(Widget Function() builder) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<T?> pushRoot<T>(Widget Function() builder, {RouterinoTransition? transition}) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      AppNavigator._createRoute<T>(builder, transition: transition),
      (route) => false,
    );
  }

  Future<T?> pushRootImmediately<T>(Widget Function() builder) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  Future<T?> pushAndRemoveUntil<T>({
    required dynamic removeUntil,
    required Widget Function() builder,
    RouterinoTransition? transition,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      AppNavigator._createRoute<T>(builder, transition: transition),
      AppNavigator._createPredicate(removeUntil),
    );
  }

  Future<T?> pushAndRemoveUntilImmediately<T>({
    required dynamic removeUntil,
    required Widget Function() builder,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: Duration.zero,
      ),
      AppNavigator._createPredicate(removeUntil),
    );
  }

  Future<T?> pushBottomSheet<T>(Widget Function() builder) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => builder(),
    );
  }

  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  void popUntil(dynamic target) {
    Navigator.of(this).popUntil(AppNavigator._createPredicate(target));
  }

  void popUntilRoot() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }
}
