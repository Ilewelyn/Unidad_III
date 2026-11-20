import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/dinero.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/mensajeria.dart';
import 'package:super_dolores/dominio/monedero.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);

/// Entorno mínimo: monedero con Ana (con $1,000), bus de eventos y el servicio de mensajes.
class Entorno {
  final Monedero monedero = Monedero(reloj: () => ahora)
    ..abrirCuenta('ana')
    ..abrirCuenta('luis');
  final BusEventos bus = BusEventos();
  final Ids ids = Ids();
  late final ServicioMensajes mensajes = ServicioMensajes(monedero, bus, ids, () => ahora);

  Entorno() {
    monedero.depositar('ana', 100000, clave: 'semilla');
  }
}

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('Mensajería', () {
    test('valida mensajes vacíos, enormes, a uno mismo y a "sistema"', () {
      final e = Entorno();
      expect(() => e.mensajes.enviar('ana', 'luis', '   '), throwsA(isA<MensajeInvalidoException>()));
      expect(() => e.mensajes.enviar('ana', 'luis', 'x' * 1001), throwsA(isA<MensajeInvalidoException>()));
      e.mensajes.enviar('ana', 'luis', 'x' * 1000); // justo en el límite
      expect(() => e.mensajes.enviar('ana', 'ana', 'hola'), throwsA(isA<DestinatarioInvalidoException>()));
      expect(() => e.mensajes.enviar('ana', ServicioMensajes.sistema, 'hola'),
          throwsA(isA<DestinatarioInvalidoException>()));
    });
    test('conversación en orden, no leídos y marcarLeidos', () {
      final e = Entorno();
      e.mensajes.enviar('ana', 'luis', 'Hola');
      e.mensajes.enviar('luis', 'ana', 'Qué tal');
      e.mensajes.enviar('ana', 'luis', 'Bien');
      expect(e.mensajes.conversacion('ana', 'luis').map((m) => m.texto), ['Hola', 'Qué tal', 'Bien']);
      expect(e.mensajes.noLeidos('luis'), 2);
      e.mensajes.marcarLeidos('luis', 'ana');
      expect(e.mensajes.noLeidos('luis'), 0);
      expect(e.mensajes.noLeidos('ana'), 1);
    });
    test('resumenes: el chat más reciente va primero y cuenta no leídos', () {
      final e = Entorno();
      e.mensajes.enviar('luis', 'ana', 'uno');
      e.mensajes.enviar('marta', 'ana', 'dos');
      e.mensajes.enviar('luis', 'ana', 'tres');
      final r = e.mensajes.resumenes('ana');
      expect(r.map((x) => x.con), ['luis', 'marta']);
      expect(r.first.noLeidos, 2);
    });
    test('mensajes de la plataforma llegan al usuario y no son de una persona', () {
      final e = Entorno();
      e.mensajes.enviarSistema('ana', 'Bienvenida');
      expect(e.mensajes.deSistema('ana').length, 1);
      expect(e.mensajes.deSistema('luis'), isEmpty);
    });
    test('dinero en el chat: transfiere, deja mensaje y publica eventos', () {
      final e = Entorno();
      final recibidos = <DineroRecibido>[];
      e.bus.suscribir<DineroRecibido>(recibidos.add);
      final m = e.mensajes.enviarDinero('ana', 'luis', 5000, clave: 'c1');
      expect(m.tipo, TipoMensaje.dinero);
      expect(e.monedero.saldo('ana'), 95000);
      expect(e.monedero.saldo('luis'), 5000);
      expect(recibidos.single.montoCentavos, 5000);
      expect(recibidos.single.cuentaComoUso, isFalse); // recibir es pasivo
    });
    test('si falta saldo, no se envía ni el dinero ni el mensaje', () {
      final e = Entorno();
      e.mensajes.enviarDinero('ana', 'luis', 50000, clave: 'c1');
      expect(() => e.mensajes.enviarDinero('ana', 'luis', 60000, clave: 'c2'),
          throwsA(isA<SaldoInsuficienteException>()));
      expect(e.mensajes.conversacion('ana', 'luis').length, 1);
    });
  });
}