import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'lapiz.dart';

/// El suelo que pisa la mascota. Sin él la ilustración flota en el vacío y la
/// pantalla se lee como un icono grande; con él hay un sitio donde está.
///
/// Formas de Flutter, nada de assets: cuatro suelos dibujados con `Path` y
/// degradados pesan cero y cambian de color solos con la identidad. Si algún
/// día hace falta más fidelidad se valorará un SVG, pero para distinguir las
/// cuatro identidades esto sobra.
///
/// El suelo es estático a propósito — no anima nada. La mascota ya se mueve
/// encima; un suelo que también respirase convertiría el conjunto en gelatina.
///
/// Con [nieve] (las fiestas, Nori vestida N-11) lleva nieve quieta sobre el
/// suelo, con el estilo de cada forma (en Dulce, a lápiz), y copos que caen
/// por encima de la escena. Los copos son un solo pintor con un solo
/// controlador, y se paran con «reducir animaciones». Sin [nieve], el
/// terrario es exactamente el de siempre: ni la capa ni el controlador están
/// en el árbol. Quién decide si hay nieve no es este widget: recibe el `bool`.
///
/// Una sola versión por identidad: no varía con la fase de la mascota. Cruzar
/// cuatro identidades por tres fases es otra vuelta, si compensa.
class TerrarioIdentidad extends StatelessWidget {
  /// Ancho disponible. El alto sale de aquí, con la proporción de cada forma.
  final double ancho;

  /// Si lleva nieve: quieta sobre el suelo y copos cayendo.
  final bool nieve;

  const TerrarioIdentidad({super.key, required this.ancho, this.nieve = false});

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final alto = ancho * 0.24;

    final suelo = SizedBox(
      width: ancho,
      height: alto,
      child: CustomPaint(
        painter: _TerrarioPainter(forma: id.forma, tokens: t),
      ),
    );
    if (!nieve) return suelo;

    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          suelo,
          Positioned.fill(
            child: CustomPaint(
              key: const ValueKey('terrario_nieve_quieta'),
              painter: _NieveQuietaPainter(forma: id.forma, tokens: t),
            ),
          ),
          // Los copos caen por encima de la escena: una caja tan ancha como
          // el suelo y bastante más alta, que no recorta ni recibe toques.
          Positioned(
            left: 0,
            right: 0,
            bottom: alto * 0.4,
            height: ancho * 1.25,
            child: IgnorePointer(
              child: CoposCayendo(forma: id.forma, tokens: t),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los copos que caen sobre el terrario nevado. Un solo controlador y un solo
/// pintor para todos (cuestan poco en móviles modestos). Con «reducir
/// animaciones» se quedan quietos y no hay controlador.
@visibleForTesting
class CoposCayendo extends StatefulWidget {
  final FormaIdentidad forma;
  final TokensContextuales tokens;

  const CoposCayendo({super.key, required this.forma, required this.tokens});

  @override
  State<CoposCayendo> createState() => _CoposCayendoState();
}

class _CoposCayendoState extends State<CoposCayendo>
    with SingleTickerProviderStateMixin {
  AnimationController? _caida;

  /// Para los tests: si hay un controlador moviendo los copos.
  @visibleForTesting
  bool get enMovimiento => _caida?.isAnimating ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quietos = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (quietos) {
      _caida?.dispose();
      _caida = null;
    } else {
      _caida ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 9),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _caida?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CoposPainter(
        forma: widget.forma,
        tokens: widget.tokens,
        caida: _caida,
      ),
    );
  }
}

/// Un copo: dónde empieza (de 0 a 1 en ancho y en alto), cuánto mide (0 a 1)
/// y lo que se balancea. Fijos: la misma semilla da la misma nevada.
class _Copo {
  final double x;
  final double y;
  final double tamano;
  final double vaiven;
  final double velocidad;

