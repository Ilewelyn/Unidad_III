import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/dominio/carrito.dart';
import 'package:tienda_talavera/dominio/dinero.dart';
import 'package:tienda_talavera/dominio/excepciones.dart';
import 'package:tienda_talavera/dominio/producto.dart';

Producto prod(String id, int precio, {int stock = 10, String? glb}) => Producto(
      id: id, nombre: 'P$id', descripcion: 'd', precioCentavos: precio,
      categoria: Categoria.talavera, existencias: stock, emoji: '🏺', modeloGlb: glb);

void main() {
  group('dinero', () {
    test('formatea pesos', () => expect(formatearPesos(125000), r'$1,250.00'));
    test('IVA incluido de 116.00 es 16.00', () => expect(ivaIncluido(11600), 1600));
    test('porcentaje redondea al centavo', () => expect(porcentaje(9999, 10), 1000));
  });

  group('producto', () {
    test('https cuenta como modelo 3D', () =>
        expect(prod('a', 1, glb: 'https://x.com/a.glb').tieneModelo3d, isTrue));
    test('http NO cuenta', () =>
        expect(prod('a', 1, glb: 'http://x.com/a.glb').tieneModelo3d, isFalse));
    test('sin modelo', () => expect(prod('a', 1).tieneModelo3d, isFalse));
  });

  group('carrito', () {
    test('suma subtotal', () {
      final c = Carrito()..agregar(prod('a', 10000), cantidad: 2)..agregar(prod('b', 5000));
      expect(c.subtotal, 25000);
    });
    test('rechaza más que las existencias y queda intacto', () {
      final c = Carrito()..agregar(prod('a', 100, stock: 3), cantidad: 2);
      expect(() => c.agregar(prod('a', 100, stock: 3), cantidad: 2),
          throwsA(isA<ExistenciasInsuficientesException>()));
      expect(c.cantidadTotal, 2);
    });
    test('límite de 10 por producto', () {
      final c = Carrito();
      expect(() => c.agregar(prod('a', 100, stock: 50), cantidad: 11),
          throwsA(isA<LimiteProductoException>()));
    });
    test('envío gratis desde \$800', () {
      expect((Carrito()..agregar(prod('a', 79999))).envio, Carrito.costoEnvio);
      expect((Carrito()..agregar(prod('a', 80000))).envio, 0);
    });
    test('cupón DOLORES10 descuenta 10%', () {
      final c = Carrito()..agregar(prod('a', 10000))..aplicarCupon(' dolores10 ');
      expect(c.descuento, 1000);
    });
    test('cupón inválido lanza', () {
      expect(() => Carrito().aplicarCupon('XYZ'), throwsA(isA<CuponInvalidoException>()));
    });
    test('restaurar recorta a existencias y descarta desconocidos', () {
      final c = Carrito();
      final p = prod('a', 100, stock: 2);
      c.restaurar([
        {'id': 'a', 'cantidad': 9},
        {'id': 'fantasma', 'cantidad': 1},
      ], (id) => id == 'a' ? p : null);
      expect(c.cantidadTotal, 2);
      expect(c.lineas.length, 1);
    });
    test('aMapas solo guarda id y cantidad', () {
      final c = Carrito()..agregar(prod('a', 100));
      expect(c.aMapas().first.keys.toSet(), {'id', 'cantidad'});
    });
  });

}
