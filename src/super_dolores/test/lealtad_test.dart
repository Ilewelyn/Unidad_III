import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/lealtad.dart';
import 'package:super_dolores/dominio/monedero.dart';

final lunes = DateTime(2026, 11, 9, 10);
DateTime dia(int n, [int h = 10]) => DateTime(2026, 11, 9 + n, h);

int _n = 0;
String id() => 'e${++_n}';

EventoApp compra(DateTime f, int total, {String u = 'u1'}) =>
    PedidoCreado(id(), u, f, pedidoId: 'p', totalCentavos: total);
EventoApp viaje(DateTime f, int monto, {String u = 'u1'}) =>
    ViajeFinalizado(id(), u, f, viajeId: 'v', montoCentavos: monto);
EventoApp mensaje(DateTime f, {String u = 'u1'}) => MensajeEnviado(id(), u, f, para: 'x');
EventoApp pago(DateTime f, {String u = 'u1'}) =>
    PagoRealizado(id(), u, f, montoCentavos: 100, concepto: 'x', origen: Servicio.pagos);

Lealtad nueva() {
  final m = Monedero()..abrirCuenta('u1');
  return Lealtad(m);
}

void main() {
  group('Lealtad: puntos por gasto', () {
    test('1 punto por cada \$10 en compras y viajes', () {
      final l = nueva()
        ..alEvento(compra(lunes, 5600))
        ..alEvento(compra(lunes, 8300)); // mismo servicio: sin bono de variedad
      expect(l.puntos('u1'), 5 + 8);
    });
    test('un evento repetido NO premia dos veces (idempotencia por id)', () {
      final l = nueva();
      final e = compra(lunes, 10000);
      l.alEvento(e);
      l.alEvento(e);
      expect(l.puntos('u1'), 10);
    });
    test('mensajes y pagos entre personas no dan puntos por gasto', () {
      final l = nueva()
        ..alEvento(mensaje(lunes))
        ..alEvento(pago(lunes));
      expect(l.puntos('u1'), 0 + 50); // solo el bono de 2 servicios distintos
    });
    test('recibir dinero es pasivo: ni puntos ni racha', () {
      final l = nueva()..alEvento(DineroRecibido(id(), 'u1', lunes, de: 'x', montoCentavos: 999999));
      expect(l.puntos('u1'), 0);
      expect(l.racha('u1'), 0);
    });
  });
  group('Lealtad: niveles', () {
    test('Bronce → Plata en 500 y → Oro en 2000', () {
      final l = nueva()..alEvento(compra(lunes, 499000));
      expect(l.puntos('u1'), 499);
      expect(l.nivel('u1'), NivelLealtad.bronce);
      l.alEvento(compra(lunes, 1000));
      expect(l.puntos('u1'), 500);
      expect(l.nivel('u1'), NivelLealtad.plata);
      l.alEvento(compra(lunes, 1500000));
      expect(l.nivel('u1'), NivelLealtad.oro);
    });
    test('Plata gana 125% de puntos por gasto', () {
      final l = nueva()..alEvento(compra(lunes, 500000)); // 500 pts → Plata
      l.alEvento(compra(lunes, 10000)); // base 10 × 125% = 12
      expect(l.puntos('u1'), 512);
    });
  });
  group('Lealtad: bono semanal por variedad de servicios', () {
    test('2 → +50, 3 → +100, 4 → +200 (una vez por escalón y por semana)', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(compra(dia(1), 1000)) // 1 pt + 50
        ..alEvento(viaje(dia(2), 1000)) // 1 pt + 100
        ..alEvento(pago(dia(3))); // +200
      expect(l.puntos('u1'), 1 + 50 + 1 + 100 + 200);
    });
    test('repetir el mismo servicio no vuelve a dar bono', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(pago(dia(0)))
        ..alEvento(mensaje(dia(1)))
        ..alEvento(pago(dia(1)));
      expect(l.puntos('u1'), 50);
    });
    test('la semana siguiente el bono se puede ganar de nuevo', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(pago(dia(1))) // semana 1: +50
        ..alEvento(mensaje(dia(7)))
        ..alEvento(pago(dia(8))); // semana 2: +50
      expect(l.puntos('u1'), 100);
    });
    test('domingo y lunes siguiente son semanas distintas', () {
      final l = nueva()
        ..alEvento(mensaje(dia(6))) // domingo
        ..alEvento(pago(dia(7))); // lunes de la semana siguiente
      expect(l.puntos('u1'), 0);
    });
  });
  group('Lealtad: racha', () {
    test('7 días seguidos dan +70', () {
      final l = nueva();
      for (var d = 0; d < 7; d++) {
        l.alEvento(mensaje(dia(d)));
      }
      expect(l.racha('u1'), 7);
      expect(l.puntos('u1'), 70);
    });
    test('varios eventos el mismo día no inflan la racha', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0, 8)))
        ..alEvento(mensaje(dia(0, 20)));
      expect(l.racha('u1'), 1);
    });
    test('saltarse un día reinicia la racha a 1', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(mensaje(dia(1)))
        ..alEvento(mensaje(dia(3)));
      expect(l.racha('u1'), 1);
    });
    test('un evento atrasado (día anterior) no rompe la racha', () {
      final l = nueva()
        ..alEvento(mensaje(dia(1)))
        ..alEvento(mensaje(dia(0)));
      expect(l.racha('u1'), 1);
    });
  });
  group('Lealtad: canje', () {
    test('100 puntos = \$10 de saldo', () {
      final m = Monedero()..abrirCuenta('u1');
      final l = Lealtad(m)..alEvento(compra(lunes, 300000)); // 300 pts
      final c = l.canjear('u1', 200);
      expect(c, 2000);
      expect(m.saldo('u1'), 2000);
      expect(l.puntos('u1'), 100);
    });
    test('solo múltiplos de 100 y sin pasarse de los puntos', () {
      final l = nueva()..alEvento(compra(lunes, 300000));
      expect(() => l.canjear('u1', 250), throwsA(isA<CanjeInvalidoException>()));
      expect(() => l.canjear('u1', 0), throwsA(isA<CanjeInvalidoException>()));
      expect(() => l.canjear('u1', 400), throwsA(isA<CanjeInvalidoException>()));
      expect(l.puntos('u1'), 300);
    });
  });
}
