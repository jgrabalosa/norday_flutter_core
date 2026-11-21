import 'package:flutter/material.dart';

import '../theme/progreso_dia.dart';
import 'cierre_del_dia.dart';
import 'ramo_dulce.dart';

/// El ramo del día de Dulce en su sitio de la lista de Hoy (D-41): una flor
/// por hábito hecho, a grafito mientras el día está abierto; con el día
/// cerrado, en color y atado.
///
/// Lee el progreso del día ([progresoDiaNotifier]) y si está cerrado
/// ([diaCerradoNotifier]); no sabe qué se cuenta. Ocupa siempre [alto], haya
/// flores o no, para que la lista no salte. Sin hábitos no pinta nada.
///
/// - **Al marcar**, la flor nueva entra con un fundido de 600 ms; **al
///   desmarcar**, se va en 400 ms.
/// - **Al cerrar el día** sin ceremonia (abrir la app con el día ya cerrado),
///   se colorea y se ata con un fundido. **Con la ceremonia en curso**
///   ([hayCierreDelDiaEnCurso]) cambia de golpe: la ceremonia lo tapa y es
///   ella la que lo colorea y lo ata en grande.
/// - Sólo se anima un cambio del mismo día y con el mismo número de hábitos;
///   al montarse, al cambiar de día o de número de hábitos, aparece quieto.
/// - Con «reducir movimiento», todo de golpe.
///
/// No lleva semántica propia: lo que se lee lo pone la app, que sabe que son
/// hábitos.
class RamoDelDia extends StatefulWidget {
  /// Alto del sitio en la lista.
  final double alto;

  const RamoDelDia({super.key, required this.alto});

  /// Lo que dura la entrada de una flor, o el coloreado sin ceremonia.
  static const Duration duracionEntrada = Duration(milliseconds: 600);

  /// Lo que tarda en irse una flor al desmarcar.
  static const Duration duracionSalida = Duration(milliseconds: 400);

  @override
  State<RamoDelDia> createState() => _RamoDelDiaState();
}

/// Lo que se pinta: cuántas flores y si está cerrado (en color y atado).
typedef _Estado = ({int flores, bool cerrado});

class _RamoDelDiaState extends State<RamoDelDia>
    with SingleTickerProviderStateMixin {
  late ProgresoDia _progreso;
  late _Estado _estado;

  /// El fundido en curso, de [_de] a [_a]; [_de] es null si no hay fundido.
  /// Va aparte de [_estado] porque un fundido puede seguir hacia un estado
  /// nuevo o volver atrás sin empezar de cero.
  _Estado? _de;
  late _Estado _a;

  /// Si el fundido añade (una flor, el color) o quita.
  bool _anade = true;

  late final AnimationController _fundido;
  bool _sinMovimiento = false;

  @override
  void initState() {
    super.initState();
    _progreso = progresoDiaNotifier.value;
    _estado = _leer();
    _a = _estado;
    _fundido = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          setState(() => _de = null);
        }
      });
    progresoDiaNotifier.addListener(_alCambiar);
    diaCerradoNotifier.addListener(_alCambiar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    progresoDiaNotifier.removeListener(_alCambiar);
    diaCerradoNotifier.removeListener(_alCambiar);
    _fundido.dispose();
    super.dispose();
  }

  _Estado _leer() {
    final p = progresoDiaNotifier.value;
    return (
      flores: p.completas.clamp(0, p.total < 0 ? 0 : p.total),
      cerrado: diaCerradoNotifier.value,
    );
  }

  void _alCambiar() {
    final anterior = _progreso;
    final nuevo = progresoDiaNotifier.value;
    final antes = _estado;
    final ahora = _leer();
    final mismoRamo =
        anterior.fecha != null &&
        anterior.fecha == nuevo.fecha &&
        anterior.total == nuevo.total;
    // Lo hecho a medias (minutos) cambia el progreso sin cambiar las flores:
    // no corta el fundido que esté en marcha.
    if (antes == ahora && mismoRamo) {
      if (anterior != nuevo) _progreso = nuevo;
      return;
    }
    final animar =
        mismoRamo &&
        !_sinMovimiento &&
        antes != ahora &&
        !(ahora.cerrado && hayCierreDelDiaEnCurso);
    setState(() {
      _progreso = nuevo;
      _estado = ahora;
      if (!animar) {
        _fundido.stop();
        _de = null;
        _a = ahora;
        return;
      }
      final anade =
          ahora.flores > antes.flores ||
          (ahora.flores == antes.flores && ahora.cerrado);
      final enCurso = _de != null && _fundido.isAnimating;
      // Marcar y desmarcar enseguida: se deshace desde donde iba.
      if (enCurso && ahora == _de) {
        _fundido.reverse();
        return;
      }
      // Otro paso en la misma dirección (deshacer el último con el día
      // cerrado: primero se va la flor y luego el color): sigue desde donde
      // iba hacia el estado nuevo, y lo de antes se va junto.
      if (enCurso && anade == _anade) {
        _a = ahora;
        return;
      }
      _anade = anade;
      _fundido.duration = _anade
          ? RamoDelDia.duracionEntrada
          : RamoDelDia.duracionSalida;
      // forward(from: 0) avisa «dismissed» al ponerse a 0 y el oyente borra
      // _de: por eso _de y _a van después.
      _fundido.forward(from: 0);
      _de = antes;
      _a = ahora;
    });
  }

  Widget _ramo(_Estado e) => RamoDulce(
    total: _progreso.total,
    alto: widget.alto,
    flores: e.flores,
    atado: e.cerrado,
    boceto: !e.cerrado,
  );

  @override
  Widget build(BuildContext context) {
    if (_progreso.total <= 0) return SizedBox(height: widget.alto);
    final de = _de;
    return SizedBox(
      height: widget.alto,
      child: Center(
        child: de == null
            ? _ramo(_estado)
            : AnimatedBuilder(
                animation: _fundido,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(_fundido.value);
                  // Lo que se añade va encima del ramo de antes, apareciendo;
                  // lo que se quita, encima del de ahora, desapareciendo. Así
                  // lo que no cambia no parpadea.
                  return Stack(
                    alignment: Alignment.center,
                    children: _anade
                        ? [_ramo(de), Opacity(opacity: t, child: _ramo(_a))]
                        : [
                            _ramo(_a),
                            Opacity(opacity: 1 - t, child: _ramo(de)),
                          ],
                  );
                },
              ),
      ),
    );
  }
}
