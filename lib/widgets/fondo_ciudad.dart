import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/progreso_dia.dart';

/// Un edificio del perfil de la ciudad de Neotokyo+.
///
/// [x] y [ancho] son fracciones del ancho de la pantalla; [alto] es una
/// fracción de la banda de ciudad, no de la pantalla. Normalizado para que el
/// mismo perfil valga a cualquier tamaño, igual que las estrellas de
/// Profundidad.
class _Bloque {
  final double x;
  final double ancho;
  final double alto;

  const _Bloque({required this.x, required this.ancho, required this.alto});
}

/// El perfil de la ciudad, escrito a mano y no generado.
///
/// En Profundidad las 44 estrellas salen de un `Random(7)` porque da igual
/// dónde caiga cada una. Aquí no: un perfil urbano tiene ritmo —torres altas
/// y estrechas junto a bloques bajos y anchos— y eso se elige, no se sortea.
/// Además así no hay semilla que pueda cambiar de significado entre versiones
/// de Dart.
///
/// Empieza en -0.02 y acaba pasado el 1.0 a propósito: la ciudad se sale por
/// los dos lados y no enseña sus extremos.
const List<_Bloque> _bloques = [
  _Bloque(x: -0.0200, ancho: 0.1007, alto: 0.6918),
  _Bloque(x: 0.0998, ancho: 0.1019, alto: 0.6555),
  _Bloque(x: 0.2168, ancho: 0.0766, alto: 0.6583),
  _Bloque(x: 0.3089, ancho: 0.1314, alto: 0.3659),
  _Bloque(x: 0.4519, ancho: 0.0682, alto: 0.8668),
  _Bloque(x: 0.5364, ancho: 0.0638, alto: 0.9875),
  _Bloque(x: 0.6198, ancho: 0.1189, alto: 0.7309),
  _Bloque(x: 0.7485, ancho: 0.0614, alto: 0.6699),
  _Bloque(x: 0.8186, ancho: 0.0771, alto: 0.4694),
  _Bloque(x: 0.9041, ancho: 0.1018, alto: 0.6084),
];

/// Qué parte de la pantalla ocupa la ciudad, medida desde abajo.
const double _bandaCiudad = 0.42;

/// La rejilla de ventanas, en píxeles lógicos y NO normalizada.
///
/// Es deliberado: si el tamaño de la ventana fuese una fracción de la
/// pantalla, en un móvil alto saldrían estiradas —5 de ancho por 17 de alto,
/// medido—. En píxeles se mantienen cuadradas y sólo cambia cuántas caben,
/// que es justo lo que hace una ciudad de verdad al alejarse.
const double _ventanaAncho = 4.0;
const double _ventanaAlto = 6.0;
const double _pasoX = 10.0;
const double _pasoY = 14.0;
const double _margenLateral = 5.0;
const double _margenSuperior = 8.0;

/// Amarillo de ventana encendida. Literal y no token, como el azul de nebulosa
/// de `FondoEstelar`: ninguna paleta tiene un amarillo, y éste es de la
/// ciudad, no de la identidad.
const Color _amarilloVentana = Color(0xFFFFE347);

/// Decide, sin guardar nada, si una ventana concreta está encendida.
///
/// La web baraja un array de ventanas y enciende las N primeras. Aquí no se
/// puede: cuántas ventanas hay depende del tamaño de la pantalla, así que un
/// array barajado de longitud fija no valdría. Esto da un valor estable en
/// 0..1 para cada posición, y se enciende si cae por debajo de la fracción.
/// Mismo efecto disperso, sin estado, y correcto a cualquier tamaño.
double _ruido(int bloque, int columna, int fila) {
  var h = (bloque * 73856093) ^ (columna * 19349663) ^ (fila * 83492791);
  h = h & 0x7FFFFFFF;
  h = (h ^ (h >> 13)) * 1274126177;
  h = h & 0x7FFFFFFF;
  return (h % 100000) / 100000.0;
}

