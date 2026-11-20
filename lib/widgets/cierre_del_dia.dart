import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/progreso_dia.dart';
import 'capa_constelacion.dart';
import 'constelaciones.dart';
import 'letreros.dart';
import 'ramo_dulce.dart';

/// El cierre del día: al completar el último hábito, todo se oscurece y
/// aparecen, en este orden, [titulo], el nombre de la figura del día y
/// [despedida]. La figura es la constelación en Profundidad, un ramo a lápiz
/// en Dulce (una flor por hábito) y el letrero de neón en Neotokyo+ (un tubo
/// por hábito, D-35). Un toque lo cierra, y el Future termina entonces.
///
/// La constelación la pinta su capa (`CapaProgresoIdentidad`), que va por
/// encima de esta: al marcar el día como cerrado se realza. El ramo y el
/// letrero viven en la lista de Hoy (D-41: `RamoDelDia` y `LetreroDelDia`),
/// debajo del velo, así que la ceremonia los pinta en grande:
/// - **Dulce:** el ramo de todas las flores, a grafito como se veía en Hoy,
///   se colorea (900 ms) y se ata (500 ms);
/// - **Neotokyo+:** el letrero se enciende tubo a tubo, con su parpadeo y el
///   zumbido ([duracionEncendidoLetrero]).
///
/// En los dos, los textos esperan a que la figura esté hecha. Si no hay nada
/// que contar (ningún hábito del día), termina en el acto. Los textos los
/// pone la app, como el resto de textos que hablan de hábitos.
///
/// Al empezar marca el día como cerrado ([marcarDiaCerrado]), así que al
/// irse el velo queda ya el estado final: la figura realzada.
///
/// Para el lector de pantalla, la ceremonia es un solo nodo: oye los tres
/// textos de una vez y la acción «Cerrar», con el mismo bloqueo que el toque
/// (no cierra hasta que los textos han entrado). Lo de debajo no se oye
/// mientras dura. Y vibra una vez al salir el nombre de la constelación.
///
/// Necesita que la app tenga montada una [CapaCierreDelDia]; si no, no
/// espera a nadie y termina en el acto.
Future<void> mostrarCierreDelDia({
  required String titulo,
  required String despedida,
}) {
  if (progresoDiaNotifier.value.total <= 0) return Future.value();
  if (_Cierre.capas == 0) return Future.value();

  final enCurso = _Cierre.peticion.value;
  if (enCurso != null) return enCurso.hecho.future;

  final peticion = _Peticion(titulo, despedida);
  _Cierre.peticion.value = peticion;
  marcarDiaCerrado(true);
  return peticion.hecho.future;
}

/// Lo que tarda en Dulce el ramo de la ceremonia: 500 ms de velo con el
/// boceto, 900 de coloreado y 500 de atado. No depende de cuántos hábitos
/// hay: las flores ya salieron durante el día (D-41).
const Duration duracionRamoCierre = Duration(milliseconds: 1900);

/// Si hay una ceremonia del cierre en curso. El letrero y el ramo de la lista
/// lo miran al ver el día cerrado: con ceremonia, el letrero espera apagado y
/// se enciende al irse el velo, y el ramo cambia de golpe (debajo del velo);
/// sin ella (abrir la app
/// con el día ya cerrado, volver a hoy en la tira), aparecen con un
/// fundido. [mostrarCierreDelDia] pone la petición antes de
/// marcar el día como cerrado, así que quien escucha ese cambio ya la ve.
bool get hayCierreDelDiaEnCurso => _Cierre.peticion.value != null;

/// Avisa cuando la ceremonia empieza, se mueve su velo o termina. Lo escucha
/// el letrero de la lista, que espera apagado debajo del velo y se enciende
/// al irse (si no, se veía doble: 20-nov-2026). No se exporta.
final Listenable cambiosCierreDelDia = Listenable.merge([
  _Cierre.peticion,
  _Cierre.velo,
]);

