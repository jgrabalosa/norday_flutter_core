import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/widgets/ramo_dulce.dart';

/// Escribe los ocho ramos como PNG para revisarlos a ojo. Solo corre con
/// NORDAY_RAMOS_PNG apuntando a una carpeta:
///   $env:NORDAY_RAMOS_PNG="C:\Dev\Norday\verif\ramo"; flutter test test/ramo_dulce_png_test.dart
void main() {
  final carpeta = Platform.environment['NORDAY_RAMOS_PNG'];

  testWidgets('escribe los ramos de 1 a 8 como PNG', (tester) async {
    await tester.runAsync(() async {
      for (var n = 1; n <= 8; n++) {
        final grabadora = ui.PictureRecorder();
        final lienzo = Canvas(grabadora);
        // El papel cubre el lienzo entero: se pinta antes de escalar, en
        // píxeles del PNG.
        lienzo.drawRect(
          const Rect.fromLTWH(0, 0, 780, 1080),
          Paint()..color = const Color(0xFFFFFCF5),
        );
        lienzo.scale(3);
        dibujarRamoDulce(lienzo, n, flores: n, atado: true);
        final imagen = await grabadora.endRecording().toImage(780, 1080);
        final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$carpeta${Platform.pathSeparator}dart$n.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    });
  }, skip: carpeta == null);
}