/// La ciudad de Neotokyo+: un perfil de edificios cuyas ventanas se encienden
/// con el progreso del día.
///
/// NO se exporta en el barrel. La puerta es `FondoIdentidad`.
///
/// A diferencia de `FondoEstelar`, este widget SÍ escucha el progreso: en
/// Neotokyo+ el fondo y la capa de progreso son la misma cosa —la ciudad es el
/// fondo y sus ventanas son el progreso—, así que no hace falta la capa de
/// delante. Escucha él, como hace `CapaConstelacion`, y no el despachador: así
/// Profundidad no se entera de nada.
class FondoCiudad extends StatelessWidget {
  /// Los colores de la identidad, que los da el despachador.
  final TokensContextuales tokens;

  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoCiudad({
    super.key,
    required this.tokens,
    required this.nivel,
  });

  /// La ciudad más apagada, que es como Neotokyo+ dice "esto está más lejos".
  /// El mismo 0.55 que Profundidad aplica a su cielo, y por el mismo motivo:
  /// es la misma ciudad, no otra.
  double get _atenuacion => nivel == NivelFondo.mundo ? 1.0 : 0.55;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgresoDia>(
      valueListenable: progresoDiaNotifier,
      builder: (context, progreso, _) => CustomPaint(
        painter: _FondoCiudadPainter(tokens, _atenuacion, progreso),
      ),
    );
  }
}

class _FondoCiudadPainter extends CustomPainter {
  final TokensContextuales tokens;
  final double atenuacion;
  final ProgresoDia progreso;

  const _FondoCiudadPainter(this.tokens, this.atenuacion, this.progreso);

  /// Qué fracción de las ventanas se enciende.
  ///
  /// El 0.55 del final es el mismo tope que usa la landing: ni con el día
  /// entero completado se enciende la ciudad al completo. Una ciudad con
  /// TODAS las ventanas dadas no parece una ciudad viva, parece un error.
  ///
  /// Con `total` a cero la fracción es cero, pero los edificios SÍ se pintan:
  /// los bloques son el equivalente del cielo, no del progreso.
  double get _fraccionEncendida =>
      progreso.total > 0 ? (progreso.hechos / progreso.total) * 0.55 : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final banda = size.height * _bandaCiudad;
    final suelo = size.height;

    final pinturaBloque = Paint()
      ..color = tokens.surface2.withValues(alpha: atenuacion);

    // Apagada y encendida se preparan una vez y se reutilizan: hay varios
    // cientos de ventanas y crear un Paint por ventana se nota.
    final apagada = Paint()
      ..color = _amarilloVentana.withValues(alpha: 0.04 * atenuacion);
    final encendida = Paint()
      ..color = _amarilloVentana.withValues(alpha: 0.80 * atenuacion);

    final fraccion = _fraccionEncendida;

    for (var i = 0; i < _bloques.length; i++) {
      final b = _bloques[i];
      final izquierda = b.x * size.width;
      final ancho = b.ancho * size.width;
      final alto = b.alto * banda;
      final arriba = suelo - alto;

      canvas.drawRect(
        Rect.fromLTWH(izquierda, arriba, ancho, alto),
        pinturaBloque,
      );

      var columna = 0;
      for (
        var vx = izquierda + _margenLateral;
        vx + _ventanaAncho <= izquierda + ancho - _margenLateral;
        vx += _pasoX
      ) {
        var fila = 0;
        for (
          var vy = arriba + _margenSuperior;
          vy + _ventanaAlto <= suelo;
          vy += _pasoY
        ) {
          canvas.drawRect(
            Rect.fromLTWH(vx, vy, _ventanaAncho, _ventanaAlto),
            _ruido(i, columna, fila) < fraccion ? encendida : apagada,
          );
          fila++;
        }
        columna++;
      }
    }
  }

  // Mismo motivo que en `_FondoEstelarPainter`: `TokensContextuales` no define
  // `operator ==`, así que se comparan los campos que el painter usa de
  // verdad. `ProgresoDia` sí lo define, así que ése se compara entero.
  @override
  bool shouldRepaint(covariant _FondoCiudadPainter oldDelegate) =>
      oldDelegate.tokens.surface2 != tokens.surface2 ||
      oldDelegate.atenuacion != atenuacion ||
      oldDelegate.progreso != progreso;
}
