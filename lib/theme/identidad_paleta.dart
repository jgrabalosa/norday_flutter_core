import 'app_theme.dart';

/// Cómo se resuelve visualmente una tarjeta/superficie de esta identidad.
/// No hay "default": cada identidad declara la suya explícitamente.
enum FormaIdentidad {
  /// Profundidad — degradado + sombra en 3 capas + inset highlight.
  glass,

  /// Neotokyo+ — esquina cortada real vía clip-path.
  chamfer,

  /// Alba — sin superficie propia, borde fino o nada.
  hairline,

  /// Dulce — radio casi total, sombra de color "glow".
  pill,
}

/// Qué se pinta detrás de las pantallas de esta identidad, y qué dibuja su
/// capa de progreso.
///
/// Separado de [FormaIdentidad] a propósito, aunque hoy sean uno a uno:
/// `forma` dice cómo se resuelve una tarjeta y esto dice qué hay detrás de la
/// pantalla entera. Confundirlos es lo que haría que tocar una superficie
/// cambiase el cielo sin querer.
enum FondoIdentidadTipo {
  /// Profundidad — campo estelar y constelación del día.
  cielo,

  /// Neotokyo+ — una ciudad cuyas ventanas se encienden. Sin pintar todavía.
  ciudad,

  /// Alba — la luz que sube. Sin pintar todavía.
  luz,

  /// Dulce — algo que se acumula. Sin pintar todavía.
  acumulacion,
}

/// A qué distancia está el mundo en esta pantalla.
///
/// No es un número a propósito. El 0.55 con el que Profundidad atenúa su cielo
/// sólo significa algo para un campo de estrellas: Neotokyo+ apagará su ciudad
/// y Alba bajará su luz. Aquí se dice el nivel; la traducción es de cada
/// identidad.
enum NivelFondo {
  /// Nivel 1 — las tres pestañas del shell. El mundo entero.
  mundo,

  /// Nivel 2 — lo que se abre encima con `Navigator.push`: Colección, Logros,
  /// Tienda, Perfil y Mascota. Habitaciones del mismo mundo.
  habitacion,
}

/// Una identidad completa: color, tipografía, radios, forma y tiempo.
///
/// El paso anterior del sistema sólo tenía color (`TokensContextuales`), y eso
/// hacía que dos temas distintos fueran la misma pantalla repintada. Aquí el
/// color es sólo uno de los cinco ejes: cambiar de identidad cambia también
/// con qué letra se escribe, cuánto se redondea, cómo se resuelve una
/// superficie y a qué ritmo respira la pantalla.
///
/// `tokens` sigue siendo el modelo de color de siempre, sin tocar: quien hoy
/// sólo consume color no se entera de que existe nada de esto.
class IdentidadPaleta {
  /// Código de producto en el catálogo de tienda — el mismo que manda el
  /// backend en el inventario. Nada de ids cableados en el cliente.
  final String codigo;

  /// Nombre visible, ej. "Neotokyo+".
  final String nombre;

  /// Los colores — el modelo existente, sin tocar.
  final TokensContextuales tokens;

  /// Familia para títulos, cifras, chips y UI corta. Es la única que admite
  /// mayúsculas, tracking o itálica.
  ///
  /// Los nombres son los de Google Fonts tal cual (`GoogleFonts.getFont`
  /// resuelve por este string): si no coincide exactamente, no hay fuente.
  final String fontDisplay;

  /// Familia del cuerpo. Es SIEMPRE la más legible de la identidad — nunca
  /// mayúsculas, tracking ni itálica: esas variaciones son sólo para
  /// [fontDisplay], jamás para párrafos largos.
  final String fontBody;

  /// Familia de un detalle puntual y único de la identidad (ej. Caveat en
  /// Dulce). Nunca de uso general: si aparece dos veces en una pantalla, se
  /// está usando mal.
  final String? fontAcento;

  /// Radio del elemento protagonista de la pantalla: tarjeta de identidad,
  /// burbuja de mascota, tarjeta de swipe.
  final double radioHero;

  /// Radio de listas y tarjetas de contenido: un hábito, una fila de lista.
  final double radioSecundario;

  /// Corte de la esquina. Sólo se usa si [forma] es [FormaIdentidad.chamfer].
  ///
  /// Token único a propósito: el mismo valor en las cuatro apariciones (badge,
  /// burbuja, chip, tarjeta). Antes salían valores distintos por descuido y el
  /// corte dejaba de leerse como un rasgo de la identidad.
  final double chaflan;

  /// Cómo se pinta una superficie en esta identidad.
  final FormaIdentidad forma;

  /// Qué hay detrás de las pantallas de esta identidad.
  final FondoIdentidadTipo fondo;

  /// El ritmo del gesto propio de la identidad (breathing, flicker, bloom,
  /// jelly). Aquí sólo vive el dato: cada pantalla que lo consuma tiene que
  /// respetar `MediaQuery.of(context).disableAnimations`, igual que ya hace
  /// `MascotaAnimadaViva`.
  final Duration duracionAnimacionFirma;

  const IdentidadPaleta({
    required this.codigo,
    required this.nombre,
    required this.tokens,
    required this.fontDisplay,
    required this.fontBody,
    this.fontAcento,
    required this.radioHero,
    required this.radioSecundario,
    this.chaflan = 10.0,
    required this.forma,
    required this.fondo,
    required this.duracionAnimacionFirma,
  });
}
