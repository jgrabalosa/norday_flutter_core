import 'package:flutter/material.dart';

/// Señal global para forzar que la mascota vuelva a leer su estado del
/// backend. Mismo patrón que `avatarEquipadoNotifier` en avatares.dart.
///
/// El valor en sí no significa nada: es un contador que solo existe para que
/// cada incremento sea un cambio distinto y despierte a los oyentes. Quien
/// escucha no mira el número, solo reacciona.
///
/// Es un mecanismo de motor: no sabe por qué hay que refrescar. Son las
/// pantallas de dominio las que deciden cuándo llamarlo.
final ValueNotifier<int> refrescoMascotaNotifier = ValueNotifier(0);

/// Llamar cuando algo haya podido cambiar el estado de ánimo o la fase de la
/// mascota en el servidor.
void solicitarRefrescoMascota() {
  refrescoMascotaNotifier.value++;
}

/// La fase de la mascota del usuario (`HUEVO`, `CRIA`, `ADULTO`), tal y como
/// la manda el backend en `fase`: la elegida, nunca `faseReal`. `null` si aún
/// no se sabe (antes de leer la mascota, o tras cerrar sesión).
///
/// La llenan quienes leen la mascota —`MiniMascota` y `MascotaScreen`, cada
/// vez que la leen bien, y `MascotaScreen` al elegir otra fase— y la escucha
/// `AvatarUsuario`, que no lee la mascota (T-032). `ApiServiceCore` la vacía
/// al borrar la sesión local: si no, la cuenta siguiente del mismo móvil
/// vería la Nori de la anterior.
final ValueNotifier<String?> faseMascotaNotifier = ValueNotifier(null);
