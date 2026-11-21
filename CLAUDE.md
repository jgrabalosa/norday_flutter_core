# norday_flutter_core — Contexto del proyecto

Paquete Flutter compartido del ecosistema Norday. **No es una app**: no tiene
`main.dart` ni `MaterialApp`. Lo consumen las apps del ecosistema como
dependencia Git.

Consumidores hoy (detalle en `docs/funcionamiento/consumidores.md`):

- `habitos_app_mobile` (Norday Habits) — por tag (`ref: vX.Y.Z`), hoy `v0.60.0`.
- `enfoque_app_mobile` (Norday Focus) — `ref: v0.55.0`; no ve las prendas de Nori.
- `conocimiento_app_mobile` (Norday Conocimiento) — fijado al commit `a873d8f`
  (12-ago-2026, anterior a `v0.1.0`); no recibe nada de lo hecho desde entonces.

## Antes de tocar…, lee…

Este fichero solo lleva lo que vale en cada sesión. El resto está en `docs/`:

- Antes de **añadir o mover un widget, servicio, modelo, pantalla o script**
  (o para saber qué hay y dónde), lee `docs/funcionamiento/inventario-core.md`.
- Antes de **meter en el core algo que huela a dominio** (hábitos, logros,
  textos de una app), lee `docs/funcionamiento/excepciones-motor-disparadores.md`.
- Antes de tocar **cualquier punto por el que la app enchufa algo**
  (`destinoTrasLogin`, `CatalogosCore.registrar…`, `nordayNavigatorKey`,
  `ayudaAnimo`/`ayudaXp`, `alElegir`, progreso y cierre del día,
  `SplashGenerico.rutaImagen`, `ApiServiceCore.appId`, `NORDAY_API_URL`,
  `TextosApp`), lee `docs/funcionamiento/puntos-de-extension.md`.
- Antes de tocar `services/widget_nori.dart` o las claves `nori_*` que lee el
  widget nativo, lee `docs/funcionamiento/widget-nori.md`.
- Antes de tocar `services/sesion_concentracion.dart`,
  `services/motor_sesion.dart` o `widgets/aro_cuenta_atras.dart`, lee
  `docs/funcionamiento/sesion-concentracion.md`.
- Antes de tocar **temas, identidades, `Equipamiento`, `TextTheme`, `aroCheck`
  o los notifiers de tema**, lee `docs/funcionamiento/identidades-y-equipamiento.md`.
- Antes de tocar **`theme/prendas.dart`, `NoriVestida`, `VestidorNori`, la
  sección «Nori» de la tienda o `equiparPrenda`**, lee
  `docs/funcionamiento/prendas-de-nori.md` (y `arte-prendas.md` y
  `nori-canonica.md` para el arte).
- Antes de **tocar nombre, símbolo, tipografía, paleta o iconos de marca**, lee
  `docs/funcionamiento/marca.md`.
- Antes de **subir de versión, taguear o hacer que una app apunte al core**, lee
  `docs/procedimientos/publicar-version.md`.
- Antes de **escribir tests de Flutter** (Firebase, temas, tickers, semántica,
  `clamp`, gen-l10n), lee `docs/lecciones/flutter-y-tests.md`.
- Antes de **dar cifras de verificación, usar rutas entre repos o trabajar con
  prompts largos**, lee `docs/lecciones/metodo-de-trabajo.md`.

## Motor vs Disparadores

**Motor** (genérico, reutilizable) aquí; **Disparadores** (lo que sabe del
dominio) en la app. Aquí: `services/`, `theme/`, `models/`, `widgets/`,
`screens/`, `l10n/`, `assets/` y `tool/` (inventario en `inventario-core.md`).
En la app: `ApiServiceHabitos`, `AnalyticsHabitos`, `Habito`, `HomeShell`,
dashboard, hábitos, `Catalogos` de dominio y `assets/branding/`.

**Ningún widget ni servicio de aquí puede conocer conceptos de dominio** como
"hábito". Si hace falta que el motor pinte algo que sí lo es, se enchufa desde
la app (puntos de extensión), nunca al revés: el paquete no puede importar de
la app. Las excepciones que hoy se la saltan están en
`excepciones-motor-disparadores.md`.

## Compilar y probar

- `flutter analyze` y `flutter test` en verde antes de cada commit.
- Tras editar un `.arb`: `flutter gen-l10n` (analyze no regenera) y commit de lo
  generado.
