import 'package:flutter/foundation.dart';

/// Cuántos hábitos hay en el día que la pantalla está mostrando, cuántos
/// están hechos y cuánto se lleva del día, sin decir cuáles.
///
/// El fondo de cada identidad dibuja con estos números —la constelación de
/// Profundidad enciende [completas] estrellas de [total] y la siguiente a
/// medias, según [resto]— y no necesita saber qué hábito es cada uno.
/// Mantenerlo en números es lo que permite que esto viva en el core:
/// `conocimiento_app_mobile` también lo consume y no tiene hábitos, así que
/// aquí no puede aparecer el modelo `Habito`.
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

  /// Cuánto se lleva del día, de 0 a 1, contando lo hecho a medias: con uno
  /// de dos completo y el otro a la mitad, 0,75. Es lo que dibujan los
  /// fondos. Quien no lo publica recibe [hechos] entre [total], que es lo que
  /// se dibujaba antes.
  final double avance;

  /// El día que describen los contadores, normalizado a medianoche. `null`
  /// mientras no se ha cargado nada.
  final DateTime? fecha;

  const ProgresoDia({
    this.hechos = 0,
    this.total = 0,
    this.avance = 0.0,
    this.fecha,
  });

  /// Estado de partida y de salida: nada cargado, nada que dibujar.
  static const ProgresoDia vacio = ProgresoDia();

  /// Cuántas unidades enteras cubre [avance]: las estrellas encendidas del
  /// todo. El margen de 1e-9 es para que dos tercios de tres den dos y no uno
  /// por el redondeo de la coma flotante.
  int get completas =>
      total <= 0 ? 0 : (avance * total + 1e-9).floor().clamp(0, total);

  /// Lo que se lleva de la siguiente unidad, de 0 a 1: el brillo de la
  /// estrella que va a medias. Cero si no hay siguiente.
  double get resto => total <= 0 || completas >= total
      ? 0.0
      : (avance * total - completas).clamp(0.0, 1.0);

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
          other.avance == avance &&
          other.fecha == fecha;

  @override
  int get hashCode => Object.hash(hechos, total, avance, fecha);

  @override
  String toString() => 'ProgresoDia($hechos/$total, $avance, $fecha)';
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
///
/// [avance] es opcional: sin él vale [hechos] entre [total], así que quien
/// sólo cuenta enteros sigue viéndose como antes. Se recorta entre 0 y 1.
void publicarProgresoDia({
  required int hechos,
  required int total,
  required DateTime fecha,
  double? avance,
}) {
  progresoDiaNotifier.value = ProgresoDia(
    hechos: hechos,
    total: total,
    avance: (avance ?? (total > 0 ? hechos / total : 0.0)).clamp(0.0, 1.0),
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
  );
}

/// Vuelve al estado vacío. Al cerrar sesión o cambiar de usuario: si no, el
/// cielo del usuario anterior sigue puesto mientras carga el siguiente.
void limpiarProgresoDia() {
  progresoDiaNotifier.value = ProgresoDia.vacio;
  diaCerradoNotifier.value = false;
}

/// Si el día que se está mostrando está cerrado: todo hecho y la ceremonia
/// del cierre ya vista.
///
/// Va aparte de [progresoDiaNotifier] a propósito: sólo le importa a la
/// constelación de Profundidad. Los fondos de las otras identidades —y
/// `conocimiento_app_mobile`— escuchan el progreso y no tienen por qué
/// repintarse cuando esto cambia. Lo decide la app, que es quien sabe
/// cuándo ha terminado la ceremonia; el core sólo lo pinta.
final ValueNotifier<bool> diaCerradoNotifier = ValueNotifier<bool>(false);

/// Marca o desmarca como cerrado el día que se está mostrando.
void marcarDiaCerrado(bool cerrado) {
  diaCerradoNotifier.value = cerrado;
}
