import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/superficie_identidad.dart';

/// En Neotokyo+ la tarjeta y el fondo son casi iguales (1.04): el filo rosa es
/// lo único que dibuja una tarjeta que se toca, y a 0.55 se quedaba en 2.37.
/// A 0.70 llega a 3.23 sobre el fondo (WCAG 1.4.11).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  testWidgets('el filo de las tarjetas de Neotokyo+ va a 0.70', (tester) async {
    aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
    final t = temaEquipadoNotifier.value;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(t),
        home: const Scaffold(body: SuperficieIdentidad(child: Text('x'))),
      ),
    );
    final caja = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SuperficieIdentidad),
            matching: find.byType(Container),
          )
          .first,
    );
    final forma = (caja.decoration! as ShapeDecoration).shape as BordeChaflan;
    expect(forma.side.color, t.primary.withValues(alpha: 0.70));
  });
}
