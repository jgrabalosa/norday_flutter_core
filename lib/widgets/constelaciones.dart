import 'dart:ui';

/// Una constelación del catálogo: sus puntos en coordenadas normalizadas
/// 0..1 y qué puntos une cada trazo.
///
/// Los segmentos van aparte del orden de encendido a propósito. Unir cada
/// punto con el anterior —que es lo que parece natural— funciona en Casiopea
/// y en la Osa Mayor, que son polilíneas, pero destroza la Cruz del Sur y
/// Orión: un cinturón no se une a un pie por el mismo trazo que a un hombro.
class Constelacion {
  /// El nombre, para poder contarlo: "hoy estás dibujando Casiopea".
  final String nombre;

  /// Los puntos EN ORDEN DE ENCENDIDO. El hábito número N enciende
  /// `puntos[N-1]`.
  final List<Offset> puntos;

  /// Pares de índices de [puntos]. Un trazo se dibuja sólo cuando sus dos
  /// extremos están encendidos.
  final List<(int, int)> segmentos;

  const Constelacion({
    required this.nombre,
    required this.puntos,
    required this.segmentos,
  });
}

/// Catálogo indexado por número de hábitos del día, de 1 a 8.
///
/// Sin huecos: cada cantidad tiene su figura entera, así que no hace falta
/// ninguna regla de "coger la siguiente y recortarla". Con 0 hábitos no se
/// dibuja nada y con más de 8 se usa Orión, que es el tope: la estrella
/// número 9 y siguientes no existen. Es deliberado — quien hace ocho hábitos
/// en un día ya se ha ganado el cielo entero.
const Map<int, Constelacion> catalogoConstelaciones = {
  1: Constelacion(
    // La Polar y el compás del logo dicen lo mismo: lo que orienta. Es la
    // figura del que empieza, y es la que más gente va a ver el primer día.
    nombre: 'Polar',
    puntos: [Offset(0.50, 0.50)],
    segmentos: [],
  ),
  2: Constelacion(
    nombre: 'Can Menor',
    puntos: [Offset(0.28, 0.66), Offset(0.74, 0.34)],
    segmentos: [(0, 1)],
  ),
  3: Constelacion(
    nombre: 'Triángulo',
    puntos: [Offset(0.24, 0.72), Offset(0.76, 0.66), Offset(0.50, 0.22)],
    segmentos: [(0, 1), (1, 2), (2, 0)],
  ),
  4: Constelacion(
    nombre: 'Cruz del Sur',
    puntos: [
      Offset(0.50, 0.14),
      Offset(0.54, 0.88),
      Offset(0.24, 0.56),
      Offset(0.80, 0.50),
    ],
    segmentos: [(0, 1), (2, 3)],
  ),
  5: Constelacion(
    nombre: 'Casiopea',
    puntos: [
      Offset(0.14, 0.40),
      Offset(0.32, 0.66),
      Offset(0.50, 0.38),
      Offset(0.68, 0.68),
      Offset(0.86, 0.34),
    ],
    segmentos: [(0, 1), (1, 2), (2, 3), (3, 4)],
  ),
  6: Constelacion(
    // La casa. Es la figura más floja del catálogo: la silueta clásica se
    // dibuja con cinco vértices y aquí hay que estirarla a seis. Si en
    // pantalla no se reconoce, el recambio natural para 6 es el pentágono
    // de Auriga.
    nombre: 'Cefeo',
    puntos: [
      Offset(0.28, 0.78),
      Offset(0.68, 0.78),
      Offset(0.70, 0.48),
      Offset(0.49, 0.22),
      Offset(0.28, 0.48),
      Offset(0.88, 0.62),
    ],
    segmentos: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)],
  ),
  7: Constelacion(
    nombre: 'Osa Mayor',
    puntos: [
      Offset(0.18, 0.62),
      Offset(0.34, 0.74),
      Offset(0.42, 0.54),
      Offset(0.26, 0.42),
      Offset(0.58, 0.46),
      Offset(0.74, 0.38),
      Offset(0.88, 0.26),
    ],
    segmentos: [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 6)],
  ),
  8: Constelacion(
    nombre: 'Orión',
    puntos: [
      Offset(0.30, 0.20),
      Offset(0.70, 0.22),
      Offset(0.40, 0.50),
      Offset(0.50, 0.52),
      Offset(0.60, 0.54),
      Offset(0.34, 0.86),
      Offset(0.72, 0.84),
      Offset(0.50, 0.68),
    ],
    segmentos: [(0, 2), (1, 4), (2, 3), (3, 4), (2, 5), (4, 6), (3, 7)],
  ),
};

/// La figura que toca para [totalHabitos]. `null` con 0 hábitos.
Constelacion? constelacionPara(int totalHabitos) {
  if (totalHabitos <= 0) return null;
  return catalogoConstelaciones[totalHabitos.clamp(1, 8)];
}
