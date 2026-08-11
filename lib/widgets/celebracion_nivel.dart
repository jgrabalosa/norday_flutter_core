import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// El momento de subir de nivel, que es el único de la pantalla que merece
/// una celebración propia.
///
/// Distinta a propósito de `AnimacionPuntos`, que sigue siendo la de cada
/// alimentada: si el "+10 XP" de siempre y el salto de nivel se vieran igual,
/// el salto de nivel dejaría de ser un momento. Aquélla es un número que
/// flota; ésta ocupa la pantalla y cambia entera con la identidad equipada.
///
/// Es un overlay, no un diálogo: no bloquea, no hay que cerrarlo y se va solo.
class CelebracionNivel {
  /// Duración del gesto completo. Se sale sola al terminar.
  static const _duracion = Duration(milliseconds: 1900);

  /// Cuánto se queda a la vista cuando el sistema pide no animar: sin
  /// recorrido no hay nada que esperar, pero el aviso tiene que dar tiempo a
  /// leerse.
  static const _duracionEstatica = Duration(milliseconds: 1500);

  static void mostrar(BuildContext context, int nivel) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => _CelebracionNivelOverlay(
        nivel: nivel,
        alTerminar: entrada.remove,
      ),
    );
    overlay.insert(entrada);
  }
}

class _CelebracionNivelOverlay extends StatefulWidget {
  final int nivel;
  final VoidCallback alTerminar;

  const _CelebracionNivelOverlay({
    required this.nivel,
    required this.alTerminar,
  });

  @override
  State<_CelebracionNivelOverlay> createState() =>
      _CelebracionNivelOverlayState();
}

