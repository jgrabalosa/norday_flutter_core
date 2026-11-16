"""Tests de sacar_prenda.py (M-8), con el gorro de prueba de la hoja.

Simulan lo que hace la IA: Nori con el gorro, sobre un fondo liso, a otro
tamaño, un poco movida y girada, con otra luz y con ruido. De ahí tiene que
salir el gorro de prueba en su sitio del lienzo de 1024.

Uso, desde la raíz del paquete (Python 3 con Pillow, NumPy y SciPy):
  py -m unittest discover -s tool/nori_canonica -p "test_*.py"
"""
import os
import sys
import tempfile
import unittest

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hoja_revision  # noqa: E402
import sacar_prenda as sp  # noqa: E402

FONDO = np.array([0.80, 0.80, 0.79], np.float32)


def imagen_de_ia(fase, gorro, ruta, lado=1254, escala=1.2, giro_grados=0.6, mover=(14, -9),
                 encima=None):
    """Cuerpo + gorro sobre fondo liso, deformado como lo haría la IA."""
    cuerpo = sp.cargar_cuerpo(fase, "sonriente")
    lienzo = cuerpo[..., :3] * cuerpo[..., 3:4] + FONDO * (1 - cuerpo[..., 3:4])
    for capa in [gorro] + ([encima] if encima is not None else []):
        lienzo = capa[..., :3] * capa[..., 3:4] + lienzo * (1 - capa[..., 3:4])
    # Del punto de la IA al del lienzo: la inversa de lo que busca sacar_prenda.
    g = np.radians(giro_grados)
    m = np.array([[np.cos(g), -np.sin(g)], [np.sin(g), np.cos(g)]]) / escala
    centro_ia = np.array([lado / 2 + mover[1], lado / 2 + mover[0]])
    desplazamiento = np.array([sp.LADO / 2, sp.LADO / 2]) - m @ centro_ia
    canales = [ndimage.affine_transform(lienzo[..., c], m, offset=desplazamiento, output_shape=(lado, lado),
                                        order=1, mode="constant", cval=float(FONDO[c])) for c in range(3)]
    ia = np.stack(canales, -1) * 0.96 + 0.015  # otra luz
    ia += np.random.default_rng(7).normal(0, 2 / 255, ia.shape)  # ruido
    Image.fromarray((np.clip(ia, 0, 1) * 255).round().astype(np.uint8), "RGB").save(ruta)


class SacarPrendaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.prueba = os.path.join(cls.tmp.name, "gorro_prueba")
        hoja_revision.crear_prueba(cls.prueba)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def gorro(self, fase):
        im = Image.open(os.path.join(self.prueba, f"GORRO_PRUEBA_{fase}.png")).convert("RGBA")
        return np.array(im).astype(np.float32) / 255

    def test_saca_el_gorro_en_su_sitio(self):
        for fase in sp.FASES:
            with self.subTest(fase=fase):
                gorro = self.gorro(fase)
                ruta = os.path.join(self.tmp.name, f"ia_{fase}.png")
                imagen_de_ia(fase, gorro, ruta)
                prenda, inf = sp.sacar(ruta, "gorro_lana", fase, salida=None)

                self.assertEqual(prenda.shape, (sp.LADO, sp.LADO, 4))
                self.assertFalse(inf["alineacion"]["floja"], inf["alineacion"])
                self.assertAlmostEqual(inf["alineacion"]["escala"], 1 / 1.2, delta=0.004)
                self.assertAlmostEqual(inf["alineacion"]["giro_grados"], 0.6, delta=0.15)

                # El gorro sale donde estaba, salvo lo que cae en el margen de la
                # pantalla y su franja blanca: lo que es casi del color de Nori
                # (crema) no se distingue de Nori por diferencia. Es el límite
                # de la herramienta (los ribetes blancos de Papá Noel).
                pant = sp.cargar_pantalla(fase, "sonriente")
                libre = ndimage.distance_transform_edt(~pant) >= sp.MARGEN_PANTALLA + 2
                blanco = gorro[..., 1] > 0.8
                esperado = (gorro[..., 3] > 0.5) & libre & ~ndimage.binary_dilation(blanco, iterations=3)
                salido = (prenda[..., 3] > 0.5) & ~ndimage.binary_dilation(blanco, iterations=3)
                iou = (esperado & salido).sum() / (esperado | salido).sum()
                self.assertGreater(iou, 0.95, f"{fase}: IoU {iou:.3f}")

                # Y del color del gorro (rojo), no de Nori ni del fondo.
                rojo = esperado & salido & (gorro[..., 0] > 0.6) & (gorro[..., 1] < 0.3)
                dif = np.abs(prenda[..., :3][rojo] - (gorro[..., :3][rojo] * 0.96 + 0.015)).mean()
                self.assertLess(dif, 0.03)

                # El gorro de prueba del adulto sí baja sobre la pantalla: se avisa
                # y en el PNG final no queda nada en ella ni en su margen.
                tapa = int(((gorro[..., 3] > 0.5) & pant).sum())
                self.assertEqual(inf["sobre_la_pantalla_px"] > 0, tapa > 0)
                cerca = pant | (ndimage.distance_transform_edt(~pant) < sp.MARGEN_PANTALLA)
                self.assertEqual(int((prenda[..., 3][cerca] > 0).sum()), 0)
                self.assertGreater(inf["subida_brote_sugerida"], 0)

    def test_nunca_deja_nada_sobre_la_pantalla(self):
        fase = "adulto"
        pant = sp.cargar_pantalla(fase, "sonriente")
        # Una mancha roja grande que baja del gorro hasta media pantalla.
        x0, y0, x1, y1 = sp.caja(pant)
        encima = np.zeros((sp.LADO, sp.LADO, 4), np.float32)
        encima[y0 - 30:(y0 + y1) // 2, x0 + 60:x0 + 140] = (0.8, 0.1, 0.1, 1)
        ruta = os.path.join(self.tmp.name, "ia_encima.png")
        imagen_de_ia(fase, self.gorro(fase), ruta, encima=encima)
        prenda, inf = sp.sacar(ruta, "gorro_lana", fase, salida=None)

        self.assertGreater(inf["sobre_la_pantalla_px"], 1000)
        self.assertTrue(any("pantalla negra" in a for a in inf["avisos"]))
        self.assertEqual(int((prenda[..., 3][pant] > 0).sum()), 0)

    def test_fondo_con_damero_se_rechaza(self):
        damero = ((np.indices((512, 512)).sum(0) // 16) % 2 * 80 + 150).astype(np.uint8)
        ruta = os.path.join(self.tmp.name, "damero.png")
        Image.fromarray(np.repeat(damero[..., None], 3, -1)).save(ruta)
        with self.assertRaises(SystemExit):
            sp.sacar(ruta, "gorro_lana", "cria", salida=None)


if __name__ == "__main__":
    unittest.main()
