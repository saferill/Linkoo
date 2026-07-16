import 'dart:async';
import 'package:flutter/widgets.dart';

/// Node for translation overrides (pure Dart)
abstract class Node {}

/// Plural resolver function type
typedef PluralResolver = String Function(num n, {String? zero, String? one, String? two, String? few, String? many, String? other});

/// Base interface for App Locale
mixin BaseAppLocale<E extends Enum, T extends BaseTranslations<E, T>> on Enum {
  String get languageCode;
  String? get scriptCode => null;
  String? get countryCode => null;

  String get languageTag => countryCode != null ? '${languageCode}_$countryCode' : languageCode;

  Locale get flutterLocale => Locale.fromSubtags(
        languageCode: languageCode,
        scriptCode: scriptCode,
        countryCode: countryCode,
      );

  Future<T> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  });
}

/// Translation Metadata for localized classes
class TranslationMetadata<E extends Enum, T extends BaseTranslations<E, T>> {
  final E locale;
  final Map<String, Node>? overrides;
  final PluralResolver? cardinalResolver;
  final PluralResolver? ordinalResolver;

  const TranslationMetadata({
    required this.locale,
    this.overrides,
    this.cardinalResolver,
    this.ordinalResolver,
  });
}

/// Plural Resolvers implementation
class PluralResolvers {
  static PluralResolver cardinal(String language) {
    return (num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
      if (n == 0 && zero != null) return zero;
      if (n == 1 && one != null) return one;
      if (n == 2 && two != null) return two;
      return other ?? (one ?? '');
    };
  }

  static PluralResolver ordinal(String language) {
    return (num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
      if (n == 0 && zero != null) return zero;
      if (n == 1 && one != null) return one;
      if (n == 2 && two != null) return two;
      return other ?? (one ?? '');
    };
  }
}

/// Base interface for Translations
mixin class BaseTranslations<E extends Enum, T extends BaseTranslations<E, T>> {
  Map<String, Node>? get overrides => null;
  PluralResolver? get cardinalResolver => null;
  PluralResolver? get ordinalResolver => null;
}

/// Inherited widget for reactive translations
class InheritedLocaleData<E extends Enum, T extends BaseTranslations<E, T>> extends InheritedWidget {
  final E locale;
  final T translations;

  Locale get flutterLocale => (locale as BaseAppLocale<E, T>).flutterLocale;

  const InheritedLocaleData({
    super.key,
    required this.locale,
    required this.translations,
    required super.child,
  });

  static InheritedLocaleData<E, T> of<E extends Enum, T extends BaseTranslations<E, T>>(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<E, T>>();
    assert(result != null, 'No TranslationProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedLocaleData<E, T> oldWidget) {
    return locale != oldWidget.locale || translations != oldWidget.translations;
  }
}

/// Base provider for wrapping the app
abstract class BaseTranslationProvider<E extends Enum, T extends BaseTranslations<E, T>> extends StatefulWidget {
  final Widget child;
  final BaseFlutterLocaleSettings<E, T> settings;

  const BaseTranslationProvider({
    super.key,
    required this.child,
    required this.settings,
  });

