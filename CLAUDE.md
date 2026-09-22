# norday_flutter_core — Contexto del proyecto

Paquete Flutter compartido del ecosistema Norday. **No es una app**: no tiene
`main.dart` ni `MaterialApp`. Lo consumen las apps del ecosistema como
dependencia Git.

Consumidores hoy:

- `habitos_app_mobile` (Norday Habits) — por tag (`ref: vX.Y.Z`).
- `conocimiento_app_mobile` (Norday Conocimiento) — fijado al commit
  `a873d8f`, del 12-ago-2026, anterior a `v0.1.0`. No recibe nada de lo que
  se ha hecho aquí desde entonces.

## Qué vive aquí y qué vive en cada app

La regla es la de siempre: **Motor** (genérico, reutilizable) aquí;
**Disparadores** (lo que sabe del dominio) en la app.

**Aquí (motor):**

- `services/` — `ApiServiceCore` (sesión, usuario, preferencias, gamificación,
  tienda, mascota, notificaciones), `ApiException`/`TipoErrorApi`,
  `AnalyticsCore` (login y alta), `CelebracionService`, `SonidoService`,
  `IdiomaService`, `ZonaService` y `RecorridoService` (si el recorrido guiado
  ya se hizo; sólo un sí o un no).
- `theme/` — `AppTheme` y tokens, `IdentidadPaleta` y `catalogoIdentidades`,
  `Equipamiento`, `assetMascota`, `refrescoMascotaNotifier`, `tonoError`,
  `progreso_dia.dart` (cuántos hay y cuántos hechos en el día, sin decir
  cuáles: de ahí dibuja el fondo) y `catalogoAvatares` (retirado, ver abajo).
- `models/usuario.dart`.
- `widgets/` — 33 ficheros:
  - escena de mascota (7): `MascotaAnimadaViva`, `MiniMascota`, halo,
    terrario, `AnilloIdentidad` (el aro de XP, que también usa el resumen del
    día), `BurbujaContexto` y `CelebracionNivel`;
  - pantallas de entrada (3): `NoriMarca`, `WordmarkIdentidad` y `LogoGoogle`;
  - superficies (2): `SuperficieIdentidad` y `CampoIdentidad`;
  - fondos y cierre del día (8): `FondoIdentidad` y `CapaProgresoIdentidad`
    (las únicas puertas), los cuatro dibujos —cielo estelar, ciudad,
    burbujas y amanecer (de Alba)—, el catálogo de constelaciones, su capa y
    el cierre del día;
  - guía (2): `AyudaCampo` (el interrogante junto a un campo) y `CoachMark`
    (el foco del recorrido guiado);
  - genéricos (9): anillo de progreso, `+X` flotante, check, skeleton,
    splash, hoja de valoración, selector de idioma y zona, onboarding de dos
    pasos y `BurbujaFlotante` (arrastre que gana al pager);
  - tienda (1): la vista previa de una identidad;
  - retirado (1): `SelectorAvatarGratis`.
- `screens/` — login, recuperación, elección de identidad (onboarding),
  tienda, mascota, logros, colección, perfil.
- `l10n/` — `NordayCoreLocalizations`, `CatalogosCore`, `MensajesError`
  (errores de red al idioma activo) y `MensajesMascota` (fase, estado y
  frase de la mascota).
- `assets/` — animations, sounds, mascota y avatares (retirados).

**En la app (disparadores):** `ApiServiceHabitos`, `AnalyticsHabitos`,
`Habito`, `HomeShell`, dashboard, hábitos, detalle de hábito, alta/edición de
hábito, `Catalogos` (categorías y logros de hábito), y `assets/branding/`.

**Ningún widget ni servicio de aquí puede conocer conceptos de dominio** como
"hábito". Si hace falta que el motor pinte algo que sí lo es, se enchufa desde
la app (ver los puntos de extensión de abajo), nunca al revés: el paquete
no puede importar de la app.

**Excepciones conocidas**, que se saltan la regla y están pendientes de
limpiar:

- `ApiServiceCore.appId` vale `'habitos'` por defecto. Norday Conocimiento
  tiene que cambiarlo a `'conocimiento'` al arrancar.
- `constelacionPara` y `nombreConstelacion` reciben `totalHabitos`.
- La vista previa de la tienda (`preview_identidad_tienda.dart`) pinta
  tarjetas de hábito y la pestaña «Hábitos», con textos del core
  (`tiendaPreviewHabito2`, `tiendaPreviewNavHabitos`…).

## Los puntos de extensión

1. **`LoginScreen.destinoTrasLogin`** y **`PerfilScreen.destinoTrasLogin`** —
   `Widget Function(BuildContext, bool mostrarOnboarding)`. El paquete no sabe
   cuál es la pantalla principal de cada app.