  const _Copo(this.x, this.y, this.tamano, this.vaiven, this.velocidad);
}

final List<_Copo> _copos = () {
  final azar = Random(1201);
  return List.generate(
    22,
    (_) => _Copo(
      azar.nextDouble(),
      azar.nextDouble(),
      azar.nextDouble(),
      azar.nextDouble() * 2 * pi,
      0.7 + azar.nextDouble() * 0.6,
    ),
  );
}();

class _CoposPainter extends CustomPainter {
  final FormaIdentidad forma;
  final TokensContextuales tokens;
  final Animation<double>? caida;

  _CoposPainter({required this.forma, required this.tokens, this.caida})
    : super(repaint: caida);

  @override
  void paint(Canvas canvas, Size size) {
    // Quietos: un momento fijo de la caída, no todos arriba.
    final t = caida?.value ?? 0.35;
    for (final copo in _copos) {
      final avance = (copo.y + t * copo.velocidad) % 1.0;
      final y = avance * size.height;
      final x =
          copo.x * size.width +
          sin(t * 2 * pi * copo.velocidad + copo.vaiven) * size.width * 0.02;
      // Se desvanecen al llegar al suelo y al nacer: sin cortes bruscos.
      final borde = min(avance, 1 - avance);
      final alfa = (borde * 8).clamp(0.0, 1.0);
      final centro = Offset(x, y);
      switch (forma) {
        case FormaIdentidad.glass:
          canvas.drawCircle(
            centro,
            1.2 + copo.tamano * 1.8,
            Paint()..color = Colors.white.withValues(alpha: 0.75 * alfa),
          );
        case FormaIdentidad.chamfer:
          // Neotokyo+: copos de píxel, cuadrados, con el brillo del filo.
          final lado = 1.6 + copo.tamano * 2.0;
          canvas.drawRect(
            Rect.fromCenter(center: centro, width: lado, height: lado),
            Paint()
              ..color = Color.lerp(
                Colors.white,
                tokens.primary,
                0.25,
              )!.withValues(alpha: 0.8 * alfa),
          );
        case FormaIdentidad.pill:
          // Dulce: estrellitas a lápiz, del color de la tinta (el papel es
          // claro: un copo blanco no se vería).
          final r = 1.6 + copo.tamano * 2.2;
          final pincel = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..strokeCap = StrokeCap.round
            ..color = tokens.primary.withValues(alpha: 0.55 * alfa);
          for (var i = 0; i < 3; i++) {
            final a = i * pi / 3 + copo.vaiven;
            final d = Offset(cos(a) * r, sin(a) * r);
            canvas.drawLine(centro - d, centro + d, pincel);
          }
      }
    }
  }

  @override
  bool shouldRepaint(_CoposPainter old) =>
      old.forma != forma || old.tokens != tokens || old.caida != caida;
}

/// La nieve quieta sobre el suelo: un manto en la parte de arriba de cada
/// forma, que deja ver el suelo por debajo.
class _NieveQuietaPainter extends CustomPainter {
  final FormaIdentidad forma;
  final TokensContextuales tokens;