/// El velo de la ceremonia, de 0 a 1. No se exporta.
double get veloCierreDelDia => _Cierre.velo.value;

/// Cierra la ceremonia: nadie la pinta ya y quien la esperaba sigue.
void _terminarCierre(_Peticion peticion) {
  if (_Cierre.peticion.value == peticion) _Cierre.peticion.value = null;
  _Cierre.velo.value = 0;
  if (!peticion.hecho.isCompleted) peticion.hecho.complete();
}

class _Peticion {
  final String titulo;
  final String despedida;
  final Completer<void> hecho = Completer<void>();

  _Peticion(this.titulo, this.despedida);
}

/// El velo, con [v] de 0 a 1. Profundidad lo oscurece; Dulce, con su papel
/// crema (lo pidió Quim): un fondo oscuro no tiene sitio en Dulce.
Color _colorVelo(double v) {
  final id = identidadEquipadaNotifier.value;
  if (id.fondo == FondoIdentidadTipo.acumulacion) {
    return id.tokens.fondoNota.withValues(alpha: 0.94 * v);
  }
  return Colors.black.withValues(alpha: _CapaCierreDelDiaState._alfaVelo * v);
}

/// Estado compartido entre la capa del contenido y el velo de la barra.
abstract final class _Cierre {
  static final ValueNotifier<_Peticion?> peticion = ValueNotifier(null);

  /// El velo, de 0 a 1. Lo mueve la capa; el de la barra lo copia.
  static final ValueNotifier<double> velo = ValueNotifier(0);

  /// Lo que hace un toque en cualquiera de los dos velos.
  static VoidCallback? alTocar;

  /// Cuántas [CapaCierreDelDia] hay montadas.
  static int capas = 0;
}

/// La capa del cierre del día. Va en el `Stack` de la pantalla principal,
/// ENTRE las páginas y la capa de la constelación: así el velo oscurece el
/// contenido y las estrellas brillan por encima. La constelación deja pasar
/// los toques, así que el toque llega a esta capa.
///
/// Mientras no hay cierre no pinta nada y no roba ningún toque.
class CapaCierreDelDia extends StatefulWidget {
  const CapaCierreDelDia({super.key});

  @override
  State<CapaCierreDelDia> createState() => _CapaCierreDelDiaState();
}

