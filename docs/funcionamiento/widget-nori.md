# Widget de Nori: los datos que deja el core

`WidgetNori` (`lib/services/widget_nori.dart`) guarda, con el paquete
`home_widget`, todo lo que necesita el widget nativo de Nori (T-009, en la app,
en Kotlin) para pintarse sin abrir la app, también al cambiar de día.

**El widget no calcula nada.** El ánimo de cada día lo da el backend (decisión
de Quim, 13-nov); las frases, los colores y los textos ya vienen resueltos. Así
su Nori es siempre la de la app.

No sabe de hábitos: solo habla de progreso (`hechos` de `total`).

## Cómo se usa

- `WidgetNori.iniciar(nombreAndroid: '…')` — lo llama la app (T-009) con el
  nombre del proveedor del widget. **Hasta que alguien lo llame no escribe
  nada**: `conocimiento_app_mobile` no lo llama nunca y no se entera.
- Estático, como `NotificacionesService`. Los seams de test (`guardarClave`,
  `repintar`, `ahora`, `reiniciarParaTest`, `pendiente`) están en la clase.
- **Nunca lanza.** Cualquier error se traga y se escribe con `debugPrint`.
- Las escrituras van en cola, en el orden en que ocurren los cambios.
- Tras cada cambio guardado pide el repintado con
  `HomeWidget.updateWidget(androidName: nombreAndroid)`.
- Los textos se resuelven sin `BuildContext`: `lookupNordayCoreLocalizations`
  con `IdiomaService.localeNotifier.value`.

## Quién escribe cada clave y cuándo

| Cuándo | Qué escribe |
|---|---|
| `iniciar` | identidad (`nori_identidad` y colores) y textos/frases, en el idioma actual |
| Cada lectura correcta de `ApiServiceCore.getMascota` | `nori_sesion`=`true`, `nori_fecha`, `nori_fase`, `nori_nombre`, `nori_animo`, `nori_animos_siguientes`, `nori_asset_*` |
| Cambia `progresoDiaNotifier` y su `fecha` es **hoy** | `nori_hechos`, `nori_total`, `nori_avance`, `nori_progreso_fecha`. Si no es hoy (el usuario mira otro día de la tira), se ignora |
| Cambia `identidadEquipadaNotifier` | `nori_identidad` y los cinco `nori_color_*` |
| Cambia `IdiomaService.localeNotifier` | las cinco `nori_frase_*` y los seis `nori_texto_*` |
| `ApiServiceCore._limpiarSesionLocal` (`logout`, cuenta eliminada, sesión caducada en marcha y token caducado al arrancar) | borra **todas** las claves y deja `nori_sesion`=`false` |

## El contrato (lo que lee T-009)

| Clave | Tipo | Qué es |
|---|---|---|
| `nori_sesion` | bool | Si hay sesión y datos de Nori |
| `nori_fecha` | String `yyyy-MM-dd` | El día al que se refieren `nori_animo` y el progreso (el de la última lectura) |
| `nori_fase` | String | `HUEVO`, `CRIA` o `ADULTO`: el campo `fase` (la elegida), nunca `faseReal`. Sin campo, `HUEVO` (como `MascotaScreen`) |
| `nori_nombre` | String | Nombre de Nori, o vacío |
| `nori_animo` | String | Ánimo de `nori_fecha` (`animo`, con `animoDeMascota`: si no viene, `estado`; sin ninguno, `triste`, como `assetMascota`) |
| `nori_animos_siguientes` | String | JSON tal cual llega de `animosSiguientes`; `[]` si el backend no lo manda |
| `nori_asset_dormida`, `_feliz`, `_exultante`, `_triste` | String | La ruta de `assetMascota(fase: …, estado: …)` para la fase guardada |
| `nori_hechos`, `nori_total` | int | Progreso de hoy |
| `nori_avance` | double | De 0 a 1, el mismo `avance` de `ProgresoDia` |
| `nori_progreso_fecha` | String `yyyy-MM-dd` | El día del progreso guardado |
| `nori_identidad` | String | Código de la identidad equipada (`TEMA_PROFUNDIDAD`…) |
| `nori_color_fondo`, `_superficie`, `_acento`, `_texto`, `_texto_suave` | int (ARGB) | Colores de esa identidad: `tokens.bg`, `surface`, `primary`, `text`, `textMuted` |
| `nori_frase_dormida`, `_feliz`, `_exultante`, `_triste`, `_huevo` | String | `mascotaAnimoAtencion`, `mascotaAnimoFeliz`, `mascotaAnimoExultante`, `mascotaAnimoTriste` y `mascotaAnimoHuevo`, en el idioma de la app |
| `nori_texto_empieza`, `nori_texto_sin_sesion`, `nori_texto_todo_hecho`, `nori_texto_progreso`, `nori_texto_progreso_corto`, `nori_texto_accesible` | String | Textos del widget, ya traducidos |

### Detalles que el widget debe saber

- **Marcadores sin sustituir.** `nori_texto_progreso`, `_progreso_corto` y
  `_accesible` se guardan con `{hechos}`, `{total}` y (el accesible) `{frase}`
  tal cual: lo que cambia cada día lo rellena el widget nativo. `{frase}` es
  la `nori_frase_*` del ánimo (o `nori_frase_huevo` si `nori_fase` es `HUEVO`,
  como `MensajesMascota.contexto`).
- **Las rutas de los dibujos son las de Flutter dentro del paquete del core**:
  `assets/mascota/Nori_{fase}_{estado}.png`, relativas a
  `packages/norday_flutter_core/`. El widget nativo debe resolverlas desde los
  assets de Flutter de la app, no como recursos de Android.
- **Nori sale sin prendas** (decisión de Claude, 19-nov): las prendas se
  descargan dentro de la app y el widget nativo no las ve.
- **Siete días**: `nori_animos_siguientes` trae los de los días siguientes; más
  allá, el widget se queda con el último.
- **El progreso puede ser de ayer.** `nori_progreso_fecha` dice a qué día
  pertenece; si no es hoy, el widget no debe enseñarlo como de hoy.
- **Tras cerrar sesión no queda ningún texto** (se borra todo, incluido
  `nori_texto_sin_sesion`): el widget necesita un texto de respaldo propio para
  `nori_sesion` = `false`. Los textos y la identidad vuelven en el siguiente
  `iniciar` o cambio de idioma/identidad.

## Qué falta

- El widget nativo y su llamada a `iniciar` (T-009, en la app).
- Que el backend mande `animosSiguientes` (T-008a/T-008c); mientras tanto se
  guarda `[]`.
