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
- `widgets/` — los 20 genéricos (anillo, puntos, burbuja, check, mascota viva,
  mini-mascota, onboarding, selector de avatar, selector de preferencias,
  skeleton, splash, hoja de valoración, los cinco de la escena de mascota
  —halo, terrario, anillo de XP, burbuja de contexto y celebración de nivel— y
  los tres de las pantallas de entrada: Nori de marca, wordmark de identidad y
  logo de Google).
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
