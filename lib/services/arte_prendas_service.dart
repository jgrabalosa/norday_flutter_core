import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/manifiesto_arte.dart';
import 'api_service_core.dart';

/// El arte de las prendas de Nori: el manifiesto y las imágenes, que se
/// descargan del servidor y se guardan en disco para siempre. Ver
/// `docs/funcionamiento/arte-prendas.md`.
///
/// Nada de aquí lanza: sin red, o con algo que no entiende, Nori se queda con
/// lo último que bajó y, si nunca bajó nada, sin prendas.
class ArtePrendasService {
  /// Dónde se guarda el último manifiesto bueno (el JSON tal cual llegó).
  static const String claveUltimoManifiesto = 'arte_manifiesto_ultimo_bueno';

  /// La única versión del formato que este código entiende.
  static const int versionManifiesto = 1;

  static final RegExp _rutaValida = RegExp(r'^[a-z0-9_./-]+$');
  static const Duration _espera = Duration(seconds: 15);

  final http.Client _cliente;
  final String _urlArte;
  final Future<Directory> Function() _carpetaCache;

  /// [cliente], [urlBase] y [carpetaCache] se inyectan en los tests. Por
  /// defecto: `ApiServiceCore.cliente`, `ApiServiceCore.baseUrl` sin el `/api`
  /// final, y `getApplicationSupportDirectory()` + `/arte`.
  ArtePrendasService({
    http.Client? cliente,
    String? urlBase,
    Future<Directory> Function()? carpetaCache,
  }) : _cliente = cliente ?? ApiServiceCore.cliente,
       _urlArte = '${_sinApi(urlBase ?? ApiServiceCore.baseUrl)}/arte',
       _carpetaCache = carpetaCache ?? _carpetaPorDefecto;

  static String _sinApi(String url) {
    var u = url;
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/api')) u = u.substring(0, u.length - 4);
    return u;
  }

  static Future<Directory> _carpetaPorDefecto() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/arte');
  }

  /// Pide el manifiesto. Si llega bien y es de la versión 1, lo guarda como
  /// último bueno y lo devuelve. Si no hay red, la respuesta no es 200, el
  /// JSON está roto o la versión no es 1: el último bueno; y si no hay,
  /// [ManifiestoArte.vacio].
  Future<ManifiestoArte> cargarManifiesto() async {
    try {
      final r = await _cliente
          .get(Uri.parse('$_urlArte/manifiesto-v1.json'))
          .timeout(_espera);
      if (r.statusCode == 200) {
        final cuerpo = utf8.decode(r.bodyBytes);
        final manifiesto = _entender(cuerpo);
        if (manifiesto != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(claveUltimoManifiesto, cuerpo);
          } catch (_) {
            // No poder guardarlo no quita que este sí sirva.
          }
          return manifiesto;
        }
      }
    } catch (_) {
      // Sin red o ilegible: cae al último bueno.
    }
    return _ultimoBueno();
  }

  Future<ManifiestoArte> _ultimoBueno() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(claveUltimoManifiesto);
      if (guardado != null) {
        return _entender(guardado) ?? ManifiestoArte.vacio;
      }
    } catch (_) {}
    return ManifiestoArte.vacio;
  }

  /// `null` si no es JSON, no es un objeto o su versión no es la 1.
  ManifiestoArte? _entender(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo);
      if (json is! Map<String, dynamic>) return null;
      if (json['version'] != versionManifiesto) return null;
      return ManifiestoArte.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// El fichero de [ruta] (relativa a `<servidor>/arte/`). Si ya está en la
  /// caché, se devuelve sin tocar la red; si no, se descarga y se guarda con
  /// su nombre. Si falla, o la ruta no es válida, `null`; nunca queda un
  /// fichero a medias.
  Future<File?> imagen(String ruta) async {
    if (!_rutaSegura(ruta)) return null;
    File? temporal;
    try {
      final carpeta = await _carpetaCache();
      final destino = File('${carpeta.path}/$ruta');
      if (await destino.exists()) return destino;

      final r = await _cliente
          .get(Uri.parse('$_urlArte/$ruta'))
          .timeout(_espera);
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) return null;

      await destino.parent.create(recursive: true);
      // A un temporal y renombrar: el rename es atómico dentro de la misma
      // carpeta, así que `destino` existe entero o no existe.
      temporal = File('${destino.path}.part');
      await temporal.writeAsBytes(r.bodyBytes, flush: true);
      await temporal.rename(destino.path);
      return destino;
    } catch (_) {
      if (temporal != null) {
        try {
          if (await temporal.exists()) await temporal.delete();
        } catch (_) {}
      }
      return null;
    }
  }

  static bool _rutaSegura(String ruta) =>
      ruta.isNotEmpty &&
      !ruta.startsWith('/') &&
      !ruta.contains('..') &&
      _rutaValida.hasMatch(ruta);
}
