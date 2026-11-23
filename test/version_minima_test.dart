import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/actualizacion_obligatoria_screen.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/services/version_minima_service.dart';

/// Lo que contesta el cliente HTTP falso. `ApiServiceCore.cliente` es un
/// `static final`: se crea una vez, dentro de `http.runWithClient`, y cada
/// test cambia solo esta función.
late Future<http.Response> Function(http.Request) responder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final falso = MockClient((peticion) => responder(peticion));
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  // La petición de verdad, antes de que setUp la sustituya.
  final pedirAlBackend = VersionMinimaService.pedirVersionMinima;
  final pedirRecomendadaAlBackend =
      VersionMinimaService.pedirVersionRecomendada;

  late List<String> preguntadas;

  setUp(() {
    ApiServiceCore.appId = 'habitos';
    preguntadas = [];
    VersionMinimaService.leerVersionInstalada = () async => 5;
    VersionMinimaService.pedirVersionMinima = (appId) async {
      preguntadas.add(appId);
      return 5;
    };
  });

  tearDown(() {
    ApiServiceCore.appId = '';
    VersionMinimaService.reiniciarParaTest();
  });

  group('hayQueActualizar', () {
    test('instalada por debajo de la mínima: hay que actualizar', () async {
      VersionMinimaService.pedirVersionMinima = (_) async => 6;
      expect(await VersionMinimaService.hayQueActualizar(), isTrue);
    });

    test('instalada igual que la mínima: no', () async {
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
    });

    test('instalada por encima de la mínima: no', () async {
      VersionMinimaService.pedirVersionMinima = (_) async => 4;
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
    });

    test('pregunta por el appId de la app', () async {
      await VersionMinimaService.hayQueActualizar();
      expect(preguntadas, ['habitos']);
    });

    test('si el backend no contesta, no bloquea', () async {
      VersionMinimaService.pedirVersionMinima = (_) async =>
          throw Exception('sin red');
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
    });

    test('si no se puede leer la versión instalada, no bloquea', () async {
      VersionMinimaService.pedirVersionMinima = (_) async => 6;
      VersionMinimaService.leerVersionInstalada = () async =>
          throw const FormatException('buildNumber raro');
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
    });

    test('sin appId no pregunta al backend ni bloquea', () async {
      ApiServiceCore.appId = '';
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
      expect(preguntadas, isEmpty);
    });
  });

  group('vigilarAlVolver', () {
    /// Lleva el ciclo de vida por los pasos que da Android, de uno en uno.
    Future<void> ciclo(
      WidgetTester tester,
      List<AppLifecycleState> pasos,
    ) async {
      for (final p in pasos) {
        tester.binding.handleAppLifecycleStateChanged(p);
        await tester.pump();
      }
    }

    const irse = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];
    const volver = [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ];

    testWidgets('arranque en frío directo a resumed: no comprueba', (
      tester,
    ) async {
      // Cada test empieza sin estado, como un proceso recién lanzado.
      expect(tester.binding.lifecycleState, isNull);
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [AppLifecycleState.resumed]);
      expect(preguntadas, isEmpty);
    });

    testWidgets('arranque en frío sin foco (inactive y luego resumed): '
        'no comprueba', (tester) async {
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      expect(preguntadas, isEmpty);
    });

    testWidgets('volver del segundo plano: comprueba una vez', (tester) async {
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [AppLifecycleState.resumed]);
      await ciclo(tester, irse);
      expect(preguntadas, isEmpty);
      await ciclo(tester, volver);
      expect(preguntadas, ['habitos']);
    });

    testWidgets('cada vuelta del segundo plano comprueba', (tester) async {
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [AppLifecycleState.resumed]);
      await ciclo(tester, [...irse, ...volver]);
      await ciclo(tester, [...irse, ...volver]);
      expect(preguntadas, ['habitos', 'habitos']);
    });

    testWidgets('volver de inactive sin pasar por hidden: comprueba, '
        'como antes', (tester) async {
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [AppLifecycleState.resumed]);
      await ciclo(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      expect(preguntadas, ['habitos']);
    });

    testWidgets('si ya estaba en primer plano al vigilar, la primera vuelta '
        'comprueba', (tester) async {
      await ciclo(tester, [AppLifecycleState.resumed]);
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [...irse, ...volver]);
      expect(preguntadas, ['habitos']);
    });

    testWidgets('llamarlo dos veces no duplica la comprobación', (
      tester,
    ) async {
      VersionMinimaService.vigilarAlVolver();
      VersionMinimaService.vigilarAlVolver();
      await ciclo(tester, [AppLifecycleState.resumed]);
      await ciclo(tester, [...irse, ...volver]);
      expect(preguntadas, ['habitos']);
    });
  });

  group('log del fallo', () {
    late List<String> lineas;
    late DebugPrintCallback printOriginal;

    setUp(() {
      lineas = [];
      printOriginal = debugPrint;
      debugPrint = (mensaje, {wrapWidth}) => lineas.add(mensaje ?? '');
      VersionMinimaService.pedirVersionMinima = pedirAlBackend;
    });

    tearDown(() => debugPrint = printOriginal);

    test('sin red: el log lleva la causa, no solo el tipo', () async {
      responder = (_) async =>
          throw http.ClientException('Failed host lookup: api.norday.app');
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
      expect(lineas, hasLength(1));
      expect(lineas.single, contains('sinConexion'));
      expect(lineas.single, contains('Failed host lookup: api.norday.app'));
    });

    test('error del servidor: el log lleva el código y el cuerpo', () async {
      responder = (_) async => http.Response('bad gateway', 502);
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
      expect(lineas, hasLength(1));
      expect(lineas.single, contains('HTTP 502'));
      expect(lineas.single, contains('bad gateway'));
    });

    test('un fallo que no es de la API se registra igual que antes', () async {
      VersionMinimaService.pedirVersionMinima = (_) async =>
          throw Exception('otra cosa');
      expect(await VersionMinimaService.hayQueActualizar(), isFalse);
      expect(lineas, [
        'Versión mínima: no se pudo comprobar: Exception: otra cosa',
      ]);
    });
  });

  group('pantalla de actualización obligatoria', () {
    Widget app(Widget home) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
      home: home,
    );

    testWidgets('enseña el título, el texto y el botón', (tester) async {
      await tester.pumpWidget(app(const ActualizacionObligatoriaScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Hay una versión nueva'), findsOneWidget);
      expect(find.text('Actualizar ahora'), findsOneWidget);
    });

    testWidgets('el botón lanza la actualización', (tester) async {
      var llamadas = 0;
      ActualizacionObligatoriaScreen.actualizar = () async => llamadas++;
      await tester.pumpWidget(app(const ActualizacionObligatoriaScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actualizar ahora'));
      await tester.pump();
      expect(llamadas, 1);
    });

    testWidgets('no se puede cerrar con atrás', (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActualizacionObligatoriaScreen(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Hay una versión nueva'), findsOneWidget);
    });
  });

  group('versionRecomendada del backend', () {
    setUp(() {
      VersionMinimaService.pedirVersionRecomendada = pedirRecomendadaAlBackend;
    });

    Future<int?> pedir(String cuerpo) {
      responder = (_) async => http.Response(cuerpo, 200);
      return VersionMinimaService.recomendada('habitos');
    }

    test('con número, lo devuelve', () async {
      expect(await pedir('{"versionMinima":3,"versionRecomendada":7}'), 7);
    });

    test('null explícito: null', () async {
      expect(
        await pedir('{"versionMinima":3,"versionRecomendada":null}'),
        isNull,
      );
    });

    test('sin la clave (backend viejo): null', () async {
      expect(await pedir('{"versionMinima":3}'), isNull);
    });
  });
}
