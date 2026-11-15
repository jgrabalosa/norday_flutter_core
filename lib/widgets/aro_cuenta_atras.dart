import 'package:flutter/material.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import 'anillo_identidad.dart';

/// La cuenta atrás de una sesión: el aro de la identidad equipada
/// ([AnilloIdentidad]: cristal en Profundidad, filo en Neotokyo+, lápiz en
/// Dulce), que se vacía según pasa el tiempo, y la cifra `mm:ss` en el
/// centro.
///
/// Solo pinta: recibe [restante] y [total] ya calculados (por ejemplo, de
/// `MotorSesion.restante` y `SesionConcentracion.duracionObjetivo`) y no sabe
/// para qué es la sesión.
///
/// La cifra redondea los segundos hacia arriba, como cualquier cuenta atrás:
/// `00:00` sale solo al final. El lector de pantalla oye los minutos que
/// faltan (también hacia arriba), no la cifra: cambiar de etiqueta cada
/// segundo lo volvería inservible.
class AroCuentaAtras extends StatelessWidget {
  /// Lo que falta.
  final Duration restante;

  /// La duración completa: con ella, el aro va lleno al empezar.
  final Duration total;

  /// Diámetro exterior del aro.
  final double tamano;

  /// Lo que se quiera encima de la cifra, dentro del aro (Nori, por
  /// ejemplo). Tiene que caber: el aro no lo recorta.
  final Widget? centro;

  const AroCuentaAtras({
    super.key,
    required this.restante,
    required this.total,
    this.tamano = 240,
    this.centro,
  });

  /// La parte del aro que queda llena, de 0 a 1.
  static double fraccion(Duration restante, Duration total) {
    if (total <= Duration.zero) return 0;
    return (restante.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  /// `mm:ss`, con los segundos redondeados hacia arriba. Más de una hora
  /// sigue en minutos (`120:00`).
  static String cifra(Duration restante) {
    final ms = restante.inMilliseconds;
    final segundos = ms <= 0 ? 0 : (ms + 999) ~/ 1000;
    final mm = (segundos ~/ 60).toString().padLeft(2, '0');
    final ss = (segundos % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Los minutos que oye el lector, redondeados hacia arriba.
  static int minutosParaLeer(Duration restante) {
    final ms = restante.inMilliseconds;
    return ms <= 0 ? 0 : (ms + 59999) ~/ 60000;
  }

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final t = tokens(context);
    // La cifra es el rol de 32 de la escala; con dígitos de ancho fijo para
    // que no baile al cambiar cada segundo.
    final estilo = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      container: true,
      label: l.aroCuentaAtrasEtiqueta(minutosParaLeer(restante)),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: tamano,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnilloIdentidad(tamano: tamano, pct: fraccion(restante, total)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (centro != null) ...[
                  centro!,
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(cifra(restante), style: estilo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
