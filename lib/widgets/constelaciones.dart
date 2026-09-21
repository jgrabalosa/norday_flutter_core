import 'dart:ui';

import '../l10n/norday_core_localizations.dart';

/// Una constelación del catálogo: sus puntos en coordenadas normalizadas
/// 0..1 y qué puntos une cada trazo.
///
/// Los segmentos van aparte del orden de encendido a propósito. Unir cada
/// punto con el anterior —que es lo que parece natural— funciona en Casiopea
/// y en la Osa Mayor, que son polilíneas, pero destroza la Cruz del Sur y
/// Orión: un cinturón no se une a un pie por el mismo trazo que a un hombro.
class Constelacion {
  /// Los puntos EN ORDEN DE ENCENDIDO. El hábito número N enciende
  /// `puntos[N-1]`.
  final List<Offset> puntos;

  /// Pares de índices de [puntos]. Un trazo se dibuja sólo cuando sus dos
  /// extremos están encendidos.
  final List<(int, int)> segmentos;

  const Constelacion({
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
    puntos: [Offset(0.50, 0.50)],
    segmentos: [],
  ),
  2: Constelacion(
    // Merak y Dubhe, las dos del cazo de la Osa Mayor que señalan a la
    // Polar. Termina en Dubhe, que es la que apunta.
    puntos: [Offset(0.52, 0.86), Offset(0.48, 0.14)],
    segmentos: [(0, 1)],
  ),
  3: Constelacion(
    // Alnitak, Alnilam y Mintaka. Quien hace tres hábitos ve el cinturón;
    // quien hace ocho, a Orión entero.
    puntos: [Offset(0.14, 0.77), Offset(0.51, 0.53), Offset(0.86, 0.23)],
    segmentos: [(0, 1), (1, 2)],
  ),
  4: Constelacion(
    puntos: [
      Offset(0.50, 0.14),
      Offset(0.54, 0.88),
      Offset(0.24, 0.56),
      Offset(0.80, 0.50),
    ],
    segmentos: [(0, 1), (2, 3)],
  ),
  5: Constelacion(
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
    // Vega y sus dos vecinas forman el triángulo; la tercera estrella y las
    // tres de abajo, el paralelogramo.
    // Sustituye a Cefeo, cuya sexta estrella salía como un palo suelto.
    puntos: [
      Offset(0.73, 0.23),
      Offset(0.58, 0.14),
      Offset(0.57, 0.35),
      Offset(0.37, 0.43),
      Offset(0.27, 0.86),
      Offset(0.46, 0.79),
    ],
    segmentos: [(0, 1), (0, 2), (1, 2), (2, 3), (3, 4), (4, 5), (5, 2)],
  ),
  7: Constelacion(
    // Posiciones reales. Empieza por la punta del mango (Alkaid) y termina
    // en Dubhe, que cierra el cazo contra Megrez.
    puntos: [
      Offset(0.14, 0.67),
      Offset(0.29, 0.54),
      Offset(0.41, 0.53),
      Offset(0.57, 0.51),
      Offset(0.66, 0.59),
      Offset(0.86, 0.48),
      Offset(0.81, 0.33),
    ],
    segmentos: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)],
  ),
  8: Constelacion(
    // Meissa (la cabeza), Betelgeuse, Bellatrix, el cinturón y los pies.
    // Posiciones reales salvo el cinturón, que se abre a 0.10 entre
    // estrellas: con las reales quedaban a unos 12 px y los destellos se
    // pisaban.
    puntos: [
      Offset(0.50, 0.14),
      Offset(0.31, 0.23),
      Offset(0.59, 0.27),
      Offset(0.39, 0.59),
      Offset(0.49, 0.55),
      Offset(0.59, 0.51),
      Offset(0.38, 0.86),
      Offset(0.69, 0.81),
    ],
    segmentos: [(0, 1), (0, 2), (1, 3), (2, 5), (3, 4), (4, 5), (3, 6), (5, 7)],
  ),
};

/// La figura que toca para [totalHabitos]. `null` con 0 hábitos.
Constelacion? constelacionPara(int totalHabitos) {
  if (totalHabitos <= 0) return null;
  return catalogoConstelaciones[totalHabitos.clamp(1, 8)];
}

/// El nombre de la figura que toca para [totalHabitos], en el idioma activo.
///
/// Va aparte del catálogo porque el catálogo es `const` y las traducciones
/// dependen del idioma, que cambia sin reiniciar la app. Mismo tope que
/// [constelacionPara]: de 8 en adelante, Orión.
String nombreConstelacion(NordayCoreLocalizations l, int totalHabitos) =>
    switch (totalHabitos.clamp(1, 8)) {
      1 => l.constelacionPolar,
      2 => l.constelacionPunteros,
      3 => l.constelacionCinturon,
      4 => l.constelacionCruzSur,
      5 => l.constelacionCasiopea,
      6 => l.constelacionLira,
      7 => l.constelacionOsaMayor,
      _ => l.constelacionOrion,
    };
