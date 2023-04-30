// ignore_for_file: comment_references

import 'dart:async';
import 'dart:convert';

import 'package:clever_logger/clever_logger.dart';
import 'package:hive/hive.dart';

final _logger = CleverLogger(
  'Settings',
  shouldLog: CleverSettings.logging,
  logActions: [const ColorfulPrintAction(printer: EmojiPrinter())],
);

/// Constant value used for the settings box in Hive.
///
/// All settings are stored in this box.
const kSettingsBox = 'clever_settings';

/// Static class for functions to control settings
///
/// See also:
/// - [SettingsValue] to store and retrieve settings.
/// - [SerializableSettingsValue] to use complex object as your settings.
class CleverSettings {
  CleverSettings._();

  /// Loads the storage in which the settings are saved.
  ///
  /// Should be called once before the app starts
  /// (typically in the main function).
  static Future<void> open() async {
    await Hive.openBox<dynamic>(kSettingsBox);
  }

  /// Enables logging for settings.
  static bool logging = true;

  /// Deletes all stored values for settings.
  static Future<void> resetSettings() async {
    await Hive.box<dynamic>(kSettingsBox).clear();
  }
}

/// {@template settings_value}
/// [SettingsValue] is a generic class that represents
/// a setting in an application.
///
/// It allows you to store and retrieve values
/// for a specific setting by its unique name.
///
/// You can store all primitive types: [List], [Map], [DateTime],
/// [BigInt] and [Uint8List].
/// To store other types, see [SerializableSettingsValue].
///
/// Example usage:
/// ```dart
/// final mySetting = SettingsValue<bool>(name:'my_setting',defaultValue: true);
/// // Set a new value for my_setting
/// mySetting.value = false;

/// // Retrieve the current value of my_setting
/// final currentValue = mySetting.value;

/// // Watch for changes to my_setting
/// final stream = mySetting.watch();
/// ```
/// {@endtemplate}
class SettingsValue<T> {
  /// Creates a new instance of a SettingsValue
  /// with the specified name and optional default value.
  ///
  /// {@macro settings_value}
  const SettingsValue({required this.name, this.defaultValue});

  /// The unique name of this setting.
  ///
  /// This is used as a key to store your values.
  /// Do not use the same name twice for different settings.
  ///
  /// Multiple [SettingsValue]s with the same name
  /// will return the identical value.
  final String name;

  /// The value that is used by default.
  ///
  /// When this is not set [SettingsValue] returns null.
  ///
  /// Unlike [value], [defaultValue] is not stored in storage
  /// but bound to this object.
  final T? defaultValue;

  /// The box used by this [SettingsValue]
  Box<dynamic> get _box => Hive.box(kSettingsBox);

  /// Get the value stored for [name].
  ///
  /// When no value is stored and [defaultValue] is set,
  /// this returns [defaultValue].
  T? get value {
    return _box.get(name, defaultValue: defaultValue) as T?;
  }

  /// Set the value stored for [name].
  set value(T? value) {
    _logger.logConfig('Setting $name changed to: $value');
    _box.put(name, value);
  }

  /// Watches this [SettingsValue] for changes.
  Stream<T?> watch() {
    final stream = _box.watch(key: name);

    final transformer = StreamTransformer<BoxEvent, T?>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data.value as T?);
      },
      handleError: (error, stackTrace, sink) {
        sink.addError(error);
      },
      handleDone: (sink) {
        sink.close();
      },
    );

    return stream.transform(transformer);
  }
}

/// {@template serializable_settings_value}
/// SerializableSettingsValue allows you to store and retrieve values
/// that can be serialized to and from JSON format.
///
/// See also:
/// - [SettingsValue]
/// {@endtemplate}
class SerializableSettingsValue<T> extends SettingsValue<T> {
  /// Creates a new instance of SerializableSettingsValue
  /// with the specified name, default value, and toJson and fromJson functions.
  ///
  /// {@macro serializable_settings_value}
  const SerializableSettingsValue({
    required super.name,
    required this.fromJson,
    required this.toJson,
    super.defaultValue,
  });

  /// Method that describes how to deserializes Json into an instance of [T].
  final T Function(Map<String, dynamic> json) fromJson;

  /// Method that describes how to serializes the value into Json.
  final Map<String, dynamic> Function(T value) toJson;

  @override
  T? get value {
    final data = _box.get(name);

    if (data == null) {
      return defaultValue;
    }

    assert(
      data is String,
      'Serializable Settings can only be stored as Strings',
    );

    try {
      return fromJson(jsonDecode(data as String) as Map<String, dynamic>);
    } catch (e) {
      _logger.logSevere(e);
      return null;
    }
  }

  @override
  set value(T? value) {
    _logger.logConfig('Setting $name changed to: $value');

    if (value == null) {
      _box.put(name, null);
      return;
    }
    _box.put(name, jsonEncode(toJson(value)));
  }
}
