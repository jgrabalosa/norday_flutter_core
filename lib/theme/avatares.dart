import 'package:flutter/material.dart';

/// Info visual de un avatar: la imagen real (Noto Emoji, Apache 2.0 — ver
/// assets/avatares/LICENCIA.txt). El PNG es transparente, asi que el color de
/// fondo lo pone quien lo pinta.
class AvatarInfo {
  final String asset;
  const AvatarInfo({required this.asset});
}

/// Registro de avatares por codigo de producto — mismo patron que catalogoPaletas.
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

/// Aplica un avatar por su código de producto. `null` deja el círculo con la
/// inicial del nombre, que es el estado por defecto.
///
/// Sólo pinta: quién está equipado lo decide el backend, y quien lo cambia es
/// `equiparAvatar` en equipamiento.dart. Antes esto escribía además en
/// `SharedPreferences`, que era una segunda fuente de verdad y se
/// desincronizaba en cuanto el usuario equipaba desde otro dispositivo.
void aplicarAvatarEquipado(String? codigo) {
  avatarEquipadoNotifier.value =
      (codigo != null && catalogoAvatares.containsKey(codigo)) ? codigo : null;
}

/// Círculo de avatar reutilizable: el avatar equipado, o si no hay ninguno,
/// un círculo con la inicial del nombre.
class AvatarUsuario extends StatelessWidget {
  final String nombre;
  final double radius;
  const AvatarUsuario({super.key, required this.nombre, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: avatarEquipadoNotifier,
      builder: (context, codigo, _) {
        final info = codigo != null ? catalogoAvatares[codigo] : null;
        if (info != null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: fondoAvatar,
            // El PNG cuadrado no llena el círculo: se deja aire alrededor.
            child: Image.asset(info.asset,
                package: 'norday_flutter_core',
                width: radius * 1.5, height: radius * 1.5),
          );
        }
        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
        return CircleAvatar(
          radius: radius,
          child: Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}