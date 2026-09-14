# norday_flutter_core — Contexto del proyecto

Paquete Flutter compartido del ecosistema Norday. **No es una app**: no tiene
`main.dart` ni `MaterialApp`. Lo consumen las apps del ecosistema como
dependencia Git.

Consumidores hoy:

- `habitos_app_mobile` (Norday Hábitos) — la primera.

## Qué vive aquí y qué vive en cada app

La regla es la de siempre: **Motor** (genérico, reutilizable) aquí;
**Disparadores** (lo que sabe del dominio) en la app.

**Aquí (motor):**

- `services/` — `ApiServiceCore` (sesión, usuario, preferencias, gamificación,
  tienda, mascota, notificaciones), `ApiException`/`TipoErrorApi`,
  `AnalyticsCore` (login y alta), `CelebracionService`, `SonidoService`,
  `IdiomaService`, `ZonaService`.
- `theme/` — `AppTheme` y tokens, `IdentidadPaleta` y `catalogoIdentidades`,
  `catalogoAvatares`, `Equipamiento`, `assetMascota`, `refrescoMascotaNotifier`,
  `tonoError`.
- `models/usuario.dart`.
- `widgets/` — los 22 genéricos (anillo, puntos, burbuja, check, mascota viva,
  mini-mascota, onboarding, selector de avatar, selector de preferencias,
  skeleton, splash, hoja de valoración, los cinco de la escena de mascota
  —halo, terrario, anillo de XP, burbuja de contexto y celebración de nivel—,
  los tres de las pantallas de entrada —Nori de marca, wordmark de identidad y
  logo de Google— y los dos que visten cualquier pantalla:
  `SuperficieIdentidad` y `CampoIdentidad`).
- `screens/` — login, recuperación, tienda, mascota, logros, colección, perfil.
- `l10n/` — `NordayCoreLocalizations` y `CatalogosCore`.
- `assets/` — animations, sounds, mascota, avatares.

**En la app (disparadores):** `ApiServiceHabitos`, `AnalyticsHabitos`,
`Habito`, `HomeShell`, dashboard, hábitos, detalle de hábito, alta/edición de
hábito, `Catalogos` (categorías y logros de hábito), y `assets/branding/`.

**Ningún widget ni servicio de aquí puede conocer conceptos de dominio** como
"hábito". Si hace falta que el motor pinte algo que sí lo es, se enchufa desde
la app (ver los tres puntos de extensión de abajo), nunca al revés: el paquete
no puede importar de la app.

## Los tres puntos de extensión

1. **`LoginScreen.destinoTrasLogin`** y **`PerfilScreen.destinoTrasLogin`** —
   `Widget Function(BuildContext, bool mostrarOnboarding)`. El paquete no sabe
   cuál es la pantalla principal de cada app.
2. **`CatalogosCore.registrarLogrosDeDominio`** — la app le pasa sus logros
   (nombres y descripciones) al arrancar. Aquí solo viven los cuatro que no
   saben de dominio: `BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`,
   `INTERACCION_RESENA`.
3. **`nordayNavigatorKey`** (`navegacion.dart`) — cada app se lo pasa a su
   `MaterialApp` en vez de declarar el suyo. Lo usa `CelebracionService`, que
   puede dispararse desde cualquier sitio.

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

## Equipamiento (tema y avatar)

La fuente de verdad es el backend, no el dispositivo: se lee con
`getInventarioProductos()` y se casa el `codigo` del producto contra
`catalogoIdentidades`/`catalogoAvatares`. Ningún `productoId` está cableado en
el cliente.

Un tema no es sólo color: `catalogoIdentidades` (`theme/identidades_paleta.dart`)
tiene las cuatro identidades —Profundidad, Neotokyo+, Alba, Dulce—, y cada una
lleva además tipografía, radios, forma de superficie y ritmo de animación
(`IdentidadPaleta`, en `theme/identidad_paleta.dart`). Hay tres notifiers y
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

- Tipografía: Manrope (única familia, distintos pesos).
- Paleta: Azul Noche `#0A1628`, Azul Acero `#23395D`, Verde Esmeralda
  `#27C76F` (nunca como texto pequeño sobre fondo claro — usar Verde Oscuro
  `#1EA85B` en ese caso), Gris Muy Claro `#EEF2F6`.
- Iconos: Lucide Icons.
- La mascota es una funcionalidad, no la identidad de marca (eso es el
  logo/brújula).

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
  `flutter pub upgrade norday_flutter_core` en cada una, porque la dependencia
  va por `ref: main` y pub cachea el commit resuelto. Una app fijada a un
  commit viejo del core seguirá con el comportamiento viejo aunque aquí esté
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
