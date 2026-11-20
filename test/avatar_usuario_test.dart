import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/screens/perfil_screen.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/avatares.dart';
import 'package:norday_flutter_core/theme/mascota_assets.dart';
import 'package:norday_flutter_core/theme/mascota_refresh.dart';
import 'package:norday_flutter_core/widgets/imagen_mascota.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T-032: sin avatar equipado, `AvatarUsuario` es tu Nori —su fase, de
/// `faseMascotaNotifier`, y lo que lleva puesto—, siempre feliz. Y sale en
/// Mi cuenta, con «Tu Nori» para el lector.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    faseMascotaNotifier.value = null;
    aplicarAvatarEquipado(null);
  });
  tearDown(() => faseMascotaNotifier.value = null);

  Widget app(Widget hijo) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: Center(child: hijo),
  );

  /// El asset de la única Nori sin prendas que pinta el avatar.
  String assetPintado(WidgetTester tester) => tester
      .widget<ImagenMascota>(
        find.descendant(
          of: find.byType(AvatarUsuario),
          matching: find.byType(ImagenMascota),
        ),
      )
      .asset;

  testWidgets('con la fase ADULTO pinta la adulta, feliz', (tester) async {
    faseMascotaNotifier.value = 'ADULTO';
    await tester.pumpWidget(app(const AvatarUsuario(radius: 26)));

    expect(assetPintado(tester), assetMascota(fase: 'ADULTO', estado: 'feliz'));
  });

  testWidgets('sin fase conocida, la cría', (tester) async {
    await tester.pumpWidget(app(const AvatarUsuario(radius: 26)));

    expect(assetPintado(tester), assetMascota(fase: 'CRIA', estado: 'feliz'));
  });

  testWidgets('al cambiar la fase, repinta', (tester) async {
    await tester.pumpWidget(app(const AvatarUsuario(radius: 26)));
    expect(assetPintado(tester), assetMascota(fase: 'CRIA', estado: 'feliz'));

    faseMascotaNotifier.value = 'HUEVO';
    await tester.pump();
    expect(assetPintado(tester), assetMascota(fase: 'HUEVO', estado: 'feliz'));

    faseMascotaNotifier.value = 'ADULTO';
    await tester.pump();
    expect(assetPintado(tester), assetMascota(fase: 'ADULTO', estado: 'feliz'));
  });

  testWidgets('con un avatar equipado, el avatar, como siempre', (
    tester,
  ) async {
    faseMascotaNotifier.value = 'ADULTO';
    aplicarAvatarEquipado('AVATAR_ZORRO');
    addTearDown(() => aplicarAvatarEquipado(null));
    await tester.pumpWidget(app(const AvatarUsuario(radius: 26)));

    expect(find.byType(ImagenMascota), findsNothing);
    final imagen = tester.widget<Image>(find.byType(Image));
    expect(
      (imagen.image as AssetImage).assetName,
      'assets/avatares/AVATAR_ZORRO.png',
    );
  });

  testWidgets('con una prenda puesta, pinta su capa en la fase de tu Nori', (
    tester,
  ) async {
    final carpeta = Directory.systemTemp.createTempSync('avatar_usuario_');
    addTearDown(() => carpeta.deleteSync(recursive: true));
    final pedidas = <String>[];
    Future<File?> imagen(String ruta) async {
      pedidas.add(ruta);
      final f = File('${carpeta.path}/${ruta.replaceAll('/', '_')}');
      f.writeAsBytesSync(const [0, 1, 2, 3]);
      return f;
    }

    final prendas = ValueNotifier<Map<String, String>>(const {
      'Cabeza': 'PRENDA_GORRO_LANA',
    });
    final manifiesto = ValueNotifier(
      ManifiestoArte.fromJson({
        'version': 1,
        'prendas': {
          'PRENDA_GORRO_LANA': {
            'sitio': 'cabeza',
            'fases': ['cria', 'adulto'],
            'imagenes': {
              'cria': 'prendas/lana_cria.webp',
              'adulto': 'prendas/lana_adulto.webp',
            },
          },
        },
      }),
    );
    faseMascotaNotifier.value = 'ADULTO';

    await tester.pumpWidget(
      app(
        AvatarUsuario(
          radius: 26,
          prendas: prendas,
          manifiesto: manifiesto,
          imagenPrenda: imagen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(pedidas, ['prendas/lana_adulto.webp']);
    expect(find.byKey(const ValueKey('prenda_Cabeza')), findsOneWidget);
    // El cuerpo canónico debajo, en la fase de tu Nori y feliz.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is ImagenMascota &&
            w.asset == assetCuerpoMascota(fase: 'ADULTO', estado: 'feliz'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Mi cuenta enseña el avatar arriba, con «Tu Nori»', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': 7,
      'nombre': 'Ana',
      'username': 'ana',
      'email': 'ana@example.com',
      'proveedorAuth': 'LOCAL',
    });
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        PerfilScreen(
          usuarioId: 7,
          destinoTrasLogin: (_, _) => const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final avatar = find.byType(AvatarUsuario);
    expect(avatar, findsOneWidget);
    expect(tester.widget<AvatarUsuario>(avatar).radius, 32);
    expect(find.semantics.byLabel('Tu Nori'), findsOne);
    semantica.dispose();
  });
}
