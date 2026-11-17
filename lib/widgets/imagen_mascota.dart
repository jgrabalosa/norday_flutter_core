import 'package:flutter/widgets.dart';

/// Lado, en píxeles, de los PNG de Nori (`assets/mascota/`).
const int ladoOriginalMascota = 1024;

/// Una ilustración de Nori descodificada al tamaño al que se pinta
/// (Nori vestida, N-3, 16-nov-2026).
///
/// Sin decirle nada, Flutter descodifica cada PNG entero: 1024 × 1024 en
/// RGBA son 4 MB en memoria por imagen, aunque se pinte a 48 puntos. Con las
/// prendas de Nori vestida habrá varias capas por Nori, y en móviles con poca
/// memoria eso se nota. Aquí se pide la imagen a `tamano × densidad × margen`
/// píxeles, nunca más que el original.
///
/// [margen] es para quien la estira después: `MascotaAnimadaViva` la escala
/// con la respiración y el squish, y sin margen se vería borrosa en el pico.
///
/// Las imágenes son cuadradas: basta con el ancho (`cacheWidth`), y el alto
/// sale de la proporción.
class ImagenMascota extends StatelessWidget {
  /// Ruta dentro de este paquete, como la da `assetMascota`.
  final String asset;

  /// Lado al que se pinta, en puntos.
  final double tamano;

  /// Cuánto mayor que [tamano] puede llegar a pintarse. 1 si no se estira.
  final double margen;

  const ImagenMascota({
    super.key,
    required this.asset,
    required this.tamano,
    this.margen = 1,
  });

  /// Los píxeles a los que se descodifica: el cálculo de arriba, entre 1 y
  /// [ladoOriginalMascota].
  static int anchoDescodificado({
    required double tamano,
    required double densidad,
    double margen = 1,
  }) => (tamano * densidad * margen).ceil().clamp(1, ladoOriginalMascota);

  @override
  Widget build(BuildContext context) {
    final densidad = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return Image.asset(
      asset,
      package: 'norday_flutter_core',
      width: tamano,
      height: tamano,
      cacheWidth: anchoDescodificado(
        tamano: tamano,
        densidad: densidad,
        margen: margen,
      ),
    );
  }
}
