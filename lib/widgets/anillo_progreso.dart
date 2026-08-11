import 'package:flutter/material.dart';

import 'anillo_identidad.dart';

/// Anillo de progreso con la cuenta dentro — genérico y exportable.
/// Recibe [actual]/[total] y anima el arco entre valores al cambiar.
/// No conoce el dominio: quien lo usa decide qué cuenta.
///
/// El aro en sí es [AnilloIdentidad], el mismo que rodea a la mascota en su
/// pantalla: aquí sólo se le pone la cifra en el centro. Antes tenía su propio
/// `CustomPainter`, que pintaba el mismo arco sin enterarse de la identidad
/// equipada y había que mantener en paralelo.
class AnilloProgreso extends StatelessWidget {
  final int actual;
  final int total;
  final Color color;
  final Color colorPista;
  final Color colorTexto;
  final double tamano;

  const AnilloProgreso({
    super.key,
    required this.actual,
    required this.total,
    required this.color,
    required this.colorPista,
    required this.colorTexto,
    this.tamano = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnilloIdentidad(
          tamano: tamano,
          pct: total <= 0 ? 0.0 : actual / total,
          color: color,
          colorPista: colorPista,
        ),
        Text(
          '$actual/$total',
          style: TextStyle(
            fontSize: tamano * 0.24,
            fontWeight: FontWeight.w600, // Números = SemiBold (identidad)
            color: colorTexto,
          ),
        ),
      ],
    );
  }
}
