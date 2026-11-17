"""Saca la prenda de una imagen de IA (Nori vestida, M-8).

Quim pide a la IA que vista a la Nori sin brote de una fase (edita el
`Nori_<fase>_<estado>_cuerpo.png` de `assets/mascota/canonica/` y le pide solo
la prenda). La IA devuelve a Nori entera, con la prenda, sobre un fondo liso,
y a menudo un poco movida, a otro tamaño o con otra luz. Esta herramienta:

  1. alinea la imagen con el cuerpo canónico de esa fase (escala, giro y
     desplazamiento), mirando solo lo que la prenda no puede tapar: la pantalla
     negra y la parte de Nori que no es de su sitio (bajo la cara si es de
     cabeza, la cabeza si es de cuerpo);
  2. separa la prenda: lo que cambia respecto al cuerpo canónico (dentro de
     Nori) o respecto al fondo (fuera). El cuerpo hace de fondo conocido, así
     que el borde sale suave y sin el color de debajo;
  3. limpia: quita las motas, la sombra en el «suelo» y lo que caiga dentro
     de la pantalla negra (regla 6 de `encargos/arte-nori-vestida.md`: el
     borde puede tocar su canto, nada entra), y rellena los agujeros pequeños;
  4. deja el PNG final de 1024 x 1024 en el lienzo de Nori, con un informe
     (alineación, píxeles dudosos, si toca la pantalla, verde, halo) y una
     imagen de control, y apunta la prenda en `prenda.json` para la hoja de
     revisión (`hoja_revision.py`).

Uso, desde la raíz del paquete (Python 3 con Pillow, NumPy y SciPy):
  py tool/nori_canonica/sacar_prenda.py IMAGEN --prenda gorro_lana --fase cria
  py tool/nori_canonica/sacar_prenda.py IMAGEN --prenda bufanda --fase cria --estado dormido
  py tool/nori_canonica/sacar_prenda.py --carpeta CARPETA
Con --carpeta, toma cada imagen que se llame como el PNG final
(`gorro_lana_cria.png`, `bufanda_cria_dormido.jpg`...).

Sale en `tool/nori_canonica/salida/prendas/<prenda>/` (no se versiona), que es
también la carpeta que se le pasa a la hoja:
  py tool/nori_canonica/hoja_revision.py --prenda tool/nori_canonica/salida/prendas/gorro_lana

Si la IA ha redibujado mucho a Nori (otra luz, otra forma), la diferencia no
basta: el informe lo dice (alineación floja o muchos píxeles dudosos) y hay que
pedir otra imagen o retocar a mano.
"""
import argparse
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage, optimize

RAIZ = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
CANONICA = os.path.join(RAIZ, "assets", "mascota", "canonica")
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "salida", "prendas")
FASES = ["huevo", "cria", "adulto"]
ESTADOS = ["sonriente", "dormido", "triste", "exultante"]
LADO = 1024

# Las 4 prendas de invierno y Navidad 2026 (encargos/arte-nori-vestida.md §1).
PRENDAS = {
    "gorro_lana": {"sitio": "cabeza", "fases": FASES, "oculta": []},
    "gorro_noel": {"sitio": "cabeza", "fases": FASES, "oculta": ["brote"]},
    "bufanda": {"sitio": "cuerpo", "fases": FASES, "oculta": []},
    "traje_noel": {"sitio": "cuerpo", "fases": ["cria", "adulto"], "oculta": []},
}

MARGEN_PANTALLA = 0   # px fuera de la pantalla negra que también se quitan (regla 6, 16-nov: 0, el borde puede tocar el canto)
UMBRAL_BAJO = 0.06    # diferencia de color (0-1) por debajo: es Nori o fondo
UMBRAL_ALTO = 0.16    # por encima: es prenda; entre los dos, borde suave
AREA_MINIMA = 800     # px: las manchas más pequeñas son motas
HUECO_MAXIMO = 1500   # px: los agujeros más pequeños dentro de la prenda se rellenan
SOLAPE_BROTE = 8      # px: cuánto se mete el pie del brote dentro de la prenda
ERROR_FLOJO = 0.05    # error medio de la alineación (0-1) a partir del que se avisa
DUDOSOS_MAXIMO = 4000 # px: el primer gorro de lana real (cría) dejó unos 2200