2. **`CatalogosCore.registrarLogrosDeDominio`** — la app le pasa sus logros
   (nombres y descripciones) al arrancar. Aquí sólo viven los que no saben
   de dominio: `BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`, los tres de
   identidad (`IDENTIDAD_PROFUNDIDAD`, `IDENTIDAD_NEOTOKYO_PLUS`,
   `IDENTIDAD_DULCE`), los dos de la mascota (`MASCOTA_CRIA`,
   `MASCOTA_ADULTO`) e `INTERACCION_RESENA` (retirado el 24-ago-2026).
3. **`nordayNavigatorKey`** (`navegacion.dart`) — cada app se lo pasa a su
   `MaterialApp` en vez de declarar el suyo. Lo usa `CelebracionService`, que
   puede dispararse desde cualquier sitio.
4. **`MascotaScreen.ayudaAnimo`** y **`MascotaScreen.ayudaXp`** — `Widget?`.
   El core deja el hueco de la ayuda y la app pone el texto, porque explicar
   por qué Nori está como está o de dónde sale la XP es hablar del dominio.
5. **`EleccionIdentidadScreen.alElegir`** — qué hace la app cuando el usuario
   ha elegido su identidad gratis en el onboarding.
6. **El progreso del día**: la app publica cuántos hay y cuántos hechos con
   `publicarProgresoDia` (y `limpiarProgresoDia`), y monta
   `CapaProgresoIdentidad` donde quiera la constelación. El core no sabe qué
   se cuenta.
7. **El cierre del día**: la app monta `CapaCierreDelDia` y llama a
   `mostrarCierreDelDia(titulo:, despedida:)` con los textos ya traducidos,
   cuando se completa lo último del día. La app decide cuándo y cuántas veces
   (Norday Habits: una vez al día por usuario, nunca en el onboarding). Hoy
   sólo hace algo en Profundidad; en las demás identidades termina en el acto.
8. **`SplashGenerico.rutaImagen`** — el símbolo de cada app. Sin él, el
   splash pinta a Nori (`NoriMarca`).
9. **`ApiServiceCore.appId`** — la cabecera `X-Norday-App` con la que el
   backend filtra los catálogos. Ver las excepciones de arriba.

## Assets: siempre con `package:`

Todo `Image.asset`/`Lottie.asset` de un asset de este paquete lleva
`package: 'norday_flutter_core'`. La excepción es la `rutaImagen` opcional de
`SplashGenerico` — ahí no se pone, porque ese asset lo pasa **la app** y no es
nuestro. Sin `rutaImagen`, el splash pinta a Nori (`NoriMarca`), que sí es
nuestra y sí lleva el prefijo. `SonidoService` no usa `package:` sino un `AudioCache` con prefijo
`packages/norday_flutter_core/assets/`, que es como audioplayers resuelve un
asset de paquete.

## Textos

Ninguna pantalla lleva literales: todo va a `lib/l10n/core_*.arb` (`es` es la
plantilla) y se accede con `NordayCoreLocalizations.of(context)!`. La clase se
llama así, y no `AppLocalizations`, para no chocar con la de cada app: las dos
conviven en `localizationsDelegates`.

**Excepción a la disciplina de la app:** aquí los `norday_core_localizations*.dart`
generados **sí se versionan**. `flutter pub get` no ejecuta `gen-l10n` sobre
una dependencia Git, así que sin ellos el paquete no compila en quien lo usa.
Tras tocar un `.arb`, `flutter gen-l10n` y commit de lo generado.

Los catálogos llegan del backend con `codigo` y se traducen con
`CatalogosCore`. **Caída obligatoria**: si el código no está traducido —o
viene a `null`— se muestra el nombre que manda el backend. Nunca un código
crudo.

## Equipamiento

La fuente de verdad es el backend, no el dispositivo: se lee con
`getInventarioProductos()` y se casa el `codigo` del producto contra
`catalogoIdentidades`. Ningún `productoId` está cableado en el cliente.

Un tema no es sólo color: `catalogoIdentidades` (`theme/identidades_paleta.dart`)
tiene cuatro identidades, y cada una lleva además tipografía, radios, forma de
superficie, fondo y ritmo de animación (`IdentidadPaleta`, en
`theme/identidad_paleta.dart`):

| Identidad | Código | Títulos | Cuerpo | Forma | Fondo |
|---|---|---|---|---|---|
| Profundidad | `TEMA_PROFUNDIDAD` | Space Grotesk | Manrope | `glass` | cielo estelar, con constelación |
| Neotokyo+ | `TEMA_NEOTOKYO_PLUS` | Chakra Petch | IBM Plex Sans | `chamfer` | ciudad |
| Dulce | `TEMA_DULCE` | Quicksand | Nunito (acento: Caveat) | `pill` | burbujas |
| Alba | `TEMA_ALBA` | Fraunces | Work Sans | `hairline` | amanecer |

