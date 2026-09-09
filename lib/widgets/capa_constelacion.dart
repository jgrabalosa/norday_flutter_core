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
    final destelloHorizontal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = tokens.streak.withValues(alpha: 0.55);
    final apagada = Paint()..color = tokens.text.withValues(alpha: 0.16);

    for (var i = 0; i < figura.puntos.length; i++) {
      final centro = situar(figura.puntos[i]);
      if (i < encendidas) {
        // El resplandor: un degradado radial que cae a cero, no un círculo
        // plano. El disco duro se recorta contra lo que hay debajo; el
        // degradado se funde con él.
        final radioResplandor = Rect.fromCircle(center: centro, radius: 9.0);
        final resplandor = Paint()
          ..shader = RadialGradient(
            colors: [
              tokens.streak.withValues(alpha: 0.30),
              tokens.streak.withValues(alpha: 0.10),
              tokens.streak.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(radioResplandor);
        canvas.drawCircle(centro, 9.0, resplandor);

        // El núcleo, casi blanco: una estrella real tiene el centro
        // quemado y el color en el halo, no al revés.
        canvas.drawCircle(centro, 2.2, nucleo);

        // El destello en cruz: lo que el ojo reconoce al instante como
        // estrella, y es barato.
        canvas.drawLine(Offset(centro.dx - 5.5, centro.dy),
            Offset(centro.dx + 5.5, centro.dy), destelloHorizontal);
        canvas.drawLine(Offset(centro.dx, centro.dy - 5.5),
            Offset(centro.dx, centro.dy + 5.5), destelloHorizontal);
      } else {
        canvas.drawCircle(centro, 1.6, apagada);
      }
    }

    canvas.restore();
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
