import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'mascota_refresh.dart';
import '../models/manifiesto_arte.dart';
import '../widgets/nori_vestida.dart';

/// Info visual de un avatar: la imagen real (Noto Emoji, Apache 2.0 — ver
/// assets/avatares/LICENCIA.txt). El PNG es transparente, asi que el color de
/// fondo lo pone quien lo pinta.
class AvatarInfo {
  final String asset;
  const AvatarInfo({required this.asset});
}

/// Registro de avatares por codigo de producto — mismo patron que catalogoIdentidades.
/// El fichero se llama igual que el codigo, para que no puedan desalinearse.
const Map<String, AvatarInfo> catalogoAvatares = {
  'AVATAR_ZORRO': AvatarInfo(asset: 'assets/avatares/AVATAR_ZORRO.png'),
  'AVATAR_GATO': AvatarInfo(asset: 'assets/avatares/AVATAR_GATO.png'),
  'AVATAR_BUHO': AvatarInfo(asset: 'assets/avatares/AVATAR_BUHO.png'),
  'AVATAR_PANDA': AvatarInfo(asset: 'assets/avatares/AVATAR_PANDA.png'),
  'AVATAR_TORTUGA': AvatarInfo(asset: 'assets/avatares/AVATAR_TORTUGA.png'),
  'AVATAR_PERRO': AvatarInfo(asset: 'assets/avatares/AVATAR_PERRO.png'),
  'AVATAR_CONEJO': AvatarInfo(asset: 'assets/avatares/AVATAR_CONEJO.png'),
  'AVATAR_KOALA': AvatarInfo(asset: 'assets/avatares/AVATAR_KOALA.png'),
  'AVATAR_PINGUINO': AvatarInfo(asset: 'assets/avatares/AVATAR_PINGUINO.png'),
  'AVATAR_LEON': AvatarInfo(asset: 'assets/avatares/AVATAR_LEON.png'),
};

/// Gris neutro detrás del PNG transparente. Antes cada avatar traía su propio
/// color de placeholder; ahora el color lo pone la ilustración, y el círculo
/// solo la separa del fondo de la tarjeta.
const Color fondoAvatar = Color(0x339CA3AF);

final ValueNotifier<String?> avatarEquipadoNotifier = ValueNotifier(null);

/// Aplica un avatar por su código de producto. `null` deja tu Nori, que es el
/// estado por defecto.
///
/// Sólo pinta: quién está equipado lo decide el backend, y quien lo cambia es
/// `equiparAvatar` en equipamiento.dart. Antes esto escribía además en
/// `SharedPreferences`, que era una segunda fuente de verdad y se
/// desincronizaba en cuanto el usuario equipaba desde otro dispositivo.
void aplicarAvatarEquipado(String? codigo) {
  avatarEquipadoNotifier.value =
      (codigo != null && catalogoAvatares.containsKey(codigo)) ? codigo : null;
}

/// Círculo de avatar reutilizable: el avatar equipado, o tu Nori si no hay
/// ninguno.
class AvatarUsuario extends StatelessWidget {
  final double radius;

  /// Para los tests, como en [NoriVestida]: lo puesto, el manifiesto y de
  /// dónde sale el fichero de una prenda. Por defecto, los de toda la app.
  final ValueListenable<Map<String, String>>? prendas;
  final ValueListenable<ManifiestoArte>? manifiesto;
  final Future<File?> Function(String ruta)? imagenPrenda;

  const AvatarUsuario({
    super.key,
    this.radius = 18,
    this.prendas,
    this.manifiesto,
    this.imagenPrenda,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return ValueListenableBuilder<String?>(
      valueListenable: avatarEquipadoNotifier,
      builder: (context, codigo, _) {
        final info = codigo != null ? catalogoAvatares[codigo] : null;
        // Sin avatar equipado se pinta Nori, no la inicial del nombre: aquel
        // círculo no pasaba por la identidad —un CircleAvatar sin
        // backgroundColor usa los colores de serie de Material— y al lado de
        // los avatares ilustrados se veía como un error.
        //
        // Es TU Nori (T-032): su fase (la elegida, de `faseMascotaNotifier`,
        // que llenan quienes leen la mascota; sin saberla, la cría) y lo que
        // lleva puesto. Siempre feliz: es una cara, no el ánimo del día.
        final lado = radius * 1.5;
        // Nori vestida, descodificada a su tamaño (N-3); un avatar retirado,
        // como siempre.
        final Widget imagen = info == null
            ? ValueListenableBuilder<String?>(
                valueListenable: faseMascotaNotifier,
                builder: (context, fase, _) => NoriVestida(
                  fase: fase ?? 'CRIA',
                  estado: 'feliz',
                  tamano: lado,
                  prendas: prendas,
                  manifiesto: manifiesto,
                  imagen: imagenPrenda,
                ),
              )
            : Image.asset(
                info.asset,
                package: 'norday_flutter_core',
                width: lado,
                height: lado,
              );
        // El contorno va en los dos casos, con avatar y sin él: si sólo lo
        // llevara el de Nori, el estado "sin avatar" destacaría más que los
        // avatares de verdad.
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fondoAvatar,
            border: Border.all(
              color: t.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          // El PNG cuadrado no llena el círculo: se deja aire alrededor.
          child: Center(child: imagen),
        );
      },
    );
  }
}
