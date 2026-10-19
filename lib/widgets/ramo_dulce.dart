import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/norday_core_localizations.dart';
import 'lapiz.dart';

// Traducción a Dart de la referencia aprobada por Quim el 19-oct-2026 (el
// Canvas 2D de la especificación). Mismos nombres de función, mismos números,
// mismo orden de dibujo y mismas semillas. Lo que cambia es la forma: los
// puntos son `Offset`, el contexto 2D es un `Canvas` y el estado de trazo se
// pasa en cada llamada.

/// El generador de la referencia (Lehmer), en double como en JavaScript.
@visibleForTesting
double Function() rngRamo(num semilla) {
  var s = (semilla % 2147483646) + 1.0;
  return () {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
}

// Colores propios del ramo (verde, miel, kraft…), decididos por Quim el
// 19-oct-2026; el resto de la app no los usa. PAP es el papel de Dulce.
const Color _pap = Color(0xFFFFFCF5);
const Color _ro = Color(0xFFE53F80);
const Color _ro2 = Color(0xFFB01E5A);
const Color _pr = Color(0xFFFF6FA5);
const Color _co = Color(0xFFE86A58);
const Color _tx = Color(0xFF4A2E3D);
const Color _mu = Color(0xFF7E3A67);
const Color _mau = Color(0xFFA57492);
const Color _nota = Color(0xFFFFF4D6);
const Color _miel = Color(0xFFE3A23B);
const Color _ve = Color(0xFF7F9A6B);
const Color _ve2 = Color(0xFF56703F);
const Color _kr = Color(0xFFC99A62);
const Color _margaritaOscura = Color(0xFFB87A1E);
const Color _margaritaPuntos = Color(0xFF8A5A16);
const Color _cosmosBorde = Color(0xFFC24A3A);
const Color _envoltorio = Color(0xFF9C7445);

double _cl(double v, double a, double b) => max(a, min(b, v));

double _hypot(double a, double b) => sqrt(a * a + b * b);

Paint _trazo(
  Color color,
  double ancho,
  double alfa, {
  StrokeCap cap = StrokeCap.butt,
}) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = cap
  ..strokeWidth = ancho
  ..color = color.withValues(alpha: _cl(alfa, 0, 1));

Path _camino(List<Offset> pts) => Path()..addPolygon(pts, true);

List<Offset> _samp(List<Offset> p, bool closed, [double st = 1.4]) {
  final o = <Offset>[];
  final n = p.length;
  final m = closed ? n : n - 1;
  for (var i = 0; i < m; i++) {
    final a = p[i];
    final b = p[(i + 1) % n];
    final d = _hypot(b.dx - a.dx, b.dy - a.dy);
    final k = max(1, (d / st).ceil());
    for (var j = 0; j < k; j++) {
      o.add(Offset(a.dx + (b.dx - a.dx) * j / k, a.dy + (b.dy - a.dy) * j / k));
    }
  }
  if (!closed) {
    o.add(p[n - 1]);
  } else {
    o.add(o[0]);
  }
  return o;
}

void _lap(
  Canvas x,
  List<Offset> pts,
  Color col,
  double w,
  int seed, {
  bool closed = true,
  double al = .9,
  int passes = 2,
}) {
  final q = _samp(pts, closed);
  final n = q.length;
  if (n < 2) return;
  for (var p = 0; p < passes; p++) {
    final r = rngRamo(seed * 7 + p * 31);
    final f1 = .035 + r() * .04;
    final f2 = .12 + r() * .1;
    final h1 = r() * 6;
    final h2 = r() * 6;
    final amp = p != 0 ? .75 : .4;
    final off = p != 0 ? (r() - .5) * .9 : 0.0;
    var s = 0.0;
    final d = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = q[max(0, i - 1)];
      final b = q[min(n - 1, i + 1)];
      var tx = b.dx - a.dx;
      var ty = b.dy - a.dy;
      final len = _hypot(tx, ty);
      final L = len == 0 ? 1.0 : len;
      tx /= L;
      ty /= L;
      if (i != 0) {
        s += _hypot(q[i].dx - q[i - 1].dx, q[i].dy - q[i - 1].dy);
      }
      final k = amp * (.6 * sin(s * f1 + h1) + .4 * sin(s * f2 + h2)) + off;
      d.add(Offset(q[i].dx - ty * k, q[i].dy + tx * k));
    }
    for (var i = 1; i < n; i++) {
      final t = i / n;
      final pr = closed ? 1.0 : pow(sin(pi * _cl(t, .02, .98)), .4).toDouble();
      final g =
          .62 +
          .38 * (.5 + .5 * sin(i * .83 + h2) * sin(i * .29 + h1)) +
          (r() - .5) * .15;
      x.drawLine(
        d[i - 1],
        d[i],
        _trazo(
          col,
          w * (.5 + .5 * pr) * (p != 0 ? .65 : 1),
          al * (p == 0 ? 1 : .45) * g * (.55 + .45 * pr),
          cap: StrokeCap.round,
        ),
      );
    }
  }
}

void _hat(
  Canvas x,
  List<Offset> poly,
  Color col,
  int seed, {
  double Function(double, double)? intensidad,
  double sep = 2,
  double al = .6,
  double ang = .8,
  double? cruz,
}) {
  final r = rngRamo(seed * 13 + 3);
  final tinta = intensidad ?? (double a, double b) => 1.0;
  final xs = poly.map((p) => p.dx);
  final ys = poly.map((p) => p.dy);
  final minX = xs.reduce((a, b) => min(a, b));
  final maxX = xs.reduce((a, b) => max(a, b));
  final minY = ys.reduce((a, b) => min(a, b));
  final maxY = ys.reduce((a, b) => max(a, b));
  final cx = (minX + maxX) / 2;
  final cy = (minY + maxY) / 2;
  final rad = _hypot(maxX - minX, maxY - minY) / 2 + 3;

  void capa(double a, double s, double alp, double umb) {
    final nx = -sin(a);
    final ny = cos(a);
    final dx = cos(a);
    final dy = sin(a);
    for (var desp = -rad; desp < rad; desp += s * (.7 + r() * .6)) {
      final j = (r() - .5) * .25;
      final ex = r() * .3;
      Offset? prev;
      for (var t = -rad * (1 - ex * .3); t < rad * (1 - r() * .2); t += 1.6) {
        final px = cx + nx * desp + dx * t + nx * t * j * .05;
        final py = cy + ny * desp + dy * t + ny * t * j * .05;
        final v = tinta(px, py);
        if (v > umb && v > r() * .22) {
          if (prev != null) {
            final ancho = .75 + r() * .35;
            final alfaTramo = alp * min(1.0, v * 1.1) * (.65 + r() * .35);
            x.drawLine(prev, Offset(px, py), _trazo(col, ancho, alfaTramo));
          }
          prev = Offset(px, py);
        } else {
          prev = null;
        }
      }
    }
  }

  x.save();
  x.clipPath(_camino(poly));
  capa(ang, sep, al, 0);
  if (cruz != null) capa(ang + 1.22, sep * 1.35, al * .55, cruz);
  x.restore();
}

List<Offset> _rot(double cx, double cy, double a, List<Offset> pts) {
  final c = cos(a);
  final s = sin(a);
  return [
    for (final p in pts)
      Offset(cx + p.dx * c - p.dy * s, cy + p.dx * s + p.dy * c),
  ];
}