  @override
  State<BaseTranslationProvider<E, T>> createState() => _BaseTranslationProviderState<E, T>();
}

class _BaseTranslationProviderState<E extends Enum, T extends BaseTranslations<E, T>>
    extends State<BaseTranslationProvider<E, T>> {
  late E _locale;
  late T _translations;
  StreamSubscription<E>? _subscription;

  @override
  void initState() {
    super.initState();
    _locale = widget.settings.currentLocaleInternal;
    _translations = widget.settings.currentTranslationsInternal;
    _subscription = widget.settings.getLocaleStreamInternal().listen((newLocale) async {
      final newTranslations = await widget.settings.loadTranslationsInternal(newLocale);
      if (mounted) {
        setState(() {
          _locale = newLocale;
          _translations = newTranslations;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData<E, T>(
      locale: _locale,
      translations: _translations,
      child: widget.child,
    );
  }
}

/// Base Locale Settings
abstract class BaseFlutterLocaleSettings<E extends Enum, T extends BaseTranslations<E, T>> {
  final BaseAppLocaleUtils<E, T> utils;
  final bool lazy;

  E _currentLocale;
  final Map<E, T> _translationMap = {};
  final StreamController<E> _streamController = StreamController<E>.broadcast();

  BaseFlutterLocaleSettings({
    required this.utils,
    required this.lazy,
  }) : _currentLocale = utils.baseLocale;

  E get currentLocaleInternal => _currentLocale;
  T get currentTranslationsInternal => _translationMap[_currentLocale] ?? _getFallbackTranslations();

  Stream<E> getLocaleStreamInternal() => _streamController.stream;

  T _getFallbackTranslations() {
    if (_translationMap.isNotEmpty) {
      return _translationMap.values.first;
    }
    throw StateError('Translations not yet initialized for $_currentLocale');
  }

  T getTranslationsInternal(E locale) {
    return _translationMap[locale] ?? currentTranslationsInternal;
  }

  Future<T> loadTranslationsInternal(E locale) async {
    if (_translationMap.containsKey(locale)) {
      return _translationMap[locale]!;
    }
    final builder = (locale as BaseAppLocale<E, T>);
    final translations = await builder.build();
    _translationMap[locale] = translations;
    return translations;
  }

  Future<E> setLocaleInternal(E locale, {bool? listenToDeviceLocale}) async {
    final translations = await loadTranslationsInternal(locale);
    _currentLocale = locale;
    _translationMap[locale] = translations;
    _streamController.add(locale);
    return locale;
  }

  E setLocaleSyncInternal(E locale, {bool? listenToDeviceLocale}) {
    _currentLocale = locale;
    _streamController.add(locale);
    return locale;
  }

  Future<E> setLocaleRawInternal(String rawLocale, {bool? listenToDeviceLocale}) async {
    final locale = utils.parseLocale(rawLocale);
    return setLocaleInternal(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  E setLocaleRawSyncInternal(String rawLocale, {bool? listenToDeviceLocale}) {
    final locale = utils.parseLocale(rawLocale);
    return setLocaleSyncInternal(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  Future<E> useDeviceLocaleInternal() async {
    final deviceLocale = utils.findDeviceLocaleInternal();
    return setLocaleInternal(deviceLocale);
  }

  E useDeviceLocaleSyncInternal() {
    final deviceLocale = utils.findDeviceLocaleInternal();
    return setLocaleSyncInternal(deviceLocale);
  }

  Future<void> setPluralResolverInternal({
    String? language,
    E? locale,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {}

  void setPluralResolverSyncInternal({
    String? language,
    E? locale,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {}
}

/// Base App Locale Utils
abstract class BaseAppLocaleUtils<E extends Enum, T extends BaseTranslations<E, T>> {
  final E baseLocale;
  final List<E> locales;

  BaseAppLocaleUtils({
    required this.baseLocale,
    required this.locales,
  });

  E parseLocale(String rawLocale) {
    final normalized = rawLocale.replaceAll('-', '_').toLowerCase();
    for (final loc in locales) {
      final bl = loc as BaseAppLocale<E, T>;
      final code = bl.countryCode != null ? '${bl.languageCode}_${bl.countryCode}'.toLowerCase() : bl.languageCode.toLowerCase();
      if (code == normalized || bl.languageCode.toLowerCase() == normalized) {
        return loc;
      }
    }
    return baseLocale;
  }

  E parseLocalePartsInternal({required String languageCode, String? scriptCode, String? countryCode}) {
    return parseLocale(countryCode != null ? '${languageCode}_$countryCode' : languageCode);
  }

  E findDeviceLocaleInternal() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return parseLocale(systemLocale.countryCode != null ? '${systemLocale.languageCode}_${systemLocale.countryCode}' : systemLocale.languageCode);
  }
}
