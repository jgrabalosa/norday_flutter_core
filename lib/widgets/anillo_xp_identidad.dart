import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// El progreso de nivel, como aro alrededor de la mascota en vez de como barra
/// debajo. La barra decía lo mismo, pero separaba el dato de a quién se
/// refiere; el aro lo pone literalmente alrededor de Nori.
///
/// Recibe el progreso ya calculado: quien lo usa sabe de XP, este widget no.
/// Como el resto del rework, el tratamiento se elige por [FormaIdentidad].
class AnilloXpIdentidad extends StatelessWidget {
  /// Diámetro exterior del aro.
  final double tamano;

  /// Progreso en [0,1]. Se recorta aquí, así que un valor fuera de rango no
  /// pinta un arco de más de una vuelta.
  final double pct;

  const AnilloXpIdentidad({
    super.key,
    required this.tamano,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final sinAnimaciones = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SizedBox(
      width: tamano,
      height: tamano,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: pct.clamp(0.0, 1.0)),
        // El arco crece hasta su valor al cargar y al ganar XP. Con "reducir
        // movimiento" salta directo al valor final: la duración a cero deja el
        // widget exactamente igual de correcto, sólo que sin recorrido.
        duration:
            sinAnimaciones ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, progreso, _) => CustomPaint(
          painter: _AnilloXpPainter(
            forma: id.forma,
            progreso: progreso,
            color: t.primary,
            colorPista: t.surface2,
          ),
        ),
      ),
    );
  }
}

/// Grosor y remate de cada forma. El resto de la diferencia (glow, segmentos)
/// no cabe en un número y se resuelve en el propio pintado.
class _TrazoAnillo {
  final double grosor;
  final StrokeCap remate;
  final double alfaPista;

  const _TrazoAnillo({
    required this.grosor,
    required this.remate,
    required this.alfaPista,
  });
}

const _trazoGlass =
    _TrazoAnillo(grosor: 7, remate: StrokeCap.round, alfaPista: 0.55);
const _trazoChamfer =
    _TrazoAnillo(grosor: 5, remate: StrokeCap.butt, alfaPista: 0.45);
const _trazoHairline =
    _TrazoAnillo(grosor: 1.5, remate: StrokeCap.butt, alfaPista: 0.30);
const _trazoPill =
    _TrazoAnillo(grosor: 12, remate: StrokeCap.round, alfaPista: 0.75);

class _AnilloXpPainter extends CustomPainter {
  final FormaIdentidad forma;
  final double progreso;
  final Color color;
  final Color colorPista;

  _AnilloXpPainter({
    required this.forma,
    required this.progreso,
    required this.color,
    required this.colorPista,
  });

  /// Arriba, las 12. Que el progreso empiece donde empieza un reloj es lo
  /// único que no hay que explicarle a nadie.
  static const _inicio = -math.pi / 2;

  _TrazoAnillo get _trazo => switch (forma) {
        FormaIdentidad.glass => _trazoGlass,
        FormaIdentidad.chamfer => _trazoChamfer,
        FormaIdentidad.hairline => _trazoHairline,
        FormaIdentidad.pill => _trazoPill,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = _trazo;
    final centro = size.center(Offset.zero);
    final radio = (size.shortestSide - trazo.grosor) / 2;
    final caja = Rect.fromCircle(center: centro, radius: radio);
    final barrido = 2 * math.pi * progreso.clamp(0.0, 1.0);

    switch (forma) {
      case FormaIdentidad.glass:
        _pista(canvas, centro, radio, trazo);
        if (barrido <= 0) return;
        // El glow es un arco desenfocado DEBAJO del nítido, no una sombra del
        // mismo trazo: así el blur se calcula una vez por pintado y no obliga
        // a redibujar una capa de sombra en cada fotograma.
        canvas.drawArc(
          caja,
          _inicio,
          barrido,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trazo.grosor * 1.5
            ..strokeCap = trazo.remate
            ..color = color.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawArc(caja, _inicio, barrido, false, _arco(trazo, color));

      case FormaIdentidad.chamfer:
        // Segmentado tipo HUD: 40 casillas y se encienden las que toquen. El
        // hueco entre casillas es fijo en ángulo, no en píxeles, para que el
        // ritmo no cambie con el tamaño.
        const casillas = 40;
        const paso = 2 * math.pi / casillas;
        const hueco = paso * 0.34;
        final encendidas = (progreso.clamp(0.0, 1.0) * casillas).floor();
        final apagado = _arco(trazo, colorPista.withValues(alpha: trazo.alfaPista));
        final encendido = _arco(trazo, color);
        for (var i = 0; i < casillas; i++) {
          canvas.drawArc(
            caja,
            _inicio + i * paso + hueco / 2,
            paso - hueco,
            false,
            i < encendidas ? encendido : apagado,
          );
        }

      case FormaIdentidad.hairline:
        // Un hilo. Alba no subraya nada más de lo imprescindible, y el aro no
        // es la excepción: se ve si lo buscas.
        _pista(canvas, centro, radio, trazo);
        if (barrido <= 0) return;
        canvas.drawArc(caja, _inicio, barrido, false, _arco(trazo, color));

      case FormaIdentidad.pill:
        _pista(canvas, centro, radio, trazo);
        if (barrido <= 0) return;
        canvas.drawArc(caja, _inicio, barrido, false, _arco(trazo, color));
        // Perdigón en la punta: remata el trazo grueso y da un punto donde
        // mirar mientras el aro crece.
        final punta = _inicio + barrido;
        canvas.drawCircle(
          centro + Offset(math.cos(punta), math.sin(punta)) * radio,
          trazo.grosor * 0.34,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
    }
  }

  Paint _arco(_TrazoAnillo trazo, Color c) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = trazo.grosor
    ..strokeCap = trazo.remate
    ..color = c;

  void _pista(
      Canvas canvas, Offset centro, double radio, _TrazoAnillo trazo) {
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = trazo.grosor
        ..color = colorPista.withValues(alpha: trazo.alfaPista),
    );
  }

  @override
  bool shouldRepaint(_AnilloXpPainter old) =>
      old.progreso != progreso ||
      old.forma != forma ||
      old.color != color ||
      old.colorPista != colorPista;
}
