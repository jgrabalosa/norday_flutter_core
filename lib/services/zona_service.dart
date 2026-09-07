import 'package:shared_preferences/shared_preferences.dart';
import 'api_service_core.dart';

/// Zona horaria del usuario. Independiente del idioma a propósito: un
/// brasileño y un portugués hablan lo mismo y están a cuatro horas.
///
/// El backend la necesita para saber cuándo es "hoy" para esta persona
/// (rachas, recordatorios), así que se sincroniza con él.
class ZonaService {
  static const String porDefecto = 'Europe/Madrid';
  static const _clave = 'zonaHoraria';

  /// Marca que el último cambio local no llegó al backend.
  ///
  /// Sin esto, un fallo de red al guardar la zona se perdía en silencio y,
  /// peor, el siguiente login traía la zona vieja del servidor y pisaba la
  /// corrección del usuario. Como el backend usa la zona para decidir qué
  /// día es, esa divergencia rompe rachas sin que nada dé error.
  static const _clavePendiente = 'zonaPendienteDeSync';

  /// Zona detectada del dispositivo.
  ///
  /// Dart no expone el nombre IANA de la zona del sistema, solo el desfase,
  /// y el desfase no identifica una zona (Madrid y Berlín comparten el mismo
  /// y cambian de hora distinto que Sao Paulo). Se deduce la más probable
  /// para ese desfase y el usuario puede corregirla en Preferencias, que es
  /// justo lo que la decisión 5 pedía: detectar y permitir corregir.
  static String detectarDelDispositivo() {
    final minutos = DateTime.now().timeZoneOffset.inMinutes;
    return _porDesfase[minutos] ?? porDefecto;
  }

  /// Un candidato razonable por desfase. No pretende ser exhaustivo: es la
  /// primera propuesta, no la última palabra.
  static const Map<int, String> _porDesfase = {
    -480: 'America/Los_Angeles',
    -420: 'America/Denver',
    -360: 'America/Mexico_City',
    -300: 'America/Bogota',
    -240: 'America/Santiago',
    -180: 'America/Sao_Paulo',
    0: 'Europe/London',
    60: 'Europe/Madrid',
    120: 'Europe/Madrid',
    180: 'Europe/Moscow',
    330: 'Asia/Kolkata',
    480: 'Asia/Shanghai',
    540: 'Asia/Tokyo',
    600: 'Australia/Sydney',
    660: 'Australia/Sydney',
    720: 'Pacific/Auckland',
    780: 'Pacific/Auckland',
  };

  static Future<String> obtenerGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clave) ?? porDefecto;
  }

  /// Primer arranque: propone la del dispositivo y la sincroniza.
  static Future<void> inicializarSiHaceFalta({int? usuarioId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_clave) != null) return;
    await cambiar(detectarDelDispositivo(), usuarioId: usuarioId);
  }

  static Future<void> cambiar(String zona, {int? usuarioId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, zona);

    if (usuarioId != null) {
      try {
        await ApiServiceCore.actualizarPreferencias(usuarioId, zonaHoraria: zona);
        await prefs.remove(_clavePendiente);
      } catch (_) {
        // El cambio local se queda: la app ya funciona con la zona nueva.
        // Lo que no puede perderse es que el backend no se enteró.
        await prefs.setBool(_clavePendiente, true);
      }
    }
  }

  /// Reenvía la zona local si el último intento no llegó.
  ///
  /// Va ANTES de leer las preferencias del backend en el login: así el
  /// servidor ya tiene el valor corregido cuando se lee, y
  /// sincronizarDesdeBackend no devuelve el usuario a la zona vieja.
  static Future<void> reintentarPendiente(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_clavePendiente) != true) return;

    final zona = prefs.getString(_clave);
    if (zona == null) {
      await prefs.remove(_clavePendiente);
      return;
    }
    try {
      await ApiServiceCore.actualizarPreferencias(usuarioId, zonaHoraria: zona);
      await prefs.remove(_clavePendiente);
    } catch (_) {
      // Sigue pendiente. Se reintentará en el próximo login.
    }
  }

  static Future<void> sincronizarDesdeBackend(String? zonaBackend) async {
    if (zonaBackend == null || zonaBackend.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, zonaBackend);
  }
}
