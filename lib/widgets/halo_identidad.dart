import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Luz ambiental detrás de la mascota: un degradado radial que late al ritmo
/// de la identidad equipada. Es lo que hace que la pantalla se sienta de una
/// identidad y no de otra antes incluso de leer nada.
///
/// El perfil se elige por [FormaIdentidad], no por el código de la identidad:
/// así una identidad nueva sólo tiene que declarar su forma y hereda halo,
/// terrario, anillo y burbuja sin tocar ninguno de los cuatro. El `switch`
/// sobre el enum es exhaustivo, así que añadir una forma rompe la compilación
/// en todos los sitios que hay que revisar — que es justo lo que se quiere.
///
/// No clipa: pinta algo más ancho que su caja a propósito, para que la luz se
/// derrame alrededor de la mascota. Quien lo mete en un `Stack` tiene que
/// dejarlo desbordar (`clipBehavior: Clip.none`).
class HaloIdentidad extends StatefulWidget {
  /// Lado de la ilustración a la que acompaña. El halo se dimensiona a partir
  /// de aquí; no hace falta pasarle su propio tamaño.
  final double tamano;

  /// Factor sobre las opacidades del perfil. A 1 el halo es el de la pantalla
  /// de mascota, que es donde manda; por debajo se apaga proporcionalmente sin
  /// tocar el ritmo ni el recorrido, que son lo que identifica a cada
  /// identidad.
  ///
  /// Existe para la mini-mascota: ahí el halo flota sobre el contenido de
  /// cualquier pantalla y no puede competir con lo que hay debajo. Escalar la
  /// intensidad es lo correcto; bajarle la duración lo convertiría en otra
  /// identidad.
  final double intensidad;

  const HaloIdentidad({
    super.key,
    required this.tamano,
    this.intensidad = 1.0,
  });

  @override
  State<HaloIdentidad> createState() => _HaloIdentidadState();
}

/// Cómo late el halo de una forma. Todo en la misma unidad: fracción de opaco.
class _PerfilHalo {
  /// Recorrido de la capa base. Si mínimo y máximo coinciden, no respira: es
  /// el caso de Neotokyo+, donde el movimiento lo pone el destello.
  final double opacidadMin;
  final double opacidadMax;

  /// Recorrido del radio, como factor sobre el radio de reposo.
  final double escalaMin;
  final double escalaMax;

  /// Techo de la capa superpuesta que parpadea. A 0 no hay segunda capa.
  ///
  /// El flicker se hace SIEMPRE así, animando la opacidad de una capa de
  /// degradado ya pintada, y nunca redibujando un `boxShadow` frame a frame:
  /// una sombra animada obliga a recalcular el blur en cada fotograma y es de
  /// lo más caro que se puede poner en un bucle permanente.
  final double destelloMax;

  const _PerfilHalo({
    required this.opacidadMin,
    required this.opacidadMax,
    required this.escalaMin,
    required this.escalaMax,
    this.destelloMax = 0,
  });
}

const _PerfilHalo _haloGlass = _PerfilHalo(
  opacidadMin: 0.18,
  opacidadMax: 0.32,
  escalaMin: 0.88,
  escalaMax: 1.0,
);

/// Base sostenida y un neón encima que parpadea. La base no respira para que
/// el parpadeo sea lo único que se mueva y se lea como un tubo de descarga.
const _PerfilHalo _haloChamfer = _PerfilHalo(
  opacidadMin: 0.14,
  opacidadMax: 0.14,
  escalaMin: 1.0,
  escalaMax: 1.0,
  destelloMax: 0.34,
);

/// Alba es discreta también aquí: se nota que hay luz, no de dónde viene.
const _PerfilHalo _haloHairline = _PerfilHalo(
  opacidadMin: 0.10,
  opacidadMax: 0.15,
  escalaMin: 0.96,
  escalaMax: 1.04,
);

const _PerfilHalo _haloPill = _PerfilHalo(
  opacidadMin: 0.16,
  opacidadMax: 0.30,
  escalaMin: 0.90,
  escalaMax: 1.04,
);

_PerfilHalo _perfilDe(FormaIdentidad forma) => switch (forma) {
      FormaIdentidad.glass => _haloGlass,
      FormaIdentidad.chamfer => _haloChamfer,
      FormaIdentidad.hairline => _haloHairline,
      FormaIdentidad.pill => _haloPill,
    };