  _NieveQuietaPainter({required this.forma, required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    switch (forma) {
      case FormaIdentidad.glass:
        _mantoCristal(canvas, size);
      case FormaIdentidad.chamfer:
        _mantoRejilla(canvas, size);
      case FormaIdentidad.pill:
        _mantoLapiz(canvas, size);
    }
  }

  /// El borde de abajo del manto, ondulado: montoncitos de nieve.
  Path _manto(
    Size size, {
    required double izquierda,
    required double derecha,
    required double arriba,
    required double grosor,
    int montones = 7,
  }) {
    final ancho = derecha - izquierda;
    final path = Path()..moveTo(izquierda, arriba + grosor * 0.4);
    path.quadraticBezierTo(
      izquierda + ancho * 0.08,
      arriba - grosor * 0.25,
      izquierda + ancho * 0.18,
      arriba,
    );
    path.lineTo(derecha - ancho * 0.18, arriba);
    path.quadraticBezierTo(
      derecha - ancho * 0.08,
      arriba - grosor * 0.25,
      derecha,
      arriba + grosor * 0.4,
    );
    final paso = ancho / montones;
    for (var i = montones; i > 0; i--) {
      final x0 = izquierda + paso * i;
      final x1 = izquierda + paso * (i - 1);
      final caida = grosor * (i.isEven ? 1.0 : 0.7);
      path.quadraticBezierTo(
        (x0 + x1) / 2,
        arriba + caida * 1.2,
        x1,
        arriba + grosor * 0.5,
      );
    }
    path.close();
    return path;
  }

  void _mantoCristal(Canvas canvas, Size size) {
    final manto = _manto(
      size,
      izquierda: size.width * 0.12,
      derecha: size.width * 0.88,
      arriba: size.height * 0.18,
      grosor: size.height * 0.22,
    );
    canvas.drawPath(
      manto,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.55),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _mantoRejilla(Canvas canvas, Size size) {
    final manto = _manto(
      size,
      izquierda: size.width * 0.20,
      derecha: size.width * 0.80,
      arriba: size.height * 0.16,
      grosor: size.height * 0.18,
      montones: 6,
    );
    canvas.drawPath(
      manto,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    // El filo de la identidad también en la nieve.
    canvas.drawPath(
      manto,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tokens.primary.withValues(alpha: 0.6),
    );
  }

  void _mantoLapiz(Canvas canvas, Size size) {
    final manto = _manto(
      size,
      izquierda: size.width * 0.12,
      derecha: size.width * 0.88,
      arriba: size.height * 0.24,
      grosor: size.height * 0.2,
    );
    final semilla = semillaDe(size);
    canvas.drawPath(
      manto,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    pintarSombreado(
      canvas,
      manto,
      color: tokens.primary,
      alfa: 0.18,
      separacion: 3.2,
      semilla: semilla,
    );
    pintarTrazoLapiz(
      canvas,
      caminoTembloroso(manto, semilla: semilla),
      color: tokens.primary,
      grosor: 1.1,
      semilla: semilla + 3,
    );
  }

  @override
  bool shouldRepaint(_NieveQuietaPainter old) =>
      old.forma != forma || old.tokens != tokens;
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
      case FormaIdentidad.pill:
        _almohadilla(canvas, size);
    }
  }

  /// La sombra de contacto que llevan todas: sin ella la mascota se despega
  /// del suelo por muy bien dibujado que esté.
  void _sombraContacto(
    Canvas canvas,
    Size size, {
    required double alfa,
    required double anchoRelativo,
  }) {
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
          colors: [tokens.surface2, tokens.surface2.withValues(alpha: 0.55)],
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
    _corazon(
      canvas,
      Offset(size.width * 0.13, size.height * 0.34),
      size.height * 0.22,
      corazon,
    );
    _corazon(
      canvas,
      Offset(size.width * 0.88, size.height * 0.48),
      size.height * 0.16,
      corazon,
    );
  }

  /// Un corazón de [lado] centrado en [centro]. Dos lóbulos y una punta: con
  /// curvas cúbicas sale más limpio que con arcos.
  void _corazon(Canvas canvas, Offset centro, double lado, Paint pincel) {
    final r = lado / 2;
    final path = Path()
      ..moveTo(centro.dx, centro.dy + r * 0.75)
      ..cubicTo(
        centro.dx - r * 1.7,
        centro.dy - r * 0.35,
        centro.dx - r * 0.55,
        centro.dy - r * 1.5,
        centro.dx,
        centro.dy - r * 0.45,
      )
      ..cubicTo(
        centro.dx + r * 0.55,
        centro.dy - r * 1.5,
        centro.dx + r * 1.7,
        centro.dy - r * 0.35,
        centro.dx,
        centro.dy + r * 0.75,
      )
      ..close();
    canvas.drawPath(path, pincel);
  }

  @override
  bool shouldRepaint(_TerrarioPainter old) =>
      old.forma != forma || old.tokens != tokens;
}
