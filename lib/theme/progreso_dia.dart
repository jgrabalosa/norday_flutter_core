import 'package:flutter/foundation.dart';

/// Cuántos hábitos hay en el día que la pantalla está mostrando y cuántos
/// están hechos, sin decir cuáles.
///
/// El fondo de cada identidad dibuja con estos dos números —la constelación de
/// Profundidad enciende [hechos] estrellas de [total]— y no necesita saber qué
/// hábito es cada uno. Mantenerlo en números es lo que permite que esto viva
/// en el core: `conocimiento_app_mobile` también lo consume y no tiene
/// hábitos, así que aquí no puede aparecer el modelo `Habito`.
///
/// [fecha] no es decorativa. El cielo refleja el día seleccionado en la tira
/// de la semana, no siempre hoy, y dos días distintos pueden tener los mismos
/// contadores: sin la fecha dentro del valor, pasar de un martes con 3 de 7 a
/// un miércoles con 3 de 7 no notificaría y el dibujo se quedaría congelado.
@immutable
class ProgresoDia {
  /// Hábitos completados en el día mostrado.
  final int hechos;

  /// Hábitos que tocaban ese día. Cero significa que ese día no había nada
  /// que hacer, y el fondo no debe dibujar nada.
  final int total;

  /// El día que describen los contadores, normalizado a medianoche. `null`
  /// mientras no se ha cargado nada.
  final DateTime? fecha;

  const ProgresoDia({
    this.hechos = 0,
    this.total = 0,
    this.fecha,
  });

  /// Estado de partida y de salida: nada cargado, nada que dibujar.
  static const ProgresoDia vacio = ProgresoDia();

  /// Sin esto el `ValueNotifier` compararía referencias y notificaría en cada
  /// escritura aunque los números fueran los mismos, repintando el fondo
  /// entero sin motivo. Es el fallo que `TokensContextuales` sí tiene y que
  /// `FondoEstelar` esquiva a mano en su `shouldRepaint`; aquí se hace bien
  /// desde el principio.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgresoDia &&
          other.hechos == hechos &&
          other.total == total &&
          other.fecha == fecha;

  @override
  int get hashCode => Object.hash(hechos, total, fecha);

  @override
  String toString() => 'ProgresoDia($hechos/$total, $fecha)';
}

/// El progreso del día que la app está mostrando ahora mismo.
///
/// Lo escribe la app de hábitos desde su dashboard; lo lee el fondo de la
/// identidad equipada. Quien no lo escriba nunca —`conocimiento_app_mobile`—
/// lo ve siempre en [ProgresoDia.vacio], que es exactamente lo que quiere.
final ValueNotifier<ProgresoDia> progresoDiaNotifier =
    ValueNotifier<ProgresoDia>(ProgresoDia.vacio);

/// Publica el progreso del día mostrado.
///
/// [fecha] se normaliza a medianoche aquí y no en quien llama, porque la hora
/// que traiga el dato de origen no debe decidir si el fondo se redibuja.
void publicarProgresoDia({
  required int hechos,
  required int total,
  required DateTime fecha,
}) {
  progresoDiaNotifier.value = ProgresoDia(
    hechos: hechos,
    total: total,
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
  );
}

/// Vuelve al estado vacío. Al cerrar sesión o cambiar de usuario: si no, el
/// cielo del usuario anterior sigue puesto mientras carga el siguiente.
void limpiarProgresoDia() {
  progresoDiaNotifier.value = ProgresoDia.vacio;
}
