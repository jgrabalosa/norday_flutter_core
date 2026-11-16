"""Nori canónica (Nori vestida, N-1): separa el brote de los 12 dibujos de Nori.

De cada `assets/mascota/Nori_<fase>_<estado>.png` salen dos capas, en el mismo
lienzo de 1024 x 1024:

  assets/mascota/canonica/Nori_<fase>_<estado>_cuerpo.png   Nori sin brote
  assets/mascota/canonica/Nori_<fase>_<estado>_brote.png    solo el brote

y `assets/mascota/canonica/geometria.json`, con la geometría de cada una (el
contrato de `docs/funcionamiento/nori-canonica.md`).

Cuerpo + brote, montados en ese orden, dan el original salvo unos pocos
píxeles del borde donde el tallo entra en la cabeza (lo comprueba
`test/nori_canonica_test.dart`).

Cómo se separa:
  1. el brote es la mayor mancha verde que empieza en el tercio de arriba
     (los ojos, el corazón y las «zzz» también son verdes, pero están más
     abajo o son manchas más pequeñas y apartadas);
  2. se le añaden 2 px de borde suavizado que no sean crema, lo
     semitransparente a menos de 4 px (la sombra suave de las hojas) y los
     trozos sueltos de menos de 3000 px pegados a él (el borde oscuro);
  3. en el cuerpo, el hueco que deja el tallo dentro de la cabeza se rellena
     con el color de alrededor, para que la cabeza quede entera cuando el
     brote se sube o se oculta.

Uso, desde la raíz del paquete (Python 3 con Pillow, NumPy y SciPy):
  py -m pip install pillow numpy scipy        (Windows; en Linux, python3 -m pip)
  py tool/nori_canonica/separar_brote.py

Solo hace falta volver a lanzarlo si cambian los 12 originales. Si cambian,
la geometría cambia con ellos: el arte de las prendas se revisa otra vez con
la hoja (`hoja_revision.py`).
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

RAIZ = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
ORIGEN = os.path.join(RAIZ, "assets", "mascota")
DESTINO = os.path.join(ORIGEN, "canonica")
FASES = ["huevo", "cria", "adulto"]
ESTADOS = ["sonriente", "dormido", "triste", "exultante"]
LADO = 1024
VERSION = 1


def separar(fase, estado):
    """Devuelve (original, cuerpo, brote) como arrays RGBA uint8."""
    a = np.array(Image.open(os.path.join(ORIGEN, f"Nori_{fase}_{estado}.png")).convert("RGBA"))
    if a.shape[:2] != (LADO, LADO):
        sys.exit(f"Nori_{fase}_{estado}.png no es de {LADO} x {LADO}")
    rgb = a[..., :3].astype(np.float32) / 255
    al = a[..., 3]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]

    # 1. La mayor mancha verde que empieza en el tercio de arriba.
    verde = (al > 30) & (g >= r) & (g > b) & (sat > 0.25)
    manchas, n = ndimage.label(verde)
    tam = ndimage.sum(verde, manchas, range(1, n + 1))
    candidatas = [k for k in range(1, n + 1)
                  if tam[k - 1] > 2000 and np.where(manchas == k)[0].min() < LADO / 3]
    if not candidatas:
        sys.exit(f"Nori_{fase}_{estado}.png: no encuentro el brote")
    brote = manchas == max(candidatas, key=lambda k: tam[k - 1])

    # 2. El borde suavizado y las motas sueltas del borde.
    borde = ndimage.binary_dilation(brote, iterations=2) & ~brote & (al > 0) & ((sat > 0.12) | (al < 250))
    m = brote | borde
    # La sombra suave alrededor de las hojas: lo semitransparente a menos de
    # 4 px del brote es del brote.
    m |= ndimage.binary_dilation(m, iterations=4) & (al > 0) & (al < 250)
    resto = (al > 0) & ~m
    trozos, nt = ndimage.label(resto, structure=np.ones((3, 3)))
    tam_t = ndimage.sum(resto, trozos, range(1, nt + 1))
    cerca = ndimage.binary_dilation(m, iterations=12)
    for k in range(1, nt + 1):
        if tam_t[k - 1] < 3000 and (cerca & (trozos == k)).any():
            m |= trozos == k

    cuerpo = a.copy()
    cuerpo[m] = 0

    # 3. El hueco del tallo dentro de la cabeza: píxeles del brote con cabeza
    # debajo y a los dos lados. Se rellena desde fuera hacia dentro con la
    # media de los vecinos ya conocidos.
    opaco = cuerpo[..., 3] > 250
    hueco = np.zeros_like(m)
    for y, x in zip(*np.where(m)):
        if opaco[y:y + 8, x].any() and opaco[y, max(0, x - 30):x].any() and opaco[y, x + 1:x + 31].any():
            hueco[y, x] = True
    hueco = ndimage.binary_fill_holes(hueco | opaco) & ~opaco & m
    lleno = cuerpo.astype(np.float32)
    conocido = opaco.copy()
    pendiente = hueco.copy()
    while pendiente.any():
        suma = np.zeros(a.shape[:2] + (3,))
        cuenta = np.zeros(a.shape[:2])
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)]:
            k = np.roll(conocido, (dy, dx), (0, 1))
            suma += np.roll(lleno[..., :3], (dy, dx), (0, 1)) * k[..., None]
            cuenta += k
        nuevos = pendiente & (cuenta > 0)
        if not nuevos.any():
            break
        lleno[nuevos, :3] = suma[nuevos] / cuenta[nuevos][:, None]
        lleno[nuevos, 3] = 255
        conocido |= nuevos
        pendiente &= ~nuevos
    cuerpo = lleno.round().astype(np.uint8)

    capa_brote = np.zeros_like(a)
    capa_brote[m] = a[m]
    return a, cuerpo, capa_brote


def caja(alfa):
    ys, xs = np.where(alfa > 0)
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def geometria(cuerpo, brote):
    """La geometría del contrato: cajas [x0, y0, x1, y1) y el anclaje del brote."""
    ab = brote[..., 3]
    cc = cuerpo[..., 3]
    x0, _, x1, _ = caja(cc)
    centro = (x0 + x1) / 2
    # El anclaje: donde el tallo toca la cabeza. Son los píxeles del brote
    # pegados al cuerpo (a 3 px) en la franja central de 60 px a cada lado:
    # con las hojas caídas (adulto dormido y triste), lo más bajo del brote es
    # la punta de una hoja junto a la cabeza, no el tallo.
    toca = (ab > 128) & ndimage.binary_dilation(cc > 128, iterations=3)
    ys, xs = np.where(toca)
    franja = np.abs(xs - centro) < 60
    if not franja.any():
        sys.exit("el brote no toca la cabeza en la franja central")
    ys, xs = ys[franja], xs[franja]
    anclaje = [int(round(np.median(xs))), int(ys.max()) + 1]
    # Lo más alto de la cabeza justo debajo del anclaje.
    cabeza = int(np.where(cc[:, anclaje[0]] > 128)[0].min())
    return {
        "cuerpo": caja(cuerpo[..., 3]),
        "brote": caja(ab),
        "anclajeBrote": anclaje,
        "cabezaArriba": [anclaje[0], cabeza],
    }


def main():
    os.makedirs(DESTINO, exist_ok=True)
    geo = {"version": VERSION, "lado": LADO, "estados": {}}
    for fase in FASES:
        for estado in ESTADOS:
            _, cuerpo, brote = separar(fase, estado)
            Image.fromarray(cuerpo).save(os.path.join(DESTINO, f"Nori_{fase}_{estado}_cuerpo.png"), optimize=True)
            Image.fromarray(brote).save(os.path.join(DESTINO, f"Nori_{fase}_{estado}_brote.png"), optimize=True)
            geo["estados"][f"{fase}_{estado}"] = geometria(cuerpo, brote)
            print(f"OK {fase}_{estado}")
    with open(os.path.join(DESTINO, "geometria.json"), "w", encoding="utf-8") as f:
        json.dump(geo, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Hecho: {DESTINO}")


if __name__ == "__main__":
    main()
