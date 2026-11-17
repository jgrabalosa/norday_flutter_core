import 'package:flutter/foundation.dart';

/// Los sitios donde Nori lleva una prenda (Nori vestida, N-7).
///
/// Cada sitio es la `categoria` del producto en el backend, que ya deja una
/// sola prenda equipada por categoría. Un sitio nuevo se añade solo aquí.
const List<String> sitiosPrenda = ['Cabeza', 'Cuerpo'];

/// Lo que lleva puesto Nori: sitio → código de producto (`PRENDA_…`). Vacío
/// si no lleva nada. Todas las Nori de la app lo escuchan, así que cambian a
/// la vez al equipar.
final ValueNotifier<Map<String, String>> prendasEquipadasNotifier =
    ValueNotifier(const {});

/// Aplica las prendas puestas. Solo pinta: quién está equipado lo decide el
/// backend, y quien lo cambia es `Equipamiento.equiparPrenda`.
///
/// Se queda solo con los sitios de [sitiosPrenda], publica un mapa que no se
/// puede modificar desde fuera y no avisa si lo puesto no ha cambiado.
void aplicarPrendasEquipadas(Map<String, String> prendas) {
  final nuevas = Map<String, String>.unmodifiable({
    for (final sitio in sitiosPrenda)
      if (prendas[sitio] != null) sitio: prendas[sitio]!,
  });
  if (mapEquals(nuevas, prendasEquipadasNotifier.value)) return;
  prendasEquipadasNotifier.value = nuevas;
}
