import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/monedero.dart';
import 'package:super_dolores/dominio/transporte.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);
const jardin = Punto(21.1561, -100.9333);
const parroquia = Punto(21.1565, -100.9339);
const utng = Punto(21.1325, -100.9267);

/// Entorno mínimo: pasajero (con saldo configurable), conductor y plataforma.
class Entorno {
  final Monedero monedero;
  final BusEventos bus = BusEventos();
  final Ids ids = Ids();
  late final ServicioViajes viajes = ServicioViajes(monedero, bus, ids, () => ahora);

  Entorno({int saldoAna = 100000}) : monedero = Monedero(reloj: () => ahora) {
    monedero
      ..abrirCuenta('ana')
      ..abrirCuenta('luis')
      ..abrirCuenta('conductor1')
      ..abrirCuenta('plataforma', sinLimites: true);
    if (saldoAna > 0) monedero.depositar('ana', saldoAna, clave: 'semilla');
  }
}

int dineroTotal(Entorno e) =>
    ['ana', 'luis', 'conductor1', 'plataforma'].fold(0, (s, c) => s + e.monedero.saldo(c));

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('Transporte', () {
    test('Haversine: un grado de longitud en el ecuador ≈ 111.195 km', () {
      expect(distanciaKm(const Punto(0, 0), const Punto(0, 1)), closeTo(111.195, 0.01));
    });
    test('distancia cero y simetría', () {
      expect(distanciaKm(jardin, jardin), 0);
      expect(distanciaKm(jardin, utng), closeTo(distanciaKm(utng, jardin), 1e-9));
      expect(distanciaKm(jardin, utng), closeTo(2.712, 0.01));
    });
    test('tarifa: base + km + minutos', () => expect(Tarifa.calcular(km: 5, minutos: 12), 8300));
    test('tarifa dinámica con tope de 2.0 y piso de 1.0', () {
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 1.5), 12450);
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 3), 16600);
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 0.5), 8300);
    });
    test('viaje muy corto paga el mínimo', () => expect(Tarifa.calcular(km: 0.5, minutos: 2), Tarifa.minimoCentavos));
    test('minutos estimados a 25 km/h, redondeando hacia arriba', () {
      expect(Tarifa.minutosEstimados(5), 12);
      expect(Tarifa.minutosEstimados(10), 24);
      expect(Tarifa.minutosEstimados(2.5), 6);
    });
    test('estimar usa la distancia real', () {
      final e = Entorno();
      expect(e.viajes.estimar(jardin, utng), 5720);
      expect(e.viajes.estimar(jardin, parroquia), Tarifa.minimoCentavos);
    });
    test('solicitar exige saldo para el estimado', () {
      final e = Entorno(saldoAna: 0);
      expect(() => e.viajes.solicitar('ana', jardin, utng), throwsA(isA<SaldoInsuficienteException>()));
    });
    test('viaje completo: cobra la tarifa REAL y paga al conductor menos 20%', () {
      final e = Entorno();
      final antes = dineroTotal(e);
      final v = e.viajes.solicitar('ana', jardin, utng);
      expect(v.estado, EstadoViaje.solicitado);
      e.viajes.aceptar(v.id, 'conductor1');
      e.viajes.iniciar(v.id);
      final fin = e.viajes.finalizar(v.id, kmReal: 5, minutosReal: 12);
      expect(fin.estado, EstadoViaje.finalizado);
      expect(fin.cobradoCentavos, 8300);
      expect(e.monedero.saldo('ana'), 91700);
      expect(e.monedero.saldo('conductor1'), 6640);
      expect(e.monedero.saldo('plataforma'), 1660);
      expect(dineroTotal(e), antes); // el dinero solo cambió de manos
    });
    test('transiciones ilegales lanzan error y no cambian nada', () {
      final e = Entorno();
      final v = e.viajes.solicitar('ana', jardin, utng);
      expect(() => e.viajes.iniciar(v.id), throwsA(isA<TransicionInvalidaException>()));
      expect(() => e.viajes.finalizar(v.id, kmReal: 1, minutosReal: 1), throwsA(isA<TransicionInvalidaException>()));
      e.viajes.aceptar(v.id, 'conductor1');
      e.viajes.iniciar(v.id);
      expect(() => e.viajes.cancelar(v.id), throwsA(isA<TransicionInvalidaException>()));
      e.viajes.finalizar(v.id, kmReal: 3, minutosReal: 8);
      expect(() => e.viajes.finalizar(v.id, kmReal: 3, minutosReal: 8), throwsA(isA<TransicionInvalidaException>()));
      expect(e.monedero.saldo('plataforma') > 0, isTrue);
    });
    test('cancelar antes de que acepten es gratis', () {
      final e = Entorno();
      final v = e.viajes.solicitar('ana', jardin, utng);
      expect(e.viajes.cancelar(v.id).estado, EstadoViaje.cancelado);
      expect(e.monedero.saldo('ana'), 100000);
    });
    test('cancelar después de aceptar cobra \$15 al pasajero para el conductor', () {
      final e = Entorno();
      final v = e.viajes.solicitar('ana', jardin, utng);
      e.viajes.aceptar(v.id, 'conductor1');
      e.viajes.cancelar(v.id);
      expect(e.monedero.saldo('ana'), 98500);
      expect(e.monedero.saldo('conductor1'), 1500);
    });
    test('la cancelación cobra solo lo que haya si el saldo es menor a \$15', () {
      final e = Entorno(saldoAna: 0);
      e.monedero.depositar('ana', 5000, clave: 'd');
      final v = e.viajes.solicitar('ana', jardin, parroquia); // estimado $45
      e.viajes.aceptar(v.id, 'conductor1');
      e.monedero.transferir('ana', 'luis', 4000, 'x', clave: 't'); // quedan $10
      e.viajes.cancelar(v.id);
      expect(e.monedero.saldo('ana'), 0);
      expect(e.monedero.saldo('conductor1'), 1000);
    });
  });
}