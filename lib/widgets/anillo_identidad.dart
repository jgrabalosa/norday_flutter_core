import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Un aro de progreso con el trazo de la identidad equipada. Lo usan el XP de
/// la mascota (rodeándola, a ~320px) y el resumen del día (a 64px, dentro de
/// `AnilloProgreso`), así que el grosor va en fracción del diámetro y no en
/// píxeles: el mismo aro tiene que leerse igual de grueso a los dos tamaños.
///
/// Recibe el progreso ya calculado: quien lo usa sabe si son XP o hábitos,
/// este widget no. Como el resto del sistema, el tratamiento se elige por
/// [FormaIdentidad] y no por el código de la identidad.
class AnilloIdentidad extends StatelessWidget {
  /// Diámetro exterior del aro.
  final double tamano;

  /// Progreso en [0,1]. Se recorta aquí, así que un valor fuera de rango no
  /// pinta un arco de más de una vuelta.
  final double pct;

  /// Color del arco. Por defecto el primario de la identidad; se puede pasar
  /// para quien ya venía eligiéndolo (`AnilloProgreso`).
  final Color? color;

  /// Color de la pista de fondo. Por defecto `inactivo`, que es el token que
  /// nombra este trabajo. Quien lo pase explícitamente está tomando una
  /// decisión de tema desde fuera de la paleta: piénsalo dos veces.
  final Color? colorPista;

  const AnilloIdentidad({
    super.key,
    required this.tamano,
    required this.pct,
    this.color,
    this.colorPista,
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
        // El arco crece hasta su valor al cargar y al avanzar. Con "reducir
        // movimiento" salta directo al valor final: la duración a cero deja el
        // widget exactamente igual de correcto, sólo que sin recorrido.
        duration:
            sinAnimaciones ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, progreso, _) => CustomPaint(
          painter: _AnilloIdentidadPainter(
            forma: id.forma,
            progreso: progreso,
            color: color ?? t.primary,
            colorPista: colorPista ?? t.inactivo,
          ),
        ),
      ),
    );
  }
}

/// Trazo de cada forma. El grosor sale de la fracción, y los topes evitan los
/// dos extremos absurdos: un hilo de 0.3px que no se ve en el aro pequeño, y
/// un trazo de 15px que se come el aro grande.
class _TrazoAnillo {
  /// Grosor como fracción del diámetro. Los valores están calibrados sobre el
  /// aro de la pantalla de mascota (~322px), que es donde se decidieron.
  final double fraccion;
  final double grosorMin;
  final double grosorMax;

  final StrokeCap remate;
  final double alfaPista;

  const _TrazoAnillo({
    required this.fraccion,
    required this.grosorMin,
    required this.grosorMax,
    required this.remate,
    required this.alfaPista,
  });

  double grosorPara(double diametro) =>
      (fraccion * diametro).clamp(grosorMin, grosorMax);
}

const _trazoGlass = _TrazoAnillo(
  fraccion: 0.0217, // 7px a 322
  grosorMin: 3,
  grosorMax: 8,
  remate: StrokeCap.round,
  alfaPista: 0.55,
);

const _trazoChamfer = _TrazoAnillo(
  fraccion: 0.0155, // 5px a 322
  grosorMin: 2.5,
  grosorMax: 6,
  remate: StrokeCap.butt,
  alfaPista: 0.45,
);

/// Un hilo es un hilo a cualquier tamaño: el recorrido entre el mínimo y el
/// máximo es medio píxel a propósito.
const _trazoHairline = _TrazoAnillo(
  fraccion: 0.0047,
  grosorMin: 1.0,
  grosorMax: 1.5,
  remate: StrokeCap.butt,
  alfaPista: 0.30,
);

const _trazoPill = _TrazoAnillo(
  fraccion: 0.0373, // 12px a 322
  grosorMin: 5,
  grosorMax: 13,
  remate: StrokeCap.round,
  alfaPista: 0.75,
);

class _AnilloIdentidadPainter extends CustomPainter {
  final FormaIdentidad forma;
  final double progreso;
  final Color color;
  final Color colorPista;

  _AnilloIdentidadPainter({
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
    final diametro = size.shortestSide;
    final grosor = trazo.grosorPara(diametro);
    final centro = size.center(Offset.zero);
    final radio = (diametro - grosor) / 2;
    final caja = Rect.fromCircle(center: centro, radius: radio);
    final barrido = 2 * math.pi * progreso.clamp(0.0, 1.0);

    switch (forma) {
      case FormaIdentidad.glass:
        _pista(canvas, centro, radio, grosor, trazo.alfaPista);
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
            ..strokeWidth = grosor * 1.5
            ..strokeCap = trazo.remate
            ..color = color.withValues(alpha: 0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, grosor * 0.86),
        );
        canvas.drawArc(
            caja, _inicio, barrido, false, _arco(grosor, trazo.remate, color));

      case FormaIdentidad.chamfer:
        // Segmentado tipo HUD. El número de casillas sale del tamaño: 40 en el
        // aro grande, la docena en el pequeño. Con un número fijo, el aro
        // pequeño se convertía en una línea de puntos ilegible.
        final casillas = (diametro / 8).round().clamp(12, 40);
        final paso = 2 * math.pi / casillas;
        // Hueco en ángulo, no en píxeles: así el ritmo no cambia con el tamaño.
        final hueco = paso * 0.34;
        final encendidas = (progreso.clamp(0.0, 1.0) * casillas).floor();
        final apagado = _arco(grosor, trazo.remate,
            colorPista.withValues(alpha: trazo.alfaPista));
        final encendido = _arco(grosor, trazo.remate, color);
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
        _pista(canvas, centro, radio, grosor, trazo.alfaPista);
        if (barrido <= 0) return;
        canvas.drawArc(
            caja, _inicio, barrido, false, _arco(grosor, trazo.remate, color));

      case FormaIdentidad.pill:
        _pista(canvas, centro, radio, grosor, trazo.alfaPista);
        if (barrido <= 0) return;
        canvas.drawArc(
            caja, _inicio, barrido, false, _arco(grosor, trazo.remate, color));
        // Perdigón en la punta: remata el trazo grueso y da un punto donde
        // mirar mientras el aro crece.
        final punta = _inicio + barrido;
        canvas.drawCircle(
          centro + Offset(math.cos(punta), math.sin(punta)) * radio,
          grosor * 0.34,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
    }
  }

  Paint _arco(double grosor, StrokeCap remate, Color c) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor
    ..strokeCap = remate
    ..color = c;

  void _pista(Canvas canvas, Offset centro, double radio, double grosor,
      double alfa) {
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..color = colorPista.withValues(alpha: alfa),
    );
  }

  @override
  bool shouldRepaint(_AnilloIdentidadPainter old) =>
      old.progreso != progreso ||
      old.forma != forma ||
      old.color != color ||
      old.colorPista != colorPista;
}
