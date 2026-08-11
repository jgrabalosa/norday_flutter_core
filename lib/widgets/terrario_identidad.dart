import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// El suelo que pisa la mascota. Sin él la ilustración flota en el vacío y la
/// pantalla se lee como un icono grande; con él hay un sitio donde está.
///
/// Formas de Flutter, nada de assets: cuatro suelos dibujados con `Path` y
/// degradados pesan cero y cambian de color solos con la identidad. Si algún
/// día hace falta más fidelidad se valorará un SVG, pero para distinguir las
/// cuatro identidades esto sobra.
///
/// Es estático a propósito — no anima nada. La mascota ya se mueve encima; un
/// suelo que también respirase convertiría el conjunto en gelatina. Por eso
/// este es el único de los cinco widgets nuevos que no mira `disableAnimations`:
/// no tiene ninguna animación que apagar.
///
/// Una sola versión por identidad: no varía con la fase de la mascota. Cruzar
/// cuatro identidades por tres fases es otra vuelta, si compensa.
class TerrarioIdentidad extends StatelessWidget {
  /// Ancho disponible. El alto sale de aquí, con la proporción de cada forma.
  final double ancho;

  const TerrarioIdentidad({super.key, required this.ancho});

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    return SizedBox(
      width: ancho,
      height: ancho * 0.24,
      child: CustomPaint(
        painter: _TerrarioPainter(forma: id.forma, tokens: t),
      ),
    );
  }
}

class _TerrarioPainter extends CustomPainter {
  final FormaIdentidad forma;
  final TokensContextuales tokens;

  _TerrarioPainter({required this.forma, required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    switch (forma) {
      case FormaIdentidad.glass:
        _plataformaCristal(canvas, size);
      case FormaIdentidad.chamfer:
        _plataformaRejilla(canvas, size);
      case FormaIdentidad.hairline:
        _lineaDeHorizonte(canvas, size);
      case FormaIdentidad.pill:
        _almohadilla(canvas, size);
    }
  }

  /// La sombra de contacto que llevan todas: sin ella la mascota se despega
  /// del suelo por muy bien dibujado que esté.
  void _sombraContacto(Canvas canvas, Size size,
      {required double alfa, required double anchoRelativo}) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * anchoRelativo,
      height: size.height * 0.34,
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = Colors.black.withValues(alpha: alfa)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  /// Profundidad — losa de cristal: degradado vertical, brillo fino arriba.
  void _plataformaCristal(Canvas canvas, Size size) {
    _sombraContacto(canvas, size, alfa: 0.34, anchoRelativo: 0.62);

    final losa = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.5),
      width: size.width * 0.86,
      height: size.height * 0.72,
    );

