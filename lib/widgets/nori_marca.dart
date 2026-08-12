import 'package:flutter/material.dart';

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
class NoriMarca extends StatelessWidget {
  /// Lado de la ilustración. La caja del widget es algo mayor, para que la luz
  /// tenga por dónde derramarse.
  final double tamano;

  /// Intensidad del halo, tal cual la entiende [HaloIdentidad]. A 1 es el de la
  /// pantalla de mascota; por debajo se apaga sin cambiar el ritmo, que es lo
  /// que identifica a cada identidad.
  final double intensidadHalo;

  const NoriMarca({
    super.key,
    required this.tamano,
    this.intensidadHalo = 1.0,
  });

  /// Misma proporción que la escena de `MascotaScreen`: deja sitio al halo sin
  /// separar a Nori de lo que venga debajo.
  static const double _proporcionCaja = 1.12;

  /// Fase y estado fijos: aquí no hay usuario a quien preguntarle los suyos.
  static const String _fase = 'adulto';
  static const String _estado = 'feliz';

  @override
  Widget build(BuildContext context) {
    final caja = tamano * _proporcionCaja;

    return SizedBox(
      width: caja,
      height: caja,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          HaloIdentidad(tamano: caja, intensidad: intensidadHalo),
          // Sin toque: mientras no haya sesión no lleva a ninguna parte.
          MascotaAnimadaViva(fase: _fase, estado: _estado, tamano: tamano),
        ],
      ),
    );
  }
}
