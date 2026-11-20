import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/notificaciones.dart';
import 'package:super_dolores/dominio/sugerencias.dart';

DateTime dia(int n, [int h = 10]) => DateTime(2026, 11, 9 + n, h);

void main() {
  group('Notificaciones éticas', () {
    Notificacion promo(DateTime f, {String u = 'u1'}) =>
        Notificacion(u, TipoNotificacion.promocional, 'Oferta', '...', f);
    Notificacion trans(DateTime f) => Notificacion('u1', TipoNotificacion.transaccional, 'Aviso', '...', f);

    test('tope de 2 promociones al día y se renueva al siguiente', () {
      final n = Notificador();
      expect(n.intentar(promo(dia(0, 9))), isTrue);
      expect(n.intentar(promo(dia(0, 12))), isTrue);
      expect(n.intentar(promo(dia(0, 15))), isFalse);
      expect(n.intentar(promo(dia(1, 9))), isTrue);
    });
    test('horario de silencio de 10 pm a 8 am para promociones', () {
      final n = Notificador();
      expect(n.intentar(promo(dia(0, 22))), isFalse);
      expect(n.intentar(promo(dia(0, 23))), isFalse);
      expect(n.intentar(promo(dia(0, 7))), isFalse);
      expect(n.intentar(promo(dia(0, 8))), isTrue);
      expect(n.intentar(promo(dia(0, 21))), isTrue);
    });
    test('las transaccionales (te llegó dinero) pasan siempre', () {
      final n = Notificador();
      for (var i = 0; i < 5; i++) {
        expect(n.intentar(trans(dia(0, 3))), isTrue);
      }
    });
    test('quien desactiva las promociones no recibe ninguna', () {
      final n = Notificador()..configurarPromociones('u1', activas: false);
      expect(n.intentar(promo(dia(0, 12))), isFalse);
      expect(n.intentar(trans(dia(0, 12))), isTrue);
      n.configurarPromociones('u1', activas: true);
      expect(n.intentar(promo(dia(0, 12))), isTrue);
    });
    test('el tope es POR persona', () {
      final n = Notificador();
      n.intentar(promo(dia(0, 9)));
      n.intentar(promo(dia(0, 10)));
      expect(n.intentar(promo(dia(0, 11), u: 'u2')), isTrue);
    });
  });

  group('Sugerencias', () {
    DateTime h(int hora) => DateTime(2026, 11, 9, hora);
    test('según la hora propone primero un servicio distinto que aún no usa', () {
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(9)).servicio, Servicio.transporte);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(13)).servicio, Servicio.comercio);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(19)).servicio, Servicio.mensajeria);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(23)).servicio, Servicio.mensajeria);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(3)).servicio, Servicio.mensajeria);
    });
    test('salta los que ya usa', () {
      final s = sugerirServicio(usosUltimos30Dias: {Servicio.transporte: 5}, ahora: h(9));
      expect(s.servicio, Servicio.mensajeria);
    });
    test('si usa todos, propone el menos usado', () {
      final s = sugerirServicio(
        usosUltimos30Dias: {Servicio.transporte: 5, Servicio.mensajeria: 3, Servicio.comercio: 1, Servicio.pagos: 2},
        ahora: h(9),
      );
      expect(s.servicio, Servicio.comercio);
    });
  });
}