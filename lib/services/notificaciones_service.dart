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

  @visibleForTesting
  static Future<void> Function(int, String) quitarToken =
      ApiServiceCore.quitarFcmToken;

  /// Lo más que espera el cierre de sesión a que el backend quite el token.
  @visibleForTesting
  static Duration topeQuitarToken = const Duration(seconds: 3);

  static StreamSubscription<String>? _suscripcion;

  @visibleForTesting
  static void reiniciarParaTest() {
    _suscripcion?.cancel();
    _suscripcion = null;
    tokenDisponible = _tokenReal;
    cambiosDeToken = () => FirebaseMessaging.instance.onTokenRefresh;
    enviarToken = ApiServiceCore.actualizarFcmToken;
    usuarioActual = _usuarioActualReal;
    quitarToken = ApiServiceCore.quitarFcmToken;
    topeQuitarToken = const Duration(seconds: 3);
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
  /// nada.
  ///
  /// El login pasa `forzar: true`: la cuenta tiene un solo token en el backend,
  /// así que el último dispositivo en iniciar sesión debe ser el que recibe los
  /// avisos, aunque este móvil ya enviara ese token antes. El arranque con
  /// sesión y el volver a primer plano no lo fuerzan.
  static Future<void> registrarSiHayPermiso(
    int usuarioId, {
    bool forzar = false,
  }) async {
    try {
      // Solo mira: lo que pide el permiso es la app, en contexto.
      if (!await Permission.notification.isGranted) return;
      await _registrar(usuarioId, forzar: forzar);
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

  /// Prefijo de la clave con el último token enviado por usuario.
  ///
  /// Lleva versión (`v2`) para que cada app reenvíe su token **una vez** al
  /// actualizarse, ya con la cabecera `X-Norday-App`: los móviles que lo
  /// enviaron antes de que el backend guardara un token por app (V24) lo
  /// mandaron sin cabecera, y sin este cambio no lo volverían a mandar. No
  /// lleva el `appId`: las preferencias del móvil son de cada app, así que dos
  /// apps nunca comparten la clave.
  static const String _prefijoClaveToken = 'fcm_token_enviado_v2_';

  /// La clave de antes de [_prefijoClaveToken]: se borra al guardar la nueva.
  static const String _prefijoClaveAntigua = 'fcm_token_enviado_';

  static String _claveToken(int usuarioId) => '$_prefijoClaveToken$usuarioId';

  /// Apunta [token] como el último enviado para [usuarioId] y borra la clave
  /// antigua, si la hay.
  static Future<void> _guardarEnviado(
    SharedPreferences prefs,
    int usuarioId,
    String token,
  ) async {
    await prefs.setString(_claveToken(usuarioId), token);
    await prefs.remove('$_prefijoClaveAntigua$usuarioId');
  }

  /// Al cerrar sesión, antes de borrar la sesión local (hace falta el JWT):
  /// si hay un token apuntado como enviado para [usuarioId], pide al backend
  /// que lo quite (solo lo hace si sigue siendo el de este móvil y esta app);
  /// después borra lo apuntado y deja de escuchar las renovaciones.
  ///
  /// Nunca bloquea la salida: la llamada tiene un tope de [topeQuitarToken] y
  /// sus fallos se tragan. Sin red, el token se queda en el backend hasta que
  /// FCM lo dé de baja.
  static Future<void> olvidarAlCerrarSesion(int usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_claveToken(usuarioId));
      if (token != null) {
        try {
          await quitarToken(usuarioId, token).timeout(topeQuitarToken);
        } catch (_) {
          // Sin red o sin respuesta: se sale igual.
        }
      }
      await prefs.remove(_claveToken(usuarioId));
      await prefs.remove('$_prefijoClaveAntigua$usuarioId');
    } catch (_) {
      // Las preferencias fallando tampoco pueden impedir salir.
    } finally {
      await _suscripcion?.cancel();
      _suscripcion = null;
    }
  }

  /// Envía el token si no es el último enviado para ese usuario, o siempre si
  /// [forzar]. Un fallo al enviar se propaga a quien llama y el token no se
  /// guarda, para que la siguiente llamada lo reintente.
  static Future<void> _registrar(int usuarioId, {bool forzar = false}) async {
    final token = await tokenDisponible();
    if (token == null) return;
    _escucharCambios();
    final prefs = await SharedPreferences.getInstance();
    if (!forzar && prefs.getString(_claveToken(usuarioId)) == token) return;
    await enviarToken(usuarioId, token);
    await _guardarEnviado(prefs, usuarioId, token);
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
        if (prefs.getString(_claveToken(id)) == token) return;
        await enviarToken(id, token);
        await _guardarEnviado(prefs, id, token);
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
