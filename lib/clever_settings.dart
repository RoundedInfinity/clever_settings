/// Clever Settings is a Dart package that provides an easy way to manage
/// and store settings for your application.
///
/// It uses Hive, a lightweight and fast key-value store,
/// to persist the settings data.
///
/// Example:
///
///```dart
/// // init hive to store data. With flutter use Hive.initFlutter
/// final path = Directory.current.path;
/// Hive.init(path);
///
/// await CleverSettings.open();
///
/// print('Is dark mode on? ${Settings.darkMode.value}');
///
/// // This is automatically saved to disk.
/// Settings.darkMode.value = true;
///
/// print('The user is ${Settings.user.value}');
///
/// // This is also stored across restarts.
/// Settings.user.value = User(name: 'John Doe', age: 22);
///```
library clever_settings;

export 'src/clever_settings.dart';
