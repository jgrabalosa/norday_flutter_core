import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

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

/// Campo estelar de la identidad Profundidad: dos nebulosas difusas y un
/// cielo de 44 estrellas fijas, pintados detrás de [child].
///
/// Sólo enciende el `CustomPaint` cuando la identidad equipada resuelve sus
/// superficies como [FormaIdentidad.glass] — las demás identidades no tienen
/// cielo, y con cualquier otra el widget devuelve [child] tal cual, sin coste
/// añadido. Escucha [identidadEquipadaNotifier] para encenderse o apagarse
/// solo al cambiar de identidad.
///
/// Sin [child], este widget necesita que el padre le dé constraints
/// ajustadas —un `Positioned.fill`, un `SizedBox.expand`— o medirá cero y no
/// pintará nada: un `CustomPaint` sin hijo y sin `size` no ocupa espacio por
/// sí mismo.
class FondoEstelar extends StatelessWidget {
  final Widget? child;

  const FondoEstelar({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentidadPaleta>(
      valueListenable: identidadEquipadaNotifier,
      builder: (context, id, child) {
        if (id.forma != FormaIdentidad.glass) {
          return child ?? const SizedBox.shrink();
        }
        return CustomPaint(
          painter: _FondoEstelarPainter(id.tokens),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _FondoEstelarPainter extends CustomPainter {
  /// Los tokens de la identidad equipada, pasados por el widget: el painter
  /// no lee ningún notifier global.
  final TokensContextuales tokens;

  const _FondoEstelarPainter(this.tokens);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Las nebulosas van antes que las estrellas: son el fondo del fondo.
    final nebulosaPrimary = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.44, -0.84),
        radius: 1.3,
        colors: [
          tokens.primary.withValues(alpha: 0.13),
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
          azulNebulosa.withValues(alpha: 0.16),
          azulNebulosa.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.68],
      ).createShader(rect);
    canvas.drawRect(rect, nebulosaAzul);

    final pinturaEstrella = Paint();
    for (final estrella in _estrellas) {
      pinturaEstrella.color = tokens.text.withValues(alpha: estrella.opacidad);
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
      oldDelegate.tokens.text != tokens.text;
}
