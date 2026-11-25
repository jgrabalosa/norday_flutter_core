import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/check_circular.dart';
import 'package:norday_flutter_core/widgets/check_vivo.dart';

/// «El check vivo» (T-018a): la mecánica de los turnos y de la vuelta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    CheckCircular.vivo = true;
    CoordinadorCheckVivo.reiniciar();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Widget montar(Widget child, {bool reducirMovimiento = false}) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reducirMovimiento),
      child: app!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  CheckCircular check(int i, {bool hecho = false, bool tocable = true}) =>
      CheckCircular(
        key: ValueKey('check-$i'),
        hecho: hecho,
        onTap: tocable ? () {} : null,
        color: Colors.green,
      );

  Widget columna(List<Widget> hijos) => Column(children: hijos);

  /// Qué checks están dando la vuelta ahora (su CustomPaint lleva primer plano).
  List<int> dandoVuelta(WidgetTester tester) => [
    for (var i = 0; i < 10; i++)
      if (tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(ValueKey('check-$i')),
              matching: find.byType(CustomPaint),
            ),
          )
          .any((c) => c.foregroundPainter != null))
        i,
  ];

  testWidgets('con vivo a false no hay registro, temporizador ni vuelta', (
    tester,
  ) async {
    CheckCircular.vivo = false;
    await tester.pumpWidget(montar(columna([check(0), check(1)])));
    expect(CoordinadorCheckVivo.registrados, 0);
    expect(CoordinadorCheckVivo.activo, isFalse);
    for (var s = 0; s < 20; s++) {
      await tester.pump(const Duration(seconds: 1));
      expect(dandoVuelta(tester), isEmpty);
    }
  });

  testWidgets('con reducir movimiento nunca hay vuelta ni registro', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(columna([check(0), check(1)]), reducirMovimiento: true),
    );
    expect(CoordinadorCheckVivo.registrados, 0);
    expect(CoordinadorCheckVivo.activo, isFalse);
    for (var s = 0; s < 20; s++) {
      await tester.pump(const Duration(seconds: 1));
      expect(dandoVuelta(tester), isEmpty);
    }
  });

  testWidgets('un check hecho y uno de solo lectura no reciben turno', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(columna([check(0, hecho: true), check(1, tocable: false)])),
    );
    expect(CoordinadorCheckVivo.registrados, 0);
    expect(CoordinadorCheckVivo.activo, isFalse);
    for (var s = 0; s < 20; s++) {
      await tester.pump(const Duration(seconds: 1));
      expect(dandoVuelta(tester), isEmpty);
    }
  });

  testWidgets('con 5 checks, uno cada vez, y en 22 s todos tienen turno', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(columna([for (var i = 0; i < 5; i++) check(i)])),
    );
    expect(CoordinadorCheckVivo.registrados, 5);

    final ordenDeTurnos = <int>[];
    var anterior = <int>[];
    for (var ms = 0; ms <= 22000; ms += 100) {
      final ahora = dandoVuelta(tester);
      expect(ahora.length, lessThanOrEqualTo(1), reason: 'a los $ms ms');
      if (ahora.isNotEmpty && anterior.isEmpty) ordenDeTurnos.add(ahora.first);
      anterior = ahora;
      await tester.pump(const Duration(milliseconds: 100));
    }
    // De arriba abajo y vuelta a empezar: cada uno, una vez, en orden.
    expect(ordenDeTurnos, [0, 1, 2, 3, 4]);
  });

  testWidgets('el turno llega a los 4 s y no a los 3', (tester) async {
    await tester.pumpWidget(montar(columna([check(0)])));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(dandoVuelta(tester), isEmpty);
    await tester.pump(const Duration(seconds: 1)); // 4 s: da el turno
    await tester.pump(); // arranca el ticker
    await tester.pump(const Duration(milliseconds: 100));
    expect(dandoVuelta(tester), [0]);
  });

  testWidgets('la vuelta dura 1 s', (tester) async {
    expect(duracionVueltaCheck, const Duration(milliseconds: 1000));
    expect(duracionVueltaCheck < CoordinadorCheckVivo.cadaTurno, isTrue);
    await tester.pumpWidget(montar(columna([check(0)])));
    await tester.pump(const Duration(seconds: 4)); // da el turno
    await tester.pump(); // arranca el ticker
    await tester.pump(const Duration(milliseconds: 900));
    expect(dandoVuelta(tester), [0]);
    await tester.pump(const Duration(milliseconds: 200));
    expect(dandoVuelta(tester), isEmpty);
  });

  testWidgets('tocar durante una vuelta la corta y completa como siempre', (
    tester,
  ) async {
    var completado = 0;
    await tester.pumpWidget(
      montar(
        CheckCircular(
          key: const ValueKey('check-0'),
          hecho: false,
          onTap: () => completado++,
          color: Colors.green,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(dandoVuelta(tester), [0]);

    await tester.tap(find.byType(CheckCircular));
    await tester.pump();
    expect(completado, 1);
    expect(dandoVuelta(tester), isEmpty);
  });

  testWidgets('al pasar a hecho se da de baja y al deshacer vuelve', (
    tester,
  ) async {
    Widget con(bool hecho) => montar(columna([check(0, hecho: hecho)]));

    await tester.pumpWidget(con(false));
    expect(CoordinadorCheckVivo.registrados, 1);

    await tester.pumpWidget(con(true));
    expect(CoordinadorCheckVivo.registrados, 0);
    expect(CoordinadorCheckVivo.activo, isFalse);

    await tester.pumpWidget(con(false));
    expect(CoordinadorCheckVivo.registrados, 1);
    expect(CoordinadorCheckVivo.activo, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('pasar a hecho en plena vuelta la corta', (tester) async {
    Widget con(bool hecho) => montar(columna([check(0, hecho: hecho)]));
    await tester.pumpWidget(con(false));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(dandoVuelta(tester), [0]);

    await tester.pumpWidget(con(true));
    await tester.pump();
    expect(dandoVuelta(tester), isEmpty);
  });

  testWidgets('al quitar los checks no queda ningún temporizador', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(columna([for (var i = 0; i < 3; i++) check(i)])),
    );
    expect(CoordinadorCheckVivo.activo, isTrue);
    await tester.pump(const Duration(seconds: 4)); // una vuelta en marcha

    await tester.pumpWidget(montar(const SizedBox()));
    expect(CoordinadorCheckVivo.registrados, 0);
    expect(CoordinadorCheckVivo.activo, isFalse);
    // Si quedara un Timer, flutter test falla al terminar este test.
  });

  /// Lleva un check de [codigo] a mitad de su vuelta y devuelve lo pintado.
  Future<RenderObject> aMitadDeVuelta(
    WidgetTester tester,
    String codigo,
  ) async {
    aplicarIdentidadEquipada(codigo);
    await tester.pumpWidget(montar(columna([check(0)])));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(dandoVuelta(tester), [0]);
    return tester.renderObject(
      find
          .descendant(
            of: find.byType(CheckCircular),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
  }

  testWidgets('Neotokyo+: la vuelta es un tramo de luz cian con brillo', (
    tester,
  ) async {
    final pintado = await aMitadDeVuelta(tester, 'TEMA_NEOTOKYO_PLUS');
    final streak = temaEquipadoNotifier.value.streak;
    expect(tester.takeException(), isNull);
    expect(
      pintado,
      paints..something((nombre, args) {
        if (nombre != #drawPath) return false;
        final p = args[1] as Paint;
        return p.maskFilter != null && p.color.toARGB32() != 0
            ? p.color.withValues(alpha: 1).toARGB32() == streak.toARGB32()
            : false;
      }),
    );
  });

  testWidgets('Dulce: la vuelta es un trazo a lápiz sin ningún resplandor', (
    tester,
  ) async {
    final pintado = await aMitadDeVuelta(tester, 'TEMA_DULCE');
    final rosa = temaEquipadoNotifier.value.primaryTrazo;
    expect(rosa, isNot(temaEquipadoNotifier.value.text));
    expect(tester.takeException(), isNull);
    // Ni difuminado ni sombras.
    expect(
      pintado,
      paints..everything((nombre, args) {
        if (nombre == #drawShadow) return false;
        if (nombre == #drawPath || nombre == #drawLine) {
          final p = args.last is Paint ? args.last as Paint : args[1] as Paint;
          return p.maskFilter == null;
        }
        return true;
      }),
    );
    // Y sí hay trazo en el primaryTrazo (rosa), no en el texto.
    expect(
      pintado,
      paints..something((nombre, args) {
        final p = args.whereType<Paint>().firstOrNull;
        return p != null &&
            p.color.withValues(alpha: 1).toARGB32() == rosa.toARGB32();
      }),
    );
  });

  testWidgets('la vuelta pinta en las tres identidades sin salirse', (
    tester,
  ) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(columna([check(0)])));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final tamano = tester.getSize(find.byType(CheckCircular));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(dandoVuelta(tester), [0], reason: codigo);
      expect(tester.getSize(find.byType(CheckCircular)), tamano);
      expect(tester.takeException(), isNull, reason: codigo);
      await tester.pumpWidget(montar(const SizedBox()));
    }
  });
}