**Salen tres.** Alba está retirada desde el 6-sep-2026: sigue en el catálogo
del cliente, pero el backend tiene `TEMA_ALBA` con `activo = false` y ninguna
pantalla la ofrece, porque todas parten de lo que manda el backend (la
elección del onboarding descarta los productos inactivos). Quitarla del
catálogo y `FormaIdentidad.hairline` está pendiente para después de la salida.

**Avatares retirados** desde el 15-sep-2026. `catalogoAvatares`,
`SelectorAvatarGratis`, `assets/avatares/` y sus textos siguen aquí como
esqueleto, pero Norday Habits no los usa y el backend los tiene inactivos.
El avatar del usuario es Nori.

Hay tres notifiers y
`aplicarIdentidadEquipada` mueve los tres: `identidadEquipadaNotifier` (la
identidad completa), `fuentesEquipadasNotifier` (sólo las dos familias, que es
lo que `AppTheme.deTema` necesita sin poder importar el catálogo) y
`temaEquipadoNotifier` (sólo los colores, que es lo que escucha el
`MaterialApp` de cada app y las pantallas aún sin migrar). El color va el
último a propósito: es el que dispara el repintado, así que cuando salta, la
letra ya está puesta.

El `TextTheme` sale de la identidad equipada: `display*`/`headline*`/`title*`
en `fontDisplay`, `body*`/`label*` en `fontBody`. `fontAcento` no entra en ese
mapeo —se invoca a mano en el único detalle que la usa—, y **las mayúsculas,
el tracking y la itálica tampoco**: eso lo aplica cada pantalla donde tiene
sentido. En el tema global, Neotokyo+ pondría en mayúsculas hasta el cuerpo de
un artículo.

Quien pinta según la identidad no mira el `codigo` sino
`IdentidadPaleta.forma`: los cinco widgets de la escena de mascota resuelven su
tratamiento con un `switch` exhaustivo sobre `FormaIdentidad`. Una identidad
nueva declara su forma y hereda halo, terrario, aro y burbuja; una forma nueva
rompe la compilación justo en los sitios que hay que revisar. Todo lo que anime
lee `MediaQuery.maybeDisableAnimationsOf`, como ya hacía `MascotaAnimadaViva`.

**Una tarjeta o un campo nuevos no se escriben a mano**: `SuperficieIdentidad`
y `CampoIdentidad` (`widgets/`) ya resuelven los cuatro tratamientos, y
`formaIdentidad`/`BordeChaflan` dan la figura para botones, recortes e
insignias. Un `Card` de Material en medio de una pantalla achaflanada canta, y
cuatro copias del mismo `switch` acaban divergiendo. Es el equivalente aquí de
`identidad_ui.dart` en la app de hábitos.

`Equipamiento.cargarDeUsuario(usuarioId)` **no se puede llamar en `main()`**:
antes del login no hay ni `usuarioId` ni token. Va tras el login y tras el
splash con sesión guardada, así que hasta que responde se ve el tema por
defecto. Ya no se usa `SharedPreferences` para esto — era una segunda fuente
de verdad y se desincronizaba al equipar desde otro dispositivo.

## Identidad de marca

- **Nombre**: la app es **Norday Habits**, en todos los idiomas. **Norday** es
  la marca del ecosistema.
- **Símbolo**: la brújula con la N. Hoy es el icono de Norday Habits en Play y
  su splash. Es un asset de cada app, no de este paquete.
- **Nori** es la mascota y una funcionalidad central, y también aparece como
  presencia de marca en el login y en el splash por defecto (`NoriMarca`).
  **Si la cara de Norday es la brújula o Nori está por decidir**, después de
  la prueba cerrada con testers. Hasta entonces, no dar ninguna de las dos
  como decidida.
- **Tipografía**: la guía original fijaba Manrope como única familia. Hoy el
  tema por defecto (sin identidad equipada) usa Space Grotesk para titulares
  y Manrope para el cuerpo, y cada identidad trae las suyas (tabla de arriba).
- **Paleta**: Azul Noche `#0A1628`, Azul Acero `#23395D`, Verde Esmeralda
  `#27C76F` (nunca como texto pequeño sobre fondo claro — usar Verde Oscuro
  `#1EA85B` en ese caso), Gris Muy Claro `#EEF2F6`.
- **Iconos**: Lucide Icons.

## Estilo de trabajo con el usuario

