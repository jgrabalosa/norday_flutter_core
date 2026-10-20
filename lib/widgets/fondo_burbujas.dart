import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/progreso_dia.dart';
import 'lapiz.dart';

/// Una burbuja del fondo de Dulce.
///
/// [x] e [y] son fracciones de la pantalla, para que valgan a cualquier
/// tamaño. [radio] va en píxeles lógicos y NO se normaliza: igual que los
/// radios de las estrellas de Profundidad, una burbuja tiene que medir lo
/// mismo en un móvil que en una tablet o saldría deformada.
class _Burbuja {
  final double x;
  final double y;
  final double radio;

  const _Burbuja({required this.x, required this.y, required this.radio});
}

/// Cuántas burbujas hay en total. Sólo se ven las primeras, según el progreso.
const int _totalBurbujas = 110;

List<_Burbuja> _generarBurbujas() {
  final random = Random(23);
  return List.generate(_totalBurbujas, (_) {
    return _Burbuja(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radio: 5.0 + random.nextDouble() * 13.0,
    );
  });
}

/// Semilla fija y generadas una sola vez al cargar el fichero, por el mismo
/// motivo que el cielo de Profundidad: el fondo tiene que ser idéntico en cada
/// arranque y en cada `build`, nunca recalculado dentro de `paint`.
///
/// Aquí sí se sortean, al revés que el perfil de la ciudad de Neotokyo+: una
/// silueta urbana tiene ritmo y se elige, pero dónde cae una burbuja da
/// exactamente igual.
final List<_Burbuja> _burbujas = _generarBurbujas();

/// Cuántas burbujas se ven con este progreso.
///
/// El 0.8 del final es el mismo tope que usa la landing: ni con el día
/// entero completado salen todas. Que siempre quede sitio para una más es lo
/// que hace que esto parezca acumulación y no una cuadrícula llena.
///
/// Con `total` a cero no sale ninguna, y entonces esta identidad no dibuja
/// nada: al contrario que la ciudad de Neotokyo+, aquí no hay parte fija.
int _visiblesDe(ProgresoDia p) =>
    p.total > 0 ? (_totalBurbujas * p.avance * 0.8).round() : 0;

/// Tope de tinta de cada burbuja: la burbuja entera se pinta dentro de una capa
/// con esta opacidad (por la atenuación). Con tres burbujas solapadas bajo una
/// letra, `textMuted` sobre `bg` se queda en 4,53 (AA). Con 0,20 bajaría a 3,9.
@visibleForTesting
const double tintaMaximaBurbuja = 0.15;

/// Las burbujas, para que los tests midan cuántas se solapan.
@visibleForTesting
List<({double x, double y, double radio})> get burbujasDeDulce => [
  for (final b in _burbujas) (x: b.x, y: b.y, radio: b.radio),
];

/// Cuántas se ven como mucho: el tope del 0,8 de [_visiblesDe].
@visibleForTesting
int get maximoBurbujasVisibles => (_totalBurbujas * 0.8).round();

/// Las burbujas de Dulce: se acumulan con el progreso del día.
///
/// NO se exporta en el barrel. La puerta es `FondoIdentidad`.
///
/// Escucha el progreso ella misma, como `FondoCiudad`: en Dulce el fondo y la
/// capa de progreso son la misma cosa, así que no usa la capa de delante.
///
/// LAS BURBUJAS SON DE LÁPIZ ROSA, Y SON MÁS OSCURAS QUE EL PAPEL, ASÍ QUE HAY
/// QUE CUIDAR SU TINTA. En Dulce hay texto en `textMuted` flotando sobre el
/// fondo sin tarjeta debajo —la cabecera "Completados" y el aviso de día sin
/// hábitos—, y ese token tiene 7.62 de contraste sobre el `bg`. Una burbuja
/// más oscura que el papel lo hunde, y solaparse lo hunde más.
///
/// El invariante: cada burbuja lleva como mucho [tintaMaximaBurbuja] de tinta,
/// en ningún punto se solapan más de tres burbujas (lo comprueba
/// dulce_burbujas_lapiz_test.dart), y así `textMuted` sobre `bg` no baja de
/// 4,5. Si alguien cambia el color, la tinta o cuántas hay, hay que volver a
/// medir.
class FondoBurbujas extends StatefulWidget {
  /// Los colores de la identidad, que los da el despachador.
  final TokensContextuales tokens;

  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoBurbujas({super.key, required this.tokens, required this.nivel});

  @override
  State<FondoBurbujas> createState() => _FondoBurbujasState();
}

