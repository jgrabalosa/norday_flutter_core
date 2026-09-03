import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/catalogos_core.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service_core.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../widgets/fondo_identidad.dart';
import '../widgets/skeleton.dart';
import '../widgets/superficie_identidad.dart';

class LogrosScreen extends StatefulWidget {
  final int usuarioId;
  const LogrosScreen({super.key, required this.usuarioId});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  bool _loading = true;
  int _saldo = 0;
  List<dynamic> _catalogo = [];
  Set<int> _idsConseguidos = {};

  /// Mismo criterio que la tienda: Lucide, no emoji. Los emoji los pinta la
  /// fuente del sistema y cambian de dibujo, color y peso entre plataformas,
  /// así que no se alinean con el resto de la iconografía ni con la identidad
  /// equipada.
  static const iconosCategoria = {
    'Inicio': LucideIcons.sprout,
    'Constancia': LucideIcons.flame,
    'Volumen': LucideIcons.chartColumn,
    'Variedad': LucideIcons.palette,
    'Exploración': LucideIcons.compass,
  };

  /// El catálogo lo manda el backend y puede crecer sin que la app se entere.
  static const iconoCategoriaDesconocida = LucideIcons.star;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final saldo = await ApiServiceCore.getSaldoPuntos(widget.usuarioId);
      final catalogo = await ApiServiceCore.getCatalogoLogros();
      final conseguidos = await ApiServiceCore.getLogrosUsuario(widget.usuarioId);

      final ids = conseguidos.map<int>((ul) => ul['logro']['logroId'] as int).toSet();

      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _catalogo = catalogo;
        _idsConseguidos = ids;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MensajesError.de(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;
    final total = _catalogo.length;
    final conseguidos = _idsConseguidos.length;
    final pct = total > 0 ? conseguidos / total : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.logrosTitulo),
        // Transparente para que la nebulosa verde —centrada contra el borde
        // superior— se vea a través de la barra en vez de quedar tapada.
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Imprescindible: sin esto Material 3 tiñe el AppBar en cuanto hay
        // scroll debajo y vuelve a tapar la nebulosa.
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nivel 2: esta pantalla se abre ENCIMA del shell, así que tiene
          // cielo pero no constelación —la monta el shell—. El cielo tenue
          // dice «sigues dentro» sin fingir un progreso que aquí no se
          // muestra.
          const Positioned.fill(child: FondoIdentidad.habitacion()),
          SafeArea(
            child: _loading
                ? _skeletonLogros()
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Saldo — el protagonista de la pantalla.
                        SuperficieIdentidad(
                          protagonista: true,
                          relleno: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(LucideIcons.coins, color: t.points, size: 40),
                              const SizedBox(height: 8),
                              Text('$_saldo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(color: t.text)),
                              Text(l.puntos,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: t.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progreso global
                        SuperficieIdentidad(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l.detLogrosDe(conseguidos, total),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: t.text)),
                                  Text(l.logrosPorcentaje((pct * 100).round()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: t.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 10,
                                  backgroundColor: t.inactivo,
                                  valueColor: AlwaysStoppedAnimation(t.points),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l.logrosSeccion,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: t.text)),
                        const SizedBox(height: 8),
                        ..._catalogo.map((logro) => _logroCard(l, logro, t)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Una fila del catálogo. Conseguido y pendiente ya no se distinguían más
  /// que por la opacidad: ahora el conseguido lleva además la insignia
  /// encendida y el filo del color de puntos, que es lo que lo convierte en
  /// algo que se ha ganado y no en una fila más de la lista.
  Widget _logroCard(NordayCoreLocalizations l, dynamic logro, TokensContextuales t) {
    final id = identidad(context);
    final conseguido = _idsConseguidos.contains(logro['logroId']);
    final icono = iconosCategoria[logro['categoria']] ?? iconoCategoriaDesconocida;

    return Opacity(
      opacity: conseguido ? 1.0 : 0.55,
      child: SuperficieIdentidad(
        esFila: true,
        margen: const EdgeInsets.only(bottom: 8),
        relleno: const EdgeInsets.all(14),
        filo: conseguido
            ? BorderSide(color: t.points.withValues(alpha: 0.55), width: 1.2)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _insignia(id, t, conseguido),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icono, size: 16, color: t.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            CatalogosCore.logro(
                                context, logro['codigo'], logro['nombre']),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: t.text)),
                      ),
                      const SizedBox(width: 8),
                      Text(l.logrosPuntos(logro['puntos'] as int),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: conseguido ? t.points : t.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      l.logrosSubtitulo(
                        CatalogosCore.logroDescripcion(
                            context, logro['codigo'], logro['descripcion']),
                        CatalogosCore.logroCategoria(context, logro['categoria']),
                        CatalogosCore.logroNivel(context, logro['nivel']),
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// El trofeo (o el candado) en la figura de la identidad. Conseguido lleva
  /// resplandor; pendiente, ni relleno ni luz.
  Widget _insignia(IdentidadPaleta id, TokensContextuales t, bool conseguido) {
    final color = conseguido ? t.points : t.textMuted;

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: conseguido ? 0.16 : 0.08),
        shape: formaIdentidad(
          id,
          radio: id.radioSecundario,
          lado: BorderSide(
              color: color.withValues(alpha: conseguido ? 0.55 : 0.25)),
        ),
        shadows: conseguido
            ? [BoxShadow(color: t.points.withValues(alpha: 0.28), blurRadius: 14)]
            : const [],
      ),
      child: Icon(
        conseguido ? LucideIcons.trophy : LucideIcons.lock,
        size: 22,
        color: color,
      ),
    );
  }

  Widget _skeletonLogros() {
    return SkeletonPulso(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de saldo
          SuperficieIdentidad(
            protagonista: true,
            relleno: const EdgeInsets.all(20),
            child: Column(
              children: const [
                SkeletonBox(width: 40, height: 40, radius: 20),
                SizedBox(height: 12),
                SkeletonBox(width: 80, height: 24),
                SizedBox(height: 6),
                SkeletonBox(width: 50, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          SuperficieIdentidad(
            relleno: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 12),
                SkeletonBox(height: 10, radius: 999),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: 80, height: 18),
          const SizedBox(height: 8),
          ...List.generate(5, (_) => const SkeletonCard(height: 76)),
        ],
      ),
    );
  }
}