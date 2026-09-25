import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:norday_flutter_core/services/api_error.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un JWT con la fecha de caducidad dada. La firma da igual: la app no la
/// comprueba, sólo lee `exp`.
String _token(DateTime caduca) {
  String parte(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = caduca.millisecondsSinceEpoch ~/ 1000;
  return '${parte({'alg': 'HS512'})}.${parte({'exp': exp})}.firma';
}

http.Response _respuesta401({String? token}) {
  final peticion = http.Request('GET', Uri.parse('https://api.norday.app/api/x'));
  if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
  return http.Response('', 401, request: peticion);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String tokenActual;

  setUp(() {
    tokenActual = _token(DateTime.now().add(const Duration(days: 10)));
    SharedPreferences.setMockInitialValues({
      'usuarioId': 7,
      'proveedorAuth': 'LOCAL',
      'recorridoHecho': true,
    });
    FlutterSecureStorage.setMockInitialValues({'token': tokenActual});
    ApiServiceCore.alCaducarSesion = null;
  });

  test('un 401 con el token de la sesión la borra y avisa a la app', () async {
    final aviso = Completer<void>();
    ApiServiceCore.alCaducarSesion = aviso.complete;

    expect(() => ApiServiceCore.verificar(_respuesta401(token: tokenActual)),
        throwsA(isA<ApiException>()));
    await aviso.future.timeout(const Duration(seconds: 2));

    expect(await ApiServiceCore.getToken(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('usuarioId'), isFalse);
    expect(prefs.getBool('recorridoHecho'), isTrue);
  });

  test('un 401 sin token (el login con la contraseña mal) no avisa', () async {
    var avisos = 0;
    ApiServiceCore.alCaducarSesion = () => avisos++;

    expect(() => ApiServiceCore.verificar(_respuesta401()),
        throwsA(isA<ApiException>()));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(avisos, 0);
    expect(await ApiServiceCore.getToken(), tokenActual);
  });

  test('un 401 de un token que ya no es el de la sesión no echa a nadie', () async {
    var avisos = 0;
    ApiServiceCore.alCaducarSesion = () => avisos++;
    final viejo = _token(DateTime.now().subtract(const Duration(days: 1)));

    expect(() => ApiServiceCore.verificar(_respuesta401(token: viejo)),
        throwsA(isA<ApiException>()));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(avisos, 0);
    expect(await ApiServiceCore.getToken(), tokenActual);
  });

  test('al arrancar, un token caducado se descarta sin salir a la red', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'token': _token(DateTime.now().subtract(const Duration(minutes: 1)))});

    expect(await ApiServiceCore.descartarSesionCaducada(), isTrue);
    expect(await ApiServiceCore.getToken(), isNull);
  });

  test('al arrancar, un token vigente se queda', () async {
    expect(await ApiServiceCore.descartarSesionCaducada(), isFalse);
    expect(await ApiServiceCore.getToken(), tokenActual);
  });
}
