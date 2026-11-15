import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../navegacion.dart';
import '../screens/actualizacion_obligatoria_screen.dart';
import 'api_error.dart';
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

  /// Si la app ya ha llegado a primer plano alguna vez desde que se vigila.
  /// Hasta entonces, un `resumed` es el arranque, no una vuelta.
  static bool _yaEnPrimerPlano = false;

  /// Deja el servicio como recién arrancado: sin oyente y sin bloqueo. El
  /// binding de test es el mismo para todos los tests de un fichero.
  @visibleForTesting
  static void reiniciarParaTest() {
    _oyente?.dispose();
    _oyente = null;
    _bloqueada = false;
    _yaEnPrimerPlano = false;
  }

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
      // `ApiException.toString()` no lleva el cuerpo a propósito (puede
      // acabar en Crashlytics); aquí sí, porque sin él «sinConexion» no dice
      // si fue el DNS, el TLS o la red cortada en segundo plano.
      final causa = e is ApiException && e.cuerpo != null
          ? ': ${e.cuerpo}'
          : '';
      debugPrint('Versión mínima: no se pudo comprobar: $e$causa');
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

  /// Vuelve a comprobar cada vez que la app vuelve a primer plano: alguien
  /// puede dejarla abierta en segundo plano durante días. Se llama una vez,
  /// en el `main` de la app, antes de `runApp`. El arranque lo comprueba
  /// cada app en su splash, así que la llegada a primer plano del arranque
  /// no comprueba.
  ///
  /// Por qué `onResume` ignorando el primero y no `onRestart`: en un arranque
  /// en frío Android pasa de ningún estado directamente a `resumed` (o a
  /// `inactive` y luego `resumed`, si el foco llega tarde) y `onResume` se
  /// dispara; esa comprobación duplicaba la del splash y, con el proceso
  /// lanzado en segundo plano, fallaba por red. `onRestart` no la tendría,
  /// pero tampoco cubre todo lo que cubría `onResume`. Según la doc del SDK
  /// (Flutter 3.44, `AppLifecycleListener.onRestart`): «A callback that is
  /// called when the application is resumed after being paused». Solo salta
  /// en `paused` → `hidden`; volver de `inactive` sin pasar por `paused`
  /// (la cortina de notificaciones, un diálogo del sistema, la otra mitad de
  /// la pantalla dividida) no lo dispara, y `onResume` sí. Para no perder
  /// esos casos se sigue con `onResume` y solo se salta la primera llegada
  /// a primer plano, que es la del arranque.
  static void vigilarAlVolver() {
    if (_oyente != null) return;
    // Si ya está en primer plano al empezar a vigilar, el arranque ya pasó:
    // el próximo `resumed` es una vuelta de verdad.
    _yaEnPrimerPlano =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _oyente = AppLifecycleListener(onResume: _alPasarAPrimerPlano);
  }

  static void _alPasarAPrimerPlano() {
    if (!_yaEnPrimerPlano) {
      _yaEnPrimerPlano = true;
      return;
    }
    unawaited(_comprobarYBloquear());
  }

  static Future<void> _comprobarYBloquear() async {
    if (_bloqueada) return;
    if (await hayQueActualizar()) bloquear();
  }
}