class _CapaCierreDelDiaState extends State<CapaCierreDelDia>
    with TickerProviderStateMixin {
  static const _duracionVelo = Duration(milliseconds: 500);

  /// Los tres textos. Cada uno entra en su tramo; el toque no cierra hasta
  /// que el último ha terminado de entrar, para que un toque reflejo tras
  /// marcar el hábito no se coma la ceremonia.
  static const _duracionTextos = Duration(milliseconds: 2900);
  static const _tramoTitulo = Interval(0.21, 0.38, curve: Curves.easeOut);
  static const _tramoNombre = Interval(0.48, 0.66, curve: Curves.easeOut);
  static const _tramoDespedida = Interval(0.83, 1.0, curve: Curves.easeOut);

  /// Lo oscuro que llega a ponerse el velo.
  static const _alfaVelo = 0.75;

  late final AnimationController _velo;
  late final AnimationController _textos;

  /// La figura de Dulce o de Neotokyo+: el ramo que se colorea y se ata, o
  /// el letrero que se enciende. Su duración se fija al empezar.
  late final AnimationController _ramo;
  bool _sinMovimiento = false;
  bool _cerrando = false;

  /// Si la ceremonia de esta vez es la de Dulce, con el ramo antes que los
  /// textos.
  bool _enDulce = false;

  /// Si es la de Neotokyo+: el letrero se enciende antes que los textos.
  bool _enNeotokyo = false;

  /// El ramo de Dulce en la ceremonia: 500 ms de velo, con el boceto ya
  /// dentro; se colorea en [_colorear] y se ata en [_atar]. Suman
  /// [duracionRamoCierre].
  static const _esperaRamo = Duration(milliseconds: 500);
  static const _colorear = Duration(milliseconds: 900);
  static const _atar = Duration(milliseconds: 500);

  /// Si ya ha vibrado en esta ceremonia: una sola vez, al salir el nombre.
  bool _vibro = false;

  @override
  void initState() {
    super.initState();
    _velo = AnimationController(vsync: this, duration: _duracionVelo)
      ..addListener(() => _Cierre.velo.value = _velo.value);
    _textos = AnimationController(vsync: this, duration: _duracionTextos)
      ..addListener(_alMoverTextos);
    _ramo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener(_alTerminarRamo);
    _Cierre.capas++;
    _Cierre.alTocar = _alTocar;
    _Cierre.peticion.addListener(_alCambiarPeticion);
    if (_Cierre.peticion.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _empezar());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _alCambiarPeticion() {
    if (_Cierre.peticion.value != null) _empezar();
  }

  void _alMoverTextos() {
    if (_vibro || _textos.value < _tramoNombre.begin) return;
    _vibro = true;
    HapticFeedback.heavyImpact();
  }

  /// En Dulce, los textos esperan a que el ramo esté formado; en Neotokyo+,
  /// a que el letrero esté encendido.
  void _alTerminarRamo(AnimationStatus estado) {
    if (estado == AnimationStatus.completed &&
        (_enDulce || _enNeotokyo) &&
        !_sinMovimiento) {
      _textos.forward(from: 0);
    }
  }

  void _empezar() {
    if (!mounted || _Cierre.peticion.value == null) return;
    _cerrando = false;
    _vibro = false;
    final fondo = identidadEquipadaNotifier.value.fondo;
    _enDulce = fondo == FondoIdentidadTipo.acumulacion;
    _enNeotokyo = fondo == FondoIdentidadTipo.ciudad;
    // En Dulce, ya no depende de cuántos hábitos hay: las flores salieron
    // durante el día. En Neotokyo+, lo que tarda el letrero en encenderse,
    // que ya incluye el velo.
    _ramo.duration = _enNeotokyo
        ? duracionEncendidoLetrero(progresoDiaNotifier.value.total)
        : duracionRamoCierre;
    if (_sinMovimiento) {
      _vibro = true;
      HapticFeedback.heavyImpact();
      _velo.value = 1;
      _ramo.value = 1;
      _textos.value = 1;
    } else {
      _velo.forward();
      if (_enDulce || _enNeotokyo) {
        _ramo.forward(from: 0);
      } else {
        _textos.forward(from: 0);
      }
    }
  }

  /// El nombre de la figura del día, en el idioma activo.
  String _nombreFigura(NordayCoreLocalizations l) {
    final total = progresoDiaNotifier.value.total;
    if (_enDulce) return nombreRamo(l, total);
    if (_enNeotokyo) return nombreLetrero(l, total);
    return nombreConstelacion(l, total);
  }

  /// El ramo en el momento que toca: todas las flores a grafito, como se
  /// veía en Hoy; después se colorea y, al final, se ata. Cada paso entra
  /// encima del anterior, así que lo que no cambia no parpadea.
  Widget _ramoEnCurso(double alto) {
    final total = progresoDiaNotifier.value.total;
    final ms = _ramo.value * duracionRamoCierre.inMilliseconds;
    final inicioColor = _esperaRamo.inMilliseconds;
    final inicioAtado = inicioColor + _colorear.inMilliseconds;
    final color = ((ms - inicioColor) / _colorear.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final atado = ((ms - inicioAtado) / _atar.inMilliseconds).clamp(0.0, 1.0);
    Widget ramo({required bool boceto, required bool atado}) =>
        RamoDulce(total: total, alto: alto, atado: atado, boceto: boceto);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (color < 1) ramo(boceto: true, atado: false),
        if (color > 0 && atado < 1)
          Opacity(
            opacity: color < 1 ? Curves.easeInOut.transform(color) : 1,
            child: ramo(boceto: false, atado: false),
          ),
        if (atado > 0)
          Opacity(
            opacity: Curves.easeOut.transform(atado),
            child: ramo(boceto: false, atado: true),
          ),
      ],
    );
  }

  Future<void> _alTocar() async {
    final peticion = _Cierre.peticion.value;
    if (peticion == null || _cerrando || !_textos.isCompleted) return;
    _cerrando = true;
    if (_sinMovimiento) {
      _velo.value = 0;
    } else {
      await _velo.reverse();
    }
    _terminarCierre(peticion);
  }

  @override
  void dispose() {
    _Cierre.peticion.removeListener(_alCambiarPeticion);
    _Cierre.capas--;
    _ramo.dispose();
    if (_Cierre.alTocar == _alTocar) _Cierre.alTocar = null;
    // Si la pantalla se va a media ceremonia, quien espera no se queda
    // colgado. Tras el frame: avisar ahora a los que escuchan, con el árbol
    // desmontándose, no está permitido.
    final peticion = _Cierre.peticion.value;
    if (peticion != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _terminarCierre(peticion),
      );
    }
    _velo.dispose();
    _textos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_velo, _textos, _ramo, _Cierre.peticion]),
      builder: (context, _) {
        final peticion = _Cierre.peticion.value;
        if (peticion == null) return const SizedBox.shrink();
        final l = NordayCoreLocalizations.of(context)!;
        return Semantics(
          container: true,
          liveRegion: true,
          label:
              '${peticion.titulo}\n'
              '${_nombreFigura(l)}\n'
              '${peticion.despedida}',
          onTap: () => _alTocar(),
          onTapHint: l.comunCerrar,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _alTocar,
              child: LayoutBuilder(
                builder: (context, restricciones) =>
                    _pintar(context, peticion, restricciones.biggest),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pintar(BuildContext context, _Peticion peticion, Size size) {
    final id = identidadEquipadaNotifier.value;
    final t = id.tokens;
    final l = NordayCoreLocalizations.of(context)!;
    final cuadro = cuadroConstelacion(size);
    final v = _velo.value;

    double alfa(Interval tramo) => v * tramo.transform(_textos.value);

    final estiloTitulo = GoogleFonts.getFont(
      id.fontDisplay,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: t.text,
    );
    // En Dulce, el nombre del ramo va en su color de texto, sin brillo.
    final estiloNombre = GoogleFonts.getFont(
      id.fontDisplay,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: _enDulce ? t.successText : t.streak,
      shadows: _enDulce
          ? null
          : [Shadow(color: t.streak.withValues(alpha: 0.6), blurRadius: 18)],
    );
    final estiloDespedida = GoogleFonts.getFont(
      id.fontBody,
      fontSize: tamanoLectura(id, 16),
      color: t.textMuted,
    );

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: _colorVelo(v))),
        // En Dulce, el ramo ocupa el cuadro de la figura y entra con el velo.
        if (_enDulce)
          Positioned.fromRect(
            rect: cuadro,
            child: Opacity(
              opacity: v,
              child: Center(child: _ramoEnCurso(cuadro.height)),
            ),
          ),
        // En Neotokyo+, el letrero de todos los tubos, que se enciende. Entra
        // con el velo por el propio pintor, no con una Opacity: dentro de una
        // la luz se sumaría a su capa, no al velo, y al acabar el velo
        // daría un salto de brillo.
        if (_enNeotokyo)
          Positioned.fromRect(
            rect: cuadro,
            child: CustomPaint(
              size: cuadro.size,
              painter: PintorLetreroCeremonia(
                t,
                progresoDiaNotifier.value.total,
                _ramo.value,
                alfa: v,
              ),
            ),
          ),
        // El título y el nombre, por encima del cuadro de la figura.
        Positioned(
          left: 24,
          right: 24,
          bottom: size.height - cuadro.top + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: alfa(_tramoTitulo),
                child: Text(
                  peticion.titulo,
                  textAlign: TextAlign.center,
                  style: estiloTitulo,
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: alfa(_tramoNombre),
                child: Text(
                  _nombreFigura(l),
                  textAlign: TextAlign.center,
                  style: estiloNombre,
                ),
              ),
            ],
          ),
        ),
        // La despedida, por debajo.
        Positioned(
          left: 24,
          right: 24,
          top: cuadro.bottom + 16,
          child: Opacity(
            opacity: alfa(_tramoDespedida),
            child: Text(
              peticion.despedida,
              textAlign: TextAlign.center,
              style: estiloDespedida,
            ),
          ),
        ),
      ],
    );
  }
}

