import '../theme/prendas.dart';

/// Lo que la tienda enseña hoy del precio de un producto (ventas por periodo,
/// T-022 del backend): el precio que se paga y, si es de una oferta, hasta
/// qué día vale.
class PrecioTienda {
  final int precio;

  /// El último día de la oferta (incluido). `null` si no es de una oferta.
  final DateTime? hasta;

  const PrecioTienda(this.precio, [this.hasta]);

  bool get gratis => precio == 0;
}

/// El precio de [producto] (un elemento del catálogo) el día de [ahora], con
/// la fecha del móvil. `null` si hoy no está a la venta.
///
/// - Sin `ofertas` (backend anterior a T-022, o producto sin ofertas): su
///   `precio` de siempre, sin fecha.
/// - Con ofertas: la que vale hoy (`desde <= hoy <= hasta`); si se solapan,
///   la de `desde` más reciente, como el backend. Si ninguna vale hoy (todas
///   futuras o ya pasadas), no sale.
///
/// Una oferta que no se entiende (fechas mal escritas) se ignora; si no se
/// entiende ninguna, es como si no tuviera.
PrecioTienda? precioEnTienda(Map producto, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final ofertas = <({DateTime desde, DateTime hasta, int precio})>[];
  final crudas = producto['ofertas'];
  if (crudas is List) {
    for (final o in crudas) {
      if (o is! Map) continue;
      final desde = _dia(o['desde']);
      final hasta = _dia(o['hasta']);
      final precio = o['precio'];
      if (desde == null || hasta == null || precio is! num) continue;
      ofertas.add((desde: desde, hasta: hasta, precio: precio.toInt()));
    }
  }
  if (ofertas.isEmpty) {
    final precio = producto['precio'];
    return PrecioTienda(precio is num ? precio.toInt() : 0);
  }
  // Si se solapan, manda la de `desde` más reciente: es la que cobra el
  // backend (`ProductoService.vigente`).
  ({DateTime desde, DateTime hasta, int precio})? vigente;
  for (final o in ofertas) {
    if (hoy.isBefore(o.desde) || hoy.isAfter(o.hasta)) continue;
    if (vigente == null || o.desde.isAfter(vigente.desde)) vigente = o;
  }
  return vigente == null ? null : PrecioTienda(vigente.precio, vigente.hasta);
}

/// Si [producto] es una prenda de Nori: su `categoria` es un sitio de
/// [sitiosPrenda]. Las prendas van al vestidor y a la sección Nori de la
/// tienda, nunca a Colección.
bool esPrenda(Map producto) => sitiosPrenda.contains(producto['categoria']);

DateTime? _dia(Object? valor) {
  if (valor is! String) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(valor);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}
