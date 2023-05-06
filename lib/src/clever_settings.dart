// ignore_for_file: comment_references, lines_longer_than_80_chars

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
  CleverSettings._(); // coverage:ignore-line

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

  /// Resets the value of this [SettingsValue] to its default value.
  ///
  /// This sets the current value to the [defaultValue] specified
  /// when the instance was created.
  ///
  /// If no [defaultValue] was specified, the value of the [SettingsValue]
  /// will be set to null.
  void reset() {
    value = defaultValue;
  }

  /// Watches this [SettingsValue] for changes.
  Stream<T?> watch() {
    final stream = _box.watch(key: name);

    final transformer = StreamTransformer<BoxEvent, T?>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data.value as T?);
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

  T? _convertFromJson(dynamic data) {
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
  T? get value {
    final data = _box.get(name);

    return _convertFromJson(data);
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

  @override
  Stream<T?> watch() {
    final stream = _box.watch(key: name);

    final transformer = StreamTransformer<BoxEvent, T?>.fromHandlers(
      handleData: (data, sink) {
        sink.add(_convertFromJson(data.value));
      },
      handleDone: (sink) {
        sink.close();
      },
    );

    return stream.transform(transformer);
  }
}

/// {@template default_settings_value}
/// A settings value that provides a default value
/// if no value is specified by the user.
///
///The value stored in this class is guaranteed to be non-null.
///
/// Example:
/// ```
/// final setting = SettingsValue<int>(name: 'setting', defaultValue: 34);
/// final defaultSetting = DefaultSettingsValue<int>(name: 'default', defaultValue: 16);
///
/// // This value is of type int? even though it has a default value.
/// final value = setting.value;
///
/// // This value is of type int and not nullable.
/// final otherValue = defaultSetting.value;
///
/// ```
/// {@endtemplate}
class DefaultSettingsValue<T> extends SettingsValue<T> {
  /// {@macro default_settings_value}
  DefaultSettingsValue({required super.name, required T super.defaultValue});

  @override
  T get value => super.value!;

  /// Set the value stored for [name].
  ///
  /// When value is `null`, the settings' value is set to [defaultValue].
  @override
  set value(T? value) {
    super.value = value ?? defaultValue!;
  }
}
