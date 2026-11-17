import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Nori vestida, N-3: las ilustraciones de Nori son PNG de 1024 × 1024 y,
/// sin decirle nada, Flutter las descodifica enteras (4 MB cada una) aunque
/// se pinten a 48 puntos. Aquí se comprueba que cada sitio donde sale Nori
/// pide la imagen al tamaño en pantalla por la densidad del móvil.
void main() {
  /// El ancho al que se descodifica la (única) imagen que haya en pantalla.
  int? anchoDescodificado(WidgetTester tester) {
    final imagen = tester.widget<Image>(find.byType(Image));
    final proveedor = imagen.image;
    return proveedor is ResizeImage ? proveedor.width : null;
  }

  Widget conDensidad(double densidad, Widget hijo) => MediaQuery(
    data: MediaQueryData(devicePixelRatio: densidad),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: hijo),
    ),
  );

  testWidgets('la miniatura de 48 puntos se descodifica a 48 por la densidad', (
    tester,
  ) async {
    await tester.pumpWidget(
      conDensidad(
        3,
        const ImagenMascota(
          asset: 'assets/mascota/Nori_cria_sonriente.png',
          tamano: 48,
        ),
      ),
    );
    expect(anchoDescodificado(tester), 144);
  });

  testWidgets('nunca se pide más que el original de 1024', (tester) async {
    await tester.pumpWidget(
      conDensidad(
        4,
        const ImagenMascota(
          asset: 'assets/mascota/Nori_cria_sonriente.png',
          tamano: 400,
          margen: 1.25,
        ),
      ),
    );
    expect(anchoDescodificado(tester), ladoOriginalMascota);
  });

  testWidgets(
    'MascotaAnimadaViva deja margen para el estirón de la animación',
    (tester) async {
      await tester.pumpWidget(
        conDensidad(
          2,
          const MediaQuery(
            data: MediaQueryData(devicePixelRatio: 2, disableAnimations: true),
            child: MascotaAnimadaViva(
              fase: 'CRIA',
              estado: 'feliz',
              tamano: 100,
            ),
          ),
        ),
      );
      // 100 puntos × 2 de densidad × 1,25 de margen.
      expect(anchoDescodificado(tester), 250);
    },
  );

  testWidgets('NoriMarca, la del login y el splash, también', (tester) async {
    await tester.pumpWidget(
      conDensidad(
        2,
        const MediaQuery(
          data: MediaQueryData(devicePixelRatio: 2, disableAnimations: true),
          child: NoriMarca(tamano: 80),
        ),
      ),
    );
    expect(anchoDescodificado(tester), 200);
  });

  testWidgets('AvatarUsuario sin avatar pinta a Nori a su tamaño', (
    tester,
  ) async {
    await tester.pumpWidget(conDensidad(3, const AvatarUsuario(radius: 16)));
    // 16 de radio: la imagen mide 24 puntos (radius × 1,5).
    expect(anchoDescodificado(tester), 72);
  });
}
