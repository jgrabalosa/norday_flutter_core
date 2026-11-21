# Equipamiento e identidades

Movido del `CLAUDE.md` (sección «Equipamiento»). Las prendas de Nori están en
`prendas-de-nori.md`.

La fuente de verdad es el backend, no el dispositivo: se lee con
`getInventarioProductos()` y se casa el `codigo` del producto contra
`catalogoIdentidades`. Ningún `productoId` está cableado en el cliente.

Un tema no es sólo color: `catalogoIdentidades` (`theme/identidades_paleta.dart`)
tiene tres identidades, y cada una lleva además tipografía, radios, forma de
superficie, fondo y ritmo de animación (`IdentidadPaleta`, en
`theme/identidad_paleta.dart`):

| Identidad | Código | Títulos | Cuerpo | Forma | Fondo |
|---|---|---|---|---|---|
| Profundidad | `TEMA_PROFUNDIDAD` | Space Grotesk | Manrope | `glass` | cielo estelar, con constelación |
| Neotokyo+ | `TEMA_NEOTOKYO_PLUS` | Chakra Petch | IBM Plex Sans | `chamfer` | ciudad |
| Dulce | `TEMA_DULCE` | Quicksand | Caveat | `pill` a lápiz | papel claro (y burbujas) |

Dulce escribe en Caveat, agrandada un 25 % (`escalaLectura`), y sus nombres de
ítem van también en Caveat (`nombresEnLectura`). Los titulares, en Quicksand.

**Son tres.** Alba se eliminó del cliente el 8-oct-2026: ya no está en el
catálogo ni existe `FormaIdentidad.hairline`. En el backend, `TEMA_ALBA`
sigue con `activo = false`.

**Avatares retirados** desde el 15-sep-2026. `catalogoAvatares`,
`SelectorAvatarGratis`, `assets/avatares/` y sus textos siguen aquí como
esqueleto, pero Norday Habits no los usa y el backend los tiene inactivos.
El avatar del usuario es Nori.

**`aroCheck` y `aroVacio`** (`TokensContextuales`): `aroVacio` es el contorno
de lo vacío en general (`ColorScheme.outline`, estrellas de valoración,
`IndicadorNivel`, campos). `aroCheck` es solo el aro del `CheckCircular` vacío
(y su check insinuado) y el check de muestra de la vista previa de la tienda;
sin declarar vale su `aroVacio`. Solo Profundidad lo declara, en `#FFB020`
(10,6:1 sobre `bg`): sus filas van sin caja sobre el cielo y el check tiene
que leerse de un vistazo, amarillo (por hacer) a verde (hecho). Para no dejar
un borde amarillo alrededor del verde, en Profundidad el aro pasa al color del
relleno a medida que éste crece (y vuelve al deshacer); Neotokyo+ y Dulce
pintan el check como siempre. No se cambió `aroVacio` porque todo lo demás se
volvería amarillo.

Hay tres notifiers y
`aplicarIdentidadEquipada` mueve los tres: `identidadEquipadaNotifier` (la
identidad completa), `fuentesEquipadasNotifier` (las familias, la escala de
lectura, `nombresEnLectura` y la forma: lo que `AppTheme.deTema` necesita sin
poder importar el catálogo) y
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
y `CampoIdentidad` (`widgets/`) ya resuelven los tres tratamientos, y
`formaIdentidad`/`BordeChaflan` dan la figura para botones, recortes e
insignias. En Neotokyo+ las secundarias son transparentes y el filo puede ir
`fijo`, `latiendo` o `encendido` (`FiloNeon`). Un `Card` de Material en medio
de una pantalla achaflanada canta, y cuatro copias del mismo `switch` acaban
divergiendo. Es el equivalente aquí de `identidad_ui.dart` en la app de
hábitos.

`Equipamiento.cargarDeUsuario(usuarioId)` y
`Equipamiento.cargarDeUsuarioSiSePuede(usuarioId)` **no se pueden llamar en
`main()`**: antes del login no hay ni `usuarioId` ni token. Van tras el login y
tras el splash con sesión guardada, así que hasta que responde se ve el tema
por defecto. Sigue sin ser fuente de verdad —manda siempre el backend—, pero
las dos guardan por usuario la última identidad que el backend confirmó
(`identidad_equipada_<usuarioId>`); no se borra al cerrar sesión.
`cargarDeUsuario` deja subir el fallo de red. `cargarDeUsuarioSiSePuede` no:
aplica esa copia y reintenta hasta 3 veces cada 15 s.

