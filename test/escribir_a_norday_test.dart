import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/escribir_a_norday.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uri? abierto;

  setUp(() {
    abierto = null;
    infoAppCorreo = () async => (app: 'Norday Habits', version: '1.4.0+57');
    sistemaCorreo = () => 'android 14';
    lanzarCorreo = (uri) async {
      abierto = uri;
      return true;
    };
  });
  tearDown(reiniciarEscribirANordayParaTest);

  test('abre un mailto con la dirección y el asunto', () async {
    final ok = await escribirANorday(
      direccion: 'hola@norday.app',
      asunto: 'Ayuda con Norday',
    );

    expect(ok, isTrue);
    expect(abierto!.scheme, 'mailto');
    expect(abierto!.path, 'hola@norday.app');
    expect(abierto!.queryParameters['subject'], 'Ayuda con Norday');
  });

  test(
    'el cuerpo lleva dos líneas en blanco y luego app, versión y sistema',
    () async {
      await escribirANorday(direccion: 'hola@norday.app', asunto: 'Hola');

      expect(
        abierto!.queryParameters['body'],
        '\n\nNorday Habits 1.4.0+57\nandroid 14',
      );
    },
  );

  test('los espacios van como %20, no como +', () async {
    await escribirANorday(direccion: 'hola@norday.app', asunto: 'Dos palabras');

    expect(abierto.toString(), contains('subject=Dos%20palabras'));
    expect(abierto.toString(), isNot(contains('Dos+palabras')));
  });

  test('sin app de correo devuelve false', () async {
    lanzarCorreo = (_) async => false;

    expect(
      await escribirANorday(direccion: 'hola@norday.app', asunto: 'Hola'),
      isFalse,
    );
  });

  test('si el lanzador lanza, devuelve false y no lanza', () async {
    lanzarCorreo = (_) async =>
        throw PlatformException(code: 'ACTIVITY_NOT_FOUND');

    expect(
      await escribirANorday(direccion: 'hola@norday.app', asunto: 'Hola'),
      isFalse,
    );
  });

  test('si no se puede leer la versión, devuelve false y no lanza', () async {
    infoAppCorreo = () async => throw StateError('sin plugin');

    expect(
      await escribirANorday(direccion: 'hola@norday.app', asunto: 'Hola'),
      isFalse,
    );
  });
}
