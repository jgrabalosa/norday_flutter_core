# Qué vive en el core: inventario

Movido del `CLAUDE.md` (sección «Qué vive aquí y qué vive en cada app»). La
regla Motor vs Disparadores sigue en el `CLAUDE.md`; aquí está el inventario
detallado de lo que hay en cada carpeta, y qué se queda en la app.

**Aquí (motor):**

- `services/` — `ApiServiceCore` (sesión, usuario, preferencias, gamificación,
  tienda, mascota, notificaciones), `ApiException`/`TipoErrorApi`,
  `AnalyticsCore` (login y alta), `AvisoActualizacion` (aviso de versión nueva
  con el modo flexible de Play; ver `docs/funcionamiento/aviso-actualizacion.md`),
  `CelebracionService`, `SonidoService`,
  `IdiomaService`, `ZonaService`, `OrigenInstalacionService` (install referrer
  de Play, enviado una vez por dispositivo tras el primer login) y
  `RecorridoService` (si el recorrido guiado
  ya se hizo; sólo un sí o un no) y `NotificacionesService` (el permiso de
  notificaciones y el registro del aviso en el backend: el login solo
  registra si el permiso ya está dado; la app lo pide en contexto. El
  registro es idempotente por usuario y token, escucha las renovaciones del
  token y la app lo llama al arrancar con sesión y al volver a primer plano;
  al cerrar sesión, `logout()` quita el token de esta app en el backend, con
  tope de 3 s y sin bloquear la salida),
  `VersionMinimaService` (la versión mínima por app, `GET
  /api/version/{appId}`: la app pregunta en su splash con
  `hayQueActualizar()` y, si toca, `bloquear()` abre
  `ActualizacionObligatoriaScreen`; `vigilarAlVolver()`, llamado en `main()`,
  comprueba al volver a primer plano, pero no en la primera llegada de un
  arranque en frío, desde 0.55.0. Nunca bloquea por un fallo de red),
  `ArtePrendasService` (el manifiesto y las imágenes del arte de las prendas,
  descargados y guardados en disco; ver `docs/funcionamiento/arte-prendas.md`)
  y el manifiesto compartido (`manifiesto_compartido.dart`:
  `manifiestoArteNotifier`, `asegurarManifiesto` y `recargarManifiesto`, uno
  para la nieve y las prendas),
  y la sesión de concentración con bloqueo suave: `SesionConcentracion` (la
  máquina de estados pura) y `MotorSesion` (ciclo de vida, persistencia y
  avisos; ver los puntos de extensión),
  y `WidgetNori` (deja con `home_widget` los datos que lee el widget nativo de
  Nori; no hace nada hasta que la app llama a `iniciar`; ver
  `docs/funcionamiento/widget-nori.md`).
- `theme/` — `AppTheme` y tokens, `IdentidadPaleta` y `catalogoIdentidades`,
  `Equipamiento`, `assetMascota` y `animoDeMascota` (el ánimo sale de
  `animo` y, si no viene, de `estado`), `refrescoMascotaNotifier`,
  `faseMascotaNotifier` (la fase elegida de la mascota, nunca `faseReal`:
  la llenan `MiniMascota` y `MascotaScreen` al leerla bien y al elegir otra,
  la escucha `AvatarUsuario` y `ApiServiceCore` la vacía al cerrar sesión),
  `tonoError`, `progreso_dia.dart` (cuántos hay, cuántos hechos y cuánto se
  lleva del día con lo hecho a medias, sin decir cuáles: de ahí dibuja el
  fondo), `prendas.dart` (los sitios de las prendas de Nori y lo que lleva
  puesto, ver «Equipamiento») y `catalogoAvatares` (retirado, ver abajo).
- `models/` — `usuario.dart`, `manifiesto_arte.dart` y `precio_tienda.dart`
  (`precioEnTienda`: el precio de hoy de un producto según sus `ofertas`, y
  `esPrenda`).
