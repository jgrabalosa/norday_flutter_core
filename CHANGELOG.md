# Changelog

Las versiones anteriores a la 0.55.0 no tienen entrada aquí: su historia
está en `git log`.

## Sin publicar

### Cambiado

- **Neotokyo+, el letrero «La ola»:** el sol sube un poco (su centro, de 20 a
  11 sobre 100) y ya no toca la cresta de la ola (Quim, 21-nov-2026).

## 0.59.1 — 20-nov-2026

### Arreglado

- **Neotokyo+, cierre del día:** el letrero de la lista ya no se enciende a
  la vez que el grande de la ceremonia. Se veía doble a través del velo y
  estropeaba la sorpresa. Ahora espera apagado y se enciende, todos los
  tubos a la vez, al ritmo del velo que se va.

## 0.59.0 — 20-nov-2026

### Nuevo

- **El letrero de Neotokyo+ y el ramo de Dulce tienen su sitio en la lista de
  Hoy** (D-41): `LetreroDelDia` y `RamoDelDia`, que monta la app en su lista
  de Hoy y que crecen ahí con cada hábito hecho. El ramo va a grafito
  mientras el día está abierto (`RamoDulce.boceto`). Sustituye a T-030.

### Cambiado

- `CapaProgresoIdentidad` ya no pinta el letrero de Neotokyo+: se formaba
  por encima de toda la pantalla, detrás de los hábitos. Solo la usa
  Profundidad. `CapaLetrero` desaparece.
- La ceremonia del cierre pinta la figura en grande: en Neotokyo+, el
  letrero que se enciende tubo a tubo (`PintorLetreroCeremonia`); en Dulce,
  el ramo entero a grafito, que se colorea y se ata en `duracionRamoCierre`
  (1,9 s), sin depender de cuántos hábitos hay.
- Se exporta `nombreLetrero`, para que la app lo lea en voz alta.
- Los sonidos, más bajos: el de completar baja 8 dB (estaba a -12 LUFS y
  saturaba) y el de logro, 2,5 dB. Los dos quedan a unos -20 LUFS, con los
  picos a -6 dBFS. Mismo formato (MP3, 256 kbps, 44,1 kHz).

## 0.58.0 — 20-nov-2026

### Cambiado

- **El aro del check vacío es amarillo en Profundidad** (`aroCheck`, nuevo
  token de `TokensContextuales`): `#FFB020`, solo en Profundidad. Al
  completar el check el aro se funde con el relleno, y también al deshacer,
  para que no quede un borde amarillo alrededor del verde. Neotokyo+ y Dulce
  no lo declaran y pintan el check igual que antes. `aroVacio` no cambia:
  sigue siendo el contorno del tema, las estrellas de valoración, el
  indicador de nivel y los campos.

## 0.57.0 — 19-nov-2026

### Nuevo

- **El letrero del día de Neotokyo+** (D-35): la figura del día de Neotokyo+,
  como la constelación en Profundidad y el ramo en Dulce.
  - Ocho letreros de neón, uno por número de hábitos (de 1 a 8): la luna, la
    taza, el gato, el ramen, el torii, la ola, el koi y Nori. Cada hábito es
    un tubo (`letreros.dart`, `catalogoLetreros`, `letreroPara`,
    `nombreLetrero`; los dibujos se generan con
    `tool/letreros_neotokyo/generar_dart.py`).
  - De día, `CapaProgresoIdentidad` pinta en Neotokyo+ los tubos de los
    hábitos hechos como cristal apagado (`CapaLetrero`, por delante del
    contenido y con mezcla aditiva, como la constelación). El tubo nuevo
    entra con un fundido.
  - Al cerrar el día, en Hoy, los tubos se encienden uno a uno con el
    parpadeo del neón (uno por tubo, por debajo de los tres destellos por
    segundo de WCAG 2.3.1), en rosa, cian y amarillo, y el letrero entero
    zumba. Después se queda encendido.
  - `mostrarCierreDelDia` tiene ceremonia también en Neotokyo+: el velo, el
    letrero que se enciende y, cuando termina
    (`duracionEncendidoLetrero`), los tres textos con el nombre del letrero.
  - Textos nuevos en es, en y pt: `letreroLuna` … `letreroNori`.

## 0.56.0 — 18-nov-2026

### Nuevo