# ---------------------------------------------------------------- utilidades

def cargar_cuerpo(fase, estado):
    ruta = os.path.join(CANONICA, f"Nori_{fase}_{estado}_cuerpo.png")
    if not os.path.exists(ruta):
        sys.exit(f"Falta {ruta}: lanza antes separar_brote.py")
    return np.array(Image.open(ruta).convert("RGBA")).astype(np.float32) / 255


def geometria(fase, estado):
    with open(os.path.join(CANONICA, "geometria.json"), encoding="utf-8") as f:
        return json.load(f)["estados"][f"{fase}_{estado}"]


def cargar_pantalla(fase, estado):
    """La pantalla negra de ese estado, del contrato (`..._pantalla.png`)."""
    ruta = os.path.join(CANONICA, f"Nori_{fase}_{estado}_pantalla.png")
    if not os.path.exists(ruta):
        sys.exit(f"Falta {ruta}: lanza antes separar_brote.py --solo-pantallas")
    return np.array(Image.open(ruta).convert("L")) > 127


def caja(mascara):
    ys, xs = np.where(mascara)
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def rampa(x, bajo, alto):
    return np.clip((x - bajo) / (alto - bajo), 0, 1)


def matriz(k, giro):
    """De (fila, columna) del lienzo a la imagen de IA: escala y giro."""
    c, s = np.cos(giro), np.sin(giro)
    return k * np.array([[c, -s], [s, c]])


# ---------------------------------------------------------------- 1. alinear

def fondo_de(ia):
    """El color del fondo de la imagen de IA (la mediana del borde)."""
    borde = np.concatenate([ia[:8].reshape(-1, 3), ia[-8:].reshape(-1, 3),
                            ia[:, :8].reshape(-1, 3), ia[:, -8:].reshape(-1, 3)])
    color = np.median(borde, axis=0)
    if np.abs(borde - color).max(-1).mean() > 0.06:
        sys.exit("El fondo de la imagen no es liso (¿un damero de «transparencia»?). "
                 "Pide a la IA la imagen sobre un fondo liso, blanco o gris.")
    return color


def zona_limpia(cuerpo, pant, sitio, geo):
    """Lo que la prenda no puede tapar: la pantalla y lo que no es de su sitio."""
    nori = cuerpo[..., 3] > 0.5
    _, py0, _, py1 = caja(pant)
    zona = ndimage.binary_dilation(pant, iterations=4)
    filas = np.arange(LADO)[:, None]
    if sitio == "cabeza":
        zona |= nori & (filas >= py1 - 20)
    else:
        zona |= nori & (filas <= py1) & (filas >= geo["cabezaArriba"][1])
    # Con el borde de la silueta: es lo que mejor fija la escala.
    return ndimage.binary_dilation(zona, iterations=3) & ndimage.binary_dilation(nori, iterations=3) | zona


