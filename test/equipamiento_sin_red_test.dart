import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/theme/equipamiento.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>> _sinRed(int usuarioId) =>
    Future.error(Exception('sin red'));

List<dynamic> _inventarioEquipando(String codigo) => [
  {
    'equipado': true,
    'producto': {'codigo': codigo},
  },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    aplicarIdentidadEquipada(null);
    Equipamiento.reiniciarParaTest();
  });

  tearDown(Equipamiento.reiniciarParaTest);

  test(
    'fallo de red con copia local: aplica la copia y devuelve null',
    () async {
      SharedPreferences.setMockInitialValues({
        'identidad_equipada_7': 'TEMA_DULCE',
      });
      Equipamiento.obtenerInventario = _sinRed;

      final resultado = await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(resultado, isNull);
      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_DULCE');
    },
  );

  test('fallo de red sin copia local: queda Profundidad', () async {
    SharedPreferences.setMockInitialValues({});
    Equipamiento.obtenerInventario = _sinRed;

    final resultado = await Equipamiento.cargarDeUsuarioSiSePuede(7);

    expect(resultado, isNull);
    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_PROFUNDIDAD');
  });

  test(
    'éxito equipando una identidad: aplica, devuelve true y guarda la copia',
    () async {
      SharedPreferences.setMockInitialValues({});
      Equipamiento.obtenerInventario = (_) async =>
          _inventarioEquipando('TEMA_NEOTOKYO_PLUS');

      final resultado = await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(resultado, isTrue);
      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_NEOTOKYO_PLUS');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('identidad_equipada_7'), 'TEMA_NEOTOKYO_PLUS');
    },
  );

  test('éxito sin identidad equipada: quita la copia local', () async {
    SharedPreferences.setMockInitialValues({
      'identidad_equipada_7': 'TEMA_DULCE',
    });
    Equipamiento.obtenerInventario = (_) async => [];

    final resultado = await Equipamiento.cargarDeUsuarioSiSePuede(7);

    expect(resultado, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('identidad_equipada_7'), isFalse);
  });

  test(
    'falla la primera vez y acierta al reintento: manda el backend',
    () async {
      SharedPreferences.setMockInitialValues({
        'identidad_equipada_7': 'TEMA_DULCE',
      });
      Equipamiento.esperaReintento = const Duration(milliseconds: 10);
      var llamadas = 0;
      Equipamiento.obtenerInventario = (_) async {
        llamadas++;
        if (llamadas == 1) throw Exception('sin red');
        return _inventarioEquipando('TEMA_NEOTOKYO_PLUS');
      };

      final resultado = await Equipamiento.cargarDeUsuarioSiSePuede(7);
      expect(resultado, isNull);
      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_DULCE');

      await Future.delayed(const Duration(milliseconds: 100));

      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_NEOTOKYO_PLUS');
      expect(llamadas, 2);

      // No queda ningún intento programado tras el éxito.
      await Future.delayed(const Duration(milliseconds: 100));
      expect(llamadas, 2);
    },
  );

  test('una copia de otro usuario no se aplica', () async {
    SharedPreferences.setMockInitialValues({
      'identidad_equipada_8': 'TEMA_DULCE',
    });
    Equipamiento.obtenerInventario = _sinRed;

    await Equipamiento.cargarDeUsuarioSiSePuede(7);

    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_PROFUNDIDAD');
  });

  test('un código local que ya no está en el catálogo se ignora', () async {
    SharedPreferences.setMockInitialValues({
      'identidad_equipada_7': 'TEMA_QUE_YA_NO_EXISTE',
    });
    Equipamiento.obtenerInventario = _sinRed;

    await Equipamiento.cargarDeUsuarioSiSePuede(7);

    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_PROFUNDIDAD');
  });
}
