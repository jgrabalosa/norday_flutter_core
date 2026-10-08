import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio genérico y exportable de efectos de sonido.
/// No conoce el dominio de la app: recibe eventos genéricos y reproduce
/// el archivo mapeado. Si un evento no tiene sonido, no hace nada.
class SonidoService {
  SonidoService._();

  /// Mapa evento → archivo. Para añadir un sonido nuevo (p. ej. 'racha'),
  /// basta con añadir la entrada y el mp3 en assets/sounds/.
  static const Map<String, String> _sonidos = {
    'completar': 'sounds/completar.mp3',
    'logro': 'sounds/logro.mp3',
  };

  /// Los mp3 viven en este paquete, no en la app que lo usa, así que el
  /// prefijo por defecto de audioplayers ('assets/') no vale: hay que
  /// apuntar a la carpeta que Flutter le reserva al paquete en el bundle.
  static final AudioCache _cache = AudioCache(
    prefix: 'packages/norday_flutter_core/assets/',
  );

  static const _claveActivado = 'sonido_activado';

  /// Se mantiene activado por defecto para no cambiar el comportamiento de
  /// usuarios existentes mientras se carga la preferencia local.
  static bool activado = true;

  static bool _contextoConfigurado = false;

  static Future<void> cargarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    activado = prefs.getBool(_claveActivado) ?? true;
  }

  static Future<void> establecerActivado(bool valor) async {
    activado = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveActivado, valor);
  }

  /// Configura el reproductor para "mezclar" con audio de otras apps
  /// (Spotify, etc.) en vez de pedir el foco exclusivo y cortarlas.
  /// Se hace una sola vez, antes del primer sonido reproducido.
  static Future<void> _asegurarContextoAudio() async {
    if (_contextoConfigurado) return;
    _contextoConfigurado = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (_) {
      // El sonido nunca debe romper la app
    }
  }

  static Future<void> reproducir(String evento) async {
    if (!activado) return;
    final ruta = _sonidos[evento];
    if (ruta == null) return;

    await _asegurarContextoAudio();

    try {
      final player = AudioPlayer();
      player.audioCache = _cache;
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource(ruta));
    } catch (_) {
      // El sonido nunca debe romper la app
    }
  }
}
