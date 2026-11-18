import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service_core.dart';
import 'avatares.dart';
import 'identidades_paleta.dart';
import 'prendas.dart';

/// Qué lleva puesto el usuario — tema, avatar y las prendas de Nori — contra
/// el backend.
///
/// La fuente de verdad es el inventario del servidor, no el dispositivo: el
/// usuario puede equipar desde otro móvil y al volver a este tiene que verlo.
/// Las únicas copias locales son la última identidad y las últimas prendas que
/// el backend confirmó, por usuario, para no quedarse en Profundidad ni con
/// Nori sin vestir si la red falla al arrancar.
///
/// El puente entre el catálogo local (`catalogoIdentidades`, `catalogoAvatares`,
/// que van por código: 'TEMA_PROFUNDIDAD', 'AVATAR_ZORRO') y el backend (que va
/// por `productoId`) es el campo `codigo` del producto. Ningún identificador
/// de la BD está cableado en el cliente.
class Equipamiento {
  const Equipamiento._();

  /// Seam de test: de dónde sale el inventario. En producción, el backend.
  @visibleForTesting
  static Future<List<dynamic>> Function(int) obtenerInventario =
      ApiServiceCore.getInventarioProductos;

  /// Seam de test: espera antes de cada reintento tras un fallo de red.
  @visibleForTesting
  static Duration esperaReintento = const Duration(seconds: 15);

  /// Seam de test: equipar en el backend (temas, avatares y prendas). En
  /// producción, `equiparProducto`.
  @visibleForTesting
  static Future<List<String>> Function(int, int) equiparEnBackend =
      ApiServiceCore.equiparProducto;

  /// Seam de test: desequipar en el backend. En producción, `desequiparProducto`.
  @visibleForTesting
  static Future<void> Function(int, int) desequiparEnBackend =
      ApiServiceCore.desequiparProducto;

  @visibleForTesting
  static void reiniciarParaTest() {
    _reintento?.cancel();
    _reintento = null;
    obtenerInventario = ApiServiceCore.getInventarioProductos;
    esperaReintento = const Duration(seconds: 15);
    equiparEnBackend = ApiServiceCore.equiparProducto;
    desequiparEnBackend = ApiServiceCore.desequiparProducto;
  }

  static const int _maxReintentos = 3;
  static Timer? _reintento;
  static String _clave(int usuarioId) => 'identidad_equipada_$usuarioId';
  static String _clavePrendas(int usuarioId) => 'prendas_equipadas_$usuarioId';

  /// Llamar cuando hay sesión: tras el login y tras el splash con sesión ya
  /// guardada. No se puede llamar antes —en `main()` no hay ni usuarioId ni
  /// token—, así que hasta que responda se ve el tema por defecto.
  ///
  /// Una sola petición para los dos: son el mismo inventario.
  static Future<void> cargarDeUsuario(int usuarioId) async {
    final inventario = await obtenerInventario(usuarioId);
    await _aplicarYGuardar(usuarioId, inventario);
  }

  /// Igual que [cargarDeUsuario] pero sin propagar el fallo: al arrancar, no
  /// poder leer el inventario no es motivo para dejar al usuario fuera. Ante
  /// un fallo se aplica la última identidad que el backend confirmó en este
  /// dispositivo y se reintenta en segundo plano hasta 3 veces. El backend
  /// sigue mandando: cualquier respuesta suya sustituye a esa copia.
  ///
  /// Devuelve si el usuario POSEE alguna identidad, que es lo que decide si
  /// hay que enseñarle el onboarding de elección: `true` posee, `false` no
  /// posee, `null` no se pudo averiguar (falló el inventario). Quien llame
  /// debe tratar `null` como "no bloquear": un corte de red al arrancar no
  /// puede encerrar a nadie en el onboarding, y la red de seguridad del
  /// backend ya cubre el caso persistente.
  ///
  /// Se mira la POSESIÓN y no lo equipado a propósito: son lo mismo hoy
  /// (otorgar equipa), pero la pregunta real es si tiene identidad.
  static Future<bool?> cargarDeUsuarioSiSePuede(int usuarioId) async {
    _reintento?.cancel();
    _reintento = null;
    try {
      final inventario = await obtenerInventario(usuarioId);
      await _aplicarYGuardar(usuarioId, inventario);
      return _poseeIdentidad(inventario);
    } catch (_) {
      // El aspecto nunca debe romper el arranque.
      await _aplicarCopiaLocal(usuarioId);
      _programarReintento(usuarioId, 1);
      return null;
    }
  }

