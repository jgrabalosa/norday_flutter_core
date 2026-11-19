"""Los 8 letreros del día de Neotokyo+ (D-35), trazados por código.

Cada letrero es una lista de tubos; cada tubo, una polilínea en un cuadro de
0 a 100. El letrero de N hábitos tiene N tubos. Los tubos alternan la tríada
de neón de la identidad: rosa, cian y amarillo.

Salida: letreros-neotokyo.png (los 8 encendidos) y letrero-estados.png (un
letrero de día y en la ceremonia).
"""
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONDO = (9, 6, 20)  # #090614
ROSA, CIAN, AMARILLO = (255, 46, 136), (0, 229, 255), (255, 227, 71)
TRIADA = [ROSA, CIAN, AMARILLO]
CRISTAL = (52, 46, 78)
TEXTO = (236, 232, 255)
TEXTO_SUAVE = (150, 140, 185)
FUENTE = "/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf"


# ---------- geometría ----------
def arco(cx, cy, r, a0, a1, n=48, ry=None):
    ry = r if ry is None else ry
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def bezier(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def une(*tramos):
    out = []
    for t in tramos:
        out.extend(t if not out else t[1:] if math.dist(out[-1], t[0]) < 0.01 else t)
    return out


def onda(x0, x1, y, amp, ondas, n=80):
    return [(x0 + (x1 - x0) * i / n, y + amp * math.sin(2 * math.pi * ondas * i / n)) for i in range(n + 1)]


def media_luna():
    """Media luna: el arco largo de un círculo y, cerrándola, el arco de otro
    círculo que lo muerde, entre sus dos cortes."""
    (x1, y1), r1 = (48, 50), 31
    (x2, y2), r2 = (62, 40), 26
    d = math.dist((x1, y1), (x2, y2))
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(r1 * r1 - a * a)
    xm, ym = x1 + a * (x2 - x1) / d, y1 + a * (y2 - y1) / d
    p = (xm + h * (y2 - y1) / d, ym - h * (x2 - x1) / d)
    q = (xm - h * (y2 - y1) / d, ym + h * (x2 - x1) / d)
    ang = lambda c, pt: math.degrees(math.atan2(pt[1] - c[1], pt[0] - c[0]))
    hacia2 = ang((x1, y1), (x2, y2))
    ap, aq = ang((x1, y1), p), ang((x1, y1), q)
    # Arco exterior: de p a q por el lado contrario al círculo que muerde.
    def dentro(a0, a1, x):
        return (x - a0) % 360 <= (a1 - a0) % 360
    if dentro(ap, ap + (aq - ap) % 360, hacia2):
        ap, aq, p, q = aq, ap, q, p
    exterior = arco(x1, y1, r1, ap, ap + (aq - ap) % 360, 90)
    # Arco interior: del círculo 2, de q a p por el lado que mira al 1.
    bq, bp = ang((x2, y2), q), ang((x2, y2), p)
    hacia1 = ang((x2, y2), (x1, y1))
    if dentro(bq, bq + (bp - bq) % 360, hacia1):
        interior = arco(x2, y2, r2, bq, bq + (bp - bq) % 360, 60)
    else:
        interior = arco(x2, y2, r2, bq, bq - (bq - bp) % 360, 60)
    return [exterior + interior[1:]]


def taza():
    cuerpo = une(
        [(26, 48), (74, 48)],
        bezier((74, 48), (74, 52), (73, 53), (72.5, 55)),
        bezier((72.5, 55), (88, 52), (90, 68), (70, 70)),
        bezier((70, 70), (68, 77), (64, 80), (58, 80)),
        [(58, 80), (42, 80)],
        bezier((42, 80), (32, 80), (26, 66), (26, 48)),
    )
    vapor = bezier((44, 42), (36, 34), (56, 28), (48, 20)) + bezier((48, 20), (44, 15), (52, 12), (54, 9))[1:]
    return [cuerpo, vapor]


def gato():
    cabeza = une([(36, 42), (33, 16), (45, 25), (55, 25), (67, 16), (64, 42)],
                 bezier((64, 42), (60, 50), (40, 50), (36, 42)))
    cuerpo = une(bezier((39, 48), (28, 58), (26, 76), (30, 86)), [(30, 86), (68, 86)],
                 bezier((68, 86), (72, 74), (70, 58), (61, 48)))
    cola = bezier((68, 84), (88, 86), (94, 66), (82, 58))
    return [cabeza, cuerpo, cola]


def ramen():
    cuenco = une([(20, 52), (80, 52)], arco(50, 52, 30, 0, 180, 60, ry=24))
    fideos = onda(28, 72, 46, 3.2, 4)
    palillo1 = [(56, 47), (84, 13)]
    palillo2 = [(63, 48), (92, 22)]
    return [cuenco, fideos, palillo1, palillo2]


def torii():
    kasagi = bezier((10, 15), (32, 26), (68, 26), (90, 15))
    nuki = [(20, 38), (80, 38)]
    pilar_i = [(30, 23), (26, 90)]
    pilar_d = [(70, 23), (74, 90)]
    gakuzuka = [(50, 24), (50, 38)]
    return [kasagi, nuki, pilar_i, pilar_d, gakuzuka]


def ola():
    grande = une(bezier((8, 78), (24, 74), (34, 30), (58, 22)),
                 bezier((58, 22), (76, 16), (82, 36), (68, 40)),
                 bezier((68, 40), (60, 42), (56, 34), (62, 31)))
    pequena = une(bezier((22, 78), (34, 74), (40, 52), (54, 48)),
                  bezier((54, 48), (62, 46), (64, 56), (56, 57)))
    mar1 = onda(6, 94, 82, 1.6, 5)
    mar2 = onda(12, 88, 88, 1.6, 4.5)
    mar3 = onda(20, 80, 94, 1.6, 3.5)
    sol = arco(84, 20, 8, 0, 360, 48)
    return [grande, pequena, mar1, mar2, mar3, sol]


def koi():
    cuerpo = une(bezier((16, 50), (24, 34), (52, 34), (72, 47)),
                 bezier((72, 47), (72, 49), (72, 51), (72, 53)),
                 bezier((72, 53), (52, 66), (24, 66), (16, 50)))
    cola = une(bezier((72, 47), (80, 40), (88, 32), (93, 33)),
               bezier((93, 33), (86, 44), (86, 56), (93, 67)),
               bezier((93, 67), (88, 68), (80, 60), (72, 53)))
    dorsal = bezier((38, 39), (44, 26), (54, 26), (60, 41))
    pectoral = une(bezier((33, 59), (36, 66), (42, 70), (46, 69)), bezier((46, 69), (44, 65), (42, 62), (41, 60)))
    pelvica = une(bezier((53, 58), (56, 63), (61, 66), (65, 65)), bezier((65, 65), (63, 62), (61, 59), (60, 56)))
    ojo = arco(25, 47, 2.4, 0, 360, 24)
    barbilla = bezier((17, 53), (14, 58), (10, 59), (7, 63))
    return [cuerpo, cola, dorsal, pectoral, pelvica, ojo, barbilla]


def nori():
    cuerpo = une(bezier((50, 25), (30, 25), (24, 44), (25, 60)),
                 bezier((25, 60), (26, 78), (36, 88), (50, 88)),
                 bezier((50, 88), (64, 88), (74, 78), (75, 60)),
                 bezier((75, 60), (76, 44), (70, 25), (50, 25)))
    r, x0, y0, x1, y1 = 7, 32, 40, 68, 62
    visor = une([(x0 + r, y0), (x1 - r, y0)], arco(x1 - r, y0 + r, r, 270, 360, 12),
                [(x1, y0 + r), (x1, y1 - r)], arco(x1 - r, y1 - r, r, 0, 90, 12),
                [(x1 - r, y1), (x0 + r, y1)], arco(x0 + r, y1 - r, r, 90, 180, 12),
                [(x0, y1 - r), (x0, y0 + r)], arco(x0 + r, y0 + r, r, 180, 270, 12))
    ojo_i = arco(42, 50, 4.2, 200, 340, 20)
    ojo_d = arco(58, 50, 4.2, 200, 340, 20)
    sonrisa = arco(50, 52, 6, 20, 160, 24)
    tallo = bezier((50, 25), (50, 21), (50, 17), (50, 13))
    hoja_i = une(bezier((50, 13), (46, 4), (36, 4), (32, 10)), bezier((32, 10), (38, 15), (46, 15), (50, 13)))
    hoja_d = une(bezier((50, 13), (54, 4), (64, 4), (68, 10)), bezier((68, 10), (62, 15), (54, 15), (50, 13)))
    return [cuerpo, visor, ojo_i, ojo_d, sonrisa, tallo, hoja_i, hoja_d]


LETREROS = [
    (1, "La luna", media_luna),
    (2, "La taza", taza),
    (3, "El gato", gato),
    (4, "El ramen", ramen),
    (5, "El torii", torii),
    (6, "La ola", ola),
    (7, "El koi", koi),
    (8, "Nori", nori),
]


# ---------- pintado ----------
def capa_linea(tamano, pts, ancho, escala, margen):
    m = Image.new("L", (tamano, tamano), 0)
    d = ImageDraw.Draw(m)
    xy = [(margen + x * escala, margen + y * escala) for x, y in pts]
    d.line(xy, fill=255, width=max(1, int(ancho)), joint="curve")
    r = ancho / 2
    for x, y in (xy[0], xy[-1]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    return m


def letrero(tubos, tamano=420, encendidos=None, cristal=0, brillo=1.0):
    """encendidos: cuántos tubos brillan (los primeros). cristal: cuántos se ven
    como cristal apagado (contando desde el primero; los encendidos van encima)."""
    encendidos = len(tubos) if encendidos is None else encendidos
    sup = 2
    T = tamano * sup
    margen = T * 0.12
    escala = (T - 2 * margen) / 100
    acc = np.zeros((T, T, 3), np.float32)
    for i, pts in enumerate(tubos):
        if i < encendidos:
            col = np.array(TRIADA[i % 3], np.float32) / 255
            ancho = 3.2 * sup * tamano / 420
            base = capa_linea(T, pts, ancho * 2.2, escala, margen)
            for radio, fuerza in ((26, 0.55), (11, 0.75), (4, 0.9)):
                g = np.asarray(base.filter(ImageFilter.GaussianBlur(radio * sup * tamano / 420)), np.float32) / 255
                acc += g[..., None] * col * fuerza * brillo
            nucleo = np.asarray(capa_linea(T, pts, ancho, escala, margen), np.float32) / 255
            blanco = col * 0.45 + 0.55
            acc += nucleo[..., None] * blanco * 1.2 * brillo
        elif i < cristal:
            col = np.array(CRISTAL, np.float32) / 255
            ancho = 3.2 * sup * tamano / 420
            m = np.asarray(capa_linea(T, pts, ancho * 1.3, escala, margen).filter(ImageFilter.GaussianBlur(1)), np.float32) / 255
            acc += m[..., None] * col
            h = np.asarray(capa_linea(T, pts, max(1, ancho * 0.35), escala, margen), np.float32) / 255
            acc += h[..., None] * np.array((0.10, 0.09, 0.15), np.float32)
    fondo = np.array(FONDO, np.float32) / 255
    img = np.clip(fondo + acc, 0, 1)
    out = Image.fromarray((img * 255).astype(np.uint8), "RGB")
    return out.resize((tamano, tamano), Image.LANCZOS)


def hoja_completa(ruta):
    celda, cols, filas = 420, 4, 2
    cab, pie = 120, 70
    W, H = celda * cols, cab + (celda + pie) * filas
    hoja = Image.new("RGB", (W, H), FONDO)
    d = ImageDraw.Draw(hoja)
    f_t = ImageFont.truetype(FUENTE, 40)
    f_s = ImageFont.truetype(FUENTE, 22)
    f_n = ImageFont.truetype(FUENTE, 28)
    d.text((40, 28), "Neotokyo+ · El letrero del día (D-35)", font=f_t, fill=TEXTO)
    d.text((40, 80), "Un tubo por hábito hecho. Con N hábitos, el letrero de N tubos. Propuesta de Claude, para elegir.",
           font=f_s, fill=TEXTO_SUAVE)
    for k, (n, nombre, fn) in enumerate(LETREROS):
        tubos = fn()
        assert len(tubos) == n, (nombre, len(tubos))
        x, y = (k % cols) * celda, cab + (k // cols) * (celda + pie)
        hoja.paste(letrero(tubos, celda), (x, y))
        d.text((x + 34, y + celda + 8), f"{n} · {nombre}", font=f_n, fill=TEXTO)
    hoja.save(ruta, optimize=True)


def hoja_estados(ruta):
    tubos = torii()
    celda, cab, pie = 380, 120, 80
    estados = [
        ("De día: 2 de 5 hechos", dict(encendidos=0, cristal=2)),
        ("De día: 5 de 5", dict(encendidos=0, cristal=5)),
        ("Ceremonia: se encienden", dict(encendidos=3, cristal=5, brillo=0.85)),
        ("Encendido entero", dict(encendidos=5)),
    ]
    W, H = celda * len(estados), cab + celda + pie
    hoja = Image.new("RGB", (W, H), FONDO)
    d = ImageDraw.Draw(hoja)
    f_t = ImageFont.truetype(FUENTE, 38)
    f_s = ImageFont.truetype(FUENTE, 22)
    d.text((36, 26), "El torii (5 hábitos), de día y en la ceremonia", font=f_t, fill=TEXTO)
    d.text((36, 78), "De día, cada hábito hecho deja su tubo como cristal apagado. Al cerrar el día, se encienden uno a uno.",
           font=f_s, fill=TEXTO_SUAVE)
    for k, (titulo, kw) in enumerate(estados):
        hoja.paste(letrero(tubos, celda, **kw), (k * celda, cab))
        d.text((k * celda + 30, cab + celda + 14), titulo, font=f_s, fill=TEXTO)
    hoja.save(ruta, optimize=True)


if __name__ == "__main__":
    destino = sys.argv[1] if len(sys.argv) > 1 else "."
    hoja_completa(f"{destino}/letreros-neotokyo.png")
    hoja_estados(f"{destino}/letrero-estados.png")
    print("hecho")
