import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'lapiz.dart';

/// Una estrella de la valoración: llena o vacía.
///
/// En Profundidad y Neotokyo+ es el icono de Lucide de siempre. En Dulce, una
/// estrella a lápiz: la llena va sombreada en `points` y la vacía es solo el
/// aro a lápiz en `aroVacio`. Lleno y vacío se distinguen por la forma además
/// de por el color.
///
/// No pone etiqueta: la da el botón que la contiene.
class EstrellaValoracion extends StatelessWidget {
  final bool marcada;

  /// Lado de la estrella. Lo que usa `ValoracionSheet`.
  final double tamano;

  const EstrellaValoracion({
    super.key,
    required this.marcada,
    this.tamano = 36,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    // El contorno de lo vacío: 3:1 en las tres identidades. Al 45 % de
    // `textMuted` se quedaba en 2.96 (Profundidad) y 2.20 (Dulce).
    final colorLlena = t.pointsText;
    final colorVacia = t.aroVacio;

    if (identidad(context).forma != FormaIdentidad.pill) {
      return Icon(
        LucideIcons.star,
        size: tamano,
        color: marcada ? colorLlena : colorVacia,
      );
    }
    return ExcludeSemantics(
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: CustomPaint(
          painter: _PintorEstrella(
            marcada: marcada,
            tamano: tamano,
            colorLlena: colorLlena,
            colorVacia: colorVacia,
          ),
        ),
      ),
    );
  }
}

class _PintorEstrella extends CustomPainter {
  final bool marcada;
  final double tamano;
  final Color colorLlena;
  final Color colorVacia;

  _PintorEstrella({
    required this.marcada,
    required this.tamano,
    required this.colorLlena,
    required this.colorVacia,
  });

  @override
  void paint(Canvas canvas, Size size) {
    pintarConCache(
      canvas,
      ('estrella', marcada, tamano, colorLlena, colorVacia),
      size,
      _dibujar,
      desborde: 2,
    );
  }

  void _dibujar(Canvas canvas) {
    // Misma regla de grosor que `IndicadorNivel`: proporcional, con suelo.
    final grosor = math.max(1.0, tamano * 0.08);
    // Metida medio trazo para que el contorno quepa entero en la caja.
    final caja = Rect.fromLTWH(0, 0, tamano, tamano).deflate(grosor / 2);
    final figura = _estrella(caja);
    final semilla = tamano.round();

    if (marcada) {
      final r = caja.shortestSide / 2;
      // El brillo de papel sin pintar, arriba a la izquierda, como en las
      // burbujas del ritmo.
      final brillo = caja.center.translate(-r * 0.34, -r * 0.34);
      pintarSombreado(
        canvas,
        figura,
        color: colorLlena,
        intensidad: (p) =>
            (((p - brillo).distance - r * 0.3) / r * 1.6).clamp(0.0, 1.0),
        separacion: math.max(1.2, tamano * 0.08),
        grosor: math.max(0.6, tamano * 0.045),
        alfa: 0.95,
        cruzado: true,
        semilla: semilla,
      );
    }
    pintarTrazoLapiz(
      canvas,
      figura,
      color: marcada ? colorLlena : colorVacia,
      grosor: grosor,
      semilla: semilla + 5,
    );
  }

  /// Estrella de cinco puntas, la primera hacia arriba. El radio interior es
  /// el 45 % del exterior, que es lo que la hace leerse como estrella y no
  /// como flor.
  Path _estrella(Rect caja) {
    final c = caja.center;
    final rExterior = caja.shortestSide / 2;
    final rInterior = rExterior * 0.45;
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final r = k.isEven ? rExterior : rInterior;
      final angulo = -math.pi / 2 + k * math.pi / 5;
      final punto = Offset(
        c.dx + r * math.cos(angulo),
        c.dy + r * math.sin(angulo),
      );
      if (k == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_PintorEstrella anterior) =>
      anterior.marcada != marcada ||
      anterior.tamano != tamano ||
      anterior.colorLlena != colorLlena ||
      anterior.colorVacia != colorVacia;
}
