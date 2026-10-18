import 'dart:math';

import 'package:flutter/material.dart';

/// El trazo a lápiz de color: el lenguaje de Dulce, que parece dibujada en un
/// bloc de papel.
///
/// Un trazo de lápiz no es una línea perfecta: tiembla un poco y se repasa.
/// Aquí se hace con geometría. El contorno se recorre, cada punto se desplaza en
/// perpendicular con una onda suave, y encima se pinta un segundo trazo más fino
/// y más tenue.
///
/// El temblor es DETERMINISTA: sale de una semilla y de la distancia recorrida,
/// nunca de un `Random()` sin semilla ni de la hora. El mismo dibujo sale igual
/// en cada fotograma y no baila. Cada pieza tiene su temblor propio, que sólo
/// cambia cuando cambia su tamaño ([semillaDe]).

/// El contorno [original] con el temblor de un lápiz. Cada [paso] píxeles se
/// toma un punto y se desplaza en perpendicular a la tangente, con una onda de
/// dos senos que nunca se aparta más de [amplitud].
Path caminoTembloroso(
  Path original, {
  required int semilla,
  double amplitud = 0.7,
  double paso = 4,
}) {
  final azar = Random(semilla);
  final f1 = 0.05 + azar.nextDouble() * 0.05;
  final f2 = 0.11 + azar.nextDouble() * 0.08;
  final fase1 = azar.nextDouble() * 2 * pi;
  final fase2 = azar.nextDouble() * 2 * pi;

  final camino = Path();
  var recorrido = 0.0;
  var primero = true;
  for (final metrica in original.computeMetrics()) {
    if (metrica.length == 0) continue;
    for (var d = 0.0; ; d += paso) {
      final distancia = min(d, metrica.length);
      final tangente = metrica.getTangentForOffset(distancia)!;
      final s = recorrido + distancia;
      final normal = Offset(-tangente.vector.dy, tangente.vector.dx);
      final onda =
          amplitud * (0.6 * sin(s * f1 + fase1) + 0.4 * sin(s * f2 + fase2));
      final punto = tangente.position + normal * onda;
      if (primero) {
        camino.moveTo(punto.dx, punto.dy);
        primero = false;
      } else {
        camino.lineTo(punto.dx, punto.dy);
      }
      if (distancia >= metrica.length) break;
    }
    recorrido += metrica.length;
  }
  return camino;
}

/// Un trazo a lápiz de [grosor] y [color] sobre [camino]. Dos pasadas: la
/// firme, casi opaca, y encima el repaso, más fino, más tenue y con otro
/// temblor.
void pintarTrazoLapiz(
  Canvas canvas,
  Path camino, {
  required Color color,
  required double grosor,
  required int semilla,
}) {
  final firme = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: 0.95);
  canvas.drawPath(
    caminoTembloroso(camino, semilla: semilla, amplitud: 0.6),
    firme,
  );

  final repaso = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grosor * 0.55
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: 0.45);
  canvas.drawPath(
    caminoTembloroso(camino, semilla: semilla + 1, amplitud: 1.2),
    repaso,
  );
}

/// Rellena [zona] con rayas paralelas en [angulo], cada [separacion] píxeles.
/// Cada raya varía su grosor y su alfa un 25 % arriba o abajo, según [semilla].
void pintarRayas(
  Canvas canvas,
  Path zona, {
  required Color color,
  double separacion = 3,
  double angulo = pi / 4,
  double grosor = 0.8,
  double alfa = 0.6,
  required int semilla,
}) {
  final azar = Random(semilla);
  final caja = zona.getBounds();
  final centro = caja.center;
  // Media diagonal: con esto las rayas cubren la caja a cualquier ángulo.
  final radio = sqrt(caja.width * caja.width + caja.height * caja.height) / 2;
  final dir = Offset(cos(angulo), sin(angulo));
  final normal = Offset(-dir.dy, dir.dx);

  canvas.save();
  canvas.clipPath(zona);
  for (var s = -radio; s <= radio; s += separacion) {
    final base = centro + normal * s;
    final variaG = 1 + (azar.nextDouble() * 0.5 - 0.25);
    final variaA = 1 + (azar.nextDouble() * 0.5 - 0.25);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor * variaG
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: (alfa * variaA).clamp(0.0, 1.0));
    canvas.drawLine(base - dir * radio, base + dir * radio, pincel);
  }
  canvas.restore();
}

/// La semilla de una pieza, a partir de su tamaño. Estable mientras la pieza no
/// cambie de tamaño; cada pieza distinta tiene su temblor.
int semillaDe(Size size) =>
    Object.hash(size.width.round(), size.height.round());

/// El borde de Dulce: el mismo rectángulo redondeado de siempre, pero con el
/// filo dibujado a lápiz. La forma (recortes, `InkWell`, relleno) no tiene
/// temblor: sólo el trazo.
class BordeLapiz extends OutlinedBorder {
  final double radio;

  const BordeLapiz({required this.radio, super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      BordeLapiz(radio: radio, side: side ?? this.side);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BordeLapiz(radio: radio * t, side: side.scale(t));

  Path _camino(Rect rect) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radio)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _camino(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    pintarTrazoLapiz(
      canvas,
      _camino(rect.deflate(side.width / 2)),
      color: side.color,
      grosor: side.width,
      semilla: semillaDe(rect.size),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BordeLapiz && other.radio == radio && other.side == side;

  @override
  int get hashCode => Object.hash(radio, side);
}
