import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/theme/equipamiento.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>> _sinRed(int usuarioId) =>
    Future.error(Exception('sin red'));

Map<String, dynamic> _item(
  int id,
  String codigo,
  String? categoria, {
  bool equipado = true,
}) => {
  'usuarioProductoId': id,
  'equipado': equipado,
  'producto': {'codigo': codigo, 'categoria': ?categoria},
};

Future<Map<String, String>?> _copia(int usuarioId) async {
  final prefs = await SharedPreferences.getInstance();
  final texto = prefs.getString('prendas_equipadas_$usuarioId');
  if (texto == null) return null;
  return Map<String, String>.from(jsonDecode(texto) as Map);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final llamadas = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    aplicarIdentidadEquipada(null);
    aplicarPrendasEquipadas(const {});
    Equipamiento.reiniciarParaTest();
    llamadas.clear();
    Equipamiento.equiparEnBackend = (u, p) async {
      llamadas.add('equipar $u $p');
      return const [];
    };
    Equipamiento.desequiparEnBackend = (u, p) async {
      llamadas.add('desequipar $u $p');
    };
  });

  tearDown(Equipamiento.reiniciarParaTest);

  group('carga del inventario', () {
    test(
      'con prendas: cada sitio con su código, y la identidad igual',
      () async {
        Equipamiento.obtenerInventario = (_) async => [
          _item(1, 'TEMA_DULCE', 'Tema'),
          _item(2, 'PRENDA_GORRO_LANA', 'Cabeza'),
          _item(3, 'PRENDA_BUFANDA', 'Cuerpo'),
          _item(4, 'PRENDA_GORRO_NOEL', 'Cabeza', equipado: false),
        ];

        await Equipamiento.cargarDeUsuario(7);

        expect(prendasEquipadasNotifier.value, {
          'Cabeza': 'PRENDA_GORRO_LANA',
          'Cuerpo': 'PRENDA_BUFANDA',
        });
        expect(identidadEquipadaNotifier.value.codigo, 'TEMA_DULCE');
        expect(await _copia(7), {
          'Cabeza': 'PRENDA_GORRO_LANA',
          'Cuerpo': 'PRENDA_BUFANDA',
        });
      },
    );

    test('sin prendas: vacío, aunque antes llevara algo', () async {
      aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});
      Equipamiento.obtenerInventario = (_) async => [
        _item(1, 'TEMA_DULCE', 'Tema'),
      ];

      await Equipamiento.cargarDeUsuario(7);

      expect(prendasEquipadasNotifier.value, isEmpty);
    });

    test('inventario antiguo, sin categoría o con un sitio que no existe: '
        'vacío y sin errores', () async {
      Equipamiento.obtenerInventario = (_) async => [
        _item(1, 'TEMA_DULCE', null),
        _item(2, 'PRENDA_GORRO_LANA', null),
        _item(3, 'PRENDA_CALCETINES', 'Pies'),
        {'equipado': true},
        {'equipado': true, 'producto': null},
      ];

      await Equipamiento.cargarDeUsuario(7);

      expect(prendasEquipadasNotifier.value, isEmpty);
      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_DULCE');
    });

    test('dos equipadas en el mismo sitio (datos rotos): gana la de id más '
        'alto, como la limpieza de T-023', () async {
      Equipamiento.obtenerInventario = (_) async => [
        _item(9, 'PRENDA_GORRO_NOEL', 'Cabeza'),
        _item(5, 'PRENDA_GORRO_LANA', 'Cabeza'),
      ];

      await Equipamiento.cargarDeUsuario(7);

      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_NOEL'});
    });

    test('lo que dice el backend corrige la copia local', () async {
      SharedPreferences.setMockInitialValues({
        'prendas_equipadas_7': jsonEncode({'Cabeza': 'PRENDA_GORRO_LANA'}),
      });
      Equipamiento.obtenerInventario = (_) async => [
        _item(2, 'PRENDA_GORRO_NOEL', 'Cabeza'),
      ];

      await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_NOEL'});
      expect(await _copia(7), {'Cabeza': 'PRENDA_GORRO_NOEL'});
    });
  });

  group('sin red', () {
    test('aplica la copia local del usuario', () async {
      SharedPreferences.setMockInitialValues({
        'prendas_equipadas_7': jsonEncode({
          'Cabeza': 'PRENDA_GORRO_LANA',
          'Cuerpo': 'PRENDA_BUFANDA',
        }),
      });
      Equipamiento.obtenerInventario = _sinRed;

      await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(prendasEquipadasNotifier.value, {
        'Cabeza': 'PRENDA_GORRO_LANA',
        'Cuerpo': 'PRENDA_BUFANDA',
      });
    });

    test(
      'la copia de otro usuario no se aplica: Nori queda sin nada',
      () async {
        SharedPreferences.setMockInitialValues({
          'prendas_equipadas_8': jsonEncode({'Cabeza': 'PRENDA_GORRO_LANA'}),
        });
        aplicarPrendasEquipadas({'Cuerpo': 'PRENDA_BUFANDA'});
        Equipamiento.obtenerInventario = _sinRed;

        await Equipamiento.cargarDeUsuarioSiSePuede(7);

        expect(prendasEquipadasNotifier.value, isEmpty);
      },
    );

    test('una copia corrupta se ignora, sin errores', () async {
      SharedPreferences.setMockInitialValues({
        'prendas_equipadas_7': '{esto no es json',
      });
      Equipamiento.obtenerInventario = _sinRed;

      await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(prendasEquipadasNotifier.value, isEmpty);
    });

    test('de la copia solo valen los sitios que existen', () async {
      SharedPreferences.setMockInitialValues({
        'prendas_equipadas_7': jsonEncode({
          'Cabeza': 'PRENDA_GORRO_LANA',
          'Pies': 'PRENDA_CALCETINES',
          'Cuerpo': 42,
        }),
      });
      Equipamiento.obtenerInventario = _sinRed;

      await Equipamiento.cargarDeUsuarioSiSePuede(7);

      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    });
  });

  group('equipar y desequipar', () {
    test('equipar: llama al backend, la pone y guarda la copia', () async {
      await Equipamiento.equiparPrenda(7, 21, 'PRENDA_GORRO_LANA', 'Cabeza');

      expect(llamadas, ['equipar 7 21']);
      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
      expect(await _copia(7), {'Cabeza': 'PRENDA_GORRO_LANA'});
    });

    test('otra en el mismo sitio sustituye a la anterior; el otro sitio no '
        'cambia', () async {
      aplicarPrendasEquipadas({
        'Cabeza': 'PRENDA_GORRO_LANA',
        'Cuerpo': 'PRENDA_BUFANDA',
      });

      await Equipamiento.equiparPrenda(7, 22, 'PRENDA_GORRO_NOEL', 'Cabeza');

      expect(prendasEquipadasNotifier.value, {
        'Cabeza': 'PRENDA_GORRO_NOEL',
        'Cuerpo': 'PRENDA_BUFANDA',
      });
    });

    test(
      'desequipar: llama al backend, quita ese sitio y guarda la copia',
      () async {
        aplicarPrendasEquipadas({
          'Cabeza': 'PRENDA_GORRO_LANA',
          'Cuerpo': 'PRENDA_BUFANDA',
        });

        await Equipamiento.desequiparPrenda(7, 21, 'Cabeza');

        expect(llamadas, ['desequipar 7 21']);
        expect(prendasEquipadasNotifier.value, {'Cuerpo': 'PRENDA_BUFANDA'});
        expect(await _copia(7), {'Cuerpo': 'PRENDA_BUFANDA'});
      },
    );

    test('si el backend falla al equipar, no cambia nada', () async {
      SharedPreferences.setMockInitialValues({
        'prendas_equipadas_7': jsonEncode({'Cabeza': 'PRENDA_GORRO_LANA'}),
      });
      aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});
      Equipamiento.equiparEnBackend = (_, _) => Future.error(Exception('500'));

      await expectLater(
        Equipamiento.equiparPrenda(7, 22, 'PRENDA_GORRO_NOEL', 'Cabeza'),
        throwsException,
      );

      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
      expect(await _copia(7), {'Cabeza': 'PRENDA_GORRO_LANA'});
    });

    test('si el backend falla al desequipar, no cambia nada', () async {
      aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});
      Equipamiento.desequiparEnBackend = (_, _) =>
          Future.error(Exception('500'));

      await expectLater(
        Equipamiento.desequiparPrenda(7, 21, 'Cabeza'),
        throwsException,
      );

      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    });

    test('un sitio que no existe se rechaza sin llamar al backend', () async {
      await expectLater(
        Equipamiento.equiparPrenda(7, 30, 'PRENDA_CALCETINES', 'Pies'),
        throwsArgumentError,
      );
      await expectLater(
        Equipamiento.desequiparPrenda(7, 30, 'Pies'),
        throwsArgumentError,
      );

      expect(llamadas, isEmpty);
      expect(prendasEquipadasNotifier.value, isEmpty);
    });

    test('equipar una prenda no toca la identidad', () async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');

      await Equipamiento.equiparPrenda(7, 21, 'PRENDA_GORRO_LANA', 'Cabeza');

      expect(identidadEquipadaNotifier.value.codigo, 'TEMA_NEOTOKYO_PLUS');
    });
  });

  test('el notifier solo avisa si cambia lo puesto', () {
    var avisos = 0;
    void escuchar() => avisos++;
    prendasEquipadasNotifier.addListener(escuchar);
    addTearDown(() => prendasEquipadasNotifier.removeListener(escuchar));

    aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});
    aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});

    expect(avisos, 1);
  });

  test('lo publicado no se puede modificar desde fuera', () {
    aplicarPrendasEquipadas({'Cabeza': 'PRENDA_GORRO_LANA'});

    expect(
      () => prendasEquipadasNotifier.value['Cuerpo'] = 'PRENDA_BUFANDA',
      throwsUnsupportedError,
    );
  });
}
