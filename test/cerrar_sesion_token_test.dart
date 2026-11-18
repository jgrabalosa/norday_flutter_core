import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cerrar sesión quita del backend el token de avisos de esta app (T-004b):
/// solo si hay uno apuntado como enviado para ese usuario, con un tope de
/// tiempo, sin que un fallo impida salir, y dejando de escuchar las
/// renovaciones. Lo de red entra por los seams de NotificacionesService.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('flutter.baseflow.com/permissions/methods');
  final notificacion = Permission.notification.value;
  const concedido = 1;

  late StreamController<String> cambios;
  late List<(int, String)> enviados;
  late List<(int, String)> quitados;

  Map<String, Object> sesion7({String? tokenEnviado}) => {
    'usuarioId': 7,
    'nombre': 'Ana',
    'username': 'ana',
    'email': 'ana@example.com',
    'proveedorAuth': 'LOCAL',
    'fcm_token_enviado_v2_7': ?tokenEnviado,
  };

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    cambios = StreamController<String>.broadcast();
    enviados = [];
    quitados = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async {
          if (call.method == 'checkPermissionStatus') return concedido;
          if (call.method == 'requestPermissions') {
            return {notificacion: concedido};
          }
          return null;
        });

    NotificacionesService.reiniciarParaTest();
    NotificacionesService.tokenDisponible = () async => 'tok1';
    NotificacionesService.cambiosDeToken = () => cambios.stream;
    NotificacionesService.enviarToken = (id, token) async {
      enviados.add((id, token));
    };
    // Aunque la sesión local ya no exista, el seam sigue diciendo 7: así se
    // ve que lo que corta las renovaciones es dejar de escuchar.
    NotificacionesService.usuarioActual = () async => 7;
    NotificacionesService.quitarToken = (id, token) async {
      quitados.add((id, token));
    };
  });

  tearDown(() async {
    NotificacionesService.reiniciarParaTest();
    await cambios.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  Future<void> asentar() => Future<void>.delayed(Duration.zero);

  test('con un token apuntado, lo quita con el usuario y el token', () async {
    SharedPreferences.setMockInitialValues(sesion7(tokenEnviado: 'tok1'));

    await ApiServiceCore.logout();

    expect(quitados, [(7, 'tok1')]);
  });

  test('tras quitarlo, la clave del token enviado ya no está', () async {
    SharedPreferences.setMockInitialValues(sesion7(tokenEnviado: 'tok1'));

    await ApiServiceCore.logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('fcm_token_enviado_v2_7'), isFalse);
  });

  test('sin token apuntado, no llama al backend', () async {
    SharedPreferences.setMockInitialValues(sesion7());

    await ApiServiceCore.logout();

    expect(quitados, isEmpty);
    expect(await ApiServiceCore.getUsuarioLocal(), isNull);
  });

  test('si quitarlo lanza, la sesión se borra igual', () async {
    SharedPreferences.setMockInitialValues(sesion7(tokenEnviado: 'tok1'));
    NotificacionesService.quitarToken = (id, token) async {
      throw Exception('sin red');
    };

    await expectLater(ApiServiceCore.logout(), completes);

    expect(await ApiServiceCore.getUsuarioLocal(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('usuarioId'), isFalse);
  });

  test('si quitarlo no responde, el tope corta y la sesión se borra', () async {
    SharedPreferences.setMockInitialValues(sesion7(tokenEnviado: 'tok1'));
    final nunca = Completer<void>();
    NotificacionesService.quitarToken = (id, token) => nunca.future;
    NotificacionesService.topeQuitarToken = const Duration(milliseconds: 50);

    await expectLater(
      ApiServiceCore.logout().timeout(const Duration(seconds: 2)),
      completes,
    );

    expect(await ApiServiceCore.getUsuarioLocal(), isNull);
  });

  test('el tope por defecto es de 3 segundos', () {
    expect(NotificacionesService.topeQuitarToken, const Duration(seconds: 3));
  });

  test(
    'una sesión caducada al arrancar se borra sin llamar al backend',
    () async {
      SharedPreferences.setMockInitialValues(sesion7(tokenEnviado: 'tok1'));
      // Un JWT con «exp» en 2001: caducado.
      FlutterSecureStorage.setMockInitialValues({
        'token': 'e30.eyJleHAiOjEwMDAwMDAwMDB9.firma',
      });

      expect(await ApiServiceCore.descartarSesionCaducada(), isTrue);

      expect(quitados, isEmpty);
    },
  );

  test('tras cerrar sesión, una renovación del token ya no se envía', () async {
    SharedPreferences.setMockInitialValues(sesion7());
    // Con el registro empieza la escucha de renovaciones.
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(enviados, [(7, 'tok1')]);

    await ApiServiceCore.logout();
    cambios.add('tok2');
    await asentar();

    expect(enviados, [(7, 'tok1')]);
  });

  test('al volver a entrar, las renovaciones se escuchan otra vez', () async {
    SharedPreferences.setMockInitialValues(sesion7());
    await NotificacionesService.registrarSiHayPermiso(7);
    await ApiServiceCore.logout();

    await NotificacionesService.registrarSiHayPermiso(7, forzar: true);
    cambios.add('tok2');
    await asentar();

    expect(enviados, [(7, 'tok1'), (7, 'tok1'), (7, 'tok2')]);
  });
}