- **El vestidor y la tienda de Nori** (N-10, T-028):
  - `VestidorNori`, debajo del selector de fases de la pantalla de Nori: una
    fila por sitio con «Nada» y las prendas que tienes, que se ponen y se
    quitan con `Equipamiento.equiparPrenda`/`desequiparPrenda`. Sale del
    inventario que la pantalla ya pide, nunca del catálogo: una prenda que
    ya no se vende sigue siendo tuya. Una prenda que no se ve en la fase de
    ahora avisa: «Se verá cuando Nori sea cría».
  - La tienda gana la sección «Nori»: las prendas a la venta hoy, por
    colección, con una Nori pequeña que la lleva puesta, el precio de la
    oferta de hoy («Gratis», «Hasta el 6 ene»; si se solapan, la de inicio
    más reciente, como el backend), «Tuyo» y «Probar» (Nori en
    grande con la prenda, sin llamar al backend). Sin `ofertas`, el precio de
    siempre; con todas en otros días, no sale (`precioEnTienda`,
    `models/precio_tienda.dart`).
  - Un 409 al comprar (fuera de temporada, actualizar la app o ya es tuyo)
    dice «No se ha podido comprar. Hemos puesto la tienda al día.»
    (`tiendaCompraRechazada`) y recarga la tienda.
  - Colección ya no enseña las prendas.
  - La descripción del gorro de Papá Noel ya no dice «solo por unos días»:
    se regala toda la Navidad y es tuyo para siempre (Quim, 18-nov).
  - `TiendaScreen` gana seams de test (`obtenerSaldo`, `obtenerCatalogo`,
    `obtenerInventario`, `comprar`, `ahora`), y `equiparTema`,
    `equiparAvatar` y `desequiparAvatar` pasan por los de `Equipamiento`
    (en producción, lo mismo que antes).
- **Nori vestida** (N-9, T-027): `NoriVestida` pinta a Nori con lo que lleva
  puesto, por capas sobre la canónica (cuerpo, prenda de cuerpo, de cabeza y
  brote, que una prenda sube u oculta), dentro de la animación. Sale vestida
  en la pantalla de Nori (también las miniaturas de las fases) y en la mini
  Nori de Hoy; sin prendas, exactamente como antes. El lector oye «Lleva: …».
  El manifiesto del arte pasa a ser uno para toda la app
  (`manifiestoArteNotifier`), para la nieve y las prendas. Los 24 cuerpos y
  brotes de la canónica entran en el `pubspec.yaml` (unos 3,5 MB más).
- **El terrario nevado** (Nori vestida, N-11, T-026): `TerrarioIdentidad`
  gana `nieve` (por defecto `false`): un manto quieto sobre el suelo en las
  tres formas (a lápiz en Dulce) y copos que caen, que se paran con «reducir
  animaciones». La pantalla de Nori carga el manifiesto del arte, sin
  esperarlo, y pone la nieve entre sus fechas (la fecha del móvil). Sin
  manifiesto en el servidor, no hay nieve.
- **Nori canónica** (Nori vestida, N-1 y N-2): `assets/mascota/canonica/`,
  los 12 dibujos de Nori separados en cuerpo y brote, con su geometría
  (`docs/funcionamiento/nori-canonica.md`), y `tool/nori_canonica/`, el
  script que los separa y la hoja de revisión del arte. Las apps las usan
  desde N-9 (ver «Nori vestida»).
- **`ImagenMascota`** (`widgets/imagen_mascota.dart`) y
  `ladoOriginalMascota`: una ilustración de Nori descodificada a
  `tamaño × densidad × margen` píxeles, nunca más de 1024 (Nori vestida,
  N-3).
- **La pantalla negra en el contrato:** `Nori_<fase>_<estado>_pantalla.png`
  y su caja (`pantalla`) en `geometria.json`. Ninguna prenda entra en ella;
  su borde puede tocar el canto (regla del arte del 16-nov).
- **El arte de las prendas se descarga** (Nori vestida, N-8, T-021):
  `ArtePrendasService` (`services/arte_prendas_service.dart`) y
  `ManifiestoArte`/`PrendaArte` (`models/manifiesto_arte.dart`). El
  manifiesto (`/arte/manifiesto-v1.json`) y las imágenes WebP se bajan del
  servidor y se guardan en disco; sin red, el último manifiesto bueno, y si
  no hay ninguno, Nori sin prendas. Nada lanza. Ver
  `docs/funcionamiento/arte-prendas.md`.
- **Textos de Nori vestida** (N-12, T-020), en es, en y pt: las cuatro
  prendas y sus descripciones, las colecciones Invierno y Navidad
  (`CatalogosCore.coleccion`), los sitios y los textos del vestidor y de la
  tienda.
