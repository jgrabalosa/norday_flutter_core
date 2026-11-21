import 'package:flutter/material.dart';

import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/progreso_dia.dart';
import 'capa_constelacion.dart';
import 'cierre_del_dia.dart';
import 'ramo_dulce.dart';

/// La figura del día de la identidad equipada, quieta y en su estado final,
/// para [total] hábitos y a [tamano] de lado: la constelación encendida en
/// Profundidad, el ramo coloreado y atado en Dulce y el letrero encendido en
/// Neotokyo+. Sin animación y sin red: es lo que pinta la postal del cierre.
///
/// No sabe qué es un hábito: solo cuántos. Con `total <= 0` no pinta nada.
class FiguraDelDia extends StatelessWidget {
  final int total;

  /// Lado del cuadrado que ocupa. El ramo, más estrecho, va centrado.
  final double tamano;

  const FiguraDelDia({super.key, required this.total, required this.tamano});

  /// La constelación llena el cuadrado entero.
  static Rect _todo(Size size) => Offset.zero & size;

  @override
  Widget build(BuildContext context) {
    final lado = tamano < 0 ? 0.0 : tamano;
    return ValueListenableBuilder<IdentidadPaleta>(
      valueListenable: identidadEquipadaNotifier,
      builder: (context, id, _) {
        final Widget figura = switch (id.fondo) {
          FondoIdentidadTipo.cielo => CustomPaint(
            size: Size.square(lado),
            painter: PintorConstelacion(
              id.tokens,
              ProgresoDia(hechos: total, total: total, avance: 1.0),
              vuelos: const {},
              apagados: const {},
              realce: 1.0,
              velo: false,
              cuadro: _todo,
            ),
          ),
          FondoIdentidadTipo.acumulacion => Center(
            child: RamoDulce(total: total, alto: lado),
          ),
          FondoIdentidadTipo.ciudad => CustomPaint(
            size: Size.square(lado),
            painter: PintorLetreroCeremonia(id.tokens, total, 1.0),
          ),
        };
        return ExcludeSemantics(
          child: SizedBox.square(dimension: lado, child: figura),
        );
      },
    );
  }
}
