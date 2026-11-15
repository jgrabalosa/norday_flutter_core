import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/services/api_error.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El registro del token de avisos lleva la app (`X-Norday-App`), para que el
/// backend guarde un token por app.
///
/// `ApiServiceCore.cliente` es un `static final`: se crea la primera vez que
/// se lee y se queda para todo el isolate. Por eso este test vive en su propio
/// fichero y lo crea dentro de `http.runWithClient`, con un cliente falso que
/// delega en [responder] para poder cambiar de respuesta en cada test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final peticiones = <http.Request>[];
  late Future<http.Response> Function(http.Request) responder;
  final falso = MockClient((peticion) {
    peticiones.add(peticion);
    return responder(peticion);
  });
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  setUp(() {
    peticiones.clear();
    responder = (_) async => http.Response('', 200);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
  });
  tearDown(() => ApiServiceCore.appId = '');

  test('el cliente compartido es el falso', () {
    expect(identical(ApiServiceCore.cliente, falso), isTrue);
  });

  test('con appId, el PUT del token lleva X-Norday-App', () async {
    ApiServiceCore.appId = 'enfoque';
    await ApiServiceCore.actualizarFcmToken(7, 'abc');

    expect(peticiones, hasLength(1));
    final p = peticiones.single;
    expect(p.method, 'PUT');
    expect(p.url.path, endsWith('/usuarios/7/fcm-token'));
    expect(p.headers['X-Norday-App'], 'enfoque');
    expect(p.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(p.body), {'fcmToken': 'abc'});
  });

  test('sin appId no se manda la cabecera (el backend lo cuenta como '
      'habitos)', () async {
    ApiServiceCore.appId = '';
    await ApiServiceCore.actualizarFcmToken(7, 'abc');

    expect(peticiones.single.headers.containsKey('X-Norday-App'), isFalse);
  });

  test('un 400 del backend (app desconocida) se propaga', () async {
    ApiServiceCore.appId = 'otra';
    responder = (_) async => http.Response('', 400);
    await expectLater(
      ApiServiceCore.actualizarFcmToken(7, 'abc'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.codigoEstado, 'codigoEstado', 400)
            .having((e) => e.tipo, 'tipo', TipoErrorApi.peticionInvalida),
      ),
    );
  });
}
