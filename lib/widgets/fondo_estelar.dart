import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/progreso_dia.dart';
import 'constelaciones.dart';

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
        return ValueListenableBuilder<ProgresoDia>(
          valueListenable: progresoDiaNotifier,
          builder: (context, progreso, child) => CustomPaint(
            painter: _FondoEstelarPainter(id.tokens, progreso),
            child: child,
          ),
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

  /// Cuántos hábitos hay hoy y cuántos están hechos, para dibujar la
  /// constelación del día.
  final ProgresoDia progreso;

  const _FondoEstelarPainter(this.tokens, this.progreso);

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

    _pintarConstelacion(canvas, size);
  }

  /// La constelación va sobre el campo estelar y ocupa la banda central de la
  /// pantalla, no la parte alta: la cabecera de Hoy ("Hoy" y la fecha) es el
  /// único texto que NO va sobre tarjeta opaca, y una figura brillante detrás
  /// de ella rompería el contraste. En la banda central el texto va siempre
  /// sobre tarjeta.
  void _pintarConstelacion(Canvas canvas, Size size) {
    final figura = constelacionPara(progreso.total);
    if (figura == null) return;

    // La caja destino conserva la proporción de la figura: sin esto la Cruz
    // del Sur se estira a lo ancho en una pantalla de móvil y deja de ser
    // una cruz.
    final destino = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.30,
      size.width * 0.72,
      size.height * 0.44,
    );
    final lado = destino.width < destino.height ? destino.width : destino.height;
    final origenX = destino.center.dx - lado / 2;
    final origenY = destino.center.dy - lado / 2;
    Offset situar(Offset p) =>
        Offset(origenX + p.dx * lado, origenY + p.dy * lado);

    final encendidas = progreso.hechos.clamp(0, figura.puntos.length);

    // Lo hecho va en ÁMBAR (`tokens.streak`, el mismo color de las rachas) y
    // lo que falta en blanco frío. No es decoración: mantiene el estado
    // binario. Un ámbar apagado se leería como "a medias", y aquí una
    // estrella está encendida o no está.
    //
    // El ámbar a opacidad PLENA es más seguro que el blanco a 0.85 que había
    // antes, y no es intuición: `streak` (#FFB020) tiene luminancia relativa
    // 0.524 contra el 0.883 de `text` (#EEF2F6), así que estorba mucho menos
    // al texto de la tarjeta que tenga encima. Medido sobre tarjeta al 0.80
    // con la estrella justo debajo: con blanco a 0.85 el peor contraste era
    // `streak` a 4.56; con ámbar a 1.0 sube a 4.98. Se ve más Y pasa AA con
    // más holgura.
    //
    // OJO al aclarar el ámbar hacia el crema: #FFD9A0 sube a luminancia 0.734
    // y ese peor contraste cae a 4.40, por debajo de AA. El color es
    // `tokens.streak` tal cual, no una versión aclarada.
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = tokens.streak.withValues(alpha: 0.38);

    for (final (a, b) in figura.segmentos) {
      if (a < encendidas && b < encendidas) {
        canvas.drawLine(
            situar(figura.puntos[a]), situar(figura.puntos[b]), trazo);
      }
    }

    // El halo va antes que el núcleo para que quede debajo. Es lo que hace
    // que un punto se lea como estrella: sube el área iluminada sin subir el
    // brillo máximo, que es lo único que la medición de contraste limita.
    final halo = Paint()..color = tokens.streak.withValues(alpha: 0.22);
    final punto = Paint();

    for (var i = 0; i < figura.puntos.length; i++) {
      final centro = situar(figura.puntos[i]);
      if (i < encendidas) {
        canvas.drawCircle(centro, 7.0, halo);
        punto.color = tokens.streak;
        canvas.drawCircle(centro, 3.4, punto);
      } else {
        punto.color = tokens.text.withValues(alpha: 0.16);
        canvas.drawCircle(centro, 1.6, punto);
      }
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
      oldDelegate.progreso != progreso;
}
