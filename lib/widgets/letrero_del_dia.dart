import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/progreso_dia.dart';
import 'cierre_del_dia.dart';
import 'letreros.dart';

/// El letrero del día de Neotokyo+ (D-35) en su sitio de la lista de Hoy
/// (D-41): un tubo por hábito hecho, que crece ahí durante el día. Antes iba
/// en una capa por encima de toda la pantalla y se formaba detrás de los
/// hábitos.
///
/// Lee el progreso del día ([progresoDiaNotifier]) y si está cerrado
/// ([diaCerradoNotifier]); no sabe qué se cuenta. Ocupa siempre [alto] y
/// pinta el letrero en el cuadrado del centro.
///
/// - **De día:** cada hábito hecho deja su tubo como cristal apagado; al
///   marcar, el tubo entra con un fundido, y al desmarcar se va.
/// - **En la ceremonia del cierre** el letrero grande lo pinta la ceremonia
///   (`mostrarCierreDelDia`); este, debajo del velo, espera apagado (si se
///   encendiera a la vez, se vería doble a través del velo: Quim, 20-nov) y
///   se enciende al irse el velo, todos los tubos a la vez y al ritmo del
///   velo.
/// - **Con el día cerrado sin ceremonia** (abrir la app con el día ya
///   cerrado, volver a hoy en la tira): aparece encendido con un fundido, sin
///   volver a parpadear. Montado con el día ya cerrado, sale encendido de
///   golpe. Si cambia el letrero (otro día u otro número de hábitos), el
///   encendido no se hereda.
/// - **Al reabrir el día** (deshacer el último): se apaga en 400 ms, cada
///   tubo desde la luz que tuviera.
///
/// Sólo se anima un cambio de `completas` del mismo día y con el mismo
/// `total`; al montarse, al cambiar de día o de número de hábitos, el cristal
/// aparece quieto. Pinta con mezcla aditiva, no lleva semántica propia (la
/// pone la app) y no recibe toques.
class LetreroDelDia extends StatefulWidget {
  /// Alto del sitio en la lista.
  final double alto;

  const LetreroDelDia({super.key, required this.alto});

  @override
  State<LetreroDelDia> createState() => _LetreroDelDiaState();
}

class _LetreroDelDiaState extends State<LetreroDelDia>
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

  bool get _encender => diaCerradoNotifier.value;

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
    cambiosCierreDelDia.addListener(_alCambiarCierre);
  }

  /// Si el velo de la ceremonia en curso ya ha llegado arriba: desde ahí,
  /// lo que baje es que se va.
  bool _veloArriba = false;

  void _alCambiarCierre() {
    if (!hayCierreDelDiaEnCurso) {
      _veloArriba = false;
    } else if (veloCierreDelDia >= 1) {
      _veloArriba = true;
    }
    setState(() {});
  }

  /// Cuánto se deja ver la luz, de 0 a 1: en la ceremonia, nada hasta que
  /// el velo empieza a irse, y luego lo que se haya ido.
  double get _luzVisible {
    if (!hayCierreDelDiaEnCurso) return 1;
    if (!_veloArriba) return 0;
    return 1 - veloCierreDelDia;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _actualizarEncendido() {
    if (_encender) {
      if (_sinMovimiento) {
        _uniforme = false;
        _encendido.value = 1;
      } else if (hayCierreDelDiaEnCurso) {
        // La ceremonia: encendido ya, pero sin dar luz hasta que se vaya el
        // velo ([_luzVisible]).
        _empezarUniforme(entrando: true);
        _encendido.value = 1;
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

  PintorLetreroDelDia _pintor() => PintorLetreroDelDia(
    tokens(context),
    _progreso,
    entradas: {for (final e in _entradas.entries) e.key: e.value.value},
    salidas: {for (final e in _salidas.entries) e.key: e.value.value},
    encendido: _encendido.value,
    uniforme: _uniforme,
    techo: _techo,
    escala: _escala,
    luzVisible: _luzVisible,
  );

  @override
  void dispose() {
    progresoDiaNotifier.removeListener(_alCambiarProgreso);
    diaCerradoNotifier.removeListener(_actualizarEncendido);
    cambiosCierreDelDia.removeListener(_alCambiarCierre);
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
        if (!mismoLetrero) _letreroNuevo();
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

  /// Otro letrero (otro día u otro número de hábitos): el encendido no se
  /// hereda. Se apaga de golpe y, si el día sigue cerrado, vuelve con el
  /// fundido. La app publica el progreso antes de reabrir el día, así que
  /// sin esto el letrero del otro día se vería encendido mientras se apaga.
  void _letreroNuevo() {
    _encendido.stop();
    _uniforme = false;
    _encendido.value = 0;
    if (!_encender) return;
    if (_sinMovimiento) {
      _encendido.value = 1;
    } else {
      _empezarUniforme(entrando: true);
      _encendido.animateTo(1, duration: _duracionFundido);
    }
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
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.alto,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _encendido,
            builder: (context, _) =>
                CustomPaint(painter: _pintor(), size: Size.infinite),
          ),
        ),
      ),
    );
  }
}

/// Pinta el letrero en el cuadrado centrado de su caja. Público para los
/// tests: el widget no deja ver otra cosa que lo que pinta.
class PintorLetreroDelDia extends CustomPainter {
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

  /// Cuánto se deja ver la luz, de 0 a 1 (en la ceremonia del cierre, el de
  /// la lista espera debajo del velo).
  final double luzVisible;

  const PintorLetreroDelDia(
    this.tokens,
    this.progreso, {
    required this.entradas,
    required this.salidas,
    required this.encendido,
    this.uniforme = false,
    this.techo = const [],
    this.escala = 1,
    this.luzVisible = 1,
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
    if (encendido <= 0 || luzVisible <= 0) return 0;
    if (uniforme) {
      final t = i < techo.length ? techo[i] : 1.0;
      return escala <= 0
          ? 0
          : (t * encendido / escala * luzVisible).clamp(0.0, 1.0);
    }
    return luzTuboEnEncendido(i, progreso.total, encendido) * luzVisible;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final letrero = letreroPara(progreso.total);
    if (letrero == null) return;
    final lado = size.shortestSide;
    final cuadro = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: lado,
      height: lado,
    );

    // La capa, más grande que el cuadro: si no, el halo de los tubos de los
    // bordes se cortaría en recto.
    canvas.saveLayer(
      cuadro.inflate(lado * 0.2),
      Paint()..blendMode = BlendMode.plus,
    );
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
  bool shouldRepaint(covariant PintorLetreroDelDia old) =>
      old.tokens.primary != tokens.primary ||
      old.tokens.streak != tokens.streak ||
      old.tokens.points != tokens.points ||
      old.progreso != progreso ||
      old.encendido != encendido ||
      old.uniforme != uniforme ||
      old.escala != escala ||
      old.luzVisible != luzVisible ||
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