/// Oculta [child] al lector de pantalla mientras dura el cierre del día.
///
/// La app envuelve con él lo que queda debajo del velo: las páginas y la
/// barra de navegación. Sin él, con TalkBack se podría llegar a lo de
/// debajo y cambiar de pestaña a media ceremonia.
class OcultoAlLectorDuranteCierre extends StatelessWidget {
  final Widget child;

  const OcultoAlLectorDuranteCierre({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Peticion?>(
      valueListenable: _Cierre.peticion,
      builder: (context, peticion, child) =>
          ExcludeSemantics(excluding: peticion != null, child: child),
      child: child,
    );
  }
}

/// El mismo velo, para ponerlo encima de la barra de navegación, que va
/// fuera del `Stack` de la pantalla. Oscurece a la vez que la capa, y un
/// toque en él hace lo mismo que en la capa: así durante la ceremonia no se
/// cambia de pestaña.
///
/// La app lo pone encima de la barra, por ejemplo en un `Stack` con la
/// barra debajo y esto en un `Positioned.fill`.
class VeloBarraCierreDelDia extends StatelessWidget {
  const VeloBarraCierreDelDia({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha también la petición: al terminar, el velo ya está a 0 y no
    // avisaría, y sin petición esto no debe quedarse robando toques.
    return ListenableBuilder(
      listenable: Listenable.merge([_Cierre.velo, _Cierre.peticion]),
      builder: (context, _) {
        if (_Cierre.peticion.value == null) return const SizedBox.shrink();
        return ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _Cierre.alTocar?.call(),
            child: ColoredBox(color: _colorVelo(_Cierre.velo.value)),
          ),
        );
      },
    );
  }
}

