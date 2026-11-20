import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/dominio/plan_diario.dart';
import 'package:habla_fluido/dominio/progreso.dart';
import 'package:habla_fluido/dominio/reglas.dart';

final d1 = DateTime(2026, 11, 5, 14, 30);

void main() {
  group('Progreso', () {
    test('EMA: el primer intento fija el valor; luego pesa 30%', () {
      final p = Progreso();
      p.registrar(Habilidad.escucha, 1.0, d1);
      expect(p.dominioDe(Habilidad.escucha), 1.0);
      p.registrar(Habilidad.escucha, 0.0, d1);
      expect(p.dominioDe(Habilidad.escucha), closeTo(0.7, 1e-9));
      expect(p.de(Habilidad.escucha)!.intentos, 2);
    });
    test('habilidad sin datos vale 0.5', () => expect(Progreso().dominioDe(Habilidad.lectura), Reglas.dominioSinEvaluar));
    test('puntaje fuera de rango se recorta', () {
      final p = Progreso()..registrar(Habilidad.lectura, 7, d1);
      expect(p.dominioDe(Habilidad.lectura), 1.0);
    });
    test('racha: mismo día, día siguiente y día perdido', () {
      final p = Progreso();
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 5, 8));
      expect(p.racha, 1);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 5, 21));
      expect(p.racha, 1);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 6));
      expect(p.racha, 2);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 9));
      expect(p.racha, 1);
    });
    test('la habilidad más débil', () {
      final p = Progreso();
      for (final h in [Habilidad.escucha, Habilidad.pronunciacion, Habilidad.lectura, Habilidad.conversacion]) {
        p.registrar(h, 0.9, d1);
      }
      expect(p.masDebil, Habilidad.escritura); // sin evaluar = 0.5 < 0.9
    });
    test('subir de nivel exige dominio e intentos en TODAS las habilidades y reinicia', () {
      final p = Progreso();
      for (final h in Habilidad.values) {
        for (var i = 0; i < Reglas.intentosParaSubir; i++) {
          p.registrar(h, 1.0, d1);
        }
      }
      expect(p.puedeSubirDeNivel, isTrue);
      expect(p.subirDeNivel(), isTrue);
      expect(p.nivel, NivelCefr.a2);
      expect(p.de(Habilidad.escucha), isNull);
      expect(p.puedeSubirDeNivel, isFalse);
    });
    test('con una habilidad floja no sube', () {
      final p = Progreso();
      for (final h in Habilidad.values) {
        for (var i = 0; i < 5; i++) {
          p.registrar(h, h == Habilidad.escritura ? 0.4 : 1.0, d1);
        }
      }
      expect(p.puedeSubirDeNivel, isFalse);
      expect(p.subirDeNivel(), isFalse);
    });
    test('JSON de ida y vuelta', () {
      final p = Progreso(nivel: NivelCefr.b1)..registrar(Habilidad.lectura, 0.6, d1);
      final r = Progreso.desdeJson(p.aJson());
      expect(r.nivel, NivelCefr.b1);
      expect(r.dominioDe(Habilidad.lectura), closeTo(0.6, 1e-9));
      expect(r.racha, 1);
      expect(Progreso.desdeJson('basura').nivel, NivelCefr.a1);
    });
  });

  group('plan diario', () {
    Progreso con(Habilidad debil) {
      final p = Progreso();
      for (final h in Habilidad.values) {
        p.registrar(h, h == debil ? 0.3 : 0.9, d1);
      }
      return p;
    }
    test('suma exactamente los minutos pedidos', () {
      for (final total in [5, 10, 17, 20, 33]) {
        final plan = generarPlan(con(Habilidad.lectura), minutosTotales: total);
        expect(plan.fold<int>(0, (a, b) => a + b.minutos), total, reason: '$total min');
      }
    });
    test('reparto concreto con escritura débil (20 min)', () {
      final plan = generarPlan(con(Habilidad.escritura));
      expect(plan.map((b) => b.minutos).toList(), [4, 4, 3, 5, 4]);
      expect(plan.where((b) => b.esRefuerzo).single.habilidad, Habilidad.escritura);
    });
    test('la habilidad débil recibe más tiempo que con su peso base', () {
      final plan = generarPlan(con(Habilidad.pronunciacion));
      final pron = plan.firstWhere((b) => b.habilidad == Habilidad.pronunciacion).minutos;
      expect(pron, 6);
    });
    test('toda habilidad recibe al menos 1 minuto en una sesión de 10', () {
      final plan = generarPlan(con(Habilidad.lectura), minutosTotales: 10);
      expect(plan.every((b) => b.minutos >= 1), isTrue);
    });
  });
}