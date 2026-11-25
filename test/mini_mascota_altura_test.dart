import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/widgets/check_circular.dart';
import 'package:norday_flutter_core/widgets/mini_mascota.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T-071a: `MiniMascota` usa toda la altura del área, su franja derecha es
/// más estrecha y la posición guardada con el formato viejo no se mueve.
const _area = Size(400, 800);

Future<void> _montar(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Widget? debajo,
}) async {
  // La ventana mide lo mismo que el área, para que todo caiga a la vista y la
  // lista llegue al mismo borde.
  tester.view.physicalSize = _area;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
      supportedLocales: NordayCoreLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: _area, disableAnimations: true),
        child: Stack(
          children: [
            ?debajo,
            const MiniMascota(usuarioId: 7, areaSize: _area),
          ],
        ),
      ),
    ),
  );
  // La primera lectura de la mascota (cliente HTTP, que falla con 400) tarda
  // algo de tiempo real: se espera a que Nori esté montada.
  for (
    var i = 0;
    i < 50 && find.byType(AnimatedScale).evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

/// La caja de 120 de Nori (la que la burbuja calcula y agarra).
Offset _esquina(WidgetTester tester) =>
    tester.getTopLeft(find.byType(AnimatedScale));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('arrastrada hacia arriba llega a la mitad de arriba del área', (
    tester,
  ) async {
    await _montar(tester);

    await tester.drag(find.byType(AnimatedScale), const Offset(0, -2000));
    await tester.pump();

    // Con 0.5 el tope era 412; ahora el margen de 12 y nada más.
    expect(_esquina(tester).dy, 12.0);
    await _desmontar(tester);
  });

  testWidgets('arrastrada abajo se queda a 12 de la barra de abajo', (
    tester,
  ) async {
    await _montar(tester);

    await tester.drag(find.byType(AnimatedScale), const Offset(0, 2000));
    await tester.pump();

    expect(_esquina(tester).dy, _area.height - 120 - 12);
    await _desmontar(tester);
  });

  testWidgets('posición vieja: se pinta en el mismo sitio y se convierte una '
      'sola vez', (tester) async {
    // Formato viejo: abajo a la derecha del todo (mitad de abajo, franja 132).
    // Esquina que se veía: left = 12 + (400-120-24-132) = 136,
    // top = 412 + (800*0.5 - 120 - 24) = 668.
    await _montar(
      tester,
      prefs: {'mini_mascota_dx': 1.0, 'mini_mascota_dy': 1.0},
    );

    expect(_esquina(tester).dx, closeTo(136, 0.01));
    expect(_esquina(tester).dy, closeTo(668, 0.01));
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(MiniMascota.claveFormatoNuevo), isTrue);
    final dxNuevo = prefs.getDouble('mini_mascota_dx')!;
    final dyNuevo = prefs.getDouble('mini_mascota_dy')!;
    expect(dyNuevo, closeTo(1.0, 1e-9));
    expect(dxNuevo, lessThan(1.0));
    await _desmontar(tester);

    // Segundo arranque: lo ya convertido no se vuelve a convertir.
    await _montar(
      tester,
      prefs: {
        'mini_mascota_dx': dxNuevo,
        'mini_mascota_dy': dyNuevo,
        MiniMascota.claveFormatoNuevo: true,
      },
    );
    expect(_esquina(tester).dx, closeTo(136, 0.01));
    expect(_esquina(tester).dy, closeTo(668, 0.01));
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('mini_mascota_dx'), dxNuevo);
    expect(prefs.getDouble('mini_mascota_dy'), dyNuevo);
    await _desmontar(tester);
  });

  testWidgets('posición vieja a media altura: mismo sitio de la pantalla', (
    tester,
  ) async {
    // dy viejo 0.5: top = 412 + 0.5 * 256 = 540.
    await _montar(
      tester,
      prefs: {'mini_mascota_dx': 0.0, 'mini_mascota_dy': 0.5},
    );

    expect(_esquina(tester).dx, closeTo(12, 0.01));
    expect(_esquina(tester).dy, closeTo(540, 0.01));
    await _desmontar(tester);
  });

  testWidgets('a la derecha del todo, 8–16 px a la izquierda de los checks de '
      'Hoy', (tester) async {
    // La maquetación de Hoy: lista con relleno de 16, tarjeta con relleno de
    // 16 y, a la derecha de la fila, un `CheckCircular` de 44. La ventana
    // mide lo mismo que el área, para que la lista llegue al mismo borde.
    final hoy = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Expanded(child: SizedBox(height: 60)),
              const SizedBox(width: 12),
              CheckCircular(
                hecho: false,
                onTap: () {},
                color: Colors.green,
                etiquetaSemantica: 'check',
              ),
            ],
          ),
        ),
      ],
    );
    await _montar(tester, debajo: hoy);

    await tester.drag(find.byType(AnimatedScale), const Offset(2000, 0));
    await tester.pump();

    final cajaCheck = tester.getRect(find.byType(CheckCircular));
    final nori = tester.getRect(find.byType(AnimatedScale));
    final hueco = cajaCheck.left - nori.right;
    expect(hueco, inInclusiveRange(8, 16));
    await _desmontar(tester);
  });
}
