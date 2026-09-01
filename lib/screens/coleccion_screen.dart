import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/catalogos_core.dart';
import '../l10n/mensajes_error.dart';
import '../services/api_service_core.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/avatares.dart';
import '../theme/equipamiento.dart';
import 'tienda_screen.dart';
import '../widgets/fondo_estelar.dart';
import '../widgets/skeleton.dart';
import '../widgets/selector_avatar_gratis.dart';
import '../widgets/superficie_identidad.dart';

class SeccionColeccion {
  /// Una seccion puede recoger varias categorias del backend: alli
  /// 'Protección' y 'Consumible' son etiquetas distintas, pero de cara al
  /// usuario son lo mismo y van juntas.
  final List<String> categoriasBackend;
  final IconData icono;
  /// Clave de traduccion resuelta al pintar. Las categorias que llegan del
  /// backend y no conocemos caen a su propio texto crudo.
  final String Function(NordayCoreLocalizations)? _titulo;
  const SeccionColeccion(this.categoriasBackend, this.icono, [this._titulo]);

  String titulo(NordayCoreLocalizations l) => _titulo?.call(l) ?? categoriasBackend.first;
}

// Orden fijo de esta app — el motor (categoria en backend) sigue siendo generico.
final seccionesConocidas = [
  SeccionColeccion(['Avatar'], LucideIcons.userRound, (l) => l.colSeccionAvatares),
  SeccionColeccion(['Protección', 'Consumible'], LucideIcons.shield, (l) => l.colSeccionConsumibles),
  SeccionColeccion(['Tema'], LucideIcons.palette, (l) => l.colSeccionTemas),
];

/// Reparte los productos ya agrupados por categoria de backend en las
/// secciones de la pantalla, en el orden declarado arriba. Las categorias que
/// no conoce ninguna seccion caen cada una en la suya, con su texto crudo.
///
/// Vive fuera del State para poder probarlo sin montar el widget.
List<(SeccionColeccion, List<dynamic>)> repartirEnSecciones(
    Map<String, List<dynamic>> agrupado) {
  final conocidas = seccionesConocidas.expand((s) => s.categoriasBackend).toSet();

  // Los productos de una seccion son la union de sus categorias, en el orden
  // en que estan declaradas.
  List<dynamic> productosDe(SeccionColeccion s) =>
      [for (final c in s.categoriasBackend) ...?agrupado[c]];

  return [
    for (final seccion in seccionesConocidas)
      if (productosDe(seccion).isNotEmpty) (seccion, productosDe(seccion)),
    for (final categoria in agrupado.keys.where((c) => !conocidas.contains(c)))
      (SeccionColeccion([categoria], LucideIcons.package), agrupado[categoria]!),
  ];
}

/// Matriz de luminancia (Rec. 709): apaga el color de lo que aun no se tiene
/// sin tocar el alfa, para que el candado siga leyendose encima.
const _filtroGrises = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

const _opacidadBloqueado = 0.45;

class ColeccionScreen extends StatefulWidget {
  final int usuarioId;
  const ColeccionScreen({super.key, required this.usuarioId});

  @override
  State<ColeccionScreen> createState() => _ColeccionScreenState();
}

