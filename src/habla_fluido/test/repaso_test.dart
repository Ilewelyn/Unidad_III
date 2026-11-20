import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/dominio/repaso.dart';

final d1 = DateTime(2026, 11, 5, 14, 30);

void main() {
  group('SM-2', () {
    test('secuencia 4, 5, 5, 2', () {
      var t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1);
      t = t.calificar(4, d1);
      expect((t.repeticiones, t.intervaloDias), (1, 1));
      expect(t.facilidad, closeTo(2.5, 1e-9));
      t = t.calificar(5, d1);
      expect((t.repeticiones, t.intervaloDias), (2, 6));
      expect(t.facilidad, closeTo(2.6, 1e-9));
      t = t.calificar(5, d1);
      expect((t.repeticiones, t.intervaloDias), (3, 16)); // 6 × 2.6 = 15.6 → 16
      expect(t.facilidad, closeTo(2.7, 1e-9));
      t = t.calificar(2, d1); // fallo: vuelve a empezar
      expect((t.repeticiones, t.intervaloDias), (0, 1));
      expect(t.facilidad, closeTo(2.38, 1e-9));
    });
    test('la facilidad nunca baja de 1.3', () {
      var t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1);
      for (var i = 0; i < 30; i++) {
        t = t.calificar(0, d1);
      }
      expect(t.facilidad, 1.3);
    });
    test('la próxima fecha se cuenta en días completos', () {
      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(5, d1);
      expect(t.proxima, DateTime(2026, 11, 6));
    });
    test('vencida si la fecha llegó (sin importar la hora)', () {
      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: DateTime(2026, 11, 6));
      expect(t.estaVencida(DateTime(2026, 11, 5, 23, 59)), isFalse);
      expect(t.estaVencida(DateTime(2026, 11, 6, 0, 1)), isTrue);
    });
    test('calidad fuera de rango lanza', () {
      expect(() => TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(6, d1),
          throwsArgumentError);
    });
    test('calidadDesdePuntaje', () {
      expect([1.0, 0.9, 0.75, 0.6, 0.4, 0.1].map(calidadDesdePuntaje), [5, 4, 3, 2, 1, 0]);
    });
    test('JSON de ida y vuelta y dato dañado', () {
      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(5, d1);
      final r = TarjetaRepaso.desdeJson(t.aJson())!;
      expect((r.id, r.intervaloDias, r.facilidad), ('a', 1, t.facilidad));
      expect(TarjetaRepaso.desdeJson({'id': 3}), isNull);
      expect(TarjetaRepaso.desdeJson('basura'), isNull);
    });
    test('mazo: registra, programa y lista pendientes', () {
      final m = MazoRepaso();
      m.registrar(id: 'a', frase: 'x', traduccion: 'y', puntaje: 0.2, hoy: d1);
      m.registrar(id: 'b', frase: 'x2', traduccion: 'y2', puntaje: 1.0, hoy: d1);
      expect(m.todas.length, 2);
      expect(m.pendientes(d1), isEmpty); // ambas quedan para mañana
      expect(m.pendientes(DateTime(2026, 11, 6)).length, 2);
      m.calificar('a', 5, DateTime(2026, 11, 6));
      expect(m.pendientes(DateTime(2026, 11, 6)).length, 1);
    });
  });
}