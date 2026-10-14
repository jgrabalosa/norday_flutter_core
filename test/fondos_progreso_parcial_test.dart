import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/fondo_identidad.dart';

/// Que los tres fondos aguanten un avance a medias y el paso a una unidad
/// entera más, con la animación de entrada de Profundidad incluida. Cómo se
/// ve se comprueba en el móvil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
  });

  testWidgets('los fondos pintan un avance a medias en las tres identidades', (
    tester,
  ) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      publicarProgresoDia(
        hechos: 0,
        total: 3,
        fecha: DateTime(2026, 10, 12),
        avance: 0.42,
      );
      await tester.pumpWidget(
        MaterialApp(
          // Una app nueva por identidad: sin interpolar temas entre vueltas.
          key: ValueKey(codigo),
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          home: const Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [FondoIdentidad(), CapaProgresoIdentidad(enHoy: true)],
            ),
          ),
        ),
      );
      await tester.pump();

      // De una entera a dos: en Profundidad, la segunda entra volando.
      publicarProgresoDia(
        hechos: 1,
        total: 3,
        fecha: DateTime(2026, 10, 12),
        avance: 0.75,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull, reason: codigo);
    }
  });

  Widget montar(String codigo, {bool sinMovimiento = false}) => MaterialApp(
    key: ValueKey('$codigo-$sinMovimiento'),
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: sinMovimiento),
      child: const Scaffold(
        body: Stack(fit: StackFit.expand, children: [FondoIdentidad()]),
      ),
    ),
  );

  testWidgets('al marcar, la ciudad y las burbujas hacen su gesto y acaban', (
    tester,
  ) async {
    for (final codigo in ['TEMA_NEOTOKYO_PLUS', 'TEMA_DULCE']) {
      aplicarIdentidadEquipada(codigo);
      final fecha = DateTime(2026, 10, 14);
      publicarProgresoDia(hechos: 1, total: 3, fecha: fecha, avance: 1 / 3);
      await tester.pumpWidget(montar(codigo));
      await tester.pump();

      publicarProgresoDia(hechos: 2, total: 3, fecha: fecha, avance: 2 / 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue, reason: codigo);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse, reason: codigo);
      expect(tester.takeException(), isNull, reason: codigo);
    }
  });

  testWidgets('sin gesto al cambiar de día ni con «Quitar animaciones»', (
    tester,
  ) async {
    for (final codigo in ['TEMA_NEOTOKYO_PLUS', 'TEMA_DULCE']) {
      aplicarIdentidadEquipada(codigo);
      publicarProgresoDia(
        hechos: 1,
        total: 3,
        fecha: DateTime(2026, 10, 13),
        avance: 1 / 3,
      );
      await tester.pumpWidget(montar(codigo));
      await tester.pump();

      // Otro día con más avance: no es marcar, es moverse por la tira.
      publicarProgresoDia(
        hechos: 3,
        total: 3,
        fecha: DateTime(2026, 10, 14),
        avance: 1,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse, reason: '$codigo, día');

      // Marcar con «Quitar animaciones».
      final fecha = DateTime(2026, 10, 15);
      publicarProgresoDia(hechos: 0, total: 3, fecha: fecha, avance: 0);
      await tester.pumpWidget(montar(codigo, sinMovimiento: true));
      await tester.pump();
      publicarProgresoDia(hechos: 1, total: 3, fecha: fecha, avance: 1 / 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse, reason: '$codigo, sin mov.');
    }
  });
}
