import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/manifiesto_arte.dart';
import '../services/manifiesto_compartido.dart';
import 'halo_identidad.dart';
import 'mascota_animada_viva.dart';

/// Nori como presencia de marca: respirando, con la luz de la identidad
/// equipada detrás.
///
/// La misma pieza en el splash y en la cabecera del login, en dos tamaños. En
/// esas dos pantallas todavía no hay sesión —y por tanto no hay fase ni estado
/// que consultar—, así que no es la mascota de nadie: se pinta siempre adulta y
/// contenta, que es la cara con la que se recibe a alguien. La mascota real,
/// con su fase y su ánimo, es cosa de `MascotaScreen` y `MiniMascota`, que sí
/// tienen a quién preguntárselo.
///
/// El halo desborda su caja a propósito (lo hace [HaloIdentidad]), y por eso el
/// `Stack` no clipa.
class NoriMarca extends StatefulWidget {
  /// Lado de la ilustración. La caja del widget es algo mayor, para que la luz
  /// tenga por dónde derramarse.
  final double tamano;

  /// Intensidad del halo, tal cual la entiende [HaloIdentidad]. A 1 es el de la
  /// pantalla de mascota; por debajo se apaga sin cambiar el ritmo, que es lo
  /// que identifica a cada identidad.
  final double intensidadHalo;

  /// Si lleva la prenda de la temporada (T-036): la que dice el apartado
  /// `login` del manifiesto del arte para hoy, la misma para todos. **Nunca**
  /// lo equipado de nadie (`prendasEquipadasNotifier`): aquí no hay sesión y
  /// puede haber otra cuenta. Sin manifiesto, sin periodo para hoy o sin el
  /// fichero bajado, el dibujo de siempre. Solo lo pide `LoginScreen`; el
  /// splash no se viste.
  final bool vestida;

  /// Para los tests: el día de hoy, el manifiesto y de dónde sale el fichero
  /// de una imagen (por defecto, el reloj, [manifiestoArteNotifier] y
  /// `ArtePrendasService().imagen`).
  final DateTime Function()? ahora;
  final ValueListenable<ManifiestoArte>? manifiesto;
  final Future<File?> Function(String ruta)? imagen;

  const NoriMarca({
    super.key,
    required this.tamano,
    this.intensidadHalo = 1.0,
    this.vestida = false,
    this.ahora,
    this.manifiesto,
    this.imagen,
  });

  @override
  State<NoriMarca> createState() => _NoriMarcaState();
}

class _NoriMarcaState extends State<NoriMarca> {
  /// Misma proporción que la escena de `MascotaScreen`: deja sitio al halo sin
  /// separar a Nori de lo que venga debajo.
  static const double _proporcionCaja = 1.12;

  /// Fase y estado fijos: aquí no hay usuario a quien preguntarle los suyos.
  static const String _fase = 'huevo';
  static const String _estado = 'feliz';

  /// Lo que lleva hoy, derivado del manifiesto: se recalcula cuando llega uno
  /// nuevo. Solo existe con `vestida`.
  ValueNotifier<Map<String, String>>? _prendas;
  ValueListenable<ManifiestoArte>? _escuchado;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  @override
  void didUpdateWidget(covariant NoriMarca anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.vestida != widget.vestida ||
        !identical(anterior.manifiesto, widget.manifiesto)) {
      _soltar();
      _preparar();
    }
  }

  @override
  void dispose() {
    _soltar();
    super.dispose();
  }

  void _preparar() {
    if (!widget.vestida) return;
    final fuente = widget.manifiesto ?? manifiestoArteNotifier;
    _escuchado = fuente..addListener(_recalcular);
    _prendas = ValueNotifier(_calcular());
  }

  void _soltar() {
    _escuchado?.removeListener(_recalcular);
    _escuchado = null;
    _prendas?.dispose();
    _prendas = null;
  }

  Map<String, String> _calcular() =>
      _escuchado!.value.prendasLogin(widget.ahora?.call() ?? DateTime.now());

  void _recalcular() {
    final nuevas = _calcular();
    final actuales = _prendas!;
    if (!mapEquals(nuevas, actuales.value)) actuales.value = nuevas;
  }

  @override
  Widget build(BuildContext context) {
    final tamano = widget.tamano;
    final caja = tamano * _proporcionCaja;

    return SizedBox(
      width: caja,
      height: caja,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          HaloIdentidad(tamano: caja, intensidad: widget.intensidadHalo),
          // Sin toque: mientras no haya sesión no lleva a ninguna parte.
          MascotaAnimadaViva(
            fase: _fase,
            estado: _estado,
            tamano: tamano,
            vestida: widget.vestida,
            prendas: _prendas,
            manifiesto: widget.manifiesto,
            imagen: widget.imagen,
          ),
        ],
      ),
    );
  }
}
