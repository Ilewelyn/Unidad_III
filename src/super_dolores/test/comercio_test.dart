import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/comercio.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/monedero.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);

/// Entorno mínimo: Ana con $1,000 y tres negocios de Dolores Hidalgo.
class Entorno {
  final Monedero monedero = Monedero(reloj: () => ahora)
    ..abrirCuenta('ana')
    ..abrirCuenta('plataforma', sinLimites: true)
    ..abrirCuenta('dueno-tortilleria')
    ..abrirCuenta('dueno-talavera')
    ..abrirCuenta('dueno-cajeta');
  final BusEventos bus = BusEventos();
  final Ids ids = Ids();
  late final ServicioComercio comercio;

  Entorno() {
    monedero.depositar('ana', 100000, clave: 'semilla');
    comercio = ServicioComercio(monedero, bus, ids, () => ahora, [
      Tienda('tortilleria', 'Tortillería Doña Lupe', '🫓', 'dueno-tortilleria', [
        ProductoTienda('kilo', 'Kilo de tortillas', 2800, 50),
      ]),
      Tienda('talavera', 'Talavera La Esperanza', '🏺', 'dueno-talavera', [
        ProductoTienda('jarron', 'Jarrón Talavera', 125000, 5),
        ProductoTienda('taza', 'Taza Talavera', 22000, 20),
      ]),
      Tienda('cajeta', 'Dulcería Cajeta Real', '🍯', 'dueno-cajeta', [
        ProductoTienda('cajeta', 'Cajeta', 9500, 40),
        ProductoTienda('alegrias', 'Alegrías', 7500, 60),
      ]),
    ]);
  }
}

int dineroTotal(Entorno e) => ['ana', 'plataforma', 'dueno-tortilleria', 'dueno-talavera', 'dueno-cajeta']
    .fold(0, (s, c) => s + e.monedero.saldo(c));

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('Comercio', () {
    test('compra: cobra, reparte la comisión del 5% y descuenta inventario', () {
      final e = Entorno();
      final pedido = e.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 2}, clave: 'p1');
      expect(pedido.totalCentavos, 5600);
      expect(pedido.comisionCentavos, 280);
      expect(e.monedero.saldo('ana'), 94400);
      expect(e.monedero.saldo('dueno-tortilleria'), 5320); // 5,600 - 280
      expect(e.monedero.saldo('plataforma'), 280);
      expect(e.comercio.tiendas.first.producto('kilo')!.existencias, 48);
      expect(e.comercio.pedidosDe('ana').single.id, pedido.id);
    });
    test('INVARIANTE: la suma de todo el dinero del sistema no cambia con una compra', () {
      final e = Entorno();
      final antes = dineroTotal(e);
      e.comercio.comprar(usuarioId: 'ana', tiendaId: 'cajeta', items: {'cajeta': 3, 'alegrias': 1}, clave: 'p1');
      expect(dineroTotal(e), antes);
    });
    test('IDEMPOTENCIA: un doble toque no compra dos veces', () {
      final e = Entorno();
      final a = e.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 1}, clave: 'p1');
      final b = e.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 1}, clave: 'p1');
      expect(identical(a, b), isTrue);
      expect(e.monedero.saldo('ana'), 97200);
      expect(e.comercio.tiendas.first.producto('kilo')!.existencias, 49);
    });
    test('sin saldo: no hay pedido, ni cobro, ni cambio de inventario', () {
      final e = Entorno();
      expect(
          () => e.comercio.comprar(usuarioId: 'ana', tiendaId: 'talavera', items: {'jarron': 1}, clave: 'p1'),
          throwsA(isA<SaldoInsuficienteException>()));
      expect(e.comercio.pedidosDe('ana'), isEmpty);
      expect(e.comercio.tiendas[1].producto('jarron')!.existencias, 5);
      expect(e.monedero.saldo('ana'), 100000);
    });
    test('validaciones del pedido', () {
      final e = Entorno();
      PedidoInvalidoException? err;
      void intentar(Map<String, int> items, {String tienda = 'tortilleria'}) {
        try {
          e.comercio.comprar(usuarioId: 'ana', tiendaId: tienda, items: items, clave: 'k${items.hashCode}');
        } on PedidoInvalidoException catch (x) {
          err = x;
        }
      }
      intentar({});
      expect(err, isNotNull);
      err = null;
      intentar({'kilo': 0});
      expect(err, isNotNull);
      err = null;
      intentar({'kilo': 11});
      expect(err, isNotNull);
      err = null;
      intentar({'noexiste': 1});
      expect(err, isNotNull);
      err = null;
      intentar({'kilo': 1}, tienda: 'fantasma');
      expect(err, isNotNull);
    });
    test('existencias insuficientes', () {
      final e = Entorno();
      expect(
          () => e.comercio.comprar(usuarioId: 'ana', tiendaId: 'talavera', items: {'jarron': 6}, clave: 'k'),
          throwsA(isA<ExistenciasInsuficientesException>()));
    });
  });
}