- Un paso a la vez, confirmar que compila antes de seguir.
- Si algo admite varios diseños o no está claro, preguntar antes de decidir —
  no asumir.
- Un cambio aquí afecta a todas las apps del ecosistema: antes de tocar una
  firma pública, comprobar quién la usa.

## Lecciones aprendidas

Errores que ya se cometieron una vez. No se vuelven a cometer.

### Flutter y tests

- **En `flutter test` Firebase no está inicializado**: acceder a
  `FirebaseAnalytics.instance` lanza `[core/no-app]`. Sirve para probar que un
  servicio no deja escapar el fallo. Ojo en sentido contrario: un servicio de
  aquí que espere a Firebase sin que la app lo haya inicializado bloquea el
  login de esa app.
- **`MaterialApp` interpola el tema con `AnimatedTheme`** y `TextStyle.lerp` no
  mezcla familias: en tests que cambian de identidad, `pumpAndSettle`, no
  `pump`.
- **El ticker de una animación toma la hora de inicio en su primer tic**: en
  tests de duración, un `pump()` sin duración antes de medir.
- **`containsSemantics` está deprecado desde Flutter 3.40** en favor de
  `isSemantics`, que tiene los mismos parámetros y también sólo comprueba lo
  indicado.
- **Tras editar un ARB, `flutter analyze` no regenera las traducciones**:
  `flutter gen-l10n` antes.
- **El analizador de Dart promociona a no nulo a través de un `bool`
  intermedio.** Si `final bool b = x != null && ...`, dentro de `if (b)` la
  variable `x` ya es no nula: añadir `&& x != null` ahí dispara
  `unnecessary_null_comparison`.
- **Test en rojo antes del arreglo.** Si el test nuevo pasa contra el código
  sin arreglar, no demuestra nada: parar.

### Publicar una versión

- **Antes de `git tag`, `git --no-pager log -1`.** Se creó y subió `v0.9.0`
  sobre el commit de `v0.8.0` porque se saltaron el merge y el cambio de
  versión. Se arregla con `git tag -d` y `git push origin --delete <tag>` si
  nadie apunta aún a él.
- **Un tag anotado resuelve a su commit, no a sí mismo**:
  `git rev-parse <tag>^{commit}`.
- **`git ls-remote origin <patrón>` no muestra la línea `^{}`** del tag: el
  patrón no casa con ella. Listar con `--tags` para verla.
- **Un cambio aquí no llega solo a las apps**: hay que hacer push y luego
  `flutter pub upgrade norday_flutter_core` en cada una, porque pub cachea
  el commit resuelto. La dependencia va por tag: se mergea y se tagea aquí
  primero, y luego la app apunta al tag nuevo. Una app fijada a un commit
  viejo del core seguirá con el comportamiento viejo aunque aquí esté
  arreglado.

### Método de trabajo (vale para los cuatro repos)

- **La primera línea de un prompt se comprueba, no se recuerda.** Tres repos
  están en `C:\Dev\Norday\` (`habitos-app`, `habitos_app_mobile`,
  `norday_flutter_core`) y `conocimiento_app_mobile` está en
  `C:\Dev\Conocimiento\`.
- **Un solo agente por repo a la vez.** Todo lo que haga otro agente se revisa
  en el remoto antes de mergear.
- **Las cifras de verificación se cuentan contra el repositorio**, nunca se
  copian del roadmap. Y son cifras exactas, no adjetivos.
- **Enumerar sin asumir el patrón**: buscar por la forma que ya has visto sólo
  encuentra lo que ya sabías.
- **Un filtro que no encuentra nada no es un resultado.** Ante una salida
  vacía, mirar la fuente completa antes de concluir.
- **Un fichero de diagnóstico no prueba nada por existir.** Abrirlo y
  comprobar que contiene el fallo antes de darlo por documentado.
- **La base de una rama `wip` envejece.** Antes de dar una cifra, comprobar de
  qué commit sale la rama.
- **Al sustituir un bloque, incluir el comentario de encima.** Si no, el
  comentario queda sobre otra declaración y describe algo que ya no es cierto.
- **No escribir en el código el término cuya ausencia se va a verificar.**
- **Mirar dónde se pega cada bloque.** Un bloque para la máquina local,
  lanzado en el VPS, llegó a `git push` y pidió credenciales.
- **`git diff` y `git log` abren paginador**: `git --no-pager`.
- **`git diff HEAD~1` compara con el directorio de trabajo**: incluye lo no
  commiteado. Para ver sólo el commit, `git diff HEAD~1 HEAD` o el remoto.
- **PowerShell 5.1 lee los `.ps1` sin BOM como ANSI**: scripts sin acentos, o
  guardados con BOM.
