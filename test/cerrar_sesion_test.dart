import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout borra la sesión y conserva lo que es del móvil', () async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': 7,
      'nombre': 'Ana',
      'username': 'ana',
      'email': 'ana@example.com',
      'proveedorAuth': 'LOCAL',
      'recorridoHecho': true,
      'idioma': 'pt',
    });
    FlutterSecureStorage.setMockInitialValues({});

    await ApiServiceCore.logout();

    final prefs = await SharedPreferences.getInstance();
    for (final clave in ['usuarioId', 'nombre', 'username', 'email', 'proveedorAuth']) {
      expect(prefs.containsKey(clave), isFalse, reason: clave);
    }
    // Lo que causaba el bug: el recorrido volvía a salir tras cerrar sesión.
    expect(prefs.getBool('recorridoHecho'), isTrue);
    expect(prefs.getString('idioma'), 'pt');
    expect(await ApiServiceCore.getUsuarioLocal(), isNull);
  });
}