class _ColeccionScreenState extends State<ColeccionScreen> {
  bool _loading = true;
  List<dynamic> _catalogo = [];
  Map<int, Map<String, dynamic>> _inventario = {};
  int? _procesando;
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
    _cargarDatos();
  }

  /// Sale de `shared_preferences`, no de la red: la tarjeta de arriba lo
  /// necesita para la inicial de caida cuando no hay avatar equipado.
  Future<void> _cargarNombre() async {
    final usuario = await ApiServiceCore.getUsuarioLocal();
    if (!mounted || usuario == null) return;
    setState(() => _nombre = usuario['nombre'] ?? '');
  }

  Future<void> _cargarDatos() async {
    try {
      final catalogo = await ApiServiceCore.getCatalogoProductos();
      final inventario = await ApiServiceCore.getInventarioProductos(widget.usuarioId);

      final mapaInventario = <int, Map<String, dynamic>>{};
      for (final up in inventario) {
        final productoId = up['producto']['productoId'] as int;
        mapaInventario[productoId] = {
          'cantidad': up['cantidad'],
          'equipado': up['equipado'],
        };
      }

      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _inventario = mapaInventario;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarError(e);
    }
  }

  // categoria: para saber qué caché de equipado actualizar (Tema/Avatar) sin
  // pisar la de la otra — antes esto aplicaba siempre el tema, lo que
  // borraba el tema premium equipado al elegir un avatar.
  Future<void> _equipar(int productoId, String? codigo, String categoria) async {
    setState(() => _procesando = productoId);
    try {
      if (categoria == 'Tema') {
        await Equipamiento.equiparTema(widget.usuarioId, productoId, codigo);
      } else if (categoria == 'Avatar') {
        await Equipamiento.equiparAvatar(widget.usuarioId, productoId, codigo);
      }
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  Future<void> _usar(int productoId) async {
    setState(() => _procesando = productoId);
    try {
      await ApiServiceCore.usarProducto(widget.usuarioId, productoId);
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  void _mostrarError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: NordayCoreLocalizations.of(context)!.colError)),
        ),
      );
    }
  }

  void _irATienda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiendaScreen(usuarioId: widget.usuarioId)),
    );
  }

  Map<String, List<dynamic>> _agruparPorCategoria() {
    final mapa = <String, List<dynamic>>{};
    for (final p in _catalogo) {
      mapa.putIfAbsent(p['categoria'] as String, () => []).add(p);
    }
    return mapa;
  }

  /// El producto equipado de una categoria, o null si no hay ninguno — que es
  /// lo normal antes del primer avatar o con el tema de serie.
  dynamic _productoEquipado(String categoria) {
    for (final p in _catalogo) {
      if (p['categoria'] == categoria &&
          _inventario[p['productoId']]?['equipado'] == true) {
        return p;
      }
    }
    return null;
  }

  bool _poseido(dynamic producto) => _inventario.containsKey(producto['productoId']);

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;

    // Ya no es pestaña del shell: se abre como ruta desde el icono de arriba,
    // asi que trae su propia cabecera y su boton de volver.
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.navColeccion),
        // Transparente para que la nebulosa verde —centrada contra el borde
        // superior— se vea a través de la barra en vez de quedar tapada.
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Imprescindible: sin esto Material 3 tiñe el AppBar en cuanto hay
        // scroll debajo y vuelve a tapar la nebulosa.
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        // Un hijo no posicionado de Stack recibe constraints holgadas, no
        // ajustadas como las que daba `body:` directamente.
        fit: StackFit.expand,
        children: [
          // Nivel 2: esta pantalla se abre ENCIMA del shell, así que tiene
          // cielo pero no constelación —la monta el shell—. El cielo tenue
          // dice «sigues dentro» sin fingir un progreso que aquí no se
          // muestra.
          const Positioned.fill(child: FondoEstelar.tenue()),
          SafeArea(child: _loading ? _skeletonColeccion() : _contenido(l, t)),
        ],
      ),
    );
  }

  Widget _skeletonColeccion() {
    return const SkeletonPulso(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 130, radius: AppRadius.lg),
            SizedBox(height: 24),
            SkeletonBox(width: 140, height: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 52, radius: AppRadius.lg),
            SizedBox(height: 24),
            SkeletonBox(width: 140, height: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 68, radius: AppRadius.lg),
            SizedBox(height: 8),
            SkeletonBox(height: 68, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }

  Widget _contenido(NordayCoreLocalizations l, TokensContextuales t) {
    final seccionesConProductos = repartirEnSecciones(_agruparPorCategoria());

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardSeleccionActual(l, t),
          const SizedBox(height: 24),
          for (final (seccion, productos) in seccionesConProductos)
            _seccionWidget(l, seccion, productos, t),
        ],
      ),
    );
  }

  /// Resumen de lo que el usuario lleva puesto ahora mismo: avatar (o inicial
  /// de caida) y la paleta del tema equipado.
  Widget _cardSeleccionActual(NordayCoreLocalizations l, TokensContextuales t) {
    final id = identidad(context);
    final codigoTema = _productoEquipado('Tema')?['codigo'] as String?;
    final identidadTema =
        codigoTema != null ? catalogoIdentidades[codigoTema] : null;
    // Sin tema equipado (o con uno que este cliente aun no conozca) lo que se
    // lleva puesto es el tema de serie: sus colores son los tokens activos.
    final colores = identidadTema != null
        ? [
            identidadTema.tokens.primary,
            identidadTema.tokens.success,
            identidadTema.tokens.points
          ]
        : [t.primary, t.success, t.points];

    // Es el elemento protagonista de la pantalla, y ademas el unico con filo
    // propio: lo que se lleva puesto tiene que separarse de lo que no.
    return SuperficieIdentidad(
      protagonista: true,
      filo: BorderSide(color: t.successText, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.colSeleccionActual,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: t.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              AvatarUsuario(nombre: _nombre, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: t.text)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tiraPaleta(id, colores, alto: 14, radio: 999),
        ],
      ),
    );
  }

  /// Los colores de un tema, uno al lado del otro. Es la representacion del
  /// tema en toda la pantalla: aqui y en su tarjeta.
  ///
  /// El recorte no es un rectangulo redondeado sino la figura de la identidad
  /// equipada: en Neotokyo+ la tira tambien corta la esquina, como todo lo
  /// demas de la pantalla.
  Widget _tiraPaleta(IdentidadPaleta id, List<Color> colores,
      {required double alto, required double radio}) {
    return ClipPath(
      clipper: ShapeBorderClipper(shape: formaIdentidad(id, radio: radio)),
      child: SizedBox(
        height: alto,
        child: Row(
          children: [for (final c in colores) Expanded(child: ColoredBox(color: c))],
        ),
      ),
    );
  }

  Widget _seccionWidget(NordayCoreLocalizations l, SeccionColeccion seccion, List<dynamic> productos,
      TokensContextuales t) {
    final algunoPoseido = productos.any(_poseido);
    final esAvatarSinElegir =
        seccion.categoriasBackend.contains('Avatar') && !algunoPoseido;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabeceraSeccion(l, seccion, productos, t),
          const SizedBox(height: 12),
          if (esAvatarSinElegir) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.colEligeAvatar,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: t.primary)),
            ),
            SelectorAvatarGratis(
              usuarioId: widget.usuarioId,
              onElegido: (_) => _cargarDatos(),
            ),
          ] else ...[
            if (!algunoPoseido) _ganchoTienda(l, seccion.titulo(l), t),
            _cuerpoSeccion(l, seccion, productos, t),
          ],
        ],
      ),
    );
  }

  /// Icono + titulo + cuantos se tienen de cuantos hay, con la misma cuenta
  /// pintada como barra debajo.
  Widget _cabeceraSeccion(NordayCoreLocalizations l, SeccionColeccion seccion,
      List<dynamic> productos, TokensContextuales t) {
    final poseidos = productos.where(_poseido).length;
    final total = productos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(seccion.icono, size: 18, color: t.successText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(seccion.titulo(l),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: t.text)),
            ),
            Text(l.colContador(poseidos, total),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: t.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : poseidos / total,
            minHeight: 4,
            backgroundColor: t.inactivo,
            valueColor: AlwaysStoppedAnimation(t.successText),
          ),
        ),
      ],
    );
  }

  Widget _cuerpoSeccion(NordayCoreLocalizations l, SeccionColeccion seccion,
      List<dynamic> productos, TokensContextuales t) {
    if (seccion.categoriasBackend.contains('Avatar')) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final p in productos) _chipAvatar(p, t)],
      );
    }
    if (seccion.categoriasBackend.contains('Tema')) {
      return Column(
        children: [for (final p in productos) _tarjetaTema(l, p, t)],
      );
    }
    // Consumibles y cualquier categoria que este cliente aun no conozca: la
    // tarjeta de fila con icono sirve para las dos.
    return Column(
      children: [for (final p in productos) _tarjetaConsumible(l, p, t)],
    );
  }

  Widget _ganchoTienda(NordayCoreLocalizations l, String titulo, TokensContextuales t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _irATienda,
        child: Text(l.colDescubre(titulo),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: t.primary)),
      ),
    );
  }

  // ── Avatares ──

  Widget _chipAvatar(dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final info = codigo != null ? catalogoAvatares[codigo] : null;
    final poseido = _poseido(producto);
    final equipado = _inventario[productoId]?['equipado'] == true;
    final procesandoEste = _procesando == productoId;

    // Un avatar que este cliente aun no conozca no rompe la tira: cae al
    // icono generico, como el nombre cae al que manda el backend.
    final Widget imagen = info != null
        ? Image.asset(info.asset, package: 'norday_flutter_core', width: 34, height: 34)
        : Icon(LucideIcons.userRound, size: 24, color: t.textMuted);

    return Tooltip(
      message: CatalogosCore.producto(context, codigo, producto['nombre']),
      child: GestureDetector(
        onTap: procesandoEste
            ? null
            : poseido
                ? (equipado ? null : () => _equipar(productoId, codigo, 'Avatar'))
                : _irATienda,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fondoAvatar,
                  border: equipado
                      ? Border.all(color: t.successText, width: 2.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: poseido
                    ? imagen
                    : Opacity(
                        opacity: _opacidadBloqueado,
                        child: ColorFiltered(colorFilter: _filtroGrises, child: imagen),
                      ),
              ),
              // El candado va fuera del filtro y la opacidad: es lo unico que
              // tiene que seguir leyendose a plena vista.
              if (!poseido) Icon(LucideIcons.lock, size: 18, color: t.text),
              if (procesandoEste)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Temas ──

  Widget _tarjetaTema(NordayCoreLocalizations l, dynamic producto, TokensContextuales t) {
    final id = identidad(context);
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final identidadTema = codigo != null ? catalogoIdentidades[codigo] : null;
    final poseido = _poseido(producto);
    final equipado = _inventario[productoId]?['equipado'] == true;
    final procesandoEste = _procesando == productoId;

    // Un tema que este cliente aun no conozca no tiene colores que enseñar:
    // la tira se queda neutra y la tarjeta sigue siendo legible.
    final colores = identidadTema != null
        ? [
            identidadTema.tokens.primary,
            identidadTema.tokens.success,
            identidadTema.tokens.points
          ]
        : [t.inactivo, t.inactivo, t.inactivo];

    final contenido = _cajaTarjeta(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: _tiraPaleta(id, colores, alto: 40, radio: id.radioSecundario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(CatalogosCore.producto(context, codigo, producto['nombre']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: t.text)),
          ),
          if (poseido) ...[
            const SizedBox(width: 8),
            if (procesandoEste)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (equipado)
              _pastillaEquipado(l, t)
            else
              OutlinedButton(
                onPressed: () => _equipar(productoId, codigo, 'Tema'),
                child: Text(l.tiendaEquipar),
              ),
          ],
        ],
      ),
    );

    if (!poseido) return _envolverBloqueado(contenido, t);
    return contenido;
  }

  Widget _pastillaEquipado(NordayCoreLocalizations l, TokensContextuales t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.successText.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(l.tiendaEquipado,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: t.successText)),
    );
  }

  // ── Consumibles ──

  Widget _tarjetaConsumible(NordayCoreLocalizations l, dynamic producto, TokensContextuales t) {
    final id = identidad(context);
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final categoria = producto['categoria'] as String;
    final poseido = _poseido(producto);
    final cantidad = (_inventario[productoId]?['cantidad'] ?? 0) as int;
    final procesandoEste = _procesando == productoId;
    // 'Protección' es justo la categoria de lo que se gasta solo cuando hace
    // falta (el escudo salta al romperse la racha); lo demas se usa a mano.
    final automatico = categoria == 'Protección';

    final contenido = _cajaTarjeta(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.successText.withValues(alpha: 0.12),
              // La misma figura que la tarjeta que lo lleva: en Neotokyo+ el
              // hueco del icono tambien corta.
              shape: formaIdentidad(id, radio: id.radioSecundario),
            ),
            child: Icon(_iconoConsumible(codigo, categoria), size: 22, color: t.successText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CatalogosCore.producto(context, codigo, producto['nombre']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: t.text)),
                if (automatico) ...[
                  const SizedBox(height: 2),
                  Text(l.colSeActivaSolo,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.textMuted)),
                ],
              ],
            ),
          ),
          if (poseido) ...[
            const SizedBox(width: 8),
            Text(l.colCantidad(cantidad),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: t.text)),
            if (!automatico) ...[
              const SizedBox(width: 10),
              if (procesandoEste)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton(
                  onPressed: cantidad > 0 ? () => _usar(productoId) : null,
                  child: Text(l.colUsar),
                ),
            ],
          ],
        ],
      ),
    );

    if (!poseido) return _envolverBloqueado(contenido, t);
    return contenido;
  }

  /// Por codigo cuando lo conocemos; si no, por categoria, para que un
  /// consumible nuevo del backend siga saliendo con un icono que dice algo.
  IconData _iconoConsumible(String? codigo, String categoria) => switch (codigo) {
        'ESCUDO_RACHA' => LucideIcons.shield,
        'COMIDA_BASICA' => LucideIcons.drumstick,
        _ => categoria == 'Protección' ? LucideIcons.shield : LucideIcons.package,
      };

  // ── Piezas comunes ──

  /// La caja comun de temas y consumibles: la superficie de la identidad
  /// equipada, para que lo unico que cambie entre secciones sea el contenido.
  ///
  /// El filtro de grises de lo bloqueado se aplica por fuera, asi que la caja
  /// no tiene que saber si lo que lleva dentro se tiene o no.
  Widget _cajaTarjeta({required Widget child}) {
    return SuperficieIdentidad(
      esFila: true,
      margen: const EdgeInsets.only(bottom: 8),
      relleno: const EdgeInsets.all(12),
      child: child,
    );
  }

  /// Lo que aun no se tiene: la misma tarjeta apagada y con candado. Tocarla
  /// lleva a la tienda, que es donde se consigue.
  Widget _envolverBloqueado(Widget tarjeta, TokensContextuales t) {
    return GestureDetector(
      onTap: _irATienda,
      child: Stack(
        children: [
          // El candado se queda fuera del filtro: es lo unico que tiene que
          // seguir leyendose a plena opacidad.
          Opacity(
            opacity: _opacidadBloqueado,
            child: ColorFiltered(
              colorFilter: _filtroGrises,
              child: IgnorePointer(child: tarjeta),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Icon(LucideIcons.lock, size: 16, color: t.text),
          ),
        ],
      ),
    );
  }
}
