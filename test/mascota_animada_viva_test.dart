import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/widgets/mascota_animada_viva.dart';

/// La reacción de `MascotaAnimadaViva` (T-051): un aviso desde fuera lanza el
/// mismo aplastón que el toque.
///
/// El aplastón se ve en el `Transform` que escala desde la base: en reposo
/// estira igual en X que en Y (sólo respira); aplastada, ensancha en X y
/// encoge en Y.
void main() {
  /// Lo que escala en X menos lo que escala en Y. Cero si no está aplastada.
  double aplastamiento(WidgetTester tester) {
    final t = tester.widget<Transform>(
      find.byWidgetPredicate(
        (w) => w is Transform && w.alignment == Alignment.bottomCenter,
      ),
    );
    return t.transform.entry(0, 0) - t.transform.entry(1, 1);
  }

  Widget montar({
    required Listenable? reaccion,
    bool sinAnimaciones = false,
    VoidCallback? onToque,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: sinAnimaciones),
      child: Center(
        child: MascotaAnimadaViva(
          fase: 'CRIA',
          estado: 'feliz',
          tamano: 100,
          reaccion: reaccion,
          onToque: onToque,
        ),
      ),
    ),
  );

  testWidgets('cada aviso la aplasta, sin llamar a onToque ni pedir '
      'permiteToque', (tester) async {
    final reaccion = ValueNotifier(0);
    addTearDown(reaccion.dispose);
    var toques = 0;
    await tester.pumpWidget(
      montar(reaccion: reaccion, onToque: () => toques++),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester), moreOrLessEquals(0));

    reaccion.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester).abs(), greaterThan(0.01));
    expect(toques, 0);

    // Acabado el rebote, vuelve a reposo; y un segundo aviso, otra vez.
    await tester.pump(const Duration(seconds: 1));
    expect(aplastamiento(tester), moreOrLessEquals(0));
    reaccion.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester).abs(), greaterThan(0.01));
  });

  testWidgets('con «reducir movimiento», no se mueve', (tester) async {
    final reaccion = ValueNotifier(0);
    addTearDown(reaccion.dispose);
    await tester.pumpWidget(montar(reaccion: reaccion, sinAnimaciones: true));

    reaccion.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester), moreOrLessEquals(0));
  });

  testWidgets('al cambiar de aviso escucha el nuevo y deja el viejo', (
    tester,
  ) async {
    final viejo = ValueNotifier(0);
    final nuevo = ValueNotifier(0);
    addTearDown(viejo.dispose);
    addTearDown(nuevo.dispose);
    await tester.pumpWidget(montar(reaccion: viejo));
    await tester.pumpWidget(montar(reaccion: nuevo));
    await tester.pump(const Duration(milliseconds: 100));

    viejo.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester), moreOrLessEquals(0));

    nuevo.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(aplastamiento(tester).abs(), greaterThan(0.01));
  });

  testWidgets('al desmontarse se da de baja', (tester) async {
    final reaccion = ValueNotifier(0);
    addTearDown(reaccion.dispose);
    await tester.pumpWidget(montar(reaccion: reaccion));
    await tester.pumpWidget(const SizedBox());

    // Si siguiera suscrita, esto animaría un controlador ya liberado.
    reaccion.value++;
    // ignore: invalid_use_of_protected_member
    expect(reaccion.hasListeners, isFalse);
  });
}
