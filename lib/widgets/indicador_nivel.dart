import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Cómo se pinta un nivel de cinco en cada identidad: el objeto de progreso
/// de su mundo.
enum DibujoNivel {
  /// Profundidad: cinco astroides, la misma silueta de las estrellas del
  /// cielo y de la constelación.
  estrellas,

  /// Neotokyo+: cinco ventanas de su ciudad, verticales y con las esquinas
  /// cortadas como el resto de la identidad.
  ventanas,

  /// Dulce: cinco burbujas que crecen, con el punto de brillo de las del
  /// fondo.
  burbujas,
}

/// Motor: pinta un nivel de 1 a 5 con el dibujo de la identidad equipada.
///
/// No sabe qué mide: recibe un número y lo pinta. Quien lo usa decide qué es
/// ese nivel y, si quiere, una etiqueta más rica para el lector de pantalla.
///
/// Las figuras llenas van rellenas en `points`; las vacías, en CONTORNO de
/// `aroVacio`. No en un relleno apagado: eso dejaba el estado en manos del
/// color solo y por debajo de 3:1 (WCAG 1.4.11). Lo lleno y lo vacío se
/// distinguen por la forma —relleno frente a contorno— además de por el color.
class IndicadorNivel extends StatelessWidget {
  /// El nivel, de 1 a 5. Fuera de rango se recorta: 0 o menos, ninguna llena;
  /// más de 5, las cinco.
  final int nivel;

  /// Lado de cada figura. La maqueta usa 20 en una tarjeta y 11 en una fila.
  final double tamano;

  /// Lo que lee el lector de pantalla. Sin ella, «Nivel N de 5».
  final String? etiquetaSemantica;

  const IndicadorNivel({
    super.key,
    required this.nivel,
    required this.tamano,
    this.etiquetaSemantica,
  });

  static const int total = 5;

  /// Cuántas figuras van llenas.
  static int llenas(int nivel) => nivel.clamp(0, total);

  /// Qué dibujo toca a cada forma. `switch` exhaustivo a propósito: una forma
  /// nueva rompe la compilación aquí, que es donde hay que decidir su dibujo.
  static DibujoNivel dibujoDe(FormaIdentidad forma) => switch (forma) {
    FormaIdentidad.glass => DibujoNivel.estrellas,
    FormaIdentidad.chamfer => DibujoNivel.ventanas,
    FormaIdentidad.pill => DibujoNivel.burbujas,
  };

  /// El color de una figura llena.
  static Color colorLlena(TokensContextuales t) => t.points;

  /// El color del contorno de una figura vacía. `aroVacio` es el token que ya
  /// se mide a 3:1 sobre los tres fondos de cada identidad.
  static Color colorVacia(TokensContextuales t) => t.aroVacio;

  /// Hueco entre figuras: un quinto del lado (4 con 20, 2,2 con 11).
  static double separacion(double tamano) => tamano / 5;

  /// Lo que ocupa: cinco figuras y cuatro huecos de ancho, una de alto.
  static Size medida(double tamano) =>
      Size(tamano * total + separacion(tamano) * (total - 1), tamano);

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final etiqueta =
        etiquetaSemantica ??
        NordayCoreLocalizations.of(context)!.indicadorNivel(llenas(nivel));
    return Semantics(
      container: true,
      image: true,
      label: etiqueta,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: medida(tamano),
          painter: _PintorNivel(
            dibujo: dibujoDe(identidad(context).forma),
            llenas: llenas(nivel),
            tamano: tamano,
            colorLlena: colorLlena(t),
            colorVacia: colorVacia(t),
          ),
        ),
      ),
    );
  }
}

class _PintorNivel extends CustomPainter {
  final DibujoNivel dibujo;
  final int llenas;
  final double tamano;
  final Color colorLlena;
  final Color colorVacia;

  _PintorNivel({
    required this.dibujo,
    required this.llenas,
    required this.tamano,
    required this.colorLlena,
    required this.colorVacia,
  });

  /// Grosor del contorno de una figura vacía. Proporcional al lado, con un
  /// suelo: a 11 px un trazo más fino que 1 se pierde.
  double get _grosor => math.max(1.0, tamano * 0.08);

  @override
  void paint(Canvas canvas, Size size) {
    final hueco = IndicadorNivel.separacion(tamano);
    final grosor = _grosor;
    for (var i = 0; i < IndicadorNivel.total; i++) {
      final caja = Rect.fromLTWH(i * (tamano + hueco), 0, tamano, tamano);
      final llena = i < llenas;
      // La vacía se dibuja metida medio trazo hacia dentro: así el contorno
      // cabe entero en su caja y no se come el hueco con la siguiente.
      final dentro = llena ? caja : caja.deflate(grosor / 2);
      final figura = switch (dibujo) {
        DibujoNivel.estrellas => _astroide(dentro),
        DibujoNivel.ventanas => _ventana(dentro),
        DibujoNivel.burbujas => _burbuja(dentro, i),
      };
      final pincel = Paint()..isAntiAlias = true;
      if (llena) {
        pincel.color = colorLlena;
      } else {
        pincel
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor
          ..strokeJoin = StrokeJoin.round
          ..color = colorVacia;
      }
      canvas.drawPath(figura, pincel);

      // El punto de brillo de las burbujas del fondo, sólo en las llenas: en
      // una vacía no hay volumen que iluminar.
      if (llena && dibujo == DibujoNivel.burbujas) {
        final r = _radioBurbuja(dentro, i);
        final centro = _centroBurbuja(dentro, r);
        canvas.drawCircle(
          centro.translate(-r * 0.34, -r * 0.34),
          r * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }
  }

  /// La astroide del cielo de Profundidad (x = r·cos³t, y = r·sin³t), la
  /// misma silueta que `_destello` en capa_constelacion.dart.
  Path _astroide(Rect caja) {
    const pasos = 48;
    final c = caja.center;
    final r = caja.shortestSide / 2;
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

  /// Una ventana de la ciudad de Neotokyo+: vertical, el 60 % del lado de
  /// ancho y el lado entero de alto, con las cuatro esquinas cortadas. El
  /// corte es una cuarta parte del ancho, para que se lea igual a 20 que a 11.
  Path _ventana(Rect caja) {
    final ancho = caja.width * 0.6;
    final r = Rect.fromCenter(
      center: caja.center,
      width: ancho,
      height: caja.height,
    );
    final c = ancho * 0.25;
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  /// Radio de la burbuja [i]: crecen del 60 % al 100 % de su caja, como
  /// crecían los escalones que sustituyen.
  double _radioBurbuja(Rect caja, int i) =>
      caja.shortestSide / 2 * (0.6 + 0.1 * i);

  /// Apoyadas abajo: las cinco comparten suelo, así el crecimiento se lee.
  Offset _centroBurbuja(Rect caja, double r) =>
      Offset(caja.center.dx, caja.bottom - r);

  Path _burbuja(Rect caja, int i) {
    final r = _radioBurbuja(caja, i);
    return Path()
      ..addOval(Rect.fromCircle(center: _centroBurbuja(caja, r), radius: r));
  }

  @override
  bool shouldRepaint(_PintorNivel anterior) =>
      anterior.dibujo != dibujo ||
      anterior.llenas != llenas ||
      anterior.tamano != tamano ||
      anterior.colorLlena != colorLlena ||
      anterior.colorVacia != colorVacia;
}