List<Offset> _petalo(
  double cx,
  double cy,
  double a,
  double len,
  double wid, {
  double b = 0,
  double notch = 0,
  double? taper,
  double pw = .8,
}) {
  const N = 18;
  final tp = taper ?? .2;
  final L = <Offset>[];
  final R = <Offset>[];
  for (var i = 0; i <= N; i++) {
    final t = i / N;
    final w = wid * pow(sin(pi * min(t, .96)), pw) * (1 - tp * t);
    L.add(Offset(b + len * t, w));
    R.add(Offset(b + len * t, -w));
  }
  final p = [...L];
  p.add(Offset(b + len - (notch != 0 ? notch : -wid * .04), 0));
  return _rot(cx, cy, a, [...p, ...R.reversed]);
}

List<Offset> _circ(double cx, double cy, double r, [int n = 36]) => [
  for (var i = 0; i < n; i++)
    Offset(cx + r * cos(i / n * 6.2832), cy + r * sin(i / n * 6.2832)),
];

List<Offset> _bez(Offset p0, Offset p1, Offset p2, [int n = 30]) {
  final out = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final u = 1 - t;
    out.add(
      Offset(
        u * u * p0.dx + 2.0 * u * t * p1.dx + t * t * p2.dx,
        u * u * p0.dy + 2.0 * u * t * p1.dy + t * t * p2.dy,
      ),
    );
  }
  return out;
}

List<Offset> _bezPts(Offset p0, Offset p1, Offset p2, [int n = 60]) =>
    _bez(p0, p1, p2, n);

void _puntos(
  Canvas x,
  double cx,
  double cy,
  double r,
  int n,
  Color col,
  int seed, [
  double sz = .9,
]) {
  final q = rngRamo(seed);
  for (var i = 0; i < n; i++) {
    final a = q() * 6.28;
    final d = sqrt(q()) * r;
    final radio = sz * (.6 + q() * .6);
    final alfa = .55 + q() * .4;
    x.drawCircle(
      Offset(cx + cos(a) * d, cy + sin(a) * d),
      radio,
      Paint()..color = col.withValues(alpha: alfa),
    );
  }
}

double Function(double, double) _radial(
  double cx,
  double cy,
  double b,
  double len, [
  double k = .9,
  double e = 1.3,
]) => (double X, double Y) {
  final d = _hypot(X - cx, Y - cy);
  return pow(_cl(1.05 - (d - b) / len * k, 0, 1), e).toDouble();
};

void _rellenar(Canvas x, List<Offset> p) {
  x.drawPath(_camino(p), Paint()..color = _pap);
}

void _recortado(Canvas x, List<Offset> poly, void Function() fn) {
  x.save();
  x.clipPath(_camino(poly));
  fn();
  x.restore();
}

({Offset p, double ang}) _enTallo(List<Offset> pts, double t) {
  final i = min(pts.length - 2, max(1, (t * (pts.length - 1)).round()));
  final a = pts[i - 1];
  final b = pts[i + 1];
  final ang = atan2(b.dy - a.dy, b.dx - a.dx);
  return (p: pts[i], ang: ang);
}

void _talloGrueso(Canvas x, List<Offset> pts, double w, int s) {
  final nor = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    final a = pts[max(0, i - 1)];
    final b = pts[min(pts.length - 1, i + 1)];
    final tx = b.dx - a.dx;
    final ty = b.dy - a.dy;
    final len = _hypot(tx, ty);
    final L = len == 0 ? 1.0 : len;
    nor.add(Offset(-ty / L, tx / L));
  }
  final L = [
    for (var i = 0; i < pts.length; i++)
      Offset(pts[i].dx - nor[i].dx * w, pts[i].dy - nor[i].dy * w),
  ];
  final R = [
    for (var i = 0; i < pts.length; i++)
      Offset(pts[i].dx + nor[i].dx * w, pts[i].dy + nor[i].dy * w),
  ];
  final poly = [...L, ...R.reversed];
  _rellenar(x, poly);
  _hat(x, poly, _ve, s, sep: 1.2, al: .7, ang: .3);
  _lap(x, R, _ve2, 1, s + 1, closed: false, al: .85);
  _lap(x, L, _ve2, .7, s + 2, closed: false, al: .6);
}

void _espina(Canvas x, List<Offset> pts, double t, double lado, int s) {
  final e = _enTallo(pts, t);
  final p = e.p;
  final a = e.ang + pi + lado * 1.0;
  final q = [
    Offset(p.dx, p.dy - 2.5),
    Offset(p.dx + cos(a) * 6, p.dy + sin(a) * 6),
    Offset(p.dx, p.dy + 2.5),
  ];
  _rellenar(x, q);
  _hat(x, q, _ve2, s, sep: .9, al: .8);
  _lap(x, q, _ve2, .7, s + 1, al: .9);
}

void _sepalos(
  Canvas x,
  double cx,
  double cy,
  double r,
  int s, [
  double ang = pi / 2,
]) {
  for (var k = 0; k < 5; k++) {
    final a = ang + (k - 2) * .42;
    final p = _petalo(cx, cy, a, r, r * .18, taper: .35, pw: .7);
    _rellenar(x, p);
    _hat(x, p, _ve, s + k, sep: 1.1, al: .8, cruz: .5);
    _lap(x, p, _ve2, .8, s + 10 + k, al: .85);
  }
}

void _hoja2(
  Canvas x,
  double cx,
  double cy,
  double a,
  double len,
  double wid,
  int s,
) {
  final p = _petalo(cx, cy, a, len, wid, taper: .3, pw: .9);
  _rellenar(x, p);
  _hat(
    x,
    p,
    _ve,
    s,
    intensidad: (double X, double Y) {
      final d = _hypot(X - cx, Y - cy);
      return .3 + .7 * _cl(1 - d / len, 0, 1);
    },
    sep: 1.6,
    al: .7,
    cruz: .7,
    ang: a + .9,
  );
  _recortado(x, p, () {
    _lap(
      x,
      _rot(cx, cy, a, [const Offset(2, 0), Offset(len * .9, 0)]),
      _ve2,
      .75,
      s + 2,
      closed: false,
      al: .65,
    );
    for (var k = 1; k < 5; k++) {
      final t = k / 5.2 * len;
      for (final sg in const [1.0, -1.0]) {
        _lap(
          x,
          _rot(cx, cy, a, [
            Offset(t, 0),
            Offset(t + wid * .55, sg * wid * .62),
          ]),
          _ve2,
          .5,
          s + k * 5 + (sg > 0 ? 1 : 2),
          closed: false,
          al: .42,
          passes: 1,
        );
      }
    }
  });
  _lap(x, p, _ve2, .95, s + 1, al: .85);
}

void _hojaDe(
  Canvas x,
  List<Offset> pts,
  double t,
  double lado,
  double len,
  double wid,
  int s, [
  double abre = .75,
]) {
  final e = _enTallo(pts, t);
  // El tallo va de la flor hacia abajo: ang apunta abajo; la hoja sube hacia fuera.
  final a = e.ang + pi + lado * abre;
  final pe = Offset(e.p.dx + cos(a) * 5, e.p.dy + sin(a) * 5);
  _lap(x, [e.p, pe], _ve2, 1, s + 50, closed: false, al: .85);
  _hoja2(x, pe.dx, pe.dy, a, len, wid, s);
}

