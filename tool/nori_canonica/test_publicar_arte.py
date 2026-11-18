"""Tests de publicar_arte.py (Nori vestida, N-13), con prendas de mentira.

Uso, desde la raíz del paquete (Python 3 con Pillow y NumPy):
  py -m unittest discover -s tool/nori_canonica -p "test_*.py"
"""
import hashlib
import json
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import publicar_arte as pa  # noqa: E402


def dibujo(semilla, lado=pa.LADO):
    """Una «prenda»: un disco de color con el borde suave, sobre transparente."""
    rng = np.random.default_rng(semilla)
    y, x = np.mgrid[:lado, :lado]
    cx, cy, r = rng.integers(300, 700), rng.integers(300, 700), rng.integers(80, 200)
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
    alfa = np.clip((r - d) / 6 + 0.5, 0, 1)
    img = np.zeros((lado, lado, 4), np.uint8)
    img[..., :3] = rng.integers(40, 220, 3)
    img[..., 3] = (alfa * 255).round().astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def huella(img):
    return hashlib.sha256(np.array(img.convert("RGBA"), np.uint8).tobytes()).hexdigest()


class PublicarArte(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.raiz = self.tmp.name
        self.salida = os.path.join(self.raiz, "salida")

    def tearDown(self):
        self.tmp.cleanup()

    def prenda(self, codigo, imagenes, sitio="cabeza", fases=("huevo", "cria", "adulto"), **extra):
        carpeta = os.path.join(self.raiz, codigo)
        os.makedirs(carpeta, exist_ok=True)
        for i, clave in enumerate(imagenes):
            dibujo(hash((codigo, clave)) % 1000 + i).save(os.path.join(carpeta, f"{codigo}_{clave}.png"))
        with open(os.path.join(carpeta, "prenda.json"), "w", encoding="utf-8") as f:
            json.dump({"codigo": codigo, "sitio": sitio, "fases": list(fases), **extra}, f)
        return carpeta

    def manifiesto(self, salida=None):
        with open(os.path.join(salida or self.salida, "arte", "manifiesto-v1.json"), encoding="utf-8") as f:
            return json.load(f)

    def otra_salida(self, nombre):
        return os.path.join(self.raiz, nombre)

    def test_una_prenda_entra_en_el_manifiesto_por_su_codigo_de_producto(self):
        c = self.prenda("gorro_lana", ["huevo", "cria", "cria_dormido", "adulto"],
                        subidaBrote={"huevo": 76, "cria": 24})
        pa.publicar([c], self.salida)
        m = self.manifiesto()
        self.assertEqual(m["version"], 1)
        p = m["prendas"]["PRENDA_GORRO_LANA"]
        self.assertEqual(p["sitio"], "cabeza")
        self.assertEqual(p["fases"], ["huevo", "cria", "adulto"])
        self.assertEqual(p["oculta"], [])
        self.assertEqual(p["subidaBrote"], {"huevo": 76, "cria": 24})
        self.assertEqual(sorted(p["imagenes"]), ["adulto", "cria", "cria_dormido", "huevo"])
        for ruta in p["imagenes"].values():
            self.assertTrue(ruta.startswith("prendas/") and ruta.endswith(".webp"), ruta)
            self.assertTrue(os.path.isfile(os.path.join(self.salida, "arte", ruta)), ruta)

    def test_la_huella_es_la_de_los_pixeles_no_la_del_fichero(self):
        c = self.prenda("bufanda", ["huevo", "cria", "adulto"], sitio="cuerpo")
        png = os.path.join(c, "bufanda_cria.png")
        esperada = huella(Image.open(png))[:8]
        pa.publicar([c], self.salida)
        primera = self.manifiesto()["prendas"]["PRENDA_BUFANDA"]["imagenes"]["cria"]
        self.assertEqual(primera, f"prendas/bufanda_cria.{esperada}.webp")

        # El mismo dibujo guardado de otra forma: mismo nombre.
        with Image.open(png) as img:
            img.load()
            img.save(png, compress_level=1)
        s2 = self.otra_salida("s2")
        pa.publicar([c], s2)
        self.assertEqual(self.manifiesto(s2)["prendas"]["PRENDA_BUFANDA"]["imagenes"]["cria"], primera)

        # Otro dibujo: otro nombre.
        dibujo(999).save(png)
        s3 = self.otra_salida("s3")
        pa.publicar([c], s3)
        self.assertNotEqual(self.manifiesto(s3)["prendas"]["PRENDA_BUFANDA"]["imagenes"]["cria"], primera)

    def test_el_alfa_sale_identico_y_el_color_cerca(self):
        c = self.prenda("gorro_noel", ["huevo", "cria", "adulto"], oculta=["brote"])
        informe = pa.publicar([c], self.salida)
        self.assertEqual(len(informe), 3)
        for nombre, inf in informe.items():
            webp = os.path.join(self.salida, "arte", "prendas", nombre)
            png = os.path.join(c, nombre.split(".")[0] + ".png")
            a = np.array(Image.open(png).convert("RGBA"))
            b = np.array(Image.open(webp).convert("RGBA"))
            np.testing.assert_array_equal(a[..., 3], b[..., 3])
            self.assertLessEqual(inf["error_color_medio"], 3)
        self.assertEqual(self.manifiesto()["prendas"]["PRENDA_GORRO_NOEL"]["oculta"], ["brote"])

    def test_parte_del_manifiesto_del_servidor_sin_tocar_las_demas(self):
        previo = os.path.join(self.raiz, "previo.json")
        otra = {"sitio": "cuerpo", "fases": ["cria"], "oculta": [], "imagenes": {"cria": "prendas/x.1.webp"}}
        with open(previo, "w", encoding="utf-8") as f:
            json.dump({"version": 1, "nieve": {"desde": "2026-12-01", "hasta": "2027-01-06"},
                       "prendas": {"PRENDA_OTRA": otra}}, f)
        c = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        pa.publicar([c], self.salida, manifiesto=previo)
        m = self.manifiesto()
        self.assertEqual(m["prendas"]["PRENDA_OTRA"], otra)
        self.assertIn("PRENDA_GORRO_LANA", m["prendas"])
        self.assertEqual(m["nieve"], {"desde": "2026-12-01", "hasta": "2027-01-06"})

    def test_la_nieve_se_pone_y_se_quita(self):
        c = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        pa.publicar([c], self.salida, nieve=("2026-11-20", "2027-01-06"))
        self.assertEqual(self.manifiesto()["nieve"], {"desde": "2026-11-20", "hasta": "2027-01-06"})
        previo = os.path.join(self.salida, "arte", "manifiesto-v1.json")
        s2 = self.otra_salida("s2")
        pa.publicar([c], s2, manifiesto=previo, sin_nieve=True)
        self.assertNotIn("nieve", self.manifiesto(s2))
        with self.assertRaises(pa.ErrorArte):
            pa.publicar([c], self.otra_salida("s3"), nieve=("2027-01-06", "2026-11-20"))
        with self.assertRaises(pa.ErrorArte):
            pa.publicar([c], self.otra_salida("s4"), nieve=("1-12-2026", "2027-01-06"))

    def test_lo_que_no_se_puede_publicar_no_escribe_el_manifiesto(self):
        casos = []
        # Falta una fase.
        casos.append(self.prenda("sin_cria", ["huevo", "adulto"]))
        # Una imagen de una fase que no está en «fases».
        casos.append(self.prenda("traje", ["cria", "adulto", "huevo"], fases=("cria", "adulto")))
        # Un nombre que no casa.
        mal = self.prenda("mal_nombre", ["huevo", "cria", "adulto"])
        dibujo(1).save(os.path.join(mal, "mal_nombre_cria_contento.png"))
        casos.append(mal)
        # Otro tamaño.
        chica = self.prenda("chica", ["huevo", "cria", "adulto"])
        dibujo(2, lado=512).save(os.path.join(chica, "chica_cria.png"))
        casos.append(chica)
        # En mayúsculas (Windows): no se salta sin avisar.
        mayus = self.prenda("mayus", ["huevo", "cria", "adulto"])
        dibujo(3).save(os.path.join(mayus, "mayus_cria_dormido.PNG"))
        casos.append(mayus)
        # Un PNG roto.
        roto = self.prenda("roto", ["huevo", "cria", "adulto"])
        with open(os.path.join(roto, "roto_cria.png"), "wb") as f:
            f.write(b"esto no es un png")
        casos.append(roto)
        # Lo que dice prenda.json no vale.
        casos.append(self.prenda("sitio_raro", ["huevo", "cria", "adulto"], sitio="Cabeza"))
        casos.append(self.prenda("oculta_rara", ["huevo", "cria", "adulto"], oculta=["cola"]))
        casos.append(self.prenda("subida_rara", ["huevo", "cria", "adulto"], subidaBrote={"pata": 3}))
        casos.append(self.prenda("subida_decimal", ["huevo", "cria", "adulto"], subidaBrote={"cria": 12.7}))
        # Un prenda.json roto.
        json_roto = self.prenda("json_roto", ["huevo", "cria", "adulto"])
        with open(os.path.join(json_roto, "prenda.json"), "w", encoding="utf-8") as f:
            f.write("{ esto no")
        casos.append(json_roto)
        for i, carpeta in enumerate(casos):
            with self.subTest(carpeta=os.path.basename(carpeta)):
                salida = self.otra_salida(f"fallo{i}")
                with self.assertRaises(pa.ErrorArte):
                    pa.publicar([carpeta], salida)
                self.assertFalse(os.path.exists(os.path.join(salida, "arte")))

    def test_si_falla_a_medias_no_queda_nada(self):
        buena = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        otra = self.prenda("bufanda", ["huevo", "cria", "adulto"], sitio="cuerpo")
        original = pa.a_webp
        llamadas = []

        def falla_a_la_cuarta(ruta, destino):
            llamadas.append(ruta)
            if len(llamadas) == 4:
                raise pa.ErrorArte("a medias")
            return original(ruta, destino)

        pa.a_webp = falla_a_la_cuarta
        try:
            with self.assertRaises(pa.ErrorArte):
                pa.publicar([buena, otra], self.salida)
        finally:
            pa.a_webp = original
        self.assertEqual(len(llamadas), 4)
        self.assertFalse(os.path.exists(os.path.join(self.salida, "arte")))

    def test_la_salida_tiene_que_estar_vacia(self):
        c = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        pa.publicar([c], self.salida)
        viejo = self.manifiesto()
        with self.assertRaises(pa.ErrorArte):
            pa.publicar([c], self.salida)
        self.assertEqual(self.manifiesto(), viejo)

    def test_si_el_alfa_no_sale_identico_no_se_publica(self):
        c = self.prenda("gorro_noel", ["huevo", "cria", "adulto"], oculta=["brote"])
        original = Image.Image.save

        def alfa_con_perdida(img, fp, *args, **kwargs):
            if kwargs.get("alpha_quality") == 100:
                kwargs["alpha_quality"] = 5
                kwargs["quality"] = 5
            return original(img, fp, *args, **kwargs)

        Image.Image.save = alfa_con_perdida
        try:
            with self.assertRaisesRegex(pa.ErrorArte, "alfa"):
                pa.publicar([c], self.salida)
        finally:
            Image.Image.save = original
        self.assertFalse(os.path.exists(os.path.join(self.salida, "arte")))

    def test_un_json_con_bom_se_lee(self):
        c = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        ruta = os.path.join(c, "prenda.json")
        with open(ruta, encoding="utf-8") as f:
            texto = f.read()
        with open(ruta, "w", encoding="utf-8-sig") as f:
            f.write(texto)
        previo = os.path.join(self.raiz, "previo.json")
        with open(previo, "w", encoding="utf-8-sig") as f:
            json.dump({"version": 1, "prendas": {}}, f)
        pa.publicar([c], self.salida, manifiesto=previo)
        self.assertIn("PRENDA_GORRO_LANA", self.manifiesto()["prendas"])

    def test_desde_la_linea_de_comandos(self):
        c = self.prenda("gorro_lana", ["huevo", "cria", "adulto"])
        self.assertEqual(pa.main([c, "--salida", self.salida, "--nieve", "2026-11-20", "2027-01-06"]), 0)
        self.assertIn("PRENDA_GORRO_LANA", self.manifiesto()["prendas"])
        self.assertEqual(
            pa.main([os.path.join(self.raiz, "no_existe"), "--salida", self.otra_salida("otra")]), 1)


if __name__ == "__main__":
    unittest.main()
