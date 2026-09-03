import 'package:flutter/material.dart';

import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'capa_constelacion.dart';
import 'fondo_ciudad.dart';
import 'fondo_estelar.dart';

/// El fondo de la identidad equipada: la capa quieta, detrás de todo.
///
/// Es la ÚNICA puerta al fondo. Los dibujos de cada identidad no se exportan
/// en el barrel: una pantalla nueva no puede montar el cielo de Profundidad a
/// mano y saltarse el despacho, que es justo como se rompen las otras tres.
///
/// Necesita constraints ajustadas del padre —un `Positioned.fill`, un
/// `SizedBox.expand`—: un `CustomPaint` sin hijo y sin `size` no ocupa espacio
/// por sí mismo.
class FondoIdentidad extends StatelessWidget {
  /// Ver [NivelFondo].
  final NivelFondo nivel;

  const FondoIdentidad({super.key}) : nivel = NivelFondo.mundo;

  /// El fondo del nivel 2. Ver [NivelFondo.habitacion].
  const FondoIdentidad.habitacion({super.key})
      : nivel = NivelFondo.habitacion;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentidadPaleta>(
      valueListenable: identidadEquipadaNotifier,
      builder: (context, id, _) {
        switch (id.fondo) {
          case FondoIdentidadTipo.cielo:
            return FondoEstelar(tokens: id.tokens, nivel: nivel);
          case FondoIdentidadTipo.ciudad:
            return FondoCiudad(tokens: id.tokens, nivel: nivel);
          // Sin painter todavía — es lo que queda de la fase C1. Devolver nada
          // es exactamente lo que estas dos hacen hoy.
          case FondoIdentidadTipo.luz:
          case FondoIdentidadTipo.acumulacion:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

/// La capa que reacciona al progreso del día, POR DELANTE del contenido.
///
/// Va aparte del fondo porque en Profundidad las tarjetas tapaban la
/// constelación. Las otras tres tienen el mismo par: la ciudad de Neotokyo+
/// enciende ventanas y Dulce acumula, y eso se dibuja con `ProgresoDia`, no
/// con el fondo quieto.
///
/// Cada implementación pone su propio `IgnorePointer`: esta capa nunca debe
/// robar los toques de lo que hay debajo.
class CapaProgresoIdentidad extends StatelessWidget {
  const CapaProgresoIdentidad({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentidadPaleta>(
      valueListenable: identidadEquipadaNotifier,
      builder: (context, id, _) {
        switch (id.fondo) {
          case FondoIdentidadTipo.cielo:
            return CapaConstelacion(tokens: id.tokens);
          case FondoIdentidadTipo.ciudad:
          case FondoIdentidadTipo.luz:
          case FondoIdentidadTipo.acumulacion:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