    canvas.drawOval(
      losa,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.surface.withValues(alpha: 0.85),
            tokens.surface2.withValues(alpha: 0.30),
          ],
        ).createShader(losa),
    );

    // Sólo la mitad de arriba del borde: el brillo de un canto de cristal cae
    // donde le da la luz, y rodearlo entero lo convertiría en un aro.
    canvas.drawArc(
      losa,
      3.34, // ~191°, un pelo pasado de las 9
      2.60, // ~149°, hasta poco antes de las 3
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  /// Neotokyo+ — plataforma con las esquinas cortadas y rejilla en fuga.
  void _plataformaRejilla(Canvas canvas, Size size) {
    _sombraContacto(canvas, size, alfa: 0.45, anchoRelativo: 0.55);

    final corte = size.height * 0.30;
    final arriba = size.height * 0.18;
    final abajo = size.height * 0.92;
    final izqArriba = size.width * 0.22;
    final derArriba = size.width * 0.78;
    final izqAbajo = size.width * 0.06;
    final derAbajo = size.width * 0.94;

    // Trapecio en fuga con los cuatro vértices cortados: el mismo chaflán que
    // la identidad usa en tarjetas y chips, aquí en horizontal.
    final plataforma = Path()
      ..moveTo(izqArriba + corte, arriba)
      ..lineTo(derArriba - corte, arriba)
      ..lineTo(derArriba, arriba + corte)
      ..lineTo(derAbajo, abajo - corte)
      ..lineTo(derAbajo - corte, abajo)
      ..lineTo(izqAbajo + corte, abajo)
      ..lineTo(izqAbajo, abajo - corte)
      ..lineTo(izqArriba, arriba + corte)
      ..close();

    canvas.drawPath(
      plataforma,
      Paint()..color = tokens.surface2.withValues(alpha: 0.72),
    );

    // La rejilla se recorta contra la plataforma, así no hay que calcular
    // dónde muere cada línea.
    canvas.save();
    canvas.clipPath(plataforma);
    final linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = tokens.primary.withValues(alpha: 0.28);

    // Horizontales cada vez más juntas hacia el fondo: la fuga es eso.
    for (final f in const [0.30, 0.55, 0.76, 0.93]) {
      final y = arriba + (abajo - arriba) * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
    // Verticales abriéndose desde el punto de fuga, que queda por encima.
    final fuga = Offset(size.width / 2, arriba - size.height * 1.6);
    for (final f in const [0.10, 0.30, 0.50, 0.70, 0.90]) {
      canvas.drawLine(fuga, Offset(size.width * f, abajo), linea);
    }
    canvas.restore();

    canvas.drawPath(
      plataforma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = tokens.primary.withValues(alpha: 0.85),
    );
  }

  /// Alba — ni plataforma ni caja: una línea de horizonte que se desvanece por
  /// los extremos. Coherente con el resto de la identidad, que tampoco encaja
  /// el contenido en tarjetas.
  void _lineaDeHorizonte(Canvas canvas, Size size) {
    _sombraContacto(canvas, size, alfa: 0.10, anchoRelativo: 0.42);

    final y = size.height * 0.52;
    final recorrido = Rect.fromLTWH(0, y - 1, size.width, 2);
    canvas.drawLine(
      Offset(size.width * 0.04, y),
      Offset(size.width * 0.96, y),
      Paint()
        ..strokeWidth = 1
        ..shader = LinearGradient(
          colors: [
            tokens.textMuted.withValues(alpha: 0),
            tokens.textMuted.withValues(alpha: 0.42),
            tokens.textMuted.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(recorrido),
    );

    // Tres briznas cortas, asimétricas: lo justo para que la línea sea un
    // suelo y no un subrayado.
    final brizna = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = tokens.primary.withValues(alpha: 0.55);
    for (final (x, alto, curva) in const [
      (0.30, 0.30, -0.05),
      (0.36, 0.46, 0.04),
      (0.68, 0.36, 0.06),
    ]) {
      final base = Offset(size.width * x, y);
      final punta = Offset(size.width * (x + curva), y - size.height * alto);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
              base.dx, (base.dy + punta.dy) / 2, punta.dx, punta.dy),
        brizna,
      );
    }
  }

  /// Dulce — un cojín, no un suelo. Radio total y un par de corazones sueltos.
  void _almohadilla(Canvas canvas, Size size) {
    _sombraContacto(canvas, size, alfa: 0.14, anchoRelativo: 0.60);

    final cojin = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.54),
        width: size.width * 0.80,
        height: size.height * 0.62,
      ),
      Radius.circular(size.height * 0.31), // píldora completa
    );

    canvas.drawRRect(
      cojin,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.surface2,
            tokens.surface2.withValues(alpha: 0.55),
          ],
        ).createShader(cojin.outerRect),
    );
    canvas.drawRRect(
      cojin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = tokens.primary.withValues(alpha: 0.45),
    );

    final corazon = Paint()..color = tokens.primary.withValues(alpha: 0.55);
    _corazon(canvas, Offset(size.width * 0.13, size.height * 0.34),
        size.height * 0.22, corazon);
    _corazon(canvas, Offset(size.width * 0.88, size.height * 0.48),
        size.height * 0.16, corazon);
  }

  /// Un corazón de [lado] centrado en [centro]. Dos lóbulos y una punta: con
  /// curvas cúbicas sale más limpio que con arcos.
  void _corazon(Canvas canvas, Offset centro, double lado, Paint pincel) {
    final r = lado / 2;
    final path = Path()
      ..moveTo(centro.dx, centro.dy + r * 0.75)
      ..cubicTo(centro.dx - r * 1.7, centro.dy - r * 0.35, centro.dx - r * 0.55,
          centro.dy - r * 1.5, centro.dx, centro.dy - r * 0.45)
      ..cubicTo(centro.dx + r * 0.55, centro.dy - r * 1.5, centro.dx + r * 1.7,
          centro.dy - r * 0.35, centro.dx, centro.dy + r * 0.75)
      ..close();
    canvas.drawPath(path, pincel);
  }

  @override
  bool shouldRepaint(_TerrarioPainter old) =>
      old.forma != forma || old.tokens != tokens;
}