- `widgets/` — 48 ficheros:
  - versión recomendada (1): `TarjetaVersionRecomendada` (Nori, título, texto
    y «Actualizar» / «Ahora no», sobre `SuperficieIdentidad`; la enseña
    `AvisoActualizacion` en un diálogo, T-061b);
  - figura del día (1): `FiguraDelDia`, la figura de la identidad equipada
    quieta y en su estado final (constelación encendida, ramo atado o letrero
    encendido), a un `tamano` dado, sin animación ni red. Es lo que pinta la
    postal del cierre (T-043, en la app);
  - postal de Nori (1): `TarjetaNori` y `DatosNori`
    (`widgets/tarjeta_nori.dart`): la postal de 360 × 450 para compartir a
    Nori, con Nori siempre contenta; la marca llega por parámetro o por
    `TextosApp`. `DatosNori` (fase, nombre, nivel) es lo que recibe
    `MascotaScreen.alCompartir` (T-063a). Ver `tarjeta-nori.md`;
  - escena de mascota (9): `MascotaAnimadaViva` (con `vestida`, la pinta
    `NoriVestida` dentro de la misma animación; con `reaccion`, un
    `Listenable` cuyo aviso lanza el gesto del toque sin ser un toque: la
    pantalla de la Mascota lo avisa al comer con XP, T-051), `MiniMascota` (vestida),
    `NoriVestida` (Nori con lo que lleva puesto, por capas sobre la canónica;
    sin prendas, el dibujo de siempre; ver `nori-canonica.md`),
    `ImagenMascota` (Nori descodificada a su tamaño en pantalla: todo lo que
    pinte un PNG de Nori pasa por ella; también `AvatarUsuario`, en
    `theme/avatares.dart`, que sin avatar equipado pinta tu Nori vestida,
    con la fase de `faseMascotaNotifier` —sin ella, la cría— y siempre
    feliz: sale en Colección y arriba de Mi cuenta, T-032), halo, terrario (con `nieve`: manto
    quieto y copos, que la pantalla de Nori pone entre las fechas del
    manifiesto del arte), `AnilloIdentidad` (el aro de XP, que también usa el resumen del
    día), `BurbujaContexto` y `CelebracionNivel`;
  - pantallas de entrada (3): `NoriMarca` (con `vestida: true`, solo en el
    login, lleva la prenda de la temporada según el apartado `login` del
    manifiesto del arte, `ManifiestoArte.prendasLogin`; nunca lo equipado de
    nadie; el splash no se viste), `WordmarkIdentidad` y `LogoGoogle`;
  - superficies (2): `SuperficieIdentidad` y `CampoIdentidad`;
  - lenguaje a lápiz (1): `lapiz.dart`, con el trazo, las rayas y
    `BordeLapiz`, que es el lenguaje de Dulce. `BordeLapiz` admite relleno a
    rayas, solo donde se pinta detrás del contenido. En Dulce, botones,
    diálogos, tarjetas, hojas y campos van a lápiz (la forma llega a
    `AppTheme.deTema` por `FuentesIdentidad.forma`). El trazo lleva presión y
    grano, y el sombreado (`pintarSombreado`) una intensidad por punto. Lo que
    se repite se graba una vez en una caché (`pintarConCache`): imágenes a
    la densidad de la pantalla, con su desborde y como mucho 12 millones de
    píxeles. El anillo de Nori, en Dulce, también va a lápiz. Las burbujas
    del fondo y las del ritmo (`IndicadorNivel`) también van a lápiz.
  - papel (1): `grano_papel.dart`, el grano de Dulce, encima de toda la
    pantalla. No recibe toques ni semántica; la app lo monta en Dulce;
  - fondos y cierre del día (12): `FondoIdentidad` y `CapaProgresoIdentidad`
    (las únicas puertas al fondo y a la capa de la constelación), los tres
    dibujos —cielo estelar, ciudad y burbujas—, el catálogo de
    constelaciones, su capa, el cierre del día, el ramo de Dulce
    (`RamoDulce`, con `boceto` a grafito, y `nombreRamo`) y el letrero de
    Neotokyo+ (`letreros.dart` con sus datos generados en
    `letreros_datos.dart`; D-35). **El letrero y el ramo del día tienen su
    sitio en la lista de Hoy** (D-41, 20-nov-2026): `LetreroDelDia` y
    `RamoDelDia`, que monta la app y que crecen ahí con cada hábito hecho.
    Antes el letrero iba en una capa por encima de la pantalla y se formaba
    detrás de los hábitos;
  - guía (2): `AyudaCampo` (el interrogante junto a un campo) y `CoachMark`
    (el foco del recorrido guiado). `AyudaCampo` acepta un `id` opcional
    (minúsculas y guiones bajos: `tienda`, `coleccion`): con él, abrir la
    nota —no cerrarla— registra el evento `ayuda_abierta` (parámetro `ayuda`)
    por `AnalyticsCore.ayudaAbierta`; sin él no registra nada. Seam de test:
    `AnalyticsCore.enviarEvento`. Con `alSaberMas` (`VoidCallback?`) la nota
    lleva debajo «Saber más →», que la cierra y llama al callback. Cerca de
    ellos, `services/escribir_a_norday.dart` (`escribirANorday`) y la pista de
    la tienda (ver `CLAUDE.md`, «Ayudas y pistas»);
  - sesión (1): `AroCuentaAtras`, la cuenta atrás `mm:ss` dentro del
    `AnilloIdentidad`, que se vacía con el tiempo;
  - genéricos (10): anillo de progreso, `+X` flotante, check, skeleton,
    splash, hoja de valoración, selector de idioma y zona,
    `EstrellaValoracion` (la estrella de la valoración: a lápiz en Dulce),
    `BurbujaFlotante` (arrastre que gana al pager) e
    `IndicadorNivel` (un nivel de 1 a 5 con el dibujo de la identidad:
    estrellas en Profundidad, ventanas en Neotokyo+ y burbujas a lápiz en
    Dulce);
  - tienda y vestidor (2): la vista previa de una identidad y
    `VestidorNori` (ver «Las prendas de Nori»);
  - retirado (1): `SelectorAvatarGratis`.
