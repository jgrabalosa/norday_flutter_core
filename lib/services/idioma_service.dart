import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service_core.dart';

/// Idioma de la app. Motor: no sabe qué textos hay ni de qué app son.
///
/// En el primer arranque se detecta del dispositivo, con caída a español si
/// el idioma del sistema no está entre los soportados. A partir de ahí manda
/// lo que el usuario haya elegido.
///
/// El idioma y la zona horaria son preferencias independientes: se guardan y
/// se cambian por separado.
class IdiomaService {
  static const List<String> soportados = ['es', 'en', 'pt'];
  static const String porDefecto = 'es';

  static const _clave = 'idioma';

  /// Marca que el último cambio local no llegó al backend.
  ///
  /// Mismo problema que en ZonaService: un fallo de red al guardar el idioma
  /// se perdía en silencio y el siguiente login traía el idioma viejo del
  /// servidor, pisando la elección del usuario. Aquí el daño no son las
  /// rachas sino los emails y los push, que el backend redacta con este
  /// valor y salen sin la app abierta.
  static const _clavePendiente = 'idiomaPendienteDeSync';

  /// Escuchado por MaterialApp: cambiarlo repinta la app sin reiniciarla.
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale(porDefecto));

  static List<Locale> get localesSoportados =>
      soportados.map((c) => Locale(c)).toList();

  /// Idioma del dispositivo si lo soportamos; si no, español.
  static String detectarDelDispositivo() {
    final delSistema = PlatformDispatcher.instance.locale.languageCode;
    return soportados.contains(delSistema) ? delSistema : porDefecto;
  }

  /// Llamar al arrancar, antes de runApp, para no pintar en el idioma
  /// equivocado durante un frame.
  static Future<void> cargarAlArrancar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);

    if (guardado != null && soportados.contains(guardado)) {
      localeNotifier.value = Locale(guardado);
      return;
    }

    // Primer arranque: lo detectamos y lo dejamos guardado
    final detectado = detectarDelDispositivo();
    await prefs.setString(_clave, detectado);
    localeNotifier.value = Locale(detectado);
  }

  /// Cambia el idioma, lo persiste y lo sincroniza con el backend (que lo
  /// necesita para los emails y los push, que salen sin la app abierta).
  static Future<void> cambiar(String codigo, {int? usuarioId}) async {
    if (!soportados.contains(codigo)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, codigo);
    localeNotifier.value = Locale(codigo);

    if (usuarioId != null) {
      // Que falle la sincronización no debe deshacer el cambio local: la app
      // ya está en el idioma nuevo. Lo que no puede perderse es que el
      // backend no se enteró, y de eso se encarga la bandera.
      try {
        await ApiServiceCore.actualizarPreferencias(usuarioId, idioma: codigo);
        await prefs.remove(_clavePendiente);
      } catch (_) {
        await prefs.setBool(_clavePendiente, true);
      }
    }
  }

  /// Reenvía el idioma local si el último intento no llegó.
  ///
  /// Va ANTES de leer las preferencias del backend en el login, igual que
  /// ZonaService.reintentarPendiente: así el servidor ya tiene el valor
  /// corregido cuando se lee, y sincronizarDesdeBackend no devuelve al
  /// usuario al idioma viejo.
  static Future<void> reintentarPendiente(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_clavePendiente) != true) return;

    final codigo = prefs.getString(_clave);
    if (codigo == null || !soportados.contains(codigo)) {
      await prefs.remove(_clavePendiente);
      return;
    }
    try {
      await ApiServiceCore.actualizarPreferencias(usuarioId, idioma: codigo);
      await prefs.remove(_clavePendiente);
    } catch (_) {
      // Sigue pendiente. Se reintentará en el próximo login.
    }
  }

  /// Alinea el estado local con lo que diga el backend tras iniciar sesión.
  static Future<void> sincronizarDesdeBackend(String? idiomaBackend) async {
    if (idiomaBackend == null || !soportados.contains(idiomaBackend)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, idiomaBackend);
    localeNotifier.value = Locale(idiomaBackend);
  }

  static String get actual => localeNotifier.value.languageCode;
}
