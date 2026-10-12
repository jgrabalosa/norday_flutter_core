import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/theme/mascota_assets.dart';

void main() {
  test('el animo manda sobre el estado', () {
    expect(
      animoDeMascota({'estado': 'feliz', 'animo': 'exultante'}),
      'exultante',
    );
  });

  test('con el animo y el estado distintos, se pinta el animo', () {
    expect(animoDeMascota({'estado': 'triste', 'animo': 'feliz'}), 'feliz');
  });

  test('sin animo, el estado de siempre', () {
    expect(animoDeMascota({'estado': 'dormida'}), 'dormida');
  });

  test('sin animo ni estado, nada', () {
    expect(animoDeMascota({}), isNull);
  });
}