void _hojaEstrecha(
  Canvas x,
  double cx,
  double cy,
  double a,
  double len,
  double wid,
  int s,
) {
  const N = 20;
  final L = <Offset>[];
  final R = <Offset>[];
  for (var i = 0; i <= N; i++) {
    final t = i / N;
    final diente = (i == 8 || i == 13) ? 1.18 : 1.0;
    final w = wid * pow(sin(pi * min(t, .97)), .7) * diente;
    L.add(Offset(len * t, w));
    R.add(Offset(len * t, -w * (i == 10 || i == 15 ? 1.15 : 1)));
  }
  final p = _rot(cx, cy, a, [...L, Offset(len * 1.02, 0), ...R.reversed]);
  _rellenar(x, p);
  _hat(x, p, _ve, s, sep: 1.3, al: .75, cruz: .7, ang: a + 1);
  _recortado(
    x,
    p,
    () => _lap(
      x,
      _rot(cx, cy, a, [const Offset(1, 0), Offset(len * .92, 0)]),
      _ve2,
      .6,
      s + 2,
      closed: false,
      al: .6,
    ),
  );
  _lap(x, p, _ve2, .85, s + 1, al: .85);
}

void _hojaEstrechaDe(
  Canvas x,
  List<Offset> pts,
  double t,
  double lado,
  double len,
  double wid,
  int s, [
  double abre = .6,
]) {
  final e = _enTallo(pts, t);
  final a = e.ang + pi + lado * abre;
  _hojaEstrecha(x, e.p.dx, e.p.dy, a, len, wid, s);
}

void _hojaPlumosa(Canvas x, double cx, double cy, double a, double len, int s) {
  final raquis = _rot(cx, cy, a, [
    for (var i = 0; i <= 20; i++)
      Offset(len * i / 20, sin(i / 20 * pi) * len * .06),
  ]);
  _lap(x, raquis, _ve2, 1.1, s, closed: false, al: .9);
  for (var k = 1; k <= 7; k++) {
    final q = raquis[(k / 8 * 20).round()];
    final l = len * (.46 - .04 * k);
    for (final sg in const [1.0, -1.0]) {
      final aa = a + sg * (.75 - .04 * k);
      final h = [
        q,
        Offset(
          q.dx + cos(aa) * l * .5 + cos(a) * l * .15,
          q.dy + sin(aa) * l * .5 + sin(a) * l * .15,
        ),
        Offset(
          q.dx + cos(aa) * l + cos(a) * l * .35,
          q.dy + sin(aa) * l + sin(a) * l * .35,
        ),
      ];
      _lap(
        x,
        h,
        _ve2,
        1.05,
        s + k * 7 + (sg > 0 ? 1 : 3),
        closed: false,
        al: .85,
      );
      final m = h[1];
      _lap(
        x,
        [
          m,
          Offset(
            m.dx + cos(aa + sg * .6) * l * .32,
            m.dy + sin(aa + sg * .6) * l * .32,
          ),
        ],
        _ve,
        .7,
        s + k * 7 + (sg > 0 ? 2 : 4),
        closed: false,
        al: .7,
      );
    }
  }
}

void _hojaPlumosaDe(
  Canvas x,
  List<Offset> pts,
  double t,
  double lado,
  double len,
  int s, [
  double abre = .6,
]) {
  final e = _enTallo(pts, t);
  _hojaPlumosa(x, e.p.dx, e.p.dy, e.ang + pi + lado * abre, len, s);
}

void _hojaTulipan(
  Canvas x,
  Offset base,
  double a,
  double len,
  double wid,
  int s,
) {
  const N = 24;
  final L = <Offset>[];
  final R = <Offset>[];
  for (var i = 0; i <= N; i++) {
    final t = i / N;
    final w = wid * pow(sin(pi * min(t, .98)), .6) * (1 - .3 * t);
    final cur = len * .12 * t * t;
    L.add(Offset(len * t, w + cur));
    R.add(Offset(len * t, -w + cur));
  }
  final p = _rot(base.dx, base.dy, a, [
    ...L,
    Offset(len * 1.02, len * .12),
    ...R.reversed,
  ]);
  _rellenar(x, p);
  _hat(
    x,
    p,
    _ve,
    s,
    sep: 1.7,
    al: .6,
    cruz: .8,
    ang: a + 1.1,
    intensidad: (double X, double Y) =>
        .3 + .6 * _cl(1 - _hypot(X - base.dx, Y - base.dy) / len, 0, 1),
  );
  _recortado(x, p, () {
    for (var k = -1; k <= 1; k++) {
      _lap(
        x,
        _rot(base.dx, base.dy, a, [
          for (var i = 0; i <= 10; i++)
            Offset(
              len * i / 10 * .95,
              k.toDouble() * wid * .35 * (1 - i / 12) +
                  len * .12 * (i / 10) * (i / 10),
            ),
        ]),
        _ve2,
        .5,
        s + 3 + k,
        closed: false,
        al: .5,
        passes: 1,
      );
    }
  });
  _lap(x, p, _ve2, .95, s + 1, al: .85);
}

void _rosa2(Canvas x, double cx, double cy, double R, int s) {
  void corona(
    int n,
    double len,
    double anch,
    double giro,
    double b,
    Color col,
    Color colB,
    int semilla,
    double dark,
  ) {
    for (var k = 0; k < n; k++) {
      final a = giro + k * 6.2832 / n;
      final p = _petalo(
        cx,
        cy,
        a,
        len,
        anch,
        b: b,
        taper: -.05,
        pw: .55,
        notch: len * .06,
      );
      _rellenar(x, p);
      _hat(
        x,
        p,
        col,
        semilla + k,
        intensidad: _radial(cx, cy, b, len, .9, 1.1),
        sep: 1.7,
        al: .6,
        ang: a + 1.2,
      );
      _hat(
        x,
        p,
        colB,
        semilla + 20 + k,
        intensidad: (double X, double Y) {
          final d = _hypot(X - cx, Y - cy);
          return pow(_cl(1 - (d - b) / (len * .72), 0, 1), .9).toDouble() *
              dark;
        },
        sep: 1.5,
        al: .85,
        cruz: .45,
        ang: a + .4,
      );
      _lap(x, p, _ro, 1.05, semilla + 40 + k, al: .85);
    }
  }

  corona(5, R, R * .62, .3, R * .1, _pr, _ro, s, .8);
  corona(5, R * .78, R * .5, .3 + .63, R * .08, _pr, _ro, s + 60, .95);
  corona(4, R * .56, R * .42, .1, R * .05, _ro, _ro2, s + 120, 1);
  // centro: tres piezas enrollados en forma de C
  final c = _circ(cx, cy, R * .3, 36);
  _rellenar(x, c);
  _hat(
    x,
    c,
    _ro,
    s + 200,
    sep: 1.3,
    al: .8,
    cruz: .3,
    intensidad: _radial(cx, cy, 0, R * .3, .5, 1),
  );
  const arcos = [(.2, 3.6, .28), (2.3, 5.6, .2), (4.4, 7.4, .12)];
  for (var i = 0; i < arcos.length; i++) {
    final (a0, a1, rr) = arcos[i];
    final arc = <Offset>[];
    for (var t = a0; t <= a1; t += .08) {
      arc.add(Offset(cx + R * rr * cos(t), cy + R * rr * .9 * sin(t)));
    }
    _lap(x, arc, _ro2, 1.1, s + 210 + i, closed: false, al: .9);
  }
  _lap(x, c, _ro2, 1, s + 220, al: .7);
}

