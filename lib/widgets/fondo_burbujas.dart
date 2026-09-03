import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/progreso_dia.dart';

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

/// Las burbujas de Dulce: se acumulan con el progreso del día.
///
/// NO se exporta en el barrel. La puerta es `FondoIdentidad`.
///
/// Escucha el progreso ella misma, como `FondoCiudad`: en Dulce el fondo y la
/// capa de progreso son la misma cosa, así que no usa la capa de delante.
///
/// LAS BURBUJAS SON MÁS CLARAS QUE EL FONDO, Y ESO NO ES DECORATIVO. En Dulce
/// hay texto en `textMuted` flotando sobre el fondo sin tarjeta debajo —la
/// cabecera "Completados" y el aviso de día sin hábitos—, y ese token sólo
/// tiene 4.95 de contraste sobre el `bg`: 0.45 de margen sobre el 4.5 de AA.
/// Con el rosa primario de la web, dos burbujas solapadas lo hunden a 3.45 y
/// no hay alfa que lo salve: el máximo que aguantaría es 0.05, invisible.
///
/// Al ser más claras que el fondo se invierte el signo: `textMuted` da 4.95
/// sobre el `bg` y 5.52 sobre `surface`, así que cada burbuja SUBE el
/// contraste del texto y solaparse sólo mejora las cosas. Si algún día se
/// cambia este color por uno más oscuro que el fondo, hay que volver a medir
/// el peor caso con solapamiento.
class FondoBurbujas extends StatelessWidget {
  /// Los colores de la identidad, que los da el despachador.
  final TokensContextuales tokens;

  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoBurbujas({
    super.key,
    required this.tokens,
    required this.nivel,
  });

  /// Las mismas burbujas, más tenues: así dice Dulce que esto está más lejos.
  /// El mismo 0.55 que Profundidad aplica a su cielo y Neotokyo+ a su ciudad.
  double get _atenuacion => nivel == NivelFondo.mundo ? 1.0 : 0.55;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgresoDia>(
      valueListenable: progresoDiaNotifier,
      builder: (context, progreso, _) => CustomPaint(
        painter: _FondoBurbujasPainter(tokens, _atenuacion, progreso),
      ),
    );
  }
}

class _FondoBurbujasPainter extends CustomPainter {
  final TokensContextuales tokens;
  final double atenuacion;
  final ProgresoDia progreso;

  const _FondoBurbujasPainter(this.tokens, this.atenuacion, this.progreso);

  /// Cuántas burbujas se ven.
  ///
  /// El 0.8 del final es el mismo tope que usa la landing: ni con el día
  /// entero completado salen todas. Que siempre quede sitio para una más es lo
  /// que hace que esto parezca acumulación y no una cuadrícula llena.
  ///
  /// Con `total` a cero no sale ninguna, y entonces esta identidad no dibuja
  /// nada: al contrario que la ciudad de Neotokyo+, aquí no hay parte fija.
  int get _visibles => progreso.total > 0
      ? (_totalBurbujas * (progreso.hechos / progreso.total) * 0.8).round()
      : 0;

  @override
  void paint(Canvas canvas, Size size) {
    final cuantas = _visibles;
    if (cuantas == 0) return;

    final pintura = Paint()
      ..color = tokens.surface.withValues(alpha: 0.85 * atenuacion);

    for (var i = 0; i < cuantas && i < _burbujas.length; i++) {
      final b = _burbujas[i];
      canvas.drawCircle(
        Offset(b.x * size.width, b.y * size.height),
        b.radio,
        pintura,
      );
    }
  }

  // Mismo motivo que en `_FondoEstelarPainter` y `_FondoCiudadPainter`:
  // `TokensContextuales` no define `operator ==`, así que se compara el campo
  // que el painter usa de verdad. `ProgresoDia` sí lo define.
  @override
  bool shouldRepaint(covariant _FondoBurbujasPainter oldDelegate) =>
      oldDelegate.tokens.surface != tokens.surface ||
      oldDelegate.atenuacion != atenuacion ||
      oldDelegate.progreso != progreso;
}
