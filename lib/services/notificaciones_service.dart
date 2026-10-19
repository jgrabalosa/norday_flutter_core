import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service_core.dart';

/// El permiso de notificaciones y el registro del aviso del móvil (el token
/// de FCM) en el backend, que es quien manda los avisos.
///
/// El permiso no se pide al entrar: lo pide la app en contexto, cuando el
/// usuario hace algo que lo necesita (activar un recordatorio). Al entrar
/// solo se registra el aviso si el permiso ya estaba dado, para que quien ya
/// aceptó siga recibiendo sus avisos.
class NotificacionesService {
  NotificacionesService._();

  /// Si el permiso está concedido ahora mismo.
  static Future<bool> concedido() async {
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Sin preguntar nada: si hay permiso, registra el aviso; si no, no hace
  /// nada. Es lo que hace el login.
  static Future<void> registrarSiHayPermiso(int usuarioId) async {
    try {
      // Solo mira: lo que pide el permiso es la app, en contexto.
      if (!await Permission.notification.isGranted) return;
      await _registrar(usuarioId);
    } catch (_) {
      // Un fallo aquí nunca bloquea la entrada.
    }
  }

  /// Pide el permiso al sistema si hace falta y, si queda concedido,
  /// registra el aviso. Devuelve si está concedido al acabar.
  static Future<bool> pedirYRegistrar(int usuarioId) async {
    try {
      final estado = await Permission.notification.request();
      if (!estado.isGranted) return false;
      await _registrar(usuarioId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True si el sistema ya no enseñará su diálogo: solo queda Ajustes.
  static Future<bool> bloqueadoEnAjustes() async {
    try {
      return await Permission.notification.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Abre los ajustes de la app en el sistema.
  static Future<bool> abrirAjustes() => openAppSettings();

  static Future<void> _registrar(int usuarioId) async {
    final messaging = FirebaseMessaging.instance;
    final ajustes = await messaging.requestPermission();
    if (ajustes.authorizationStatus != AuthorizationStatus.authorized) return;
    final token = await messaging.getToken();
    if (token != null) {
      await ApiServiceCore.actualizarFcmToken(usuarioId, token);
    }
  }
}
