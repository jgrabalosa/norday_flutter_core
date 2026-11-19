import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/progreso_dia.dart';
import 'capa_constelacion.dart';
import 'cierre_del_dia.dart';
import 'letreros.dart';

/// El letrero del día de Neotokyo+ (D-35), en su propia capa por ENCIMA del
/// contenido, como la constelación de Profundidad.
///
/// NO se exporta en el barrel. La puerta es `CapaProgresoIdentidad`.
///
/// - **De día:** cada hábito hecho deja su tubo como cristal apagado; al
///   marcar, el tubo entra con un fundido, y al desmarcar se va.
/// - **En la ceremonia del cierre** (`mostrarCierreDelDia`, que va por debajo
///   de esta capa): los tubos se encienden uno a uno con el parpadeo del neón
///   y el letrero entero zumba; la ceremonia espera a
///   [duracionEncendidoLetrero] para sacar los textos. Después se queda
///   encendido, en Hoy.
/// - **Con el día cerrado sin ceremonia** (abrir la app con el día ya
///   cerrado, volver a hoy en la tira, cambiar de pestaña): el letrero
///   aparece encendido con un fundido, sin volver a parpadear, como el realce
///   de la constelación. Montada con el día ya cerrado, sale encendido.
/// - **Al reabrir el día** (deshacer el último): se apaga en 400 ms, cada
///   tubo desde la luz que tuviera.
///
/// Mismas reglas que la constelación: sólo se anima un cambio de `completas`
/// del mismo día y con el mismo `total`; al montarse, al cambiar de día o de
/// número de hábitos, el cristal aparece quieto. Pinta con mezcla aditiva y
/// lleva [IgnorePointer].
class CapaLetrero extends StatefulWidget {
  /// Los colores de la identidad: la tríada de neón sale de aquí.
  final TokensContextuales tokens;

  /// Si la capa está encima de Hoy. El letrero encendido sólo se pinta ahí.
  final bool enHoy;

  const CapaLetrero({super.key, required this.tokens, this.enHoy = false});

  @override
  State<CapaLetrero> createState() => _CapaLetreroState();
}

class _CapaLetreroState extends State<CapaLetrero>
    with TickerProviderStateMixin {
  static const _duracionEntrada = Duration(milliseconds: 600);
  static const _duracionSalida = Duration(milliseconds: 400);
  static const _duracionApagar = Duration(milliseconds: 400);
  static const _duracionFundido = Duration(milliseconds: 600);

  late ProgresoDia _progreso;
  bool _sinMovimiento = false;

  /// Tubos que están entrando y saliendo, por índice. A 1.0, el de entrada
  /// ya está puesto y el de salida ya no se ve.
  final Map<int, AnimationController> _entradas = {};
  final Map<int, AnimationController> _salidas = {};

  /// El encendido, de 0 a 1 sobre [duracionEncendidoLetrero].
  late final AnimationController _encendido;

  /// Si el encendido va por igual en todos los tubos (un fundido de
  /// entrada o un apagado) en vez de tubo a tubo. Entonces la luz del tubo
  /// `i` es `_techo[i] * encendido / _escala`.
  bool _uniforme = false;

  /// La luz de cada tubo al empezar el fundido: 1 al entrar; al apagar, la
  /// que tuviera (a media ignición, los que aún no habían arrancado siguen a
  /// 0 y no aparecen de golpe).
  List<double> _techo = const [];

  /// El valor del encendido al empezar a apagar (al entrar, 1).
  double _escala = 1;

  bool get _encender => widget.enHoy && diaCerradoNotifier.value;

  @override
  void initState() {
    super.initState();
    _progreso = progresoDiaNotifier.value;
    progresoDiaNotifier.addListener(_alCambiarProgreso);
    _encendido = AnimationController(
      vsync: this,
      duration: duracionEncendidoLetrero(_progreso.total),
      value: _encender ? 1.0 : 0.0,
    );
    diaCerradoNotifier.addListener(_actualizarEncendido);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(covariant CapaLetrero oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cambiar de pestaña no es cerrar el día: el letrero aparece o se va
    // sin volver a parpadear.
    if (oldWidget.enHoy != widget.enHoy) {
      _uniforme = false;
      _encendido.value = _encender ? 1 : 0;
    }
  }

  void _actualizarEncendido() {
    if (_encender) {
      if (_sinMovimiento) {
        _uniforme = false;
        _encendido.value = 1;
      } else if (hayCierreDelDiaEnCurso) {
        // La ceremonia: tubo a tubo, con su parpadeo y el zumbido.
        _uniforme = false;
        _encendido.duration = duracionEncendidoLetrero(_progreso.total);
        _encendido.forward(from: 0);
      } else {
        // El día ya estaba cerrado: un fundido, todos a la vez.
        _empezarUniforme(entrando: true);
        _encendido.animateTo(1, duration: _duracionFundido);
      }
    } else if (_sinMovimiento) {
      _encendido.value = 0;
    } else {
      _empezarUniforme(entrando: false);
      _encendido.animateBack(0, duration: _duracionApagar);
    }
  }

  void _empezarUniforme({required bool entrando}) {
    final n = letreroPara(_progreso.total)?.tubos.length ?? 0;
    final actual = _pintor();
    _techo = [for (var i = 0; i < n; i++) entrando ? 1.0 : actual.luz(i)];
    _escala = entrando ? 1 : _encendido.value;
    _uniforme = true;
  }

  PintorCapaLetrero _pintor() => PintorCapaLetrero(
    widget.tokens,
    _progreso,
    entradas: {for (final e in _entradas.entries) e.key: e.value.value},
    salidas: {for (final e in _salidas.entries) e.key: e.value.value},
    encendido: _encendido.value,
    uniforme: _uniforme,
    techo: _techo,
    escala: _escala,
  );

  @override
  void dispose() {
    progresoDiaNotifier.removeListener(_alCambiarProgreso);
    diaCerradoNotifier.removeListener(_actualizarEncendido);
    _cancelarTodo();
    _encendido.dispose();
    super.dispose();
  }

  void _cancelarTodo() {
    for (final c in [..._entradas.values, ..._salidas.values]) {
      c.dispose();
    }
    _entradas.clear();
    _salidas.clear();
  }

  void _alCambiarProgreso() {
    final anterior = _progreso;
    final nuevo = progresoDiaNotifier.value;
    final mismoLetrero =
        anterior.fecha != null &&
        anterior.fecha == nuevo.fecha &&
        anterior.total == nuevo.total;
    setState(() {
      _progreso = nuevo;
      if (!mismoLetrero || _sinMovimiento) {
        _cancelarTodo();
        return;
      }
      for (var i = anterior.completas; i < nuevo.completas; i++) {
        _salidas.remove(i)?.dispose();
        _lanzar(_entradas, i, _duracionEntrada);
      }
      for (var i = nuevo.completas; i < anterior.completas; i++) {
        _entradas.remove(i)?.dispose();
        _lanzar(_salidas, i, _duracionSalida);
      }
    });
  }

  void _lanzar(Map<int, AnimationController> mapa, int i, Duration duracion) {
    mapa.remove(i)?.dispose();
    final c = AnimationController(vsync: this, duration: duracion)
      ..addListener(() => setState(() {}));
    mapa[i] = c;
    c.forward();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _encendido,
        builder: (context, _) =>
            CustomPaint(painter: _pintor(), size: Size.infinite),
      ),
    );
  }
}

