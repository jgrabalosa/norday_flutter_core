import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/norday_core_localizations.dart';
import 'analytics_service.dart';

/// Motor: avisa de que hay una versión nueva, sin obligar a nada.
///
/// Usa el modo flexible de Google Play: la descarga va por detrás mientras se
/// usa la app y, al acabar, un `SnackBar` ofrece «Reiniciar». Obligar es cosa
/// de la versión mínima del backend ([ActualizacionObligatoriaScreen]), no de
/// aquí. Solo funciona en Android y con la app instalada desde Play; en
/// cualquier otro caso [comprobar] no hace nada.
///
/// Esta clase no sabe de ninguna app: quien la use decide cuándo llamarla
/// (nunca durante el alta ni con otra tarjeta abierta).
class AvisoActualizacion {
  AvisoActualizacion._();

  /// Clave de `SharedPreferences` con el día (`aaaa-mm-dd`, hora del móvil) en
  /// que se ofreció o se enseñó el aviso por última vez.
  static const claveDia = 'aviso_actualizacion_dia';

  /// Lo que dura el aviso en pantalla.
  static const duracionAviso = Duration(seconds: 10);

  // ── Seams: lo que toca el mundo exterior, sustituible en tests ──────────

  @visibleForTesting
  static bool Function() esAndroid = () =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static Future<AppUpdateInfo> Function() consultar =
      InAppUpdate.checkForUpdate;

  @visibleForTesting
  static Future<AppUpdateResult> Function() empezarFlexible =
      InAppUpdate.startFlexibleUpdate;

  @visibleForTesting
  static Future<void> Function() completarFlexible =
      InAppUpdate.completeFlexibleUpdate;

  @visibleForTesting
  static Stream<InstallStatus> Function() estadoInstalacion = () =>
      InAppUpdate.installUpdateListener;

  /// Mira si hay versión nueva y, como mucho una vez al día, la ofrece.
  /// Nunca lanza.
  static Future<void> comprobar(BuildContext context) async {
    if (!esAndroid()) return;
    StreamSubscription<InstallStatus>? suscripcion;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoy = _dia(ahora());
      if (prefs.getString(claveDia) == hoy) return;

      final info = await consultar();

      // Se bajó otro día y no se reinició: solo falta el aviso.
      if (info.installStatus == InstallStatus.downloaded) {
        await prefs.setString(claveDia, hoy);
        await AnalyticsCore.avisoActualizacion('descargada');
        if (context.mounted) _mostrarAviso(context);
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return;
      }

      await prefs.setString(claveDia, hoy);
      await AnalyticsCore.avisoActualizacion('ofrecida');

      // Se escucha antes de empezar para no perder un `downloaded` rápido.
      suscripcion = estadoInstalacion().listen((estado) {
        switch (estado) {
          case InstallStatus.downloaded:
            suscripcion?.cancel();
            AnalyticsCore.avisoActualizacion('descargada');
            if (context.mounted) _mostrarAviso(context);
          case InstallStatus.failed || InstallStatus.canceled:
            suscripcion?.cancel();
          default:
            break;
        }
      });

      final resultado = await empezarFlexible();
      if (resultado == AppUpdateResult.success) {
        await AnalyticsCore.avisoActualizacion('aceptada');
      } else {
        // Dijo que no, o Google falló: no habrá descarga que escuchar.
        suscripcion.cancel();
        if (resultado == AppUpdateResult.userDeniedUpdate) {
          await AnalyticsCore.avisoActualizacion('rechazada');
        }
      }
    } catch (e) {
      suscripcion?.cancel();
      debugPrint('Aviso de actualización: no se pudo: $e');
    }
  }

  static String _dia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static void _mostrarAviso(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final t = NordayCoreLocalizations.of(context);
    if (messenger == null || t == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.avisoActualizacionTexto),
        duration: duracionAviso,
        persist: false,
        action: SnackBarAction(
          label: t.avisoActualizacionReiniciar,
          onPressed: _reiniciar,
        ),
      ),
    );
  }

  /// Solo se llega aquí tocando «Reiniciar»: Google instala y reabre la app.
  static Future<void> _reiniciar() async {
    await AnalyticsCore.avisoActualizacion('reiniciada');
    try {
      await completarFlexible();
    } catch (e) {
      debugPrint('Aviso de actualización: no se pudo reiniciar: $e');
    }
  }
}
