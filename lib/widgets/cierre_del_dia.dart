import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/progreso_dia.dart';
import 'capa_constelacion.dart';
import 'constelaciones.dart';

/// El cierre del día: al completar el último hábito, todo se oscurece y
/// aparecen, en este orden, [titulo], el nombre de la constelación del día y
/// [despedida]. Un toque lo cierra, y el Future termina entonces.
///
/// Sólo existe en Profundidad. En las demás identidades, o si no hay figura,
/// termina en el acto sin pintar nada: el día que se diseñe su cierre, se
/// pone aquí. Los textos los pone la app, como el resto de textos que
/// hablan de hábitos.
///
/// Al empezar marca el día como cerrado ([marcarDiaCerrado]), así que al
/// irse el velo queda ya el estado final: la figura realzada.
///
/// Necesita que la app tenga montada una [CapaCierreDelDia]; si no, no
/// espera a nadie y termina en el acto.
Future<void> mostrarCierreDelDia({
  required String titulo,
  required String despedida,
}) {
  if (identidadEquipadaNotifier.value.fondo != FondoIdentidadTipo.cielo) {
    return Future.value();
  }
  if (constelacionPara(progresoDiaNotifier.value.total) == null) {
    return Future.value();
  }
  if (_Cierre.capas == 0) return Future.value();

  final enCurso = _Cierre.peticion.value;
  if (enCurso != null) return enCurso.hecho.future;

  final peticion = _Peticion(titulo, despedida);
  _Cierre.peticion.value = peticion;
  marcarDiaCerrado(true);
  return peticion.hecho.future;
}

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
  bool _sinMovimiento = false;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _velo = AnimationController(vsync: this, duration: _duracionVelo)
      ..addListener(() => _Cierre.velo.value = _velo.value);
    _textos = AnimationController(vsync: this, duration: _duracionTextos);
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

  void _empezar() {
    if (!mounted || _Cierre.peticion.value == null) return;
    _cerrando = false;
    if (_sinMovimiento) {
      _velo.value = 1;
      _textos.value = 1;
    } else {
      _velo.forward();
      _textos.forward(from: 0);
    }
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
    if (_Cierre.alTocar == _alTocar) _Cierre.alTocar = null;
    // Si la pantalla se va a media ceremonia, quien espera no se queda
    // colgado. Tras el frame: avisar ahora a los que escuchan, con el árbol
    // desmontándose, no está permitido.
    final peticion = _Cierre.peticion.value;
    if (peticion != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _terminarCierre(peticion));
    }
    _velo.dispose();
    _textos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_velo, _textos, _Cierre.peticion]),
      builder: (context, _) {
        final peticion = _Cierre.peticion.value;
        if (peticion == null) return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _alTocar,
          child: LayoutBuilder(
            builder: (context, restricciones) =>
                _pintar(context, peticion, restricciones.biggest),
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
    final estiloNombre = GoogleFonts.getFont(
      id.fontDisplay,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: t.streak,
      shadows: [
        Shadow(color: t.streak.withValues(alpha: 0.6), blurRadius: 18),
      ],
    );
    final estiloDespedida = GoogleFonts.getFont(
      id.fontBody,
      fontSize: 16,
      color: t.textMuted,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: _alfaVelo * v),
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
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    peticion.titulo,
                    textAlign: TextAlign.center,
                    style: estiloTitulo,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: alfa(_tramoNombre),
                child: Text(
                  nombreConstelacion(l, progresoDiaNotifier.value.total),
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _Cierre.alTocar?.call(),
          child: ColoredBox(
            color: Colors.black.withValues(
                alpha: _CapaCierreDelDiaState._alfaVelo * _Cierre.velo.value),
          ),
        );
      },
    );
  }
}