class _CelebracionNivelOverlayState extends State<_CelebracionNivelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  Timer? _relojEstatico;

  /// El gesto sólo se lanza una vez. Se hace en `didChangeDependencies` y no
  /// en `initState` porque la preferencia se lee del `MediaQuery`, igual que
  /// en `MascotaAnimadaViva`, y ahí el contexto todavía no vale.
  bool _arrancado = false;

  /// Los corazones de Dulce. Se siembran con el nivel, así que la misma
  /// subida cae siempre igual y no hay azar que perseguir al depurar.
  late final List<_Corazon> _corazones;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: CelebracionNivel._duracion,
    );

    final azar = math.Random(widget.nivel);
    _corazones = List.generate(
      18,
      (_) => _Corazon(
        x: azar.nextDouble(),
        retraso: azar.nextDouble() * 0.35,
        deriva: azar.nextDouble() * 80 - 40,
        giro: azar.nextDouble() * 1.6 - 0.8,
        lado: 14 + azar.nextDouble() * 16,
      ),
    );

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;

    // Aquí no se apaga el aviso —el usuario ha subido de nivel y tiene que
    // enterarse—, se apaga el movimiento: el controlador se queda parado en su
    // punto de plena vista y el overlay se retira solo un momento después.
    final sinAnimaciones =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (sinAnimaciones) {
      _controlador.value = 0.45; // el pico: todo presente, nada en tránsito
      _relojEstatico = Timer(
        CelebracionNivel._duracionEstatica,
        widget.alTerminar,
      );
    } else {
      _controlador.forward().whenComplete(widget.alTerminar);
    }
  }

  @override
  void dispose() {
    _relojEstatico?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  /// Entra con rebote, se sostiene y se va. Común a las cuatro: lo que cambia
  /// entre identidades es lo que rodea al texto, no cuándo aparece.
  static final _tweenEscala = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.4, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 28,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
  ]);

  static final _tweenOpacidad = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 28),
  ]);

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;
    final texto = l.mascotaSubidaNivel(widget.nivel);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controlador,
        builder: (context, _) {
          final v = _controlador.value;
          return Opacity(
            opacity: _tweenOpacidad.transform(v).clamp(0.0, 1.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ..._fondo(id, t, v),
                Center(
                  child: Transform.scale(
                    scale: _tweenEscala.transform(v),
                    child: _texto(id, t, texto, v),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Lo que pasa detrás del texto, por identidad.
  List<Widget> _fondo(IdentidadPaleta id, TokensContextuales t, double v) {
    return switch (id.forma) {
      // Profundidad — destello: un fogonazo verde que se apaga y un aro que
      // se abre desde el centro.
      FormaIdentidad.glass => [
          CustomPaint(
            painter: _DestelloPainter(color: t.success, avance: v),
          ),
        ],
      // Neotokyo+ — glitch: bandas horizontales desplazadas, como una señal
      // que se rompe. El desgarro va aquí; la separación de color, en el texto.
      FormaIdentidad.chamfer => [
          CustomPaint(
            painter: _GlitchPainter(
              color: t.primary,
              acento: t.points,
              avance: v,
            ),
          ),
        ],
      // Alba no pone nada detrás: su celebración es el brillo que cruza la
      // letra, y añadirle fondo la sacaría de su propio registro.
      FormaIdentidad.hairline => const [],
      // Dulce — confeti de corazones cayendo.
      FormaIdentidad.pill => [
          CustomPaint(
            painter: _ConfetiCorazonesPainter(
              corazones: _corazones,
              color: t.primary,
              acento: t.streak,
              avance: v,
            ),
          ),
        ],
    };
  }

  Widget _texto(
      IdentidadPaleta id, TokensContextuales t, String texto, double v) {
    final base = GoogleFonts.getFont(
      id.fontDisplay,
      fontSize: 40,
      fontWeight: FontWeight.w800,
      color: t.text,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return switch (id.forma) {
      FormaIdentidad.glass => Text(texto, style: base),

      // Separación de canales: el mismo texto tres veces, dos de ellas
      // desplazadas y en color, temblando a distinto ritmo.
      FormaIdentidad.chamfer => Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(_tembleque(v, 13) * 5, 0),
              child: Text(texto.toUpperCase(),
                  style: base.copyWith(
                      color: t.primary.withValues(alpha: 0.85),
                      letterSpacing: 2)),
            ),
            Transform.translate(
              offset: Offset(_tembleque(v, 7) * -5, 0),
              child: Text(texto.toUpperCase(),
                  style: base.copyWith(
                      color: t.points.withValues(alpha: 0.85),
                      letterSpacing: 2)),
            ),
            Text(texto.toUpperCase(),
                style: base.copyWith(letterSpacing: 2)),
          ],
        ),

      // Alba — un brillo dorado que cruza la letra de lado a lado, en itálica
      // como todo su display. Nada más: es toda la celebración.
      FormaIdentidad.hairline => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            // El barrido va de fuera a fuera, así que el reflejo entra y sale
            // en vez de aparecer y desaparecer dentro de la palabra.
            final centro = -0.4 + v * 1.8;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                t.points.withValues(alpha: 0),
                t.points,
                t.points.withValues(alpha: 0),
              ],
              stops: [
                (centro - 0.22).clamp(0.0, 1.0),
                centro.clamp(0.0, 1.0),
                (centro + 0.22).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          child: Text(
            texto,
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

      FormaIdentidad.pill => Text(
          texto,
          style: base.copyWith(color: t.primary),
        ),
    };
  }

  /// Temblor de -1 a 1 con [frecuencia] ciclos por gesto. Determinista: el
  /// glitch tiene que ser reproducible, no aleatorio.
  double _tembleque(double v, double frecuencia) =>
      math.sin(v * 2 * math.pi * frecuencia) *
      math.sin(v * 2 * math.pi * 2.7 + 0.6);
}

/// Profundidad — fogonazo radial y aro expansivo.
class _DestelloPainter extends CustomPainter {
  final Color color;
  final double avance;

  _DestelloPainter({required this.color, required this.avance});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final maximo = size.shortestSide * 0.75;

    // Fogonazo: entra de golpe y se apaga en el primer tercio.
    final fogonazo = (1 - (avance / 0.35)).clamp(0.0, 1.0);
    if (fogonazo > 0) {
      final rect = Rect.fromCircle(center: centro, radius: maximo);
      canvas.drawCircle(
        centro,
        maximo,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.55 * fogonazo),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    // Aro: se abre durante todo el gesto y se adelgaza al llegar al borde.
    final radio = maximo * Curves.easeOutCubic.transform(avance);
    final alfa = (1 - avance).clamp(0.0, 1.0);
    if (radio > 0 && alfa > 0.01) {
      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * alfa + 0.5
          ..color = color.withValues(alpha: 0.6 * alfa),
      );
    }
  }

  @override
  bool shouldRepaint(_DestelloPainter old) =>
      old.avance != avance || old.color != color;
}

/// Neotokyo+ — bandas desplazadas, señal rota.
class _GlitchPainter extends CustomPainter {
  final Color color;
  final Color acento;
  final double avance;

  _GlitchPainter({
    required this.color,
    required this.acento,
    required this.avance,
  });

  /// Alto de cada banda y a qué altura de la pantalla cae, en fracción.
  static const _bandas = [
    (0.34, 0.030, 17.0),
    (0.44, 0.014, 29.0),
    (0.52, 0.022, 11.0),
    (0.61, 0.010, 37.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Sólo en la mitad central del gesto: un glitch permanente es un patrón,
    // no un fallo.
    final fuerza = math.sin(avance.clamp(0.0, 1.0) * math.pi);
    if (fuerza < 0.05) return;

    for (final (y, alto, frecuencia) in _bandas) {
      final salto =
          math.sin(avance * 2 * math.pi * frecuencia) * size.width * 0.10;
      final rect = Rect.fromLTWH(
        salto,
        size.height * y,
        size.width,
        size.height * alto,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = (frecuencia > 20 ? acento : color)
              .withValues(alpha: 0.22 * fuerza),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchPainter old) =>
      old.avance != avance || old.color != color || old.acento != acento;
}

/// Un corazón del confeti de Dulce.
class _Corazon {
  /// Posición horizontal de salida, en fracción del ancho.
  final double x;

  /// Cuánto tarda en empezar a caer, en fracción del gesto.
  final double retraso;

  /// Desplazamiento horizontal a lo largo de la caída, en píxeles.
  final double deriva;

  /// Vuelta completa que da mientras cae, en radianes.
  final double giro;

  final double lado;

  const _Corazon({
    required this.x,
    required this.retraso,
    required this.deriva,
    required this.giro,
    required this.lado,
  });
}

class _ConfetiCorazonesPainter extends CustomPainter {
  final List<_Corazon> corazones;
  final Color color;
  final Color acento;
  final double avance;

  _ConfetiCorazonesPainter({
    required this.corazones,
    required this.color,
    required this.acento,
    required this.avance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < corazones.length; i++) {
      final c = corazones[i];
      // Cada uno recorre su propio 0→1 desde que le toca salir.
      final t = ((avance - c.retraso) / (1 - c.retraso)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final y = -c.lado + (size.height + c.lado * 2) * Curves.easeIn.transform(t);
      final x = size.width * c.x + c.deriva * t;
      final alfa = (1 - t * t).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.giro * t * 2 * math.pi);
      _dibujar(
        canvas,
        c.lado,
        Paint()..color = (i.isEven ? color : acento).withValues(alpha: alfa),
      );
      canvas.restore();
    }
  }

  /// Un corazón centrado en el origen: dos lóbulos y una punta. Con cúbicas
  /// sale más limpio que empalmando arcos.
  void _dibujar(Canvas canvas, double lado, Paint pincel) {
    final r = lado / 2;
    canvas.drawPath(
      Path()
        ..moveTo(0, r * 0.75)
        ..cubicTo(-r * 1.7, -r * 0.35, -r * 0.55, -r * 1.5, 0, -r * 0.45)
        ..cubicTo(r * 0.55, -r * 1.5, r * 1.7, -r * 0.35, 0, r * 0.75)
        ..close(),
      pincel,
    );
  }

  @override
  bool shouldRepaint(_ConfetiCorazonesPainter old) =>
      old.avance != avance || old.color != color || old.acento != acento;
}
