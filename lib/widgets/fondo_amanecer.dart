import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/progreso_dia.dart';

/// Los dos extremos del cielo de Alba.
///
/// El amanecer va de un alba pálida y fría a un alba plena y cálida, y NO de
/// noche a día. El motivo no es estético: las filas de Alba no llevan tarjeta
/// —`hairline` sólo dibuja una línea debajo—, así que TODO el texto de la
/// pantalla se apoya directamente en este cielo. Un cielo nocturno dejaría el
/// texto casi negro de Alba sin contraste justo en el estado de cero hábitos
/// completados, que es el que ve un usuario nuevo su primer día.
///
/// Estos cuatro valores están medidos: en el peor punto de todo el recorrido
/// —abajo del todo, con el día entero completado, `#FFE3CC`— `textMuted` da
/// 4.87 sobre el 4.5 de AA, y el `aroVacio` del check da 3.12 sobre el 3.0 de
/// WCAG 1.4.11. Si se calienta más el horizonte, el aro deja de verse. Ver
/// también `TokensContextuales.aroVacio`.
const Color _cieloAltoPalido = Color(0xFFF2EFF3);
const Color _cieloBajoPalido = Color(0xFFF6EEEA);
const Color _cieloAltoPleno = Color(0xFFF7F0E8);
const Color _cieloBajoPleno = Color(0xFFFFE3CC);

/// El sol y su halo. Los dos MÁS CLAROS que cualquier punto del cielo, y eso
/// es lo que hace segura toda la composición: lo único que puede bajar el
/// contraste es que el cielo se caliente, y ese recorrido está acotado arriba.
/// El sol sólo puede subirlo.
const Color _nucleoSol = Color(0xFFFFF6E8);
const Color _haloSol = Color(0xFFFFEDD5);

/// Dónde está el sol, en fracciones de pantalla.
///
/// Sale por la derecha y se queda en el tercio bajo: nunca sube hasta la
/// cabecera. Con nada hecho su centro está por debajo del borde inferior y
/// sólo asoma el halo, que es exactamente lo que tiene que parecer un alba que
/// aún no ha empezado.
const double _solX = 0.72;
const double _solYInicio = 1.06;
const double _solYFinal = 0.66;

/// Radio del sol como fracción del ancho de la pantalla, y cuánto se extiende
/// su halo respecto a ese radio.
const double _solRadio = 0.16;
const double _haloVeces = 3.0;

/// El amanecer de Alba: el cielo se calienta y el sol sube con el progreso.
///
/// NO se exporta en el barrel. La puerta es `FondoIdentidad`.
///
/// Escucha el progreso él mismo, como `FondoCiudad` y `FondoBurbujas`: en las
/// tres identidades que no son Profundidad el fondo y el progreso son el mismo
/// dibujo, así que no usan la capa de delante.
class FondoAmanecer extends StatelessWidget {
  /// Los colores de la identidad. Alba no los usa para pintar el cielo —sus
  /// cuatro tonos son propios y medidos—, pero se reciben igual que las otras
  /// tres para que el despachador trate a las cuatro por igual.
  final TokensContextuales tokens;

  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoAmanecer({
    super.key,
    required this.tokens,
    required this.nivel,
  });

  /// Alba NO atenúa: retrasa.
  ///
  /// Las otras tres bajan el alfa de su dibujo para decir "esto está más
  /// lejos". Aquí eso sería oscurecer el cielo, y oscurecer el cielo es
  /// quedarse sin contraste para el texto que flota encima. Así que el 0.55
  /// multiplica al PROGRESO: el nivel 2 es un amanecer menos avanzado, no un
  /// amanecer más apagado.
  ///
  /// Consecuencia asumida: con cero hábitos hechos, los niveles 1 y 2 de Alba
  /// se ven iguales.
  double get _factorNivel => nivel == NivelFondo.mundo ? 1.0 : 0.55;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgresoDia>(
      valueListenable: progresoDiaNotifier,
      builder: (context, progreso, _) => CustomPaint(
        painter: _FondoAmanecerPainter(progreso, _factorNivel),
      ),
    );
  }
}

class _FondoAmanecerPainter extends CustomPainter {
  final ProgresoDia progreso;
  final double factorNivel;

  const _FondoAmanecerPainter(this.progreso, this.factorNivel);

  /// Cuánto ha avanzado el amanecer, de 0 a 1.
  ///
  /// Con `total` a cero el cielo se queda en el alba pálida, y se dibuja
  /// igualmente: el cielo es el fondo, no el progreso. Es lo mismo que hacen
  /// los bloques de Neotokyo+ y lo contrario que las burbujas de Dulce.
  double get _avance {
    if (progreso.total <= 0) return 0.0;
    return (progreso.hechos / progreso.total).clamp(0.0, 1.0) * factorNivel;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final t = _avance;

    // El cielo: un degradado vertical entre dos degradados. Nada de línea de
    // horizonte ni silueta de tierra — una masa oscura abajo caería justo
    // encima de las filas de hábitos.
    final arriba = Color.lerp(_cieloAltoPalido, _cieloAltoPleno, t)!;
    final abajo = Color.lerp(_cieloBajoPalido, _cieloBajoPleno, t)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [arriba, abajo],
        ).createShader(rect),
    );

    final centro = Offset(
      _solX * size.width,
      (_solYInicio + (_solYFinal - _solYInicio) * t) * size.height,
    );
    final radio = _solRadio * size.width;
    final lado = size.shortestSide;

    // El halo primero, el disco encima.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (centro.dx / size.width) * 2 - 1,
            (centro.dy / size.height) * 2 - 1,
          ),
          radius: (radio * _haloVeces) / lado,
          colors: [
            _haloSol.withValues(alpha: 0.85),
            _haloSol.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(centro, radio, Paint()..color = _nucleoSol);
  }

  @override
  bool shouldRepaint(covariant _FondoAmanecerPainter oldDelegate) =>
      oldDelegate.progreso != progreso ||
      oldDelegate.factorNivel != factorNivel;
}
