import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/comercio.dart';
import 'package:super_dolores/dominio/contexto.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/mensajeria.dart';
import 'package:super_dolores/dominio/mini_app.dart';
import 'package:super_dolores/dominio/monedero.dart';
import 'package:super_dolores/dominio/transporte.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);
const jardin = Punto(21.1561, -100.9333);
const parroquia = Punto(21.1565, -100.9339);

const miniChat = MiniApp('chat', 'Mensajes', '💬',
    {Permiso.identidad, Permiso.mensajesLeer, Permiso.mensajesEscribir, Permiso.monederoPagar});
const miniMonedero = MiniApp('monedero', 'Monedero', '👛', {Permiso.identidad, Permiso.monederoLeer, Permiso.monederoPagar});
const miniViajes = MiniApp('viajes', 'Viajes', '🚕', {Permiso.identidad, Permiso.ubicacion, Permiso.monederoPagar});
const miniHoroscopo = MiniApp('horoscopo', 'Horóscopo', '🔮', {Permiso.identidad});

/// Entorno mínimo: monedero con Ana y Luis (con $1,000 cada una), registro de mini-apps y servicios.
class Entorno {
  final Monedero monedero = Monedero(reloj: () => ahora)
    ..abrirCuenta('ana')
    ..abrirCuenta('luis')
    ..abrirCuenta('plataforma', sinLimites: true);
  final BusEventos bus = BusEventos();
  final Ids ids = Ids();
  final RegistroMiniApps registro = RegistroMiniApps();
  late final ServicioMensajes mensajes = ServicioMensajes(monedero, bus, ids, () => ahora);
  late final ServicioComercio comercio = ServicioComercio(monedero, bus, ids, () => ahora, const []);
  late final ServicioViajes viajes = ServicioViajes(monedero, bus, ids, () => ahora);

  Entorno() {
    monedero.depositar('ana', 100000, clave: 'semilla');
    monedero.depositar('luis', 100000, clave: 'semilla');
    for (final a in [miniChat, miniMonedero, miniViajes, miniHoroscopo]) {
      registro.registrar(a);
    }
  }

  ContextoMiniApp contextoPara(MiniApp app, String usuario) =>
      ContextoMiniApp(app, usuario, registro, monedero, mensajes, comercio, viajes);
}

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('Mini-apps, permisos y kill switch', () {
    test('no se puede registrar dos veces la misma mini-app', () {
      final e = Entorno();
      expect(() => e.registro.registrar(miniChat), throwsArgumentError);
    });
    test('una mini-app de tercero (solo identidad) no toca dinero ni chats', () {
      final e = Entorno();
      final ctx = e.contextoPara(miniHoroscopo, 'ana');
      expect(() => ctx.monedero, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.pagos, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.mensajes, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.comercio, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.viajes, throwsA(isA<PermisoDenegadoException>()));
    });
    test('el chat puede enviar dinero pero NO leer el saldo (menor privilegio)', () {
      final e = Entorno();
      final ctx = e.contextoPara(miniChat, 'ana');
      expect(() => ctx.monedero, throwsA(isA<PermisoDenegadoException>()));
      ctx.pagos.enviarDinero('luis', 1000, clave: 'x');
      expect(e.monedero.saldo('luis'), 101000);
    });
    test('la API está ligada a UN usuario: no puede actuar como otra persona', () {
      final e = Entorno();
      final ctx = e.contextoPara(miniMonedero, 'ana');
      expect(ctx.monedero.saldo(), e.monedero.saldo('ana'));
      ctx.pagos.pagar(1000, 'Algo', clave: 'k');
      expect(e.monedero.saldo('ana'), 99000);
      expect(e.monedero.saldo('luis'), 100000); // intacto
    });
    test('kill switch: apagar una mini-app la oculta y bloquea sus llamadas', () {
      final e = Entorno();
      final ctx = e.contextoPara(miniChat, 'ana');
      e.registro.apagar('chat');
      expect(e.registro.activas.map((a) => a.id), isNot(contains('chat')));
      expect(() => ctx.mensajes, throwsA(isA<MiniAppNoDisponibleException>()));
      e.registro.encender('chat');
      expect(() => ctx.mensajes, returnsNormally);
    });
    test('una mini-app no puede operar sobre viajes de otra persona', () {
      final e = Entorno();
      final ana = e.contextoPara(miniViajes, 'ana').viajes;
      final luis = e.contextoPara(miniViajes, 'luis').viajes;
      final v = ana.solicitar(jardin, parroquia);
      expect(() => luis.cancelar(v.id), throwsA(isA<PedidoInvalidoException>()));
    });
  });
}