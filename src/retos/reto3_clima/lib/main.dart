import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiKey = 'c60e3f08ef845d9ce239f8748431e38d';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: AppClima()));

class Clima {
  final String ciudad, descripcion;
  final double temperatura, sensacion;
  final int humedad;
  Clima({
    required this.ciudad,
    required this.descripcion,
    required this.temperatura,
    required this.sensacion,
    required this.humedad,
  });
}

Future<Clima> obtenerClima(String ciudad) async {
  final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
    'q': ciudad,
    'units': 'metric',
    'lang': 'es',
    'appid': _apiKey,
  });
  final r = await http.get(uri);
  if (r.statusCode != 200) throw Exception('No se pudo obtener el clima (${r.statusCode})');
  final j = jsonDecode(r.body);
  return Clima(
    ciudad: j['name'],
    descripcion: j['weather'][0]['description'],
    temperatura: (j['main']['temp'] as num).toDouble(),
    sensacion: (j['main']['feels_like'] as num).toDouble(),
    humedad: j['main']['humidity'],
  );
}

class AppClima extends StatefulWidget {
  const AppClima({super.key});
  @override
  State<AppClima> createState() => _AppClimaState();
}

class _AppClimaState extends State<AppClima> {
  late Future<Clima> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = obtenerClima('Dolores Hidalgo,MX');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: Center(
        child: FutureBuilder<Clima>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            if (snap.hasError) return Text('${snap.error}', textAlign: TextAlign.center);
            final c = snap.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.ciudad, style: const TextStyle(fontSize: 28)),
                Text('${c.temperatura.round()}°C',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300)),
                Text(c.descripcion, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text('Sensación: ${c.sensacion.round()}°C  •  Humedad: ${c.humedad}%'),
              ],
            );
          },
        ),
      ),
    );
  }
}
