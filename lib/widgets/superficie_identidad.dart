import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'lapiz.dart';

/// Cómo se resuelve una superficie en cada identidad, en un solo sitio.
///
/// Nació dentro de `login_screen.dart` y salió de ahí en cuanto Perfil,
/// Colección y Logros necesitaron lo mismo: una tarjeta de Material en medio de
/// una pantalla achaflanada canta, y cuatro copias del mismo `switch` acaban
/// divergiendo. Es el equivalente en el motor a `identidad_ui.dart` de la app
/// de hábitos, que hace esto mismo para la tarjeta de hábito y el chip.
///
/// Se despacha por [FormaIdentidad] con un `switch` exhaustivo y los radios
/// salen de [IdentidadPaleta], nunca de un número suelto.

/// Rectángulo con las cuatro esquinas cortadas en recto, el rasgo de
/// Neotokyo+. Es un [OutlinedBorder] y no un painter para que valga igual de
/// forma de un `Container`, de un botón o de un recorte.
class BordeChaflan extends OutlinedBorder {
  final double chaflan;

  const BordeChaflan({required this.chaflan, super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      BordeChaflan(chaflan: chaflan, side: side ?? this.side);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BordeChaflan(chaflan: chaflan * t, side: side.scale(t));

  Path _camino(Rect rect) {
    // Con cajas muy bajas el corte se comería el lado entero.
    final c = chaflan.clamp(0.0, rect.shortestSide / 2);
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _camino(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_camino(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is BordeChaflan && other.chaflan == chaflan && other.side == side;

  @override
  int get hashCode => Object.hash(chaflan, side);
}

/// La figura de una superficie de esta identidad al radio que se le pida.
/// Sale de aquí para que la tarjeta, el botón y el recorte de una tira de
/// color no puedan acabar cortando la esquina de formas distintas.
ShapeBorder formaIdentidad(
  IdentidadPaleta id, {
  required double radio,
  BorderSide lado = BorderSide.none,
}) => switch (id.forma) {
  FormaIdentidad.chamfer => BordeChaflan(chaflan: id.chaflan, side: lado),
  FormaIdentidad.pill => BordeLapiz(radio: radio, side: lado),
  FormaIdentidad.glass => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radio),
    side: lado,
  ),
};

/// Cómo luce el filo de neón de Neotokyo+. En las demás identidades no
/// tiene efecto.
enum FiloNeon {
  /// El de siempre: 0,70.
  fijo,

  /// Respira de 0,70 a 1,0 y vuelta, en un ciclo de
  /// `duracionAnimacionFirma` (2400 ms). Para lo que está pendiente.
  latiendo,

  /// Fijo a 1,0. Para lo ya hecho.
  encendido,
}

/// El reloj del latido. Es el de la pared y no el del montaje: todas las
/// tarjetas laten en la misma fase, y dos montadas en momentos distintos siguen
/// latiendo juntas. Los tests lo cambian para fijar la hora.
@visibleForTesting
int Function() relojFilo = () => DateTime.now().millisecondsSinceEpoch;

/// Los extremos del filo de Neotokyo+ y su grosor.
const double _filoFijo = 0.70;
const double _filoEncendido = 1.0;
const double _filoGrosor = 1.2;

/// Una superficie —tarjeta, panel, fila de lista— en el lenguaje de la
/// identidad equipada.
///
class SuperficieIdentidad extends StatelessWidget {
  final Widget child;

  final VoidCallback? onTap;

  final EdgeInsets margen;

  final EdgeInsets relleno;

  /// El elemento protagonista de la pantalla usa [IdentidadPaleta.radioHero];
  /// el contenido de una lista, [IdentidadPaleta.radioSecundario].
  final bool protagonista;

  /// Filo propio, cuando esta superficie tiene que destacar sobre las de su
  /// alrededor. Sin él manda el de la identidad, y [filoNeon] no se mira.
  final BorderSide? filo;

  /// Cómo late el filo de Neotokyo+: fijo, latiendo o encendido. Sólo tiene
  /// efecto en esa identidad, y no si viene [filo].
  final FiloNeon filoNeon;

  /// Deja ver el fondo de la identidad a través de la superficie.
  ///
  /// La usan las cinco protagonistas a 0.75: login, Tienda, Colección, Logros
  /// y el esqueleto de Logros. Sobre el cielo de Profundidad eso deja la
  /// tarjeta a 1,54 de contraste sobre el fondo —frente a 1,88 opaca— y SUBE
  /// el del texto encima: `text` pasa de 9,17 a 11,18 y `primary` de 4,66 a
  /// 5,68, porque la tarjeta se oscurece hacia el fondo y el texto es claro.
  ///
  /// Sólo tiene efecto en la protagonista de glass. En Dulce la tarjeta ya
  /// está a 1,11 de contraste sobre su fondo —lo que la define es el filo a
  /// lápiz, no el relleno—, así que bajar el alpha allí no aclararía nada
  /// y en cambio dejaría pasar las burbujas a través del formulario. En
  /// Neotokyo+ tampoco aplica: la protagonista va opaca (`surface`) para que
  /// las ventanas de la ciudad no crucen el formulario, y las secundarias no
  /// pintan relleno.
  final double opacidadSuperficie;

  const SuperficieIdentidad({
    super.key,
    required this.child,
    this.onTap,
    this.margen = EdgeInsets.zero,
    this.relleno = const EdgeInsets.all(16),
    this.protagonista = false,
    this.filo,
    this.filoNeon = FiloNeon.fijo,
    this.opacidadSuperficie = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    // Sólo el filo que late necesita estado. Un filo explícito manda sobre el
    // modo, así que en ese caso no entra aquí.
    if (filo == null &&
        id.forma == FormaIdentidad.chamfer &&
        filoNeon == FiloNeon.latiendo) {
      return _FiloLatiente(
        duracion: id.duracionAnimacionFirma,
        color: t.primary,
        construir: (lado) => _superficie(id, t, lado),
      );
    }
    return _superficie(id, t, _ladoDe(id, t));
  }

  /// El filo que pide esta superficie cuando nadie lo pone. Un [filo] explícito
  /// gana siempre; en Neotokyo+ depende de [filoNeon] cuando no late.
  BorderSide _ladoDe(IdentidadPaleta id, TokensContextuales t) =>
      filo ??
      switch (id.forma) {
        // El filo claro es lo que hace que el cristal tenga canto, y
        // ahora sólo lo lleva la protagonista: la secundaria de
        // Profundidad ya no tiene superficie que enmarcar.
        FormaIdentidad.glass =>
          protagonista
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        FormaIdentidad.chamfer => BorderSide(
          // 0.70 y no menos: el filo es lo que dibuja la tarjeta. A 0.55
          // daba 2.37; a 0.70, 3.23 sobre el fondo y 3.18 sobre `surface`
          // (WCAG 1.4.11).
          color: t.primary.withValues(
            alpha: filoNeon == FiloNeon.encendido ? _filoEncendido : _filoFijo,
          ),
          width: _filoGrosor,
        ),
        // El filo de Dulce es el trazo a lápiz: el rosa de trazo, no el de
        // relleno, que no llega a 3.0 sobre el fondo.
        FormaIdentidad.pill => BorderSide(color: t.primaryTrazo, width: 1.6),
      };

  /// La superficie en sí: forma, relleno, sombra y contenido. Es la misma con
  /// el filo fijo y con el que late; lo único que cambia es el [lado].
  Widget _superficie(
    IdentidadPaleta id,
    TokensContextuales t,
    BorderSide lado,
  ) {
    final forma = formaIdentidad(
      id,
      radio: protagonista ? id.radioHero : id.radioSecundario,
      lado: lado,
    );

    final caja = Container(
      margin: margen,
      decoration: ShapeDecoration(
        shape: forma,
        // La protagonista de Profundidad es `surfaceAlta` PLANA, sin
        // degradado. Antes caía de `surfaceAlta` a `surface2`, y como
        // `surface2` gobernaba desde el 3,5% hasta el 100% de la altura, el
        // borde inferior de la tarjeta quedaba a 1,13 de contraste sobre el
        // `bg`: invisible. La tarjeta se desvanecía hacia abajo y eso es lo
        // que se leía como gris. Plana a `surfaceAlta` son 1,89 en toda su
        // superficie. Verificado en dispositivo el 9-sep-2026 con una prueba
        // en rojo: el degradado SÍ se pintaba, el problema eran los valores.
        //
        // Y translúcida cuando se lo piden: `opacidadSuperficie` a 0.75 en
        // las cinco protagonistas. Lo que le da canto no es el relleno sino
        // el filo claro de arriba.
        //
        // Las secundarias de glass y de chamfer no pintan superficie (null):
        // van directamente sobre el fondo. Lo que separa una fila de la
        // siguiente ya no es una caja, y lo que dice «esto se toca» es el
        // propio CheckCircular: en glass, aro grueso, base propia y el check
        // insinuado; en chamfer, base propia y el filo rosa. Pill y las
        // protagonistas de chamfer, `surface` opaco; la de glass, `surfaceAlta`.
        color: switch (id.forma) {
          FormaIdentidad.glass =>
            protagonista
                ? t.surfaceAlta.withValues(alpha: opacidadSuperficie)
                : null,
          FormaIdentidad.chamfer => protagonista ? t.surface : null,
          FormaIdentidad.pill => t.surface,
        },
        shadows: switch (id.forma) {
          // Con el sistema de estratos la elevación la lleva la luminosidad
          // de la capa y, en la protagonista, el filo claro. Una
          // sombra negra sobre un fondo estelar apaga las estrellas en un
          // halo alrededor de cada tarjeta, justo lo contrario del efecto
          // buscado. Profundidad se queda sin sombra, como Neotokyo+.
          FormaIdentidad.glass => const [],
          // Dulce no proyecta un resplandor de Material: su sombra es un
          // trazo a rayas, que pinta `_SombraLapiz` detrás de la caja.
          FormaIdentidad.pill => const [],
          // Neotokyo+ no proyecta sombra: su relieve es el corte y el borde.
          FormaIdentidad.chamfer => const [],
        },
      ),
      child: onTap == null
          ? Padding(padding: relleno, child: child)
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                customBorder: forma,
                child: Padding(padding: relleno, child: child),
              ),
            ),
    );

    if (id.forma != FormaIdentidad.pill) return caja;
    return CustomPaint(
      painter: _SombraLapiz(
        radio: protagonista ? id.radioHero : id.radioSecundario,
        margen: margen,
        color: t.text,
      ),
      child: caja,
    );
  }
}

/// La sombra a rayas de Dulce: la caja desplazada un poco hacia abajo y a la
/// derecha, menos la caja en sí, rellena de rayas. Se pinta detrás de la
/// superficie y dentro del tamaño de la caja, no del margen.
class _SombraLapiz extends CustomPainter {
  _SombraLapiz({
    required this.radio,
    required this.margen,
    required this.color,
  });

  final double radio;
  final EdgeInsets margen;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Con el tamaño redondeado, igual que la clave de la caché.
    final tamano = Size(
      size.width.roundToDouble(),
      size.height.roundToDouble(),
    );
    pintarConCache(canvas, (
      tamano.width,
      tamano.height,
      radio,
      margen,
      color,
    ), (c) => _pintar(c, tamano));
  }

  void _pintar(Canvas canvas, Size size) {
    final caja = Rect.fromLTRB(
      margen.left,
      margen.top,
      size.width - margen.right,
      size.height - margen.bottom,
    );
    final rr = RRect.fromRectAndRadius(caja, Radius.circular(radio));
    final desplazada = Path()..addRRect(rr.shift(const Offset(7, 9)));
    final sombra = Path.combine(
      PathOperation.difference,
      desplazada,
      Path()..addRRect(rr),
    );
    // Más oscura pegada a la tarjeta y que se desvanece hacia fuera: cuánto se
    // sale el punto de la caja por la derecha o por abajo, lo que sea mayor.
    double tinta(Offset p) {
      final fuera = max(
        max(0.0, p.dx - caja.right),
        max(0.0, p.dy - caja.bottom),
      );
      return max(0.15, 1 - fuera / 9);
    }

    pintarSombreado(
      canvas,
      sombra,
      color: color,
      intensidad: tinta,
      separacion: 2.1,
      alfa: 0.55,
      grosor: 0.9,
      cruzado: true,
      semilla: semillaDe(size),
    );
  }

  @override
  bool shouldRepaint(_SombraLapiz viejo) =>
      viejo.radio != radio || viejo.margen != margen || viejo.color != color;
}

/// La superficie de Neotokyo+ con el filo latiendo. Es el único caso con
/// estado: el resto de la superficie se construye igual, y sólo cambia el alfa
/// del borde en cada fotograma.
class _FiloLatiente extends StatefulWidget {
  final Duration duracion;
  final Color color;
  final Widget Function(BorderSide lado) construir;

  const _FiloLatiente({
    required this.duracion,
    required this.color,
    required this.construir,
  });

  @override
  State<_FiloLatiente> createState() => _FiloLatienteState();
}

class _FiloLatienteState extends State<_FiloLatiente>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _alfa;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duracion);
    // Ida y vuelta, cada tramo con la misma curva: 0,70 → 1,0 → 0,70.
    _alfa = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: _filoFijo,
          end: _filoEncendido,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _filoEncendido,
          end: _filoFijo,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con "reducir movimiento" el filo se queda en 0,70 y no corre ningún
    // ticker.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      // La fase sale del reloj, no del montaje ni de lo último que se pintó:
      // todas las tarjetas laten juntas, también al volver de «Quitar
      // animaciones».
      final ciclo = widget.duracion.inMilliseconds;
      _controller.value = (relojFilo() % ciclo) / ciclo;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _alfa,
    builder: (context, _) => widget.construir(
      BorderSide(
        color: widget.color.withValues(alpha: _alfa.value),
        width: _filoGrosor,
      ),
    ),
  );
}