def alinear(ia, ref, zona, informe):
    """Escala, giro y posición de la imagen de IA respecto al lienzo.

    Busca el mínimo de la diferencia de luminancia en la zona limpia, de lo
    grueso a lo fino: primero una rejilla (paso de 8 px), luego Powell.
    """
    lum_ia = ia @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    lum_ref = ref @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    alto, ancho = lum_ia.shape
    centro = np.array([LADO / 2, LADO / 2])

    def coste_en(paso, lum_s, lum_r):
        ys, xs = np.where(zona[::paso, ::paso])
        puntos = np.stack([ys * paso, xs * paso]).astype(np.float64)
        objetivo = lum_r[ys * paso, xs * paso]

        def coste(p):
            k, giro, by, bx = p
            q = matriz(k, giro) @ (puntos - centro[:, None]) + np.array([[by], [bx]])
            v = ndimage.map_coordinates(lum_s, q, order=1, mode="nearest")
            return float(np.minimum(np.abs(v - objetivo), 0.2).mean())
        return coste

    k0 = max(alto, ancho) / LADO
    inicio = np.array([k0, 0.0, alto / 2, ancho / 2])

    # Rejilla gruesa: la imagen suavizada y un punto de cada 8.
    coste = coste_en(8, ndimage.gaussian_filter(lum_ia, 4 * k0), ndimage.gaussian_filter(lum_ref, 4))
    mejor, mejor_c = inicio, coste(inicio)
    for k in k0 * np.linspace(0.85, 1.15, 13):
        for dy in range(-64, 65, 8):
            for dx in range(-64, 65, 8):
                p = np.array([k, 0.0, alto / 2 + dy * k0, ancho / 2 + dx * k0])
                c = coste(p)
                if c < mejor_c:
                    mejor, mejor_c = p, c

    # Fino: Powell a pasos de 4, 2 y 1.
    escala = np.array([0.01 * k0, 0.01, 1.0, 1.0])
    for paso, sigma in ((4, 2.0), (2, 1.0), (1, 0.5)):
        coste = coste_en(paso, ndimage.gaussian_filter(lum_ia, sigma * k0),
                         ndimage.gaussian_filter(lum_ref, sigma))
        r = optimize.minimize(lambda u: coste(mejor + u * escala), np.zeros(4), method="Powell",
                              options={"xtol": 1e-3, "ftol": 1e-6, "maxfev": 3000})
        mejor = mejor + r.x * escala
        mejor_c = float(r.fun)

    k, giro, by, bx = mejor
    informe["alineacion"] = {
        "escala": round(float(1 / k), 4),
        # Cuánto ha girado la IA a Nori; positivo, en el sentido de las agujas del reloj.
        "giro_grados": round(float(-np.degrees(giro)), 2),
        # Dónde cae el centro del lienzo en la imagen de IA, en px de la IA.
        "centro_en_ia": [round(float(bx), 1), round(float(by), 1)],
        "error_medio": round(mejor_c, 4),
        "floja": mejor_c > ERROR_FLOJO,
    }
    return mejor


def deformar(ia, p):
    """La imagen de IA llevada al lienzo de 1024."""
    k, giro, by, bx = p
    m = matriz(k, giro)
    desplazamiento = np.array([by, bx]) - m @ np.array([LADO / 2, LADO / 2])
    canales = [ndimage.affine_transform(ia[..., c], m, offset=desplazamiento,
                                        output_shape=(LADO, LADO), order=1, mode="nearest")
               for c in range(3)]
    return np.clip(np.stack(canales, -1), 0, 1)


# ---------------------------------------------------------------- 2 y 3. separar y limpiar

def ajuste_de_tono(img, cuerpo, zona):
    """Ganancia y desplazamiento por canal (la IA suele cambiar un poco la luz)."""
    sel = zona & (cuerpo[..., 3] > 0.99)
    g, o = np.ones(3, np.float32), np.zeros(3, np.float32)
    for c in range(3):
        x, y = cuerpo[..., c][sel], img[..., c][sel]
        bien = np.ones_like(x, dtype=bool)
        for _ in range(3):
            if bien.sum() < 100:
                break
            a, b = np.polyfit(x[bien], y[bien], 1)
            bien = np.abs(a * x + b - y) < 0.08
        g[c], o[c] = a, b
    return g, o


