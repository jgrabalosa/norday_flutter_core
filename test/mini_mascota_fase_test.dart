import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/theme/mascota_refresh.dart';
import 'package:norday_flutter_core/widgets/mini_mascota.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `MiniMascota` publica la fase que lee en `faseMascotaNotifier`, para el
/// avatar (T-032).
///
/// Sin seam nuevo: `ApiServiceCore.cliente` es un `static final` que se crea
/// la primera vez que se lee, así que este fichero lo crea dentro de
/// `http.runWithClient` con un cliente falso (como `fcm_token_app_test.dart`).
/// Por eso vive solo: en otro fichero el cliente ya podría estar creado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final pedidas = <Uri>[];
  late http.Response Function() responder;
  final falso = MockClient((peticion) async {
    pedidas.add(peticion.url);
    return responder();
  });
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  setUp(() {
    pedidas.clear();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
    faseMascotaNotifier.value = null;
  });
  tearDown(() => faseMascotaNotifier.value = null);

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(400, 800), disableAnimations: true),
          child: Stack(
            children: [MiniMascota(usuarioId: 7, areaSize: Size(400, 800))],
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  /// El vagabundeo de la burbuja deja un `Future.delayed` de unos segundos:
  /// se deja correr tras desmontar.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('llena el notifier con la fase elegida de la respuesta', (
    tester,
  ) async {
    responder = () => http.Response(
      jsonEncode({'fase': 'ADULTO', 'faseReal': 'ADULTO', 'estado': 'feliz'}),
      200,
    );
    await montar(tester);

    expect(pedidas.single.path, endsWith('/mascota/7'));
    expect(faseMascotaNotifier.value, 'ADULTO');
    await desmontar(tester);
  });

  testWidgets('la elegida, nunca la real', (tester) async {
    responder = () => http.Response(
      jsonEncode({'fase': 'CRIA', 'faseReal': 'ADULTO', 'estado': 'feliz'}),
      200,
    );
    await montar(tester);

    expect(faseMascotaNotifier.value, 'CRIA');
    await desmontar(tester);
  });

  testWidgets('si la lectura falla, no la toca', (tester) async {
    faseMascotaNotifier.value = 'ADULTO';
    responder = () => http.Response('', 500);
    await montar(tester);

    expect(pedidas, hasLength(1));
    expect(faseMascotaNotifier.value, 'ADULTO');
    await desmontar(tester);
  });
}
