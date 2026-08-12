import 'dart:math' as math;

import 'package:flutter/material.dart';

/// El logotipo de Google —la "G" de cuatro colores— dibujado a vector.
///
/// Sustituye a la `Text('G', color: Colors.red)` que había en el botón de
/// "Continuar con Google", que no era el logo de nadie. Las directrices de
/// marca de Google piden el logo tal cual, sin recolorear ni deformar: por eso
/// los cuatro colores son los oficiales y no salen de la identidad equipada.
///
/// Va pintado y no como SVG porque el ecosistema no depende de `flutter_svg` y
/// una figura de cuatro arcos y una barra no justifica meter una dependencia
/// nueva en todas las apps. Si algún día entra, esto se sustituye por el asset
/// oficial y no cambia nada más.
class LogoGoogle extends StatelessWidget {
  final double lado;

  const LogoGoogle({super.key, this.lado = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lado,
      height: lado,
      child: CustomPaint(painter: _LogoGooglePainter()),
    );
  }
}

class _LogoGooglePainter extends CustomPainter {
  // Los cuatro oficiales.
  static const _azul = Color(0xFF4285F4);
  static const _verde = Color(0xFF34A853);
  static const _amarillo = Color(0xFFFBBC05);
  static const _rojo = Color(0xFFEA4335);

  /// Proporciones del logo original (lienzo de 48): anillo de radio exterior 22
  /// y grosor 8.5, y la barra desde el centro hasta 45, con el mismo grosor.
  static const _radioExterior = 22 / 48;
  static const _grosor = 8.5 / 48;
  static const _finBarra = 45 / 48;

  /// Dónde empieza cada arco y cuánto barre, en grados y en sentido horario
  /// desde las tres en punto. El azul cubre el 0, que es donde arranca la
  /// barra: los dos son la misma pieza.
  static const _arcos = <(Color, double, double)>[
    (_azul, -45, 75),
    (_verde, 30, 105),
    (_amarillo, 135, 90),
    (_rojo, 225, 90),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide;
    final centro = size.center(Offset.zero);
    final grosor = lado * _grosor;
    // El arco se traza por el centro del trazo, no por su borde exterior.
    final radio = lado * _radioExterior - grosor / 2;
    final caja = Rect.fromCircle(center: centro, radius: radio);

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.butt;

    for (final (color, inicio, barrido) in _arcos) {
      canvas.drawArc(
        caja,
        inicio * math.pi / 180,
        barrido * math.pi / 180,
        false,
        pincel..color = color,
      );
    }

    // La barra: del centro hacia la derecha, centrada en la horizontal.
    canvas.drawRect(
      Rect.fromLTRB(
        centro.dx,
        centro.dy - grosor / 2,
        lado * _finBarra,
        centro.dy + grosor / 2,
      ),
      Paint()..color = _azul,
    );
  }

  @override
  bool shouldRepaint(_LogoGooglePainter old) => false;
}
