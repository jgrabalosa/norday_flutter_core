import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/check_circular.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';
import 'package:norday_flutter_core/widgets/superficie_identidad.dart';

/// Dulce pasa a parecer dibujada a lápiz de color: el borde, la sombra y el
/// check. Profundidad y Neotokyo+ no cambian en nada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(body: Center(child: child)),
  );

  ShapeDecoration decoracion(WidgetTester tester) {
    final caja = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SuperficieIdentidad),
            matching: find.byType(Container),
          )
          .first,
    );
    return caja.decoration! as ShapeDecoration;
  }

  /// Si la llamada [nombre] con [args] es un relleno o un trazo de [color].
  /// `drawPath` lleva el `Paint` en el segundo argumento.
  bool dibuja(
    Symbol nombre,
    List<dynamic> args,
    Color color, {
    PaintingStyle? estilo,
  }) {
    if (nombre != #drawPath || args.length < 2 || args[1] is! Paint) {
      return false;
    }
    final pintura = args[1] as Paint;
    // `Colors.green` es un `MaterialColor`, y `==` de `Color` compara el tipo:
    // se compara el valor ARGB.
    return pintura.color.toARGB32() == color.toARGB32() &&
        (estilo == null || pintura.style == estilo);
  }

  group('caminoTembloroso', () {
    test('es determinista y se aparta poco del original', () {
      final recta = Path()
        ..moveTo(0, 0)
        ..lineTo(200, 0);

      List<Offset> puntosDe(Path p) => [
        for (final m in p.computeMetrics())
          for (var d = 0.0; d <= m.length; d += 2)
            m.getTangentForOffset(d)!.position,
      ];

      final a = puntosDe(caminoTembloroso(recta, semilla: 7));
      final b = puntosDe(caminoTembloroso(recta, semilla: 7));
      expect(b, a);

      final otra = puntosDe(caminoTembloroso(recta, semilla: 8));
      expect(otra, isNot(a));

      // El temblor sale en perpendicular a una recta horizontal, así que va
      // por `dy`, y no pasa de la amplitud.
      for (final p in a) {
        expect(p.dy.abs(), lessThanOrEqualTo(0.7 + 1e-6));
      }
    });
  });

  group('BordeLapiz', () {
    test('tiene la forma del rectángulo redondeado, sin temblor', () {
      const rect = Rect.fromLTWH(0, 0, 120, 60);
      final lapiz = BordeLapiz(radio: 18).getOuterPath(rect);
      final ref = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ).getOuterPath(rect);

      expect(lapiz.getBounds(), ref.getBounds());
      for (var x = -2.0; x <= 122; x += 3) {
        for (var y = -2.0; y <= 62; y += 3) {
          final p = Offset(x, y);
          expect(lapiz.contains(p), ref.contains(p), reason: '$p');
        }
      }
    });

    testWidgets('sin filo no pinta nada y con filo, sí', (tester) async {
      Widget pintor(ShapeBorder borde) => Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          size: const Size(120, 60),
          painter: _PintaBorde(borde),
        ),
      );

      await tester.pumpWidget(pintor(BordeLapiz(radio: 18)));
      expect(tester.renderObject(find.byType(CustomPaint)), paintsNothing);

      await tester.pumpWidget(
        pintor(
          BordeLapiz(
            radio: 18,
            side: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      );
      expect(
        tester.renderObject(find.byType(CustomPaint)),
        isNot(paintsNothing),
      );
    });
  });

  testWidgets(
    'en Dulce, la superficie tiene borde a lápiz, filo rosa y sin sombra',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      final t = temaEquipadoNotifier.value;

      for (final protagonista in [false, true]) {
        await tester.pumpWidget(
          montar(
            SuperficieIdentidad(
              protagonista: protagonista,
              child: const Text('x'),
            ),
          ),
        );
        final deco = decoracion(tester);
        expect(deco.shape.runtimeType.toString(), 'BordeLapiz');
        final lado = (deco.shape as OutlinedBorder).side;
        expect(
          lado.color,
          t.primaryTrazo,
          reason: 'protagonista=$protagonista',
        );
        expect(lado.width, 1.6, reason: 'protagonista=$protagonista');
        expect(deco.shadows, anyOf(isNull, isEmpty));
      }
    },
  );

  testWidgets('Profundidad y Neotokyo+ no cambian: forma, filo y sombra', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    await tester.pumpWidget(
      montar(const SuperficieIdentidad(child: Text('x'))),
    );
    final glass = decoracion(tester);
    expect(glass.shape, isA<RoundedRectangleBorder>());
    expect((glass.shape as OutlinedBorder).side, BorderSide.none);
    expect(glass.shadows, anyOf(isNull, isEmpty));

    aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
    final t = temaEquipadoNotifier.value;
    await tester.pumpWidget(
      montar(const SuperficieIdentidad(child: Text('x'))),
    );
    final chamfer = decoracion(tester);
    expect(chamfer.shape.runtimeType.toString(), 'BordeChaflan');
    final lado = (chamfer.shape as OutlinedBorder).side;
    expect(lado.color, t.primary.withValues(alpha: 0.70));
    expect(lado.width, 1.2);
    expect(chamfer.shadows, anyOf(isNull, isEmpty));
  });

  testWidgets(
    'el check de Dulce hecho no tiene relleno liso y se pinta en el texto',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      final t = temaEquipadoNotifier.value;

      await tester.pumpWidget(
        montar(CheckCircular(hecho: true, onTap: () {}, color: Colors.green)),
      );
      await tester.pump();

      final pintado = tester.renderObject(
        find.descendant(
          of: find.byType(CheckCircular),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        pintado,
        paints..everything(
          (nombre, args) =>
              !dibuja(nombre, args, Colors.green, estilo: PaintingStyle.fill),
        ),
      );
      expect(
        pintado,
        paints..something((nombre, args) => dibuja(nombre, args, t.text)),
      );
    },
  );

  testWidgets('el check de Profundidad y Neotokyo+ hecho sigue igual', (
    tester,
  ) async {
    for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(
        montar(CheckCircular(hecho: true, onTap: () {}, color: Colors.green)),
      );
      await tester.pump();

      final pintado = tester.renderObject(
        find.descendant(
          of: find.byType(CheckCircular),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        pintado,
        paints..something(
          (nombre, args) =>
              dibuja(nombre, args, Colors.green, estilo: PaintingStyle.fill),
        ),
        reason: codigo,
      );
      expect(
        pintado,
        paints..something((nombre, args) => dibuja(nombre, args, Colors.white)),
        reason: codigo,
      );
    }
  });
}

class _PintaBorde extends CustomPainter {
  _PintaBorde(this.borde);

  final ShapeBorder borde;

  @override
  void paint(Canvas canvas, Size size) =>
      borde.paint(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_PintaBorde viejo) => false;
}