  /// Equipa un tema: lo dice el backend y, si acepta, se pinta y se guarda
  /// como copia local.
  ///
  /// Devuelve los logros que el backend haya otorgado por equiparlo.
  static Future<List<String>> equiparTema(
    int usuarioId,
    int productoId,
    String? codigo,
  ) async {
    final logros = await equiparEnBackend(usuarioId, productoId);
    aplicarIdentidadEquipada(codigo);
    await _guardarCopia(usuarioId, codigo);
    return logros;
  }

  /// Equipa un avatar: lo dice el backend y, si acepta, se pinta.
  static Future<void> equiparAvatar(
    int usuarioId,
    int productoId,
    String? codigo,
  ) async {
    // Un avatar nunca otorga logro: se descarta la lista a propósito.
    await equiparEnBackend(usuarioId, productoId);
    aplicarAvatarEquipado(codigo);
  }

  /// Quita el avatar y vuelve al círculo con la inicial del nombre.
  static Future<void> desequiparAvatar(int usuarioId, int productoId) async {
    await desequiparEnBackend(usuarioId, productoId);
    aplicarAvatarEquipado(null);
  }

  /// Pone una prenda en su sitio (Nori vestida, N-7): lo dice el backend y,
  /// si acepta, se pinta y se guarda como copia local. Otra prenda en el mismo
  /// sitio la sustituye, como hace el backend (una equipada por categoría).
  ///
  /// Si el backend falla, el error sube y no cambia nada. Un [sitio] que no
  /// está en [sitiosPrenda] se rechaza sin llamar al backend.
  ///
  /// Devuelve los logros que el backend haya otorgado por equiparla.
  static Future<List<String>> equiparPrenda(
    int usuarioId,
    int productoId,
    String codigo,
    String sitio,
  ) async {
    _comprobarSitio(sitio);
    final logros = await equiparEnBackend(usuarioId, productoId);
    final prendas = {...prendasEquipadasNotifier.value, sitio: codigo};
    aplicarPrendasEquipadas(prendas);
    await _guardarPrendas(usuarioId, prendas);
    return logros;
  }

  /// Quita la prenda de un sitio (Nori vestida, N-7): lo dice el backend y,
  /// si acepta, se deja de pintar y se guarda la copia local.
  static Future<void> desequiparPrenda(
    int usuarioId,
    int productoId,
    String sitio,
  ) async {
    _comprobarSitio(sitio);
    await desequiparEnBackend(usuarioId, productoId);
    final prendas = {...prendasEquipadasNotifier.value}..remove(sitio);
    aplicarPrendasEquipadas(prendas);
    await _guardarPrendas(usuarioId, prendas);
  }

  static void _comprobarSitio(String sitio) {
    if (!sitiosPrenda.contains(sitio)) {
      throw ArgumentError.value(sitio, 'sitio', 'no es un sitio de prenda');
    }
  }

  /// Aplica lo que el backend dice del inventario y guarda la identidad como
  /// copia local. Aplicar va primero: el guardado no puede retrasar el pintado.
  static Future<void> _aplicarYGuardar(
    int usuarioId,
    List<dynamic> inventario,
  ) async {
    final equipados = _codigosEquipados(inventario);
    aplicarIdentidadEquipada(
      equipados.where(catalogoIdentidades.containsKey).firstOrNull,
    );
    aplicarAvatarEquipado(
      equipados.where(catalogoAvatares.containsKey).firstOrNull,
    );
    final prendas = _prendasEquipadas(inventario);
    aplicarPrendasEquipadas(prendas);
    await _guardarCopia(
      usuarioId,
      equipados.where(catalogoIdentidades.containsKey).firstOrNull,
    );
    await _guardarPrendas(usuarioId, prendas);
  }

