import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/mascota_screen.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/services/manifiesto_compartido.dart';
import 'package:norday_flutter_core/theme/mascota_refresh.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/burbuja_contexto.dart';
import 'package:norday_flutter_core/widgets/mascota_animada_viva.dart';
import 'package:norday_flutter_core/widgets/tarjeta_nori.dart';
import 'package:norday_flutter_core/widgets/vestidor_nori.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usuarioId = 7;

/// El backend que la pantalla de la Mascota pide al cargarse y al comer. Las
/// rutas son las de `ApiServiceCore`; el arte (`/arte/…`) responde 404, así que
/// el manifiesto queda vacío y no sale nada de red.
class _Backend {
  /// La XP que devuelve dar de comer. Por defecto, la que da un consumible.
  int xpGanada = 5;

  /// Lo que `getMascota` dice de las comidas de hoy; null = backend anterior.
  int? comidasHoy;
  int? comidasMaxDia;

  /// Si no es null, dar de comer responde con este código.
  int? estadoAlUsar;

  /// Cada petición como `MÉTODO /ruta`, en orden.
  final List<String> peticiones = [];

  Future<http.Response> responder(http.Request r) async {
    final ruta = r.url.toString().replaceFirst(ApiServiceCore.baseUrl, '');
    peticiones.add('${r.method} $ruta');
    if (ruta == '/mascota/$_usuarioId') {
      return _json({
        'nombre': 'Pepa',
        'nivel': 2,
        'xpEnNivelActual': 5,
        'xpParaSiguienteNivel': 20,
        'fase': 'CRIA',
        'faseReal': 'CRIA',
        'animo': 'feliz',
        'comidasHoy': ?comidasHoy,
        'comidasMaxDia': ?comidasMaxDia,
      });
    }
    if (ruta == '/gamificacion/productos/usuario/$_usuarioId') {
      return _json([
        {
          'cantidad': 3,
          'producto': {
            'productoId': 1,
            'codigo': 'COMIDA_BASICA',
            'nombre': 'Comida',
            'categoria': 'Consumible',
          },
        },
        {
          'cantidad': 1,
          'producto': {
            'productoId': 10,
            'codigo': 'PRENDA_GORRO_LANA',
            'nombre': 'Gorro de lana',
            'categoria': 'Cabeza',
          },
        },
      ]);
    }
    if (ruta == '/gamificacion/productos/usar/$_usuarioId/1') {
      if (estadoAlUsar != null) return http.Response('x', estadoAlUsar!);
      return _json({
        'codigoConsumido': 'COMIDA_BASICA',
        'subioNivel': false,
        'nivelNuevo': 0,
        'xpGanada': xpGanada,
      });
    }
    return http.Response('', 404);
  }

