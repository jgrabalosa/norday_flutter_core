import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/version_core.dart';

/// `versionCore` tiene que ser la `version:` del `pubspec.yaml`. Si se sube
/// una y no la otra, el backend daría o quitaría prendas a quien no toca.
void main() {
  test('versionCore es la versión del pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final linea = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(linea, isNotNull, reason: 'el pubspec.yaml no tiene version:');
    final version = linea!.group(1)!.split('+').first;

    expect(versionCore, version);
  });
}
