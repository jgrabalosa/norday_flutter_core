import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/l10n/mensajes_mascota.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';

String frase(String idioma, String fase, String estado, int nivel) =>
    MensajesMascota.contexto(
      lookupNordayCoreLocalizations(Locale(idioma)),
      codigoFase: fase,
      codigoEstado: estado,
      nivel: nivel,
    );

void main() {
  test('exultante tiene su frase en los tres idiomas', () {
    expect(frase('es', 'CRIA', 'exultante', 3), 'Cría · Nivel 3 · radiante');
    expect(
      frase('en', 'CRIA', 'exultante', 3),
      'Hatchling · Level 3 · beaming',
    );
    expect(
      frase('pt', 'ADULTO', 'exultante', 7),
      'Adulto · Nível 7 · radiante',
    );
  });

  test('los tres estados de siempre no cambian', () {
    expect(frase('es', 'CRIA', 'feliz', 3), 'Cría · Nivel 3 · a gusto contigo');
    expect(
      frase('es', 'CRIA', 'dormida', 3),
      'Cría · Nivel 3 · echando una cabezada',
    );
    expect(
      frase('es', 'CRIA', 'triste', 3),
      'Cría · Nivel 3 · te echa de menos',
    );
  });

  test('dentro del huevo no se menciona el estado, tampoco exultante', () {
    expect(
      frase('es', 'HUEVO', 'exultante', 1),
      'Huevo · Nivel 1 · a punto de romper el cascarón',
    );
  });
}