/// Pinta la capa del letrero. Público para los tests: la capa no deja ver
/// otra cosa que lo que pinta.
class PintorCapaLetrero extends CustomPainter {
  final TokensContextuales tokens;
  final ProgresoDia progreso;

  /// Avance de 0 a 1 de los tubos que entran y de los que salen.
  final Map<int, double> entradas;
  final Map<int, double> salidas;

  /// El encendido del día cerrado, de 0 a 1.
  final double encendido;

  /// Si el encendido va por igual en todos los tubos: la luz del tubo `i`
  /// es `techo[i] * encendido / escala`. Si no, tubo a tubo
  /// ([luzTuboEnEncendido]).
  final bool uniforme;
  final List<double> techo;
  final double escala;

  const PintorCapaLetrero(
    this.tokens,
    this.progreso, {
    required this.entradas,
    required this.salidas,
    required this.encendido,
    this.uniforme = false,
    this.techo = const [],
    this.escala = 1,
  });

  /// Cuánto se ve el cristal del tubo [i], de 0 a 1.
  double cristal(int i) {
    final hechos = progreso.completas;
    if (i < hechos) {
      final e = entradas[i];
      return e == null ? 1 : Curves.easeOut.transform(e);
    }
    final s = salidas[i];
    return s == null ? 0 : 1 - Curves.easeOut.transform(s);
  }

  /// Cuánto brilla el tubo [i], de 0 a 1.
  double luz(int i) {
    if (encendido <= 0) return 0;
    if (uniforme) {
      final t = i < techo.length ? techo[i] : 1.0;
      return escala <= 0 ? 0 : (t * encendido / escala).clamp(0.0, 1.0);
    }
    return luzTuboEnEncendido(i, progreso.total, encendido);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final letrero = letreroPara(progreso.total);
    if (letrero == null) return;
    final cuadro = cuadroConstelacion(size);

    // Igual que en Profundidad: con el día cerrado, lo de debajo se apaga un
    // poco para que el letrero destaque. Fuera de la capa aditiva, que solo
    // sabe sumar luz.
    if (encendido > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.25 * encendido),
      );
    }
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.plus);
    pintarLetrero(
      canvas,
      cuadro,
      letrero,
      tokens,
      cristal: cristal,
      luz: luz,
      zumbido: uniforme ? 1 : zumbidoLetrero(progreso.total, encendido),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PintorCapaLetrero old) =>
      old.tokens.primary != tokens.primary ||
      old.tokens.streak != tokens.streak ||
      old.tokens.points != tokens.points ||
      old.progreso != progreso ||
      old.encendido != encendido ||
      old.uniforme != uniforme ||
      old.escala != escala ||
      !listEquals(old.techo, techo) ||
      !_iguales(old.entradas, entradas) ||
      !_iguales(old.salidas, salidas);

  static bool _iguales(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