  /// Guarda las prendas puestas como copia local, o la quita si no hay. Igual
  /// que con la identidad, un fallo de prefs nunca rompe nada.
  static Future<void> _guardarPrendas(
    int usuarioId,
    Map<String, String> prendas,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prendas.isEmpty) {
        await prefs.remove(_clavePrendas(usuarioId));
      } else {
        await prefs.setString(_clavePrendas(usuarioId), jsonEncode(prendas));
      }
    } catch (_) {
      // Sin copia local, sin red Nori sale sin prendas hasta que vuelva.
    }
  }

  /// Aplica la copia local de las prendas del usuario. A diferencia de la
  /// identidad, sin copia (o con una corrupta) Nori se queda sin prendas: lo
  /// que hubiera puesto podría ser de otra cuenta del mismo móvil.
  static Future<void> _aplicarCopiaPrendas(int usuarioId) async {
    var prendas = const <String, String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clavePrendas(usuarioId));
      final copia = texto == null ? null : jsonDecode(texto);
      if (copia is Map) {
        prendas = {
          for (final sitio in sitiosPrenda)
            if (copia[sitio] is String) sitio: copia[sitio] as String,
        };
      }
    } catch (_) {
      // Copia ilegible: se trata como si no hubiera.
    }
    aplicarPrendasEquipadas(prendas);
  }

  /// Guarda el código de identidad equipada o quita la copia si no hay. Un
  /// fallo de prefs nunca rompe la carga: sólo se pierde la copia.
  static Future<void> _guardarCopia(int usuarioId, String? codigo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (codigo != null && catalogoIdentidades.containsKey(codigo)) {
        await prefs.setString(_clave(usuarioId), codigo);
      } else {
        await prefs.remove(_clave(usuarioId));
      }
    } catch (_) {
      // Sin copia local, el peor caso es quedarse en Profundidad al caer la red.
    }
  }

  /// Aplica la copia local del usuario si su código sigue en el catálogo. Una
  /// copia de otro usuario o un código retirado no se aplica.
  static Future<void> _aplicarCopiaLocal(int usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigo = prefs.getString(_clave(usuarioId));
      if (codigo != null && catalogoIdentidades.containsKey(codigo)) {
        aplicarIdentidadEquipada(codigo);
      }
    } catch (_) {
      // Sin copia no hay nada que aplicar: se queda como estaba.
    }
    await _aplicarCopiaPrendas(usuarioId);
  }

  /// Reintenta la carga en segundo plano hasta [_maxReintentos] veces. Cada
  /// fallo programa el siguiente; un éxito no deja nada pendiente.
  static void _programarReintento(int usuarioId, int intento) {
    if (intento > _maxReintentos) return;
    _reintento = Timer(esperaReintento, () async {
      try {
        final inventario = await obtenerInventario(usuarioId);
        await _aplicarYGuardar(usuarioId, inventario);
        _reintento = null;
      } catch (_) {
        _programarReintento(usuarioId, intento + 1);
      }
    });
  }

  /// Códigos de todo lo que el usuario lleva puesto.
  ///
  /// El inventario llega como lista de `{producto: {...}, equipado: bool}`;
  /// se lee defensivamente porque un campo que falte es "no equipado", no un
  /// crash.
  static List<String> _codigosEquipados(List<dynamic> inventario) {
    final codigos = <String>[];
    for (final up in inventario) {
      if (up['equipado'] != true) continue;
      final codigo = up['producto']?['codigo'];
      if (codigo is String) codigos.add(codigo);
    }
    return codigos;
  }

  /// Prendas puestas según el inventario: sitio → código. El sitio es la
  /// `categoria` del producto; lo que no es de [sitiosPrenda] (temas, avatares,
  /// un backend antiguo sin `categoria`) no cuenta. Si un sitio tiene dos
  /// equipadas, que no debería (N-5), gana la de `usuarioProductoId` más alto,
  /// la misma que deja la limpieza de N-5.
  static Map<String, String> _prendasEquipadas(List<dynamic> inventario) {
    final prendas = <String, String>{};
    final ids = <String, int>{};
    for (final up in inventario) {
      if (up is! Map || up['equipado'] != true) continue;
      final producto = up['producto'];
      if (producto is! Map) continue;
      final sitio = producto['categoria'];
      final codigo = producto['codigo'];
      if (sitio is! String || codigo is! String) continue;
      if (!sitiosPrenda.contains(sitio)) continue;
      final id = up['usuarioProductoId'];
      final idNum = id is int ? id : -1;
      if ((ids[sitio] ?? -2) >= idNum) continue;
      prendas[sitio] = codigo;
      ids[sitio] = idNum;
    }
    return prendas;
  }

  /// Posee identidad si alguno de los productos del inventario tiene un
  /// código que esté en el catálogo local de identidades, esté equipado o no.
  static bool _poseeIdentidad(List<dynamic> inventario) {
    for (final up in inventario) {
      final codigo = up['producto']?['codigo'];
      if (codigo is String && catalogoIdentidades.containsKey(codigo)) {
        return true;
      }
    }
    return false;
  }
}
