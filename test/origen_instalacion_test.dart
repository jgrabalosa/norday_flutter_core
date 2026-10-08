import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/origen_instalacion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> enviados;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    enviados = [];
    OrigenInstalacionService.leerReferrer = () async =>
        'utm_source=reddit&utm_medium=social';
    OrigenInstalacionService.enviarAlBackend =
        (int usuarioId, String referrer) async {
          enviados.add('$usuarioId|$referrer');
        };
  });

  test('envía el referrer una sola vez', () async {
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    expect(enviados, ['7|utm_source=reddit&utm_medium=social']);
  });

  test('una segunda cuenta en el mismo móvil no vuelve a enviarlo', () async {
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    await OrigenInstalacionService.enviarSiHaceFalta(8);
    expect(enviados.length, 1);
  });

  test(
    'si el envío falla no lanza, no marca y reintenta en el siguiente login',
    () async {
      OrigenInstalacionService.enviarAlBackend = (int u, String r) async {
        throw Exception('sin red');
      };
      await OrigenInstalacionService.enviarSiHaceFalta(7);

      OrigenInstalacionService.enviarAlBackend =
          (int usuarioId, String referrer) async {
            enviados.add('$usuarioId|$referrer');
          };
      await OrigenInstalacionService.enviarSiHaceFalta(7);
      expect(enviados.length, 1);
    },
  );

  test('si no hay referrer legible no envía ni marca', () async {
    OrigenInstalacionService.leerReferrer = () async => null;
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    expect(enviados, isEmpty);

    OrigenInstalacionService.leerReferrer = () async => 'utm_source=x';
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    expect(enviados.length, 1);
  });

  test('si leer el referrer lanza, no lanza hacia fuera ni marca', () async {
    OrigenInstalacionService.leerReferrer = () async {
      throw Exception('sin Play Services');
    };
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    expect(enviados, isEmpty);
  });

  test('un referrer vacío es válido y se envía', () async {
    OrigenInstalacionService.leerReferrer = () async => '';
    await OrigenInstalacionService.enviarSiHaceFalta(7);
    expect(enviados, ['7|']);
  });
}
