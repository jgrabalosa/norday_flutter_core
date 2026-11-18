import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/services/arte_prendas_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _manifiestoBueno = {
  'version': 1,
  'nieve': {'desde': '2026-12-01', 'hasta': '2027-01-06'},
  'prendas': {
    'PRENDA_GORRO_LANA': {
      'sitio': 'cabeza',
      'fases': ['huevo', 'cria', 'adulto'],
      'oculta': ['brote'],
      'subidaBrote': {'huevo': 76, 'cria': 24},
      'imagenes': {
        'huevo': 'prendas/gorro_lana_huevo.62733313.webp',
        'cria': 'prendas/gorro_lana_cria.28e8ce75.webp',
        'cria_dormido': 'prendas/gorro_lana_cria_dormido.3a4b5c6d.webp',
      },
    },
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory carpeta;
  late List<Uri> llamadas;
  late Future<http.Response> Function(http.Request) responder;

  ArtePrendasService servicio() => ArtePrendasService(
    cliente: MockClient((p) {
      llamadas.add(p.url);
      return responder(p);
    }),
    urlBase: 'https://servidor.test/api',
    carpetaCache: () async => carpeta,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    llamadas = [];
    carpeta = await Directory.systemTemp.createTemp('arte_test');
    responder = (_) async => http.Response(jsonEncode(_manifiestoBueno), 200);
  });

  tearDown(() async {
    if (await carpeta.exists()) await carpeta.delete(recursive: true);
  });

  group('cargarManifiesto', () {
    test('un manifiesto bueno se lee entero y queda guardado', () async {
      final m = await servicio().cargarManifiesto();

      expect(llamadas.single.toString(),
          'https://servidor.test/arte/manifiesto-v1.json');
      expect(m.version, 1);
      expect(m.nieveDesde, DateTime(2026, 12, 1));
      expect(m.nieveHasta, DateTime(2027, 1, 6));
      final p = m.prendas['PRENDA_GORRO_LANA']!;
      expect(p.sitio, 'cabeza');
      expect(p.fases, ['huevo', 'cria', 'adulto']);
      expect(p.oculta, ['brote']);
      expect(p.subidaBrote, {'huevo': 76, 'cria': 24});
      expect(p.imagenes['huevo'], 'prendas/gorro_lana_huevo.62733313.webp');
      expect(p.imagenes, hasLength(3));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ArtePrendasService.claveUltimoManifiesto),
          isNotNull);
    });

    final fallos = <String, Future<http.Response> Function(http.Request)>{
      'roto (JSON inválido)': (_) async => http.Response('{no es json', 200),
      'de otra versión': (_) async =>
          http.Response(jsonEncode({..._manifiestoBueno, 'version': 2}), 200),
      'error 500': (_) async => http.Response('boom', 500),
      'sin red': (_) async => throw http.ClientException('sin red'),
    };

    fallos.forEach((nombre, fallo) {
      test('$nombre: devuelve el último bueno', () async {
        await servicio().cargarManifiesto();
        responder = fallo;
        final m = await servicio().cargarManifiesto();
        expect(m.prendas.keys, ['PRENDA_GORRO_LANA']);
        expect(m.nieveDesde, DateTime(2026, 12, 1));
      });

      test('$nombre: sin último bueno, el vacío', () async {
        responder = fallo;
        final m = await servicio().cargarManifiesto();
        expect(m.prendas, isEmpty);
        expect(m.nieveActiva(DateTime(2026, 12, 25)), isFalse);
      });
    });

    test('uno malo no pisa el último bueno guardado', () async {
      await servicio().cargarManifiesto();
      responder = (_) async =>
          http.Response(jsonEncode({..._manifiestoBueno, 'version': 2}), 200);
      await servicio().cargarManifiesto();
      responder = (_) async => throw http.ClientException('sin red');
      final m = await servicio().cargarManifiesto();
      expect(m.prendas, isNotEmpty);
    });
  });

  group('modelo', () {
    final prenda = ManifiestoArte.fromJson(
      Map<String, dynamic>.from(_manifiestoBueno),
    ).prendas['PRENDA_GORRO_LANA']!;

    test('imagenPara: <fase>_<estado> si existe', () {
      expect(prenda.imagenPara('cria', 'dormido'),
          'prendas/gorro_lana_cria_dormido.3a4b5c6d.webp');
    });

    test('imagenPara: cae a <fase>', () {
      expect(prenda.imagenPara('cria', 'contento'),
          'prendas/gorro_lana_cria.28e8ce75.webp');
    });

    test('imagenPara: sin imagen, null', () {
      expect(prenda.imagenPara('adulto', 'contento'), isNull);
    });

    test('subidaBroteEn de una fase que falta da 0', () {
      expect(prenda.subidaBroteEn('huevo'), 76);
      expect(prenda.subidaBroteEn('adulto'), 0);
    });

    test('nieveActiva: bordes incluidos', () {
      final m = ManifiestoArte.fromJson(
        Map<String, dynamic>.from(_manifiestoBueno),
      );
      expect(m.nieveActiva(DateTime(2026, 11, 30, 23, 59)), isFalse);
      expect(m.nieveActiva(DateTime(2026, 12, 1)), isTrue);
      expect(m.nieveActiva(DateTime(2027, 1, 6, 23, 59)), isTrue);
      expect(m.nieveActiva(DateTime(2027, 1, 7)), isFalse);
    });

    test('sin nieve, nieveActiva es false', () {
      expect(ManifiestoArte.vacio.nieveActiva(DateTime(2026, 12, 25)), isFalse);
    });
  });

  group('imagen', () {
    const ruta = 'prendas/gorro_lana_huevo.62733313.webp';
    final bytes = [1, 2, 3, 4];

    test('la primera vez descarga y guarda; la segunda no llama a la red',
        () async {
      responder = (_) async => http.Response.bytes(bytes, 200);
      final s = servicio();

      final a = await s.imagen(ruta);
      expect(a, isNotNull);
      expect(await a!.readAsBytes(), bytes);
      expect(llamadas.single.toString(), 'https://servidor.test/arte/$ruta');

      final b = await s.imagen(ruta);
      expect(b!.path, a.path);
      expect(llamadas, hasLength(1));
    });

    test('si la descarga falla, null y no queda fichero', () async {
      responder = (_) async => throw http.ClientException('sin red');
      expect(await servicio().imagen(ruta), isNull);
      expect(carpeta.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('con un 404, null y no queda fichero', () async {
      responder = (_) async => http.Response('no', 404);
      expect(await servicio().imagen(ruta), isNull);
      expect(carpeta.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    for (final mala in [
      'prendas/../secreto.webp',
      '../secreto.webp',
      '/etc/passwd',
      'prendas/Gorro.webp',
      'prendas/gorro lana.webp',
      '',
    ]) {
      test('ruta no válida "$mala": null sin llamar a la red', () async {
        expect(await servicio().imagen(mala), isNull);
        expect(llamadas, isEmpty);
      });
    }
  });
}