- Scripts de Python: `py -m unittest discover -s tool/nori_canonica -p "test_*.py"`.
- Un test nuevo debe fallar contra el código sin arreglar; si pasa, no
  demuestra nada: parar.
- Un cambio aquí afecta a todas las apps: antes de tocar una firma pública,
  comprobar quién la usa.

## Git

- `git --no-pager` en `diff` y `log` (abren paginador).
- `git diff HEAD~1` incluye lo no commiteado; para ver solo el commit,
  `git diff HEAD~1 HEAD`.
- Antes de `git tag`, `git --no-pager log -1`. Un cambio no llega a las apps
  solo: merge, tag y luego la app apunta al tag (ver `publicar-version.md`).
- Un solo agente por repo a la vez.

## Assets: siempre con `package:`

Todo `Image.asset` de un asset de este paquete lleva
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

## Reglas de UI e identidad (cada cambio de pantalla)

- La fuente de verdad del equipamiento es el backend, no el dispositivo.
  Ningún `productoId` cableado en el cliente.
- **Una tarjeta o un campo nuevos no se escriben a mano**: `SuperficieIdentidad`
  y `CampoIdentidad`; `formaIdentidad`/`BordeChaflan` para botones, recortes e
  insignias. Quien pinta según la identidad no mira el `codigo` sino
  `IdentidadPaleta.forma` (`switch` exhaustivo sobre `FormaIdentidad`).
- Todo lo que anime lee `MediaQuery.maybeDisableAnimationsOf`.
- `Equipamiento.cargarDeUsuario…` **no se llama en `main()`**: antes del login
  no hay `usuarioId` ni token.
- Son tres identidades (Profundidad, Neotokyo+, Dulce); Alba está eliminada.
- **Espaciado**: rejilla de 4 (`AppSpacing`: 4, 8, 12, 16, 24, 32). Todo lo
  nuevo sale de ahí; lo existente se pasa cuando se toque.
- **Escala de letra**: los titulares van en pasos de 4 (16/20/24/28; la cifra,
  32), con suelo de 11. Un tamaño nuevo se pide a un rol de la escala, nunca con
  `fontSize` a mano.
- Iconos: Lucide Icons. Verde Esmeralda `#27C76F` nunca como texto pequeño sobre
  fondo claro (usar Verde Oscuro `#1EA85B`).
- **Si la cara de Norday es la brújula o Nori está por decidir**: no dar ninguna
  de las dos como decidida.
- Un tamaño o animación sobre un área calculada: protege el recorrido con
  `max(0.0, …)` antes de usarlo en `clamp`, divisor o `width`/`height`
  (detalle en `flutter-y-tests.md`).

## Formato del código

Todo el código Dart va formateado con `dart format`. Antes de cada commit que
toque un `.dart`, desde la raíz: `dart format lib test`.

- Sólo `lib` y `test`. Nunca `dart format .`.
- **Después de formatear, `flutter analyze`.** El formateador parte en varias
  líneas un `if` sin llaves que cabía en una, y entonces salta
  `curly_braces_in_flow_control_structures`. Se arregla poniendo llaves, no
  deshaciendo el formato.
- Un cambio que sólo reformatea va en su propio commit, sin mezclar con código.
- `l10n.yaml` lleva `format: true`: `flutter gen-l10n` deja los
  `norday_core_localizations*.dart` ya formateados. No se quita.

## Estilo de trabajo con el usuario

- Un paso a la vez, confirmar que compila antes de seguir.
- Si algo admite varios diseños o no está claro, preguntar antes de decidir —
  no asumir.

## Lecciones aprendidas

Errores que ya se cometieron una vez; no se vuelven a cometer. Las lecciones
nuevas de Flutter y tests van a `docs/lecciones/flutter-y-tests.md`, las de
publicación a `docs/procedimientos/publicar-version.md` y las de método a
`docs/lecciones/metodo-de-trabajo.md`. Una lección que valga en cada sesión se
añade aquí.

- **La versión va en dos sitios:** la `version:` del `pubspec.yaml` y
  `versionCore` (`lib/version_core.dart`); `test/version_core_test.dart` lo vigila.
- **Un filtro que no encuentra nada no es un resultado.** Ante una salida
  vacía, mirar la fuente completa antes de concluir.
- **Al sustituir un bloque, incluir el comentario de encima.**
