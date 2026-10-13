import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../navegacion.dart';
import '../screens/actualizacion_obligatoria_screen.dart';
import 'api_service_core.dart';

/// Motor: la versión mínima con la que puede funcionar esta app.
///
/// El backend la guarda por app (`GET /api/version/{appId}`) y se sube a
/// mano con cada versión publicada, siempre después de que Play ya la
/// ofrezca. Por debajo de ella la app se bloquea y solo deja actualizar.
///
/// Nunca bloquea por un fallo: sin red, sin respuesta, con una respuesta
/// rara o sin `appId`, deja pasar. Bloquear a alguien por un error nuestro
/// es peor que dejarle usar una versión vieja un rato más.
class VersionMinimaService {
  /// versionCode de Android de esta instalación. Sustituible en tests.
  @visibleForTesting
  static Future<int> Function() leerVersionInstalada = _leerDelPaquete;

  /// Versión mínima según el backend. Sustituible en tests.
  @visibleForTesting
  static Future<int> Function(String appId) pedirVersionMinima =
      _pedirAlBackend;

  static AppLifecycleListener? _oyente;
  static bool _bloqueada = false;

  static Future<int> _leerDelPaquete() async {
    final info = await PackageInfo.fromPlatform();
    return int.parse(info.buildNumber);
  }

  static Future<int> _pedirAlBackend(String appId) async {
    final r = await ApiServiceCore.enviar(
      () => ApiServiceCore.cliente.get(
        Uri.parse('${ApiServiceCore.baseUrl}/version/$appId'),
      ),
      // Corto a propósito: corre en el splash y, si no contesta, se deja pasar.
      timeout: const Duration(seconds: 5),
    );
    ApiServiceCore.verificar(r);
    return ApiServiceCore.parsear(
      () =>
          (jsonDecode(r.body) as Map<String, dynamic>)['versionMinima'] as int,
    );
  }

  /// `true` solo si el backend ha contestado y la versión instalada está por
  /// debajo de la mínima. Nunca lanza.
  static Future<bool> hayQueActualizar() async {
    final appId = ApiServiceCore.appId;
    if (appId.isEmpty) return false;
    try {
      final minima = await pedirVersionMinima(appId);
      final instalada = await leerVersionInstalada();
      return instalada < minima;
    } catch (e) {
      debugPrint('Versión mínima: no se pudo comprobar: $e');
      return false;
    }
  }

  /// Lleva a la pantalla de actualización y quita todo lo que había debajo.
  /// Usa [nordayNavigatorKey]: la app tiene que habérselo dado a su
  /// `MaterialApp`.
  static void bloquear() {
    if (_bloqueada) return;
    final navegador = nordayNavigatorKey.currentState;
    if (navegador == null) return;
    _bloqueada = true;
    navegador.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ActualizacionObligatoriaScreen()),
      (_) => false,
    );
  }

  /// Vuelve a comprobar cada vez que la app pasa a primer plano: alguien
  /// puede dejarla abierta en segundo plano durante días. Se llama una vez,
  /// en el `main` de la app, antes de `runApp`. El arranque lo comprueba
  /// cada app en su splash.
  static void vigilarAlVolver() {
    _oyente ??= AppLifecycleListener(
      onResume: () => unawaited(_comprobarYBloquear()),
    );
  }

  static Future<void> _comprobarYBloquear() async {
    if (_bloqueada) return;
    if (await hayQueActualizar()) bloquear();
  }
}
