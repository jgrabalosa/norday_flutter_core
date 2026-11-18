import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/manifiesto_arte.dart';
import 'arte_prendas_service.dart';

/// El manifiesto del arte, uno para toda la app (Nori vestida, N-9; decisión
/// de Quim del 18-nov): la nieve del terrario y las prendas de cada Nori leen
/// este mismo. Empieza en [ManifiestoArte.vacio] (sin nieve ni prendas).
final ValueNotifier<ManifiestoArte> manifiestoArteNotifier = ValueNotifier(
  ManifiestoArte.vacio,
);

/// El servicio con el que se pide. Para los tests.
@visibleForTesting
ArtePrendasService Function() servicioManifiesto = ArtePrendasService.new;

Future<void>? _enMarcha;
bool _pedido = false;

/// Lo pide solo si nunca se ha pedido en este proceso (cada `NoriVestida` con
/// prendas lo llama al montarse). Si hay una petición en marcha, la comparte:
/// diez Nori montadas a la vez hacen una sola.
Future<void> asegurarManifiesto() {
  if (_pedido) return _enMarcha ?? Future.value();
  return recargarManifiesto();
}

/// Lo pide otra vez y pone el resultado en [manifiestoArteNotifier] (la
/// pantalla de Nori, al cargar sus datos). Comparte la petición en marcha:
/// dos llamadas a la vez, una sola petición. `cargarManifiesto` no lanza:
/// sin red, el último bueno o el vacío.
Future<void> recargarManifiesto() {
  final enMarcha = _enMarcha;
  if (enMarcha != null) return enMarcha;
  _pedido = true;
  // `_enMarcha` se pone antes de arrancar: aunque crear el servicio lanzara
  // en síncrono, el `finally` lo limpia después de ponerlo, y la siguiente
  // recarga vuelve a pedir.
  final hecho = Completer<void>();
  _enMarcha = hecho.future;
  () async {
    try {
      manifiestoArteNotifier.value = await servicioManifiesto()
          .cargarManifiesto();
    } catch (_) {
      // cargarManifiesto no lanza; por si acaso, el manifiesto se queda.
    } finally {
      _enMarcha = null;
      hecho.complete();
    }
  }();
  return hecho.future;
}

/// Deja el estado como al arrancar. Para los tests.
@visibleForTesting
void reiniciarManifiestoParaTest() {
  _enMarcha = null;
  _pedido = false;
  servicioManifiesto = ArtePrendasService.new;
  manifiestoArteNotifier.value = ManifiestoArte.vacio;
}
