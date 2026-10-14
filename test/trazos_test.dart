import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/campo_identidad.dart';

/// En Dulce el rosa de relleno no vale como trazo ni como texto: el campo
/// enfocado tiene que usar `primaryTrazo` para el borde y el cursor, y
/// `successText` para la etiqueta que flota.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  testWidgets('el campo de Dulce usa primaryTrazo y successText', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    final t = temaEquipadoNotifier.value;
    final controlador = TextEditingController();
    addTearDown(controlador.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(t),
        home: Scaffold(
          body: CampoIdentidad(controlador: controlador, etiqueta: 'Email'),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.cursorColor, t.primaryTrazo);
    expect(campo.decoration?.floatingLabelStyle?.color, t.successText);

    final caja = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    final borde = (caja.decoration! as BoxDecoration).border! as Border;
    expect(borde.top.color, t.primaryTrazo);
  });
}
