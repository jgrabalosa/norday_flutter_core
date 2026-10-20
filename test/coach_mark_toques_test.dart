import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/coach_mark.dart';

/// Lo señalado. Debajo hay un elemento que cuenta sus toques en toda la
/// pantalla: si un toque llega ahí, es que atravesó la marca.
const _foco = Rect.fromLTWH(100, 300, 160, 60);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Future<void> montar(
    WidgetTester tester, {
    required CoachMark marca,
    required VoidCallback alTocarFondo,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: alTocarFondo,
                  child: const SizedBox.expand(),
                ),
              ),
              marca,
            ],
          ),
        ),
      ),
    );
    // El velo tiene un pulso que se repite: no se puede usar pumpAndSettle.
    await tester.pump();
  }

  testWidgets('paso con botón: tocar el hueco no llega debajo; el botón sí', (
    tester,
  ) async {
    var fondo = 0;
    var boton = 0;
    await montar(
      tester,
      alTocarFondo: () => fondo++,
      marca: CoachMark(
        foco: _foco,
        titulo: 'Título',
        cuerpo: 'Cuerpo',
        textoBoton: 'Entendido',
        onBoton: () => boton++,
      ),
    );

    await tester.tapAt(_foco.center);
    await tester.pump();
    expect(fondo, 0, reason: 'el hueco de un paso con botón no deja pasar');

    await tester.tap(find.text('Entendido'));
    await tester.pump();
    expect(boton, 1);
    expect(fondo, 0);
  });

  testWidgets('paso de acción: tocar el hueco sí llega debajo', (tester) async {
    var fondo = 0;
    await montar(
      tester,
      alTocarFondo: () => fondo++,
      marca: const CoachMark(foco: _foco, titulo: 'Título', cuerpo: 'Cuerpo'),
    );

    await tester.tapAt(_foco.center);
    await tester.pump();
    expect(fondo, 1);
  });

  testWidgets('paso con botón: tocar fuera del hueco tampoco llega debajo', (
    tester,
  ) async {
    var fondo = 0;
    await montar(
      tester,
      alTocarFondo: () => fondo++,
      marca: CoachMark(
        foco: _foco,
        titulo: 'Título',
        cuerpo: 'Cuerpo',
        textoBoton: 'Entendido',
        onBoton: () {},
      ),
    );

    await tester.tapAt(const Offset(20, 50));
    await tester.pump();
    expect(fondo, 0);
  });
}
