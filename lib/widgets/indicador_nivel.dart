import 'package:flutter/material.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Cómo se pinta un nivel de cinco en cada identidad.
enum DibujoNivel {
  /// Profundidad: cinco estrellas de cuatro puntas.
  estrellas,

  /// Las identidades que aún no tienen dibujo propio: cinco escalones que
  /// crecen, como la cobertura de un móvil.
  escalones,
}

/// Motor: pinta un nivel de 1 a 5 con el dibujo de la identidad equipada.
///
/// No sabe qué mide: recibe un número y lo pinta. Quien lo usa decide qué es
/// ese nivel y, si quiere, una etiqueta más rica para el lector de pantalla.
/// Las figuras llenas van en `points` y las vacías en `inactivo`, los dos
/// tokens de cada identidad, así que el color cambia solo con el tema.
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
    FormaIdentidad.chamfer => DibujoNivel.escalones,
    FormaIdentidad.pill => DibujoNivel.escalones,
  };

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
            colorLlena: t.points,
            colorVacia: t.inactivo,
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

  @override
  void paint(Canvas canvas, Size size) {
    final hueco = IndicadorNivel.separacion(tamano);
    for (var i = 0; i < IndicadorNivel.total; i++) {
      final origen = Offset(i * (tamano + hueco), 0);
      final pincel = Paint()
        ..isAntiAlias = true
        ..color = (i < llenas ? colorLlena : colorVacia);
      final figura = switch (dibujo) {
        DibujoNivel.estrellas => _estrella(origen),
        DibujoNivel.escalones => _escalon(origen, i),
      };
      canvas.drawPath(figura, pincel);
    }
  }

  /// La estrella de cuatro puntas de la maqueta, dibujada en una caja de 10 y
  /// escalada al lado.
  Path _estrella(Offset origen) {
    const puntos = [
      Offset(5, 0),
      Offset(6.2, 3.8),
      Offset(10, 5),
      Offset(6.2, 6.2),
      Offset(5, 10),
      Offset(3.8, 6.2),
      Offset(0, 5),
      Offset(3.8, 3.8),
    ];
    final escala = tamano / 10;
    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final p = origen + puntos[i] * escala;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  /// El escalón [i]: un quinto de alto más por cada uno, apoyados abajo.
  Path _escalon(Offset origen, int i) {
    final alto = tamano * (i + 1) / IndicadorNivel.total;
    final ancho = tamano * 0.6;
    final caja = Rect.fromLTWH(
      origen.dx + (tamano - ancho) / 2,
      origen.dy + tamano - alto,
      ancho,
      alto,
    );
    return Path()
      ..addRRect(RRect.fromRectAndRadius(caja, Radius.circular(tamano * 0.12)));
  }

  @override
  bool shouldRepaint(_PintorNivel anterior) =>
      anterior.dibujo != dibujo ||
      anterior.llenas != llenas ||
      anterior.tamano != tamano ||
      anterior.colorLlena != colorLlena ||
      anterior.colorVacia != colorVacia;
}
