"""Publica el arte de las prendas de Nori (Nori vestida, N-13).

A partir de las carpetas revisadas de cada prenda (las de `sacar_prenda.py` o
las de marketing: los PNG `<prenda>_<fase>[_<estado>].png` de 1024 x 1024 y su
`prenda.json`), deja una carpeta `arte/` lista para copiar al servidor:

  arte/manifiesto-v1.json
  arte/prendas/<prenda>_<fase>[_<estado>].<huella>.webp

  1. Cada PNG pasa a **WebP con el alfa sin pérdida** (`alpha_quality=100`;
     el color, a calidad 90): el borde no se ensucia. Se comprueba al
     descodificarlo: el alfa tiene que salir idéntico, o no se publica.
  2. La huella del nombre son los 8 primeros caracteres del SHA-256 **de los
     píxeles** del PNG (RGBA de 1024 x 1024, 8 bits, por filas), no del
     fichero: el mismo dibujo guardado otra vez da el mismo nombre, y un
     dibujo nuevo, otro (la app guarda las imágenes por su nombre, para
     siempre: `docs/funcionamiento/arte-prendas.md`).
  3. Cada prenda entra en el manifiesto por su código de producto
     (`PRENDA_<prenda en mayúsculas>`), sin tocar las demás; si se da
     `--manifiesto`, se parte de ese (el que ya está en el servidor).
  4. La nieve (`--nieve DESDE HASTA`, fechas `AAAA-MM-DD`) se pone o se quita
     (`--sin-nieve`); sin ninguna de las dos, se deja la que había.

Uso, desde la raíz del paquete (Python 3 con Pillow y NumPy):
  py tool/nori_canonica/publicar_arte.py CARPETA [CARPETA...] --salida SALIDA
      [--manifiesto MANIFIESTO] [--nieve 2026-11-20 2027-01-06 | --sin-nieve]

SALIDA tiene que estar vacía o no existir. Si algo no se puede publicar, no
queda nada en ella. Sin `--manifiesto` se parte de cero: el manifiesto que se
suba sustituye al del servidor, así que tiene que llevar todas las prendas.

Después: primero a staging (`scp -r SALIDA/arte/* …`), se mira en la app de
prueba, y luego a producción (`encargos/arte-servidor.md`, §3).
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

LADO = 1024
FASES = ("huevo", "cria", "adulto")
ESTADOS = ("sonriente", "triste", "dormido", "exultante")
CALIDAD_COLOR = 90
VERSION_MANIFIESTO = 1


SITIOS = ("cabeza", "cuerpo")
CAPAS_OCULTABLES = ("brote",)


class ErrorArte(Exception):
    """Algo no se puede publicar: no queda nada escrito en la salida."""


def leer_json(ruta):
    """Un JSON en UTF-8, con o sin BOM (el Bloc de notas y PowerShell 5.1 lo
    ponen). Si no se puede leer, `ErrorArte`."""
    try:
        with open(ruta, encoding="utf-8-sig") as f:
            return json.load(f)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as e:
        raise ErrorArte(f"{ruta}: no se puede leer como JSON en UTF-8 ({e})") from e


def huella_pixeles(imagen):
    """SHA-256 de los píxeles RGBA de 8 bits, por filas (como `huellas.txt`)."""
    pixeles = np.array(imagen.convert("RGBA"), dtype=np.uint8)
    return hashlib.sha256(pixeles.tobytes()).hexdigest()


def clave_imagen(nombre, prenda):
    """`gorro_lana_cria_dormido.png` → `cria_dormido`; si no casa, `None`."""
    m = re.fullmatch(re.escape(prenda) + r"_([a-z]+)(?:_([a-z]+))?\.png", nombre)
    if not m:
        return None
    fase, estado = m.group(1), m.group(2)
    if fase not in FASES or (estado is not None and estado not in ESTADOS):
        return None
    return fase if estado is None else f"{fase}_{estado}"


def leer_prenda(carpeta):
    """La prenda de una carpeta: su `prenda.json` y sus PNG, ya comprobados."""
    ruta_json = os.path.join(carpeta, "prenda.json")
    if not os.path.isfile(ruta_json):
        raise ErrorArte(f"{carpeta}: falta prenda.json")
    datos = leer_json(ruta_json)
    if not isinstance(datos, dict):
        raise ErrorArte(f"{ruta_json}: no es un objeto JSON")
    codigo = datos.get("codigo")
    if not isinstance(codigo, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", codigo):
        raise ErrorArte(f"{carpeta}: el código de prenda.json no es válido: {codigo!r}")
    sitio = datos.get("sitio")
    if sitio not in SITIOS:
        raise ErrorArte(f"{carpeta}: el sitio tiene que ser uno de {SITIOS}: {sitio!r}")
    fases = datos.get("fases") or []
    if not isinstance(fases, list) or not fases or any(f not in FASES for f in fases):
        raise ErrorArte(f"{carpeta}: fases no válidas: {fases!r}")
    oculta = datos.get("oculta") or []
    if not isinstance(oculta, list) or any(c not in CAPAS_OCULTABLES for c in oculta):
        raise ErrorArte(f"{carpeta}: «oculta» solo admite {CAPAS_OCULTABLES}: {oculta!r}")
    subida = datos.get("subidaBrote") or {}
    if not isinstance(subida, dict) or any(
        k not in fases or isinstance(v, bool) or not isinstance(v, int) or v < 0
        for k, v in subida.items()
    ):
        raise ErrorArte(f"{carpeta}: «subidaBrote» va por fase de «fases», en píxeles enteros: {subida!r}")

    imagenes = {}
    for nombre in sorted(os.listdir(carpeta)):
        if not nombre.lower().endswith(".png"):
            continue
        if nombre != nombre.lower():
            # En Windows es fácil que salga «.PNG»: no se salta sin avisar.
            raise ErrorArte(f"{carpeta}: {nombre} tiene que ir en minúsculas")
        clave = clave_imagen(nombre, codigo)
        if clave is None:
            raise ErrorArte(f"{carpeta}: {nombre} no se llama {codigo}_<fase>[_<estado>].png")
        if clave.split("_")[0] not in fases:
            raise ErrorArte(f"{carpeta}: {nombre} es de una fase que no está en «fases»")
        ruta = os.path.join(carpeta, nombre)
        comprobar_png(ruta)
        imagenes[clave] = ruta
    for fase in fases:
        if fase not in imagenes:
            raise ErrorArte(f"{carpeta}: falta {codigo}_{fase}.png")

    entrada = {"sitio": sitio, "fases": list(fases), "oculta": list(oculta)}
    if subida:
        entrada["subidaBrote"] = dict(subida)
    return codigo, entrada, imagenes


def comprobar_png(ruta):
    """Que se abre y mide 1024 x 1024, antes de convertir nada."""
    try:
        with Image.open(ruta) as img:
            img.verify()
        with Image.open(ruta) as img:
            tamano = img.size
    except (OSError, SyntaxError) as e:
        raise ErrorArte(f"{ruta}: no es un PNG que se pueda leer ({e})") from e
    if tamano != (LADO, LADO):
        raise ErrorArte(f"{ruta}: mide {tamano}, no {LADO} x {LADO}")


def a_webp(ruta_png, carpeta_destino):
    """Convierte un PNG (ya comprobado) y devuelve (nombre del WebP, informe).
    Comprueba que el alfa sale idéntico; si no, borra el WebP y lanza.

    Ojo: la huella es la de los píxeles del PNG, no la del WebP. Si un día
    cambia la calidad o la versión de libwebp, el mismo dibujo saldría con el
    mismo nombre y otros bytes, y los móviles se quedarían con los que ya
    tienen (los guardan por su nombre)."""
    with Image.open(ruta_png) as original:
        rgba = original.convert("RGBA")
    huella = huella_pixeles(rgba)
    base = os.path.splitext(os.path.basename(ruta_png))[0]
    nombre = f"{base}.{huella[:8]}.webp"
    destino = os.path.join(carpeta_destino, nombre)
    rgba.save(destino, "WEBP", quality=CALIDAD_COLOR, alpha_quality=100, method=6)

    with Image.open(destino) as vuelta:
        leida = np.array(vuelta.convert("RGBA"), dtype=np.int16)
    antes = np.array(rgba, dtype=np.int16)
    if not np.array_equal(leida[..., 3], antes[..., 3]):
        os.remove(destino)
        raise ErrorArte(f"{ruta_png}: el alfa no sale idéntico en el WebP")
    # El color se mide donde se ve (alfa >= 128): en los bordes casi
    # transparentes la diferencia es grande y no se nota.
    opaco = antes[..., 3] >= 128
    error = np.abs(leida[..., :3] - antes[..., :3])[opaco]
    informe = {
        "kb": round(os.path.getsize(destino) / 1024, 1),
        "huella": huella,
        "error_color_medio": round(float(error.mean()), 1) if error.size else 0.0,
        "error_color_p99": int(np.percentile(error, 99)) if error.size else 0,
    }
    return nombre, informe


def fecha(texto):
    try:
        return datetime.date.fromisoformat(texto).isoformat()
    except ValueError as e:
        raise ErrorArte(f"fecha no válida: {texto!r} (AAAA-MM-DD)") from e


def publicar(carpetas, salida, manifiesto=None, nieve=None, sin_nieve=False):
    """Hace todo y devuelve el informe por imagen. Si algo falla, lanza
    `ErrorArte` y no deja nada en la salida.

    La salida tiene que estar vacía (o no existir): así lo que se copia al
    servidor es justo lo de esta pasada, sin un manifiesto viejo ni WebP de
    otra vez."""
    destino = os.path.join(salida, "arte")
    if os.path.isdir(salida) and os.listdir(salida):
        raise ErrorArte(f"{salida}: tiene que estar vacía")
    if manifiesto:
        datos = leer_json(manifiesto)
        if not isinstance(datos, dict) or not isinstance(datos.get("prendas", {}), dict):
            raise ErrorArte(f"{manifiesto}: no es un manifiesto")
        if datos.get("version") != VERSION_MANIFIESTO:
            raise ErrorArte(f"{manifiesto}: versión {datos.get('version')!r}, se esperaba {VERSION_MANIFIESTO}")
    else:
        datos = {"version": VERSION_MANIFIESTO, "prendas": {}}
    datos.setdefault("prendas", {})

    if sin_nieve:
        datos.pop("nieve", None)
    elif nieve:
        desde, hasta = fecha(nieve[0]), fecha(nieve[1])
        if desde > hasta:
            raise ErrorArte(f"la nieve empieza ({desde}) después de acabar ({hasta})")
        datos["nieve"] = {"desde": desde, "hasta": hasta}

    prendas = [leer_prenda(c) for c in carpetas]
    codigos = [c for c, _, _ in prendas]
    if len(set(codigos)) != len(codigos):
        raise ErrorArte(f"una prenda sale dos veces: {codigos}")

    carpeta_prendas = os.path.join(destino, "prendas")
    os.makedirs(carpeta_prendas, exist_ok=True)
    try:
        informe = {}
        for codigo, entrada, imagenes in prendas:
            entrada["imagenes"] = {}
            for clave, ruta in sorted(imagenes.items()):
                nombre, inf = a_webp(ruta, carpeta_prendas)
                entrada["imagenes"][clave] = f"prendas/{nombre}"
                informe[nombre] = inf
            datos["prendas"][f"PRENDA_{codigo.upper()}"] = entrada

        ruta_manifiesto = os.path.join(destino, "manifiesto-v1.json")
        with open(ruta_manifiesto, "w", encoding="utf-8") as f:
            json.dump(datos, f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")
    except BaseException:
        # A medias no se queda nada: ni WebP sueltos ni manifiesto.
        shutil.rmtree(destino, ignore_errors=True)
        raise
    return informe


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("carpetas", nargs="+", help="carpetas de prenda (con prenda.json)")
    p.add_argument("--salida", required=True, help="donde se deja arte/")
    p.add_argument("--manifiesto", help="el manifiesto del que se parte (el del servidor)")
    nieve = p.add_mutually_exclusive_group()
    nieve.add_argument("--nieve", nargs=2, metavar=("DESDE", "HASTA"))
    nieve.add_argument("--sin-nieve", action="store_true")
    args = p.parse_args(argv)
    if not args.manifiesto:
        print("Ojo: sin --manifiesto se parte de cero. El que se suba sustituye al del "
              "servidor: tiene que llevar todas las prendas.", file=sys.stderr)
    try:
        informe = publicar(args.carpetas, args.salida, args.manifiesto, args.nieve, args.sin_nieve)
    except ErrorArte as e:
        print(f"No se publica nada: {e}", file=sys.stderr)
        return 1
    for nombre, inf in informe.items():
        print(f"{nombre}: {inf['kb']} KB, alfa idéntico, color: media ±{inf['error_color_medio']}, "
              f"p99 ±{inf['error_color_p99']}")
    print(f"Manifiesto: {os.path.join(args.salida, 'arte', 'manifiesto-v1.json')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
