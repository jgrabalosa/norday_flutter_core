# Nori canónica: el contrato de geometría

_Nori vestida, N-1 (16-nov-2026). Lo que se dibuja encima de Nori (las
prendas, más adelante la cara de T-016) se dibuja sobre esta geometría. Si
cambia, el arte de las prendas se revisa otra vez._

## Qué es

Los 12 dibujos de Nori (`assets/mascota/Nori_<fase>_<estado>.png`, 3 fases × 4
ánimos) separados en dos capas, en el mismo lienzo:

| Fichero | Qué |
|---|---|
| `assets/mascota/canonica/Nori_<fase>_<estado>_cuerpo.png` | Nori sin brote. Lleva las «zzz» del dormido |
| `assets/mascota/canonica/Nori_<fase>_<estado>_brote.png` | Solo el brote |
| `assets/mascota/canonica/geometria.json` | La geometría de cada estado (abajo) |

Los genera `tool/nori_canonica/separar_brote.py`. Solo se vuelve a lanzar si
cambian los 12 originales.

**Aún no van en el `pubspec.yaml`:** `assets/mascota/` declara solo los
ficheros de esa carpeta, no los de `canonica/`, así que hoy no entran en las
apps. Se declaran con N-9 (`NoriVestida`), cuando se pinten. Hasta entonces la
app sigue pintando los 12 originales.

## El contrato

- **Lienzo:** 1024 × 1024 px, el mismo que los originales. Origen arriba a la
  izquierda. Todas las capas (cuerpo, brote, prendas) comparten lienzo: se
  montan una encima de otra sin mover nada, y la animación
  (`MascotaAnimadaViva`) las mueve juntas.
- **Orden de las capas,** de abajo arriba (decisión 7 de Nori vestida):
  1. el cuerpo, sin brote;
  2. la cara, cuando llegue T-016;
  3. la prenda de cuerpo;
  4. la prenda de cabeza;
  5. el brote.
- **Cuerpo + brote, en ese orden, dan el original** salvo unos pocos píxeles
  del borde donde el tallo entra en la cabeza: como mucho 23 de 1.048.576 con
  una diferencia de más de 8 (de 255), en el huevo dormido. En el cuerpo, el
  hueco del tallo dentro de la cabeza está relleno, para que la cabeza quede
  entera cuando el brote se sube o se oculta. Queda una muesca pequeña donde
  el tallo sobresalía del perfil de la cabeza: la tapa la prenda de cabeza.
- **El brote se mueve, no se redibuja.** Una prenda de cabeza que no lo
  oculta dice cuántos píxeles del lienzo lo sube en cada fase
  (`subidaBrote`); una que lo oculta, `oculta: ["brote"]` (decisión 8).
- **`geometria.json`** (versión 1), por estado (`huevo_sonriente`…):

  | Campo | Qué |
  |---|---|
  | `cuerpo` | Caja `[x0, y0, x1, y1)` de lo visible del cuerpo (con las «zzz») |
  | `brote` | Caja del brote |
  | `anclajeBrote` | `[x, y]`: donde el tallo toca la cabeza (el pie del brote) |
  | `cabezaArriba` | `[x, y]`: lo más alto de la cabeza en la columna del anclaje |

  Es para quien dibuje prendas (dónde está la cabeza en cada estado) y para
  la hoja de revisión. En el adulto dormido y triste las hojas caen por los
  lados: la caja del brote baja más que el anclaje.

Valores de hoy (x, y del anclaje y de lo alto de la cabeza):

| Estado | Anclaje | Cabeza |
|---|---|---|
| huevo (los cuatro) | (511–514, 274–275) | y 263–264 |
| cría (los cuatro) | (514–521, 234–235) | y 232–233 |
| adulto (los cuatro) | (510–513, 274–275) | y 272 |

La cría dormida es la más desplazada (x 521): está sentada. Una prenda que
valga para toda la fase tiene que caber en ese juego; si no, lleva su imagen
por estado (`<codigo>_<fase>_<estado>.png`, decisión 9).

## Cómo se separa (para revisarlo)

1. El brote es la mayor mancha verde que empieza en el tercio de arriba. Los
   ojos, el corazón del adulto y las «zzz» de la cría y el adulto también son
   verdes, pero están más abajo o son manchas apartadas.
2. Se le suma el borde: 2 px suavizados que no son crema, lo semitransparente
   a menos de 4 px (la sombra suave de las hojas) y los trozos sueltos de
   menos de 3000 px pegados a él (el borde oscuro).
3. El hueco del tallo dentro de la cabeza se rellena desde fuera hacia dentro
   con la media de los vecinos.

Lo vigila `test/nori_canonica_test.dart`: cuerpo + brote dan el original
(como mucho 50 píxeles distintos por estado), el brote no se ha quedado en el
cuerpo y la geometría es coherente.

## La hoja de revisión (N-2)

`tool/nori_canonica/hoja_revision.py` pinta a Nori, con una prenda o sin
ella, en los 12 estados, sobre el fondo de las tres identidades y a tres
tamaños (la pantalla de Nori, la mini Nori y el selector de fases). Es lo que
se revisa del arte, no el móvil. Cómo se describe una prenda (`prenda.json`),
en el propio script. `--crear-prueba` hace un gorro de prueba (no es arte)
para ver el orden de las capas y la subida del brote.

Las dos herramientas son Python 3 con Pillow y NumPy (y SciPy para separar):

```
py -m pip install pillow numpy scipy
py tool/nori_canonica/separar_brote.py
py tool/nori_canonica/hoja_revision.py
py tool/nori_canonica/hoja_revision.py --prenda <carpeta>
```

Las hojas salen en `tool/nori_canonica/salida/`, que no se versiona.
