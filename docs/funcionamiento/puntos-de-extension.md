# Los puntos de extensión

Movido del `CLAUDE.md` (sección «Los puntos de extensión»). La sesión con
bloqueo suave (punto 12) está en `sesion-concentracion.md`.

1. **`LoginScreen.destinoTrasLogin`** y **`PerfilScreen.destinoTrasLogin`** —
   `Widget Function(BuildContext, bool mostrarOnboarding)`. El paquete no sabe
   cuál es la pantalla principal de cada app.
2. **`CatalogosCore.registrarLogrosDeDominio`** — la app le pasa sus logros
   (nombres y descripciones) al arrancar. Aquí sólo viven los que no saben
   de dominio: `BIENVENIDO`, `PRIMEROS_PASOS`, `LOGIN_GOOGLE`, los tres de
   identidad (`IDENTIDAD_PROFUNDIDAD`, `IDENTIDAD_NEOTOKYO_PLUS`,
   `IDENTIDAD_DULCE`), los dos de la mascota (`MASCOTA_CRIA`,
   `MASCOTA_ADULTO`) e `INTERACCION_RESENA` (retirado el 24-ago-2026).
   **`CatalogosCore.registrarProductosDeDominio`** hace lo mismo con los
   productos propios de una app: `nombres`, `descripciones` y `usos`. `usos`
   es para un consumible que no se gasta desde Colección sino desde una
   pantalla de la app: Colección enseña ese texto en vez del botón «Usar»
   (`CatalogosCore.productoUso`). Norday Habits registra así la pausa
   (`PAUSA_HABITO`). Si el core traduce el mismo código, manda el core.
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
   `CapaProgresoIdentidad` donde quiera la constelación (solo Profundidad la
   usa) y, en su lista de Hoy, `LetreroDelDia` (Neotokyo+) y `RamoDelDia`
   (Dulce), cada uno con su `alto` (D-41). Puede pasar además
   el `avance` del día, de 0 a 1 con lo hecho a medias; sin él vale
   `hechos / total`. El core no sabe qué se cuenta.
7. **El cierre del día**: la app monta `CapaCierreDelDia` y llama a
   `mostrarCierreDelDia(titulo:, despedida:)` con los textos ya traducidos,
   cuando se completa lo último del día. La app decide cuándo y cuántas veces
   (Norday Habits: una vez al día por usuario, nunca en el onboarding). Hoy
   hace algo en las tres: en Profundidad (la constelación, que realza su
   capa), en Dulce (el ramo de todas las flores, a grafito como en Hoy, que
   se colorea y se ata en `duracionRamoCierre`) y en Neotokyo+ (el letrero de
   neón, un tubo por hábito, que la ceremonia enciende en grande; los textos
   esperan a `duracionEncendidoLetrero`). El ramo de la lista queda
   debajo del velo y, al irse, ya está en su estado final. El letrero de la
   lista espera apagado mientras dura la ceremonia y se enciende al ritmo del
   velo que se va (si no, se veía doble a través del velo: 20-nov-2026). Lleva lector de pantalla (los tres textos y la acción Cerrar) y vibra al salir el nombre de la constelación. La app envuelve las páginas y la barra con `OcultoAlLectorDuranteCierre` para que el lector no llegue a lo de debajo durante la ceremonia.
8. **`SplashGenerico.rutaImagen`** — el símbolo de cada app. Sin él, el
   splash pinta a Nori (`NoriMarca`).
9. **`ApiServiceCore.appId`** — la cabecera `X-Norday-App` con la que el
   backend filtra los catálogos. Vale `''` por defecto: sin él no se manda
   la cabecera y `VersionMinimaService` no pregunta. Cada app lo fija antes
   de `runApp` (`'habitos'`, `'conocimiento'`, `'enfoque'`…). La llevan los
   dos catálogos, `actualizarFcmToken` (`PUT /usuarios/{id}/fcm-token`) y
   `quitarFcmToken` (al cerrar sesión): el
   backend guarda un token por usuario y app, y sin cabecera lo cuenta como
   `habitos`. Una app desconocida para el backend da 400. El catálogo de
   productos y la compra llevan además `X-Norday-Core` con `versionCore`,
   que no depende de la app (ver «Publicar una versión»).
10. **`NORDAY_API_URL`** — la URL del backend, como constante de compilación:
   `--dart-define=NORDAY_API_URL=<url>`. Sin ella, `ApiServiceCore.baseUrl`
   es producción (`https://api.norday.app/api`). Sigue siendo `const`: las
   apps la copian en las suyas (Norday Habits, en `ApiServiceHabitos`).
11. **`TextosApp`** (`l10n/textos_app.dart`) — los textos que dependen de qué
   app es, como `String Function(BuildContext)` ya traducidos: `nombre`
   (wordmark del login), `lemaLogin`, `actualizacionObligatoria` (cuerpo de
   `ActualizacionObligatoriaScreen`) y `eliminarCuenta` (primera
   confirmación de `PerfilScreen`). La app llama a `TextosApp.registrar(...)`
   en `main()`, antes de `runApp`; registrar sustituye los cuatro, y lo que
   quede a `null` cae en la caída neutra del core (`appTitulo` «Norday»,
   `loginTagline`, `actualizacionTexto`, `perfilEliminarCuerpo`), que no
   nombra ningún dominio. El core lee con `TextosApp.nombreDe(context)` y
   sus hermanos, nunca la clave directamente. El título de la tarea
   (`onGenerateTitle`) es de cada app: no lo pinta el core.
