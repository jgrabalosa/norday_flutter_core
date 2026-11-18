import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/terrario_identidad.dart';

/// El terrario nevado (Nori vestida, N-11): con nieve, la capa quieta y los
/// copos en las tres formas; los copos se paran con «reducir animaciones»; y
/// sin nieve, el terrario de siempre, sin la capa ni controlador. Sin golden:
/// lo visual lo mira Quim en el móvil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  const codigos = ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS', 'TEMA_DULCE'];

  Future<void> montar(
    WidgetTester tester, {
    required String codigo,
    required bool nieve,
    bool sinMovimiento = false,
  }) async {
    aplicarIdentidadEquipada(codigo);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: sinMovimiento),
          child: Scaffold(
            body: Center(child: TerrarioIdentidad(ancho: 240, nieve: nieve)),
          ),
        ),
      ),
    );
    // El tema se interpola: se deja acabar sin esperar a los copos.
    await tester.pump(const Duration(seconds: 1));
  }

  final capaQuieta = find.byKey(const ValueKey('terrario_nieve_quieta'));

  bool enMovimiento(WidgetTester tester) =>
      (tester.state(find.byType(CoposCayendo)) as dynamic).enMovimiento as bool;

  for (final codigo in codigos) {
    group(codigo, () {
      testWidgets('sin nieve: el de siempre, sin la capa ni copos', (
        tester,
      ) async {
        await montar(tester, codigo: codigo, nieve: false);

        expect(find.byType(TerrarioIdentidad), findsOneWidget);
        expect(capaQuieta, findsNothing);
        expect(find.byType(CoposCayendo), findsNothing);
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('con nieve: la capa quieta y los copos cayendo', (
        tester,
      ) async {
        await montar(tester, codigo: codigo, nieve: true);

        expect(capaQuieta, findsOneWidget);
        expect(find.byType(CoposCayendo), findsOneWidget);
        expect(enMovimiento(tester), isTrue);
        expect(tester.takeException(), isNull);

        // Desmontar suelta el controlador sin dejar nada vivo.
        await tester.pumpWidget(const SizedBox());
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('con «reducir animaciones»: la nieve se queda y los copos '
          'no se mueven', (tester) async {
        await montar(tester, codigo: codigo, nieve: true, sinMovimiento: true);

        expect(capaQuieta, findsOneWidget);
        expect(find.byType(CoposCayendo), findsOneWidget);
        expect(enMovimiento(tester), isFalse);
        expect(tester.hasRunningAnimations, isFalse);
      });
    });
  }

  test('las fechas de la nieve cruzan de año (1-dic al 6-ene)', () {
    final m = ManifiestoArte.fromJson({
      'version': 1,
      'nieve': {'desde': '2026-12-01', 'hasta': '2027-01-06'},
      'prendas': <String, dynamic>{},
    });
    expect(
      m.nieveActiva(DateTime(2026, 11, 30)),
      isFalse,
      reason: 'el día antes',
    );
    expect(m.nieveActiva(DateTime(2026, 12, 1)), isTrue, reason: 'el primero');
    expect(
      m.nieveActiva(DateTime(2026, 12, 31, 23, 59)),
      isTrue,
      reason: '31-dic',
    );
    expect(m.nieveActiva(DateTime(2027, 1, 1)), isTrue, reason: '1-ene');
    expect(m.nieveActiva(DateTime(2027, 1, 6)), isTrue, reason: 'el último');
    expect(
      m.nieveActiva(DateTime(2027, 1, 7)),
      isFalse,
      reason: 'el siguiente',
    );
  });
}