void _margarita2(Canvas x, double cx, double cy, double R, int s) {
  void corona(int n, double giro, double len, double anch, int semilla) {
    for (var k = 0; k < n; k++) {
      final a = giro + k * 6.2832 / n;
      final p = _petalo(
        cx,
        cy,
        a,
        len,
        anch,
        b: R * .18,
        taper: .05,
        pw: .7,
        notch: 1.6,
      );
      _rellenar(x, p);
      _hat(
        x,
        p,
        _pr,
        semilla + k,
        intensidad: _radial(cx, cy, R * .2, len, 1.5, 1.4),
        sep: 1.5,
        al: .5,
        ang: a + 1.45,
      );
      _lap(x, p, _mu, .7, semilla + 30 + k, al: .6);
      _lap(
        x,
        _rot(cx, cy, a, [Offset(R * .3, 0), Offset(len * .75, 0)]),
        _mau,
        .45,
        semilla + 60 + k,
        closed: false,
        al: .35,
        passes: 1,
      );
    }
  }

  corona(13, .12, R, R * .13, s);
  corona(13, .12 + .24, R * .92, R * .13, s + 100);
  final c = _circ(cx, cy, R * .27, 30);
  _rellenar(x, c);
  _hat(
    x,
    c,
    _miel,
    s + 200,
    sep: 1.2,
    al: .9,
    cruz: .25,
    intensidad: (double X, double Y) =>
        .45 +
        .55 * _cl(_hypot(X - cx + R * .08, Y - cy + R * .08) / (R * .3), 0, 1),
  );
  _lap(x, c, _margaritaOscura, 1, s + 201, al: .8);
  _puntos(
    x,
    cx + R * .05,
    cy + R * .06,
    R * .19,
    26,
    _margaritaPuntos,
    s + 202,
    .75,
  );
}

void _caliz(Canvas x, double cx, double cy, double r, int s) {
  final p = <Offset>[];
  for (var t = 0.0; t <= pi; t += .1) {
    p.add(Offset(cx + r * cos(t), cy + r * .55 * sin(t)));
  }
  _rellenar(x, p);
  _hat(x, p, _ve, s, sep: 1.1, al: .8, cruz: .4);
  _lap(x, p, _ve2, .8, s + 1, al: .85);
  for (var k = -2; k <= 2; k++) {
    _lap(
      x,
      [Offset(cx + k * r * .35, cy), Offset(cx + k * r * .3, cy + r * .45)],
      _ve2,
      .45,
      s + 5 + k,
      closed: false,
      al: .5,
      passes: 1,
    );
  }
}

List<Offset> _petaloCosmos(
  double cx,
  double cy,
  double a,
  double len,
  double wid,
  double b,
) {
  const N = 16;
  final L = <Offset>[];
  final R = <Offset>[];
  for (var i = 0; i <= N; i++) {
    final t = i / N;
    final w =
        wid *
        (.22 + .78 * sin(min(1, t * 1.15) * pi / 2)) *
        (t > .9 ? 1 - (t - .9) * 2.5 : 1);
    L.add(Offset(b + len * t, w));
    R.add(Offset(b + len * t, -w));
  }
  final tip = [
    Offset(b + len * 1.0, wid * .6),
    Offset(b + len * .95, wid * .34),
    Offset(b + len * 1.03, wid * .14),
    Offset(b + len * .97, -wid * .08),
    Offset(b + len * 1.02, -wid * .32),
    Offset(b + len * .96, -wid * .58),
  ];
  return _rot(cx, cy, a, [
    ...L.sublist(0, N),
    ...tip,
    ...R.sublist(0, N).reversed,
  ]);
}

void _cosmos2(Canvas x, double cx, double cy, double R, int s) {
  for (var k = 0; k < 8; k++) {
    final a = .2 + k * .785 + (k % 2 != 0 ? .04 : -.03);
    final p = _petaloCosmos(cx, cy, a, R * .9, R * .37, R * .14);
    _rellenar(x, p);
    _hat(
      x,
      p,
      _co,
      s + k,
      intensidad: _radial(cx, cy, R * .12, R, .85, 1.3),
      sep: 1.6,
      al: .65,
      ang: a + 1.35,
    );
    _hat(
      x,
      p,
      _ro,
      s + 20 + k,
      intensidad: (double X, double Y) =>
          _cl(1 - (_hypot(X - cx, Y - cy) - R * .12) / (R * .32), 0, 1),
      sep: 1.4,
      al: .75,
      cruz: .4,
      ang: a + .3,
    );
    _recortado(x, p, () {
      for (var j = 0; j < 3; j++) {
        final o = [-.35, 0.0, .35][j];
        _lap(
          x,
          _rot(cx, cy, a, [
            Offset(R * .16, o * R * .05),
            Offset(R * .85, o * R * .22),
          ]),
          _cosmosBorde,
          .45,
          s + 40 + k * 3 + j,
          closed: false,
          al: .4,
          passes: 1,
        );
      }
    });
    _lap(x, p, _cosmosBorde, .95, s + 70 + k, al: .85);
  }
  final c = _circ(cx, cy, R * .24, 28);
  _rellenar(x, c);
  _hat(x, c, _mu, s + 90, sep: 1.1, al: .9, cruz: .2);
  _lap(x, c, _tx, .9, s + 91, al: .85);
  final q = rngRamo(s + 92);
  for (var i = 0; i < 22; i++) {
    final a = i / 22 * 6.2832 + q() * .2;
    final rad = R * (.2 + q() * .06);
    x.drawCircle(
      Offset(cx + cos(a) * rad, cy + sin(a) * rad),
      .9 + q() * .5,
      Paint()..color = _miel.withValues(alpha: .9),
    );
  }
  _puntos(x, cx, cy, R * .1, 8, _miel, s + 93, .8);
}

void _tulipan2(Canvas x, double cx, double cy, double R, int s) {
  List<Offset> pet(double a0, double len, double anch, double dx) =>
      _petalo(cx + dx, cy + R * .75, a0, len, anch, taper: .3, pw: .55);
  final atras = pet(-1.5708, R * 1.55, R * .55, 0);
  final izq = pet(-1.95, R * 1.35, R * .5, -R * .08);
  final der = pet(-1.19, R * 1.35, R * .5, R * .08);
  double intensidad(double X, double Y) =>
      pow(_cl((Y - (cy - R * .9)) / (R * 1.7), 0, 1), 1.1).toDouble() + .06;
  final piezas = [atras, izq, der];
  const angulos = [-1.5708, -1.95, -1.19];
  for (var i = 0; i < piezas.length; i++) {
    final p = piezas[i];
    _rellenar(x, p);
    _hat(
      x,
      p,
      _pr,
      s + i,
      intensidad: intensidad,
      sep: 1.6,
      al: .7,
      ang: 1.45 - i * .2,
    );
    _hat(
      x,
      p,
      _ro,
      s + 10 + i,
      intensidad: (double X, double Y) =>
          _cl((Y - (cy + R * .1)) / (R * .7), 0, 1),
      sep: 1.4,
      al: .75,
      cruz: .5,
      ang: .5,
    );
    _recortado(
      x,
      p,
      () => _lap(
        x,
        _rot(cx, cy + R * .75, angulos[i], [
          Offset(R * .2, 0),
          Offset(R * 1.2, 0),
        ]),
        _ro,
        .5,
        s + 20 + i,
        closed: false,
        al: .45,
        passes: 1,
      ),
    );
    _lap(x, p, _ro2, 1, s + 30 + i, al: .85);
  }
}

