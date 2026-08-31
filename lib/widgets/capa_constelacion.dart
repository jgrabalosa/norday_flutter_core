import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/progreso_dia.dart';
import 'constelaciones.dart';

/// La constelación del día, en su propia capa por ENCIMA del contenido.
///
/// Sólo se enciende cuando la identidad equipada resuelve sus superficies
/// como [FormaIdentidad.glass] — las demás identidades no tienen cielo.
/// Pensado para ir en un `Positioned.fill` por encima de las tarjetas: por
/// eso pinta con mezcla aditiva (ver [_CapaConstelacionPainter]) y por eso
/// envuelve el `CustomPaint` en [IgnorePointer], imprescindible para que la
/// capa no se coma los toques de lo que hay debajo.
class CapaConstelacion extends StatelessWidget {
  const CapaConstelacion({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentidadPaleta>(
      valueListenable: identidadEquipadaNotifier,
      builder: (context, id, child) {
        if (id.forma != FormaIdentidad.glass) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<ProgresoDia>(
          valueListenable: progresoDiaNotifier,
          builder: (context, progreso, child) => IgnorePointer(
            child: CustomPaint(
              painter: _CapaConstelacionPainter(id.tokens, progreso),
              size: Size.infinite,
            ),
          ),
        );
      },
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
      if (a < encendidas && b < encendidas) {
        canvas.drawLine(
            situar(figura.puntos[a]), situar(figura.puntos[b]), trazo);
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