  static http.Response _json(Object cuerpo) => http.Response(
    jsonEncode(cuerpo),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// La pantalla de la Mascota (MascotaScreen), montada entera contra un backend
/// falso.
///
/// Sin seam nuevo: `ApiServiceCore.cliente` es un `static final` que se crea
/// la primera vez que se lee, así que este fichero lo crea dentro de
/// `http.runWithClient` con un cliente falso (como `mini_mascota_fase_test.dart`).
/// Por eso vive solo: en otro fichero el cliente ya podría estar creado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late _Backend backend;
  final falso = MockClient((peticion) => backend.responder(peticion));
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
    aplicarPrendasEquipadas(const {});
    backend = _Backend();
  });

  tearDown(() {
    aplicarPrendasEquipadas(const {});
    faseMascotaNotifier.value = null;
    reiniciarManifiestoParaTest();
  });

  /// Deja acabar las cargas (con respuestas inmediatas) y la transición de la
  /// ilustración. No `pumpAndSettle`: Nori respira en bucle.
  Future<void> asentar(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Monta la pantalla en 520 × 900: la fuente de los tests da a cada letra un
  /// ancho de 1 em, y en 400 la fila de Alimentar y Tienda desborda aunque en
  /// un móvil de verdad quepa. Las animaciones van apagadas: el aviso de
  /// reacción se cuenta igual, porque no depende de moverse.
  Future<void> montar(
    WidgetTester tester, {
    GlobalKey? ancla,
    Future<void> Function(DatosNori)? alCompartir,
  }) async {
    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: MascotaScreen(
            usuarioId: _usuarioId,
            embebida: true,
            anclaAlimentar: ancla,
            alCompartir: alCompartir,
          ),
        ),
      ),
    );
    await asentar(tester);
  }

  group('compartir', () {
    final boton = find.byTooltip('Compartir a Nori');
    final icono = find.widgetWithIcon(IconButton, LucideIcons.share2);

    testWidgets('sin alCompartir no hay botón', (tester) async {
      await montar(tester);
      expect(boton, findsNothing);
    });

    testWidgets('con alCompartir, el botón lo llama una vez con los datos y '
        'se apaga mientras se prepara', (tester) async {
      final datos = <DatosNori>[];
      final terminar = Completer<void>();
      await montar(
        tester,
        alCompartir: (d) {
          datos.add(d);
          return terminar.future;
        },
      );
      expect(boton, findsOneWidget);
      // Esquina superior derecha de la escena: sobre Nori, a su derecha.
      final nori = tester.getRect(find.byType(MascotaAnimadaViva));
      final esquina = tester.getCenter(boton);
      expect(esquina.dx, greaterThan(nori.center.dx));
      expect(esquina.dy, lessThan(nori.center.dy));

      await tester.tap(boton);
      await tester.pump();
      await tester.tap(boton, warnIfMissed: false);
      await tester.pump();

      expect(datos, hasLength(1));
      expect(datos.single.fase, 'CRIA');
      expect(datos.single.nombre, 'Pepa');
      expect(datos.single.nivel, 2);
      expect(tester.widget<IconButton>(icono).onPressed, isNull);

      terminar.complete();
      await tester.pump();
      expect(tester.widget<IconButton>(icono).onPressed, isNotNull);
    });
  });

  testWidgets('el botón de alimentar queda debajo de Nori y por encima del '
      'vestidor', (tester) async {
    final ancla = GlobalKey();
    await montar(tester, ancla: ancla);

    final alimentar = tester.getTopLeft(find.byKey(ancla)).dy;
    expect(
      alimentar,
      greaterThan(tester.getBottomLeft(find.byType(BurbujaContexto)).dy),
    );
    expect(
      alimentar,
      lessThan(tester.getTopLeft(find.byType(VestidorNori)).dy),
    );
  });

  testWidgets('al dar de comer con XP, Nori recibe la reacción una vez', (
    tester,
  ) async {
    final ancla = GlobalKey();
    await montar(tester, ancla: ancla);

    var reacciones = 0;
    tester
        .widget<MascotaAnimadaViva>(find.byType(MascotaAnimadaViva))
        .reaccion!
        .addListener(() {
          reacciones++;
        });

    await tester.tap(find.byKey(ancla));
    await asentar(tester);
    // Lo que dura el «+XP» flotante, para que no quede nada pendiente.
    await tester.pump(const Duration(seconds: 2));

    expect(
      backend.peticiones,
      contains('POST /gamificacion/productos/usar/7/1'),
    );
    expect(reacciones, 1);
  });

  group('Nori lleno', () {
    const usar = 'POST /gamificacion/productos/usar/7/1';

    Future<void> alimentar(WidgetTester tester, GlobalKey ancla) async {
      await montar(tester, ancla: ancla);
      await tester.tap(find.byKey(ancla));
      await asentar(tester);
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('lleno: avisa, Nori reacciona y no llama al backend', (
      tester,
    ) async {
      backend.comidasHoy = 3;
      backend.comidasMaxDia = 3;
      final ancla = GlobalKey();
      await montar(tester, ancla: ancla);
      var reacciones = 0;
      tester
          .widget<MascotaAnimadaViva>(find.byType(MascotaAnimadaViva))
          .reaccion!
          .addListener(() => reacciones++);

      await tester.tap(find.byKey(ancla));
      await asentar(tester);

      expect(find.textContaining('¡Nori está lleno!'), findsOneWidget);
      expect(find.textContaining('comido 3 veces'), findsOneWidget);
      expect(backend.peticiones, isNot(contains(usar)));
      expect(reacciones, 1);
    });

    testWidgets('con 2 de 3, da de comer', (tester) async {
      backend.comidasHoy = 2;
      backend.comidasMaxDia = 3;
      await alimentar(tester, GlobalKey());
      expect(backend.peticiones, contains(usar));
      expect(find.textContaining('¡Nori está lleno!'), findsNothing);
    });

    testWidgets('sin comidasMaxDia, da de comer', (tester) async {
      backend.comidasHoy = 3;
      await alimentar(tester, GlobalKey());
      expect(backend.peticiones, contains(usar));
    });

    testWidgets('un 409 enseña el mismo aviso y recarga', (tester) async {
      backend.estadoAlUsar = 409;
      await alimentar(tester, GlobalKey());
      expect(backend.peticiones, contains(usar));
      expect(find.textContaining('¡Nori está lleno!'), findsOneWidget);
      expect(
        backend.peticiones.where((p) => p == 'GET /mascota/7'),
        hasLength(2),
      );
    });

    testWidgets('otro error sigue siendo el genérico', (tester) async {
      backend.estadoAlUsar = 400;
      await alimentar(tester, GlobalKey());
      expect(find.textContaining('¡Nori está lleno!'), findsNothing);
    });
  });

  testWidgets('sin XP, Nori no reacciona', (tester) async {
    backend.xpGanada = 0;
    final ancla = GlobalKey();
    await montar(tester, ancla: ancla);

    var reacciones = 0;
    tester
        .widget<MascotaAnimadaViva>(find.byType(MascotaAnimadaViva))
        .reaccion!
        .addListener(() {
          reacciones++;
        });

    await tester.tap(find.byKey(ancla));
    await asentar(tester);
    await tester.pump(const Duration(seconds: 2));

    expect(
      backend.peticiones,
      contains('POST /gamificacion/productos/usar/7/1'),
    );
    expect(reacciones, 0);
  });
}
