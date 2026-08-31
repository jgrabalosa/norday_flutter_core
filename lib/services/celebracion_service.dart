import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/catalogos_core.dart';
import '../navegacion.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../widgets/celebracion_nivel.dart';
import '../widgets/superficie_identidad.dart';
import 'api_service_core.dart';
import 'sonido_service.dart';

class CelebracionService {
  static bool _mostrando = false;
  static final List<String> _cola = [];

  static Future<void> mostrar(List<String> codigos) async {
    if (codigos.isEmpty) return;
    _cola.addAll(codigos);
    if (_mostrando) return;
    _mostrando = true;
    await _procesarCola();
    _mostrando = false;
  }

static Future<void> _procesarCola() async {
    Map<String, String> nombres = {};
    Map<String, String> descripciones = {};
    try {
      final catalogo = await ApiServiceCore.getCatalogoLogros();
      for (var l in catalogo) {
        nombres[l['codigo']] = l['nombre'];
        descripciones[l['codigo']] = l['descripcion'] ?? '';
      }
    } catch (_) {}

    while (_cola.isNotEmpty) {
      final codigo = _cola.removeAt(0);
      final context = nordayNavigatorKey.currentContext;
      if (context == null) continue;
      if (!context.mounted) return;
      SonidoService.reproducir('logro');

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: NordayCoreLocalizations.of(context)!.comunCerrar,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
        transitionBuilder: (context, anim, anim2, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return Stack(
            children: [
              // Diálogo del logro (debajo)
              Transform.scale(
                scale: curved.value,
                child: Opacity(
                  opacity: anim.value.clamp(0.0, 1.0),
                  child: _CelebracionDialog(
                    codigo: codigo,
                    nombreBackend: nombres[codigo] ?? codigo,
                    descripcionBackend: descripciones[codigo] ?? '',
                  ),
                ),
              ),
              // El gesto de la identidad a pantalla completa, encima y sin
              // bloquear toques: el mismo destello, glitch, brillo o confeti de
              // corazones que celebra subir de nivel. Antes era un confeti de
              // Lottie idéntico en las cuatro identidades.
              //
              // La semilla es el código del logro: el mismo logro cae siempre
              // igual, y dos logros seguidos no caen iguales.
              GestoCelebracionIdentidad(semilla: codigo.hashCode),
            ],
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}

class _CelebracionDialog extends StatelessWidget {
  final String codigo;
  final String nombreBackend;
  final String descripcionBackend;
  const _CelebracionDialog({
    required this.codigo,
    required this.nombreBackend,
    required this.descripcionBackend,
  });

  /// Lado de la insignia del trofeo. Manda en el diálogo, como mandaba el
  /// confeti de 140 que había antes en su sitio.
  static const double _ladoInsignia = 120;

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final id = identidad(context);
    final t = tokens(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          // La figura sale de la identidad, pero la superficie se pinta
          // siempre: un diálogo flota sobre la pantalla oscurecida y necesita
          // fondo propio, también en Alba, que en una pantalla no lo pondría.
          decoration: ShapeDecoration(
            color: t.surface,
            shape: formaIdentidad(
              id,
              radio: id.radioHero,
              lado: BorderSide(color: t.primary.withValues(alpha: 0.45)),
            ),
            shadows: const [
              BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _insignia(id, t),
              const SizedBox(height: 20),
              // «Logro desbloqueado» pasa a ser una etiqueta pequeña: dice qué
              // ha ocurrido, pero no merece el titular. El titular es el
              // nombre del logro, que es la información de verdad, y debajo va
              // el porqué. `logroDescripcion` ya existía traducida y no se
              // usaba en ningún sitio.
              Text(l.celLogroDesbloqueado,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: t.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(CatalogosCore.logro(context, codigo, nombreBackend),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: t.text),
                  textAlign: TextAlign.center),
              if (descripcionBackend.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                    CatalogosCore.logroDescripcion(
                        context, codigo, descripcionBackend),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: t.textMuted),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  shape: formaIdentidad(id, radio: id.radioSecundario)
                      as OutlinedBorder,
                ),
                child: Text(l.celGenial),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// El trofeo en la figura de la identidad, con el color de puntos y su
  /// resplandor. Sustituye al emoji 🏆, que lo pintaba la fuente del sistema y
  /// cambiaba de dibujo entre plataformas — el mismo criterio que ya se siguió
  /// en la tienda y en logros.
  Widget _insignia(IdentidadPaleta id, TokensContextuales t) {
    return Container(
      width: _ladoInsignia,
      height: _ladoInsignia,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: t.points.withValues(alpha: 0.14),
        shape: formaIdentidad(
          id,
          radio: _ladoInsignia / 2,
          lado: BorderSide(color: t.points.withValues(alpha: 0.55), width: 1.5),
        ),
        shadows: [
          BoxShadow(color: t.points.withValues(alpha: 0.30), blurRadius: 22),
        ],
      ),
      child: Icon(LucideIcons.trophy, size: 56, color: t.points),
    );
  }
}