void _campana2(
  Canvas x,
  double cx,
  double cy,
  double a,
  double largo,
  double ancho,
  int s,
) {
  const N = 16;
  final izq = <Offset>[];
  final der = <Offset>[];
  for (var i = 0; i <= N; i++) {
    final t = i / N;
    final w =
        ancho * (.28 + .72 * pow(t, 1.6).toDouble()) +
        (t > .85 ? ancho * .25 * (t - .85) / .15 : 0);
    izq.add(Offset(largo * t, w));
    der.add(Offset(largo * t, -w));
  }
  final wb = ancho * 1.25;
  final boca = <Offset>[];
  for (var k = 0; k <= 10; k++) {
    final u = 1.0 - 2 * k / 10;
    boca.add(Offset(largo + (k % 2 != 0 ? -largo * .1 : largo * .04), u * wb));
  }
  final pol = _rot(cx, cy, a, [...izq, ...boca, ...der.reversed]);
  _rellenar(x, pol);
  _hat(
    x,
    pol,
    _pr,
    s,
    sep: 1.15,
    al: .75,
    ang: a + 1.5,
    intensidad: (double X, double Y) =>
        .4 + .6 * _cl(_hypot(X - cx, Y - cy) / largo, 0, 1),
  );
  _hat(
    x,
    pol,
    _ro,
    s + 1,
    sep: 1.4,
    al: .45,
    cruz: .7,
    ang: a + .5,
    intensidad: (double X, double Y) {
      final u = _rot(0, 0, -a, [Offset(X - cx, Y - cy)]).first;
      return _cl(u.dy.abs() / ancho - .35, 0, 1);
    },
  );
  _recortado(x, pol, () {
    for (var j = 0; j < 3; j++) {
      final o = [-.5, 0.0, .5][j];
      _lap(
        x,
        _rot(cx, cy, a, [
          Offset(largo * .12, o * ancho * .3),
          Offset(largo * .97, o * wb * .85),
        ]),
        _ro,
        .45,
        s + 5 + j,
        closed: false,
        al: .4,
        passes: 1,
      );
    }
  });
  _lap(x, pol, _ro2, .85, s + 2, al: .88);
  // el interior de la boca, más oscuro
  final bo = _rot(cx, cy, a, [
    Offset(largo * .98, -wb * .85),
    Offset(largo * 1.02, 0),
    Offset(largo * .98, wb * .85),
  ]);
  _lap(x, bo, _ro2, .6, s + 3, closed: false, al: .6);
}

void _campanillas3(Canvas x, Offset p0, Offset p1, Offset p2, int s) {
  final st = _bezPts(p0, p1, p2, 70);
  _talloGrueso(x, st, .9, s);
  const campanas = [
    (.56, 14.0, 5.6),
    (.66, 13.5, 5.4),
    (.75, 12.5, 5.0),
    (.83, 11.5, 4.6),
    (.9, 10.0, 4.0),
    (.97, 8.5, 3.4),
  ];
  for (var i = 0; i < campanas.length; i++) {
    final (t, largo, ancho) = campanas[i];
    final p = _enTallo(st, t).p;
    final ped = Offset(p.dx + 1.5, p.dy + 6);
    _lap(
      x,
      [p, Offset(p.dx + 2, p.dy + 3), ped],
      _ve2,
      .75,
      s + 10 + i,
      closed: false,
      al: .85,
    );
    _campana2(
      x,
      ped.dx,
      ped.dy,
      1.5708 - .18 + i * .04,
      largo,
      ancho,
      s + 20 + i * 6,
    );
  }
  for (var i = 0; i < 2; i++) {
    _hojaEstrechaDe(
      x,
      st,
      const [.3, .38][i],
      i != 0 ? 1 : -1,
      16,
      2.6,
      s + 70 + i,
      .7,
    );
  }
}

void _florecita(Canvas x, double cx, double cy, double r, int s) {
  final q = rngRamo(s);
  for (var k = 0; k < 5; k++) {
    final a = 1.2566 * k + q();
    final p = _petalo(cx, cy, a, r, r * .5, taper: 0, pw: .6);
    _rellenar(x, p);
    _lap(x, p, _mau, .45, s + k, al: .7, passes: 1);
  }
  x.drawCircle(
    Offset(cx, cy),
    r * .28,
    Paint()..color = _miel.withValues(alpha: .8),
  );
}

void _paniculata2(Canvas x, Offset base, List<Offset> puntas, int s) {
  for (var i = 0; i < puntas.length; i++) {
    final p = puntas[i];
    final m = Offset(
      (base.dx + p.dx) / 2 + (i % 2 != 0 ? 7 : -7),
      (base.dy + p.dy) / 2,
    );
    final rama = _bezPts(base, m, p, 30);
    _lap(x, rama, _ve2, .7, s + i, closed: false, al: .75);
    final q = rngRamo(s + i * 13);
    for (var j = 0; j < 4; j++) {
      final t = .55 + j * .12;
      final o = _enTallo(rama, t).p;
      final fin = Offset(o.dx + (q() - .5) * 20, o.dy - 6 - q() * 10);
      _lap(
        x,
        [o, fin],
        _ve2,
        .5,
        s + i * 20 + j,
        closed: false,
        al: .6,
        passes: 1,
      );
      for (var k = 0; k < 3; k++) {
        final f = Offset(fin.dx + (q() - .5) * 9, fin.dy + (q() - .5) * 7);
        _lap(
          x,
          [fin, f],
          _ve,
          .35,
          s + i * 40 + j * 5 + k,
          closed: false,
          al: .5,
          passes: 1,
        );
        _florecita(x, f.dx, f.dy, 2.3 + q() * .7, s + i * 60 + j * 7 + k);
      }
    }
    _florecita(x, p.dx, p.dy, 2.8, s + i * 70);
  }
}

void _lavanda3(Canvas x, Offset p0, Offset p1, Offset p2, int s) {
  final st = _bezPts(p0, p1, p2, 80);
  _talloGrueso(x, st, .8, s);
  const ojos = [(-1.0, .9), (-.45, .35), (.45, -.35), (1.0, -.9)];
  for (var i = 0; i < 16; i++) {
    final t = .6 + .025 * i;
    final e = _enTallo(st, min(.995, t));
    final p = e.p;
    final tam = 1.0 - .035 * i;
    final up = e.ang + pi;
    for (var k = 0; k < ojos.length; k++) {
      final (sg, off) = ojos[k];
      final a = up + sg * .62;
      final ep = _petalo(
        p.dx + off * 1.2,
        p.dy,
        a,
        8.5 * tam,
        3 * tam,
        taper: .1,
        pw: .6,
      );
      _rellenar(x, ep);
      _hat(
        x,
        ep,
        _mau,
        s + i * 11 + k,
        sep: .95,
        al: .9,
        cruz: .35,
        intensidad: (double X, double Y) =>
            .45 + .55 * _cl(1 - _hypot(X - p.dx, Y - p.dy) / 9, 0, 1),
      );
      _lap(x, ep, _mu, .6, s + i * 11 + k + 5, al: .8);
    }
  }
  for (var i = 0; i < 2; i++) {
    _hojaEstrechaDe(
      x,
      st,
      const [.36, .44][i],
      i != 0 ? 1 : -1,
      22,
      2.2,
      s + 200 + i,
      .4,
    );
  }
}

