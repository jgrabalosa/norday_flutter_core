import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Dulce es un bloc de papel claro: el fondo, las tarjetas y las hojas son el
/// mismo papel, y solo los dibujan el lápiz y su sombra. Encima, un grano muy
/// suave. Profundidad y Neotokyo+ no cambian en nada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  /// WCAG: la misma cuenta que contraste_test.dart.
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final claro = la > lb ? la : lb;
    final oscuro = la > lb ? lb : la;
    return (claro + 0.05) / (oscuro + 0.05);
  }

  group('tokens de Dulce', () {
    final t = catalogoIdentidades['TEMA_DULCE']!.tokens;

    test(
      'el papel: fondo y tarjeta son el mismo, y el campo algo más oscuro',
      () {
        expect(t.bg, const Color(0xFFFFFCF5));
        expect(t.surface, const Color(0xFFFFFCF5));
        expect(t.surface2, const Color(0xFFF6EFE3));
        // surfaceAlta no se declara en Dulce: hereda surface, que es el papel.
        expect(t.surfaceAlta, const Color(0xFFFFFCF5));
      },
    );

    test('inactivo y aroVacio se recalculan sobre el papel nuevo', () {
      expect(t.inactivo, const Color(0xFFC9ABB9));
      expect(t.aroVacio, const Color(0xFFA57492));
    });

    test(
      'los mínimos de contraste se cumplen sobre bg, surface y surface2',
      () {
        final fondos = {
          'bg': t.bg,
          'surface': t.surface,
          'surface2': t.surface2,
        };
        const texto = {
          'text': 4.5,
          'textMuted': 4.5,
          'successText': 4.5,
          'streakText': 4.5,
          'pointsText': 4.5,
        };
        const trazo = {
          'primaryTrazo': 3.0,
          'success': 3.0,
          'aroVacio': 3.0,
          'streak': 3.0,
        };
        final colores = {
          'text': t.text,
          'textMuted': t.textMuted,
          'successText': t.successText,
          'streakText': t.streakText,
          'pointsText': t.pointsText,
          'primaryTrazo': t.primaryTrazo,
          'success': t.success,
          'aroVacio': t.aroVacio,
          'streak': t.streak,
        };
        for (final minimos in [texto, trazo]) {
          for (final entrada in minimos.entries) {
            for (final fondo in fondos.entries) {
              expect(
                contraste(colores[entrada.key]!, fondo.value),
                greaterThanOrEqualTo(entrada.value),
                reason: '${entrada.key} sobre ${fondo.key}',
              );
            }
          }
        }
        // inactivo es un apagado a propósito: basta con ~2 sobre el fondo.
        expect(contraste(t.inactivo, t.bg), greaterThanOrEqualTo(2.0));
      },
    );
  });

  group('grano de papel', () {
    Widget montar({required Widget capa, Widget? debajo}) => MaterialApp(
      theme: AppTheme.deTema(temaEquipadoNotifier.value),
      home: Scaffold(
        body: Stack(
          children: [
            if (debajo != null) Positioned.fill(child: debajo),
            capa,
          ],
        ),
      ),
    );

    testWidgets('en Dulce pinta algo', (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      await tester.pumpWidget(montar(capa: const GranoPapel()));
      await tester.pump();
      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(GranoPapel),
            matching: find.byType(CustomPaint),
          ),
        ),
        isNot(paintsNothing),
      );
    });

    testWidgets('en Profundidad y Neotokyo+ no pinta nada', (tester) async {
      for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
        aplicarIdentidadEquipada(codigo);
        await tester.pumpWidget(montar(capa: const GranoPapel()));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(GranoPapel),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
          reason: codigo,
        );
      }
    });

    testWidgets('está fuera del árbol semántico y deja pasar los toques', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      var pulsado = 0;
      await tester.pumpWidget(
        montar(
          debajo: Center(
            child: ElevatedButton(
              onPressed: () => pulsado++,
              child: const Text('pulsa'),
            ),
          ),
          capa: const GranoPapel(),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(GranoPapel),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GranoPapel),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );

      await tester.tap(find.text('pulsa'));
      expect(pulsado, 1);
    });
  });

  test('Profundidad y Neotokyo+ no cambian sus tokens de fondo', () {
    final profundidad = catalogoIdentidades['TEMA_PROFUNDIDAD']!.tokens;
    expect(profundidad.bg, const Color(0xFF070D19));
    expect(profundidad.surface, const Color(0xFF1E2E4C));
    expect(profundidad.surface2, const Color(0xFF101B2F));

    final neotokyo = catalogoIdentidades['TEMA_NEOTOKYO_PLUS']!.tokens;
    expect(neotokyo.bg, const Color(0xFF090614));
    expect(neotokyo.surface, const Color(0xFF110B21));
    expect(neotokyo.surface2, const Color(0xFF160F28));
  });
}
