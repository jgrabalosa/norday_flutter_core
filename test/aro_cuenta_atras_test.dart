import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/anillo_identidad.dart';
import 'package:norday_flutter_core/widgets/aro_cuenta_atras.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    usarCacheLapiz = true;
  });

  Widget montar(Widget child, {Locale locale = const Locale('es')}) =>
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        locale: locale,
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  group('cifra', () {
    test('mm:ss con los segundos hacia arriba', () {
      expect(AroCuentaAtras.cifra(const Duration(minutes: 25)), '25:00');
      expect(
        AroCuentaAtras.cifra(const Duration(minutes: 24, milliseconds: 59001)),
        '25:00',
      );
      expect(
        AroCuentaAtras.cifra(const Duration(minutes: 24, seconds: 59)),
        '24:59',
      );
      expect(AroCuentaAtras.cifra(const Duration(milliseconds: 1)), '00:01');
      expect(AroCuentaAtras.cifra(Duration.zero), '00:00');
      expect(AroCuentaAtras.cifra(const Duration(seconds: -3)), '00:00');
    });

    test('más de una hora sigue en minutos', () {
      expect(AroCuentaAtras.cifra(const Duration(minutes: 120)), '120:00');
    });
  });

  test('los minutos que oye el lector, hacia arriba', () {
    expect(AroCuentaAtras.minutosParaLeer(const Duration(minutes: 25)), 25);
    expect(
      AroCuentaAtras.minutosParaLeer(const Duration(minutes: 24, seconds: 1)),
      25,
    );
    expect(AroCuentaAtras.minutosParaLeer(const Duration(seconds: 1)), 1);
    expect(AroCuentaAtras.minutosParaLeer(Duration.zero), 0);
  });

  test('la fracción se recorta a [0,1] y aguanta un total cero', () {
    const total = Duration(minutes: 20);
    expect(AroCuentaAtras.fraccion(total, total), 1);
    expect(AroCuentaAtras.fraccion(const Duration(minutes: 5), total), 0.25);
    expect(AroCuentaAtras.fraccion(const Duration(minutes: 30), total), 1);
    expect(AroCuentaAtras.fraccion(const Duration(seconds: -1), total), 0);
    expect(AroCuentaAtras.fraccion(total, Duration.zero), 0);
  });

  testWidgets('construye en las tres identidades con el aro de la identidad', (
    tester,
  ) async {
    usarCacheLapiz = false;
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(
        montar(
          const AroCuentaAtras(
            restante: Duration(minutes: 10),
            total: Duration(minutes: 40),
            tamano: 200,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AroCuentaAtras)),
        const Size(200, 200),
        reason: codigo,
      );
      final aro = tester.widget<AnilloIdentidad>(find.byType(AnilloIdentidad));
      expect(aro.pct, 0.25, reason: codigo);
      expect(aro.tamano, 200, reason: codigo);
      expect(find.text('10:00'), findsOneWidget, reason: codigo);
      expect(tester.takeException(), isNull, reason: codigo);
    }
  });

  testWidgets('el lector oye los minutos que faltan, no la cifra', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      montar(
        const AroCuentaAtras(
          restante: Duration(minutes: 24, seconds: 30),
          total: Duration(minutes: 25),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Quedan 25 minutos'), findsOne);
    expect(find.semantics.byLabel('24:30'), findsNothing);

    await tester.pumpWidget(
      montar(
        const AroCuentaAtras(
          restante: Duration(seconds: 40),
          total: Duration(minutes: 25),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('1 minute left'), findsOne);
    semantica.dispose();
  });

  testWidgets('pinta lo que se le ponga en el centro, encima de la cifra', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(
        const AroCuentaAtras(
          restante: Duration(minutes: 5),
          total: Duration(minutes: 25),
          centro: Icon(Icons.star, key: ValueKey('centro')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final centro = tester.getCenter(find.byKey(const ValueKey('centro')));
    final cifra = tester.getCenter(find.text('05:00'));
    expect(centro.dy, lessThan(cifra.dy));
  });
}
