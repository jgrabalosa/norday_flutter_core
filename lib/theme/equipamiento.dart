import '../services/api_service_core.dart';
import 'avatares.dart';
import 'identidades_paleta.dart';

/// Qué lleva puesto el usuario — tema y avatar — contra el backend.
///
/// La fuente de verdad es el inventario del servidor, no el dispositivo: el
/// usuario puede equipar desde otro móvil y al volver a este tiene que verlo.
///
/// El puente entre el catálogo local (`catalogoIdentidades`, `catalogoAvatares`,
/// que van por código: 'TEMA_ALBA', 'AVATAR_ZORRO') y el backend (que va
/// por `productoId`) es el campo `codigo` del producto. Ningún identificador
/// de la BD está cableado en el cliente.
class Equipamiento {
  const Equipamiento._();

  /// Llamar cuando hay sesión: tras el login y tras el splash con sesión ya
  /// guardada. No se puede llamar antes —en `main()` no hay ni usuarioId ni
  /// token—, así que hasta que responda se ve el tema por defecto.
  ///
  /// Una sola petición para los dos: son el mismo inventario.
  static Future<void> cargarDeUsuario(int usuarioId) async {
    final inventario = await ApiServiceCore.getInventarioProductos(usuarioId);
    final equipados = _codigosEquipados(inventario);
    // Cuál es tema y cuál avatar no se le pregunta al backend: se mira en qué
    // catálogo local cae el código. Así basta con que el inventario traiga
    // `codigo`, sin depender de que además mande la categoría.
    aplicarIdentidadEquipada(
        equipados.where(catalogoIdentidades.containsKey).firstOrNull);
    aplicarAvatarEquipado(
        equipados.where(catalogoAvatares.containsKey).firstOrNull);
  }

  /// Igual que [cargarDeUsuario] pero sin propagar el fallo: al arrancar, no
  /// poder leer el inventario no es motivo para dejar al usuario fuera —
  /// se queda el tema por defecto y ya se corregirá al siguiente intento.
  static Future<void> cargarDeUsuarioSiSePuede(int usuarioId) async {
    try {
      await cargarDeUsuario(usuarioId);
    } catch (_) {
      // El aspecto nunca debe romper el arranque.
    }
  }

  /// Equipa un tema: lo dice el backend y, si acepta, se pinta.
  static Future<void> equiparTema(
      int usuarioId, int productoId, String? codigo) async {
    await ApiServiceCore.equiparProducto(usuarioId, productoId);
    aplicarIdentidadEquipada(codigo);
  }

  /// Equipa un avatar: lo dice el backend y, si acepta, se pinta.
  static Future<void> equiparAvatar(
      int usuarioId, int productoId, String? codigo) async {
    await ApiServiceCore.equiparProducto(usuarioId, productoId);
    aplicarAvatarEquipado(codigo);
  }

  /// Quita el avatar y vuelve al círculo con la inicial del nombre.
  static Future<void> desequiparAvatar(int usuarioId, int productoId) async {
    await ApiServiceCore.desequiparProducto(usuarioId, productoId);
    aplicarAvatarEquipado(null);
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
}
