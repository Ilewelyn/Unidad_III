import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Recomendador(),
    ));

class Pelicula {
  final String titulo;
  final String genero;
  final int anio;
  final double calificacion;
  final Color color;
  const Pelicula(this.titulo, this.genero, this.anio, this.calificacion, this.color);
}

const peliculas = [
  Pelicula('Coco', 'Animación', 2017, 8.4, Color(0xFFE76F51)),
  Pelicula('Matrix', 'Ciencia ficción', 1999, 8.7, Color(0xFF2A9D8F)),
  Pelicula('Del revés', 'Animación', 2015, 8.1, Color(0xFFF4A261)),
  Pelicula('Interestelar', 'Ciencia ficción', 2014, 8.7, Color(0xFF264653)),
  Pelicula('Pulp Fiction', 'Crimen', 1994, 8.5, Color(0xFFE9C46A)),
  Pelicula('El viaje de Chihiro', 'Fantasía', 2001, 8.6, Color(0xFF8AB17D)),
  Pelicula('Whiplash', 'Drama', 2014, 8.5, Color(0xFF6D597A)),
  Pelicula('Ratatouille', 'Animación', 2007, 8.1, Color(0xFFB56576)),
];

class Recomendador extends StatefulWidget {
  const Recomendador({super.key});
  @override
  State<Recomendador> createState() => _RecomendadorState();
}

class _RecomendadorState extends State<Recomendador> {
  Pelicula _actual = peliculas[0];

  void _otraAlAzar() {
    setState(() {
      _actual = peliculas[Random().nextInt(peliculas.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _actual;
    return Scaffold(
      appBar: AppBar(title: const Text('Película del fin de semana')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 4,
                child: SizedBox(
                  width: 280,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        color: p.color,
                        child: const Icon(Icons.movie, size: 96, color: Colors.white),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(p.titulo,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${p.genero} • ${p.anio}'),
                            const SizedBox(height: 4),
                            Text('⭐ ${p.calificacion.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _otraAlAzar,
                child: const Text('Otra al azar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}