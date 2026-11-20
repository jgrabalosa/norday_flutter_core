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

  /// El estado de antes mientras dura un fundido; null si no hay fundido.
  _Estado? _previo;

  /// Si el fundido añade (una flor, el color) o quita.
  bool _anade = true;

  late final AnimationController _fundido;
  bool _sinMovimiento = false;

  @override
  void initState() {
    super.initState();
    _progreso = progresoDiaNotifier.value;
    _estado = _leer();
    _fundido = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _previo = null);
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
        _previo = null;
        return;
      }
      _anade =
          ahora.flores > antes.flores ||
          (ahora.flores == antes.flores && ahora.cerrado);
      _previo = antes;
      _fundido.duration = _anade
          ? RamoDelDia.duracionEntrada
          : RamoDelDia.duracionSalida;
      _fundido.forward(from: 0);
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
    final previo = _previo;
    return SizedBox(
      height: widget.alto,
      child: Center(
        child: previo == null
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
                        ? [
                            _ramo(previo),
                            Opacity(opacity: t, child: _ramo(_estado)),
                          ]
                        : [
                            _ramo(_estado),
                            Opacity(opacity: 1 - t, child: _ramo(previo)),
                          ],
                  );
                },
              ),
      ),
    );
  }
}
