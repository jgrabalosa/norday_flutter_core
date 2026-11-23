import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/norday_core_localizations.dart';
import '../screens/actualizacion_obligatoria_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/tarjeta_version_recomendada.dart';
import 'analytics_service.dart';
import 'api_service_core.dart';
import 'version_minima_service.dart';

/// Motor: avisa de que hay una versión nueva, sin obligar a nada.
///
/// Usa el modo flexible de Google Play: la descarga va por detrás mientras se
/// usa la app y, al acabar, un `SnackBar` ofrece «Reiniciar». Obligar es cosa
/// de la versión mínima del backend ([ActualizacionObligatoriaScreen]), no de
/// aquí. El aviso de Play solo funciona en Android y con la app instalada desde
/// Play; cuando no ofrece nada, [comprobar] mira la versión recomendada del
/// backend y enseña [TarjetaVersionRecomendada] (T-061).
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

  /// Clave de `SharedPreferences` con la última versión recomendada que ya se
  /// ofreció en este móvil (el número). Una vez por versión recomendada.
  static const claveRecomendadaOfrecida = 'version_recomendada_ofrecida';

  /// Mira si hay versión nueva y, como mucho una vez al día, la ofrece. Si el
  /// aviso de Play no ofrece nada en esta llamada, mira la versión
  /// recomendada del backend ([_comprobarRecomendada]). Nunca los dos juntos.
  /// Nunca lanza.
  static Future<void> comprobar(BuildContext context) async {
    final ofrecioPlay = await _avisoDePlay(context);
    if (ofrecioPlay) return;
    if (!context.mounted) return;
    await _comprobarRecomendada(context);
  }

  /// El aviso de Play de siempre. Devuelve `true` si en esta llamada ha
  /// ofrecido o enseñado algo, o si hoy ya lo hizo (el corte diario cuenta
  /// como «Play ya ha hablado hoy»: ese día no sale la tarjeta de Norday).
  static Future<bool> _avisoDePlay(BuildContext context) async {
    if (!esAndroid()) return false;
    var ofrecio = false;
    StreamSubscription<InstallStatus>? suscripcion;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoy = _dia(ahora());
      if (prefs.getString(claveDia) == hoy) return true;

      final info = await consultar();

      // Se bajó otro día y no se reinició: solo falta el aviso.
      if (info.installStatus == InstallStatus.downloaded) {
        ofrecio = true;
        await prefs.setString(claveDia, hoy);
        await AnalyticsCore.avisoActualizacion('descargada');
        if (context.mounted) _mostrarAviso(context);
        return true;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return false;
      }

      ofrecio = true;
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
    return ofrecio;
  }

  /// Si la instalada es menor que la `versionRecomendada` del backend y esa
  /// no se ha ofrecido ya en este móvil, enseña la tarjeta. Nunca lanza.
  static Future<void> _comprobarRecomendada(BuildContext context) async {
    try {
      final appId = ApiServiceCore.appId;
      if (appId.isEmpty) return;
      final recomendada = await VersionMinimaService.recomendada(appId);
      if (recomendada == null) return;
      final instalada = await VersionMinimaService.instalada();
      if (instalada >= recomendada) return;

      final prefs = await SharedPreferences.getInstance();
      final ofrecida = prefs.getInt(claveRecomendadaOfrecida);
      if (ofrecida != null && ofrecida >= recomendada) return;
      if (!context.mounted) return;

      await prefs.setInt(claveRecomendadaOfrecida, recomendada);
      await AnalyticsCore.versionRecomendada('ofrecida');
      if (!context.mounted) return;

      // Sin esperar: [comprobar] termina al enseñarla, no al cerrarla.
      unawaited(_enseniarTarjeta(context));
    } catch (e) {
      debugPrint('Versión recomendada: no se pudo: $e');
    }
  }

  /// El diálogo con la tarjeta y lo que pasa al cerrarlo. Nunca lanza.
  static Future<void> _enseniarTarjeta(BuildContext context) async {
    try {
      final actualizar = await showDialog<bool>(
        context: context,
        builder: (c) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: TarjetaVersionRecomendada(
            onActualizar: () => Navigator.of(c).pop(true),
            onAhoraNo: () => Navigator.of(c).pop(false),
          ),
        ),
      );
      if (actualizar == true) {
        await AnalyticsCore.versionRecomendada('actualizar');
        await ActualizacionObligatoriaScreen.abrirActualizacion();
      } else {
        // «Ahora no» o tocar fuera: lo mismo.
        await AnalyticsCore.versionRecomendada('ahora_no');
      }
    } catch (e) {
      debugPrint('Versión recomendada: no se pudo: $e');
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
