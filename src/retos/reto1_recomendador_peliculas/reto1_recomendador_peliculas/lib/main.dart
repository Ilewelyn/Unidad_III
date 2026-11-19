import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiKey = '43231e1db48510331c9c15c396ec74c5';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Recomendador()));

class Pelicula {
  final String titulo;
  final String? poster;
  final double calificacion;
  Pelicula.fromJson(Map<String, dynamic> j)
      : titulo = j['title'] ?? '',
        poster = j['poster_path'],
        calificacion = (j['vote_average'] ?? 0).toDouble();
}

Future<List<Pelicula>> obtenerTendencias() async {
  final uri = Uri.https('api.themoviedb.org', '/3/trending/movie/week',
      {'api_key': _apiKey, 'language': 'es-MX'});
  final r = await http.get(uri);
  if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
  final lista = jsonDecode(r.body)['results'] as List;
  return lista.map((j) => Pelicula.fromJson(j)).toList();
}

class Recomendador extends StatefulWidget {
  const Recomendador({super.key});
  @override
  State<Recomendador> createState() => _RecomendadorState();
}

class _RecomendadorState extends State<Recomendador> {
  late Future<List<Pelicula>> _futuro;
  Pelicula? _elegida;

  @override
  void initState() {
    super.initState();
    _futuro = obtenerTendencias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Película del fin de semana')),
      body: FutureBuilder<List<Pelicula>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final peliculas = snap.data!;
          final p = _elegida ?? peliculas.first;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.poster != null)
                          Image.network('https://image.tmdb.org/t/p/w500${p.poster}',
                              width: 280, fit: BoxFit.cover),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            Text(p.titulo,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('⭐ ${p.calificacion.toStringAsFixed(1)}'),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(
                        () => _elegida = peliculas[Random().nextInt(peliculas.length)]),
                    child: const Text('Otra al azar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