def separar(img, cuerpo, fondo, zona, pant, geo, informe):
    ganancia, desplazamiento = ajuste_de_tono(img, cuerpo, zona)
    informe["tono"] = {"ganancia": [round(float(v), 3) for v in ganancia],
                       "desplazamiento": [round(float(v), 3) for v in desplazamiento]}
    a_cuerpo = cuerpo[..., 3:4]
    # El fondo conocido de cada píxel: Nori (con el tono de la IA) o el fondo liso.
    debajo = a_cuerpo * np.clip(cuerpo[..., :3] * ganancia + desplazamiento, 0, 1) + (1 - a_cuerpo) * fondo
    dif = np.abs(img - debajo).max(-1)
    alfa = rampa(dif, UMBRAL_BAJO, UMBRAL_ALTO)

    # El fondo lejos de todo es fondo, aunque tenga un degradado suave.
    fuera = (cuerpo[..., 3] < 0.5) & (dif < 0.10)
    manchas, _ = ndimage.label(fuera)
    del_borde = np.setdiff1d(np.unique(np.concatenate([manchas[0], manchas[-1], manchas[:, 0], manchas[:, -1]])), [0])
    fondo_lejos = np.isin(manchas, del_borde)
    fondo_lejos &= ~ndimage.binary_dilation(~fondo_lejos, iterations=2)
    alfa[fondo_lejos] = 0

    # Manchas: fuera los hilos (el borde de la silueta que la IA ha movido un
    # píxel), las motas y la sombra en el suelo.
    nucleo = ndimage.binary_opening(alfa >= 0.5, structure=np.ones((3, 3)), iterations=2)
    informe_hilos = int(((alfa >= 0.5) & ~nucleo).sum())
    manchas, n = ndimage.label(nucleo, structure=np.ones((3, 3)))
    suelo = geo["cuerpo"][3] - 20
    quedan = np.zeros_like(nucleo)
    motas = sombra = 0
    for k in range(1, n + 1):
        m = manchas == k
        area = int(m.sum())
        ys, _ = np.where(m)
        if area < AREA_MINIMA:
            motas += area
        elif ys.mean() > suelo and (cuerpo[..., 3][m] < 0.5).mean() > 0.8:
            sombra += area
        else:
            quedan |= m
    informe["quitado"] = {"hilos_px": informe_hilos, "motas_px": motas, "sombra_en_el_suelo_px": sombra}

    # Agujeros: los pequeños se rellenan; los grandes se avisan.
    agujeros = ndimage.binary_fill_holes(quedan) & ~quedan
    manchas, n = ndimage.label(agujeros)
    grandes = []
    for k in range(1, n + 1):
        m = manchas == k
        area = int(m.sum())
        if area <= HUECO_MAXIMO:
            quedan |= m
            alfa[m] = 1
        else:
            grandes.append({"caja": caja(m), "px": area})
    informe["agujeros_grandes"] = grandes

    # Solo la prenda y su borde suave; lo demás, dudoso. En la pantalla no
    # cuenta: la IA siempre redibuja el brillo de los ojos y ahí no hay prenda.
    distancia = ndimage.distance_transform_edt(~pant)
    prohibido = pant | (distancia < MARGEN_PANTALLA)
    cerca = ndimage.binary_dilation(quedan, iterations=3)
    informe["dudosos_px"] = int(((alfa > 0.25) & ~cerca & ~prohibido).sum())
    alfa = np.where(quedan, np.maximum(alfa, 0.5), alfa) * cerca

    # La pantalla negra y su margen (regla 6).
    informe["sobre_la_pantalla_px"] = int(((alfa > 0.5) & pant).sum())
    informe["en_el_margen_px"] = int(((alfa > 0.5) & prohibido & ~pant).sum())
    # Se quita exactamente lo que entra (y el margen, si lo hay); el resto, tal cual.
    alfa[pant | prohibido] = 0

    # El color de la prenda, quitando lo que había debajo en el borde suave.
    a3 = alfa[..., None]
    color = np.where(a3 > 0.02, debajo + (img - debajo) / np.maximum(a3, 0.02), 0)
    color = np.clip(color, 0, 1)
    return np.concatenate([color, a3], -1)


# ---------------------------------------------------------------- 4. comprobar y guardar

