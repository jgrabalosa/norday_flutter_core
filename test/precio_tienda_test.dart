import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/models/precio_tienda.dart';

void main() {
  Map<String, dynamic> producto({Object? ofertas, Object? precio = 300}) => {
    'precio': precio,
    'categoria': 'Cabeza',
    'ofertas': ?ofertas,
  };

  final navidad = [
    {'desde': '2026-12-01', 'hasta': '2027-01-06', 'precio': 0},
  ];

  test('los dos extremos de la oferta cuentan, a cualquier hora', () {
    final primero = precioEnTienda(
      producto(ofertas: navidad),
      DateTime(2026, 12, 1, 0, 1),
    );
    final ultimo = precioEnTienda(
      producto(ofertas: navidad),
      DateTime(2027, 1, 6, 23, 59),
    );
    expect(primero!.precio, 0);
    expect(primero.gratis, isTrue);
    expect(primero.hasta, DateTime(2027, 1, 6));
    expect(ultimo!.precio, 0);
    expect(
      precioEnTienda(producto(ofertas: navidad), DateTime(2027, 1, 7)),
      isNull,
    );
    expect(
      precioEnTienda(producto(ofertas: navidad), DateTime(2026, 11, 30)),
      isNull,
    );
  });

  test('sin ofertas, o con la lista vacía, el precio de siempre', () {
    final sin = precioEnTienda(producto(), DateTime(2026, 12, 10))!;
    expect(sin.precio, 300);
    expect(sin.hasta, isNull);
    expect(
      precioEnTienda(
        producto(ofertas: const []),
        DateTime(2026, 12, 10),
      )!.precio,
      300,
    );
  });

  test('una oferta que no se entiende no cuenta', () {
    final mal = [
      {'desde': '1-12-2026', 'hasta': '2027-01-06', 'precio': 0},
      {'desde': '2026-12-01', 'hasta': null, 'precio': 0},
      {'desde': '2026-12-01', 'hasta': '2027-01-06', 'precio': 'cero'},
      'nada',
    ];
    final p = precioEnTienda(producto(ofertas: mal), DateTime(2026, 12, 10))!;
    expect(p.precio, 300);
    expect(p.hasta, isNull);
  });

  test('esPrenda: solo las categorías de los sitios', () {
    expect(esPrenda({'categoria': 'Cabeza'}), isTrue);
    expect(esPrenda({'categoria': 'Cuerpo'}), isTrue);
    expect(esPrenda({'categoria': 'Tema'}), isFalse);
    expect(esPrenda({}), isFalse);
  });
}
