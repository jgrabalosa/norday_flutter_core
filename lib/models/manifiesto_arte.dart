/// El manifiesto del arte de las prendas de Nori: por prenda, cómo se pinta.
/// Ver `docs/funcionamiento/arte-prendas.md`.
///
/// Viene de fuera (el servidor), así que `fromJson` es tolerante: lo que no
/// entiende lo ignora en vez de lanzar. Quien necesite saber si el documento
/// entero es válido (la versión) lo comprueba antes, en el servicio.
class ManifiestoArte {
  final int version;
  final DateTime? nieveDesde;
  final DateTime? nieveHasta;

  /// Por código de producto del backend.
  final Map<String, PrendaArte> prendas;

  const ManifiestoArte({
    required this.version,
    this.nieveDesde,
    this.nieveHasta,
    this.prendas = const {},
  });

  /// Sin prendas ni nieve: lo que hay cuando nunca se bajó nada.
  static const ManifiestoArte vacio = ManifiestoArte(version: 1);

  factory ManifiestoArte.fromJson(Map<String, dynamic> json) {
    final nieve = json['nieve'];
    DateTime? desde;
    DateTime? hasta;
    if (nieve is Map) {
      desde = _fecha(nieve['desde']);
      hasta = _fecha(nieve['hasta']);
    }
    final prendas = <String, PrendaArte>{};
    final crudas = json['prendas'];
    if (crudas is Map) {
      crudas.forEach((codigo, valor) {
        if (codigo is String && valor is Map) {
          prendas[codigo] = PrendaArte.fromJson(
            Map<String, dynamic>.from(valor),
          );
        }
      });
    }
    return ManifiestoArte(
      version: json['version'] is int ? json['version'] as int : 0,
      nieveDesde: desde,
      nieveHasta: hasta,
      prendas: Map.unmodifiable(prendas),
    );
  }

  /// `true` solo entre `desde` y `hasta`, ambos incluidos, comparando la
  /// fecha (sin hora) de [hoy]. Sin las dos fechas, `false`.
  bool nieveActiva(DateTime hoy) {
    final desde = nieveDesde;
    final hasta = nieveHasta;
    if (desde == null || hasta == null) return false;
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return !dia.isBefore(desde) && !dia.isAfter(hasta);
  }

  static DateTime? _fecha(Object? valor) {
    if (valor is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(valor);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
}

/// Cómo se pinta una prenda.
class PrendaArte {
  /// `cabeza`, `cuerpo`…
  final String sitio;
  final List<String> fases;

  /// Capas de Nori que esta prenda tapa (hoy solo `brote`).
  final List<String> oculta;

  /// Píxeles del lienzo de 1024, por fase.
  final Map<String, int> subidaBrote;

  /// Clave `<fase>` o `<fase>_<estado>`; valor, ruta relativa a `<servidor>/arte/`.
  final Map<String, String> imagenes;

  const PrendaArte({
    required this.sitio,
    this.fases = const [],
    this.oculta = const [],
    this.subidaBrote = const {},
    this.imagenes = const {},
  });

  factory PrendaArte.fromJson(Map<String, dynamic> json) {
    final subida = <String, int>{};
    final crudaSubida = json['subidaBrote'];
    if (crudaSubida is Map) {
      crudaSubida.forEach((fase, px) {
        if (fase is String && px is num) subida[fase] = px.toInt();
      });
    }
    final imagenes = <String, String>{};
    final crudaImagenes = json['imagenes'];
    if (crudaImagenes is Map) {
      crudaImagenes.forEach((clave, ruta) {
        if (clave is String && ruta is String) imagenes[clave] = ruta;
      });
    }
    return PrendaArte(
      sitio: json['sitio'] is String ? json['sitio'] as String : '',
      fases: _lista(json['fases']),
      oculta: _lista(json['oculta']),
      subidaBrote: Map.unmodifiable(subida),
      imagenes: Map.unmodifiable(imagenes),
    );
  }

  /// La ruta de `<fase>_<estado>`; si no hay, la de `<fase>`; si tampoco,
  /// `null`.
  String? imagenPara(String fase, String estado) =>
      imagenes['${fase}_$estado'] ?? imagenes[fase];

  /// La subida del brote en [fase], o 0.
  int subidaBroteEn(String fase) => subidaBrote[fase] ?? 0;

  static List<String> _lista(Object? valor) =>
      valor is List ? List.unmodifiable(valor.whereType<String>()) : const [];
}