/// Al marcar, las burbujas nuevas entran con el rebote de la identidad
/// (320 ms, `easeOutBack`, su `duracionTransicion` y su `curvaTransicion`).
/// Sólo cuando el avance sube en el mismo día; con «Quitar animaciones», nada.
class _FondoBurbujasState extends State<FondoBurbujas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gesto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  ProgresoDia _progreso = progresoDiaNotifier.value;

  /// Cuántas se veían ANTES del último marcado: las de ahí en adelante son
  /// las nuevas. `null` si no hay nada nuevo que animar.
  int? _desde;

  /// Las mismas burbujas, más tenues: así dice Dulce que esto está más lejos.
  /// El mismo 0.55 que Profundidad aplica a su cielo y Neotokyo+ a su ciudad.
  double get _atenuacion => widget.nivel == NivelFondo.mundo ? 1.0 : 0.55;

  @override
  void initState() {
    super.initState();
    progresoDiaNotifier.addListener(_alCambiar);
  }

  void _alCambiar() {
    if (!mounted) return;
    final nuevo = progresoDiaNotifier.value;
    final sube =
        nuevo.fecha == _progreso.fecha && nuevo.avance > _progreso.avance;
    final sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final antes = _progreso;
    setState(() {
      _progreso = nuevo;
      _desde = sube && !sinMovimiento ? _visiblesDe(antes) : null;
    });
    if (_desde != null) {
      _gesto.forward(from: 0);
    } else {
      _gesto.value = 1;
    }
  }

  @override
  void dispose() {
    progresoDiaNotifier.removeListener(_alCambiar);
    _gesto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gesto,
      builder: (context, _) => CustomPaint(
        painter: _FondoBurbujasPainter(
          widget.tokens,
          _atenuacion,
          _progreso,
          desde: _desde,
          gesto: _gesto.value,
        ),
      ),
    );
  }
}

class _FondoBurbujasPainter extends CustomPainter {
  final TokensContextuales tokens;
  final double atenuacion;
  final ProgresoDia progreso;

  /// Ver `_FondoBurbujasState._desde`.
  final int? desde;

  /// De 0 a 1, el recorrido de la entrada de las burbujas nuevas.
  final double gesto;

  const _FondoBurbujasPainter(
    this.tokens,
    this.atenuacion,
    this.progreso, {
    this.desde,
    this.gesto = 1.0,
  });

  /// Ver [_visiblesDe].
  int get _visibles => _visiblesDe(progreso);

  @override
  void paint(Canvas canvas, Size size) {
    final cuantas = _visibles;
    if (cuantas == 0) return;

    for (var i = 0; i < cuantas && i < _burbujas.length; i++) {
      final b = _burbujas[i];
      // Las nuevas entran con el rebote de la identidad; las demás, quietas.
      final escala = desde != null && i >= desde!
          ? Curves.easeOutBack.transform(gesto)
          : 1.0;
      if (escala <= 0) continue;
      final centro = Offset(b.x * size.width, b.y * size.height);
      final lado = b.radio * 2;
      // Cada burbuja se graba una vez a su tamaño; el rebote solo la escala.
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.scale(escala);
      canvas.translate(-b.radio, -b.radio);
      pintarConCache(
        canvas,
        ('burbuja', i, b.radio, tokens.primaryTrazo, atenuacion),
        Size(lado, lado),
        (c) => _pintarBurbuja(c, b.radio, i),
        desborde: 3,
      );
      canvas.restore();
    }
  }

  /// Una burbuja a lápiz: rayas que se desvanecen hacia el brillo (papel sin
  /// pintar, arriba a la izquierda) y el aro. Todo en una capa con tope de
  /// tinta, ver [tintaMaximaBurbuja].
  void _pintarBurbuja(Canvas c, double r, int i) {
    final centro = Offset(r, r);
    final circulo = Path()..addOval(Rect.fromCircle(center: centro, radius: r));
    final brillo = centro.translate(-r * 0.34, -r * 0.34);
    c.saveLayer(
      Rect.fromCircle(center: centro, radius: r + 3),
      Paint()..color = Color.fromRGBO(0, 0, 0, tintaMaximaBurbuja * atenuacion),
    );
    pintarSombreado(
      c,
      circulo,
      color: tokens.primaryTrazo,
      intensidad: (p) =>
          (((p - brillo).distance - r * 0.28) / r).clamp(0.0, 1.0),
      separacion: 2.2,
      alfa: 0.9,
      semilla: 7 * i + 3,
    );
    pintarTrazoLapiz(
      c,
      circulo,
      color: tokens.primaryTrazo,
      grosor: 1.4,
      semilla: 7 * i + 5,
    );
    c.restore();
  }

  // Mismo motivo que en `_FondoEstelarPainter` y `_FondoCiudadPainter`:
  // `TokensContextuales` no define `operator ==`, así que se compara el campo
  // que el painter usa de verdad (el trazo de lápiz, `primaryTrazo`).
  // `ProgresoDia` sí lo define.
  @override
  bool shouldRepaint(covariant _FondoBurbujasPainter oldDelegate) =>
      oldDelegate.tokens.primaryTrazo != tokens.primaryTrazo ||
      oldDelegate.atenuacion != atenuacion ||
      oldDelegate.progreso != progreso ||
      oldDelegate.desde != desde ||
      oldDelegate.gesto != gesto;
}
