import 'package:shared_preferences/shared_preferences.dart';

/// Si el recorrido guiado ya se hizo. Sólo eso: un sí o un no.
///
/// NO se guarda por qué paso iba, y es deliberado. El punto de partida del
/// recorrido se deduce del estado real de la app —si ya hay hábitos creados,
/// se entra directamente por el tramo de explicación—, y esa capacidad hace
/// falta de todas formas para quien lo relanza desde el menú con la app ya
/// montada. Teniéndola, la app cerrada a medias se resuelve sola: no hace
/// falta un número de paso guardado que mañana apunte a un paso que ya no
/// existe.
///
/// Es local y por dispositivo a propósito. No vale nada si se pierde, así que
/// no arrastra migración ni sincronización con el backend, a diferencia de
/// IdiomaService o ZonaService. Reinstalar la app repite el recorrido.
class RecorridoService {
  static const String _clave = 'recorridoHecho';

  static Future<bool> yaHecho() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clave) ?? false;
  }

  /// Se llama al terminar el recorrido y también al abandonarlo: quien lo
  /// salta no quiere que le vuelva a saltar solo en el siguiente arranque.
  /// Para volver a verlo a propósito está la entrada del menú.
  static Future<void> marcarHecho() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, true);
  }

  /// La entrada del menú. Sólo borra la marca; no arranca nada por su cuenta.
  /// Quien llame decide si lanza el recorrido en ese mismo momento.
  static Future<void> reiniciar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
