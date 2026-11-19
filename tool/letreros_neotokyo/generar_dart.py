"""Escribe lib/widgets/letreros_datos.dart con los tubos de los 8 letreros.

Los tubos salen de letreros.py (el mismo dibujo que la hoja PNG), en
coordenadas 0..100, y se pasan a 0..1 simplificados con Ramer-Douglas-Peucker
(tolerancia 0.12 sobre 100): a la vista, idénticos; en el fichero, muchos
menos puntos.

Uso, desde la raíz del core:
    python3 tool/letreros_neotokyo/generar_dart.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import letreros  # noqa: E402

TOLERANCIA = 0.12


def _dist_segmento(p, a, b):
    if a == b:
        return math.dist(p, a)
    (x, y), (x1, y1), (x2, y2) = p, a, b
    t = max(0, min(1, ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / ((x2 - x1) ** 2 + (y2 - y1) ** 2)))
    return math.dist(p, (x1 + t * (x2 - x1), y1 + t * (y2 - y1)))


def simplificar(pts):
    if len(pts) < 3:
        return pts
    d, i = max((_dist_segmento(pts[k], pts[0], pts[-1]), k) for k in range(1, len(pts) - 1))
    if d <= TOLERANCIA:
        return [pts[0], pts[-1]]
    return simplificar(pts[: i + 1])[:-1] + simplificar(pts[i:])


def main():
    raiz = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    destino = os.path.join(raiz, "lib", "widgets", "letreros_datos.dart")
    lineas = [
        "// GENERADO por tool/letreros_neotokyo/generar_dart.py. No editar a mano:",
        "// se cambia el dibujo en letreros.py y se vuelve a generar.",
        "",
        "part of 'letreros.dart';",
        "",
        "const Map<int, Letrero> catalogoLetreros = {",
    ]
    total_puntos = 0
    for n, nombre, fn in letreros.LETREROS:
        tubos = fn()
        assert len(tubos) == n, (nombre, len(tubos))
        lineas.append(f"  // {nombre}: {n} tubo{'s' if n > 1 else ''}.")
        lineas.append(f"  {n}: Letrero(")
        lineas.append("    tubos: [")
        for tubo in tubos:
            pts = simplificar([(round(x, 3), round(y, 3)) for x, y in tubo])
            total_puntos += len(pts)
            cuerpo = ", ".join(f"Offset({x / 100:.4f}, {y / 100:.4f})" for x, y in pts)
            lineas.append(f"      [{cuerpo}],")
        lineas.append("    ],")
        lineas.append("  ),")
    lineas.append("};")
    open(destino, "w", encoding="utf-8").write("\n".join(lineas) + "\n")
    print(f"{destino}: {total_puntos} puntos")


if __name__ == "__main__":
    main()
