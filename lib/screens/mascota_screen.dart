import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/mensajes_error.dart';
import '../l10n/mensajes_mascota.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service_core.dart';
import '../theme/app_theme.dart';
import '../theme/mascota_assets.dart';
import '../widgets/anillo_xp_identidad.dart';
import '../widgets/animacion_puntos.dart';
import '../widgets/burbuja_contexto.dart';
import '../widgets/celebracion_nivel.dart';
import '../widgets/halo_identidad.dart';
import '../widgets/mascota_animada_viva.dart';
import '../widgets/skeleton.dart';
import '../widgets/terrario_identidad.dart';
import 'tienda_screen.dart';

class MascotaScreen extends StatefulWidget {
  final int usuarioId;

  /// Dentro del shell la cabecera ya la pone el shell: un Scaffold propio aquí
  /// pintaría el título dos veces. Abierta como ruta (mini-mascota) sí necesita
  /// la suya, con su botón de volver.
  final bool embebida;

  /// Si la pantalla está a la vista. Dentro del PageView del shell el estado se
  /// mantiene vivo, así que `initState` sólo corre una vez: sin esto, una fase
  /// que cambia mientras el usuario está en otra pestaña no se vería hasta
  /// reiniciar. Abierta como ruta siempre está activa.
  final bool activa;

  const MascotaScreen({
    super.key,
    required this.usuarioId,
    this.embebida = false,
    this.activa = true,
  });

  @override
  State<MascotaScreen> createState() => _MascotaScreenState();
}

class _MascotaScreenState extends State<MascotaScreen> {
  bool _loading = true;
  String _nombre = '';
  int _nivel = 1;
  int _xpEnNivelActual = 0;
  int _xpParaSiguienteNivel = 20;
  String _fase = 'HUEVO'; // código, no texto: se traduce al pintar
  String _estado = 'triste';

  /// Comida disponible. El id del producto sale del propio inventario: el
  /// cliente no cablea ningún identificador de la BD, sólo el código.
  static const _codigoComida = 'COMIDA_BASICA';
  int? _comidaProductoId;
  int _comidaCantidad = 0;
  bool _alimentando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void didUpdateWidget(covariant MascotaScreen anterior) {
    super.didUpdateWidget(anterior);
    // Al volver a la pestaña, no al salir de ella.
    if (!anterior.activa && widget.activa) _cargarDatos();
  }

  Future<void> _cargarDatos() =>
      Future.wait([_cargarMascota(), _cargarInventario()]);

  Future<void> _cargarMascota() async {
    try {
      final data = await ApiServiceCore.getMascota(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _nombre = data['nombre'] ?? '';
        _nivel = data['nivel'] ?? 1;
        _xpEnNivelActual = data['xpEnNivelActual'] ?? 0;
        _xpParaSiguienteNivel = data['xpParaSiguienteNivel'] ?? 20;
        _fase = data['fase'] ?? 'HUEVO';
        _estado = data['estado'] ?? 'triste';
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

  /// El inventario es accesorio: si falla, la mascota se sigue viendo y el
  /// botón de alimentar se queda deshabilitado. No se avisa por separado
  /// porque un fallo de red ya lo canta la carga de la mascota.
  Future<void> _cargarInventario() async {
    try {
      final inventario = await ApiServiceCore.getInventarioProductos(widget.usuarioId);
      int? productoId;
      int cantidad = 0;
      for (final up in inventario) {
        if (up['producto']?['codigo'] == _codigoComida) {
          productoId = up['producto']['productoId'] as int?;
          cantidad = up['cantidad'] ?? 0;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _comidaProductoId = productoId;
        _comidaCantidad = cantidad;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _comidaCantidad = 0);
    }
  }

  Future<void> _alimentar() async {
    final productoId = _comidaProductoId;
    if (productoId == null || _comidaCantidad <= 0 || _alimentando) return;

    setState(() => _alimentando = true);
    try {
      final resultado = await ApiServiceCore.usarProducto(widget.usuarioId, productoId);
      if (!mounted) return;
      // Consumir la comida siempre da XP; subir de nivel es el caso vistoso.
      if (resultado['subioNivel'] == true || resultado['codigoConsumido'] != null) {
        AnimacionPuntos.mostrar(context, 10, simbolo: 'XP');
      }
      if (resultado['subioNivel'] == true) {
        // El nivel nuevo lo manda el backend en la misma respuesta. Se usa ése
        // y no `_nivel`, que hasta el `_cargarDatos` de abajo sigue siendo el
        // anterior; la caída sólo cubre que algún día deje de venir.
        final nivelNuevo = resultado['nivelNuevo'] as int? ?? 0;
        CelebracionNivel.mostrar(
            context, nivelNuevo > 0 ? nivelNuevo : _nivel + 1);
      }
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: NordayCoreLocalizations.of(context)!.mascotaErrorAlimentar)),
        ),
      );
    } finally {
      if (mounted) setState(() => _alimentando = false);
    }
  }

