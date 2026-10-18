import 'dart:math';
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// La calidad del lápiz: trazo con presión y tres pasadas, sombreado con
/// intensidad y caché de dibujos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    usarCacheLapiz = true;
    vaciarCacheLapiz();
  });

  /// Pinta [pintar] dentro de un CustomPaint de [tamano].
  Future<void> montar(
    WidgetTester tester,
    void Function(Canvas canvas, Size size) pintar, {
    Size tamano = const Size(100, 60),
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      // Con el tamaño fijado: sin esto, la superficie de test (800 × 600)
      // manda sobre el tamaño pedido.
      child: Center(
        child: SizedBox.fromSize(
          size: tamano,
          child: CustomPaint(size: tamano, painter: _Pinta(pintar)),
        ),
      ),
    ),
  );

  /// Las llamadas de dibujo del último pintado, en texto.
  List<String> llamadas(WidgetTester tester) {
    final lista = <String>[];
    expect(
      tester.renderObject(find.byType(CustomPaint)),
      paints..everything((nombre, args) {
        lista.add('$nombre ${args.join(' ')}');
        return true;
      }),
    );
    return lista;
  }

  /// Suma de las longitudes de los drawLine del último pintado.
  double longitudDeLineas(WidgetTester tester) {
    var total = 0.0;
    expect(
      tester.renderObject(find.byType(CustomPaint)),
      paints..everything((nombre, args) {
        if (nombre == #drawLine) {
          total += ((args[1] as Offset) - (args[0] as Offset)).distance;
        }
        return true;
      }),
    );
    return total;
  }

  Path rectRedondeado(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(10)),
    );

  testWidgets('el trazo es determinista: misma semilla, mismas llamadas', (
    tester,
  ) async {
    await montar(
      tester,
      (c, s) => pintarTrazoLapiz(
        c,
        rectRedondeado(s),
        color: Colors.pink,
        grosor: 2,
        semilla: 7,
      ),
    );
    final primera = llamadas(tester);

    await montar(
      tester,
      (c, s) => pintarTrazoLapiz(
        c,
        rectRedondeado(s),
        color: Colors.pink,
        grosor: 2,
        semilla: 7,
      ),
    );
    final segunda = llamadas(tester);

    await montar(
      tester,
      (c, s) => pintarTrazoLapiz(
        c,
        rectRedondeado(s),
        color: Colors.pink,
        grosor: 2,
        semilla: 8,
      ),
    );
    final otra = llamadas(tester);

    expect(segunda, primera);
    expect(
      primera.where((l) => l.contains('drawLine')).length,
      greaterThan(40),
    );
    expect(otra, isNot(primera));
  });

  testWidgets('en un contorno cerrado, las pasadas se pasan del inicio', (
    tester,
  ) async {
    // Perímetro de un rectángulo de 100x60 con radio 10.
    const perimetro = 2 * 80 + 2 * 40 + 2 * pi * 10;
    await montar(
      tester,
      (c, s) => pintarTrazoLapiz(
        c,
        rectRedondeado(s),
        color: Colors.pink,
        grosor: 2,
        semilla: 7,
      ),
    );
    // Firme y repaso dan ~1,06 vueltas cada uno; la tercera, ~0,35.
    expect(longitudDeLineas(tester) / perimetro, greaterThan(2.41));
  });

  testWidgets('en un contorno abierto no hay pasada de más', (tester) async {
    await montar(
      tester,
      (c, s) => pintarTrazoLapiz(
        c,
        Path()
          ..moveTo(0, 30)
          ..lineTo(100, 30),
        color: Colors.pink,
        grosor: 2,
        semilla: 7,
      ),
    );
    // Firme y repaso, una vuelta cada uno; la tercera, ~0,35.
    expect(longitudDeLineas(tester) / 100, lessThan(2.41));
  });

  testWidgets('el sombreado no pinta donde la intensidad es cero', (
    tester,
  ) async {
    await montar(
      tester,
      (c, s) => pintarSombreado(
        c,
        Path()..addRect(Offset.zero & s),
        color: Colors.black,
        intensidad: (p) => p.dx < 50 ? 1 : 0,
        separacion: 3,
        semilla: 3,
      ),
    );
    expect(
      tester.renderObject(find.byType(CustomPaint)),
      paints
        ..something((nombre, args) => nombre == #drawLine)
        ..everything((nombre, args) {
          if (nombre != #drawLine) return true;
          final a = args[0] as Offset;
          final b = args[1] as Offset;
          // Solo en la mitad izquierda (con el margen del filo y la curva) y
          // dentro de la zona, con 1 px de margen.
          return a.dx <= 52 &&
              b.dx <= 52 &&
              a.dx >= -1 &&
              a.dy >= -1 &&
              a.dy <= 61 &&
              b.dy >= -1 &&
              b.dy <= 61;
        }),
    );
  });

  group('caché de dibujos', () {
    final borde = BordeLapiz(
      radio: 18,
      side: const BorderSide(color: Colors.red, width: 2),
    );

    test('veinte pintadas del mismo borde graban una sola vez', () {
      final canvas = Canvas(PictureRecorder());
      for (var i = 0; i < 20; i++) {
        borde.paint(canvas, const Rect.fromLTWH(0, 0, 36, 36));
      }
      expect(grabacionesLapiz, 1);

      // Otro tamaño, otra grabación.
      borde.paint(canvas, const Rect.fromLTWH(0, 0, 40, 36));
      expect(grabacionesLapiz, 2);
    });

    test('al pasar de 256 claves sale la primera y se vuelve a grabar', () {
      final canvas = Canvas(PictureRecorder());
      const primera = Rect.fromLTWH(0, 0, 36, 36);
      borde.paint(canvas, primera);
      expect(grabacionesLapiz, 1);

      for (var w = 40; w < 40 + 256; w++) {
        borde.paint(canvas, Rect.fromLTWH(0, 0, w.toDouble(), 36));
      }
      final despues = grabacionesLapiz;
      expect(despues, 257);

      // La primera salió de la caché: pintarla otra vez graba de nuevo.
      borde.paint(canvas, primera);
      expect(grabacionesLapiz, despues + 1);
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