void _capullo2(Canvas x, Offset p0, Offset p1, Offset tip, int s) {
  final st = _bezPts(p0, p1, tip, 50);
  _talloGrueso(x, st, 1.2, s);
  _espina(x, st, .55, 1, s + 3);
  final b = Offset(tip.dx, tip.dy - 1);
  final gota = _petalo(b.dx, b.dy, -1.5708, 26, 9, taper: .4, pw: .55);
  _rellenar(x, gota);
  _hat(
    x,
    gota,
    _ro,
    s + 5,
    sep: 1.4,
    al: .8,
    cruz: .55,
    intensidad: (double X, double Y) =>
        .3 + .7 * _cl((Y - (b.dy - 26)) / 26, 0, 1),
  );
  _lap(x, gota, _ro2, 1.05, s + 6, al: .9);
  final pliegue = [
    Offset(b.dx - 3, b.dy - 22),
    Offset(b.dx + 1, b.dy - 12),
    Offset(b.dx + 5, b.dy - 4),
  ];
  _lap(x, pliegue, _ro2, .85, s + 7, closed: false, al: .75);
  final pliegue2 = [Offset(b.dx + 2, b.dy - 24), Offset(b.dx - 2, b.dy - 14)];
  _lap(x, pliegue2, _ro2, .6, s + 8, closed: false, al: .55);
  const sepales = [(-2.35, 15.0), (-.8, 15.0), (-1.75, 10.0)];
  for (var i = 0; i < sepales.length; i++) {
    final (ang, largo) = sepales[i];
    final sp = _petalo(b.dx, b.dy + 2, ang, largo, 3.4, taper: .35, pw: .7);
    _rellenar(x, sp);
    _hat(x, sp, _ve, s + 10 + i, sep: 1.1, al: .85, cruz: .4);
    _lap(x, sp, _ve2, .85, s + 13 + i, al: .9);
  }
}

void _cinta(Canvas x, double cx, double cy, double w, int s) {
  // vueltas de cinta apretando los tallos en el nudo
  const vueltas = [(0.0, -.14), (6.0, .12), (12.0, -.1)];
  for (var i = 0; i < vueltas.length; i++) {
    final (dy, inc) = vueltas[i];
    const h = 5.0;
    final p = [
      Offset(cx - w, cy + dy - w * inc),
      Offset(cx + w, cy + dy + w * inc),
      Offset(cx + w, cy + dy + w * inc + h),
      Offset(cx - w, cy + dy - w * inc + h),
    ];
    _rellenar(x, p);
    _hat(x, p, _ro, s + i, sep: 1.2, al: .8, cruz: .3, ang: 1.4);
    _lap(x, p, _ro2, .9, s + i + 10, al: .85);
  }
}

void _lazoAtado(Canvas x, double cx, double cy, double k, double w, int s) {
  // colas: detrás de la cinta, salen hacia los lados
  final tails = [
    [
      Offset(cx - 4, cy + 6),
      Offset(cx - 14 * k, cy + 26 * k),
      Offset(cx - 26 * k, cy + 46 * k),
      Offset(cx - 17 * k, cy + 43 * k),
      Offset(cx - 14 * k, cy + 50 * k),
      Offset(cx - 6 * k, cy + 28 * k),
      Offset(cx, cy + 8),
    ],
    [
      Offset(cx + 4, cy + 6),
      Offset(cx + 12 * k, cy + 28 * k),
      Offset(cx + 22 * k, cy + 50 * k),
      Offset(cx + 14 * k, cy + 45 * k),
      Offset(cx + 10 * k, cy + 52 * k),
      Offset(cx + 4 * k, cy + 28 * k),
      Offset(cx, cy + 8),
    ],
  ];
  for (var i = 0; i < tails.length; i++) {
    final t = tails[i];
    _rellenar(x, t);
    _hat(
      x,
      t,
      _ro,
      s + i,
      sep: 1.5,
      al: .75,
      cruz: .5,
      intensidad: (double X, double Y) =>
          .45 + .55 * _cl(1 - (Y - cy) / (50 * k), 0, 1),
    );
    _lap(x, t, _ro2, 1, s + i + 5, al: .85);
  }
  _cinta(x, cx, cy + 6, w, s + 30);
  // lazos y nudo, rellenos de papel
  final lazos = [
    _petalo(cx, cy, 3.45, 30 * k, 12 * k, taper: -.2, pw: .6),
    _petalo(cx, cy, -.31, 30 * k, 12 * k, taper: -.2, pw: .6),
  ];
  for (var i = 0; i < lazos.length; i++) {
    final l = lazos[i];
    _rellenar(x, l);
    _hat(
      x,
      l,
      _ro,
      s + 10 + i,
      sep: 1.5,
      al: .75,
      cruz: .6,
      intensidad: _radial(cx, cy, 0, 30 * k, .8, 1),
    );
    _lap(x, l, _ro2, 1.1, s + 12 + i, al: .85);
    final f = _petalo(cx, cy, i != 0 ? -.31 : 3.45, 16 * k, 5 * k, taper: 0);
    _hat(x, f, _ro2, s + 14 + i, sep: 1.3, al: .55);
  }
  final n = _circ(cx, cy, 5.5 * k, 20);
  _rellenar(x, n);
  _hat(x, n, _ro2, s + 20, sep: 1.2, al: .85, cruz: .1);
  _lap(x, n, _ro2, 1, s + 21);
}

void _cintaCono(
  Canvas x,
  double cx,
  double cy,
  double w,
  int s, [
  List<double> dys = const [-6, 1, 8],
]) {
  for (var i = 0; i < dys.length; i++) {
    final dy = dys[i];
    const h = 5.2;
    const sag = 4.5;
    const N = 24;
    final arriba = <Offset>[];
    final abajo = <Offset>[];
    for (var k = 0; k <= N; k++) {
      final u = -1.0 + 2 * k / N;
      final X = cx + u * (w - dy * .12);
      final c = sag * (1 - u * u);
      arriba.add(Offset(X, cy + dy + c));
      abajo.add(Offset(X, cy + dy + c + h));
    }
    final p = [...arriba, ...abajo.reversed];
    _rellenar(x, p);
    _hat(
      x,
      p,
      _ro,
      s + i,
      sep: 1.2,
      al: .8,
      cruz: .3,
      ang: 1.45,
      intensidad: (double X, double Y) =>
          .55 + .45 * _cl((X - cx).abs() / w, 0, 1),
    );
    _lap(x, p, _ro2, .9, s + i + 10, al: .85);
  }
}

