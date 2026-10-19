import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/cierre_del_dia.dart';
import 'package:norday_flutter_core/widgets/ramo_dulce.dart';

/// El cierre del día para quien no lo ve: un lector de pantalla oye los tres
/// textos de una vez y la acción «Cerrar», con el mismo bloqueo que el toque,
/// y la vibración sale una sola vez al aparecer el nombre de la constelación.
/// Nada de esto se ve en el móvil, así que lo comprueban estos tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
  });

  /// Quita la capa y deja que el estado global se limpie antes del siguiente.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// Aunque el test falle a mitad de la ceremonia, la petición no puede
  /// quedarse puesta para el siguiente.
  void alFinal(WidgetTester tester) => addTearDown(() => desmontar(tester));

  /// Monta la pantalla con el cierre y publica 3 de 3 para que haya figura.
  Future<void> montar(
    WidgetTester tester, {
    bool sinMovimiento = false,
    String codigo = 'TEMA_PROFUNDIDAD',
  }) async {
    alFinal(tester);
    aplicarIdentidadEquipada(codigo);
    publicarProgresoDia(hechos: 3, total: 3, fecha: DateTime(2026, 10, 18));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: sinMovimiento),
          child: const Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                OcultoAlLectorDuranteCierre(child: Text('debajo')),
                CapaCierreDelDia(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// El nodo del contenedor del cierre: el que lleva los tres textos.
  Finder nodoCierre() => find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        (w.properties.label ?? '').contains('Cinturón de Orión'),
  );

  /// El mismo nodo, para tocarlo por la acción semántica.
  SemanticsFinder nodoCierreSemantico() =>
      find.semantics.byPredicate((n) => n.label.contains('Cinturón de Orión'));

  /// Captura las vibraciones que llegan al canal de la plataforma.
  List<MethodCall> capturarVibraciones(WidgetTester tester) {
    final llamadas = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') llamadas.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return llamadas;
  }

  testWidgets(
    'durante la ceremonia, el nodo tiene los tres textos, liveRegion y «Cerrar»',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final l = await NordayCoreLocalizations.delegate.load(const Locale('es'));
      await montar(tester);
      unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      final nodo = tester.getSemantics(nodoCierre());
      final etiqueta = nodo.label;
      final posT = etiqueta.indexOf('T');
      final posOrion = etiqueta.indexOf('Cinturón de Orión');
      final posD = etiqueta.lastIndexOf('D');
      expect(posT, lessThan(posOrion), reason: etiqueta);
      expect(posOrion, lessThan(posD), reason: etiqueta);

      final datos = nodo.getSemanticsData();
      expect(datos.flagsCollection.isLiveRegion, isTrue);
      expect(datos.hasAction(SemanticsAction.tap), isTrue);
      final widget = tester.widget<Semantics>(nodoCierre());
      expect(widget.properties.hintOverrides?.onTapHint, l.comunCerrar);

      await tester.pump(const Duration(milliseconds: 3000));
      await desmontar(tester);
      semantica.dispose();
    },
  );

  testWidgets('durante la ceremonia «debajo» no se oye; al acabar, sí', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    try {
      await montar(tester);
      unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.semantics.byLabel('debajo'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2000));
      tester.semantics.tap(nodoCierreSemantico());
      // Como en el test 3: el ticker del velo de salida toma su hora en el
      // primer tic, y la petición a null necesita otro frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.semantics.byLabel('debajo'), findsOneWidget);
    } finally {
      await desmontar(tester);
      semantica.dispose();
    }
  });

  testWidgets('un toque semántico antes de los 2900 ms no cierra; después sí', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester);
    var cerrado = false;
    unawaited(
      mostrarCierreDelDia(
        titulo: 'T',
        despedida: 'D',
      ).then((_) => cerrado = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.semantics.tap(nodoCierreSemantico());
    await tester.pump(const Duration(milliseconds: 600));
    expect(cerrado, isFalse);

    await tester.pump(const Duration(milliseconds: 2400));
    tester.semantics.tap(nodoCierreSemantico());
    // El ticker toma su hora de inicio en el primer tic: sin este pump, el
    // velo de salida se mediría desde el final del siguiente.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(cerrado, isTrue);

    await desmontar(tester);
    semantica.dispose();
  });

  testWidgets(
    'vibra una vez, al pasar el 48 % de los 2900 ms, y sigue habiendo una al acabar',
    (tester) async {
      final vibraciones = capturarVibraciones(tester);
      await montar(tester);
      unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1300));
      expect(vibraciones, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));
      expect(vibraciones.length, 1);
      expect(vibraciones.single.arguments, 'HapticFeedbackType.heavyImpact');

      await tester.pump(const Duration(milliseconds: 1500));
      tester.semantics.tap(nodoCierreSemantico());
      await tester.pump(const Duration(milliseconds: 600));
      expect(vibraciones.length, 1);

      await desmontar(tester);
    },
  );

  testWidgets('con «Quitar animaciones», vibra una vez nada más empezar', (
    tester,
  ) async {
    final vibraciones = capturarVibraciones(tester);
    await montar(tester, sinMovimiento: true);
    unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
    await tester.pump();
    expect(vibraciones.length, 1);

    await tester.pump(const Duration(milliseconds: 3000));
    expect(vibraciones.length, 1);

    await desmontar(tester);
  });

  testWidgets(
    'la barra queda fuera del árbol semántico durante la ceremonia, y no sin ella',
    (tester) async {
      final semantica = tester.ensureSemantics();
      alFinal(tester);
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      publicarProgresoDia(hechos: 3, total: 3, fecha: DateTime(2026, 10, 18));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              NordayCoreLocalizations.localizationsDelegates,
          supportedLocales: NordayCoreLocalizations.supportedLocales,
          locale: const Locale('es'),
          theme: AppTheme.deTema(temaEquipadoNotifier.value),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // La capa es la que pide la ceremonia; el velo de la barra
                // va encima de 'barra', como en la app.
                const CapaCierreDelDia(),
                const OcultoAlLectorDuranteCierre(child: Text('barra')),
                const Positioned.fill(child: VeloBarraCierreDelDia()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.semantics.byLabel('barra'), findsOneWidget);

      unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.semantics.byLabel('barra'), findsNothing);

      await tester.pump(const Duration(milliseconds: 3000));
      tester.semantics.tap(nodoCierreSemantico());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      semantica.dispose();
    },
  );

  /// El nodo de la ceremonia de Dulce: lleva el nombre del ramo de 3.
  Finder nodoRamo() => find.byWidgetPredicate(
    (w) => w is Semantics && (w.properties.label ?? '').contains('Ramillete'),
  );

  SemanticsFinder nodoRamoSemantico() =>
      find.semantics.byPredicate((n) => n.label.contains('Ramillete'));

  testWidgets('en Dulce, la ceremonia pinta el ramo sobre un velo crema', (
    tester,
  ) async {
    await montar(tester, codigo: 'TEMA_DULCE');
    unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(RamoDulce), findsWidgets);
    final crema = temaEquipadoNotifier.value.fondoNota.toARGB32() & 0xFFFFFF;
    final colores = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((c) => c.color.toARGB32())
        .toList();
    expect(
      colores.any((c) => (c & 0xFFFFFF) == crema),
      isTrue,
      reason: '$colores',
    );
    // Un ColoredBox transparente del propio framework no cuenta: lo que no
    // debe haber es un negro opaco.
    expect(
      colores.any((c) => c >>> 24 > 0 && (c & 0xFFFFFF) == 0),
      isFalse,
      reason: '$colores',
    );

    await desmontar(tester);
  });

  testWidgets(
    'en Dulce, el nodo lleva el nombre del ramo y no cierra antes de tiempo',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, codigo: 'TEMA_DULCE');
      var cerrado = false;
      unawaited(
        mostrarCierreDelDia(
          titulo: 'T',
          despedida: 'D',
        ).then((_) => cerrado = true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(
        tester.widget<Semantics>(nodoRamo()).properties.label,
        contains('Ramillete'),
      );

      // Con 3 flores y el atado, el ramo son 4 etapas de 500 ms más los 500
      // de velo, y los textos empiezan cuando el ramo está formado: a los
      // 3000 ms aún no se puede cerrar.
      await tester.pump(const Duration(milliseconds: 2000));
      tester.semantics.tap(nodoRamoSemantico());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(cerrado, isFalse, reason: 'a los 3000 ms');

      // Después de los 5400 ms, con el ramo y los textos ya dentro, sí.
      await tester.pump(const Duration(milliseconds: 3000));
      tester.semantics.tap(nodoRamoSemantico());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(cerrado, isTrue, reason: 'a los 6600 ms');

      await desmontar(tester);
      semantica.dispose();
    },
  );

  testWidgets('en Neotokyo+ termina en el acto, sin ceremonia', (tester) async {
    await montar(tester, codigo: 'TEMA_NEOTOKYO_PLUS');
    var cerrado = false;
    unawaited(
      mostrarCierreDelDia(
        titulo: 'T',
        despedida: 'D',
      ).then((_) => cerrado = true),
    );
    await tester.pump();
    expect(cerrado, isTrue);

    await desmontar(tester);
  });
}
