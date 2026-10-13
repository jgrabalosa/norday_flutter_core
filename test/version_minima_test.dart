import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/actualizacion_obligatoria_screen.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/services/version_minima_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  tearDown(() => ApiServiceCore.appId = '');

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
}
