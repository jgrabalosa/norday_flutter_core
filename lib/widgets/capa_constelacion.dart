import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/progreso_dia.dart';
import 'constelaciones.dart';

/// La constelación del día de Profundidad, en su propia capa por ENCIMA del
/// contenido.
///
/// NO se exporta en el barrel. La puerta es `CapaProgresoIdentidad`. Pinta con
/// mezcla aditiva (ver [_CapaConstelacionPainter]) y lleva [IgnorePointer]
/// dentro, imprescindible para que la capa no se coma los toques de lo que hay
/// debajo.
class CapaConstelacion extends StatelessWidget {
  /// Los colores de la identidad, que los da el despachador.
  final TokensContextuales tokens;

  const CapaConstelacion({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgresoDia>(
      valueListenable: progresoDiaNotifier,
      builder: (context, progreso, child) => IgnorePointer(
        child: CustomPaint(
          painter: _CapaConstelacionPainter(tokens, progreso),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CapaConstelacionPainter extends CustomPainter {
  /// Los tokens de la identidad equipada, pasados por el widget: el painter
  /// no lee ningún notifier global.
  final TokensContextuales tokens;

  /// Cuántos hábitos hay hoy y cuántos están hechos, para dibujar la
  /// constelación del día.
  final ProgresoDia progreso;

  const _CapaConstelacionPainter(this.tokens, this.progreso);

  /// La constelación ocupa la banda central de la pantalla, no la parte
  /// alta: la cabecera de Hoy ("Hoy" y la fecha) es el único texto que NO va
  /// sobre tarjeta opaca, y una figura brillante detrás de ella rompería el
  /// contraste. En la banda central el texto va siempre sobre tarjeta.
  @override
  void paint(Canvas canvas, Size size) {
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

    // Toda la constelación va dentro de una capa aditiva: la capa va
    // DELANTE del contenido, así que no hay superficie que atenúe la luz
    // como pasaba detrás. La luz se suma a lo que hay debajo en vez de
    // sustituirlo — una estrella sobre texto blanco lo vuelve más blanco,
    // nunca lo borra — y es además lo que hace la luz de verdad.
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.plus);

    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = tokens.streak.withValues(alpha: 0.38);

    for (final (a, b) in figura.segmentos) {
      final pa = situar(figura.puntos[a]);
      final pb = situar(figura.puntos[b]);
      final aEncendida = a < encendidas;
      final bEncendida = b < encendidas;

      if (aEncendida && bEncendida) {
        canvas.drawLine(pa, pb, trazo);
      } else if (aEncendida || bEncendida) {
        // Un trazo con un solo extremo encendido no desaparece: sale de la
        // estrella que ya está y se apaga antes de llegar a la que falta.
        //
        // Sin esto la figura a medias no se lee. El caso peor era la Cruz del
        // Sur con 3 de 4: sus dos segmentos no comparten ningún punto, así
        // que salía la barra vertical y una estrella suelta al lado, que no
        // parece media cruz sino una errata. El cabo le da su medio brazo y
        // la cruz se reconoce. Vale para las ocho figuras, no sólo para ésa.
        //
        // El punto apagado ya se dibuja tenue más abajo, así que el cabo no
        // apunta al vacío: va hacia una estrella que se ve.
        final desde = aEncendida ? pa : pb;
        final hacia = aEncendida ? pb : pa;
        canvas.drawLine(
          desde,
          hacia,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(
              desde,
              hacia,
              [
                tokens.streak.withValues(alpha: 0.22),
                tokens.streak.withValues(alpha: 0.0),
              ],
              [0.0, 0.55],
            ),
        );
      }
    }

    final nucleo = Paint()..color = tokens.text;
    final cuerpo = Paint()..color = tokens.text.withValues(alpha: 0.95);
    final borde = Paint()..color = tokens.streak.withValues(alpha: 0.55);
    final diagonal = Paint()..color = tokens.streak.withValues(alpha: 0.35);
    final apagada = Paint()..color = tokens.text.withValues(alpha: 0.16);

    for (var i = 0; i < figura.puntos.length; i++) {
      final centro = situar(figura.puntos[i]);
      if (i < encendidas) {
        // El resplandor: un degradado radial que cae a cero, no un círculo
        // plano. El disco duro se recorta contra lo que hay debajo; el
        // degradado se funde con él.
        final radioResplandor = Rect.fromCircle(center: centro, radius: 17.0);
        final resplandor = Paint()
          ..shader = RadialGradient(
            colors: [
              tokens.streak.withValues(alpha: 0.34),
              tokens.streak.withValues(alpha: 0.12),
              tokens.streak.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(radioResplandor);
        canvas.drawCircle(centro, 17.0, resplandor);

        // Dos puntas diagonales, cortas y tenues, detrás del destello: le
        // dan brillo de estrella sin competir con las cuatro puntas grandes.
        canvas.drawPath(_puntasDiagonales(centro, 5.0, 1.0), diagonal);

        // El destello de cuatro puntas, con los lados curvados hacia dentro.
        // Primero el borde ámbar, algo mayor, y encima el cuerpo casi blanco.
        // Es lo que separa la constelación del cielo de fondo, cuyas
        // estrellas más grandes miden 1.7.
        canvas.drawPath(_destello(centro, 9.5), borde);
        canvas.drawPath(_destello(centro, 7.0), cuerpo);

        // El núcleo: una estrella real tiene el centro quemado y el color
        // en el halo, no al revés.
        canvas.drawCircle(centro, 2.0, nucleo);
      } else {
        canvas.drawCircle(centro, 1.6, apagada);
      }
    }

    canvas.restore();
  }

  /// Una astroide de radio [r] centrada en [c]: x = r·cos³t, y = r·sin³t.
  /// Cuatro puntas con los lados curvados hacia dentro, que es la silueta
  /// que el ojo lee como destello.
  static Path _destello(Offset c, double r) {
    const pasos = 64;
    final path = Path();
    for (var k = 0; k <= pasos; k++) {
      final t = 2 * math.pi * k / pasos;
      final cs = math.cos(t);
      final sn = math.sin(t);
      final x = c.dx + r * cs * cs * cs;
      final y = c.dy + r * sn * sn * sn;
      if (k == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// Cuatro triángulos finos a 45°, de [largo] desde el centro y [ancho] en
  /// la base.
  static Path _puntasDiagonales(Offset c, double largo, double ancho) {
    final path = Path();
    for (var k = 0; k < 4; k++) {
      final a = math.pi / 4 + k * math.pi / 2;
      final dx = math.cos(a);
      final dy = math.sin(a);
      final px = -dy * ancho / 2;
      final py = dx * ancho / 2;
      path
        ..moveTo(c.dx + px, c.dy + py)
        ..lineTo(c.dx + dx * largo, c.dy + dy * largo)
        ..lineTo(c.dx - px, c.dy - py)
        ..close();
    }
    return path;
  }

  // `TokensContextuales` no define `operator ==`, así que comparar el
  // objeto entero compara referencias, no valores: funciona hoy sólo porque
  // las cuatro paletas son `const` y Dart las canoniza. `ProgresoDia` sí
  // define `operator ==`, así que ese campo se compara por valor.
  @override
  bool shouldRepaint(covariant _CapaConstelacionPainter oldDelegate) =>
      oldDelegate.tokens.primary != tokens.primary ||
      oldDelegate.tokens.streak != tokens.streak ||
      oldDelegate.progreso != progreso;
}
