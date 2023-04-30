// ignore_for_file: prefer_const_constructors, cascade_invocations, inference_failure_on_function_invocation, unawaited_futures
import 'dart:async';
import 'dart:io';

import 'package:clever_settings/clever_settings.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    final path = Directory.current.path;
    Hive.init(path);
    await Hive.deleteFromDisk();
    await CleverSettings.open();
  });
  group('CleverSettings', () {
    test('value is null after load', () {
      final setting = SettingsValue<bool>(name: 'bool_setting');
      expect(setting.value, isNull);
    });

    test('defaultValue is null after load', () {
      final setting = SettingsValue<bool>(name: 'bool_setting');
      expect(setting.defaultValue, isNull);
    });

    test('settings a value to true', () {
      final setting = SettingsValue<bool>(name: 'bool_setting')..value = true;

      expect(setting.value, equals(true));
    });

    test('settings a value to false', () {
      final setting = SettingsValue<bool>(name: 'bool_setting')..value = false;

      expect(setting.value, equals(false));
    });

    test('using default value', () {
      final setting =
          SettingsValue<String>(name: 'string_setting', defaultValue: 'hey');

      expect(setting.value, equals('hey'));
    });

    test('using same settings object value', () {
      final setting = SettingsValue<String>(name: 'some_value');
      final otherSetting = SettingsValue<String>(name: 'some_value');

      setting.value = 'hello';

      expect(setting.value, equals(otherSetting.value));
    });

    test('watch a setting', () async {
      final setting =
          SettingsValue<int>(name: 'streamed_setting', defaultValue: 0);

      final stream = setting.watch();

      expectLater(stream, emitsInOrder([1, 2, 3]));

      await Future<void>.delayed(Duration.zero);

      setting.value = 1;
      await Future<void>.delayed(Duration.zero);
      setting.value = 2;
      await Future<void>.delayed(Duration.zero);
      setting.value = 3;

      Hive.box(kSettingsBox).close();
    });

    test('watch a setting with null value', () async {
      final setting =
          SettingsValue<int>(name: 'streamed_setting', defaultValue: 0);

      final stream = setting.watch();

      expectLater(stream, emitsInOrder([null]));

      await Future<void>.delayed(Duration.zero);

      setting.value = null;

      unawaited(Hive.box(kSettingsBox).close());
    });

    test('serializable value', () {
      final setting = SerializableSettingsValue<User>(
        name: 'user',
        fromJson: User.fromJson,
        toJson: (value) => value.toJson(),
      );
      setting.value = User(name: 'John Pork', age: 27);

      expect(setting.value, isA<User>());
    });
  });
}

class User {
  User({
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
}
