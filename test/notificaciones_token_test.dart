import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El registro del token de FCM: que se envía una vez por usuario y token, que
/// las renovaciones se escuchan con sesión y con permiso, y que un fallo al
/// enviar no se da por enviado. Todo lo de Firebase y de red entra por los
/// seams de NotificacionesService; el permiso se simula en su canal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('flutter.baseflow.com/permissions/methods');
  final notificacion = Permission.notification.value;
  const denegado = 0;
  const concedidoValor = 1;

  late int estado;
  late StreamController<String> cambios;
  late List<(int, String)> enviados;
  late int pedidosDeToken;
  late int? sesion;
  late Object? errorAlEnviar;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    estado = concedidoValor;
    cambios = StreamController<String>.broadcast();
    enviados = [];
    pedidosDeToken = 0;
    sesion = 7;
    errorAlEnviar = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async {
          if (call.method == 'checkPermissionStatus') return estado;
          if (call.method == 'requestPermissions') {
            return {notificacion: estado};
          }
          return null;
        });

    NotificacionesService.reiniciarParaTest();
    NotificacionesService.tokenDisponible = () async {
      pedidosDeToken++;
      return 'tok1';
    };
    NotificacionesService.cambiosDeToken = () => cambios.stream;
    NotificacionesService.enviarToken = (id, token) async {
      if (errorAlEnviar != null) throw errorAlEnviar!;
      enviados.add((id, token));
    };
    NotificacionesService.usuarioActual = () async => sesion;
  });

  tearDown(() async {
    NotificacionesService.reiniciarParaTest();
    await cambios.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  /// Deja que los eventos y las esperas asíncronas terminen.
  Future<void> asentar() => Future<void>.delayed(Duration.zero);

  test(
    'con permiso envía el token una vez, con el usuario y el token',
    () async {
      await NotificacionesService.registrarSiHayPermiso(7);
      expect(enviados, [(7, 'tok1')]);
    },
  );

  test('una segunda llamada con el mismo token no vuelve a enviar', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(enviados, [(7, 'tok1')]);
  });

  test('con un token distinto sí envía', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    NotificacionesService.tokenDisponible = () async => 'tok2';
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(enviados, [(7, 'tok1'), (7, 'tok2')]);
  });

  test('sin permiso no pide el token ni envía nada', () async {
    estado = denegado;
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(pedidosDeToken, 0);
    expect(enviados, isEmpty);
  });

  test(
    'si el envío falla, no propaga, no lo da por enviado y reintenta',
    () async {
      errorAlEnviar = Exception('sin red');
      await expectLater(
        NotificacionesService.registrarSiHayPermiso(7),
        completes,
      );

      errorAlEnviar = null;
      await NotificacionesService.registrarSiHayPermiso(7);
      expect(enviados, [(7, 'tok1')]);
    },
  );

  test('una renovación del token con sesión y permiso se envía', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    cambios.add('tok3');
    await asentar();
    expect(enviados, [(7, 'tok1'), (7, 'tok3')]);
  });

  test('una renovación sin sesión no se envía', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    sesion = null;
    cambios.add('tok3');
    await asentar();
    expect(enviados, [(7, 'tok1')]);
  });

  test(
    'tres llamadas no crean tres escuchas: una renovación envía una vez',
    () async {
      await NotificacionesService.registrarSiHayPermiso(7);
      await NotificacionesService.registrarSiHayPermiso(7);
      await NotificacionesService.registrarSiHayPermiso(7);
      cambios.add('tok9');
      await asentar();
      expect(enviados, [(7, 'tok1'), (7, 'tok9')]);
    },
  );

  test('el token enviado de un usuario no cuenta para otro', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    await NotificacionesService.registrarSiHayPermiso(8);
    expect(enviados, [(7, 'tok1'), (8, 'tok1')]);
  });

  test('con forzar, un token ya guardado se vuelve a enviar', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    await NotificacionesService.registrarSiHayPermiso(7, forzar: true);
    expect(enviados, [(7, 'tok1'), (7, 'tok1')]);
  });

  test('sin forzar, un token ya guardado sigue sin enviarse', () async {
    await NotificacionesService.registrarSiHayPermiso(7);
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(enviados, [(7, 'tok1')]);
  });

  test('con forzar, si el envío falla no se guarda como enviado', () async {
    errorAlEnviar = Exception('sin red');
    await expectLater(
      NotificacionesService.registrarSiHayPermiso(7, forzar: true),
      completes,
    );

    errorAlEnviar = null;
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(enviados, [(7, 'tok1')]);
  });
}
