enum Flavor { staging, production }

class FlavorConfig {
  FlavorConfig._();

  static Flavor? _flavor;

  static void initialize(Flavor flavor) {
    _flavor = flavor;
  }

  static Flavor get flavor {
    assert(_flavor != null, 'FlavorConfig must be initialized before use.');
    return _flavor!;
  }

  static bool get isStaging => flavor == Flavor.staging;
  static bool get isProduction => flavor == Flavor.production;

  static String get name {
    switch (flavor) {
      case Flavor.staging:
        return 'Staging';
      case Flavor.production:
        return 'Production';
    }
  }

  static String get envFileName {
    switch (flavor) {
      case Flavor.staging:
        return '.env.staging';
      case Flavor.production:
        return '.env.production';
    }
  }

  /// Banner color shown in debug overlay (staging only)
  static String get bannerText => isStaging ? 'STAGING' : '';
}