class _HaloIdentidadState extends State<HaloIdentidad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido;

  /// Misma lectura y mismo criterio que `MascotaAnimadaViva`: un bucle
  /// permanente es exactamente lo que "reducir movimiento" quiere apagar.
  bool _animacionesDesactivadas = false;

  /// Última duración con la que se sincronizó el bucle. La identidad no llega
  /// por parámetro sino del notifier, así que `didUpdateWidget` no se entera
  /// de que ha cambiado: se comprueba en `build` y sólo se toca el controlador
  /// cuando de verdad cambia algo.
  Duration? _duracionSincronizada;

  @override
  void initState() {
    super.initState();
    _latido = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animacionesDesactivadas =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _duracionSincronizada = null; // fuerza la resincronización en el build
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  void _sincronizarBucle(Duration duracion) {
    if (_duracionSincronizada == duracion) return;
    _duracionSincronizada = duracion;
    _latido.duration = duracion;
    if (_animacionesDesactivadas) {
      _latido.stop();
      _latido.value = 0.25; // cuarto de ciclo: el pico del péndulo, luz plena
    } else {
      _latido.repeat();
    }
  }

  /// De [0,1] a un vaivén 0→1→0 sin saltos en el empalme del bucle. Se usa el
  /// coseno en vez de `repeat(reverse: true)` porque el destello necesita el
  /// recorrido crudo y así los dos salen del mismo controlador.
  double _pendulo(double v) => (1 - math.cos(v * 2 * math.pi)) / 2;

  /// Parpadeo irregular: tres senos primos entre sí, para que no se le vea el
  /// periodo. Barato de calcular — sale una vez por fotograma.
  double _parpadeo(double v) {
    final a = math.sin(v * 2 * math.pi * 3);
    final b = math.sin(v * 2 * math.pi * 11 + 1.7);
    final c = math.sin(v * 2 * math.pi * 23 + 0.4);
    return (0.55 + 0.28 * a + 0.12 * b + 0.05 * c).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final perfil = _perfilDe(id.forma);
    _sincronizarBucle(id.duracionAnimacionFirma);

    return SizedBox(
      width: widget.tamano,
      height: widget.tamano,
      child: AnimatedBuilder(
        animation: _latido,
        builder: (context, _) {
          final p = _pendulo(_latido.value);
          return CustomPaint(
            painter: _HaloPainter(
              colorBase: t.primary,
              // El destello va en el color de puntos, no en el primario: dos
              // tonos distintos es lo que separa un neón de un foco.
              colorDestello: t.points,
              opacidad: (perfil.opacidadMin +
                      (perfil.opacidadMax - perfil.opacidadMin) * p) *
                  widget.intensidad,
              escala:
                  perfil.escalaMin + (perfil.escalaMax - perfil.escalaMin) * p,
              destello: perfil.destelloMax == 0
                  ? 0
                  : perfil.destelloMax *
                      _parpadeo(_latido.value) *
                      widget.intensidad,
            ),
          );
        },
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  final Color colorBase;
  final Color colorDestello;
  final double opacidad;
  final double escala;
  final double destello;

  _HaloPainter({
    required this.colorBase,
    required this.colorDestello,
    required this.opacidad,
    required this.escala,
    required this.destello,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    // Por encima de la mitad del lado: la luz desborda la caja, que es lo que
    // la hace parecer ambiente y no un disco pintado detrás.
    final radio = size.shortestSide * 0.58 * escala;

    _capa(canvas, centro, radio, colorBase, opacidad);
    if (destello > 0) {
      _capa(canvas, centro, radio * 0.82, colorDestello, destello);
    }
  }

  void _capa(
      Canvas canvas, Offset centro, double radio, Color color, double alfa) {
    if (alfa <= 0.004 || radio <= 0) return;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pincel = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alfa),
          color.withValues(alpha: alfa * 0.34),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(rect);
    canvas.drawCircle(centro, radio, pincel);
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.opacidad != opacidad ||
      old.escala != escala ||
      old.destello != destello ||
      old.colorBase != colorBase ||
      old.colorDestello != colorDestello;
}