- **`tool/nori_canonica/publicar_arte.py`** (Nori vestida, N-13): deja la
  carpeta `arte/` lista para el servidor: cada PNG de una prenda revisada en
  WebP (alfa sin pérdida, comprobado al descodificar; color a calidad 90),
  con la huella de sus píxeles en el nombre, y el manifiesto
  `manifiesto-v1.json` con la prenda añadida (sin tocar las demás) y la
  nieve, si se pide. Ver `docs/funcionamiento/arte-prendas.md`.
- **`tool/nori_canonica/sacar_prenda.py`** (Nori vestida, M-8): saca la
  prenda de una imagen de IA, la alinea con el cuerpo canónico y deja el PNG
  final con un informe, una imagen de control y su `prenda.json`.
- **Las prendas puestas** (Nori vestida, N-7): `theme/prendas.dart`
  (`sitiosPrenda`, `prendasEquipadasNotifier` y `aplicarPrendasEquipadas`),
  y en `Equipamiento`, `equiparPrenda` y `desequiparPrenda`. Lo puesto sale
  del inventario (la `categoria` del producto es el sitio), con copia local
  por usuario para cuando no hay red. Temas y avatares, igual que antes.
- **`versionCore`** (`lib/version_core.dart`, Nori vestida N-6): la versión
  del core, que el catálogo de productos y la compra mandan en
  `X-Norday-Core`. Un test vigila que es la del `pubspec.yaml`. Un backend
  anterior ignora la cabecera.

### Cambia

- **Textos de Nori** (M-3, acordado con marketing el 16-nov): el ánimo
  triste pasa de «te echa de menos» a «te espera» («waiting for you», «à tua
  espera»), sin culpa. Nori es chico: «O Nori cresceu», «comida para o
  Nori», «passa de cria a adulto» y «Give him a name».
- `MascotaAnimadaViva` (y con ella `MiniMascota`, `NoriMarca` y la pantalla
  de Nori), el selector de fases de `MascotaScreen` y `AvatarUsuario` sin
  avatar ya no descodifican el PNG de 1024 × 1024 entero (4 MB por imagen):
  lo piden a su tamaño en pantalla. `MascotaAnimadaViva` deja un margen de
  1,25 para el estirón de la respiración y el squish.
- **Seis Nori a todo color, sin escalones** (pedido de marketing, 18-nov): los
  4 huevos y la cría triste y la dormida dejan de ser de paleta (256 colores)
  y ya no tienen escalones de color en el cuerpo. **Los huevos, sin la sombra
  pegada debajo** (decisión de Quim): ninguna otra fase la tenía y en los
  fondos oscuros parecía una neblina. Su canónica y `geometria.json`,
  regeneradas: la caja del cuerpo de los huevos acaba en y=853 (antes 891).
  Pesan más (de unos 80 KB a 170-400 KB cada una, 1,4 MB en total),
  comprimidas sin pérdida.
- **El token de avisos se reenvía una vez con la cabecera de la app**
  (T-019): `NotificacionesService` apunta lo enviado en
  `fcm_token_enviado_v2_<usuarioId>` y borra la clave antigua. Un móvil que
  envió su token antes de que el backend guardara uno por app (V24), sin
  `X-Norday-App`, lo vuelve a enviar una sola vez al actualizar la app, y su
  fila de `usuario_dispositivo` deja de faltar.
- **Cerrar sesión quita el token de avisos de esta app** (T-004b):
  `ApiServiceCore.logout()` pide al backend, antes de borrar la sesión, que
  quite el token que `NotificacionesService` tiene apuntado como enviado
  (`quitarFcmToken`, `POST /usuarios/{id}/fcm-token/quitar`, con la cabecera
  de la app; solo lo quita si sigue siendo el de este móvil). Tope de 3 s y
  sin bloquear la salida; deja de escuchar las renovaciones. La sesión
  caducada y la cuenta eliminada no llaman al backend. Necesita el backend
  con T-004a.

### Arreglado

- **`BurbujaFlotante` ya no lanza en áreas pequeñas** (T-003a): el recorrido
  de cada eje se protege antes de usarlo como límite de `clamp`, divisor o
  tamaño. Eran los 11 cierres de Crashlytics al arrastrar a Nori en
  pantallas bajas.

### Compatibilidad

- **Dependencia nueva: `path_provider: ^2.1.5`** (la caché del arte, T-021).
  Las apps la reciben sola con `flutter pub upgrade norday_flutter_core`.
- **Los 24 cuerpos y brotes de la canónica entran en el `pubspec.yaml`**:
  unos 3,5 MB más en cada app.
- Ninguna firma pública existente cambia. `MascotaAnimadaViva` gana
  `vestida` (por defecto `false`) y `TerrarioIdentidad`, `nieve` (por
  defecto `false`).
