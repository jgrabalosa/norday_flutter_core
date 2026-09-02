import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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

  /// Color del arco. Por defecto el primario de la identidad.
  final Color? color;

  /// Color de la pista de fondo. Por defecto `inactivo`, que es el token que
  /// nombra este trabajo.
  final Color? colorPista;

  /// Color de la cifra del centro. Por defecto el texto de la identidad.
  final Color? colorTexto;

  final double tamano;

  const AnilloProgreso({
    super.key,
    required this.actual,
    required this.total,
    this.color,
    this.colorPista,
    this.colorTexto,
    this.tamano = 64,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // El arco y la pista los resuelve AnilloIdentidad, que ya acepta
        // nulos y pone los suyos: no se duplica aquí el valor por defecto.
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
            color: colorTexto ?? t.text,
          ),
        ),
      ],
    );
  }
}