def comprobar(prenda, pant, fondo, informe):
    a = prenda[..., 3]
    rgb = prenda[..., :3]
    visible = a > 0.5
    informe["prenda_px"] = int(visible.sum())
    if visible.any():
        informe["prenda_caja"] = caja(visible)
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # Verde como el del brote: puede ser de la prenda (el puño del gorro) o un
    # brote que ha dibujado la IA. Se mira en la hoja.
    informe["verde_px"] = int((visible & (g >= r) & (g > b) & (sat > 0.25)).sum())
    # Halo: borde semitransparente del color del fondo de la IA.
    borde = (a > 0.05) & (a < 0.95)
    informe["halo_px"] = int((borde & (np.abs(rgb - fondo).max(-1) < 0.08)).sum())
    distancia = ndimage.distance_transform_edt(~pant)
    informe["distancia_minima_a_la_pantalla"] = round(float(distancia[a > 0.02].min()), 1) if (a > 0.02).any() else None


def subida_brote(prenda, geo):
    """Cuánto subir el brote para que salga de lo alto de la prenda (sugerida)."""
    ax, ay = geo["anclajeBrote"]
    columna = prenda[:, max(0, ax - 6):ax + 7, 3] > 0.5
    filas = np.where(columna.any(1))[0]
    filas = filas[filas < ay + 40]
    if filas.size == 0:
        return 0
    return max(0, int(ay - (filas.min() + SOLAPE_BROTE)))


