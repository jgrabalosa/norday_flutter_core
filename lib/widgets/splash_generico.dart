import 'package:flutter/material.dart';

import 'nori_marca.dart';
import 'wordmark_identidad.dart';

/// Splash genérico y exportable al ecosistema Norday: fondo de marca +
/// símbolo + wordmark, con una duración mínima y la posibilidad de esperar
/// una tarea real (sesión, tema...). El punto 6.5 (Estados de carga) ampliará
/// `tarea` para que también espere los datos del Dashboard.
///
/// El símbolo es Nori respirando, con el halo de la identidad equipada detrás
/// ([NoriMarca]): la pantalla tenía la espera bien resuelta pero no se movía
/// nada en ella. La espera no ha cambiado — sigue siendo exactamente
/// [duracionMinima].
class SplashGenerico<T> extends StatefulWidget {
  /// Símbolo propio de la app, si lo tiene y prefiere ése. Sin él —el caso
  /// normal— manda Nori, que además es lo único de las dos pantallas de
  /// entrada que está vivo.
  final String? rutaImagen;

  final Color colorFondo;
  final Duration duracionMinima;
  final Future<T> Function() tarea;
  final void Function(BuildContext context, T resultado) onListo;
  final String? wordmark;

  /// Ancho del símbolo en dp. Cada app del ecosistema tiene su propio
  /// logo, así que el tamaño es del consumidor, no del motor.
  final double anchoImagen;

  /// Tamaño de fuente del wordmark en dp, acompañando a [anchoImagen].
  final double tamanoWordmark;

  const SplashGenerico({
    super.key,
    this.rutaImagen,
    required this.colorFondo,
    required this.tarea,
    required this.onListo,
    this.duracionMinima = const Duration(milliseconds: 1200),
    this.wordmark,
    this.anchoImagen = 180,
    this.tamanoWordmark = 26,
  });

  @override
  State<SplashGenerico<T>> createState() => _SplashGenericoState<T>();
}

class _SplashGenericoState<T> extends State<SplashGenerico<T>> {
  @override
  void initState() {
    super.initState();
    _ejecutar();
  }

  Future<void> _ejecutar() async {
    final inicio = DateTime.now();
    final resultado = await widget.tarea();
    final transcurrido = DateTime.now().difference(inicio);
    final restante = widget.duracionMinima - transcurrido;
    if (restante > Duration.zero) {
      await Future.delayed(restante);
    }
    if (mounted) widget.onListo(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    final ruta = widget.rutaImagen;

    return Scaffold(
      backgroundColor: widget.colorFondo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ruta != null)
              Image.asset(ruta, width: widget.anchoImagen)
            else
              NoriMarca(tamano: widget.anchoImagen),
            if (widget.wordmark != null) ...[
              const SizedBox(height: 20),
              WordmarkIdentidad(
                texto: widget.wordmark!,
                tamano: widget.tamanoWordmark,
                // El fondo lo elige la app y es de marca (Azul Noche), así que
                // el wordmark va en blanco y no en el color de la identidad:
                // aquí manda el contraste contra ese fondo, no la paleta.
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