- `screens/` — 9 pantallas: login, recuperación, elección de identidad
  (onboarding), tienda, mascota, logros, colección, perfil y actualización
  obligatoria (`ActualizacionObligatoriaScreen`).
- `l10n/` — `NordayCoreLocalizations`, `CatalogosCore`, `MensajesError`
  (errores de red al idioma activo), `MensajesMascota` (fase, estado y
  frase de la mascota) y `TextosApp` (los textos que dependen de qué app es;
  ver los puntos de extensión).
- `assets/` — animations (`confetti.json`, sin uso desde que
  `CelebracionService` dejó Lottie), sounds, mascota y avatares (retirados).
  `assets/mascota/canonica/` es Nori separada en cuerpo y brote, con su
  geometría y la máscara de la pantalla negra (Nori vestida, N-1): un
  contrato para el arte de las prendas,
  en `docs/funcionamiento/nori-canonica.md`. Desde N-9 se declaran en el
  `pubspec.yaml`, uno a uno, sus 24 cuerpos y brotes (no las máscaras ni
  `geometria.json`, que son de las herramientas).
- `tool/nori_canonica/` — scripts de Python: `separar_brote.py` (genera esa
  carpeta), `hoja_revision.py` (la hoja con la que se revisa el arte de Nori
  y de sus prendas, N-2) y `sacar_prenda.py` (saca la prenda de una imagen de
  IA y la deja en el lienzo de Nori, M-8) y `publicar_arte.py` (pasa las
  prendas revisadas a WebP con el alfa sin pérdida y la huella de los
  píxeles en el nombre, y escribe el manifiesto, N-13), con sus tests
  (`py -m unittest discover -s tool/nori_canonica -p "test_*.py"`).
- `tool/letreros_neotokyo/` — `letreros.py` (los 8 letreros de Neotokyo+ en
  PNG, para revisarlos; necesita Pillow y numpy) y `generar_dart.py`, que
  escribe `lib/widgets/letreros_datos.dart` (y lo formatea con `dart`). Un
  letrero se cambia ahí y se vuelve a generar, nunca a mano en el `.dart`.

**En la app (disparadores):** `ApiServiceHabitos`, `AnalyticsHabitos`,
`Habito`, `HomeShell`, dashboard, hábitos, detalle de hábito, alta/edición de
hábito, `Catalogos` (categorías y logros de hábito), y `assets/branding/`.
