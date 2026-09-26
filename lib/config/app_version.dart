/// Shown on the brand splash. Must equal the `version:` name in pubspec.yaml
/// (`test/brand_splash_test.dart` fails the build when they drift) — a const
/// here avoids adding a package just to read our own version at startup.
const kAppVersion = '1.0.0';
