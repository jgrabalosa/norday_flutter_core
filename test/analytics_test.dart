import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/analytics_service.dart';

/// En los tests Firebase no está inicializado, así que cualquier llamada real
/// a Analytics falla. Es justo el caso que estos métodos no pueden dejar
/// escapar: quien los llama lo hace dentro de su propio try.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsCore.login(1), completes);
  });

  test('ayudaAbierta manda ayuda_abierta con el id', () async {
    final enviados = <(String, Map<String, Object>)>[];
    final original = AnalyticsCore.enviarEvento;
    addTearDown(() => AnalyticsCore.enviarEvento = original);
    AnalyticsCore.enviarEvento = (n, p) async => enviados.add((n, p));

    await AnalyticsCore.ayudaAbierta('tienda');

    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'ayuda_abierta');
    expect(enviados.single.$2, {'ayuda': 'tienda'});
  });

  test('ayudaAbierta no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsCore.ayudaAbierta('tienda'), completes);
  });

  test('pistaVista manda pista_vista con la pista', () async {
    final enviados = <(String, Map<String, Object>)>[];
    final original = AnalyticsCore.enviarEvento;
    addTearDown(() => AnalyticsCore.enviarEvento = original);
    AnalyticsCore.enviarEvento = (n, p) async => enviados.add((n, p));

    await AnalyticsCore.pistaVista('tienda');

    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'pista_vista');
    expect(enviados.single.$2, {'pista': 'tienda'});
  });

  test('pistaVista no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsCore.pistaVista('tienda'), completes);
  });

  test('avisoActualizacion manda aviso_actualizacion con el paso', () async {
    final enviados = <(String, Map<String, Object>)>[];
    final original = AnalyticsCore.enviarEvento;
    addTearDown(() => AnalyticsCore.enviarEvento = original);
    AnalyticsCore.enviarEvento = (n, p) async => enviados.add((n, p));

    await AnalyticsCore.avisoActualizacion('ofrecida');

    expect(enviados.single.$1, 'aviso_actualizacion');
    expect(enviados.single.$2, {'paso': 'ofrecida'});
  });

  test('avisoActualizacion no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsCore.avisoActualizacion('ofrecida'), completes);
  });

  test('registro no lanza aunque Firebase falle', () async {
    await expectLater(AnalyticsCore.registro(1), completes);
  });
}
