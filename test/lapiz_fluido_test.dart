import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// El lápiz fluido: la caché guarda imágenes (no listas de dibujo), con límite
/// por píxeles; el sombreado acepta el dentro por RRect; la sombra de Dulce va
/// en successText; y el anillo de Nori va a lápiz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  setUp(() {
    usarCacheLapiz = true;
    vaciarCacheLapiz();
  });
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  /// Pinta [pintar] en un CustomPaint de [tamano], centrado y con tamaño fijo.
  Future<void> montar(
    WidgetTester tester,
    void Function(Canvas canvas, Size size) pintar,
    Size tamano,
  ) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox.fromSize(
          size: tamano,
          child: CustomPaint(size: tamano, painter: _Pinta(pintar)),
        ),
      ),
    ),
  );

  group('caché de imágenes', () {
    testWidgets(
      'dos pintadas con la misma clave graban una vez y se reproducen con drawImageRect',
      (tester) async {
        await montar(tester, (c, s) {
          for (var i = 0; i < 2; i++) {
            pintarConCache(
              c,
              'clave',
              const Size(40, 30),
              (cc) => cc.drawRect(
                Offset.zero & const Size(40, 30),
                Paint()..color = Colors.black,
              ),
              desborde: 4,
            );
          }
        }, const Size(40, 30));

        expect(grabacionesLapiz, 1);
        final pintado = tester.renderObject(find.byType(CustomPaint));
        // Lo que se sale de la caja, hasta el desborde, no se corta.
        expect(
          pintado,
          paints..something(
            (n, a) =>
                n == #drawImageRect &&
                a[2] == const Rect.fromLTWH(-4, -4, 48, 38),
          ),
        );
        expect(pintado, paints..everything((n, a) => n != #drawPicture));
      },
    );

    test(
      'la caché sale por píxeles: al pasar el límite, sale la más antigua',
      () {
        final canvas = Canvas(ui.PictureRecorder());
        pintarConCache(canvas, 'primera', const Size(20, 20), (c) {});
        expect(entradasCacheLapiz, 1);

        // Imágenes grandes hasta pasar el límite de píxeles, con margen.
        final densidad =
            ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
        final lado = (200 * densidad).ceil();
        final porImagen = lado * lado;
        final cuantas = limitePixelesCacheLapiz ~/ porImagen + 3;
        for (var i = 0; i < cuantas; i++) {
          pintarConCache(canvas, 'g$i', const Size(200, 200), (c) {});
        }

        expect(pixelesCacheLapiz, lessThanOrEqualTo(limitePixelesCacheLapiz));
        // La primera salió: pintarla otra vez graba de nuevo.
        final antes = grabacionesLapiz;
        pintarConCache(canvas, 'primera', const Size(20, 20), (c) {});
        expect(grabacionesLapiz, antes + 1);
      },
    );
  });

  group('sombreado con dentro', () {
    testWidgets(
      'con dentro, ninguna raya cae a la derecha aunque la zona sea entera',
      (tester) async {
        usarCacheLapiz = false;
        await montar(
          tester,
          (c, s) => pintarSombreado(
            c,
            Path()..addRect(Offset.zero & s),
            color: Colors.black,
            separacion: 3,
            semilla: 3,
            dentro: (p) => p.dx < 50,
          ),
          const Size(100, 60),
        );
        final pintado = tester.renderObject(find.byType(CustomPaint));
        expect(pintado, isNot(paintsNothing));
        expect(
          pintado,
          paints..everything((n, a) {
            if (n != #drawLine) return true;
            final x = a[0] as Offset;
            final y = a[1] as Offset;
            // La mitad izquierda, con lo que la curva del filo añade.
            return x.dx <= 52 && y.dx <= 52;
          }),
        );
      },
    );
  });

  testWidgets('en Dulce, la sombra de la tarjeta va en successText', (
    tester,
  ) async {
    usarCacheLapiz = false;
    aplicarIdentidadEquipada('TEMA_DULCE');
    final t = temaEquipadoNotifier.value;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(t),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: SuperficieIdentidad(child: Text('x')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pintado = tester.renderObject(
      find.descendant(
        of: find.byType(SuperficieIdentidad),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      pintado,
      paints..something(
        (n, a) =>
            n == #drawLine &&
            ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                (t.successText.toARGB32() & 0xFFFFFF),
      ),
    );
  });

  group('anillo de Nori', () {
    testWidgets(
      'en Dulce, el anillo va a lápiz: sin arco liso ni perdigón blanco',
      (tester) async {
        usarCacheLapiz = false;
        aplicarIdentidadEquipada('TEMA_DULCE');
        const color = Color(0xFFFF6FA5);
        await tester.pumpWidget(
          MaterialApp(
            home: const Scaffold(
              body: Center(
                child: AnilloIdentidad(tamano: 64, pct: 0.6, color: color),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pintado = tester.renderObject(
          find.descendant(
            of: find.byType(AnilloIdentidad),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(pintado, paints..everything((n, a) => n != #drawArc));
        expect(
          pintado,
          paints..everything(
            (n, a) =>
                !(n == #drawCircle &&
                    ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) == 0xFFFFFF),
          ),
        );
        expect(
          pintado,
          paints..something(
            (n, a) =>
                n == #drawLine &&
                ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                    (color.toARGB32() & 0xFFFFFF),
          ),
        );
      },
    );

    testWidgets('en Profundidad y Neotokyo+, el anillo sigue dibujando arcos', (
      tester,
    ) async {
      usarCacheLapiz = false;
      for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
        aplicarIdentidadEquipada(codigo);
        await tester.pumpWidget(
          MaterialApp(
            home: const Scaffold(
              body: Center(child: AnilloIdentidad(tamano: 64, pct: 0.6)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final pintado = tester.renderObject(
          find.descendant(
            of: find.byType(AnilloIdentidad),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(
          pintado,
          paints..something((n, a) => n == #drawArc),
          reason: codigo,
        );
      }
    });
  });
}

class _Pinta extends CustomPainter {
  _Pinta(this.pintar);

  final void Function(Canvas canvas, Size size) pintar;

  @override
  void paint(Canvas canvas, Size size) => pintar(canvas, size);

  @override
  bool shouldRepaint(_Pinta viejo) => true;
}
