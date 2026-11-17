import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/version_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El catálogo de productos y la compra llevan la versión del core
/// (`X-Norday-Core`), para que el backend no dé prendas que este core no sabe
/// pintar (Nori vestida, N-6).
///
/// Como en `fcm_token_app_test.dart`: `ApiServiceCore.cliente` es un
/// `static final`, así que el cliente falso se pone en su propio fichero.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final peticiones = <http.Request>[];
  final falso = MockClient((peticion) async {
    peticiones.add(peticion);
    return http.Response('[]', 200);
  });
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  setUp(() {
    peticiones.clear();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
  });
  tearDown(() => ApiServiceCore.appId = '');

  test('la versión no está vacía', () {
    expect(versionCore, isNotEmpty);
  });

  test('el catálogo de productos lleva X-Norday-Core, junto a '
      'X-Norday-App', () async {
    ApiServiceCore.appId = 'habitos';
    await ApiServiceCore.getCatalogoProductos();

    final p = peticiones.single;
    expect(p.url.path, endsWith('/gamificacion/productos/catalogo'));
    expect(p.headers['X-Norday-Core'], versionCore);
    expect(p.headers['X-Norday-App'], 'habitos');
  });

  test('sin appId, el catálogo lleva igual X-Norday-Core', () async {
    await ApiServiceCore.getCatalogoProductos();

    expect(peticiones.single.headers['X-Norday-Core'], versionCore);
    expect(peticiones.single.headers.containsKey('X-Norday-App'), isFalse);
  });

  test('la compra lleva X-Norday-Core', () async {
    await ApiServiceCore.comprarProducto(7, 21);

    final p = peticiones.single;
    expect(p.url.path, endsWith('/gamificacion/productos/comprar/7/21'));
    expect(p.headers['X-Norday-Core'], versionCore);
  });

  test('el inventario no la lleva: no depende de quién mira', () async {
    await ApiServiceCore.getInventarioProductos(7);

    expect(peticiones.single.headers.containsKey('X-Norday-Core'), isFalse);
  });
}
