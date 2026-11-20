import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/datos/pasarela_simulada.dart';
import 'package:tienda_talavera/dominio/contratos.dart';
import 'package:tienda_talavera/dominio/tarjeta.dart';

const buena = DatosTarjeta(numero: '4242424242424242', titular: 'Ana', mes: 12, anio: 30, cvv: '123');
const rechazada = DatosTarjeta(numero: '4000000000000002', titular: 'Ana', mes: 12, anio: 30, cvv: '123');

void main() {
  group('pasarela simulada', () {
    test('aprueba tarjeta de prueba', () async {
      final r = await PasarelaSimulada().cobrar(
          montoCentavos: 1000, tarjeta: buena, claveIdempotencia: 'k1');
      expect(r, isA<PagoAprobado>());
    });
    test('rechaza tarjeta 0002', () async {
      final r = await PasarelaSimulada().cobrar(
          montoCentavos: 1000, tarjeta: rechazada, claveIdempotencia: 'k1');
      expect(r, isA<PagoRechazado>());
    });
    test('IDEMPOTENCIA: misma clave dos veces cobra una sola vez', () async {
      final p = PasarelaSimulada();
      final a = await p.cobrar(montoCentavos: 1000, tarjeta: buena, claveIdempotencia: 'k1');
      final b = await p.cobrar(montoCentavos: 1000, tarjeta: buena, claveIdempotencia: 'k1');
      expect((a as PagoAprobado).referencia, (b as PagoAprobado).referencia);
      expect(p.cobrosAprobados, 1);
    });
    test('claves distintas sí cobran por separado', () async {
      final p = PasarelaSimulada();
      await p.cobrar(montoCentavos: 1000, tarjeta: buena, claveIdempotencia: 'k1');
      await p.cobrar(montoCentavos: 1000, tarjeta: buena, claveIdempotencia: 'k2');
      expect(p.cobrosAprobados, 2);
    });
  });
}