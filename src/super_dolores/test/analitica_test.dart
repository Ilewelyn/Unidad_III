import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/analitica.dart';
import 'package:super_dolores/dominio/eventos.dart';

void main() {
  group('Analítica de retención (datos hechos a mano, verificados con un cálculo independiente)', () {
    final a = Analitica();
    void r(String u, Servicio s, int d) => a.agregar(RegistroUso(u, s, DateTime(2026, 11, d, 12)));
    setUpAll(() {
      r('A', Servicio.mensajeria, 1);
      r('A', Servicio.comercio, 2);
      r('A', Servicio.mensajeria, 8);
      r('B', Servicio.pagos, 1);
      r('C', Servicio.transporte, 1);
      r('C', Servicio.transporte, 2);
      r('D', Servicio.mensajeria, 2);
      r('D', Servicio.pagos, 9);
      r('E', Servicio.comercio, 2);
    });
    DateTime nov(int d) => DateTime(2026, 11, d);
    test('DAU, WAU y MAU', () {
      expect(a.dau(nov(2)), 4);
      expect(a.wau(nov(2)), 5);
      expect(a.mau(nov(2)), 5);
      expect(a.dau(nov(8)), 1);
      expect(a.wau(nov(8)), 4); // B ya salió de la ventana de 7 días
      expect(a.mau(nov(8)), 5);
    });
    test('stickiness = DAU / MAU', () {
      expect(a.stickiness(nov(2)), closeTo(0.8, 1e-9));
      expect(a.stickiness(nov(8)), closeTo(0.2, 1e-9));
      expect(Analitica().stickiness(nov(1)), 0);
    });
    test('cohortes: quién llegó por primera vez cada día', () {
      expect(a.cohorte(nov(1)), {'A', 'B', 'C'});
      expect(a.cohorte(nov(2)), {'D', 'E'});
      expect(a.primerDia('D'), nov(2));
      expect(a.primerDia('nadie'), isNull);
    });
    test('retención D1 y D7 por cohorte', () {
      expect(a.retencion(nov(1), 1), closeTo(2 / 3, 1e-9)); // A y C volvieron el día 2
      expect(a.retencion(nov(1), 7), closeTo(1 / 3, 1e-9)); // solo A el día 8
      expect(a.retencion(nov(2), 7), closeTo(1 / 2, 1e-9)); // D el día 9
      expect(a.retencion(nov(2), 1), 0);
      expect(a.retencion(nov(20), 1), 0); // cohorte vacía: sin dividir entre cero
    });
    test('servicios por usuario y % multiservicio', () {
      expect(a.serviciosPorUsuario(nov(1), nov(9)), closeTo(1.4, 1e-9));
      expect(a.porcentajeMultiservicio(nov(1), nov(9)), closeTo(0.4, 1e-9));
      expect(a.porcentajeMultiservicio(nov(1), nov(9), minimo: 1), 1.0);
    });
    test('semana 2 según servicios usados en la semana 1 (correlación, no causa)', () {
      final c = a.retencionSemana2PorServicios(nov(1), nov(2));
      expect(c.nUno, 4);
      expect(c.unServicio, closeTo(0.25, 1e-9));
      expect(c.nMulti, 1);
      expect(c.multiservicio, 1.0);
    });
    test('el registro de eventos ignora lo pasivo', () {
      final bus = BusEventos();
      final b = Analitica()..conectar(bus);
      bus.publicar(DineroRecibido('e1', 'u', DateTime(2026, 11, 1), de: 'x', montoCentavos: 1));
      bus.publicar(MensajeEnviado('e2', 'u', DateTime(2026, 11, 1), para: 'x'));
      expect(b.registros.length, 1);
    });
  });
}