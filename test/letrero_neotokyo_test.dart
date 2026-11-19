import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/capa_constelacion.dart';
import 'package:norday_flutter_core/widgets/capa_letrero.dart';
import 'package:norday_flutter_core/widgets/cierre_del_dia.dart';
import 'package:norday_flutter_core/widgets/fondo_identidad.dart';
import 'package:norday_flutter_core/widgets/letreros.dart';

/// El letrero del día de Neotokyo+ (D-35): el catálogo, sus nombres y la capa
/// que lo pinta. Cómo se ve se comprueba en el móvil; aquí, qué se pinta y
/// cuándo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
  });

  final dia = DateTime(2026, 11, 19);

  group('catálogo', () {
    test(
      'un letrero por cantidad, de 1 a 8, con tantos tubos como hábitos',
      () {
        for (var n = 1; n <= 8; n++) {
          final letrero = catalogoLetreros[n];
          expect(letrero, isNotNull, reason: '$n');
          expect(letrero!.tubos, hasLength(n), reason: '$n');
          for (final tubo in letrero.tubos) {
            expect(tubo.length, greaterThanOrEqualTo(2), reason: '$n');
            for (final p in tubo) {
              expect(p.dx, inInclusiveRange(0, 1), reason: '$n: $p');
              expect(p.dy, inInclusiveRange(0, 1), reason: '$n: $p');
            }
          }
        }
      },
    );

    test('sin hábitos no hay letrero; de 8 en adelante, el de 8', () {
      expect(letreroPara(0), isNull);
      expect(letreroPara(3), same(catalogoLetreros[3]));
      expect(letreroPara(12), same(catalogoLetreros[8]));
    });

    test('ocho nombres distintos en los tres idiomas', () {
      for (final idioma in const ['es', 'en', 'pt']) {
        final l = lookupNordayCoreLocalizations(Locale(idioma));
        final nombres = {for (var n = 1; n <= 8; n++) nombreLetrero(l, n)};
        expect(nombres, hasLength(8), reason: idioma);
        expect(nombres.every((s) => s.trim().isNotEmpty), isTrue);
        expect(nombreLetrero(l, 20), nombreLetrero(l, 8), reason: idioma);
      }
      expect(
        nombreLetrero(lookupNordayCoreLocalizations(const Locale('es')), 3),
        'El gato',
      );
    });

    test('los tubos se encienden en orden, con un solo parpadeo', () {
      // Antes de su turno, apagado; al final, todos a 1.
      expect(luzTuboEnEncendido(0, 3, 0), 0);
      expect(luzTuboEnEncendido(2, 3, 0.3), 0);
      for (var i = 0; i < 3; i++) {
        expect(luzTuboEnEncendido(i, 3, 1), 1, reason: '$i');
      }
      // Un tubo pasa por arriba, baja y vuelve: un parpadeo, no más.
      final ms = duracionEncendidoLetrero(3).inMilliseconds;
      final curva = [
        for (var k = 0; k <= 400; k++) luzTuboEnEncendido(0, 3, (500 + k) / ms),
      ];
      var bajadas = 0;
      for (var k = 1; k < curva.length; k++) {
        if (curva[k] < curva[k - 1] - 0.3) bajadas++;
      }
      expect(bajadas, 1);
      // El zumbido solo multiplica al final, y acaba en 1.
      expect(zumbidoLetrero(3, 0.2), 1);
      expect(zumbidoLetrero(3, 1), 1);
    });
  });

  group('la capa', () {
    Future<void> montar(
      WidgetTester tester, {
      String codigo = 'TEMA_NEOTOKYO_PLUS',
      bool enHoy = true,
      bool sinMovimiento = false,
      VoidCallback? alTocar,
    }) async {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('$codigo$enHoy$sinMovimiento'),
          localizationsDelegates:
              NordayCoreLocalizations.localizationsDelegates,
          supportedLocales: NordayCoreLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: sinMovimiento),
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  TextButton(onPressed: alTocar, child: const Text('debajo')),
                  const CapaCierreDelDia(),
                  CapaProgresoIdentidad(enHoy: enHoy),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    PintorCapaLetrero pintor(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(CapaLetrero),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as PintorCapaLetrero;

    testWidgets('Neotokyo+ pinta el letrero; Profundidad, la constelación', (
      tester,
    ) async {
      publicarProgresoDia(hechos: 1, total: 3, fecha: dia);
      await montar(tester);
      expect(find.byType(CapaLetrero), findsOneWidget);
      expect(find.byType(CapaConstelacion), findsNothing);

      await montar(tester, codigo: 'TEMA_PROFUNDIDAD');
      expect(find.byType(CapaLetrero), findsNothing);
      expect(find.byType(CapaConstelacion), findsOneWidget);

      await montar(tester, codigo: 'TEMA_DULCE');
      expect(find.byType(CapaLetrero), findsNothing);
    });

    testWidgets(
      'de día, un tubo de cristal por hábito hecho y ninguno encendido',
      (tester) async {
        publicarProgresoDia(hechos: 2, total: 5, fecha: dia);
        await montar(tester);
        final p = pintor(tester);
        expect([for (var i = 0; i < 5; i++) p.cristal(i)], [1, 1, 0, 0, 0]);
        expect([for (var i = 0; i < 5; i++) p.luz(i)], everyElement(0));
      },
    );

    testWidgets('al marcar, el tubo nuevo entra con un fundido', (
      tester,
    ) async {
      publicarProgresoDia(hechos: 1, total: 3, fecha: dia);
      await montar(tester);
      publicarProgresoDia(hechos: 2, total: 3, fecha: dia);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final aMedias = pintor(tester).cristal(1);
      expect(aMedias, greaterThan(0));
      expect(aMedias, lessThan(1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(pintor(tester).cristal(1), 1);

      // Al desmarcar, se va.
      publicarProgresoDia(hechos: 1, total: 3, fecha: dia);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(pintor(tester).cristal(1), 0);
    });

    testWidgets(
      'en la ceremonia del cierre se enciende tubo a tubo y se queda',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        await montar(tester);
        var cerrado = false;
        unawaited(
          mostrarCierreDelDia(
            titulo: 'T',
            despedida: 'D',
          ).then((_) => cerrado = true),
        );
        await tester.pump();

        // Poco después del velo, el primero ya ha arrancado y el último no.
        await tester.pump(const Duration(milliseconds: 700));
        expect(pintor(tester).luz(0), greaterThan(0));
        expect(pintor(tester).luz(2), 0);

        await tester.pump(duracionEncendidoLetrero(3));
        final p = pintor(tester);
        expect([for (var i = 0; i < 3; i++) p.luz(i)], everyElement(1));
        expect(p.encendido, 1);

        // Al cerrar la ceremonia, el letrero se queda encendido.
        await tester.pump(const Duration(seconds: 3));
        await tester.tapAt(const Offset(200, 300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(cerrado, isTrue);
        expect(pintor(tester).encendido, 1);
      },
    );

    testWidgets(
      'con el día cerrado sin ceremonia (abrir la app, volver a hoy), '
      'aparece con un fundido, sin parpadear',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        await montar(tester);
        marcarDiaCerrado(true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final p = pintor(tester);
        final luces = [for (var i = 0; i < 3; i++) p.luz(i)];
        expect(luces.first, greaterThan(0));
        expect(luces.first, lessThan(1));
        expect(luces, everyElement(luces.first), reason: 'todos a la vez');

        await tester.pump(const Duration(milliseconds: 400));
        expect(pintor(tester).encendido, 1);
        expect(pintor(tester).luz(2), 1);
      },
    );

    testWidgets('al reabrir el día (deshacer el último) se apaga entero', (
      tester,
    ) async {
      publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
      marcarDiaCerrado(true);
      await montar(tester);
      expect(pintor(tester).luz(2), 1);

      publicarProgresoDia(hechos: 2, total: 3, fecha: dia);
      marcarDiaCerrado(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final p = pintor(tester);
      expect(p.luz(0), greaterThan(0));
      expect(p.luz(0), lessThan(1));
      expect(p.luz(1), p.luz(0), reason: 'todos a la vez');

      await tester.pump(const Duration(milliseconds: 500));
      expect([for (var i = 0; i < 3; i++) pintor(tester).luz(i)], [0, 0, 0]);
      expect(pintor(tester).cristal(2), 0, reason: 'el tubo deshecho se va');
      expect(pintor(tester).cristal(1), 1);
    });

    testWidgets(
      'si se reabre a media ignición, los tubos sin arrancar no aparecen',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        await montar(tester);
        unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(pintor(tester).luz(2), 0);

        marcarDiaCerrado(false);
        await tester.pump();
        for (var k = 0; k < 8; k++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(pintor(tester).luz(2), 0, reason: 'a los ${50 * (k + 1)} ms');
        }
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets(
      'con hoy cerrado, al pasar a otro día el letrero nuevo no se enciende',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        marcarDiaCerrado(true);
        await montar(tester);
        expect(pintor(tester).luz(0), 1);

        // Como la app: primero el progreso del otro día, luego reabrir.
        publicarProgresoDia(
          hechos: 1,
          total: 4,
          fecha: dia.subtract(const Duration(days: 1)),
        );
        marcarDiaCerrado(false);
        await tester.pump();
        for (var k = 0; k < 6; k++) {
          await tester.pump(const Duration(milliseconds: 50));
          final p = pintor(tester);
          expect(
            [for (var i = 0; i < 4; i++) p.luz(i)],
            everyElement(0),
            reason: 'a los ${50 * (k + 1)} ms',
          );
        }
      },
    );

    testWidgets(
      'si cambia el número de hábitos y el día sigue cerrado, vuelve con '
      'el fundido',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        marcarDiaCerrado(true);
        await montar(tester);
        publicarProgresoDia(hechos: 2, total: 2, fecha: dia);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        final p = pintor(tester);
        expect([p.luz(0), p.luz(1)], [1, 1]);
      },
    );

    testWidgets(
      'cambiar de pestaña con el día cerrado no lo vuelve a encender',
      (tester) async {
        publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
        marcarDiaCerrado(true);
        Widget app(bool enHoy) => MaterialApp(
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [CapaProgresoIdentidad(enHoy: enHoy)],
            ),
          ),
        );
        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
        await tester.pumpWidget(app(true));
        await tester.pump();
        expect(pintor(tester).encendido, 1);

        await tester.pumpWidget(app(false));
        await tester.pump();
        expect(pintor(tester).encendido, 0);

        await tester.pumpWidget(app(true));
        await tester.pump();
        expect(pintor(tester).encendido, 1, reason: 'de golpe, sin parpadeo');
        expect(pintor(tester).luz(2), 1);
      },
    );

    testWidgets('fuera de Hoy, el día cerrado no lo enciende', (tester) async {
      publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
      await montar(tester, enHoy: false);
      marcarDiaCerrado(true);
      await tester.pump();
      await tester.pump(duracionEncendidoLetrero(3));
      expect(pintor(tester).encendido, 0);
    });

    testWidgets('montada con el día ya cerrado, sale encendido sin parpadear', (
      tester,
    ) async {
      publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
      marcarDiaCerrado(true);
      await montar(tester);
      expect(pintor(tester).encendido, 1);
    });

    testWidgets('con «reducir movimiento», todo de golpe', (tester) async {
      publicarProgresoDia(hechos: 1, total: 3, fecha: dia);
      await montar(tester, sinMovimiento: true);
      publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
      await tester.pump();
      expect(pintor(tester).cristal(2), 1);
      marcarDiaCerrado(true);
      await tester.pump();
      expect(pintor(tester).encendido, 1);
    });

    testWidgets('no se come los toques de debajo', (tester) async {
      var tocado = false;
      publicarProgresoDia(hechos: 2, total: 3, fecha: dia);
      await montar(tester, alTocar: () => tocado = true);
      await tester.tap(find.text('debajo'), warnIfMissed: false);
      expect(tocado, isTrue);
    });

    testWidgets('se pinta sin errores de 1 a 8, a medias y encendido', (
      tester,
    ) async {
      for (var n = 1; n <= 8; n++) {
        limpiarProgresoDia();
        publicarProgresoDia(hechos: n ~/ 2, total: n, fecha: dia);
        await montar(tester, codigo: 'TEMA_NEOTOKYO_PLUS');
        publicarProgresoDia(hechos: n, total: n, fecha: dia);
        await tester.pump();
        marcarDiaCerrado(true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump(duracionEncendidoLetrero(n));
        expect(tester.takeException(), isNull, reason: '$n');
      }
    });
  });
}
