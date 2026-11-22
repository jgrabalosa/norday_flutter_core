import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los datos que el core deja para el widget nativo de Nori (T-008b).
///
/// Los seams de `WidgetNori` sustituyen a `home_widget`, que en `flutter test`
/// no tiene plataforma nativa. La lectura de la mascota va por
/// `ApiServiceCore.getMascota` de verdad, con un cliente falso creado dentro de
/// `http.runWithClient` (como `mini_mascota_fase_test.dart`): por eso este
/// fichero vive solo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late http.Response Function() responder;
  final falso = MockClient((_) async => responder());
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  late Map<String, Object?> guardado;
  late List<String> repintados;

  setUp(() {
    SharedPreferences.setMockInitialValues({'usuarioId': 7});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
    guardado = {};
    repintados = [];
    WidgetNori.reiniciarParaTest();
    WidgetNori.guardarClave = (clave, valor) async {
      if (valor == null) {
        guardado.remove(clave);
      } else {
        guardado[clave] = valor;
      }
    };
    WidgetNori.repintar = (nombre) async => repintados.add(nombre);
    WidgetNori.ahora = () => DateTime(2026, 11, 21, 15, 30);
    progresoDiaNotifier.value = ProgresoDia.vacio;
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    IdiomaService.localeNotifier.value = const Locale('es');
    responder = () => http.Response(jsonEncode(_mascota()), 200);
  });

  tearDown(() {
    WidgetNori.reiniciarParaTest();
    progresoDiaNotifier.value = ProgresoDia.vacio;
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    IdiomaService.localeNotifier.value = const Locale('es');
  });

  /// Inicia el servicio y deja pasar lo que escribe al arrancar.
  Future<void> iniciar() async {
    WidgetNori.iniciar(nombreAndroid: 'NoriWidgetProvider');
    await WidgetNori.pendiente;
    guardado.clear();
    repintados.clear();
  }

  test('sin iniciar, nada se guarda ni se repinta', () async {
    await ApiServiceCore.getMascota(7);
    publicarProgresoDia(hechos: 2, total: 5, fecha: DateTime(2026, 11, 21));
    aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
    IdiomaService.localeNotifier.value = const Locale('en');
    await ApiServiceCore.logout();
    await WidgetNori.pendiente;

    expect(guardado, isEmpty);
    expect(repintados, isEmpty);
  });

  test('iniciar deja la identidad y los textos, y repinta', () async {
    WidgetNori.iniciar(nombreAndroid: 'NoriWidgetProvider');
    await WidgetNori.pendiente;

    expect(guardado['nori_identidad'], 'TEMA_PROFUNDIDAD');
    expect(guardado['nori_texto_sin_sesion'], 'Inicia sesión para ver tu día');
    expect(guardado, isNot(contains('nori_sesion')));
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('una respuesta de la mascota guarda fase, ánimo, nombre, dibujos y '
      'animosSiguientes', () async {
    await iniciar();
    final siguientes = [
      {'fecha': '2026-11-22', 'animo': 'dormida'},
      {'fecha': '2026-11-23', 'animo': 'triste'},
    ];
    responder = () => http.Response(
      jsonEncode(_mascota(extra: {'animosSiguientes': siguientes})),
      200,
    );

    await ApiServiceCore.getMascota(7);
    await WidgetNori.pendiente;

    expect(guardado['nori_sesion'], true);
    expect(guardado['nori_fecha'], '2026-11-21');
    // `fase`, la elegida; nunca `faseReal`.
    expect(guardado['nori_fase'], 'CRIA');
    expect(guardado['nori_nombre'], 'Brote');
    expect(guardado['nori_animo'], 'exultante');
    expect(
      jsonDecode(guardado['nori_animos_siguientes'] as String),
      siguientes,
    );
    expect(
      guardado['nori_asset_dormida'],
      'assets/mascota/Nori_cria_dormido.png',
    );
    expect(
      guardado['nori_asset_feliz'],
      'assets/mascota/Nori_cria_sonriente.png',
    );
    expect(
      guardado['nori_asset_exultante'],
      'assets/mascota/Nori_cria_exultante.png',
    );
    expect(
      guardado['nori_asset_triste'],
      'assets/mascota/Nori_cria_triste.png',
    );
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('sin animosSiguientes se guarda []', () async {
    await iniciar();
    await ApiServiceCore.getMascota(7);
    await WidgetNori.pendiente;

    expect(guardado['nori_animos_siguientes'], '[]');
  });

  test('sin `animo`, el ánimo sale de `estado`', () async {
    await iniciar();
    responder = () => http.Response(
      jsonEncode({'nombre': 'Brote', 'fase': 'ADULTO', 'estado': 'feliz'}),
      200,
    );
    await ApiServiceCore.getMascota(7);
    await WidgetNori.pendiente;

    expect(guardado['nori_animo'], 'feliz');
    expect(guardado['nori_fase'], 'ADULTO');
  });

  test('el progreso de hoy se guarda', () async {
    await iniciar();
    publicarProgresoDia(
      hechos: 3,
      total: 7,
      avance: 0.5,
      fecha: DateTime(2026, 11, 21, 9),
    );
    await WidgetNori.pendiente;

    expect(guardado['nori_hechos'], 3);
    expect(guardado['nori_total'], 7);
    expect(guardado['nori_avance'], 0.5);
    expect(guardado['nori_progreso_fecha'], '2026-11-21');
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('el progreso de otro día no se guarda', () async {
    await iniciar();
    publicarProgresoDia(hechos: 3, total: 7, fecha: DateTime(2026, 11, 20));
    await WidgetNori.pendiente;

    expect(guardado, isEmpty);
    expect(repintados, isEmpty);
  });

  test('cambiar de identidad guarda su código y sus colores', () async {
    await iniciar();
    aplicarIdentidadEquipada('TEMA_DULCE');
    await WidgetNori.pendiente;

    final t = catalogoIdentidades['TEMA_DULCE']!.tokens;
    expect(guardado['nori_identidad'], 'TEMA_DULCE');
    expect(guardado['nori_color_fondo'], t.bg.toARGB32());
    expect(guardado['nori_color_superficie'], t.surface.toARGB32());
    expect(guardado['nori_color_acento'], t.primary.toARGB32());
    expect(guardado['nori_color_texto'], t.text.toARGB32());
    expect(guardado['nori_color_texto_suave'], t.textMuted.toARGB32());
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('cambiar de idioma vuelve a guardar frases y textos', () async {
    await iniciar();
    IdiomaService.localeNotifier.value = const Locale('en');
    await WidgetNori.pendiente;

    expect(guardado['nori_frase_feliz'], 'happy with you');
    expect(guardado['nori_frase_dormida'], 'taking a nap');
    expect(guardado['nori_frase_exultante'], 'beaming');
    expect(guardado['nori_frase_triste'], 'waiting for you');
    expect(guardado['nori_frase_huevo'], 'about to hatch');
    expect(guardado['nori_texto_empieza'], 'Start whenever you like');
    expect(guardado['nori_texto_todo_hecho'], 'All done for today!');
    expect(guardado['nori_texto_progreso'], '{hechos} of {total} today');
    expect(guardado['nori_texto_progreso_corto'], '{hechos} of {total}');
    expect(
      guardado['nori_texto_accesible'],
      'Nori, {frase}. {hechos} of {total} today. Tap to open Norday.',
    );
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('cerrar sesión lo borra todo y deja nori_sesion en false', () async {
    await iniciar();
    await ApiServiceCore.getMascota(7);
    publicarProgresoDia(hechos: 1, total: 2, fecha: DateTime(2026, 11, 21));
    await WidgetNori.pendiente;
    expect(guardado, isNotEmpty);
    repintados.clear();

    await ApiServiceCore.logout();

    expect(guardado, {'nori_sesion': false});
    expect(repintados, ['NoriWidgetProvider']);
  });

  test('la sesión caducada al arrancar también lo borra', () async {
    await iniciar();
    await ApiServiceCore.getMascota(7);
    await WidgetNori.pendiente;
    // Un token ilegible cuenta como caducado.
    expect(await ApiServiceCore.descartarSesionCaducada(), isTrue);

    expect(guardado, {'nori_sesion': false});
  });

  test('todas las claves del contrato están en la lista de borrado', () {
    expect(WidgetNori.todasLasClaves.toSet().length, 31);
  });

  test('si guardar o repintar lanzan, nada sale hacia fuera', () async {
    WidgetNori.guardarClave = (_, _) async => throw StateError('sin guardar');
    WidgetNori.repintar = (_) async => throw StateError('sin repintar');

    WidgetNori.iniciar(nombreAndroid: 'NoriWidgetProvider');
    await ApiServiceCore.getMascota(7);
    publicarProgresoDia(hechos: 1, total: 2, fecha: DateTime(2026, 11, 21));
    aplicarIdentidadEquipada('TEMA_DULCE');
    IdiomaService.localeNotifier.value = const Locale('pt');
    await ApiServiceCore.logout();
    await WidgetNori.pendiente;
  });
}

Map<String, dynamic> _mascota({Map<String, dynamic> extra = const {}}) => {
  'nombre': 'Brote',
  'fase': 'CRIA',
  'faseReal': 'ADULTO',
  'animo': 'exultante',
  'estado': 'feliz',
  ...extra,
};
