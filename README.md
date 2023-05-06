# Clever Settings

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]
![Coverage](https://raw.githubusercontent.com/RoundedInfinity/clever_settings/fddb130e811980659044ae1b3bb86fed38f2f866/coverage_badge.svg)

Clever Settings is a Dart package that provides an easy way to manage and store settings for your application. It uses Hive, a lightweight and fast key-value store, to persist the settings data.

## Installation 💻

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  clever_settings: ^[version]
  # When using flutter (optional)
  clever_settings_flutter: ^[version]
```

Install it:

```sh
dart pub get
```

---

## Initialization 🚀

Before you can start using Clever Settings, you need to initialize [Hive](https://docs.hivedb.dev/#/README?id=initialize) first by calling `Hive.init` (or `Hive.initFlutter`). Call the open function once at the start of your application:

```dart
// Initialize Hive before this
await CleverSettings.open();
```

Alternatively, when using [clever_settings_flutter](https://pub.dev/packages/clever_settings_flutter), you can just call:

```dart
await CleverSettingsFlutter.init();
```

## Usage 💡

Clever Settings provides multiple classes for managing settings. SettingsValue is used for storing primitive types like bool, int, String, etc. SerializableSettingsValue is used for storing complex objects that can be serialized to and from JSON.

> For additional flutter features, see [clever_settings_flutter](https://pub.dev/packages/clever_settings_flutter).

### Example

```dart
class Settings {
  const Settings._();

  /// A settings value that uses a bool value
  static const darkMode =
      SettingsValue<bool>(name: 'darkMode', defaultValue: false);
}

...

void myMethod() {
  // This is automatically saved to disk.
  Settings.darkMode.value = true;

  // Get the value. 
  final darkModeEnabled = Settings.darkMode.value;
}
```

### SettingsValue

To create a new `SettingsValue`, simply provide a unique name for the setting and an optional default value:

```dart
final mySetting = SettingsValue<bool>(name: 'mySetting', defaultValue: true);
```

You can then get or set the value of the setting. This automatically stores the setting to storage:

```dart
final currentValue = mySetting.value;
mySetting.value = false;
```

You can also listen to changes to the setting by calling the `watch` function:

```dart
final stream = mySetting.watch();
stream.listen((newValue) {
  // do something with the new value
});
```

### SerializableSettingsValue

`SerializableSettingsValue` works the same way as `SettingsValue`, but you also need to provide `fromJson` and `toJson` functions to serialize and deserialize the value:

```dart
final myObjectSetting = SerializableSettingsValue<MyObject>(
  name: 'myObjectSetting',
  fromJson: (json) => MyObject.fromJson(json),
  toJson: (object) => object.toJson(),
);
```

### DefaultSettingsValue

DefaultSettingsValue is a subclass of SettingsValue that provides a default value if no value is specified by the user. The value stored in this class is guaranteed to be non-null.

```dart
final setting = SettingsValue<int>(name: 'setting', defaultValue: 34);
final defaultSetting = DefaultSettingsValue<int>(name: 'default', defaultValue: 16);

// This value is of type int? even though it has a default value.
final value = setting.value;

// This value is of type int and not nullable.
final otherValue = defaultSetting.value;
```

## License

This package is released under the MIT License. See LICENSE for more information.

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
