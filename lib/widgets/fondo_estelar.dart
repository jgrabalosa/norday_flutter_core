import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';

/// Una estrella del cielo de Profundidad. Posición normalizada 0..1 para que
/// valga a cualquier tamaño de pantalla.
class _Estrella {
  final double x;
  final double y;
  final double radio;
  final double opacidad;

  const _Estrella({
    required this.x,
    required this.y,
    required this.radio,
    required this.opacidad,
  });
}

const List<double> _radiosEstrella = [0.8, 0.8, 1.0, 1.0, 1.1, 1.4, 1.7];

List<_Estrella> _generarEstrellas() {
  final random = Random(7);
  return List.generate(44, (_) {
    return _Estrella(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radio: _radiosEstrella[random.nextInt(_radiosEstrella.length)],
      opacidad: 0.18 + random.nextDouble() * (0.85 - 0.18),
    );
  });
}

/// Semilla fija (`Random(7)`) y generada una única vez al cargar el fichero:
/// el cielo tiene que ser idéntico en cada arranque y en cada `build`, nunca
/// recalculado dentro de `paint`.
final List<_Estrella> _estrellas = _generarEstrellas();

/// Campo estelar de Profundidad: dos nebulosas difusas y un cielo de 44
/// estrellas fijas.
///
/// NO se exporta en el barrel. La puerta es `FondoIdentidad`, que es quien
/// decide si esta identidad tiene cielo. Aquí ya no se comprueba nada: si este
/// widget se construye es porque el despacho ya dijo que sí.
class FondoEstelar extends StatelessWidget {
  /// Los colores de la identidad, que los da el despachador. Este widget no
  /// lee ningún notifier: quien escucha es `FondoIdentidad`.
  final TokensContextuales tokens;

  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoEstelar({
    super.key,
    required this.tokens,
    required this.nivel,
  });

  /// Cuánta luz llega. Es el mismo cielo en los dos casos —las mismas 44
  /// estrellas en las mismas posiciones, las mismas dos nebulosas—, sólo que
  /// más lejos. Menos estrellas sería OTRO cielo, y el nivel 2 son
  /// habitaciones del mismo mundo, no otro sitio.
  ///
  /// Un solo factor para nebulosas y estrellas, y no uno por cosa, porque es
  /// lo que hace la distancia de verdad: todo se apaga a la vez.
  ///
  /// Aquí no hay suelo de contraste que respetar: esto va detrás del contenido
  /// y ninguna información depende de ello.
  double get _atenuacion =>
      nivel == NivelFondo.mundo ? 1.0 : 0.55;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FondoEstelarPainter(tokens, _atenuacion),
    );
  }
}

class _FondoEstelarPainter extends CustomPainter {
  /// Los tokens de la identidad equipada, pasados por el widget: el painter
  /// no lee ningún notifier global.
  final TokensContextuales tokens;

  /// Ver [FondoEstelar.atenuacion].
  final double atenuacion;

  const _FondoEstelarPainter(this.tokens, this.atenuacion);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Las nebulosas van antes que las estrellas: son el fondo del fondo.
    final nebulosaPrimary = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.44, -0.84),
        radius: 1.3,
        colors: [
          tokens.primary.withValues(alpha: 0.13 * atenuacion),
          tokens.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.62],
      ).createShader(rect);
    canvas.drawRect(rect, nebulosaPrimary);

    const azulNebulosa = Color(0xFF4060AA);
    final nebulosaAzul = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.64, 0.64),
        radius: 1.0,
        colors: [
          azulNebulosa.withValues(alpha: 0.16 * atenuacion),
          azulNebulosa.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.68],
      ).createShader(rect);
    canvas.drawRect(rect, nebulosaAzul);

    final pinturaEstrella = Paint();
    for (final estrella in _estrellas) {
      pinturaEstrella.color =
          tokens.text.withValues(alpha: estrella.opacidad * atenuacion);
      canvas.drawCircle(
        Offset(estrella.x * size.width, estrella.y * size.height),
        estrella.radio,
        pinturaEstrella,
      );
    }
  }

  // `TokensContextuales` no define `operator ==`, así que comparar el objeto
  // entero compara referencias, no valores: funciona hoy sólo porque las
  // cuatro paletas son `const` y Dart las canoniza. En cuanto alguien
  // construya tokens en tiempo de ejecución, esa comparación deja de detectar
  // "son iguales" y repinta cada frame. Se comparan los dos campos que el
  // painter usa de verdad, que es lo que realmente decide si hay algo nuevo
  // que pintar.
  @override
  bool shouldRepaint(covariant _FondoEstelarPainter oldDelegate) =>
      oldDelegate.tokens.primary != tokens.primary ||
      oldDelegate.tokens.text != tokens.text ||
      oldDelegate.atenuacion != atenuacion;
}