void _lazoCono(Canvas x, double cx, double cy, double k, double w, int s) {
  final tails = [
    [
      Offset(cx - 4, cy + 6),
      Offset(cx - 14 * k, cy + 26 * k),
      Offset(cx - 26 * k, cy + 46 * k),
      Offset(cx - 17 * k, cy + 43 * k),
      Offset(cx - 14 * k, cy + 50 * k),
      Offset(cx - 6 * k, cy + 28 * k),
      Offset(cx, cy + 8),
    ],
    [
      Offset(cx + 4, cy + 6),
      Offset(cx + 12 * k, cy + 28 * k),
      Offset(cx + 22 * k, cy + 50 * k),
      Offset(cx + 14 * k, cy + 45 * k),
      Offset(cx + 10 * k, cy + 52 * k),
      Offset(cx + 4 * k, cy + 28 * k),
      Offset(cx, cy + 8),
    ],
  ];
  for (var i = 0; i < tails.length; i++) {
    final t = tails[i];
    _rellenar(x, t);
    _hat(
      x,
      t,
      _ro,
      s + i,
      sep: 1.5,
      al: .75,
      cruz: .5,
      intensidad: (double X, double Y) =>
          .45 + .55 * _cl(1 - (Y - cy) / (50 * k), 0, 1),
    );
    _lap(x, t, _ro2, 1, s + i + 5, al: .85);
  }
  _cintaCono(x, cx, cy, w, s + 30);
  final lazos = [
    _petalo(cx, cy, 3.45, 30 * k, 12 * k, taper: -.2, pw: .6),
    _petalo(cx, cy, -.31, 30 * k, 12 * k, taper: -.2, pw: .6),
  ];
  for (var i = 0; i < lazos.length; i++) {
    final l = lazos[i];
    _rellenar(x, l);
    _hat(
      x,
      l,
      _ro,
      s + 10 + i,
      sep: 1.5,
      al: .75,
      cruz: .6,
      intensidad: _radial(cx, cy, 0, 30 * k, .8, 1),
    );
    _lap(x, l, _ro2, 1.1, s + 12 + i, al: .85);
    final f = _petalo(cx, cy, i != 0 ? -.31 : 3.45, 16 * k, 5 * k, taper: 0);
    _hat(x, f, _ro2, s + 14 + i, sep: 1.3, al: .55);
  }
  final n = _circ(cx, cy, 5.5 * k, 20);
  _rellenar(x, n);
  _hat(x, n, _ro2, s + 20, sep: 1.2, al: .85, cruz: .1);
  _lap(x, n, _ro2, 1, s + 21);
}

void _envCortoAtras(Canvas x, int s) {
  final p = [
    const Offset(70, 238),
    const Offset(78, 222),
    const Offset(100, 212),
    const Offset(124, 216),
    const Offset(146, 206),
    const Offset(168, 213),
    const Offset(188, 210),
    const Offset(198, 224),
    const Offset(192, 236),
    const Offset(146, 340),
    const Offset(116, 340),
  ];
  x.drawPath(_camino(p), Paint()..color = _nota);
  _hat(
    x,
    p,
    _kr,
    s,
    sep: 1.8,
    al: .55,
    ang: 1.2,
    intensidad: (double X, double Y) => .5 + .5 * _cl((Y - 208) / 50, 0, 1),
  );
  _hat(
    x,
    p,
    _envoltorio,
    s + 1,
    sep: 2.2,
    al: .35,
    ang: 2.2,
    intensidad: (double X, double Y) => _cl((Y - 224) / 36, 0, 1),
  );
  _lap(x, p, _kr, 1, s + 2, al: .85);
}

void _envCortoDelante(Canvas x, int s) {
  const borde = [
    Offset(70, 238),
    Offset(86, 244),
    Offset(102, 240),
    Offset(118, 247),
    Offset(134, 242),
    Offset(150, 248),
    Offset(166, 241),
    Offset(180, 245),
    Offset(192, 236),
  ];
  final p = [...borde, const Offset(146, 340), const Offset(116, 340)];
  x.drawPath(_camino(p), Paint()..color = _nota);
  _hat(
    x,
    p,
    _kr,
    s,
    sep: 2.1,
    al: .45,
    ang: 1.85,
    intensidad: (double X, double Y) =>
        .3 +
        .7 * _cl((X - 70) / 120, 0, 1) * .6 +
        .4 * _cl((Y - 240) / 100, 0, 1),
  );
  _recortado(x, p, () {
    const bandas = [
      (102.0, 240.0, -1.0),
      (134.0, 242.0, 1.0),
      (166.0, 241.0, 1.0),
    ];
    for (var i = 0; i < bandas.length; i++) {
      final (px, py, sg) = bandas[i];
      final fin = Offset(121.0 + i * 10, 340);
      _lap(
        x,
        [Offset(px, py), fin],
        _envoltorio,
        .8,
        s + 10 + i,
        closed: false,
        al: .6,
      );
      final banda = [
        Offset(px, py),
        fin,
        Offset(fin.dx + sg * 4, fin.dy),
        Offset(px + sg * 8, py + 2),
      ];
      _hat(x, banda, _envoltorio, s + 20 + i, sep: 1.3, al: .4, ang: 1.7);
    }
  });
  _lap(x, p, _kr, 1.15, s + 1, al: .9);
  _lap(x, borde, _envoltorio, .7, s + 2, closed: false, al: .5);
}

void _ramo1(Canvas x, {required int flores, required bool atado}) {
  const K = Offset(130, 268);
  final rosa = flores >= 1;
  final arriba = _bezPts(const Offset(130, 152), const Offset(124, 214), K);
  final abajo = _bezPts(K, const Offset(131, 310), const Offset(129, 348));
  if (rosa) _talloGrueso(x, arriba, 1.6, 1);
  if (rosa) _talloGrueso(x, abajo, 1.6, 3);
  if (rosa) _espina(x, arriba, .55, 1, 5);
  if (rosa) _espina(x, abajo, .55, -1, 7);
  if (rosa) _hojaDe(x, arriba, .42, 1, 44, 14, 11, .8);
  if (rosa) _hojaDe(x, arriba, .68, -1, 38, 12, 13, .75);
  if (rosa) _sepalos(x, 130, 150, 14, 20);
  if (rosa) _rosa2(x, 130, 114, 42, 10);
  if (atado) _lazoAtado(x, K.dx, K.dy - 8, 1, 6, 90);
}

void _ramo2(Canvas x, {required int flores, required bool atado}) {
  const K = Offset(130, 270);
  final margarita = flores >= 2;
  final rosa = flores >= 1;
  final tRosa = _bezPts(const Offset(148, 150), const Offset(140, 214), K);
  final tMarg = _bezPts(const Offset(90, 168), const Offset(104, 224), K);
  final bRosa = _bezPts(K, const Offset(133, 310), const Offset(138, 348));
  final bMarg = _bezPts(K, const Offset(127, 310), const Offset(121, 348));
  if (margarita) _talloGrueso(x, tMarg, 1.3, 21);
  if (margarita) _talloGrueso(x, bMarg, 1.3, 23);
  if (rosa) _talloGrueso(x, tRosa, 1.6, 1);
  if (rosa) _talloGrueso(x, bRosa, 1.6, 3);
  if (rosa) _espina(x, tRosa, .5, 1, 5);
  if (rosa) _espina(x, bRosa, .5, 1, 7);
  if (margarita) _hojaEstrechaDe(x, tMarg, .5, -1, 40, 5, 31, .6);
  if (rosa) _hojaDe(x, tRosa, .55, 1, 40, 13, 13, .75);
  if (margarita) _caliz(x, 90, 165, 9, 40);
  if (margarita) _margarita2(x, 90, 140, 31, 50);
  if (rosa) _sepalos(x, 148, 150, 13, 20);
  if (rosa) _rosa2(x, 148, 114, 38, 10);
  if (atado) _lazoAtado(x, K.dx, K.dy - 8, 1, 8, 90);
}

