import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_core.dart';

/// El permiso de notificaciones y el registro del aviso del móvil (el token
/// de FCM) en el backend, que es quien manda los avisos.
///
/// El permiso no se pide al entrar: lo pide la app en contexto, cuando el
/// usuario hace algo que lo necesita (activar un recordatorio). Al entrar
/// solo se registra el aviso si el permiso ya estaba dado, para que quien ya
/// aceptó siga recibiendo sus avisos.
///
/// El registro es idempotente por usuario y token: el último token enviado
/// para cada usuario se guarda en el móvil y no se vuelve a enviar. Además
/// escucha las renovaciones del token de FCM mientras hay sesión y permiso.
/// La app lo llama al arrancar con sesión y al volver a primer plano.
class NotificacionesService {
  NotificacionesService._();

  /// Seams de test: cada uno da por defecto la implementación real.
  @visibleForTesting
  static Future<String?> Function() tokenDisponible = _tokenReal;

  @visibleForTesting
  static Stream<String> Function() cambiosDeToken = () =>
      FirebaseMessaging.instance.onTokenRefresh;

  @visibleForTesting
  static Future<void> Function(int, String) enviarToken =
      ApiServiceCore.actualizarFcmToken;

  @visibleForTesting
  static Future<int?> Function() usuarioActual = _usuarioActualReal;

  static StreamSubscription<String>? _suscripcion;

  @visibleForTesting
  static void reiniciarParaTest() {
    _suscripcion?.cancel();
    _suscripcion = null;
    tokenDisponible = _tokenReal;
    cambiosDeToken = () => FirebaseMessaging.instance.onTokenRefresh;
    enviarToken = ApiServiceCore.actualizarFcmToken;
    usuarioActual = _usuarioActualReal;
  }

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

  static String _claveToken(int usuarioId) => 'fcm_token_enviado_$usuarioId';

  /// Envía el token si no es el último enviado para ese usuario. Un fallo al
  /// enviar se propaga a quien llama y el token no se guarda, para que la
  /// siguiente llamada lo reintente.
  static Future<void> _registrar(int usuarioId) async {
    final token = await tokenDisponible();
    if (token == null) return;
    _escucharCambios();
    final prefs = await SharedPreferences.getInstance();
    final clave = _claveToken(usuarioId);
    if (prefs.getString(clave) == token) return;
    await enviarToken(usuarioId, token);
    await prefs.setString(clave, token);
  }

  /// Escucha las renovaciones del token. Una sola suscripción: si ya la hay,
  /// no hace nada. Cada renovación se envía con la sesión abierta y el permiso
  /// dado; un fallo aquí no tumba nada.
  static void _escucharCambios() {
    if (_suscripcion != null) return;
    _suscripcion = cambiosDeToken().listen((token) async {
      try {
        if (!await concedido()) return;
        final id = await usuarioActual();
        if (id == null) return;
        final prefs = await SharedPreferences.getInstance();
        final clave = _claveToken(id);
        if (prefs.getString(clave) == token) return;
        await enviarToken(id, token);
        await prefs.setString(clave, token);
      } catch (_) {
        // Se reintenta en la siguiente apertura o renovación.
      }
    }, onError: (_) {});
  }

  static Future<String?> _tokenReal() async {
    final messaging = FirebaseMessaging.instance;
    final ajustes = await messaging.requestPermission();
    if (ajustes.authorizationStatus != AuthorizationStatus.authorized) {
      return null;
    }
    return messaging.getToken();
  }

  static Future<int?> _usuarioActualReal() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    return usuario?['usuarioId'] as int?;
  }
}