  String get _imagenMascota => assetMascota(fase: _fase, estado: _estado);

  /// Sin nombre puesto, se muestra la fase localizada. Así el valor por
  /// defecto está traducido sin haber guardado nada en la BD.
  ///
  /// La traducción de fase y estado ya no vive aquí: la comparte
  /// [MensajesMascota] con la frase de contexto, para que las dos no puedan
  /// acabar diciendo cosas distintas de los mismos códigos.
  String _nombreVisible(NordayCoreLocalizations l) =>
      _nombre.isEmpty ? MensajesMascota.fase(l, _fase) : _nombre;

  Future<void> _editarNombre() async {
    final l = NordayCoreLocalizations.of(context)!;
    final controller = TextEditingController(text: _nombre);
    // El controller es local al dialogo: se destruye al cerrarse, pase lo que
    // pase. Si no, cada vez que se abre el dialogo se queda uno vivo.
    String? nuevoNombre;
    try {
      nuevoNombre = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.mascotaPonleNombre),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(hintText: l.mascotaHintNombre),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancelar),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.guardar),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    final elegido = nuevoNombre;
    if (elegido != null && elegido.isNotEmpty && elegido != _nombre) {
      final anterior = _nombre;
      setState(() => _nombre = elegido);
      try {
        await ApiServiceCore.actualizarNombreMascota(widget.usuarioId, elegido);
      } catch (e) {
        if (mounted) {
          setState(() => _nombre = anterior);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(MensajesError.de(context, e,
                  generico: l.mascotaErrorNombre)),
            ),
          );
        }
      }
    }
  }

  /// Nori manda en la pantalla: ocupa casi tres cuartos del ancho. Los topes
  /// suben con el factor, pero el de arriba se queda algo por debajo de la
  /// proporción exacta (serían 372): en tablet el ancho crece mucho más que el
  /// alto, y pasado ese punto Nori empuja los botones fuera de la pantalla.
  double _tamanoMascota(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.72).clamp(185.0, 360.0);

  /// La escena entera: halo detrás, terrario bajo los pies, aro de XP
  /// alrededor y la mascota en medio. Cuatro capas que no se conocen entre
  /// sí — cada una lee de la identidad equipada por su cuenta.
  ///
  /// La caja es algo mayor que la ilustración para dejar sitio al aro por
  /// fuera; el halo desborda incluso eso, y por eso el `Stack` no clipa.
  Widget _escenario(BuildContext context, double pct) {
    final lado = _tamanoMascota(context);
    final caja = lado * 1.12;

    return SizedBox(
      width: caja,
      height: caja,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          HaloIdentidad(tamano: caja),
          Positioned(
            bottom: lado * 0.02,
            child: TerrarioIdentidad(ancho: lado * 0.68),
          ),
          AnilloXpIdentidad(tamano: caja, pct: pct),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: MascotaAnimadaViva(
              // La clave es la ilustración, no el estado: el AnimatedSwitcher
              // tiene que cruzar cuando cambia lo que se ve.
              key: ValueKey(_imagenMascota),
              fase: _fase,
              estado: _estado,
              tamano: lado,
              permiteToque: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;
    final pct = _xpParaSiguienteNivel > 0 ? _xpEnNivelActual / _xpParaSiguienteNivel : 0.0;

    final contenido = _loading
          ? _skeletonMascota(context)
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              // El scroll se conserva aunque el contenido quepa de sobra: es lo
              // que da el gesto de tirar para refrescar. Lo que añade el
              // LayoutBuilder es el `minHeight` del viewport, para que la
              // Column pueda centrarse verticalmente en ese hueco en vez de
              // apelotonarse arriba. Restamos el padding vertical (8 + 24)
              // porque el mínimo se aplica al contenido ya despadeado: sin eso
              // la pantalla scrollearía siempre 32px de más.
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // El clamp cubre el viewport más bajo que el propio
                      // padding: un mínimo negativo revienta BoxConstraints.
                      minHeight: (restricciones.maxHeight - 32).clamp(0.0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // Como hacía el ListView: los hijos ocupan todo el ancho,
                      // que es de lo que tiran la barra de XP y la fila de
                      // nivel.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _escenario(context, pct)),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: _editarNombre,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_nombreVisible(l),
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: t.text)),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.pencil,
                                    size: 16, color: t.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: BurbujaContexto(
                            texto: MensajesMascota.contexto(
                              l,
                              codigoFase: _fase,
                              codigoEstado: _estado,
                              nivel: _nivel,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Progreso desnudo, sin tarjeta: acompaña a Nori en vez
                        // de competir con ella por la atención.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.mascotaNivel(_nivel),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: t.text)),
                            Text(
                                l.mascotaXp(
                                    _xpEnNivelActual, _xpParaSiguienteNivel),
                                style: TextStyle(color: t.textMuted)),
                          ],
                        ),
                        // El progreso ya no va aquí: es el aro que rodea a la
                        // mascota. Lo que queda es la lectura exacta, que el
                        // aro no da.
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              // Sin comida el botón sigue a la vista, apagado:
                              // es la pista de que hay algo que comprar en la
                              // tienda.
                              onPressed: _comidaCantidad > 0 && !_alimentando
                                  ? _alimentar
                                  : null,
                              icon: _alimentando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(LucideIcons.drumstick, size: 18),
                              label: Text(
                                  '${l.mascotaAlimentar} ($_comidaCantidad)'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TiendaScreen(
                                        usuarioId: widget.usuarioId),
                                  ),
                                ).then((_) => _cargarDatos());
                              },
                              icon: const Icon(LucideIcons.store, size: 18),
                              label: Text(l.tiendaTitulo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

    if (widget.embebida) return contenido;

    return Scaffold(
      appBar: AppBar(title: Text(l.mascotaTitulo)),
      body: contenido,
    );
  }

  Widget _skeletonMascota(BuildContext context) {
    final lado = _tamanoMascota(context);
    return SkeletonPulso(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(child: SkeletonBox(width: lado, height: lado, radius: lado / 2)),
          const SizedBox(height: 16),
          const Center(child: SkeletonBox(width: 160, height: 26)),
          const SizedBox(height: 10),
          const Center(child: SkeletonBox(width: 110, height: 14)),
          const SizedBox(height: 24),
          // Sin barra de progreso: ahora el progreso es el aro, y el aro cae
          // dentro del hueco redondo de arriba.
          const SkeletonBox(height: 14),
          const SizedBox(height: 28),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 130, height: 40, radius: 20),
              SizedBox(width: 12),
              SkeletonBox(width: 110, height: 40, radius: 20),
            ],
          ),
        ],
      ),
    );
  }
}