void _ramo3(Canvas x, {required int flores, required bool atado}) {
  const K = Offset(130, 272);
  final cosmos = flores >= 3;
  final margarita = flores >= 2;
  final rosa = flores >= 1;
  final tRosa = _bezPts(const Offset(140, 150), const Offset(136, 214), K);
  final tMarg = _bezPts(const Offset(86, 168), const Offset(100, 226), K);
  final tCos = _bezPts(const Offset(194, 176), const Offset(166, 226), K);
  final bRosa = _bezPts(K, const Offset(132, 312), const Offset(134, 350));
  final bMarg = _bezPts(K, const Offset(126, 312), const Offset(118, 350));
  final bCos = _bezPts(K, const Offset(136, 312), const Offset(146, 350));
  if (rosa) _hojaDe(x, tRosa, .6, -1, 34, 11, 13, .7);
  if (cosmos) _talloGrueso(x, tCos, 1.1, 41);
  if (cosmos) _talloGrueso(x, bCos, 1.1, 43);
  if (margarita) _talloGrueso(x, tMarg, 1.3, 21);
  if (margarita) _talloGrueso(x, bMarg, 1.3, 23);
  if (rosa) _talloGrueso(x, tRosa, 1.6, 1);
  if (rosa) _talloGrueso(x, bRosa, 1.6, 3);
  if (rosa) _espina(x, tRosa, .42, 1, 5);
  if (rosa) _espina(x, bRosa, .55, -1, 7);
  if (margarita) _hojaEstrechaDe(x, tMarg, .42, -1, 38, 5, 31, .6);
  if (cosmos) _hojaPlumosaDe(x, tCos, .4, 1, 46, 61, .6);
  if (cosmos) _caliz(x, 194, 174, 7, 70);
  if (cosmos) _cosmos2(x, 194, 150, 28, 80);
  if (margarita) _caliz(x, 86, 165, 9, 40);
  if (margarita) _margarita2(x, 86, 140, 30, 50);
  if (rosa) _sepalos(x, 140, 150, 13, 20);
  if (rosa) _rosa2(x, 140, 112, 38, 10);
  if (atado) _lazoAtado(x, K.dx, K.dy - 8, 1, 9, 90);
}

void _ramoGrande(Canvas x, int n, {required int flores, required bool atado}) {
  final tTul = _bezPts(
    const Offset(90, 86),
    const Offset(100, 226),
    const Offset(124, 356),
  );
  final tRosa = _bezPts(
    const Offset(138, 152),
    const Offset(134, 250),
    const Offset(130, 356),
  );
  final tMarg = _bezPts(
    const Offset(78, 170),
    const Offset(104, 250),
    const Offset(120, 356),
  );
  final tCos = _bezPts(
    const Offset(192, 172),
    const Offset(160, 250),
    const Offset(138, 356),
  );
  final rosa = flores >= 1;
  final margarita = flores >= 2;
  final cosmos = flores >= 3;
  final tulipan = flores >= 4;
  final campanillas = n >= 5 && flores >= 5;
  final paniculata = n >= 6 && flores >= 6;
  final lavanda = n >= 7 && flores >= 7;
  final capullo = n >= 8 && flores >= 8;

  if (atado) _envCortoAtras(x, 300);
  // flores de fondo, detrás de las cuatro principales
  if (lavanda) {
    _lavanda3(
      x,
      const Offset(126, 300),
      const Offset(122, 150),
      const Offset(132, 10),
      400,
    );
  }
  if (paniculata) {
    _paniculata2(x, const Offset(108, 250), const [
      Offset(42, 104),
      Offset(58, 74),
      Offset(34, 132),
      Offset(70, 56),
    ], 420);
  }
  if (capullo) {
    _capullo2(
      x,
      const Offset(134, 300),
      const Offset(150, 140),
      const Offset(170, 74),
      440,
    );
  }
  if (campanillas) {
    _campanillas3(
      x,
      const Offset(150, 300),
      const Offset(178, 8),
      const Offset(238, 64),
      460,
    );
  }
  if (cosmos) _talloGrueso(x, tCos, 1.1, 41);
  if (margarita) _talloGrueso(x, tMarg, 1.3, 21);
  if (tulipan) _talloGrueso(x, tTul, 1.9, 51);
  if (rosa) _talloGrueso(x, tRosa, 1.6, 1);
  if (tulipan) _hojaTulipan(x, _enTallo(tTul, .6).p, -1.3, 50, 7, 61);
  if (margarita) _hojaEstrechaDe(x, tMarg, .3, -1, 36, 4.8, 31, .6);
  if (rosa) _hojaDe(x, tRosa, .36, 1, 36, 12, 13, .8);
  if (cosmos) _hojaPlumosaDe(x, tCos, .27, 1, 42, 71, .65);
  if (tulipan) _tulipan2(x, 90, 70, 24, 110);
  if (cosmos) _caliz(x, 192, 170, 7, 80);
  if (cosmos) _cosmos2(x, 192, 146, 28, 90);
  if (margarita) _caliz(x, 78, 167, 9, 40);
  if (margarita) _margarita2(x, 78, 143, 30, 50);
  if (rosa) _sepalos(x, 138, 152, 13, 20);
  if (rosa) _rosa2(x, 138, 116, 37, 10);
  if (atado) _envCortoDelante(x, 320);
  if (atado) _lazoCono(x, 131, 290, 1, 35, 130);
}

/// Dibuja el ramo de [total] hábitos (1, 2, 3 y de 4 a 8; más de 8, el de 8)
/// en el marco de la referencia, 260 x 360. Se ven las [flores] primeras, en
/// el orden de los hábitos, y el papel y el lazo si [atado].
@visibleForTesting
void dibujarRamoDulce(
  Canvas canvas,
  int total, {
  required int flores,
  required bool atado,
}) {
  if (total <= 0) return;
  if (total == 1) {
    _ramo1(canvas, flores: flores, atado: atado);
  } else if (total == 2) {
    _ramo2(canvas, flores: flores, atado: atado);
  } else if (total == 3) {
    _ramo3(canvas, flores: flores, atado: atado);
  } else {
    _ramoGrande(canvas, min(total, 8), flores: flores, atado: atado);
  }
}

/// El ramo del cierre del día de Dulce. Mide [alto] de alto y alto·260/360
/// de ancho. Se graba una vez en la caché del lápiz por cada combinación.
class RamoDulce extends StatelessWidget {
  const RamoDulce({
    super.key,
    required this.total,
    required this.alto,
    this.flores,
    this.atado = true,
  });

  final int total;
  final double alto;

  /// Cuántas flores se ven; null = todas.
  final int? flores;
  final bool atado;

  static const double ancho = 260, altoMarco = 360;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(alto * ancho / altoMarco, alto),
        painter: _PintorRamo(
          total: total,
          flores: flores ?? total,
          atado: atado,
        ),
      ),
    );
  }
}

class _PintorRamo extends CustomPainter {
  _PintorRamo({required this.total, required this.flores, required this.atado});

  final int total;
  final int flores;
  final bool atado;

  @override
  void paint(Canvas canvas, Size size) {
    pintarConCache(canvas, ('ramo', total.clamp(0, 8), flores, atado), size, (
      c,
    ) {
      c.scale(size.height / RamoDulce.altoMarco);
      dibujarRamoDulce(c, total, flores: flores, atado: atado);
    }, desborde: 2);
  }

  @override
  bool shouldRepaint(_PintorRamo anterior) =>
      anterior.total != total ||
      anterior.flores != flores ||
      anterior.atado != atado;
}

/// El nombre del ramo de [total] hábitos, en el idioma activo. De 8 en adelante, «Gran ramo».
String nombreRamo(NordayCoreLocalizations l, int total) =>
    switch (total.clamp(1, 8)) {
      1 => l.ramoUnaRosa,
      2 => l.ramoDetalle,
      3 => l.ramoRamillete,
      4 => l.ramoCampo,
      5 => l.ramoPrimavera,
      6 => l.ramoJardin,
      7 => l.ramoFiesta,
      _ => l.ramoGrande,
    };
