import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/eventos.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);

void main() {
  group('Bus de eventos', () {
    EventoApp pago(String id) => PagoRealizado(id, 'ana', ahora, montoCentavos: 100, concepto: 'x', origen: Servicio.pagos);
    test('cada suscriptor recibe solo el TIPO que pidió', () {
      final bus = BusEventos();
      final pagos = <String>[];
      final mensajes = <String>[];
      bus.suscribir<PagoRealizado>((e) => pagos.add(e.id));
      bus.suscribir<MensajeEnviado>((e) => mensajes.add(e.id));
      bus.publicar(pago('e1'));
      bus.publicar(MensajeEnviado('e2', 'ana', ahora, para: 'luis'));
      expect(pagos, ['e1']);
      expect(mensajes, ['e2']);
    });
    test('un suscriptor que falla no impide que los demás reciban el evento', () {
      final bus = BusEventos();
      var recibido = 0;
      bus.suscribir<PagoRealizado>((_) => throw StateError('boom'));
      bus.suscribir<PagoRealizado>((_) => recibido++);
      bus.publicar(pago('e1'));
      expect(recibido, 1);
      expect(bus.errores.length, 1);
    });
    test('Ids genera identificadores únicos y legibles', () {
      final ids = Ids();
      expect([ids.siguiente('ev'), ids.siguiente('ev'), ids.siguiente('msg')], ['ev-1', 'ev-2', 'msg-3']);
    });
    test('recibir dinero no cuenta como uso; enviar mensajes sí', () {
      expect(DineroRecibido('e', 'ana', ahora, de: 'luis', montoCentavos: 1).cuentaComoUso, isFalse);
      expect(MensajeEnviado('e', 'ana', ahora, para: 'luis').cuentaComoUso, isTrue);
    });
  });
}