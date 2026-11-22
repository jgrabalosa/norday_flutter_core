import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:norday_flutter_core/screens/actualizacion_obligatoria_screen.dart';
import 'package:norday_flutter_core/services/version_minima_service.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppUpdateInfo _info({
  UpdateAvailability disponibilidad = UpdateAvailability.updateAvailable,
  bool flexible = true,
  InstallStatus instalacion = InstallStatus.unknown,
}) => AppUpdateInfo(
  updateAvailability: disponibilidad,
  immediateUpdateAllowed: true,
  immediateAllowedPreconditions: null,
  flexibleUpdateAllowed: flexible,
  flexibleAllowedPreconditions: null,
  availableVersionCode: 2,
  installStatus: instalacion,
  packageName: 'x',
  clientVersionStalenessDays: null,
  updatePriority: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int consultas;
  late int empezadas;
  late int completadas;
  late List<String> pasos;
  late StreamController<InstallStatus> estados;
  late AppUpdateInfo Function() respuesta;
  late AppUpdateResult resultadoEmpezar;
  late DateTime hoy;
  late bool android;
  late BuildContext contexto;
  late List<String> pasosRecomendada;
  late int pidiendoRecomendada;
  late int? recomendada;
  late int instalada;
  late int aperturasPlay;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    consultas = 0;
    empezadas = 0;
    completadas = 0;
    pasos = [];
    estados = StreamController<InstallStatus>.broadcast();
    respuesta = () =>
        _info(disponibilidad: UpdateAvailability.updateNotAvailable);
    resultadoEmpezar = AppUpdateResult.success;
    hoy = DateTime(2026, 11, 22, 10);
    android = true;

    AvisoActualizacion.esAndroid = () => android;
    AvisoActualizacion.ahora = () => hoy;
    AvisoActualizacion.consultar = () async {
      consultas++;
      return respuesta();
    };
    AvisoActualizacion.empezarFlexible = () async {
      empezadas++;
      return resultadoEmpezar;
    };
    AvisoActualizacion.completarFlexible = () async => completadas++;
    AvisoActualizacion.estadoInstalacion = () => estados.stream;
    AnalyticsCore.enviarEvento = (n, p) async {
      if (n == 'aviso_actualizacion') pasos.add(p['paso'] as String);
      if (n == 'version_recomendada') pasosRecomendada.add(p['paso'] as String);
    };

    ApiServiceCore.appId = 'habitos';
    pasosRecomendada = [];
    pidiendoRecomendada = 0;
    recomendada = null;
    instalada = 5;
    aperturasPlay = 0;
    VersionMinimaService.pedirVersionRecomendada = (_) async {
      pidiendoRecomendada++;
      return recomendada;
    };
    VersionMinimaService.leerVersionInstalada = () async => instalada;
    ActualizacionObligatoriaScreen.actualizar = () async => aperturasPlay++;
  });

  tearDown(() async {
    await estados.close();
    AvisoActualizacion.esAndroid = () => true;
    ApiServiceCore.appId = '';
  });

  Future<void> montar(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) {
              contexto = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  testWidgets('sin actualización no hay aviso ni se ofrece nada', (t) async {
    await montar(t);
    await AvisoActualizacion.comprobar(contexto);
    await t.pump();

    expect(consultas, 1);
    expect(empezadas, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(pasos, isEmpty);
  });

  testWidgets('con actualización flexible se ofrece una vez al día', (t) async {
    respuesta = () => _info();
    await montar(t);

    await AvisoActualizacion.comprobar(contexto);
    expect(empezadas, 1);
    expect(pasos, ['ofrecida', 'aceptada']);

    // Mismo día: ni siquiera consulta.
    await AvisoActualizacion.comprobar(contexto);
    expect(empezadas, 1);
    expect(consultas, 1);

    // Al día siguiente, sí.
    hoy = DateTime(2026, 11, 23, 8);
    await AvisoActualizacion.comprobar(contexto);
    expect(empezadas, 2);
  });

  testWidgets('si el usuario dice que no, se registra y no insiste ese día', (
    t,
  ) async {
    respuesta = () => _info();
    resultadoEmpezar = AppUpdateResult.userDeniedUpdate;
    await montar(t);

    await AvisoActualizacion.comprobar(contexto);
    await AvisoActualizacion.comprobar(contexto);

    expect(empezadas, 1);
    expect(pasos, ['ofrecida', 'rechazada']);
    expect(estados.hasListener, isFalse);
  });

  testWidgets('un error de checkForUpdate no llega a quien llama', (t) async {
    AvisoActualizacion.consultar = () async => throw Exception('sin Play');
    await montar(t);

    await expectLater(AvisoActualizacion.comprobar(contexto), completes);
    expect(empezadas, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('fuera de Android no llama a nada', (t) async {
    android = false;
    respuesta = () => _info();
    await montar(t);

    await AvisoActualizacion.comprobar(contexto);

    expect(consultas, 0);
    expect(empezadas, 0);
    expect(pasos, isEmpty);
  });

  testWidgets('con downloaded sale el aviso y Reiniciar completa una vez', (
    t,
  ) async {
    respuesta = () => _info();
    await montar(t);

    await AvisoActualizacion.comprobar(contexto);
    estados.add(InstallStatus.downloaded);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Hay una versión nueva lista.'), findsOneWidget);
    expect(completadas, 0);
    expect(estados.hasListener, isFalse);

    await t.tap(find.text('Reiniciar'));
    await t.pump();
    await t.pump();

    expect(completadas, 1);
    expect(pasos, ['ofrecida', 'aceptada', 'descargada', 'reiniciada']);
  });

  testWidgets(
    'ya descargada otro día: aviso directo, sin tocar nunca completa',
    (t) async {
      respuesta = () => _info(instalacion: InstallStatus.downloaded);
      await montar(t);

      await AvisoActualizacion.comprobar(contexto);
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(empezadas, 0);

      // Pasa el tiempo del aviso sin tocar nada.
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(seconds: 11));
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(completadas, 0);
    },
  );

  testWidgets('failed y canceled cancelan la escucha sin aviso', (t) async {
    respuesta = () => _info();
    await montar(t);
    await AvisoActualizacion.comprobar(contexto);
    expect(estados.hasListener, isTrue);

    estados.add(InstallStatus.failed);
    await t.pump();

    expect(estados.hasListener, isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('los textos salen en los tres idiomas', (t) async {
    const esperados = {
      'es': ('Hay una versión nueva lista.', 'Reiniciar'),
      'en': ('A new version is ready.', 'Restart'),
      'pt': ('Há uma versão nova pronta.', 'Reiniciar'),
    };
    for (final e in esperados.entries) {
      SharedPreferences.setMockInitialValues({});
      respuesta = () => _info(instalacion: InstallStatus.downloaded);
      await montar(t, locale: Locale(e.key));
      await AvisoActualizacion.comprobar(contexto);
      await t.pump();
      expect(find.text(e.value.$1), findsOneWidget, reason: e.key);
      expect(find.text(e.value.$2), findsOneWidget, reason: e.key);
      await t.pumpWidget(const SizedBox());
    }
  });

  group('versión recomendada', () {
    Future<void> comprobar(WidgetTester t) async {
      await montar(t);
      await AvisoActualizacion.comprobar(contexto);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Play no ofrece nada y la instalada es menor: sale', (t) async {
      recomendada = 6;
      await comprobar(t);

      expect(find.byType(TarjetaVersionRecomendada), findsOneWidget);
      expect(find.byType(NoriVestida), findsOneWidget);
      expect(pasosRecomendada, ['ofrecida']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('version_recomendada_ofrecida'), 6);
    });

    testWidgets('fuera de Android también mira la recomendada', (t) async {
      android = false;
      recomendada = 6;
      await comprobar(t);

      expect(consultas, 0);
      expect(find.byType(TarjetaVersionRecomendada), findsOneWidget);
    });

    testWidgets('si Play ofrece, no sale la tarjeta ni se pide al backend', (
      t,
    ) async {
      respuesta = () => _info();
      recomendada = 6;
      await comprobar(t);

      expect(pasos, ['ofrecida', 'aceptada']);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
      expect(pidiendoRecomendada, 0);
    });

    testWidgets('si Play ya ofreció hoy, tampoco sale la tarjeta', (t) async {
      SharedPreferences.setMockInitialValues({
        AvisoActualizacion.claveDia: '2026-11-22',
      });
      recomendada = 6;
      await comprobar(t);

      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
      expect(pidiendoRecomendada, 0);
    });

    testWidgets('si Play falla, mira la recomendada', (t) async {
      AvisoActualizacion.consultar = () async => throw Exception('sin Play');
      recomendada = 6;
      await comprobar(t);

      expect(find.byType(TarjetaVersionRecomendada), findsOneWidget);
    });

    testWidgets('recomendada nula: no sale', (t) async {
      recomendada = null;
      await comprobar(t);

      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
      expect(pidiendoRecomendada, 1);
    });

    testWidgets('instalada igual o mayor que la recomendada: no sale', (
      t,
    ) async {
      recomendada = 5;
      await comprobar(t);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);

      instalada = 9;
      await comprobar(t);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
    });

    testWidgets('una vez por recomendada; con otra mayor, vuelve', (t) async {
      recomendada = 6;
      await comprobar(t);
      expect(find.byType(TarjetaVersionRecomendada), findsOneWidget);
      await t.tap(find.text('Ahora no'));
      await t.pumpAndSettle();

      await comprobar(t);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);

      recomendada = 7;
      await comprobar(t);
      expect(find.byType(TarjetaVersionRecomendada), findsOneWidget);
      expect(pasosRecomendada, ['ofrecida', 'ahora_no', 'ofrecida']);
    });

    testWidgets('sin appId no pide nada', (t) async {
      ApiServiceCore.appId = '';
      recomendada = 6;
      await comprobar(t);

      expect(pidiendoRecomendada, 0);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
    });

    testWidgets('un fallo del backend no llega a quien llama', (t) async {
      VersionMinimaService.pedirVersionRecomendada = (_) async =>
          throw Exception('sin red');
      await montar(t);

      await expectLater(AvisoActualizacion.comprobar(contexto), completes);
      await t.pump();
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
    });

    testWidgets('«Actualizar» abre Play y registra el paso', (t) async {
      recomendada = 6;
      await comprobar(t);
      await t.tap(find.text('Actualizar'));
      await t.pumpAndSettle();

      expect(aperturasPlay, 1);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
      expect(pasosRecomendada, ['ofrecida', 'actualizar']);
    });

    testWidgets('«Ahora no» cierra sin abrir Play y registra el paso', (
      t,
    ) async {
      recomendada = 6;
      await comprobar(t);
      await t.tap(find.text('Ahora no'));
      await t.pumpAndSettle();

      expect(aperturasPlay, 0);
      expect(find.byType(TarjetaVersionRecomendada), findsNothing);
      expect(pasosRecomendada, ['ofrecida', 'ahora_no']);
    });

    testWidgets('los textos salen en los tres idiomas', (t) async {
      const esperados = {
        'es': (
          'Hay una versión nueva',
          'Trae mejoras para ti y para Nori. Se actualiza en un momento desde Google Play.',
          'Actualizar',
          'Ahora no',
        ),
        'en': (
          "There's a new version",
          'It brings improvements for you and Nori. It updates in a moment from Google Play.',
          'Update',
          'Not now',
        ),
        'pt': (
          'Há uma versão nova',
          'Traz melhorias para ti e para o Nori. Atualiza-se num instante a partir do Google Play.',
          'Atualizar',
          'Agora não',
        ),
      };
      for (final e in esperados.entries) {
        SharedPreferences.setMockInitialValues({});
        recomendada = 6;
        await montar(t, locale: Locale(e.key));
        await AvisoActualizacion.comprobar(contexto);
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text(e.value.$1), findsOneWidget, reason: e.key);
        expect(find.text(e.value.$2), findsOneWidget, reason: e.key);
        expect(find.text(e.value.$3), findsOneWidget, reason: e.key);
        expect(find.text(e.value.$4), findsOneWidget, reason: e.key);
        await t.pumpWidget(const SizedBox());
      }
    });
  });
}
