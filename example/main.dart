// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:clever_settings/clever_settings.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class Settings {
  const Settings._();

  /// A settings value that uses a bool value
  static const darkMode =
      SettingsValue<bool>(name: 'darkMode', defaultValue: false);

  /// A settings that contains a complex object
  static final user = SerializableSettingsValue<User>(
    name: 'user',
    fromJson: User.fromJson,
    toJson: (value) => value.toJson(),
    defaultValue: const User(name: 'John Pork', age: 27),
  );
}

void main(List<String> args) async {
  // init hive to store data. With flutter use Hive.initFlutter
  final path = Directory.current.path;
  Hive.init(path);

  await CleverSettings.open();

  print('Is dark mode on? ${Settings.darkMode.value}');

  // This is automatically saved to disk.
  Settings.darkMode.value = true;

  print('The user is ${Settings.user.value}');

  // This is also stored across restarts.
  Settings.user.value = const User(name: 'John Doe', age: 22);
}

/// A complex object that can be converted to json.
///
/// This should have equality when using the `.watch` method on a setting.
@immutable
class User {
  const User({
    required this.name,
    required this.age,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
    );
  }

  final String name;
  final int age;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User && other.name == name && other.age == age;
  }

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
