# Compartir a Nori: `TarjetaNori` y `alCompartir`

T-063a. Dos piezas independientes entre sí y de la escena actual de
`MascotaScreen` (que se rehará): la pantalla nueva las reutiliza tal cual.

## `TarjetaNori` (`widgets/tarjeta_nori.dart`, exportada)

La postal: una imagen quieta de 360 × 450 lógicos (`TarjetaNori.ancho` y
`.alto`), para capturar a 1080 × 1350 con `pixelRatio: 3`.

- Capas: `FondoIdentidad`, `TerrarioIdentidad` (con `nieve` si la app lo
  decide) y `NoriVestida` en la fase dada, **siempre con estado `feliz`** (como
  el avatar, D-39). Nombre (o el de la fase si está vacío) y «Nivel N».
- Sin aro de XP ni halo animado. No llama al backend.
- Parámetros: `fase` (código), `nombre`, `nivel`, `nieve`, `marca`.
  `TarjetaNori.de(DatosNori)` es el atajo desde lo que entrega `alCompartir`.
  `prendas`, `manifiesto` e `imagen` son para tests, como en `NoriVestida`.
- **La marca de abajo** («Norday Habits») sale de `marca` si se pasa; si no, de
  `TextosApp.nombreDe(context)` (lo que la app registró) y, sin registrar, de
  «Norday». El core no conoce ninguna app. Focus lo reutiliza sin tocar nada si
  registra su nombre en `TextosApp`.
- La nieve **no** se decide dentro (no lee la fecha): la app pasa
  `manifiesto.nieveActiva(DateTime.now())` si quiere nieve, como hace la escena.
- Capturar y compartir lo hace la app (`RepaintBoundary` + `toImage`); el fondo
  y las prendas se cargan asíncronas, así que hay que esperar al menos un frame
  tras montarla antes de capturar.

## `MascotaScreen.alCompartir`

`Future<void> Function(DatosNori)?`. `DatosNori` = `fase` (la **elegida**, no la
real), `nombre` (vacío si no tiene) y `nivel`.

- Con él, un `IconButton` (Lucide `share2`) en la esquina superior derecha de la
  escena, con tooltip y etiqueta de accesibilidad `mascotaCompartir` («Compartir
  a Nori»).
- Mientras el futuro no termina el botón está desactivado (no se lanza dos
  veces); se reactiva aunque falle.
- Sin él, la pantalla queda como antes.

Focus lo reutiliza pasando su propio `alCompartir` y, si quiere, `marca`.

## Probarlo a ojo

`NORDAY_NORI_PNG=/carpeta flutter test test/tarjeta_nori_test.dart` exporta la
postal a 1080 × 1350 en las tres identidades (`nori_TEMA_….png`). Sin la
variable, ese test se salta.
