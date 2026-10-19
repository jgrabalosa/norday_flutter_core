import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:permission_handler/permission_handler.dart';

/// El permiso de notificaciones, simulando el canal de permission_handler:
/// quién pide el permiso y cuándo, sin abrir ningún diálogo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('flutter.baseflow.com/permissions/methods');
  // Valor del permiso de notificaciones en el canal.
  final notificacion = Permission.notification.value;

  // Valores de PermissionStatus en el canal: denegado y concedido.
  const denegado = 0;
  const concedidoValor = 1;

  late List<String> llamadas;
  late int estado;

  setUp(() {
    llamadas = [];
    estado = denegado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async {
          llamadas.add(call.method);
          if (call.method == 'checkPermissionStatus') return estado;
          if (call.method == 'requestPermissions') {
            return {notificacion: estado};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test('registrarSiHayPermiso no pide el permiso', () async {
    estado = denegado;
    await NotificacionesService.registrarSiHayPermiso(7);
    expect(llamadas, isNot(contains('requestPermissions')));
  });

  test(
    'pedirYRegistrar pide el permiso y devuelve false si lo deniegan',
    () async {
      estado = denegado;
      final concedido = await NotificacionesService.pedirYRegistrar(7);
      expect(llamadas, contains('requestPermissions'));
      expect(concedido, isFalse);
    },
  );

  test('pedirYRegistrar pide el permiso cuando lo conceden', () async {
    // Hasta el permiso: el registro del aviso necesita Firebase, que no
    // existe en un test, así que no se mira el valor devuelto.
    estado = concedidoValor;
    await NotificacionesService.pedirYRegistrar(7);
    expect(llamadas, contains('requestPermissions'));
  });
}