- Necesita el backend con V28 a V30 (ofertas, una prenda por sitio y la
  versión mínima del core) para que salgan las prendas; con uno anterior, la
  tienda y Colección se ven como antes.

## 0.55.0 — 15-nov-2026

### Nuevo

- **`TextosApp`** (`l10n/textos_app.dart`): cada app registra en `main()` su
  nombre, el lema del login, el texto de la actualización obligatoria y el de
  borrado de cuenta (`TextosApp.registrar(...)`). Lo que no registre cae en
  un texto neutro del core.
- **Sesión de concentración con bloqueo suave**:
  - `SesionConcentracion`, `EstadoSesion`, `MotivoPerdida`, `ReglasSesion`
    y `generarClave()` (`services/sesion_concentracion.dart`): la máquina de
    estados pura.
  - `SesionConcentracion.versionFormato` (1), `marcarSalidaPendiente`,
    `quitarSalidaPendiente` y `salidaPendienteMonoMs`.
  - `MotorSesion`, `FuenteReloj`, `FuentePantalla`, `AvisosSesion` y
    `AvisosSesionNulos` (`services/motor_sesion.dart`): ciclo de vida,
    persistencia, recomposición y avisos. `MotorSesion.avisarDesbloqueo()`
    (la app lo llama desde un receptor de `ACTION_USER_PRESENT`) y el
    parámetro `intervaloVigilancia` (2 s): en `paused` con la sesión
    corriendo se consulta la pantalla periódicamente. Sin servicio en primer
    plano no hay garantía completa: Android puede congelar la app.
  - `AroCuentaAtras` (`widgets/aro_cuenta_atras.dart`).
  - Textos: `sesionAvisoSalir`, `sesionAvisoGraciaTitulo`,
    `sesionAvisoGraciaCuerpo`, `sesionAvisoFinTitulo`, `sesionAvisoFinCuerpo`
    y `aroCuentaAtrasEtiqueta` (es, en, pt).

### Cambia

- `appTitulo`, `loginTagline`, `actualizacionTexto` y `perfilEliminarCuerpo`
  pasan a ser la caída neutra («Norday» y frases sin dominio). Las claves
  siguen existiendo. **Una app que no registre sus textos con `TextosApp`
  verá los neutros**: Norday Habits tiene que registrarlos al subir a esta
  versión.
- **`appTitulo` vale ahora «Norday», no «Norday Habits».** Quien lo lea
  directamente —por ejemplo, `onGenerateTitle` del `MaterialApp`, como hace
  hoy Norday Habits— verá «Norday» en el título de la tarea (Recientes)
  hasta que use su propio texto.
- `ApiServiceCore.actualizarFcmToken` manda la cabecera `X-Norday-App` con
  `ApiServiceCore.appId` (sin ella si `appId` está vacío), para que el
  backend guarde un token de avisos por app.

### Arreglado

- **`VersionMinimaService.vigilarAlVolver()` ya no comprueba en el arranque.**
  Escuchaba `onResume`, que en un arranque en frío de Android también salta
  (de ningún estado directamente a `resumed`): era una segunda petición
  además de la del splash y, con el proceso lanzado en segundo plano,
  fallaba por red. Ahora se ignora la primera llegada a primer plano, salvo
  que la app ya estuviera en `resumed` al empezar a vigilar. Volver del
  segundo plano y volver de `inactive` (cortina de notificaciones, diálogo
  del sistema) siguen comprobando. No se usa `onRestart` porque solo salta
  en `paused` → `hidden` y perdería las vueltas desde `inactive`.
- El log `Versión mínima: no se pudo comprobar` incluye el `cuerpo` de la
  `ApiException` (la causa real: DNS, TLS, el cuerpo de un 5xx).
  `ApiException.toString()` no cambia: lo que no se captura acaba en
  Crashlytics y no debe llevar cuerpos.
- `VersionMinimaService.reiniciarParaTest()` (`@visibleForTesting`), para
  los tests del ciclo de vida.

### Reglas de la sesión que conviene saber

- **Reinicio:** al recomponer, una sesión activa se da por perdida
  (`MotivoPerdida.reinicio`) si el reloj monótono está por debajo del
  inicio o si el instante de arranque del móvil (hora de pared menos
  monótono) se ha desplazado más de 5 minutos
  (`ReglasSesion.toleranciaArranque`). Eso incluye **cambiar la hora a mano
  más de 5 minutos con el proceso muerto** durante una sesión.
- Una marca provisional de salida (proceso muerto entre las dos consultas
  de pantalla) cuenta como salida al recomponer.

### Compatibilidad

- Ninguna firma pública existente cambia. Sin dependencias nuevas.