def control(img, cuerpo, prenda, pant, subida, oculta_brote, fase, estado, ruta):
    """Cuatro paneles: la IA alineada, la prenda sola, y Nori vestida en Profundidad y en Dulce."""
    lado = 512
    letra = ImageFont.load_default()
    out = Image.new("RGB", (lado * 4, lado + 16), (128, 128, 128))
    d = ImageDraw.Draw(out)

    # 1. La IA alineada, con la silueta canónica y la pantalla (y su margen) encima.
    p1 = Image.fromarray((img * 255).astype(np.uint8)).convert("RGBA")
    silueta = cuerpo[..., 3] > 0.5
    contorno = silueta & ~ndimage.binary_erosion(silueta, iterations=2)
    margen = ndimage.distance_transform_edt(~pant) < MARGEN_PANTALLA
    lineas = np.zeros((LADO, LADO, 4), np.uint8)
    lineas[contorno] = (255, 0, 0, 255)
    lineas[margen & ~ndimage.binary_erosion(margen, iterations=2)] = (0, 160, 255, 255)
    p1.alpha_composite(Image.fromarray(lineas))

    # 2. La prenda sobre un damero.
    damero = ((np.indices((LADO, LADO)).sum(0) // 32) % 2)[..., None] * 60 + 160
    fondo = Image.fromarray(np.repeat(damero, 3, -1).astype(np.uint8)).convert("RGBA")
    capa_prenda = Image.fromarray((prenda * 255).round().astype(np.uint8))
    fondo.alpha_composite(capa_prenda)

    # 3 y 4. Montada como en la app: cuerpo, prenda y brote (subido u oculto).
    montada = Image.fromarray((cuerpo * 255).round().astype(np.uint8))
    montada.alpha_composite(capa_prenda)
    ruta_brote = os.path.join(CANONICA, f"Nori_{fase}_{estado}_brote.png")
    if not oculta_brote and os.path.exists(ruta_brote):
        brote = Image.open(ruta_brote).convert("RGBA")
        movido = Image.new("RGBA", (LADO, LADO))
        movido.paste(brote, (0, -subida))
        montada.alpha_composite(movido)
    paneles = [p1, fondo]
    for color in ((0x07, 0x0D, 0x19), (0xFF, 0xFC, 0xF5)):
        p = Image.new("RGBA", (LADO, LADO), color + (255,))
        p.alpha_composite(montada)
        paneles.append(p)
    titulos = ["IA alineada (rojo: Nori; azul: margen de la pantalla)", "prenda sola",
               f"Profundidad (brote +{subida} px)", "Dulce"]
    for i, (p, t) in enumerate(zip(paneles, titulos)):
        out.paste(p.convert("RGB").resize((lado, lado), Image.LANCZOS), (i * lado, 16))
        d.text((i * lado + 4, 2), t, fill=(0, 0, 0), font=letra)
    out.save(ruta, optimize=True)


def apuntar_prenda(carpeta, codigo, fase, subida):
    """Mantiene `prenda.json` (el formato de hoja_revision.py) al día."""
    ruta = os.path.join(carpeta, "prenda.json")
    datos = PRENDAS[codigo]
    if os.path.exists(ruta):
        with open(ruta, encoding="utf-8") as f:
            p = json.load(f)
    else:
        p = {"codigo": codigo, "sitio": datos["sitio"], "fases": datos["fases"],
             "oculta": datos["oculta"], "subidaBrote": {}}
    if datos["sitio"] == "cabeza" and "brote" not in datos["oculta"] and subida is not None:
        p.setdefault("subidaBrote", {})[fase] = subida
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(p, f, ensure_ascii=False, indent=2)
        f.write("\n")


def sacar(ruta_ia, codigo, fase, estado=None, salida=SALIDA):
    """Saca la prenda de una imagen de IA. Devuelve (prenda RGBA 0-1, informe)."""
    if codigo not in PRENDAS:
        sys.exit(f"Prenda desconocida «{codigo}»: {', '.join(PRENDAS)}")
    if fase not in PRENDAS[codigo]["fases"]:
        sys.exit(f"{codigo} no lleva la fase «{fase}»")
    if estado is not None and estado not in ESTADOS:
        sys.exit(f"Estado desconocido «{estado}»")
    estado_cuerpo = estado or "sonriente"
    sitio = PRENDAS[codigo]["sitio"]
    nombre = f"{codigo}_{fase}" + (f"_{estado}" if estado and estado != "sonriente" else "")

    informe = {"imagen": os.path.basename(ruta_ia), "prenda": codigo, "fase": fase,
               "estado": estado_cuerpo, "sitio": sitio}
    imagen = Image.open(ruta_ia)
    tiene_alfa = imagen.mode in ("RGBA", "LA") or "transparency" in imagen.info
    imagen = imagen.convert("RGBA")
    informe["tamano_ia"] = list(imagen.size)
    ia = np.array(imagen).astype(np.float32) / 255
    if tiene_alfa and ia[..., 3].min() < 0.98:
        # Con transparencia: se pone sobre gris neutro y se trata como fondo liso.
        gris = np.float32(0.5)
        ia = ia[..., :3] * ia[..., 3:4] + gris * (1 - ia[..., 3:4])
    else:
        ia = ia[..., :3]
    fondo = fondo_de(ia)
    informe["fondo"] = [round(float(v), 3) for v in fondo]

    cuerpo = cargar_cuerpo(fase, estado_cuerpo)
    geo = geometria(fase, estado_cuerpo)
    pant = cargar_pantalla(fase, estado_cuerpo)
    zona = zona_limpia(cuerpo, pant, sitio, geo)
    ref = cuerpo[..., :3] * cuerpo[..., 3:4] + fondo * (1 - cuerpo[..., 3:4])

    p = alinear(ia, ref, zona, informe)
    img = deformar(ia, p)
    prenda = separar(img, cuerpo, fondo, zona, pant, geo, informe)
    comprobar(prenda, pant, fondo, informe)

    oculta = "brote" in PRENDAS[codigo]["oculta"]
    subida = subida_brote(prenda, geo) if sitio == "cabeza" and not oculta else None
    if subida is not None:
        informe["subida_brote_sugerida"] = subida

    avisos = []
    if informe["alineacion"]["floja"]:
        avisos.append("alineación floja: la IA ha cambiado mucho a Nori")
    if informe["sobre_la_pantalla_px"]:
        avisos.append("la prenda tapaba la pantalla negra: se ha recortado, pero hay que pedir otra imagen")
    elif informe["en_el_margen_px"] > 500:  # solo con MARGEN_PANTALLA > 0
        avisos.append("mucha prenda en el margen de la pantalla: se ha recortado, mirar el control")
    if informe["dudosos_px"] > DUDOSOS_MAXIMO:
        avisos.append("muchos píxeles dudosos: mirar el control")
    if informe["agujeros_grandes"]:
        avisos.append("agujeros grandes dentro de la prenda")
    if informe["halo_px"] > 300:
        avisos.append("halo del color del fondo en el borde")
    if informe["quitado"]["sombra_en_el_suelo_px"]:
        avisos.append("se ha quitado una sombra en el suelo")
    if informe["prenda_px"] == 0:
        avisos.append("no ha salido prenda")
    informe["avisos"] = avisos

    if salida:
        carpeta = os.path.join(salida, codigo)
        os.makedirs(os.path.join(carpeta, "control"), exist_ok=True)
        Image.fromarray((prenda * 255).round().astype(np.uint8), "RGBA").save(
            os.path.join(carpeta, f"{nombre}.png"), optimize=True)
        with open(os.path.join(carpeta, "control", f"{nombre}_informe.json"), "w", encoding="utf-8") as f:
            json.dump(informe, f, ensure_ascii=False, indent=2)
            f.write("\n")
        control(img, cuerpo, prenda, pant, subida or 0, oculta, fase, estado_cuerpo,
                os.path.join(carpeta, "control", f"{nombre}_control.png"))
        if estado in (None, "sonriente"):
            apuntar_prenda(carpeta, codigo, fase, subida)
        informe["salida"] = os.path.join(carpeta, f"{nombre}.png")
    return prenda, informe


def resumen(inf):
    a = inf["alineacion"]
    lineas = [
        f"{inf['prenda']} {inf['fase']} {inf['estado']} ({inf['imagen']}, {inf['tamano_ia'][0]}x{inf['tamano_ia'][1]})",
        f"  alineación: escala {a['escala']}, giro {a['giro_grados']}°, error {a['error_medio']}"
        + (" ← FLOJA" if a["floja"] else ""),
        f"  prenda: {inf['prenda_px']} px; dudosos {inf['dudosos_px']}; verde {inf['verde_px']}; halo {inf['halo_px']}",
        f"  pantalla: tapaba {inf['sobre_la_pantalla_px']} px y {inf['en_el_margen_px']} en el margen; "
        f"queda a {inf['distancia_minima_a_la_pantalla']} px",
    ]
    if "subida_brote_sugerida" in inf:
        lineas.append(f"  subida del brote sugerida: {inf['subida_brote_sugerida']} px")
    for aviso in inf["avisos"]:
        lineas.append(f"  AVISO: {aviso}")
    if "salida" in inf:
        lineas.append(f"  -> {inf['salida']}")
    return "\n".join(lineas)


PATRON = re.compile(r"^(" + "|".join(PRENDAS) + r")_(" + "|".join(FASES) + r")(?:_(" + "|".join(ESTADOS) + r"))?$")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("imagen", nargs="?", help="la imagen de IA")
    ap.add_argument("--prenda", choices=sorted(PRENDAS))
    ap.add_argument("--fase", choices=FASES)
    ap.add_argument("--estado", choices=ESTADOS, help="solo para las de «dormido»")
    ap.add_argument("--carpeta", help="saca todas las imágenes de una carpeta, por su nombre")
    ap.add_argument("--salida", default=SALIDA)
    a = ap.parse_args()
    trabajos = []
    if a.carpeta:
        for f in sorted(os.listdir(a.carpeta)):
            base, ext = os.path.splitext(f)
            m = PATRON.match(base)
            if m and ext.lower() in (".png", ".jpg", ".jpeg", ".webp"):
                trabajos.append((os.path.join(a.carpeta, f), m.group(1), m.group(2), m.group(3)))
        if not trabajos:
            sys.exit("No hay imágenes con nombre de prenda (gorro_lana_cria.png...)")
    elif a.imagen and a.prenda and a.fase:
        trabajos.append((a.imagen, a.prenda, a.fase, a.estado))
    else:
        ap.error("pasa IMAGEN --prenda --fase, o --carpeta")
    for ruta, codigo, fase, estado in trabajos:
        _, inf = sacar(ruta, codigo, fase, estado, a.salida)
        print(resumen(inf))


if __name__ == "__main__":
    main()