/// El letrero grande de la ceremonia en Neotokyo+: todos los tubos, que se
/// encienden uno a uno según [encendido] (de 0 a 1 sobre
/// [duracionEncendidoLetrero]), con el zumbido, y entran con el velo
/// ([alfa]). Público para los tests.
class PintorLetreroCeremonia extends CustomPainter {
  final TokensContextuales tokens;
  final int total;
  final double encendido;

  /// Lo que lleva el velo, de 0 a 1: el cristal y la luz entran con él.
  final double alfa;

  const PintorLetreroCeremonia(
    this.tokens,
    this.total,
    this.encendido, {
    this.alfa = 1,
  });

  /// Cuánto brilla el tubo [i], de 0 a 1.
  double luz(int i) => luzTuboEnEncendido(i, total, encendido) * alfa;

  @override
  void paint(Canvas canvas, Size size) {
    final letrero = letreroPara(total);
    if (letrero == null) return;
    // La capa, más grande que el cuadro: si no, el halo de los tubos de los
    // bordes se cortaría en recto.
    canvas.saveLayer(
      (Offset.zero & size).inflate(size.shortestSide * 0.2),
      Paint()..blendMode = BlendMode.plus,
    );
    pintarLetrero(
      canvas,
      Offset.zero & size,
      letrero,
      tokens,
      cristal: (_) => alfa,
      luz: luz,
      zumbido: zumbidoLetrero(total, encendido),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PintorLetreroCeremonia old) =>
      old.total != total ||
      old.encendido != encendido ||
      old.alfa != alfa ||
      old.tokens.primary != tokens.primary ||
      old.tokens.streak != tokens.streak ||
      old.tokens.points != tokens.points;
}
