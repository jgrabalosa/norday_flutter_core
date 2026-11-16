import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Nori canónica (Nori vestida, N-1): los 12 dibujos de Nori separados en
/// cuerpo y brote (`tool/nori_canonica/separar_brote.py`). Es un contrato
/// (`docs/funcionamiento/nori-canonica.md`): las prendas se dibujan sobre
/// esta geometría. Si alguien cambia los originales sin volver a separarlos,
/// o separa mal, salta aquí.
///
/// Las capas aún no van en el `pubspec.yaml` (se declararán con N-9, cuando
/// se pinten), así que se leen del disco y no del bundle.
void main() {
  const fases = ['huevo', 'cria', 'adulto'];
  const estados = ['sonriente', 'dormido', 'triste', 'exultante'];
  const dir = 'assets/mascota';

  /// RGBA sin premultiplicar, de 1024 × 1024.
  Future<Uint8List> pixeles(String ruta) async {
    final codec = await ui.instantiateImageCodec(File(ruta).readAsBytesSync());
    final imagen = (await codec.getNextFrame()).image;
    expect(imagen.width, 1024, reason: ruta);
    expect(imagen.height, 1024, reason: ruta);
    final datos = await imagen.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    return datos!.buffer.asUint8List();
  }

  testWidgets('cuerpo + brote dan el original, salvo unos pocos píxeles', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final fase in fases) {
        for (final estado in estados) {
          final nombre = 'Nori_${fase}_$estado';
          final o = await pixeles('$dir/$nombre.png');
          final c = await pixeles('$dir/canonica/${nombre}_cuerpo.png');
          final b = await pixeles('$dir/canonica/${nombre}_brote.png');
          var distintos = 0, delBrote = 0, enLosDos = 0;
          for (var i = 0; i < o.length; i += 4) {
            if (b[i + 3] > 200) {
              delBrote++;
              if (c[i + 3] > 128) enLosDos++;
            }
            // El brote encima del cuerpo, en premultiplicado y de 0 a 255.
            final ab = b[i + 3] / 255, ac = c[i + 3] / 255;
            final a = ab + ac * (1 - ab);
            var peor = ((a * 255) - o[i + 3]).abs();
            for (var k = 0; k < 3; k++) {
              final montado = b[i + k] * ab + c[i + k] * ac * (1 - ab);
              final original = o[i + k] * o[i + 3] / 255;
              final d = (montado - original).abs();
              if (d > peor) peor = d;
            }
            if (peor > 8) distintos++;
          }
          // Hoy, como mucho 23 (el huevo dormido): el borde donde el tallo
          // entra en la cabeza. De 1.048.576.
          expect(distintos, lessThanOrEqualTo(50), reason: nombre);
          // Y el brote no se ha quedado en el cuerpo: solo lo comparten el
          // tallo y la cabeza rellena debajo (hoy, como mucho 134 píxeles).
          expect(delBrote, greaterThan(5000), reason: nombre);
          expect(enLosDos, lessThanOrEqualTo(300), reason: nombre);
        }
      }
    });
  });

  test(
    'la geometría tiene los 12 estados y el brote se apoya en la cabeza',
    () {
      final geo =
          jsonDecode(File('$dir/canonica/geometria.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(geo['version'], 1);
      expect(geo['lado'], 1024);
      final porEstado = geo['estados'] as Map<String, dynamic>;
      expect(porEstado.length, 12);
      for (final fase in fases) {
        for (final estado in estados) {
          final g = porEstado['${fase}_$estado'] as Map<String, dynamic>;
          final brote = (g['brote'] as List).cast<int>();
          final cuerpo = (g['cuerpo'] as List).cast<int>();
          final anclaje = (g['anclajeBrote'] as List).cast<int>();
          final cabeza = (g['cabezaArriba'] as List).cast<int>();
          final nombre = '${fase}_$estado';
          // El anclaje está dentro de la caja del brote (abajo del todo, salvo
          // con las hojas caídas, que bajan más) y en la misma columna que lo
          // más alto de la cabeza, a pocos píxeles.
          expect(
            anclaje[0],
            inInclusiveRange(brote[0], brote[2]),
            reason: nombre,
          );
          expect(
            anclaje[1],
            inInclusiveRange(brote[1], brote[3]),
            reason: nombre,
          );
          expect(cabeza[0], anclaje[0], reason: nombre);
          expect(
            (anclaje[1] - cabeza[1]).abs(),
            lessThanOrEqualTo(15),
            reason: nombre,
          );
          // El brote empieza por encima del cuerpo.
          expect(brote[1], lessThan(cabeza[1]), reason: nombre);
          expect(cuerpo[3], greaterThan(cabeza[1]), reason: nombre);
        }
      }
    },
  );

  // La pantalla negra (regla 6 del arte: ninguna prenda entra en ella). La
  // máscara sale del cuerpo (`separar_brote.py --solo-pantallas`).
  testWidgets(
    'la pantalla de cada estado es la del cuerpo y su caja, la de la geometría',
    (tester) async {
      await tester.runAsync(() async {
        final geo =
            jsonDecode(File('$dir/canonica/geometria.json').readAsStringSync())
                as Map<String, dynamic>;
        final porEstado = geo['estados'] as Map<String, dynamic>;
        for (final fase in fases) {
          for (final estado in estados) {
            final nombre = 'Nori_${fase}_$estado';
            final m = await pixeles('$dir/canonica/${nombre}_pantalla.png');
            final c = await pixeles('$dir/canonica/${nombre}_cuerpo.png');
            var dentro = 0, oscuros = 0;
            var x0 = 1024, y0 = 1024, x1 = 0, y1 = 0;
            for (var i = 0; i < m.length; i += 4) {
              if (m[i] < 128) continue;
              dentro++;
              final p = i ~/ 4, x = p % 1024, y = p ~/ 1024;
              if (x < x0) x0 = x;
              if (y < y0) y0 = y;
              if (x + 1 > x1) x1 = x + 1;
              if (y + 1 > y1) y1 = y + 1;
              // Del cuerpo (el huevo tiene algún píxel algo translúcido: hoy,
              // alfa 200 como mínimo) y casi toda negra (ojos y boca, dentro).
              expect(c[i + 3], greaterThan(127), reason: nombre);
              if ((c[i] + c[i + 1] + c[i + 2]) / 3 < 70) oscuros++;
            }
            // Hoy, entre 55.000 y 57.000 píxeles por estado.
            expect(dentro, inInclusiveRange(40000, 70000), reason: nombre);
            // Hoy, entre el 69 % (adulto exultante, con los ojos de estrella) y el
            // 91 % de la pantalla es negro.
            expect(oscuros / dentro, greaterThan(0.6), reason: nombre);
            final g = porEstado['${fase}_$estado'] as Map<String, dynamic>;
            expect((g['pantalla'] as List).cast<int>(), [
              x0,
              y0,
              x1,
              y1,
            ], reason: nombre);
            // Debajo de lo alto de la cabeza.
            expect(
              y0,
              greaterThan((g['cabezaArriba'] as List)[1] as int),
              reason: nombre,
            );
          }
        }
      });
    },
  );
}
