import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_core.dart';

/// Motor: de dónde vino la instalación, según Google Play.
///
/// Lee el "install referrer" (solo existe en Android, y solo si se instaló
/// desde Play) y se lo manda una vez al backend, que se queda con el
/// primero de cada usuario. Sirve para medir qué canal de difusión trae
/// gente, con cifras agregadas.
///
/// Nunca lanza: medir no puede romper el login que lo dispara. Si algo
/// falla, no se marca como enviado y se reintenta en el siguiente login.
class OrigenInstalacionService {
  static const _claveEnviado = 'origenInstalacionEnviado';

  /// Lee el referrer. Sustituible en tests.
  @visibleForTesting
  static Future<String?> Function() leerReferrer = _leerDePlay;

  /// Lo manda al backend. Sustituible en tests.
  @visibleForTesting
  static Future<void> Function(int usuarioId, String referrer) enviarAlBackend =
      ApiServiceCore.registrarOrigen;

  static Future<String?> _leerDePlay() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final detalles = await PlayInstallReferrer.installReferrer;
    return detalles.installReferrer;
  }

  /// Envía el origen si aún no se ha enviado desde este dispositivo. La
  /// marca es del dispositivo, no de la cuenta: cerrar sesión no la borra.
  static Future<void> enviarSiHaceFalta(int usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_claveEnviado) == true) return;

      final referrer = await leerReferrer();
      if (referrer == null) return;

      await enviarAlBackend(usuarioId, referrer);
      await prefs.setBool(_claveEnviado, true);
    } catch (e) {
      debugPrint('Origen de instalación: no se envió: $e');
    }
  }
}
