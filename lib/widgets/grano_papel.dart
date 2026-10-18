import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'lapiz.dart';

/// Un grano de papel muy suave encima de toda la pantalla, para que el texto,
/// los iconos y el lápiz parezcan sobre el mismo papel. No recibe toques ni se
/// oye. Solo en Dulce: en las demás identidades no ocupa nada.
class GranoPapel extends StatelessWidget {
  const GranoPapel({super.key});

  @override
  Widget build(BuildContext context) {
    if (identidad(context).forma != FormaIdentidad.pill) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.expand(child: CustomPaint(painter: _GranoPainter())),
      ),
    );
  }
}

/// La semilla fija del grano: el mismo papel en cada pantalla y en cada
/// fotograma.
const int _semilla = 0x4D6F;

class _GranoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width.roundToDouble();
    final alto = size.height.roundToDouble();
    pintarConCache(canvas, (
      'grano',
      ancho,
      alto,
    ), (c) => _grabar(c, Size(ancho, alto)));
  }

  /// Tres motas por celda de 10 × 10 px, y de vez en cuando una fibra corta.
  void _grabar(Canvas canvas, Size size) {
    final azar = Random(_semilla);
    const color = Color(0xFF786046);
    for (var y = 0.0; y < size.height; y += 10) {
      for (var x = 0.0; x < size.width; x += 10) {
        for (var k = 0; k < 3; k++) {
          final px = x + azar.nextDouble() * 10;
          final py = y + azar.nextDouble() * 10;
          final alfa = azar.nextDouble() * 0.05;
          if (azar.nextInt(40) == 0) {
            // Una fibra de 2 a 3 px, casi horizontal.
            final largo = 2 + azar.nextDouble();
            final caida = azar.nextDouble() * 0.6 - 0.3;
            canvas.drawLine(
              Offset(px, py),
              Offset(px + largo, py + caida),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = color.withValues(alpha: alfa),
            );
          } else {
            canvas.drawRect(
              Rect.fromLTWH(px, py, 1, 1),
              Paint()..color = color.withValues(alpha: alfa),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GranoPainter viejo) => false;
}
