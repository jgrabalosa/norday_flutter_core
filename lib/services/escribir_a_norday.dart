import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Seams de test de [escribirANorday]: qué app y versión es esta, qué sistema
/// es, y quién abre el `Uri`. En producción, `package_info_plus`, `dart:io` y
/// `url_launcher`.
@visibleForTesting
Future<({String app, String version})> Function() infoAppCorreo = () async {
  final info = await PackageInfo.fromPlatform();
  return (app: info.appName, version: '${info.version}+${info.buildNumber}');
};

@visibleForTesting
String Function() sistemaCorreo = () =>
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

@visibleForTesting
Future<bool> Function(Uri) lanzarCorreo = (uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

@visibleForTesting
void reiniciarEscribirANordayParaTest() {
  infoAppCorreo = () async {
    final info = await PackageInfo.fromPlatform();
    return (app: info.appName, version: '${info.version}+${info.buildNumber}');
  };
  sistemaCorreo = () =>
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  lanzarCorreo = (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// El `mailto:` de [escribirANorday]. Aparte para poder probarlo sin abrir
/// nada.
///
/// El cuerpo empieza con dos líneas en blanco —ahí escribe la persona— y
/// debajo lleva la app, su versión y el sistema, que es lo primero que habría
/// que preguntarle. Asunto y cuerpo van con `%20`, no con `+`: en un `mailto:`
/// el `+` se leería como un `+` de verdad.
@visibleForTesting
Uri correoANorday({
  required String direccion,
  required String asunto,
  required String app,
  required String version,
  required String sistema,
}) {
  final cuerpo = '\n\n$app $version\n$sistema';
  return Uri(
    scheme: 'mailto',
    path: direccion,
    query:
        'subject=${Uri.encodeComponent(asunto)}'
        '&body=${Uri.encodeComponent(cuerpo)}',
  );
}

/// Abre la app de correo para escribir a [direccion] con [asunto], y en el
/// cuerpo los datos de la app. La dirección la pone la app que llama: el core
/// no conoce ninguna.
///
/// Devuelve `false` si no hay app de correo (la pantalla lo avisa) y nunca
/// lanza.
Future<bool> escribirANorday({
  required String direccion,
  required String asunto,
}) async {
  try {
    final info = await infoAppCorreo();
    final uri = correoANorday(
      direccion: direccion,
      asunto: asunto,
      app: info.app,
      version: info.version,
      sistema: sistemaCorreo(),
    );
    return await lanzarCorreo(uri);
  } catch (e) {
    debugPrint('Escribir a Norday: no se pudo abrir el correo: $e');
    return false;
  }
}
