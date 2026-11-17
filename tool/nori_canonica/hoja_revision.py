"""Hoja de revisión del arte de Nori (Nori vestida, N-2).

Pinta a Nori, con una prenda o sin ella, en los 12 estados (3 fases x 4
ánimos), sobre el fondo de las tres identidades y a tres tamaños, en una sola
imagen. Es lo que se revisa del arte, no el móvil: en un móvil no se ven los
halos sobre fondo claro, las rayas a 48 px ni las fases que no tiene el
usuario.

Tamaños, en puntos (a 1x): la pantalla de Nori (280, un móvil de 390 de ancho
x 0,72), la mini Nori (108, 120 x 0,90) y 48 (el selector de fases).
`--densidad 2` los pinta al doble.

Las capas van en el orden de la decisión 7 de Nori vestida, de abajo arriba:
cuerpo sin brote, (la cara, cuando llegue T-016), prenda de cuerpo, prenda de
cabeza y brote. Usa las capas de `assets/mascota/canonica/` (las genera
`separar_brote.py`).

Una prenda es una carpeta con `prenda.json`:

  {
    "codigo": "GORRO_LANA",
    "sitio": "cabeza",                     "cabeza" o "cuerpo"
    "fases": ["huevo", "cria", "adulto"],  en las que se ve
    "oculta": [],                          ["brote"] si lo tapa
    "subidaBrote": {"huevo": 40, "cria": 36, "adulto": 30}
  }

y sus imágenes, de 1024 x 1024 en el mismo lienzo que Nori:
`<codigo>_<fase>_<estado>.png` y, si no hay para ese estado,
`<codigo>_<fase>.png` (decisión 9). Sin imagen para una fase, en esa fase no
se pinta (y la hoja lo marca con «sin arte»). `subidaBrote` está en píxeles del
lienzo de 1024: cuánto sube el brote en cada fase cuando la prenda no lo oculta.

Uso, desde la raíz del paquete (Python 3 con Pillow y NumPy):
  py tool/nori_canonica/hoja_revision.py                        la hoja de Nori sin prenda
  py tool/nori_canonica/hoja_revision.py --prenda CARPETA       la de una prenda
  py tool/nori_canonica/hoja_revision.py --crear-prueba CARPETA crea un gorro de prueba
La hoja sale en `tool/nori_canonica/salida/` (no se versiona).
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
CANONICA = os.path.join(RAIZ, "assets", "mascota", "canonica")
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "salida")
FASES = ["huevo", "cria", "adulto"]
ESTADOS = ["sonriente", "dormido", "triste", "exultante"]
LADO = 1024
# El `bg` de cada identidad (lib/theme/app_theme.dart y identidades_paleta.dart).
IDENTIDADES = [
    ("Profundidad", (0x07, 0x0D, 0x19)),
    ("Neotokyo+", (0x09, 0x06, 0x14)),
    ("Dulce", (0xFF, 0xFC, 0xF5)),
]
TAMANOS = [("pantalla de Nori", 280), ("mini Nori", 108), ("selector", 48)]


def capa(nombre):
    ruta = os.path.join(CANONICA, nombre)
    if not os.path.exists(ruta):
        sys.exit(f"Falta {ruta}: lanza antes separar_brote.py")
    return Image.open(ruta).convert("RGBA")


def cargar_prenda(carpeta):
    with open(os.path.join(carpeta, "prenda.json"), encoding="utf-8") as f:
        p = json.load(f)
    for clave in ("codigo", "sitio", "fases"):
        if clave not in p:
            sys.exit(f"prenda.json: falta «{clave}»")
    if p["sitio"] not in ("cabeza", "cuerpo"):
        sys.exit("prenda.json: «sitio» es «cabeza» o «cuerpo»")
    p.setdefault("oculta", [])
    p.setdefault("subidaBrote", {})
    p["carpeta"] = carpeta
    return p


def imagen_prenda(prenda, fase, estado):
    """La imagen de la prenda para ese estado, o None (decisión 9)."""
    if fase not in prenda["fases"]:
        return None
    for nombre in (f"{prenda['codigo']}_{fase}_{estado}.png", f"{prenda['codigo']}_{fase}.png"):
        ruta = os.path.join(prenda["carpeta"], nombre)
        if os.path.exists(ruta):
            im = Image.open(ruta).convert("RGBA")
            if im.size != (LADO, LADO):
                sys.exit(f"{nombre} no es de {LADO} x {LADO}")
            return im
    return None


def montar(fase, estado, prenda=None):
    """Nori montada en el lienzo de 1024, y si a la prenda le falta arte."""
    lienzo = capa(f"Nori_{fase}_{estado}_cuerpo.png")
    brote = capa(f"Nori_{fase}_{estado}_brote.png")
    sin_arte = False
    if prenda is not None:
        im = imagen_prenda(prenda, fase, estado)
        if im is None:
            sin_arte = fase in prenda["fases"]
        else:
            lienzo = Image.alpha_composite(lienzo, im)
            if "brote" in prenda["oculta"]:
                brote = None
            else:
                subida = int(prenda["subidaBrote"].get(fase, 0))
                if subida:
                    movido = Image.new("RGBA", (LADO, LADO))
                    movido.paste(brote, (0, -subida))
                    brote = movido
    if brote is not None:
        lienzo = Image.alpha_composite(lienzo, brote)
    return lienzo, sin_arte


def hoja(prenda, densidad):
    margen = 8 * densidad
    letra = ImageFont.load_default()
    alto_titulo = 14 * densidad
    celdas = [max(t * densidad, 1) for _, t in TAMANOS]
    ancho = margen + len(FASES) * len(ESTADOS) * (celdas[0] + margen)
    alto_bloque = alto_titulo + sum(c + margen for c in celdas)
    alto = alto_titulo + len(IDENTIDADES) * (alto_bloque + margen)
    out = Image.new("RGBA", (ancho, alto), (128, 128, 128, 255))
    d = ImageDraw.Draw(out)
    titulo = f"Nori sin prenda (canónica)" if prenda is None else f"Prenda {prenda['codigo']} ({prenda['sitio']})"
    d.text((margen, 2), titulo, fill=(0, 0, 0, 255), font=letra)
    montadas = {}
    for fase in FASES:
        for estado in ESTADOS:
            montadas[(fase, estado)] = montar(fase, estado, prenda)
    y = alto_titulo
    for nombre, fondo in IDENTIDADES:
        d.rectangle([0, y, ancho, y + alto_bloque], fill=fondo + (255,))
        claro = sum(fondo) > 380
        tinta = (60, 40, 50, 255) if claro else (220, 220, 230, 255)
        d.text((margen, y + 2), nombre, fill=tinta, font=letra)
        yy = y + alto_titulo
        for (_, tam), lado in zip(TAMANOS, celdas):
            x = margen
            for fase in FASES:
                for estado in ESTADOS:
                    im, sin_arte = montadas[(fase, estado)]
                    out.alpha_composite(im.resize((lado, lado), Image.LANCZOS), (x, yy))
                    if sin_arte and lado == celdas[0]:
                        d.text((x + 4, yy + 4), "sin arte", fill=(255, 60, 60, 255), font=letra)
                    if lado == celdas[0] and nombre == IDENTIDADES[0][0]:
                        d.text((x + 4, yy + lado - 12 * densidad), f"{fase} {estado}", fill=tinta, font=letra)
                    x += celdas[0] + margen
            yy += lado + margen
        y += alto_bloque + margen
    return out


def crear_prueba(carpeta):
    """Un gorro de prueba, rojo con franja blanca, colocado con la geometría.

    No es arte: sirve para probar la hoja y el orden de las capas, y enseña
    cómo una prenda de cabeza sube el brote.
    """
    with open(os.path.join(CANONICA, "geometria.json"), encoding="utf-8") as f:
        geo = json.load(f)["estados"]
    os.makedirs(carpeta, exist_ok=True)
    subida = {}
    for fase in FASES:
        g = geo[f"{fase}_sonriente"]
        x0, _, x1, _ = g["cuerpo"]
        cx, cy = g["cabezaArriba"]
        ancho = (x1 - x0) * 0.62
        alto = ancho * 0.42
        k = 4  # dibujado a 4x y reducido: bordes suaves
        im = Image.new("RGBA", (LADO * k, LADO * k))
        d = ImageDraw.Draw(im)
        caja = [(cx - ancho / 2) * k, (cy - alto * 0.35) * k, (cx + ancho / 2) * k, (cy + alto * 1.3) * k]
        d.pieslice(caja, 180, 360, fill=(200, 40, 50, 255))
        medio = (caja[1] + caja[3]) / 2
        d.rectangle([caja[0], medio - 6 * k, caja[2], medio + 14 * k], fill=(245, 245, 240, 255))
        im = im.resize((LADO, LADO), Image.LANCZOS)
        im.save(os.path.join(carpeta, f"GORRO_PRUEBA_{fase}.png"))
        subida[fase] = int(round(alto * 0.35 + 6))
    with open(os.path.join(carpeta, "prenda.json"), "w", encoding="utf-8") as f:
        json.dump({"codigo": "GORRO_PRUEBA", "sitio": "cabeza", "fases": FASES,
                   "oculta": [], "subidaBrote": subida}, f, indent=2)
        f.write("\n")
    print(f"Gorro de prueba en {carpeta}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--prenda", help="carpeta de la prenda (con prenda.json)")
    ap.add_argument("--crear-prueba", metavar="CARPETA", help="crea un gorro de prueba")
    ap.add_argument("--densidad", type=int, default=1, help="1 (por defecto) o 2")
    a = ap.parse_args()
    if a.crear_prueba:
        crear_prueba(a.crear_prueba)
        return
    prenda = cargar_prenda(a.prenda) if a.prenda else None
    os.makedirs(SALIDA, exist_ok=True)
    nombre = "hoja_nori.png" if prenda is None else f"hoja_{prenda['codigo']}.png"
    ruta = os.path.join(SALIDA, nombre)
    hoja(prenda, a.densidad).convert("RGB").save(ruta, optimize=True)
    print(f"Hoja: {ruta}")


if __name__ == "__main__":
    main()
